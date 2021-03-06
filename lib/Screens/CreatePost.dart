import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:Clothesgram/Models/Utente.dart';
import 'package:Clothesgram/Models/Negozio.dart';
import 'package:Clothesgram/Screens/DatiLogin.dart';
import 'package:Clothesgram/Screens/FirstPage.dart';
import 'package:Clothesgram/Screens/Profilo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePost extends StatefulWidget {
  static const String routeName = "/HomePage/CreatePost";
  final String title;
  final bool isUtente;
  final Object arg;
  final DocumentSnapshot documentSnapshot;

  CreatePost(
      {Key key, this.title, this.isUtente, this.arg, this.documentSnapshot})
      : super(key: key);

  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  File file;
  FileImage image;
  StorageTaskSnapshot storageTaskSnapshot;

  FirebaseFirestore _database;
  FirebaseStorage storage;

  Utente utente;
  Negozio negozio;

  TextEditingController descrizioneController = TextEditingController();
  TextEditingController prezzoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _database = FirebaseFirestore.instance;
    storage = FirebaseStorage.instance;
  }

  Widget buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(widget.isUtente
                        ? utente.photoProfile
                        : negozio.photoProfile),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.isUtente
                        ? utente.nome + " " + utente.cognome
                        : negozio.nomeNegozio,
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text("I miei dati"),
            onTap: () => Navigator.pushNamed(context, Profilo.routeName,
                arguments: widget.documentSnapshot),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Impostazioni"),
            onTap: () => Navigator.pushNamed(context, DatiLogin.routeName,
                arguments: widget.isUtente),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text("Esci dall'account"),
            onTap: () async {
              await GoogleSignIn().signOut;
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamed(context, FirstPage.routeName);
            },
          ),
        ],
      ),
    );
  }

  void builCupertinoDrawer(BuildContext context) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(widget.isUtente
              ? utente.nome + " " + utente.cognome
              : negozio.nomeNegozio),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: Text("I miei dati"),
              onPressed: () {
                Navigator.pushNamed(context, Profilo.routeName,
                    arguments: widget.documentSnapshot);
              },
            ),
            CupertinoActionSheetAction(
              child: Text("Impostazioni"),
              onPressed: () => Navigator.pushNamed(context, DatiLogin.routeName,
                  arguments: widget.isUtente),
            ),
            CupertinoActionSheetAction(
              child: Text("Esci dall'account",
                  style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: () async {
                await GoogleSignIn().signOut;
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamed(context, FirstPage.routeName);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showDialogPostPosted() async {
    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Post pubblicato correttamente"),
              content: Text("Il post è stato pubblicato!"),
              actions: <Widget>[
                FlatButton(
                  child: Text("Ok"),
                  onPressed: () {
                    setState(() {
                      descrizioneController = TextEditingController();
                      prezzoController = TextEditingController();
                      file = null;
                      image = null;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    }
    if (Platform.isIOS) {
      return showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text("Post pubblicato correttamente"),
              content: Text("Il post è stato pubblicato!"),
              actions: <Widget>[
                CupertinoButton(
                  child: Text("Ok"),
                  onPressed: () {
                    setState(() {
                      descrizioneController = TextEditingController();
                      prezzoController = TextEditingController();
                      file = null;
                      image = null;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    }
  }

  Future<void> putImage(File file) async {
    storageTaskSnapshot = await storage
        .ref()
        .child('fotoPost/' + file.path.split('/').last)
        .putFile(file)
        .onComplete;
    await _database.collection('posts').add({
      'ownerId': FirebaseAuth.instance.currentUser.uid,
      'nomeOwner': negozio.nomeNegozio,
      'mediaUrl': await storageTaskSnapshot.ref.getDownloadURL(),
      'descrizione': descrizioneController.text,
      'photoProfileOwner': negozio.photoProfile,
      'prezzo': prezzoController.text,
      'numSalvati': 0,
      'dateCreated': DateTime.now(),
    }).then((value) {
      _database.collection('posts').doc(value.id).update({
        'postId': value.id,
      });
    });
  }

  Widget build(BuildContext context) {
    if (widget.arg.runtimeType.toString() == "Utente") {
      utente = widget.arg;
    } else {
      negozio = widget.arg;
    }

    if (Platform.isAndroid) {
      return Scaffold(
          drawer: buildDrawer(),
          appBar: AppBar(
            title: Text(widget.title),
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                );
              },
            ),
            automaticallyImplyLeading: false,
          ),
          body: Container(
            child: ListView(
              children: <Widget>[
                Padding(padding: EdgeInsets.all(8)),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      // fit: BoxFit.fill,
                      image: image == null
                          ? AssetImage('contents/images/fotoProfilo.jpg')
                          : image,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text("Scatta una foto"),
                  onTap: () async {
                    ImagePicker imagePicker = ImagePicker();
                    PickedFile pickedFile =
                        await imagePicker.getImage(source: ImageSource.camera);
                    setState(() {
                      file = File(pickedFile.path);
                      image = FileImage(file);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text("Scegli dalla libreria"),
                  onTap: () async {
                    ImagePicker imagePicker = ImagePicker();
                    PickedFile pickedFile =
                        await imagePicker.getImage(source: ImageSource.gallery);
                    setState(() {
                      file = File(pickedFile.path);
                      image = FileImage(file);
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Descrizione"),
                    controller: descrizioneController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Prezzo"),
                    controller: prezzoController,
                  ),
                ),
                ListTile(
                  title: const Text(
                    "Posta",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    await putImage(file);
                    showDialogPostPosted();
                  },
                ),
                ListTile(
                  title: const Text("Cancella le modifiche"),
                  onTap: () {
                    setState(() {
                      descrizioneController.text = "";
                      prezzoController.text = "";
                      image = null;
                      file = null;
                    });
                  },
                ),
              ],
            ),
          ));
    }
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(widget.title),
            trailing: CupertinoButton(
              padding: EdgeInsets.only(bottom: 5),
              child: Icon(CupertinoIcons.settings),
              onPressed: () => builCupertinoDrawer(context),
            ),
          ),
          child: Container(
            child: ListView(
              children: <Widget>[
                Padding(padding: EdgeInsets.all(8)),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      // fit: BoxFit.fill,
                      image: image == null
                          ? AssetImage('contents/images/fotoProfilo.jpg')
                          : image,
                    ),
                  ),
                ),
                CupertinoButton(
                  child: Row(
                    children: <Widget>[
                      Icon(CupertinoIcons.photo_camera_solid),
                      Text("Scatta una foto"),
                    ],
                  ),
                  onPressed: () async {
                    ImagePicker imagePicker = ImagePicker();
                    PickedFile pickedFile =
                        await imagePicker.getImage(source: ImageSource.camera);
                    setState(() {
                      file = File(pickedFile.path);
                      image = FileImage(file);
                    });
                  },
                ),
                CupertinoButton(
                  child: Row(
                    children: <Widget>[
                      Icon(CupertinoIcons.photo_camera),
                      Text("Scegli dalla libreria"),
                    ],
                  ),
                  onPressed: () async {
                    ImagePicker imagePicker = ImagePicker();
                    PickedFile pickedFile =
                        await imagePicker.getImage(source: ImageSource.gallery);
                    setState(() {
                      file = File(pickedFile.path);
                      image = FileImage(file);
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CupertinoTextField(
                    placeholder: "Descrizione",
                    controller: descrizioneController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CupertinoTextField(
                    placeholder: "Prezzo",
                    controller: prezzoController,
                  ),
                ),
                CupertinoButton(
                  child: const Text(
                    "Posta",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await putImage(file);
                    showDialogPostPosted();
                  },
                ),
                CupertinoButton(
                  child: const Text("Cancella le modifiche"),
                  onPressed: () {
                    setState(() {
                      descrizioneController.text = "";
                      prezzoController.text = "";
                      image = null;
                      file = null;
                    });
                  },
                ),
              ],
            ),
          ));
    }
  }
}
