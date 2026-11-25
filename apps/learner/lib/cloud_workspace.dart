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
  final email=TextEditingController(),password=TextEditingController(),guestName=TextEditingController(),newPassword=TextEditingController(),confirmNewPassword=TextEditingController();
  final client=Supabase.instance.client;
  StreamSubscription<AuthState>? subscription;
  LearnerStore? store;
  LearnerStore? guestStore;
  String? owner;
  String error='',notice='';
  bool busy=false,loading=false,recovering=false;
  int generation=0;
  @override void initState(){super.initState();subscription=client.auth.onAuthStateChange.listen((state){if(state.event==AuthChangeEvent.passwordRecovery){if(mounted)setState(()=>recovering=true);return;}unawaited(loadAccount());},onError:(_){if(mounted)setState(()=>error='The login session could not refresh. Your unsaved work remains open.');});unawaited(loadAccount());}
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
  Future<void> continueAsGuest() async {
    if(busy)return;
    final displayName=guestName.text.trim();
    if(displayName.isEmpty){setState(()=>error='Enter your name to continue as a guest.');return;}
    setState((){busy=true;error='';notice='';});
    final temporary=LearnerStore(storage:MemoryStorage(),temporary:true);
    try{
      await temporary.start();
      await temporary.preferences(displayName:displayName);
      if(!mounted){temporary.dispose();return;}
      setState(()=>guestStore=temporary);
    }catch(_){
      temporary.dispose();
      if(mounted)setState(()=>error='Could not start a guest session. Please try again.');
    }finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> sendPasswordReset() async {
    final address=email.text.trim();
    if(!address.contains('@')){setState(()=>error='Enter the email address linked to your account first.');return;}
    setState((){busy=true;error='';notice='';});
    try{
      await client.auth.resetPasswordForEmail(address);
      if(mounted)setState(()=>notice='If the address belongs to an account, Supabase will send a password reset email. Check your inbox and spam folder.');
    }on AuthException catch(e){if(mounted)setState(()=>error=e.message);}
    catch(_){if(mounted)setState(()=>error='Could not send the reset request. Check your connection and try again.');}
    finally{if(mounted)setState(()=>busy=false);}
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
  Future<void> updateRecoveredPassword() async {
    if(newPassword.text.length<8){setState(()=>error='Use a password with at least eight characters.');return;}
    if(newPassword.text!=confirmNewPassword.text){setState(()=>error='The passwords do not match.');return;}
    setState((){busy=true;error='';notice='';});
    try{
      await client.auth.updateUser(UserAttributes(password:newPassword.text));
      newPassword.clear();confirmNewPassword.clear();
      await client.auth.signOut();
      if(mounted)setState((){recovering=false;notice='Your password has been updated. Sign in with your new password.';});
    }on AuthException catch(e){if(mounted)setState(()=>error=e.message);}
    catch(_){if(mounted)setState(()=>error='Could not update your password. Open the reset link again and retry.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Widget passwordRecoveryScreen()=>Scaffold(appBar:AppBar(title:const Text('Reset your password')),body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.lock_reset,size:42,color:Color(0xff0eaaa7)),const SizedBox(height:20),const Text('Choose a new password',style:TextStyle(fontSize:25,fontWeight:FontWeight.w700)),const SizedBox(height:12),
    const Text('Enter and confirm your new password. Use at least eight characters.'),const SizedBox(height:24),
    TextField(controller:newPassword,obscureText:true,enableSuggestions:false,autocorrect:false,decoration:const InputDecoration(labelText:'New password',border:OutlineInputBorder())),const SizedBox(height:16),
    TextField(controller:confirmNewPassword,obscureText:true,enableSuggestions:false,autocorrect:false,decoration:const InputDecoration(labelText:'Confirm new password',border:OutlineInputBorder()),onSubmitted:(_)=>updateRecoveredPassword()),const SizedBox(height:18),
    FilledButton(onPressed:busy?null:updateRecoveredPassword,child:Text(busy?'Updating…':'Update password')),
    if(error.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(error,style:const TextStyle(color:Colors.red))),
  ])))));
  @override Widget build(BuildContext context){
    if(recovering)return passwordRecoveryScreen();
    if(guestStore!=null)return widget.builder(guestStore!);
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(store!=null&&client.auth.currentUser?.id==owner)return widget.builder(store!);
    return Scaffold(appBar:AppBar(title:const Text('Bajinka Academy')),body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Icon(Icons.school_outlined,size:42,color:Color(0xff0eaaa7)),const SizedBox(height:20),const Text('Your private workbench',style:TextStyle(fontSize:25,fontWeight:FontWeight.w700)),const SizedBox(height:12),
      const Text('Sign in to load your projects, Python workspaces, investigation notes, saved files and settings from Supabase. Your saved work belongs to your account.'),const SizedBox(height:24),
      if(client.auth.currentUser==null)...[
        TextField(controller:email,keyboardType:TextInputType.emailAddress,autocorrect:false,decoration:const InputDecoration(labelText:'Email',border:OutlineInputBorder())),const SizedBox(height:16),
        TextField(controller:password,obscureText:true,enableSuggestions:false,autocorrect:false,decoration:const InputDecoration(labelText:'Password',border:OutlineInputBorder()),onSubmitted:(_)=>authenticate(false)),const SizedBox(height:18),
        FilledButton(onPressed:busy?null:()=>authenticate(false),child:Text(busy?'Connecting…':'Sign in')),
        TextButton(onPressed:busy?null:()=>authenticate(true),child:const Text('Create my account')),
        TextButton(onPressed:busy?null:sendPasswordReset,child:const Text('Forgot password?')),
        const Divider(height:32),
        const Text('Prefer not to create an account?',style:TextStyle(fontWeight:FontWeight.w600)),
        const SizedBox(height:8),
        TextField(controller:guestName,textCapitalization:TextCapitalization.words,autocorrect:false,decoration:const InputDecoration(labelText:'Your name',border:OutlineInputBorder())),
        const SizedBox(height:10),
        OutlinedButton(onPressed:busy?null:continueAsGuest,child:const Text('Continue as guest')),
        const SizedBox(height:6),
        const Text('Guest work is temporary. It is not uploaded or saved and will be lost when this session ends.',style:TextStyle(fontSize:12)),
      ]else FilledButton(onPressed:loadAccount,child:const Text('Retry loading my cloud workspace')),
      if(notice.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(notice)),if(error.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(error,style:const TextStyle(color:Colors.red))),
      const SizedBox(height:16),const Text('Internet is required. You will sign in again after reopening or refreshing the app.',style:TextStyle(fontSize:12)),
    ])))));
  }
  @override void dispose(){generation++;subscription?.cancel();guestStore?.dispose();email.dispose();password.dispose();guestName.dispose();newPassword.dispose();confirmNewPassword.dispose();super.dispose();}
}
