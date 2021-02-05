class UserModel {
  String uid;
  String userName;
  bool alive;
  String lastAnswer;
  int score;

  UserModel({
    this.uid,
    this.userName,
    this.alive,
    this.lastAnswer,
    this.score,
  });

  UserModel.fromMap(Map<String, dynamic> mapData) {
    this.uid = mapData['uid'];
    this.userName = mapData['userName'];
    this.alive = mapData['alive'] == "TRUE";
    this.lastAnswer = mapData['lastAnswer'];
    this.score = mapData['score'];
  }
}
