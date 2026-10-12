import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learner_store.dart';

class SupabaseWorkspaceStorage implements DeviceStorage {
  SupabaseWorkspaceStorage(this.client, this.userId);
  final SupabaseClient client;
  final String userId;
  int revision = 0;
  bool conflicted = false;
  void checkOwner() {
    if(client.auth.currentUser?.id != userId) throw const FormatException('Sign in again to save your workspace.');
  }
  @override Future<String?> read(String key) async {
    checkOwner();
    final row = await client.from('academy_workspaces').select('payload,revision').eq('user_id',userId).maybeSingle().timeout(const Duration(seconds:20));
    revision = row == null ? 0 : (row['revision'] as num).toInt();conflicted=false;
    return row == null ? null : jsonEncode(row['payload']);
  }
  @override Future<void> write(String key,String value) async {
    checkOwner();if(conflicted) throw const WorkspaceConflict();
    try {
      final next = await client.rpc('academy_save_workspace',params:{'p_payload':jsonDecode(value),'p_revision':revision}).timeout(const Duration(seconds:20));
      revision=(next as num).toInt();
    } on PostgrestException catch(e) {
      if(e.message.contains('WORKSPACE_CONFLICT')) {conflicted=true;throw const WorkspaceConflict();}
      rethrow;
    }
  }
}

class CloudAccountGate extends StatefulWidget {
  const CloudAccountGate({super.key,required this.builder});
  final Widget Function(LearnerStore) builder;
  @override State<CloudAccountGate> createState()=>_CloudAccountGateState();
}
class _CloudAccountGateState extends State<CloudAccountGate> {
  final email=TextEditingController(),password=TextEditingController();
  final client=Supabase.instance.client;
  StreamSubscription<AuthState>? subscription;
  LearnerStore? store;
  String? owner;
  String error='',notice='';
  bool busy=false,loading=false;
  int generation=0;
  @override void initState(){super.initState();subscription=client.auth.onAuthStateChange.listen((state){unawaited(loadAccount());},onError:(_){if(mounted)setState(()=>error='The login session could not refresh. Your unsaved work remains open.');});unawaited(loadAccount());}
  Future<void> loadAccount() async {
    final user=client.auth.currentUser;
    if(user?.id==owner && store!=null)return;
    final current=++generation;
    if(user==null){if(mounted)setState((){owner=null;store=null;loading=false;});return;}
    owner=user.id;
    if(mounted)setState((){loading=true;error='';});
    final next=LearnerStore(storage:SupabaseWorkspaceStorage(client,user.id),cloud:true);
    await next.start();
    if(!mounted||current!=generation){next.dispose();return;}
    if(next.loadFailed){next.dispose();owner=null;setState((){loading=false;error='Your cloud workspace could not load. Check your connection and retry.';});return;}
    setState((){store=next;loading=false;});
  }
  Future<void> authenticate(bool create) async {
    if(busy)return;
    if(!email.text.trim().contains('@')||password.text.length<8){setState(()=>error='Enter your email and a password of at least eight characters.');return;}
    setState((){busy=true;error='';notice='';});
    try{
      if(create){final result=await client.auth.signUp(email:email.text.trim(),password:password.text);if(result.session==null&&mounted)setState(()=>notice='Check your email to confirm your account, then return here and sign in.');}
      else{await client.auth.signInWithPassword(email:email.text.trim(),password:password.text);}
      password.clear();await loadAccount();
    }on AuthException catch(e){if(mounted)setState(()=>error=e.message);}
    catch(_){if(mounted)setState(()=>error='Could not connect to Supabase. Check your connection and try again.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(store!=null&&client.auth.currentUser?.id==owner)return widget.builder(store!);
    return Scaffold(appBar:AppBar(title:const Text('Bajinka Academy')),body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Icon(Icons.school_outlined,size:42,color:Color(0xff0eaaa7)),const SizedBox(height:20),const Text('Your private learning workspace',style:TextStyle(fontSize:25,fontWeight:FontWeight.w700)),const SizedBox(height:12),
      const Text('Sign in to load your notes, code, terminal history, settings and learning record from Supabase. Saved work belongs to your account. This app does not keep local work or login credentials.'),const SizedBox(height:24),
      if(client.auth.currentUser==null)...[
        TextField(controller:email,keyboardType:TextInputType.emailAddress,autocorrect:false,decoration:const InputDecoration(labelText:'Email',border:OutlineInputBorder())),const SizedBox(height:16),
        TextField(controller:password,obscureText:true,enableSuggestions:false,autocorrect:false,decoration:const InputDecoration(labelText:'Password',border:OutlineInputBorder()),onSubmitted:(_)=>authenticate(false)),const SizedBox(height:18),
        FilledButton(onPressed:busy?null:()=>authenticate(false),child:Text(busy?'Connecting…':'Sign in')),
        TextButton(onPressed:busy?null:()=>authenticate(true),child:const Text('Create my account')),
      ]else FilledButton(onPressed:loadAccount,child:const Text('Retry loading my cloud workspace')),
      if(notice.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(notice)),if(error.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(error,style:const TextStyle(color:Colors.red))),
      const SizedBox(height:16),const Text('Internet is required. You will sign in again after reopening or refreshing the app.',style:TextStyle(fontSize:12)),
    ])))));
  }
  @override void dispose(){generation++;subscription?.cancel();email.dispose();password.dispose();super.dispose();}
}
