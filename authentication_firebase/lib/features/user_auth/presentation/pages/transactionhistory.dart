import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteTransaction(String username, String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(username)
          .collection('userTransactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      print("Error deleting transaction: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String username = _auth.currentUser?.email?.split('@')[0] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .doc(username)
            .collection('userTransactions')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No transactions available.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              final data = document.data() as Map<String, dynamic>;
              DateTime transactionDate = (data['date'] as Timestamp).toDate(); // Assuming you have a 'date' field

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('${data['type']}: ${data['amount']}'), // No dollar symbol
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${data['category']}'),
                      Text('Notes: ${data['notes']}'),
                      Text('Date: ${DateFormat('yyyy-MM-dd').format(transactionDate)}'), // Display the date
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Confirm Deletion
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete Transaction'),
                            content: Text('Are you sure you want to delete this transaction?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Dismiss dialog
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Delete the transaction
                                  _deleteTransaction(username, document.id);
                                  Navigator.pop(context); // Dismiss dialog
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
