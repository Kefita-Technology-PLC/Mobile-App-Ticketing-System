import 'package:flutter/material.dart';
import 'package:ticketingmobile_system/Pages/Ticket_HistoryPage.dart';
import '../Pages/Admin_StoredInfo.dart';
import '../Pages/Admin_Report.dart';
import '../Pages/Admin_UserInfo.dart';
import '../Pages/Ticketing_Page.dart';

class ReusableAdminButton extends StatelessWidget {
  final String text;

  ReusableAdminButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0XFF3D8BFF),
          borderRadius: BorderRadius.circular(7),
        ),
        child: TextButton(
          onPressed: () {
            _navigateBasedOnText(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateBasedOnText(BuildContext context) {
    if (text == "Reporting Page") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminReport()),
      );
    } else if (text == "Users Information") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LocalStoragePage()),
      );
    } else if (text == "Stored Informations") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StoredDatas()),
      );
    } else if (text == "Ticketing Page") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => TicketingPage()));
    } else if (text == "Ticketing History") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => TicketingHistory()));
    }
  }
}
