//SourceUnit: pool.sol

pragma solidity ^0.5.10;
contract TrxStar {
    using SafeMath for uint256;
    address payable public owner;
    uint256 public totalinvested;
    uint256 public totalpayout;
    
    uint256 public currUserID ;
    uint256 public station1currUserID ;
    uint256 public station2currUserID ;
    uint256 public station3currUserID ;
    uint256 public station4currUserID ;
    uint256 public station5currUserID ;
    uint256 public station6currUserID ;
    uint256 public station7currUserID ;
    uint256 public station8currUserID ;
    uint256 public station9currUserID ;
    uint256 public station10currUserID ;
    uint256 public station11currUserID ;
    uint256 public station12currUserID ;
    uint256 public station13currUserID ;
    uint256 public station14currUserID ;
    uint256 public station15currUserID ;
    uint256 public station16currUserID ;
    uint256 public station17currUserID ;
    uint256 public station18currUserID ;
    uint256 public station19currUserID ;
    uint256 public station20currUserID ;
    
    uint256 public startStationUserCount;
    uint256 public station1UserCount;
    uint256 public station2UserCount;
    uint256 public station3UserCount;
    uint256 public station4UserCount;
    uint256 public station5UserCount;
    uint256 public station6UserCount;
    uint256 public station7UserCount;
    uint256 public station8UserCount;
    uint256 public station9UserCount;
    uint256 public station10UserCount;
    uint256 public station11UserCount;
    uint256 public station12UserCount;
    uint256 public station13UserCount;
    uint256 public station14UserCount;
    uint256 public station15UserCount;
    uint256 public station16UserCount;
    uint256 public station17UserCount;
    uint256 public station18UserCount;
    uint256 public station19UserCount;
    uint256 public station20UserCount;
    
    uint256 public startStationactiveUserID = 1;
    uint256 public station1activeUserID = 1;
    uint256 public station2activeUserID = 1;
    uint256 public station3activeUserID = 1;
    uint256 public station4activeUserID = 1;
    uint256 public station5activeUserID = 1;
    uint256 public station6activeUserID = 1;
    uint256 public station7activeUserID = 1;
    uint256 public station8activeUserID = 1;
    uint256 public station9activeUserID = 1;
    uint256 public station10activeUserID = 1;
    uint256 public station11activeUserID = 1;
    uint256 public station12activeUserID = 1;
    uint256 public station13activeUserID = 1;
    uint256 public station14activeUserID = 1;
    uint256 public station15activeUserID = 1;
    uint256 public station16activeUserID = 1;
    uint256 public station17activeUserID = 1;
    uint256 public station18activeUserID = 1;
    uint256 public station19activeUserID = 1;
    uint256 public station20activeUserID = 1;
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
    mapping(address => StationUserStruct) public station6users;
    mapping(uint => address payable) public station6userList;
    mapping(address => StationUserStruct) public station7users;
    mapping(uint => address payable) public station7userList;
    mapping(address => StationUserStruct) public station8users;
    mapping(uint => address payable) public station8userList;
    mapping(address => StationUserStruct) public station9users;
    mapping(uint => address payable) public station9userList;
    mapping(address => StationUserStruct) public station10users;
    mapping(uint => address payable) public station10userList;
    mapping(address => StationUserStruct) public station11users;
    mapping(uint => address payable) public station11userList;
    mapping(address => StationUserStruct) public station12users;
    mapping(uint => address payable) public station12userList;
    mapping(address => StationUserStruct) public station13users;
    mapping(uint => address payable) public station13userList;
    mapping(address => StationUserStruct) public station14users;
    mapping(uint => address payable) public station14userList;
    mapping(address => StationUserStruct) public station15users;
    mapping(uint => address payable) public station15userList;
    mapping(address => StationUserStruct) public station16users;
    mapping(uint => address payable) public station16userList;
    mapping(address => StationUserStruct) public station17users;
    mapping(uint => address payable) public station17userList;
    mapping(address => StationUserStruct) public station18users;
    mapping(uint => address payable) public station18userList;
    mapping(address => StationUserStruct) public station19users;
    mapping(uint => address payable) public station19userList;
    mapping(address => StationUserStruct) public station20users;
    mapping(uint => address payable) public station20userList;
    
    
    constructor(address payable _owner) public {

        owner=_owner;
    }

    function reInvest(address payable _user) internal {
        require(users[_user].isExist, "User Exists");
        totalinvested+=150 trx;
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
    users[userList[users[_user].referrerID]].refReward+=40 trx;
    users[userList[users[_user].referrerID]].contractReward+=40 trx;
    owner.transfer(40 trx);
    if(startStationusers[startStationuserList[startStationactiveUserID]].payment_received>=3){
    startStationusers[startStationuserList[startStationactiveUserID]].payment_received=0;
    startStationuserList[startStationactiveUserID].transfer(70 trx);
    users[startStationuserList[startStationactiveUserID]].StationReward+=70 trx;
    users[startStationuserList[startStationactiveUserID]].contractReward+=70 trx;
    totalpayout+=70 trx;
    buyStation1(userList[startStationactiveUserID]);
    

    startStationactiveUserID++;
    startStationUserCount--;
    }
    }
    
    function buyStartStation(address payable _referrer ) public payable {
    require(!users[msg.sender].isExist, "User Exists");
    require(msg.value == 150 trx, 'Incorrect Value');
    totalinvested+=msg.value;
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
        owner.transfer(40 trx);
    if(startStationusers[startStationuserList[startStationactiveUserID]].payment_received>=3){
          startStationusers[startStationuserList[startStationactiveUserID]].payment_received=0;
      startStationuserList[startStationactiveUserID].transfer(70 trx);
      users[startStationuserList[startStationactiveUserID]].StationReward+=70 trx ;
      users[startStationuserList[startStationactiveUserID]].contractReward+=70 trx;
      totalpayout+=70 trx;
      buyStation1(userList[startStationactiveUserID]);
    

    startStationactiveUserID++;
    startStationUserCount--;
    }
    }


    
    function buyStation1(address payable _user) internal {
    require(users[_user].isExist, "User Exists");
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
        uint amount = 140 trx;
        owner.transfer(amount.div(10));
        totalpayout+=amount;
    station1userList[station1activeUserID].transfer(amount.mul(90).div(100));
    users[station1userList[station1activeUserID]].StationReward+=amount;
    users[station1userList[station1activeUserID]].contractReward+=amount;
    buyStation2(station1userList[station1activeUserID]);
    
    station1activeUserID++;
    station1UserCount--;
    }
    }


    function buyStation2(address payable _user) internal {
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
        uint amount = 280 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station2userList[station2activeUserID].transfer(amount.mul(90).div(100));
    users[station2userList[station2activeUserID]].StationReward+=amount;
    users[station2userList[station2activeUserID]].contractReward+=amount;
    buyStation3(station2userList[station2activeUserID]);    

    station2activeUserID++;
    station2UserCount--;
    }
    }
    function buyStation3(address payable _user) internal {
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
        uint amount = 560 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station3userList[station3activeUserID].transfer(amount.mul(90).div(100));
    users[station3userList[station3activeUserID]].StationReward+=amount;
    users[station3userList[station3activeUserID]].contractReward+=amount;
    buyStation4(station3userList[station3activeUserID]);

    station3activeUserID++;
    station3UserCount--;
    }
    }

    function buyStation4(address payable _user) internal {

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
        uint amount = 1120 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station4userList[station4activeUserID].transfer(amount.mul(90).div(100) );
    users[station4userList[station4activeUserID]].StationReward+=amount;
    users[station4userList[station4activeUserID]].contractReward+=amount;
    buyStation5(station4userList[station4activeUserID]);
    
    station4activeUserID++;
    station4UserCount--;
    }    
    }
    
    function buyStation5(address payable _user) internal {

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
        uint amount = 2240 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station5userList[station5activeUserID].transfer(amount.mul(90).div(100));
    users[station5userList[station5activeUserID]].StationReward+=amount;
    users[station5userList[station5activeUserID]].contractReward+=amount;
    buyStation6(station5userList[station5activeUserID]);
    
    station5activeUserID++;
    station5UserCount--;
    }    
    }
    
    function buyStation6(address payable _user) internal {

    station6currUserID++;
    station6UserCount++;
        station6users[_user] = StationUserStruct({
            isExist: true,
            id: station6currUserID,
            payment_received: 0
        });
    station6userList[station6currUserID] = _user;
        
                                

    station6users[station6userList[station6activeUserID]].payment_received+=1;
    if(station6users[station6userList[station6activeUserID]].payment_received>=3){
    station6users[station6userList[station6activeUserID]].payment_received=0;
        uint amount = 4480 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station6userList[station6activeUserID].transfer(amount.mul(90).div(100));
    users[station6userList[station6activeUserID]].StationReward+=amount;
    users[station6userList[station6activeUserID]].contractReward+=amount;
    buyStation7(station6userList[station6activeUserID]);
    
    station6activeUserID++;
    station6UserCount--;
    }    
    }
    function buyStation7(address payable _user) internal {

    station7currUserID++;
    station7UserCount++;
        station7users[_user] = StationUserStruct({
            isExist: true,
            id: station7currUserID,
            payment_received: 0
        });
    station7userList[station7currUserID] = _user;
        
                                

    station7users[station7userList[station7activeUserID]].payment_received+=1;
    if(station7users[station7userList[station7activeUserID]].payment_received>=3){
    station7users[station7userList[station7activeUserID]].payment_received=0;
        uint amount = 8960 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station7userList[station7activeUserID].transfer(amount.mul(90).div(100));
    users[station7userList[station7activeUserID]].StationReward+=amount;
    users[station7userList[station7activeUserID]].contractReward+=amount;
    buyStation8(station7userList[station7activeUserID]);
    
    station7activeUserID++;
    station7UserCount--;
    }    
    }
    
    function buyStation8(address payable _user) internal {

    station8currUserID++;
    station8UserCount++;
        station8users[_user] = StationUserStruct({
            isExist: true,
            id: station8currUserID,
            payment_received: 0
        });
    station8userList[station8currUserID] = _user;
        
                                

    station8users[station8userList[station8activeUserID]].payment_received+=1;
    if(station8users[station8userList[station8activeUserID]].payment_received>=3){
    station8users[station8userList[station8activeUserID]].payment_received=0;
        uint amount = 17920 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station8userList[station8activeUserID].transfer(amount.mul(90).div(100));
    users[station8userList[station8activeUserID]].StationReward+=amount;
    users[station8userList[station8activeUserID]].contractReward+=amount;
    buyStation9(station8userList[station8activeUserID]);
    
    station8activeUserID++;
    station8UserCount--;
    }    
    }
    
    function buyStation9(address payable _user) internal {

    station9currUserID++;
    station9UserCount++;
        station9users[_user] = StationUserStruct({
            isExist: true,
            id: station9currUserID,
            payment_received: 0
        });
    station9userList[station9currUserID] = _user;
        
                                

    station9users[station9userList[station9activeUserID]].payment_received+=1;
    if(station9users[station9userList[station9activeUserID]].payment_received>=3){
    station9users[station9userList[station9activeUserID]].payment_received=0;
        uint amount = 35840 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station9userList[station9activeUserID].transfer(amount.mul(90).div(100));
    users[station9userList[station9activeUserID]].StationReward+=amount;
    users[station9userList[station9activeUserID]].contractReward+=amount;
    buyStation10(station9userList[station9activeUserID]);
    
    station9activeUserID++;
    station9UserCount--;
    }    
    }
    
    function buyStation10(address payable _user) internal {

    station10currUserID++;
    station10UserCount++;
        station10users[_user] = StationUserStruct({
            isExist: true,
            id: station10currUserID,
            payment_received: 0
        });
    station10userList[station10currUserID] = _user;
        
                                

    station10users[station10userList[station10activeUserID]].payment_received+=1;
    if(station10users[station10userList[station10activeUserID]].payment_received>=3){
    station10users[station10userList[station10activeUserID]].payment_received=0;
        uint amount = 71680 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station10userList[station10activeUserID].transfer(amount.mul(90).div(100));
    users[station10userList[station10activeUserID]].StationReward+=amount;
    users[station10userList[station10activeUserID]].contractReward+=amount;
    buyStation11(station10userList[station10activeUserID]);
    
    station10activeUserID++;
    station10UserCount--;
    }    
    }
    
    function buyStation11(address payable _user) internal {

    station11currUserID++;
    station11UserCount++;
        station11users[_user] = StationUserStruct({
            isExist: true,
            id: station11currUserID,
            payment_received: 0
        });
    station11userList[station11currUserID] = _user;
        
                                

    station11users[station11userList[station11activeUserID]].payment_received+=1;
    if(station11users[station11userList[station11activeUserID]].payment_received>=3){
    station11users[station11userList[station11activeUserID]].payment_received=0;
        uint amount = 143360 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station11userList[station11activeUserID].transfer(amount.mul(90).div(100));
    users[station11userList[station11activeUserID]].StationReward+=amount;
    users[station11userList[station11activeUserID]].contractReward+=amount;
    buyStation12(station11userList[station11activeUserID]);
    
    station11activeUserID++;
    station11UserCount--;
    }    
    }
    
    function buyStation12(address payable _user) internal {

    station12currUserID++;
    station12UserCount++;
        station12users[_user] = StationUserStruct({
            isExist: true,
            id: station12currUserID,
            payment_received: 0
        });
    station12userList[station12currUserID] = _user;
        
                                

    station12users[station12userList[station12activeUserID]].payment_received+=1;
    if(station12users[station12userList[station12activeUserID]].payment_received>=3){
    station12users[station12userList[station12activeUserID]].payment_received=0;
        uint amount = 286720 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station12userList[station12activeUserID].transfer(amount.mul(90).div(100));
    users[station12userList[station12activeUserID]].StationReward+=amount;
    users[station12userList[station12activeUserID]].contractReward+=amount;
    buyStation13(station12userList[station12activeUserID]);
    
    station12activeUserID++;
    station12UserCount--;
    }    
    }
    
    function buyStation13(address payable _user) internal {

    station13currUserID++;
    station13UserCount++;
        station13users[_user] = StationUserStruct({
            isExist: true,
            id: station13currUserID,
            payment_received: 0
        });
    station13userList[station13currUserID] = _user;
        
                                

    station13users[station13userList[station13activeUserID]].payment_received+=1;
    if(station13users[station13userList[station13activeUserID]].payment_received>=3){
    station13users[station13userList[station13activeUserID]].payment_received=0;
        uint amount = 573440 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station13userList[station13activeUserID].transfer(amount.mul(90).div(100));
    users[station13userList[station13activeUserID]].StationReward+=amount;
    users[station13userList[station13activeUserID]].contractReward+=amount;
    buyStation14(station13userList[station13activeUserID]);
    
    station13activeUserID++;
    station13UserCount--;
    }    
    }
    
    function buyStation14(address payable _user) internal {
    station14currUserID++;
    station14UserCount++;
        station14users[_user] = StationUserStruct({
            isExist: true,
            id: station14currUserID,
            payment_received: 0
        });
    station14userList[station14currUserID] = _user;
        
                                

    station14users[station14userList[station14activeUserID]].payment_received+=1;
    if(station14users[station14userList[station14activeUserID]].payment_received>=3){
    station14users[station14userList[station14activeUserID]].payment_received=0;
        uint amount = 1146880 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station14userList[station14activeUserID].transfer(amount.mul(90).div(100));
    users[station14userList[station14activeUserID]].StationReward+=amount;
    users[station14userList[station14activeUserID]].contractReward+=amount;
    buyStation15(station14userList[station14activeUserID]);
    
    station14activeUserID++;
    station14UserCount--;
    }    
    }
    
    function buyStation15(address payable _user) internal {

    station15currUserID++;
    station15UserCount++;
        station15users[_user] = StationUserStruct({
            isExist: true,
            id: station15currUserID,
            payment_received: 0
        });
    station15userList[station15currUserID] = _user;
        
                                

    station15users[station15userList[station15activeUserID]].payment_received+=1;
    if(station15users[station15userList[station15activeUserID]].payment_received>=3){
    station15users[station15userList[station15activeUserID]].payment_received=0;
        uint amount = 2293760 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station15userList[station15activeUserID].transfer(amount.mul(90).div(100));
    users[station15userList[station15activeUserID]].StationReward+=amount;
    users[station15userList[station15activeUserID]].contractReward+=amount;
    buyStation16(station15userList[station15activeUserID]);
    
    station15activeUserID++;
    station15UserCount--;
    }    
    }
    
    function buyStation16(address payable _user) internal {

    station16currUserID++;
    station16UserCount++;
        station16users[_user] = StationUserStruct({
            isExist: true,
            id: station16currUserID,
            payment_received: 0
        });
    station16userList[station16currUserID] = _user;
        
                                

    station16users[station16userList[station16activeUserID]].payment_received+=1;
    if(station16users[station16userList[station16activeUserID]].payment_received>=3){
    station16users[station16userList[station16activeUserID]].payment_received=0;
        uint amount = 4587520 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station16userList[station16activeUserID].transfer(amount.mul(90).div(100));
    users[station16userList[station16activeUserID]].StationReward+=amount;
    users[station16userList[station16activeUserID]].contractReward+=amount;
    buyStation17(station16userList[station16activeUserID]);
    
    station16activeUserID++;
    station16UserCount--;
    }    
    }
    
    function buyStation17(address payable _user) internal {

    station17currUserID++;
    station17UserCount++;
        station17users[_user] = StationUserStruct({
            isExist: true,
            id: station17currUserID,
            payment_received: 0
        });
    station17userList[station17currUserID] = _user;
    station17users[station17userList[station17activeUserID]].payment_received+=1;
    if(station17users[station17userList[station17activeUserID]].payment_received>=3){
    station17users[station17userList[station17activeUserID]].payment_received=0;
        uint amount = 9175040 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station17userList[station17activeUserID].transfer(amount.mul(90).div(100));
    users[station17userList[station17activeUserID]].StationReward+=amount;
    users[station17userList[station17activeUserID]].contractReward+=amount;
    buyStation18(station17userList[station17activeUserID]);
    
    station17activeUserID++;
    station17UserCount--;
    }    
    }
    
    function buyStation18(address payable _user) internal {

    station18currUserID++;
    station18UserCount++;
        station18users[_user] = StationUserStruct({
            isExist: true,
            id: station18currUserID,
            payment_received: 0
        });
    station18userList[station18currUserID] = _user;
        
                                

    station18users[station18userList[station18activeUserID]].payment_received+=1;
    if(station18users[station18userList[station18activeUserID]].payment_received>=3){
    station18users[station18userList[station18activeUserID]].payment_received=0;
        uint amount = 18350080 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station18userList[station18activeUserID].transfer(amount.mul(90).div(100));
    users[station18userList[station18activeUserID]].StationReward+=amount;
    users[station18userList[station18activeUserID]].contractReward+=amount;
    buyStation19(station18userList[station18activeUserID]);
    
    station18activeUserID++;
    station18UserCount--;
    }    
    }
    
    function buyStation19(address payable _user) internal {

    station19currUserID++;
    station19UserCount++;
        station19users[_user] = StationUserStruct({
            isExist: true,
            id: station19currUserID,
            payment_received: 0
        });
    station19userList[station19currUserID] = _user;
        
                                

    station19users[station19userList[station19activeUserID]].payment_received+=1;
    if(station19users[station19userList[station19activeUserID]].payment_received>=3){
    station19users[station19userList[station19activeUserID]].payment_received=0;
        uint amount = 36700160 trx;
        totalpayout+=amount;
        owner.transfer(amount.div(10));
    station19userList[station19activeUserID].transfer(amount.mul(90).div(100));
    users[station19userList[station19activeUserID]].StationReward+=amount;
    users[station19userList[station19activeUserID]].contractReward+=amount;
    buyStation20(station19userList[station19activeUserID]);
    
    
    station19activeUserID++;
    station19UserCount--;
    }    
    }

    function buyStation20(address payable _user) internal {
    station20currUserID++;
    station20UserCount++;
        station20users[_user] = StationUserStruct({
            isExist: true,
            id: station20currUserID,
            payment_received: 0
            });
    station20userList[station20currUserID] = _user;
    station20users[station20userList[station20activeUserID]].payment_received+=1;
    if(station20users[station20userList[station20activeUserID]].payment_received>=3){
    station20users[station20userList[station20activeUserID]].payment_received=0;
    station1users[station20userList[station20activeUserID]].isExist=false;
    station2users[station20userList[station20activeUserID]].isExist=false;
    station3users[station20userList[station20activeUserID]].isExist=false;
    station4users[station20userList[station20activeUserID]].isExist=false;
    station5users[station20userList[station20activeUserID]].isExist=false;
    station6users[station20userList[station20activeUserID]].isExist=false;
    station7users[station20userList[station20activeUserID]].isExist=false;
    station8users[station20userList[station20activeUserID]].isExist=false;
    station9users[station20userList[station20activeUserID]].isExist=false;
    station10users[station20userList[station20activeUserID]].isExist=false;
    station11users[station20userList[station20activeUserID]].isExist=false;
    station12users[station20userList[station20activeUserID]].isExist=false;
    station13users[station20userList[station20activeUserID]].isExist=false;
    station14users[station20userList[station20activeUserID]].isExist=false;
    station15users[station20userList[station20activeUserID]].isExist=false;
    station16users[station20userList[station20activeUserID]].isExist=false;
    station17users[station20userList[station20activeUserID]].isExist=false;
    station18users[station20userList[station20activeUserID]].isExist=false;
    station19users[station20userList[station20activeUserID]].isExist=false;
    station20users[station20userList[station20activeUserID]].isExist=false;
    startStationusers[station20userList[station20activeUserID]].isExist=false;
    uint amount = 220200960 trx;
    totalpayout+=amount;
    owner.transfer(amount.div(10));
    station20userList[station20activeUserID].transfer(amount.mul(90).div(100).sub(150 trx));
    users[station20userList[station20activeUserID]].StationReward+=amount;
    users[station20userList[station20activeUserID]].contractReward+=amount;
    reInvest(station20userList[station20activeUserID]);
    station20activeUserID++;
    station20UserCount--;
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