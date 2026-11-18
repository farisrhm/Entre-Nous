import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/attention.dart';

class AttentionRepository {
  final SupabaseClient client;
  AttentionRepository(this.client);
  Future<List<AttentionVoucher>> list() async {
    final rows = await client.from('couple_vouchers').select().order('created_at',ascending:false);
    return rows.map(AttentionVoucher.new).toList();
  }
  Future<List<Map<String,dynamic>>> events(String id) => client.from('couple_voucher_events')
    .select().eq('voucher_id',id).order('created_at');
  Future<void> offer(Map<String,dynamic> params) async { await client.rpc('offer_voucher',params:params); }
  Future<void> act(Map<String,dynamic> params) async { await client.rpc('act_on_voucher',params:params); }
}
