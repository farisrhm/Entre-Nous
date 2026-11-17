"""Select a downloaded App Store profile that actually grants production push."""

import argparse
from datetime import datetime
from pathlib import Path
import plistlib
import subprocess
import sys


def rejection_reasons(profile, bundle_id, now):
    entitlements = profile.get("Entitlements", {})
    prefixes = profile.get("ApplicationIdentifierPrefix", [])
    reasons = []
    if entitlements.get("application-identifier") not in [
        f"{prefix}.{bundle_id}" for prefix in prefixes
    ]:
        reasons.append("App ID différent ou wildcard")
    if entitlements.get("aps-environment") != "production":
        reasons.append("aps-environment=production absent")
    if (
        entitlements.get("get-task-allow", False)
        or "ProvisionedDevices" in profile
        or profile.get("ProvisionsAllDevices", False)
    ):
        reasons.append("profil hors App Store")
    if profile.get("ExpirationDate", datetime.min) <= now:
        reasons.append("profil expiré")
    return reasons


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, action="append", required=True)
    parser.add_argument("--bundle-id", required=True)
    args = parser.parse_args()
    candidates = []
    paths = sorted({path for directory in args.directory
                    for path in directory.glob("*.mobileprovision")})
    if not paths:
        print(
            "Aucun profil installé par Codemagic. Vérifier Team settings > "
            "Code signing identities : certificat Distribution et profil App Store "
            "pour ce bundle ID, avec certificat associé (coche verte).",
            file=sys.stderr,
        )
        return 1
    for path in paths:
        result = subprocess.run(
            ["security", "cms", "-D", "-i", str(path)],
            capture_output=True,
        )
        try:
            if result.returncode:
                raise ValueError("CMS decoding failed")
            profile = plistlib.loads(result.stdout)
        except (ValueError, plistlib.InvalidFileException):
            print(f"Profil illisible : {path.name}", file=sys.stderr)
            continue
        reasons = rejection_reasons(profile, args.bundle_id, datetime.utcnow())
        print(
            f"Profil : {profile.get('Name')} | UUID : {profile.get('UUID')} | "
            f"Push : {profile.get('Entitlements', {}).get('aps-environment', 'absent')} | "
            + (", ".join(reasons) if reasons else "compatible TestFlight + push"),
            file=sys.stderr,
        )
        if not reasons:
            candidates.append((profile.get("CreationDate", datetime.min), path))
    if not candidates:
        print(
            f"Aucun profil App Store avec push production pour {args.bundle_id}. "
            "Dans Apple Developer > Profiles, régénérer le profil App Store de cet "
            "App ID après activation de Push Notifications, puis relancer le build. "
            "La clé APNs Firebase ne corrige pas un profil de signature.",
            file=sys.stderr,
        )
        return 1
    # stdout is consumed by the workflow; diagnostics remain on stderr.
    print(max(candidates)[1])
    return 0


if __name__ == "__main__":
    sys.exit(main())
