//SourceUnit: Test.sol

pragma solidity ^0.5.8;

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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract TRC20 {
    function distribute(address reciever, uint value) public returns(bool);
}

contract Troncoin {

    struct UserStruct {
        bool isExist;
        uint id;
        uint totalDirects;
        uint referrerID;
        uint8 currentLevel;
        uint totalEarningTrx;
        address[] referral;
        address[] level_1;
        address[] level_2;
        address[] level_3;
        address[] level_4;
        address[] level_5;
        address[] level_6;
        address[] level_1_passup;
        address[] level_2_passup;
        address[] level_3_passup;
        address[] level_4_passup;
        address[] level_5_passup;
        address[] level_6_passup;
        uint[] id_level_1;
        uint[] id_level_2;
        uint[] id_level_3;
        uint[] id_level_4;
        uint[] id_level_5;
        uint[] id_level_6;
        uint[] id_level_1_passup;
        uint[] id_level_2_passup;
        uint[] id_level_3_passup;
        uint[] id_level_4_passup;
        uint[] id_level_5_passup;
        uint[] id_level_6_passup;
        mapping (uint8 => bool) levelStatus;
    }
    
    struct AutoPoolUserStruct {
        bool isExist;
        address userAddress;
        uint uniqueId;
        uint referrerID;
        uint8 currentLevel;
        uint totalEarningTrx;
        mapping (uint8 => uint[]) referral;
        mapping (uint8 => bool) levelStatus;
        mapping (uint8 => uint) reInvestCount;
    }
    
    using SafeMath for uint256;
    address public passup; 
    address public rebirth;
    uint public userCurrentId = 0;
    TRC20 Token;
    address public marketingAddress;
    uint256 constant public LEVEL_1 = 4;
    uint256 constant public LEVEL_2 = 20;
    uint256 constant public LEVEL_3 = 20;
    uint256 constant public LEVEL_4 = 20;
    uint256 constant public LEVEL_5 = 20;
    uint256 constant public LEVEL_6 = 20;
    uint256 constant public AUTOPOOL_PER = 20;

    address[] public level_1_users;
    address[] public level_2_users; 
    address[] public level_3_users; 
    address[] public level_4_users; 
    address[] public level_5_users; 
    address[] public level_6_users; 
    address[] public level_7_users; 
    address[] public level_8_users; 
    address[] public level_9_users; 
    address[] public level_10_users; 
    address[] public level_11_users; 
    address[] public level_12_users; 
    address owner;
    mapping (address => uint) level_1_usersIndex;
    mapping (address => uint) level_2_usersIndex;
    mapping (address => uint) level_3_usersIndex;
    mapping (address => uint) level_4_usersIndex;
    mapping (address => uint) level_5_usersIndex;
    mapping (address => uint) level_6_usersIndex;
    mapping (address => uint) level_7_usersIndex;
    mapping (address => uint) level_8_usersIndex;
    mapping (address => uint) level_9_usersIndex;
    mapping (address => uint) level_10_usersIndex;
    mapping (address => uint) level_11_usersIndex;
    mapping (address => uint) level_12_usersIndex;
    mapping (uint8 => uint) public autoPoolcurrentId;
    mapping (address => uint) index;
    mapping (uint8 => uint) public APId;
    mapping (uint => address) public userList;
    mapping (address => uint) public autoPoolId;
    mapping (address => UserStruct) public users;
    mapping (uint8 => uint) public levelPrice;
    mapping (uint8 => uint) public tokensForLevel;
    mapping (uint8 => mapping (uint => address)) public autoPoolUserList;
    mapping (uint => AutoPoolUserStruct) public autoPoolUniqueUsers;
    mapping (uint8 => mapping (uint => AutoPoolUserStruct)) public autoPoolUsers;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public EarnedTrx;

    
    modifier onlyOwner() {
        require(msg.sender == passup, "Only Owner");
        _;
    }
    
    event regLevelEvent(uint8 indexed Matrix, address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Time);
    event buyLevelEvent(uint8 indexed Matrix, address indexed UserAddress, uint UserId, uint8 Levelno, uint Time);
    event getMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint LevelPrice, uint Time);
    event reInvestEvent(uint8 indexed Matrix, address indexed UserAddress, uint UserId,  address indexed Caller, uint CallerId, uint8 Levelno, uint ReInvestCount, uint Time);
    event sponsorEarnedEvent(address indexed UserAddress, uint UserId, address indexed Caller, uint CallerId, uint8 Level, uint EarnAmount, uint Time);
    
    constructor(address _rebirth,address _marketingAddress,address _tokenAddress) public {
        passup = msg.sender;
        owner = msg.sender;
        rebirth = _rebirth;
        marketingAddress = _marketingAddress;
        Token = TRC20(_tokenAddress);
        levelPrice[1] = 1 trx;
        levelPrice[2] = 2 trx;
        levelPrice[3] = 3 trx;
        levelPrice[4] = 4 trx;
        levelPrice[5] = 5 trx;
        levelPrice[6] = 6 trx;
        levelPrice[7] = 7 trx;
        levelPrice[8] = 8 trx;
        levelPrice[9] = 9 trx;
        levelPrice[10] = 10 trx;
        levelPrice[11] = 11 trx;
        levelPrice[12] = 12 trx;
        tokensForLevel[1] = 100*(10**2);

        UserStruct memory userStruct;
        userCurrentId = 1;

        userStruct = UserStruct({
            isExist: true,
            id: userCurrentId,
            referrerID: 0,
            totalDirects:0,
            currentLevel:1,
            totalEarningTrx:0,
            referral: new address[](0),
            level_1: new address[](0),
            level_2: new address[](0),
            level_3: new address[](0),
            level_4: new address[](0),
            level_5: new address[](0),
            level_6: new address[](0),
            level_1_passup: new address[](0),
            level_2_passup: new address[](0),
            level_3_passup: new address[](0),
            level_4_passup: new address[](0),
            level_5_passup: new address[](0),
            level_6_passup: new address[](0),
            id_level_1: new uint[](0),
            id_level_2: new uint[](0),
            id_level_3: new uint[](0),
            id_level_4: new uint[](0),
            id_level_5: new uint[](0),
            id_level_6: new uint[](0),
            id_level_1_passup: new uint[](0),
            id_level_2_passup: new uint[](0),
            id_level_3_passup: new uint[](0),
            id_level_4_passup: new uint[](0),
            id_level_5_passup: new uint[](0),
            id_level_6_passup: new uint[](0)
        });
        users[passup] = userStruct;
        userList[userCurrentId] = passup;
        AutoPoolUserStruct memory autoPoolStruct;
        autoPoolStruct = AutoPoolUserStruct({
            isExist: true,
            userAddress: passup,
            uniqueId: userCurrentId,
            referrerID: 0,
            currentLevel: 1,
            totalEarningTrx:0
        });
        autoPoolUniqueUsers[userCurrentId] = autoPoolStruct;
        autoPoolId[passup] = userCurrentId;
        autoPoolUniqueUsers[userCurrentId].currentLevel = 12;
        users[passup].currentLevel = 12;
        for(uint8 i = 1; i <= 12; i++) {   
            users[passup].levelStatus[i] = true;
            autoPoolcurrentId[i] = 1;
            autoPoolUsers[i][autoPoolcurrentId[i]].levelStatus[i] = true;
            autoPoolUserList[i][autoPoolcurrentId[i]] = passup;
            autoPoolUsers[i][autoPoolcurrentId[i]] = autoPoolStruct;
            autoPoolUniqueUsers[userCurrentId].levelStatus[i] = true;
            APId[i] = 1;
            tokensForLevel[i] = 0;
        }
    }
   
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function register(uint _referrerID) external payable {
        
        uint _userId = autoPoolId[msg.sender];  
        require(users[msg.sender].isExist == false && autoPoolUniqueUsers[_userId].isExist ==  false, "User Exist");
        require(msg.value == levelPrice[1], "Incorrect Value");
        require(_referrerID > 0 && _referrerID <= userCurrentId, "Incorrect referrerID");
        
        // check 
        address UserAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract");
        
        userCurrentId = userCurrentId.add(1);
        userList[userCurrentId] = msg.sender;
        if(!inArrayLevel1(msg.sender)){
            level_1_usersIndex[msg.sender] = level_1_users.length;
            level_1_users.push(msg.sender);
        }
        _workPlanReg(_referrerID);
        _autoPoolReg();
    }
    
    function upgrade(uint8 _level) external payable {
        uint _userId = autoPoolId[msg.sender];
        
        require(users[msg.sender].isExist && autoPoolUniqueUsers[_userId].isExist, "User not exist"); 
        require(users[msg.sender].levelStatus[_level] ==  false && autoPoolUniqueUsers[_userId].levelStatus[_level] == false, "Already Active in this level");
        require(_level > 0 && _level <= 12, "Incorrect level");
        require(msg.value == levelPrice[_level], "Incorrect Value");
        if(_level != 1)  
        {
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].levelStatus[l] == true && autoPoolUniqueUsers[_userId].levelStatus[l] == true, "Buy the previous level");
        }    

        if(_level == 1)  
        {
           if(!inArrayLevel1(msg.sender)){
            level_1_usersIndex[msg.sender] = level_1_users.length;
            level_1_users.push(msg.sender);
           }  
        }    
        if(_level == 2)  
        {
           if(!inArrayLevel2(msg.sender)){
            level_2_usersIndex[msg.sender] = level_2_users.length;
            level_2_users.push(msg.sender);
           }  
            
        }    
        if(_level == 3)  
        {
           if(!inArrayLevel3(msg.sender)){
            level_3_usersIndex[msg.sender] = level_3_users.length;
            level_3_users.push(msg.sender);
           }   
            
        }    
        if(_level == 4)  
        {
           if(!inArrayLevel4(msg.sender)){
            level_4_usersIndex[msg.sender] = level_4_users.length;
            level_4_users.push(msg.sender);
           }    
            
        }    
        if(_level == 5)  
        {
           if(!inArrayLevel5(msg.sender)){
            level_5_usersIndex[msg.sender] = level_5_users.length;
            level_5_users.push(msg.sender);
           }
            
        }    
        if(_level == 6)  
        {
           if(!inArrayLevel6(msg.sender)){
            level_6_usersIndex[msg.sender] = level_6_users.length;
            level_6_users.push(msg.sender);
           }  
            
        }    
        if(_level == 7)  
        {
           if(!inArrayLevel7(msg.sender)){
            level_7_usersIndex[msg.sender] = level_7_users.length;
            level_7_users.push(msg.sender);
           }  
            
        }    
        if(_level == 8)  
        {
           if(!inArrayLevel8(msg.sender)){
            level_8_usersIndex[msg.sender] = level_8_users.length;
            level_8_users.push(msg.sender);
           } 
            
        }    
        if(_level == 9)  
        {
           if(!inArrayLevel9(msg.sender)){
            level_9_usersIndex[msg.sender] = level_9_users.length;
            level_9_users.push(msg.sender);
           }
            
        }    
        if(_level == 10)  
        {
           if(!inArrayLevel10(msg.sender)){
            level_10_usersIndex[msg.sender] = level_10_users.length;
            level_10_users.push(msg.sender);
           }   
            
        }    
        if(_level == 11)  
        {
           if(!inArrayLevel11(msg.sender)){
            level_11_usersIndex[msg.sender] = level_11_users.length;
            level_11_users.push(msg.sender);
           } 
            
        }    
        if(_level == 12)  
        {
           if(!inArrayLevel12(msg.sender)){
            level_12_usersIndex[msg.sender] = level_12_users.length;
            level_12_users.push(msg.sender);
           } 

        }
        
        _workPlanBuy(_level);
        _autoPoolBuy(_userId,_level);
    }
    
    function failSafe(address payable _toUser, uint _amount) onlyOwner external returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function viewWPUserReferral(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].referral;
    }

    function viewWPUserReferralID(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_1;
    }

    function viewWPIDLevel_1_income(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_1;
    }

    function viewWPIDLevel_2_income(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_2;
    }

    function viewWPIDLevel_3_income(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_3;
    }

    function viewWPIDLevel_4_income(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_4;
    }

    function viewWPIDLevel_5_income(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_5;
    }

    function viewWPIDLevel_6_income(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_6;
    }

     function viewWPIDLevel_1_passup(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_1_passup;
    }

    function viewWPIDLevel_2_passup(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_2_passup;
    }

    function viewWPIDLevel_3_passup(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_3_passup;
    }

    function viewWPIDLevel_4_passup(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_4_passup;
    }

    function viewWPIDLevel_5_passup(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_5_passup;
    }

    function viewWPIDLevel_6_passup(address _userAddress) public view returns(uint[] memory) {
        return users[_userAddress].id_level_6_passup;
    }

    function viewWPLevel_1_income(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_1;
    }

    function viewWPLevel_2_income(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_2;
    }

    function viewWPLevel_3_income(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_3;
    }

    function viewWPLevel_4_income(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_4;
    }

    function viewWPLevel_5_income(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_5;
    }

    function viewWPLevel_6_income(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_6;
    }

     function viewWPLevel_1_passup(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_1_passup;
    }

    function viewWPLevel_2_passup(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_2_passup;
    }

    function viewWPLevel_3_passup(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_3_passup;
    }

    function viewWPLevel_4_passup(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_4_passup;
    }

    function viewWPLevel_5_passup(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_5_passup;
    }

    function viewWPLevel_6_passup(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].level_6_passup;
    }

    function viewAPUserReferral(uint _userId, uint8 _level) public view returns(uint[] memory) {
        return (autoPoolUniqueUsers[_userId].referral[_level]);
    }
    
    function viewAPInternalUserReferral(uint _userId, uint8 _level) public view returns(uint[] memory) {
        return (autoPoolUsers[_level][_userId].referral[_level]);
    }

    function updateLevelToken(uint8 _level, uint _token) onlyOwner external returns (bool) {
        tokensForLevel[_level] = _token;
        return true;
    }

    function mintTokens(uint _token) onlyOwner external returns (bool) {
        Token.distribute(msg.sender, _token);
        return true;
    }

    function inArrayLevel1(address referer) public view returns (bool) {
        if(level_1_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel2(address referer) public view returns (bool) {
        if(level_2_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel3(address referer) public view returns (bool) {
        if(level_3_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel4(address referer) public view returns (bool) {
        if(level_4_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel5(address referer) public view returns (bool) {
        if(level_5_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel6(address referer) public view returns (bool) {
        if(level_6_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel7(address referer) public view returns (bool) {
        if(level_7_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel8(address referer) public view returns (bool) {
        if(level_8_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel9(address referer) public view returns (bool) {
        if(level_9_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel10(address referer) public view returns (bool) {
        if(level_10_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel11(address referer) public view returns (bool) {
        if(level_11_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }

    function inArrayLevel12(address referer) public view returns (bool) {
        if(level_12_usersIndex[referer] >0){
            return true;
        }
        else{
            return false;
        }
    }
    
    function viewUserLevelStatus(address _userAddress, uint8 _matrix, uint8 _level) public view returns(bool) {
        
        if(_matrix == 1)        
            return users[_userAddress].levelStatus[_level];
            
        if(_matrix == 2) {
            uint256 _userId = autoPoolId[_userAddress];        
            return autoPoolUniqueUsers[_userId].levelStatus[_level];
        }
        
    }

    function viewLevel_1_users() public view returns(address[] memory){
        return level_1_users;
    }

    function viewLevel_2_users() public view returns(address[] memory){
        return level_2_users;
    }

    function viewLevel_3_users() public view returns(address[] memory){
        return level_3_users;
    }

    function viewLevel_4_users() public view returns(address[] memory){
        return level_4_users;
    }

    function viewLevel_5_users() public view returns(address[] memory){
        return level_5_users;
    }

    function viewLevel_6_users() public view returns(address[] memory){
        return level_6_users;
    }

    function viewLevel_7_users() public view returns(address[] memory){
        return level_7_users;
    }

    function viewLevel_8_users() public view returns(address[] memory){
        return level_8_users;
    }

    function viewLevel_9_users() public view returns(address[] memory){
        return level_9_users;
    }

    function viewLevel_10_users() public view returns(address[] memory){
        return level_10_users;
    }

    function viewLevel_11_users() public view returns(address[] memory){
        return level_11_users;
    }

    function viewLevel_12_users() public view returns(address[] memory){
        return level_12_users;
    }
    
    function viewAPUserReInvestCount(uint _userId, uint8 _level) public view returns(uint) {
        return autoPoolUniqueUsers[_userId].reInvestCount[_level];
    }
   
    function getTotalEarnedTrx(uint8 _matrix) public view returns(uint) {
        uint totalTrx;
        if(_matrix == 1)
        {
            for( uint i=1;i<=userCurrentId;i++) {
                totalTrx = totalTrx.add(users[userList[i]].totalEarningTrx);
            }
        }
        else if(_matrix == 2)
        {
            for( uint i = 1; i <= userCurrentId; i++) {
                totalTrx = totalTrx.add(autoPoolUniqueUsers[i].totalEarningTrx);
            }   
        }
        return totalTrx;
    }
   
    function _workPlanReg(uint _referrerID) internal  {
        
        address referer = userList[_referrerID];
        
        UserStruct memory userStruct;
        
        userStruct = UserStruct({
            isExist: true,
            id: userCurrentId,
            referrerID: _referrerID,
            totalDirects:0,
            currentLevel:1,
            totalEarningTrx:0,
            referral: new address[](0),
            level_1: new address[](0),
            level_2: new address[](0),
            level_3: new address[](0),
            level_4: new address[](0),
            level_5: new address[](0),
            level_6: new address[](0),
            level_1_passup: new address[](0),
            level_2_passup: new address[](0),
            level_3_passup: new address[](0),
            level_4_passup: new address[](0),
            level_5_passup: new address[](0),
            level_6_passup: new address[](0),
            id_level_1: new uint[](0),
            id_level_2: new uint[](0),
            id_level_3: new uint[](0),
            id_level_4: new uint[](0),
            id_level_5: new uint[](0),
            id_level_6: new uint[](0),
            id_level_1_passup: new uint[](0),
            id_level_2_passup: new uint[](0),
            id_level_3_passup: new uint[](0),
            id_level_4_passup: new uint[](0),
            id_level_5_passup: new uint[](0),
            id_level_6_passup: new uint[](0)
        });

        users[msg.sender] = userStruct;
        users[msg.sender].levelStatus[1] = true;
        users[referer].referral.push(msg.sender);
        _workPlanPay(0,1, msg.sender);
        emit regLevelEvent(1, msg.sender, userCurrentId, userList[_referrerID], _referrerID, now);
    }
    
    function _autoPoolReg() internal  {
        
        uint _referrerID;
        
        for(uint i = APId[1]; i <= autoPoolcurrentId[1]; i++) {
            if(autoPoolUsers[1][i].referral[1].length < 9) {
                _referrerID = i; 
                break;
            }
            else if(autoPoolUsers[1][i].referral[1].length == 9) {
                APId[1] = i;
                continue;
            }
        }
        
        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[1] = autoPoolcurrentId[1].add(1);
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            userAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningTrx:0
        });

        autoPoolUsers[1][autoPoolcurrentId[1]] = nonWorkUserStruct;
        autoPoolUserList[1][autoPoolcurrentId[1]] = msg.sender;
        autoPoolUsers[1][autoPoolcurrentId[1]].levelStatus[1] = true;
        autoPoolUsers[1][autoPoolcurrentId[1]].reInvestCount[1] = 0;
        
        autoPoolUniqueUsers[userCurrentId] = nonWorkUserStruct;
        autoPoolId[msg.sender] = userCurrentId;
        autoPoolUniqueUsers[userCurrentId].referral[1] = new uint[](0);
        autoPoolUniqueUsers[userCurrentId].levelStatus[1] = true;
        autoPoolUniqueUsers[userCurrentId].reInvestCount[1] = 0;
        
        autoPoolUsers[1][_referrerID].referral[1].push(autoPoolcurrentId[1]);
        autoPoolUniqueUsers[autoPoolId[autoPoolUsers[1][_referrerID].userAddress]].referral[1].push(userCurrentId);
        
        _updateNWDetails(_referrerID,1);
        emit regLevelEvent(2, msg.sender, userCurrentId, autoPoolUserList[1][_referrerID], _referrerID, now);
    }
    
    function _workPlanBuy(uint8 _level) internal  {
       
        users[msg.sender].levelStatus[_level] = true;
        users[msg.sender].currentLevel = _level;
       
        _workPlanPay(0,_level, msg.sender);
        emit buyLevelEvent(1, msg.sender, users[msg.sender].id, _level, now);
    }
    
    function _autoPoolBuy(uint _userId, uint8 _level) internal  {
        
        uint _referrerID;
        
        for(uint i = APId[_level]; i <= autoPoolcurrentId[_level]; i++) {
            if(autoPoolUsers[_level][i].referral[_level].length < 7) {
                _referrerID = i; 
                break;
            }
            else if(autoPoolUsers[_level][i].referral[_level].length == 7) {
                APId[_level] = i;
                continue;
            }
        }
        
        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[_level] = autoPoolcurrentId[_level].add(1);
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            userAddress: msg.sender,
            uniqueId: _userId,
            referrerID: _referrerID,
            currentLevel: _level,
            totalEarningTrx:0
        });
            
        autoPoolUsers[_level][autoPoolcurrentId[_level]] = nonWorkUserStruct;
        autoPoolUserList[_level][autoPoolcurrentId[_level]] = msg.sender;
        autoPoolUsers[_level][autoPoolcurrentId[_level]].levelStatus[_level] = true;
        
        autoPoolUniqueUsers[_userId].levelStatus[_level] = true;
        autoPoolUniqueUsers[_userId].currentLevel = _level;
        autoPoolUniqueUsers[_userId].referral[_level] = new uint[](0);
        autoPoolUniqueUsers[_userId].reInvestCount[_level] = 0;
        
        autoPoolUsers[_level][_referrerID].referral[_level].push(autoPoolcurrentId[_level]);
        autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].referral[_level].push(autoPoolId[autoPoolUsers[_level][autoPoolcurrentId[_level]].userAddress]);
        
        _updateNWDetails(_referrerID,_level);
        emit buyLevelEvent(2, msg.sender, _userId, _level, now);
    }
    
    function _updateNWDetails(uint _referrerID, uint8 _level) internal {
        
        autoPoolUsers[_level][autoPoolcurrentId[_level]].referral[_level] = new uint[](0);
        
        if(autoPoolUsers[_level][_referrerID].referral[_level].length == 8) {
            _autoPoolPay(1,_level,autoPoolcurrentId[_level]);
            if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].levelStatus[_level] = true 
                && autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level] < 5) {
                _reInvest(_referrerID,_level);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].referral[_level] = new uint[](0);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level] =  autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level].add(1);
                
                emit reInvestEvent(2, autoPoolUserList[_level][_referrerID], autoPoolId[autoPoolUserList[_level][_referrerID]],  msg.sender,
               autoPoolId[msg.sender], _level, autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level], now);
            }
            else if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level] == 5) {
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].levelStatus[_level] = false;
                users[autoPoolUsers[_level][_referrerID].userAddress].levelStatus[_level] = false;
            }
        }
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 1) 
            _autoPoolPay(1,_level,autoPoolcurrentId[_level]);
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 2) 
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 3) 
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 4) 
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 5) 
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 6) 
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 7) 
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
    }
     
    function _reInvest(uint _refId, uint8 _level) internal  {
        
        uint _reInvestId;
       
        for(uint i = APId[_level]; i <= autoPoolcurrentId[_level]; i++) {
            
            if(autoPoolUsers[_level][i].referral[_level].length < 9) {
                _reInvestId = i; 
                break;
            }
            else if(autoPoolUsers[_level][i].referral[_level].length == 9) {
                APId[_level] = i;
                continue;
            }
            
        }
        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[_level] = autoPoolcurrentId[_level].add(1);
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            userAddress: autoPoolUserList[_level][_refId],
            uniqueId: autoPoolUsers[_level][_refId].uniqueId,
            referrerID: _reInvestId,
            currentLevel: _level,
            totalEarningTrx:0
        });
            
        autoPoolUsers[_level][autoPoolcurrentId[_level]] = nonWorkUserStruct;
        autoPoolUserList[_level][autoPoolcurrentId[_level]] = autoPoolUserList[_level][_refId];
        autoPoolUsers[_level][autoPoolcurrentId[_level]].levelStatus[_level] = true;
        
        autoPoolUsers[_level][_reInvestId].referral[_level].push(autoPoolcurrentId[_level]);
        autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].referral[_level].push(autoPoolId[autoPoolUsers[_level][autoPoolcurrentId[_level]].userAddress]);
        
        autoPoolUsers[_level][autoPoolcurrentId[_level]].referral[_level] = new uint[](0);
        
        if(autoPoolUsers[_level][_reInvestId].referral[_level].length == 3) {
            
            if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].levelStatus[_level] = true 
                && autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level] < 5) {
                _reInvest(_reInvestId,_level);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].referral[_level] = new uint[](0);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level] =  autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level].add(1);
                emit reInvestEvent(2, autoPoolUsers[_level][_reInvestId].userAddress , autoPoolId[autoPoolUserList[_level][_reInvestId]], msg.sender, autoPoolId[msg.sender], _level, 
                    autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level], now);
            }
            else if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level] == 5) {
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].levelStatus[_level] = false;
                users[autoPoolUsers[_level][_reInvestId].userAddress].levelStatus[_level] = false;
            }
            
        }
       
    }
    
    function _getReferrer(uint8 _level, address _user) internal returns (address) {
        if (_level == 0 || _user == address(0)) {
            return _user;
        }
        
        return _getReferrer( _level - 1,userList[users[_user].referrerID]);
    }

    function getID(address _user) internal returns (uint){
         return users[_user].id;
    }

    function _workPlanPay(uint8 _flag, uint8 _level, address _userAddress) internal {
        
        address referer;
        uint refererID;
        for(uint8 i = 1; i <= 6; i++) {   
            uint256 _sharePercentage;
            if(i == 1){
                _sharePercentage = LEVEL_1;
            }
            if(i == 2){
                _sharePercentage = LEVEL_2;
            }
            if(i == 3){
                _sharePercentage = LEVEL_3;
            }
            if(i == 4){
                _sharePercentage = LEVEL_4;
            }
            if(i == 5){
                _sharePercentage = LEVEL_5;
            }
             if(i == 6){
                _sharePercentage = LEVEL_6;
            }
            if(_flag == 0){
                 referer = _getReferrer(i,_userAddress);
                 refererID = getID(referer);
             }
            else if(_flag == 1){ 
                 referer = passup;
                 refererID = getID(referer);
             }

            if(users[referer].isExist == false){ 
                 referer = passup;
                 refererID = getID(referer);
             }
            address level_income = userList[refererID];
            if(users[referer].levelStatus[_level] == true) {  
                if(i == 1){
                users[level_income].level_1.push(msg.sender);
                users[level_income].id_level_1.push(users[msg.sender].id);
                }

                if(i == 2){
                users[level_income].level_2.push(msg.sender);
                users[level_income].id_level_2.push(users[msg.sender].id);
                }

                if(i == 3){
                users[level_income].level_3.push(msg.sender);
                users[level_income].id_level_3.push(users[msg.sender].id);
                }

                if(i == 4){
                users[level_income].level_4.push(msg.sender);
                users[level_income].id_level_4.push(users[msg.sender].id);
                }

                if(i == 5){
                users[level_income].level_5.push(msg.sender);
                users[level_income].id_level_5.push(users[msg.sender].id);
                }

                if(i == 6){
                users[level_income].level_6.push(msg.sender);
                users[level_income].id_level_6.push(users[msg.sender].id);
                }

                uint _share = (levelPrice[_level]).div(_sharePercentage);
                require((address(uint160(referer)).send(_share)), "Transaction Failure");
                users[referer].totalEarningTrx = users[referer].totalEarningTrx.add(_share);
                EarnedTrx[referer][i][_level] =  EarnedTrx[referer][i][_level].add(_share);
                emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, referer, users[referer].id, _level, _share, now);
            }
            else {
                if(i == 1){
                users[level_income].level_1_passup.push(msg.sender);
                users[level_income].id_level_1_passup.push(users[msg.sender].id);
                }

                if(i == 2){
                users[level_income].level_2_passup.push(msg.sender);
                users[level_income].id_level_2_passup.push(users[msg.sender].id);
                }

                if(i == 3){
                users[level_income].level_3_passup.push(msg.sender);
                users[level_income].id_level_3_passup.push(users[msg.sender].id);
                }

                if(i == 4){
                users[level_income].level_4_passup.push(msg.sender);
                users[level_income].id_level_4_passup.push(users[msg.sender].id);
                }

                if(i == 5){
                users[level_income].level_5_passup.push(msg.sender);
                users[level_income].id_level_5_passup.push(users[msg.sender].id);
                }

                if(i == 6){
                users[level_income].level_6_passup.push(msg.sender);
                users[level_income].id_level_6_passup.push(users[msg.sender].id);
                }

                referer = passup;
                uint _share = (levelPrice[_level]).div(_sharePercentage);
                require((address(uint160(referer)).send(_share)), "Transaction Failure");
                emit lostMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, referer, users[referer].id, _level, _share, now);
            }
      }
    }
    
    function _autoPoolPay(uint8 _flag, uint8 _level, uint _userId) internal {
        uint refId;
        address userAdd;
        address sponsorAddress;
        address refererAddress;
        if(_flag == 0){
          refId = autoPoolUsers[_level][_userId].referrerID;
        }
        if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][refId].userAddress]].levelStatus[_level] = true|| _flag == 1 || _flag == 2 || _flag == 4) {
            uint _share_a = (levelPrice[_level]).mul(7);
            uint _share = _share_a.div(AUTOPOOL_PER);
            uint tobeminted = tokensForLevel[_level];
            if(_flag == 1){
                 refererAddress = rebirth;
            }
            else if(_flag == 2){
                 userAdd = autoPoolUsers[_level][_userId].userAddress;
                 sponsorAddress = _getReferrer(1,userAdd);
                 refererAddress = sponsorAddress;
            }
            else if(_flag == 4){
                 refererAddress = marketingAddress;
             }
            else{
                 refererAddress = autoPoolUserList[_level][refId];
             }

            require((address(uint160(refererAddress)).send(_share)) && (Token.distribute(msg.sender, tobeminted)), "Transaction Failure");
            autoPoolUniqueUsers[autoPoolId[refererAddress]].totalEarningTrx = autoPoolUniqueUsers[autoPoolId[refererAddress]].totalEarningTrx.add(_share);
            EarnedTrx[refererAddress][7][_level] =  EarnedTrx[refererAddress][7][_level].add(_share);
            emit getMoneyForLevelEvent(2, msg.sender, autoPoolId[msg.sender], refererAddress, autoPoolId[refererAddress], _level, _share, now);
        }
        else {
            uint _share = (levelPrice[_level]).mul(AUTOPOOL_PER);
            refId = autoPoolUsers[_level][_userId].referrerID;
            refererAddress = autoPoolUserList[_level][refId];
            
            emit lostMoneyForLevelEvent(2, msg.sender, autoPoolId[msg.sender], refererAddress, autoPoolId[refererAddress], _level, _share, now);
            _autoPoolPay(1, _level, refId);
            
        }
    }
}