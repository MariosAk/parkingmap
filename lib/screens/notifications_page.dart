import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dependency_injection.dart';
import '../model/notifications.dart';
import '../services/sqlite_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  final SqliteService _sqliteService = getIt<SqliteService>();
  late Future<List<Notifications>> notifications;
  late List<Notifications> notificationlist;

  @override
  void initState() {
    super.initState();

    //notifications = this.getNotificationsList();
  }

  Future<List<Notifications>> getNotificationsList() async {
    return await _sqliteService.getNotifications();
  }

  Future<void> deleteFromDataBase(String id) async {
    return await _sqliteService.deleteItem(id);
  }

  AssetImage notificationImage(String cT) {
    switch (cT) {
      case "Sedan":
        {
          return const AssetImage('Assets/Images/Sedan.png');
        }
      case "Coupe":
        return const AssetImage('Assets/Images/Coupe.png');
      case "Pickup":
        return const AssetImage('Assets/Images/Pickup.png');
      case "Jeep":
        return const AssetImage('Assets/Images/Jeep.png');
      case "Wagon":
        return const AssetImage('Assets/Images/Wagon.png');
      case "Crossover":
        return const AssetImage('Assets/Images/Crossover.png');
      case "Hatchback":
        return const AssetImage('Assets/Images/Hatchback.png');
      case "Van":
        return const AssetImage('Assets/Images/Van.png');
      case "Sportcoupe":
        return const AssetImage('Assets/Images/SportCoupe.png');
      case "SUV":
        return const AssetImage('Assets/Images/SUV.png');
      default:
        return const AssetImage('Assets/Images/Sedan.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Notifications>>(
        future: getNotificationsList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // Future done with no errors
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return Container(
                color: const Color.fromRGBO(246, 255, 255, 1.0),
                child: SafeArea(
                    child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          title: Text(
                            "Notifications",
                            style: GoogleFonts.openSans(
                                textStyle:
                                    const TextStyle(color: Colors.black)),
                          ),
                          leading: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black38,
                            ),
                            onPressed: () =>
                                Navigator.pop(context, snapshot.data.length),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.black38,
                              ),
                              onPressed: () => Navigator.pop(context, 'close'),
                            ),
                          ],
                          centerTitle: true,
                        ),
                        body: Center(
                            child: SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: snapshot.data!.isNotEmpty
                              ? ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Dismissible(
                                      key: UniqueKey(),
                                      background: Container(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        color: Colors.red,
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onDismissed: (direction) async {
                                        await getNotificationsList();
                                        await deleteFromDataBase(snapshot
                                                .data![index].entryId
                                                .toString())
                                            .then((value) => ScaffoldMessenger
                                                    .of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Data for ${snapshot.data![index].time.toString()} dismissed'))));
                                        snapshot.data!.removeAt(index);
                                      },
                                      direction: DismissDirection.endToStart,
                                      child: Card(
                                        elevation: 5,
                                        child: SizedBox(
                                          height: 100.0,
                                          child: Row(
                                            children: <Widget>[
                                              Container(
                                                  height: 100.0,
                                                  width: 70.0,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                              bottomLeft: Radius
                                                                  .circular(5),
                                                              topLeft: Radius
                                                                  .circular(5)),
                                                      image: DecorationImage(
                                                          fit: BoxFit.fitWidth,
                                                          image: notificationImage(
                                                              snapshot
                                                                  .data![index]
                                                                  .carType)))),
                                              SizedBox(
                                                height: 100,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 2, 0, 0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      SizedBox(
                                                          width: 260,
                                                          child: Text(
                                                            "Address: ${snapshot.data![index].address.toString()}",
                                                          )),
                                                      Text(
                                                        "Cartype: ${snapshot.data![index].carType.toString()}",
                                                      ),
                                                      Text(
                                                        "Time: ${snapshot.data![index].time.toString()}",
                                                      ),
                                                      Text(
                                                        "Status: ${snapshot.data![index].status.toString()}",
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                              : const Text('You have no notifications.'),
                        )))));
          }
          // Future with some errors
          else if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            return Text("The error ${snapshot.error} occured");
          }
          // Future not done yet
          else {
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 1.5,
                  height: MediaQuery.of(context).size.width / 1.5,
                  child: const CircularProgressIndicator(strokeWidth: 10),
                ),
              ),
            );
          }
        });
  }
}
