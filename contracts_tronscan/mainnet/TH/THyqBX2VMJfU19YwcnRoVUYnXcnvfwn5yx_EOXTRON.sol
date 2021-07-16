//SourceUnit: EOXTRON.sol

pragma solidity 0.5.9;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract TRC20 {
    mapping (address => uint) public balances;
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function transfer(address to, uint value) public returns(bool);
    function allowance(address owner, address spender) public view returns (uint);
    event Transfer(address indexed _from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract EOXTRON {
    
    struct UserStruct {
        bool isExist;
        uint id;
        address referrer;
        uint partnersCount;
        mapping (uint8 => X3Struct) X3Matrix;
        mapping (uint8 => X4Struct) X4Matrix;
        mapping (uint8 => uint8) currentLevel;
    }
    
    struct X4Struct{
        address UserAddress;
        uint uniqueId;
        address currentReferrer;
        uint[] referrals;
        bool levelStatus;
        uint reInvestCount;
    }
    
    struct X3Struct{
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] firstLineRef;
        uint[] secondLineRef;
        bool levelStatus;
        uint reInvestCount;
    }
    
    using SafeMath for uint;
    uint8 public LAST_LEVEL = 12;
    address public ownerAddress; 
    TRC20 public Token;
    uint public userCurrentId = 1;
    bool public lockStatus;
    
    mapping (address => uint)  ownerBal;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint8 => uint)) public totalEarnedTrx;
    mapping (uint8 => mapping (uint8 => uint)) public levelPrice;
    mapping (uint8 => mapping (uint8 => uint)) public levelBasedTokens;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public earnedTrx;
    mapping (address => mapping (uint8 => uint)) public totalEarnedEox;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public earnedEox;
    mapping (address => mapping(uint8 => uint)) public rewardEarned;
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
      
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    
    event regLevelEvent(uint8 indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(uint8 indexed Matrix, address indexed UserAddress, uint8 Levelno, uint Time);
    event getMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event lostMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event reInvestEvent(uint8 indexed Matrix, address indexed UserAddress,address indexed CallerAddress, uint8 Levelno, uint ReInvestCount, uint Time);
    event adminDepositEvent(address TokenAddress, uint DepositedAmount, uint Time);
    
    constructor(address _tokenAddress) public {
        ownerAddress = msg.sender;
        Token = TRC20(_tokenAddress);
        
        // x3LevelPrice
        levelPrice[1][1] = 150 trx;
        levelPrice[1][2] = 250 trx;
        levelPrice[1][3] = 500 trx;
        levelPrice[1][4] = 1000 trx;
        levelPrice[1][5] = 2000 trx;
        levelPrice[1][6] = 4000 trx;
        levelPrice[1][7] = 8000 trx;
        levelPrice[1][8] = 15000 trx;
        levelPrice[1][9] = 25000 trx;
        levelPrice[1][10] = 50000 trx;
        levelPrice[1][11] = 75000 trx;
        levelPrice[1][12] = 100000 trx;
       
        // x3LevelBasedTokens
        levelBasedTokens[1][1] = 1.5   * (10**6);
        levelBasedTokens[1][2] = 2.5   * (10**6);
        levelBasedTokens[1][3] = 5     * (10**6);
        levelBasedTokens[1][4] = 10    * (10**6);
        levelBasedTokens[1][5] = 20    * (10**6);
        levelBasedTokens[1][6] = 40    * (10**6);
        levelBasedTokens[1][7] = 80    * (10**6);
        levelBasedTokens[1][8] = 150   * (10**6);
        levelBasedTokens[1][9] = 250   * (10**6);
        levelBasedTokens[1][10] = 500  * (10**6);
        levelBasedTokens[1][11] = 750  * (10**6);
        levelBasedTokens[1][12] = 1000 * (10**6);
        
        // x4LevelPrice
        levelPrice[2][1] = 100 trx;
        levelPrice[2][2] = 200 trx;
        levelPrice[2][3] = 400 trx;
        levelPrice[2][4] = 800 trx;
        levelPrice[2][5] = 1600 trx;
        levelPrice[2][6] = 3200 trx;
        levelPrice[2][7] = 6400 trx;
        levelPrice[2][8] = 10000 trx;
        levelPrice[2][9] = 20000 trx;
        levelPrice[2][10] = 30000 trx;
        levelPrice[2][11] = 40000 trx;
        levelPrice[2][12] = 50000 trx;
        
        // x4LevelBasedTokens
        levelBasedTokens[2][1] = 1    * (10**6);
        levelBasedTokens[2][2] = 2    * (10**6);
        levelBasedTokens[2][3] = 4    * (10**6);
        levelBasedTokens[2][4] = 8    * (10**6);
        levelBasedTokens[2][5] = 16   * (10**6);
        levelBasedTokens[2][6] = 32   * (10**6);
        levelBasedTokens[2][7] = 64   * (10**6);
        levelBasedTokens[2][8] = 100  * (10**6);
        levelBasedTokens[2][9] = 200  * (10**6);
        levelBasedTokens[2][10] = 300 * (10**6);
        levelBasedTokens[2][11] = 400 * (10**6);
        levelBasedTokens[2][12] = 500 * (10**6);
            
        users[ownerAddress].isExist = true;
        users[ownerAddress].id = userCurrentId;
        users[ownerAddress].referrer = address(0);
        userList[userCurrentId] = ownerAddress;
        
        X3Struct memory x3UserDetails;
    
        x3UserDetails = X3Struct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            referrerID: 0,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        
        X4Struct memory x4UserDetails;
    
        x4UserDetails = X4Struct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            currentReferrer: address(0),
            referrals: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[ownerAddress].currentLevel[1] = LAST_LEVEL;
        users[ownerAddress].currentLevel[2] = LAST_LEVEL;
            
        for(uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].X3Matrix[i] = x3UserDetails;
            users[ownerAddress].X4Matrix[i] = x4UserDetails;
        }
        
    }
   
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function adminTrxDeposit() external onlyOwner payable {
        ownerBal[address(0)] = ownerBal[address(0)].add(msg.value);
        emit adminDepositEvent(address(0),msg.value,now);
    }
    
    function adminTokenDeposit(uint _amount) external onlyOwner  {
        Token.transferFrom(msg.sender,address(this),_amount);
        ownerBal[address(Token)] = ownerBal[address(Token)].add(_amount); 
        emit adminDepositEvent(address(Token),_amount,now);
    }
    
    function shareRewards(uint8 _flag, address[] calldata _users, uint[] calldata _amount) external onlyOwner {
        for(uint8 i=0; i< _users.length; i++) {
            require(users[_users[i]].isExist == true, "User Doesnot Exist");
            require(_amount[i] > 0, "Amount is not valid");
        
            if(_flag == 1) {
                require(Token.transfer(_users[i],_amount[i]), "Insufficient Contract Balance - Token");
                rewardEarned[_users[i]][1] = rewardEarned[_users[i]][1].add(_amount[i]);
                ownerBal[address(Token)] = ownerBal[address(Token)].sub(_amount[i]);
            }
            
            else {
                require(address(uint160(_users[i])).send(_amount[i]), "Insufficient Contract Balance - Trx");
                rewardEarned[_users[i]][2] = rewardEarned[_users[i]][2].add(_amount[i]);
                ownerBal[address(0)] = ownerBal[address(0)].sub(_amount[i]);
            }
        }
    }
    
    function viewOwnerBal() public onlyOwner view returns(uint TrxBal, uint TokenBal) {
        TrxBal = ownerBal[address(0)];
        TokenBal = ownerBal[address(Token)];
    }
    
    function registration(uint _referrerID) external isLock payable{
        require(users[msg.sender].isExist == false, "User Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
        require(msg.value == levelPrice[1][1].add(levelPrice[2][1]),"Incorrect Value");
        
        // check 
        address UserAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract");
        
        
        UserStruct memory userData;
        userCurrentId = userCurrentId.add(1);
        
        userData = UserStruct ({
            isExist: true,
            id: userCurrentId,
            referrer: userList[_referrerID],
            partnersCount: 0
        });
        
        users[msg.sender]= userData;
        userList[userCurrentId] = msg.sender;
        users[userList[_referrerID]].partnersCount = users[userList[_referrerID]].partnersCount.add(1);
        
        
        _x3Registration(_referrerID);
        _x4Registration(_referrerID);
    }
    
    function x3BuyLevel(uint8 _level) external isLock payable {
        require(_level > 0 && _level <= LAST_LEVEL, "Incorrect level");
        require(users[msg.sender].isExist ==  true, "User not exist");
        require(users[msg.sender].X3Matrix[_level].levelStatus == false, "Already Active in this level");
        require(msg.value == levelPrice[1][_level], "Incorrect Value");
        
        if(_level != 1) {   
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].X3Matrix[l].levelStatus == true, "Buy the previous level");
        }
       
        uint firstLineId;
        uint secondLineId = _getX3Referrer(msg.sender,_level);
        
       if(users[userList[secondLineId]].X3Matrix[_level].firstLineRef.length < 3) {
            firstLineId = secondLineId;
            secondLineId = users[userList[firstLineId]].X3Matrix[_level].referrerID;
        }
        
        else if(users[userList[secondLineId]].X3Matrix[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findX3Referrer(_level,secondLineId);
        }
        
        X3Struct memory s1UserDetails;
        
        s1UserDetails = X3Struct({
            UserAddress: msg.sender,
            uniqueId: users[msg.sender].id,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].X3Matrix[_level] = s1UserDetails;
        users[msg.sender].currentLevel[1]  = _level;
        
        users[userList[firstLineId]].X3Matrix[_level].firstLineRef.push(users[msg.sender].id);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].X3Matrix[_level].secondLineRef.push(users[msg.sender].id);
        
        _updateX3Details(secondLineId, msg.sender,_level);
        
        emit buyLevelEvent(1,msg.sender, _level, now);
    }
    
    function x4BuyLevel(uint8 _level) external isLock payable {
        require(_level > 0 && _level <= LAST_LEVEL, "Incorrect level");
        require(users[msg.sender].isExist ==  true, "User not exist");
        require(users[msg.sender].X4Matrix[_level].levelStatus == false, "Already Active in this level");
        require(msg.value == levelPrice[2][_level], "Incorrect Value");
        
        if(_level != 1) {   
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].X4Matrix[l].levelStatus == true, "Buy the previous level");
        }
      
        uint userUniqueId = users[msg.sender].id;
        address _freeReferrer = _findX4Referrer(msg.sender,_level);
        
        X4Struct memory x4UserDetails;
        
        x4UserDetails = X4Struct({
            UserAddress: msg.sender,
            uniqueId: userUniqueId,
            currentReferrer: _freeReferrer,
            referrals: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
       
        users[msg.sender].X4Matrix[_level] = x4UserDetails;
        users[msg.sender].currentLevel[2]  = _level;
        
        users[_freeReferrer].X4Matrix[_level].referrals.push(userUniqueId);
     
        _updateX4Details(_freeReferrer,_level);
       
        emit buyLevelEvent(2,msg.sender, _level, now);
    }
    
    function contractLock(bool _lockStatus) external returns(bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        lockStatus = _lockStatus;
        return true;
    }
    
    function failSafe(uint8 _flag, address payable _toUser, uint _amount) external onlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address"); 
        
        if(_flag == 1) {
            require(address(this).balance >= _amount, "Insufficient balance");
            (_toUser).transfer(_amount);
            ownerBal[address(0)] = ownerBal[address(0)].sub(_amount);
        }
        
        else {
            require(Token.balances(address(this)) >= _amount, "Insufficient Token Balance");
            Token.transfer(_toUser,_amount);
            ownerBal[address(Token)] = ownerBal[address(Token)].sub(_amount);
        }
        
        return true;
    }
    
    function updateLevelPrice(uint8 _matrix, uint8 _level, uint _price) external onlyOwner returns(bool) {
        levelPrice[_matrix][_level] = _price;
        return true;
    }
    
    function updateLevelBasedTokens(uint8 _matrix, uint8 _level, uint _price) external onlyOwner returns(bool) {
        levelBasedTokens[_matrix][_level] = _price;
        return true;
    }
    
    function getTotalEarnedTrx(uint8 _matrix) public view returns(uint) {
        uint totalEth;
        
        for( uint i=1;i<=userCurrentId;i++) {
            totalEth = totalEth.add(totalEarnedTrx[userList[i]][_matrix]);
        }
        
        return totalEth;
    }
    
    
    function getTotalEarnedEOX(uint8 _matrix) public view returns(uint) {
        uint totalEOX;
        
        for( uint i=1;i<=userCurrentId;i++) {
            totalEOX = totalEOX.add(totalEarnedEox[userList[i]][_matrix]);
        }
        
        return totalEOX;
    }
    
    
    function viewX3Referral(address userAddress, uint8 _level) public view returns(uint[] memory, uint[] memory) {
        return (users[userAddress].X3Matrix[_level].firstLineRef,users[userAddress].X3Matrix[_level].secondLineRef);
    }
    
    function viewX4Referral(address userAddress, uint8 _level) public view returns(uint[] memory) {
        return (users[userAddress].X4Matrix[_level].referrals);
    }
    
    function viewUserLevelStaus(uint8 _matrix, address _userAddress, uint8 _level) public view returns(bool) {
        if(_matrix == 1)        
            return (users[_userAddress].X3Matrix[_level].levelStatus);
        else if(_matrix == 2)        
            return (users[_userAddress].X4Matrix[_level].levelStatus);
    }
    
    function viewUserReInvestCount(uint8 _matrix, address _userAddress, uint8 _level) public view returns(uint) {
         if(_matrix == 1)        
            return (users[_userAddress].X3Matrix[_level].reInvestCount);
        else if(_matrix == 2)        
            return (users[_userAddress].X4Matrix[_level].reInvestCount);
    }
    
    function viewUserCurrentLevel(uint8 _matrix, address _userAddress) public view returns(uint8) {
            return (users[_userAddress].currentLevel[_matrix]);
    }
    
    function _x3Registration(uint _referrerID) internal  {
        
        uint firstLineId;
        uint secondLineId;
        
        if(users[userList[_referrerID]].X3Matrix[1].firstLineRef.length < 3) {
            firstLineId = _referrerID;
            secondLineId = users[userList[firstLineId]].X3Matrix[1].referrerID;
        }
        
        else if(users[userList[_referrerID]].X3Matrix[1].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findX3Referrer(1,_referrerID);
        }
        
        
        X3Struct memory X3MatrixUserDetails;
        
        X3MatrixUserDetails = X3Struct({
            UserAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].X3Matrix[1] = X3MatrixUserDetails;
        users[msg.sender].currentLevel[1]  = 1;
      
        users[userList[firstLineId]].X3Matrix[1].firstLineRef.push(userCurrentId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].X3Matrix[1].secondLineRef.push(userCurrentId);
        
        _updateX3Details(secondLineId, msg.sender,1);
        emit regLevelEvent(1, msg.sender, userList[firstLineId], now);
    }
    
    function _x4Registration(uint _referrerID) internal  {
        uint userUniqueId = users[msg.sender].id;  
        
        X4Struct memory x4UserDetails;
        
        x4UserDetails = X4Struct({
            UserAddress: msg.sender,
            uniqueId: userUniqueId,
            currentReferrer: userList[_referrerID],
            referrals: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].X4Matrix[1] = x4UserDetails;
        users[msg.sender].currentLevel[2]  = 1;
           
        users[userList[_referrerID]].X4Matrix[1].referrals.push(userUniqueId);
      
        _updateX4Details(userList[_referrerID],1);
        emit regLevelEvent(2, msg.sender, userList[_referrerID], now);
    }
    
    function _updateX3Details(uint secondLineId, address _userAddress, uint8 _level) internal {
        
        if(secondLineId == 0)
            secondLineId = 1;
        
        if(users[userList[secondLineId]].X3Matrix[_level].secondLineRef.length == 9) { // reInvest Amount
            _payX3Trx(1, _level, _userAddress, levelPrice[1][_level]);
            
            users[userList[secondLineId]].X3Matrix[_level].secondLineRef = new uint[](0);
            users[userList[secondLineId]].X3Matrix[_level].firstLineRef = new uint[](0);
            users[userList[secondLineId]].X3Matrix[_level].reInvestCount =  users[userList[secondLineId]].X3Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(1, userList[secondLineId], msg.sender, _level, users[userList[secondLineId]].X3Matrix[_level].reInvestCount, now);
        }
        else if(users[userList[secondLineId]].X3Matrix[_level].secondLineRef.length < 9) {
            
            if(users[userList[secondLineId]].X3Matrix[_level].secondLineRef.length == 8)
                _payX3Trx(1,_level, _userAddress, levelPrice[1][_level]);
                
            else if(users[userList[secondLineId]].X3Matrix[_level].secondLineRef.length < 8)
                _payX3Trx(0, _level, _userAddress, levelPrice[1][_level]);
        }
        
    }
    
    function _updateX4Details(address _referrerAddress, uint8 _level) internal {
        
        if(users[_referrerAddress].X4Matrix[_level].referrals.length == 4) { // REINVEST 
           _payX4Trx(3,_level,_referrerAddress,levelPrice[2][_level]);
            
            users[_referrerAddress].X4Matrix[_level].referrals = new uint[](0);
            users[_referrerAddress].X4Matrix[_level].reInvestCount =  users[_referrerAddress].X4Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(2, _referrerAddress, msg.sender, _level, users[_referrerAddress].X4Matrix[_level].reInvestCount, now);
        }
        else if(users[_referrerAddress].X4Matrix[_level].referrals.length == 1)  // upline - 100%
            _payX4Trx(1,_level,_referrerAddress,levelPrice[2][_level]);
            
        else if(users[_referrerAddress].X4Matrix[_level].referrals.length == 2 || users[_referrerAddress].X4Matrix[_level].referrals.length == 3) // upline - 50% 1st upline - 50%
            _payX4Trx(2,_level,_referrerAddress,levelPrice[2][_level]);
    }
    
    function _getX3Referrer(address _userAddress, uint8 _level) internal returns(uint) {
        while (true) {
            
            uint referrerID =  users[_userAddress].X3Matrix[1].referrerID;
            if (users[userList[referrerID]].X3Matrix[_level].levelStatus == true) {
                return referrerID;
            }
            
            _userAddress = userList[referrerID];
            emit lostMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[referrerID],referrerID, _level, levelPrice[1][_level],now);
        }
        
    }
    
    function _payX3Trx(uint8 _flag, uint8 _level, address _userAddress, uint _amt) internal {
        
        uint[3] memory referer;
        
        referer[0] = users[_userAddress].X3Matrix[_level].referrerID;
        referer[1] = users[userList[referer[0]]].X3Matrix[_level].referrerID;
        referer[2] = users[userList[referer[1]]].X3Matrix[_level].referrerID;
        
        
        uint tokenShare = levelBasedTokens[1][_level];
        uint shareAmount;
        
        if(_flag == 0) { // 2ND UPLINE - 40%
        
            shareAmount = _amt.mul(40 trx).div(100 trx);
         
            if(users[userList[referer[1]]].X3Matrix[_level].levelStatus == false) 
                referer[1] = 1;
                
            if(userList[referer[1]] != ownerAddress) 
                require((address(uint160(userList[referer[1]])).send(shareAmount)) , "Transaction Failure");
                
            else 
                ownerBal[address(0)] = ownerBal[address(0)].add(shareAmount);
            
            require(Token.transfer(msg.sender, tokenShare), "Transaction Failure");
            ownerBal[address(Token)] = ownerBal[address(Token)].sub(tokenShare);
            earnedEox[msg.sender][1][_level] = earnedEox[msg.sender][1][_level].add(tokenShare);
            totalEarnedEox[msg.sender][1] = totalEarnedEox[msg.sender][1].add(tokenShare);
            totalEarnedTrx[userList[referer[1]]][1] = totalEarnedTrx[userList[referer[1]]][1].add(shareAmount);
            earnedTrx[userList[referer[1]]][1][_level] =  earnedTrx[userList[referer[1]]][1][_level].add(shareAmount);
            emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, userList[referer[1]], referer[1], _level, shareAmount, now);
        }
        
        else if(_flag == 1) { // REINVEST 3RD UPLINE - 50%
        
            shareAmount = _amt.mul(50 trx).div(100 trx);
            
            if(users[userList[referer[2]]].X3Matrix[_level].levelStatus == false) 
                referer[2] = 1;
                
            if(userList[referer[2]] != ownerAddress) 
                require((address(uint160(userList[referer[2]])).send(shareAmount)), "Transaction Failure");
            
            else 
                ownerBal[address(0)] = ownerBal[address(0)].add(shareAmount);
            
            require(Token.transfer(msg.sender, tokenShare), "Transaction Failure");
            ownerBal[address(Token)] = ownerBal[address(Token)].sub(tokenShare);
            earnedEox[msg.sender][1][_level] = earnedEox[msg.sender][1][_level].add(tokenShare);
            totalEarnedEox[msg.sender][1] = totalEarnedEox[msg.sender][1].add(tokenShare);
            totalEarnedTrx[userList[referer[2]]][1] = totalEarnedTrx[userList[referer[2]]][1].add(shareAmount);
            earnedTrx[userList[referer[2]]][1][_level] =  earnedTrx[userList[referer[2]]][1][_level].add(shareAmount);
            emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, userList[referer[2]],referer[2], _level, shareAmount, now);
        }
        
        uint defaultShare  = _amt.mul(25 trx).div(100 trx);
       
        // DIRECT REFERRALS - 25%
        address directRef =  users[_userAddress].referrer;
        
        if(users[directRef].X3Matrix[_level].levelStatus == false) 
            directRef = ownerAddress;
            
        if(directRef != ownerAddress)    
            require( address(uint160(directRef)).send(defaultShare)  , "Transaction Failure");
        
        else  
            ownerBal[address(0)] = ownerBal[address(0)].add(defaultShare);
        
        totalEarnedTrx[directRef][1] = totalEarnedTrx[directRef][1].add(defaultShare);
        earnedTrx[directRef][1][_level] =  earnedTrx[directRef][1][_level].add(defaultShare);
        emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, directRef, users[directRef].id, _level, defaultShare, now);
        
        
        // 1ST UPLINE - 25%
        if(users[userList[referer[0]]].X3Matrix[_level].levelStatus == false) 
            referer[0] = 1;
        
        if(userList[referer[0]]  != ownerAddress)  
            require( address(uint160(userList[referer[0]])).send(defaultShare)  , "Transaction Failure");
        
        else 
            ownerBal[address(0)] = ownerBal[address(0)].add(defaultShare);
        
        totalEarnedTrx[userList[referer[0]] ][1] = totalEarnedTrx[userList[referer[0]]][1].add(defaultShare);
        earnedTrx[userList[referer[0]]][1][_level] =  earnedTrx[userList[referer[0]]][1][_level].add(defaultShare);
        emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, userList[referer[0]], referer[0], _level, defaultShare, now);
        
        
        // OWNER - 10%
        if(_flag != 1) {
            uint adminShare  = _amt.mul(10 trx).div(100 trx);
            ownerBal[address(0)] = ownerBal[address(0)].add(adminShare);
            
            totalEarnedTrx[ownerAddress][1] = totalEarnedTrx[ownerAddress][1].add(adminShare);
            earnedTrx[ownerAddress][1][_level] =  earnedTrx[ownerAddress][1][_level].add(adminShare);
            emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, userList[1], 1, _level, adminShare, now);
        }
        
    }
    
    function _payX4Trx(uint8 _flag, uint8 _level, address _directRefferer, uint _amt) internal {
        address[3] memory referer;
        
        uint tokenShare = levelBasedTokens[2][_level];
        
        if(_flag == 1)  { // DIRECT REFERRER - 100%
            referer[0] = _directRefferer;
    
            if(users[referer[0]].X4Matrix[_level].levelStatus == false) 
                referer[0] = ownerAddress;
            
            if(referer[0] != ownerAddress) 
                require((address(uint160(referer[0])).send(_amt)), "Transaction Failure");
            else 
                ownerBal[address(0)] = ownerBal[address(0)].add(_amt);
                
            require(Token.transfer(msg.sender, tokenShare), "Transaction Failure");
            ownerBal[address(Token)] = ownerBal[address(Token)].sub(tokenShare);
            earnedEox[msg.sender][2][_level] = earnedEox[msg.sender][2][_level].add(tokenShare);
            totalEarnedEox[msg.sender][2] = totalEarnedEox[msg.sender][2].add(tokenShare);
            totalEarnedTrx[referer[0]][2] = totalEarnedTrx[referer[0]][2].add(_amt);
            earnedTrx[referer[0]][2][_level] =  earnedTrx[referer[0]][2][_level].add(_amt);
            emit getMoneyForLevelEvent(2, msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, _amt, now);
        }
        
        else if(_flag == 2) { // 1ST UPLINE  - 50% 2ND UPLINE - 50%
            referer[1] = users[_directRefferer].X4Matrix[_level].currentReferrer;
            referer[0] = _directRefferer;
            
            if(users[referer[0]].X4Matrix[_level].levelStatus == false) 
                referer[0] = ownerAddress;
           
            if(referer[0] != ownerAddress)     
                require( (address(uint160(referer[0])).send(_amt.div(2))), "Transaction Failure");
            
            else if(referer[0] ==  ownerAddress) 
                ownerBal[address(0)] = ownerBal[address(0)].add(_amt.div(2));
            
            totalEarnedTrx[referer[0]][2] = totalEarnedTrx[referer[0]][2].add(_amt.div(2));
            earnedTrx[referer[0]][2][_level] =  earnedTrx[referer[0]][2][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(2, msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, _amt.div(2), now);
            
                 
            if(users[referer[1]].X4Matrix[_level].levelStatus == false) 
                referer[1] = ownerAddress;
            
            if(referer[1] != ownerAddress) 
                require( (address(uint160(referer[1])).send(_amt.div(2))) , "Transaction Failure");
                
            else if(referer[1] == ownerAddress)  
                ownerBal[address(0)] = ownerBal[address(0)].add(_amt.div(2));
               
            
            require(Token.transfer(msg.sender, tokenShare), "Token Transaction Failure");
            ownerBal[address(Token)] = ownerBal[address(Token)].sub(tokenShare);
            earnedEox[msg.sender][2][_level] = earnedEox[msg.sender][2][_level].add(tokenShare);
            totalEarnedEox[msg.sender][2] = totalEarnedEox[msg.sender][2].add(tokenShare);
            totalEarnedTrx[referer[1]][2] = totalEarnedTrx[referer[1]][2].add(_amt.div(2));
            earnedTrx[referer[1]][2][_level] =  earnedTrx[referer[1]][2][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(2, msg.sender, users[msg.sender].id, referer[1], users[referer[1]].id, _level, _amt.div(2), now);
        }
        
        else if(_flag == 3) { //REINVEST - 100%
            referer[0] = users[_directRefferer].X4Matrix[_level].currentReferrer;
            
            if(users[referer[0]].X4Matrix[_level].levelStatus == false) 
                referer[0] = ownerAddress;
             
            if(referer[0] != ownerAddress)    
                require((address(uint160(referer[0])).send(_amt)), "Transaction Failure");
                
            else if(referer[0] ==  ownerAddress) 
                ownerBal[address(0)] = ownerBal[address(0)].add(_amt);
            
            require(Token.transfer(msg.sender, tokenShare), "Transaction Failure");
            ownerBal[address(Token)] = ownerBal[address(Token)].sub(tokenShare);
            earnedEox[msg.sender][2][_level] = earnedEox[msg.sender][2][_level].add(tokenShare);
            totalEarnedEox[msg.sender][2] = totalEarnedEox[msg.sender][2].add(tokenShare);
            totalEarnedTrx[referer[0]][2] = totalEarnedTrx[referer[0]][2].add(_amt);
            earnedTrx[referer[0]][2][_level] =  earnedTrx[referer[0]][2][_level].add(_amt);
            emit getMoneyForLevelEvent(2, msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, _amt, now);
        }
        
    }
    
    function _findX3Referrer(uint8 _level, uint _refId) internal returns(uint,uint) {
        
        if(users[userList[_refId]].X3Matrix[_level].firstLineRef.length <3)
            return(users[userList[_refId]].X3Matrix[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].X3Matrix[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].X3Matrix[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].X3Matrix[_level].firstLineRef[2];
            
            
            for(uint8 r=0; r<3; r++) {
                if(users[userList[referrals[r]]].X3Matrix[_level].firstLineRef.length < 3) 
                    return (_refId, referrals[r]);
            }
            
        }
        
    }
    
    function _findX4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].X4Matrix[level].levelStatus) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
}