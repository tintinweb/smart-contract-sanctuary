//SourceUnit: Peopl'sDream.sol

pragma solidity 0.5.10;
contract PeoplesDreams {
       using SafeMath for uint256;
    address payable public owner;
    address payable internal externalWallet;
    uint256 public currUserID = 0;
    uint256 public station1currUserID = 0;
    uint256 public station2currUserID = 0;
    uint256 public station3currUserID = 0;
    uint256 public station4currUserID = 0;
    uint256 public station5currUserID = 0;
    
    uint256 public startStationUserCount;
    uint256 public station1UserCount;
    uint256 public station2UserCount;
    uint256 public station3UserCount;
    uint256 public station4UserCount;
    uint256 public station5UserCount;
    
    uint256 public startStationactiveUserID ;
    uint256 public station1activeUserID ;
    uint256 public station2activeUserID ;
    uint256 public station3activeUserID ;
    uint256 public station4activeUserID ;
    uint256 public station5activeUserID ;
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
    mapping(address => StationUserStruct) public station3users;
    mapping(uint => address payable) public station3userList;
    mapping(address => StationUserStruct) public station4users;
    mapping(uint => address payable) public station4userList;
    mapping(address => StationUserStruct) public station5users;
    mapping(uint => address payable) public station5userList;
    // address [5] public arr;
    UserStruct[] public requests;
    uint public totalEarned = 0;
    constructor(address payable _owner,address payable _externalWallet) public {
          owner = _owner;
          externalWallet=_externalWallet;
          startStationactiveUserID++;
          station1activeUserID++;
          station2activeUserID++;
          station3activeUserID++;
          station4activeUserID++;
          station5activeUserID++;
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
    userList[users[_user].referrerID].transfer(40 trx);
    users[userList[users[_user].referrerID]].refReward+=40;
    users[userList[users[_user].referrerID]].contractReward+=40;
    externalWallet.transfer(40 trx);
    if(startStationusers[startStationuserList[startStationactiveUserID]].payment_received>=3){
    startStationusers[startStationuserList[startStationactiveUserID]].payment_received=0;
    if(!station1users[startStationuserList[startStationactiveUserID]].isExist){
    startStationuserList[startStationactiveUserID].transfer(70 trx);
    users[startStationuserList[startStationactiveUserID]].StationReward+=70 ;
    users[startStationuserList[startStationactiveUserID]].contractReward+=70 ;
    buyStation1(userList[startStationactiveUserID]);
    }
    else{
    startStationuserList[startStationactiveUserID].transfer(210 trx);
    users[startStationuserList[startStationactiveUserID]].StationReward+=210 ;
    users[startStationuserList[startStationactiveUserID]].contractReward+=210 ;
    }
    startStationactiveUserID++;
    startStationUserCount--;
    }
    }
    
    function buyStartStation(address payable _referrer ) public payable {
    require(!users[msg.sender].isExist, "User Exists");
    require(msg.value == 150 trx, 'Incorrect Value');
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
        _referrer.transfer(40 trx);
        users[_referrer].refReward+=40;
        users[_referrer].contractReward+=40;
        externalWallet.transfer(40 trx);
      if(startStationusers[startStationuserList[startStationactiveUserID]].payment_received>=3){
          startStationusers[startStationuserList[startStationactiveUserID]].payment_received=0;
      if(!station1users[startStationuserList[startStationactiveUserID]].isExist){
      startStationuserList[startStationactiveUserID].transfer(70 trx);
      users[startStationuserList[startStationactiveUserID]].StationReward+=70 ;
      users[startStationuserList[startStationactiveUserID]].contractReward+=70 ;
      buyStation1(userList[startStationactiveUserID]);
    }
    else{
        startStationuserList[startStationactiveUserID].transfer(210 trx);
      users[startStationuserList[startStationactiveUserID]].StationReward+=210 ;
      users[startStationuserList[startStationactiveUserID]].contractReward+=210 ;
    }
    startStationactiveUserID++;
    startStationUserCount--;
    }
    }

    function buyStations(uint _station) public payable{
        require(_station >=1 && _station < 7, "Invalid Level");
        if(_station == 1){
            require(msg.value == 140 trx, 'Incorrect Value');
            buyStation1(msg.sender);
        } 
        else if(_station == 2){
            require(msg.value == 280 trx, 'Incorrect Value');
            buyStation2(msg.sender);
        }else if(_station == 3){
            require(msg.value == 560 trx, 'Incorrect Value');
            buyStation3(msg.sender);
        } else if(_station == 4){
            require(msg.value == 1120 trx, 'Incorrect Value');
            buyStation4(msg.sender);
        }else if(_station == 5){
            require(msg.value == 2240 trx, 'Incorrect Value');
            buyStation5(msg.sender);
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
    station1userList[station1activeUserID].transfer(140 trx);
    users[station1userList[station1activeUserID]].StationReward+=140;
    users[station1userList[station1activeUserID]].contractReward+=140;
    buyStation2(station1userList[station1activeUserID]);
    }
    else{
    station1userList[station1activeUserID].transfer(420 trx);
    users[station1userList[station1activeUserID]].StationReward+=420;
    users[station1userList[station1activeUserID]].contractReward+=420;
    }
    station1activeUserID++;
    station1UserCount--;
    }
    }


    function buyStation2(address payable _user) internal {
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
    if(!station3users[station2userList[station2activeUserID]].isExist){
    station2userList[station2activeUserID].transfer(280 trx);
    users[station2userList[station2activeUserID]].StationReward+=280;
    users[station2userList[station2activeUserID]].contractReward+=280;
    buyStation3(station2userList[station2activeUserID]);    
    }
    else{
    station2userList[station2activeUserID].transfer(840 trx);
    users[station2userList[station2activeUserID]].StationReward+=840;
    users[station2userList[station2activeUserID]].contractReward+=840;
    }
    station2activeUserID++;
    station2UserCount--;
    }
    
    }

    

    function buyStation3(address payable _user) internal {
    require(station2users[_user].isExist, "User buy level 2 first"); 
    require(!station3users[_user].isExist, "Already in Station 3");
    station3currUserID++;
    station3UserCount++;
    station3users[_user] = StationUserStruct({
            isExist: true,
            id: station3currUserID,
            payment_received: 0
        });
        station3userList[station3currUserID] = _user;
    station3users[station3userList[station3activeUserID]].payment_received+=1;
    if(station3users[station3userList[station3activeUserID]].payment_received>=3){
    station3users[station3userList[station3activeUserID]].payment_received=0;
    if(!station4users[station3userList[station3activeUserID]].isExist){
    station3userList[station3activeUserID].transfer(560 trx);
    users[station3userList[station3activeUserID]].StationReward+=560;
    users[station3userList[station3activeUserID]].contractReward+=560;
    buyStation4(station3userList[station3activeUserID]);
    }
    else{
    station3userList[station3activeUserID].transfer(1680 trx);
    users[station3userList[station3activeUserID]].StationReward+=1680;
    users[station3userList[station3activeUserID]].contractReward+=1680;
    }
    station3activeUserID++;
    station3UserCount--;
    }
    
    }

    function buyStation4(address payable _user) internal {
    require(station3users[_user].isExist, "User buy level 3 first");
    require(!station4users[_user].isExist, "Already in Station 4");
    
    station4currUserID++;
    station4UserCount++;
        station4users[_user] = StationUserStruct({
            isExist: true,
            id: station4currUserID,
            payment_received: 0
        });
    station4userList[station4currUserID] = _user;
        
                                

    station4users[station4userList[station4activeUserID]].payment_received+=1;
    if(station4users[station4userList[station4activeUserID]].payment_received>=3){
    station4users[station4userList[station4activeUserID]].payment_received=0;
    if(!station5users[station4userList[station4activeUserID]].isExist){
    station4userList[station4activeUserID].transfer(1120 trx);
    users[station4userList[station4activeUserID]].StationReward+=1120;
    users[station4userList[station4activeUserID]].contractReward+=1120;
    buyStation5(station4userList[station4activeUserID]);
    }else
    {
    station4userList[station4activeUserID].transfer(3360 trx);
    users[station4userList[station4activeUserID]].StationReward+=3360;
    users[station4userList[station4activeUserID]].contractReward+=3360;
    }
    station4activeUserID++;
    station4UserCount--;
    }    
    }

    function buyStation5(address payable _user) internal {
    require(station4users[_user].isExist, "User buy level 4 first");
    require(!station5users[_user].isExist, "Already in Station 5");
    station5currUserID++;
    station5UserCount++;
        station5users[_user] = StationUserStruct({
            isExist: true,
            id: station5currUserID,
            payment_received: 0
            });
    station5userList[station5currUserID] = _user;
    station5users[station5userList[station5activeUserID]].payment_received+=1;
    if(station5users[station5userList[station5activeUserID]].payment_received>=3){
    station5users[station5userList[station5activeUserID]].payment_received=0;
    station1users[station5userList[station5activeUserID]].isExist=false;
    station2users[station5userList[station5activeUserID]].isExist=false;
    station3users[station5userList[station5activeUserID]].isExist=false;
    station4users[station5userList[station5activeUserID]].isExist=false;
    station5users[station5userList[station5activeUserID]].isExist=false;
    startStationusers[station5userList[station5activeUserID]].isExist=false;
    station5userList[station5activeUserID].transfer(6570 trx);
    users[station5userList[station5activeUserID]].StationReward+=6570;
    users[station5userList[station5activeUserID]].contractReward+=6570;
    reInvest(station5userList[station5activeUserID]);
    station5activeUserID++;
    station5UserCount--;
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