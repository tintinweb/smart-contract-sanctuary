//SourceUnit: PeoplesDreamsPro.sol

pragma solidity 0.5.10;
contract PeoplesDreamsPro {
    using SafeMath for uint256;
    address payable public owner;
    address payable internal externalWallet;
    uint256 public currUserID = 0;
    uint256 public station1currUserID = 0;
    uint256 public station2currUserID = 0;
    
    uint256 public startStationUserCount;
    uint256 public station1UserCount;
    uint256 public station2UserCount;
    
    uint256 public startStationactiveUserID ;
    uint256 public station1activeUserID ;
    uint256 public station2activeUserID ;
    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 referredUsers;
        uint256 contractReward;
        uint256 refReward;
        uint256 StationReward;
    }
    struct StationUserStruct {
        bool isExist;
        uint id;
        uint payment_received;
    }

    mapping(address => UserStruct) public users;
    mapping(uint => address payable) public userList;
    mapping(address => StationUserStruct) public startStationusers;
    mapping(uint => address payable) public startStationuserList;
    mapping(address => StationUserStruct) public station1users;
    mapping(uint => address payable) public station1userList;
    mapping(address => StationUserStruct) public station2users;
    mapping(uint => address payable) public station2userList;

    UserStruct[] public requests;
    uint public totalEarned = 0;
    constructor(address payable _owner,address payable _externalWallet) public {
          owner = _owner;
          externalWallet=_externalWallet;
          startStationactiveUserID++;
          station1activeUserID++;
          station2activeUserID++;
    }

    function reInvest(address payable _user) internal {
    require(users[_user].isExist, "User Exists");
        currUserID++;
        startStationUserCount++;
        users[_user]  = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: users[_user].referrerID,
            referredUsers:users[_user].referredUsers,
            contractReward:users[_user].contractReward,
            refReward:users[_user].refReward,
            StationReward:users[_user].StationReward
        });
        userList[currUserID]=_user;
        startStationusers[_user] = StationUserStruct({
            isExist: true,
            id: currUserID,
            payment_received: 0
        });
    startStationuserList[currUserID]=_user;
    startStationusers[startStationuserList[startStationactiveUserID]].payment_received+=1;
    userList[users[_user].referrerID].transfer(400 trx);
    users[userList[users[_user].referrerID]].refReward+=400;
    users[userList[users[_user].referrerID]].contractReward+=400;
    externalWallet.transfer(400 trx);
    if(startStationusers[startStationuserList[startStationactiveUserID]].payment_received>=3){
    startStationusers[startStationuserList[startStationactiveUserID]].payment_received=0;
    if(!station1users[startStationuserList[startStationactiveUserID]].isExist){
    startStationuserList[startStationactiveUserID].transfer(700 trx);
    users[startStationuserList[startStationactiveUserID]].StationReward+=700 ;
    users[startStationuserList[startStationactiveUserID]].contractReward+=700 ;
    buyStation1(userList[startStationactiveUserID]);
    }
    else{
    startStationuserList[startStationactiveUserID].transfer(2100 trx);
    users[startStationuserList[startStationactiveUserID]].StationReward+=2100 ;
    users[startStationuserList[startStationactiveUserID]].contractReward+=2100 ;
    }
    startStationactiveUserID++;
    startStationUserCount--;
    }
    }
    
    function buyStartStation(address payable _referrer ) public payable {
    require(!users[msg.sender].isExist, "User Exists");
    require(msg.value == 1500 trx, 'Incorrect Value');
    uint256 _referrerID=users[_referrer].id;
    currUserID++;
    startStationUserCount++;
        users[msg.sender]  = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers:users[msg.sender].referredUsers,
            contractReward:0,
            refReward:0,
            StationReward:0
            
        });
        userList[currUserID]=msg.sender;
        startStationusers[msg.sender] = StationUserStruct({
            isExist: true,
            id: currUserID,
            payment_received: 0
        });
        startStationuserList[currUserID]=msg.sender;
        users[_referrer].referredUsers=users[_referrer].referredUsers.add(1);
        startStationusers[startStationuserList[startStationactiveUserID]].payment_received+=1;
        _referrer.transfer(400 trx);
        users[_referrer].refReward+=400;
        users[_referrer].contractReward+=400;
        externalWallet.transfer(400 trx);
      if(startStationusers[startStationuserList[startStationactiveUserID]].payment_received>=3){
          startStationusers[startStationuserList[startStationactiveUserID]].payment_received=0;
      if(!station1users[startStationuserList[startStationactiveUserID]].isExist){
      startStationuserList[startStationactiveUserID].transfer(700 trx);
      users[startStationuserList[startStationactiveUserID]].StationReward+=700 ;
      users[startStationuserList[startStationactiveUserID]].contractReward+=700 ;
      buyStation1(userList[startStationactiveUserID]);
    }
    else{
        startStationuserList[startStationactiveUserID].transfer(2100 trx);
      users[startStationuserList[startStationactiveUserID]].StationReward+=2100 ;
      users[startStationuserList[startStationactiveUserID]].contractReward+=2100 ;
    }
    startStationactiveUserID++;
    startStationUserCount--;
    }
    }

    function buyStations(uint _station) public payable{
        require(_station >=1 && _station < 3, "Invalid Level");
        if(_station == 1){
            require(msg.value == 1400 trx, 'Incorrect Value');
            buyStation1(msg.sender);
        }else if(_station == 2){
            require(msg.value == 2800 trx, 'Incorrect Value');
            buyStation2(msg.sender);
        }
    }
    
    function buyStation1(address payable _user) internal {
    require(users[_user].isExist, "User Exists");
    require(!station1users[_user].isExist, "Already in Station 1");
    station1currUserID++;
    station1UserCount++;
        station1users[_user] = StationUserStruct({
            isExist: true,
            id: station1currUserID,
            payment_received: 0
          });
    station1userList[station1currUserID] =_user;
    station1users[station1userList[station1activeUserID]].payment_received+=1;
    if(station1users[station1userList[station1activeUserID]].payment_received>=3){
    station1users[station1userList[station1activeUserID]].payment_received=0; 
    if(!station2users[station1userList[station1activeUserID]].isExist){
    station1userList[station1activeUserID].transfer(1400 trx);
    users[station1userList[station1activeUserID]].StationReward+=1400;
    users[station1userList[station1activeUserID]].contractReward+=1400;
    buyStation2(station1userList[station1activeUserID]);
    }
    else{
    station1userList[station1activeUserID].transfer(4200 trx);
    users[station1userList[station1activeUserID]].StationReward+=4200;
    users[station1userList[station1activeUserID]].contractReward+=4200;
    }
    station1activeUserID++;
    station1UserCount--;
    }
    }


    function buyStation2(address payable _user) internal   {
    require(station1users[_user].isExist, "User buy level 1 first");
    require(!station2users[_user].isExist, "Already in Station 2");
    station2currUserID++;
    station2UserCount++;
        station2users[_user] = StationUserStruct({
            isExist: true,
            id: station2currUserID,
            payment_received: 0
            });
    station2userList[station2currUserID] = _user;
    station2users[station2userList[station2activeUserID]].payment_received+=1;
    if(station2users[station2userList[station2activeUserID]].payment_received>=3){
    station2users[station2userList[station2activeUserID]].payment_received=0;
    station1users[station2userList[station2activeUserID]].isExist=false;
    station2users[station2userList[station2activeUserID]].isExist=false;
    startStationusers[station2userList[station2activeUserID]].isExist=false;
    station2userList[station2activeUserID].transfer(6900 trx);
    users[station2userList[station2activeUserID]].StationReward+=6900;
    users[station2userList[station2activeUserID]].contractReward+=6900;
    reInvest(station2userList[station2activeUserID]);
    station2activeUserID++;
    station2UserCount--;
    }
 
    }



    function getTrxBalance() public view returns(uint) {
        return address(this).balance;
    }

    }
    library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    }