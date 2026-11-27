export function pushMessage(event: string, name: string, gender: string) {
  const from = /^[aeiouyhàâéèêëîïôùûü]/i.test(name)
    ? `d’${name}`
    : `de ${name}`;
  switch (event) {
    case "thought":
      return {
        title: `${name} pense à toi 🤍`,
        body: "Une petite pensée, juste pour toi.",
      };
    case "memory":
      return {
        title: "Un nouveau souvenir à deux",
        body: `${name} a ajouté un souvenir à votre histoire.`,
      };
    case "dua":
      return {
        title: "Une dou‘a pour toi 🌙",
        body: `${name} t’a dédié une dou‘a.`,
      };
    case "letter":
      return {
        title: gender === "feminine"
          ? "Une lettre de ta bien-aimée 💌"
          : gender === "masculine"
          ? "Une lettre de ton bien-aimé 💌"
          : "Une lettre pour toi 💌",
        body: `${name} a déposé quelques mots pour toi.`,
      };
    case "letter_ready":
      return {
        title: "Le moment est arrivé",
        body: `Tu peux maintenant ouvrir la lettre ${from}.`,
      };
    case "voucher":
      return {
        title: "Les petites attentions",
        body: `${name} a laissé du nouveau dans votre carnet d’attentions.`,
      };
    default:
      throw Error("Unsupported notification");
  }
}
