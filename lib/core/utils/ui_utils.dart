DateTime? loginClickTime;

bool isRedundentClick(DateTime currentTime) {
  if (loginClickTime == null) {
    loginClickTime = currentTime;
    print("first click");
    return false;
  }
  // print('diff is ${currentTime.difference(loginClickTime!).inSeconds}');
  if (currentTime.difference(loginClickTime!).inMilliseconds < 1000) {
    //set this difference time in seconds
    return true;
  }

  loginClickTime = currentTime;
  return false;
}