import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserStatus(String status) async {
    final userId =
        _auth.currentUser!.uid; // Obtendo o ID do usuário autenticado
    DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    // Atualizar status no Firestore
    await userDocRef.update({'status': status, 'last_seen': Timestamp.now()});
  }

  void setUserOnline() async {
    await updateUserStatus('online');
  }

  void setUserOffline() async {
    await updateUserStatus('offline');
  }
}
