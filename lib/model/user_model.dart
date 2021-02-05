class UserModel {
  String uid;
  String userName;
  bool alive;
  String lastAnswer;

  UserModel({
    this.uid,
    this.userName,
    this.alive,
    this.lastAnswer,
  });

  UserModel.fromMap(Map<String, dynamic> mapData) {
    this.uid = mapData['uid'];
    this.userName = mapData['userName'];
    this.alive = mapData['alive'] == "true";
    this.lastAnswer = mapData['lastAnswer'];
  }
}
