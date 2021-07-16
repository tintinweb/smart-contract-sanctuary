//SourceUnit: xscoinUpdated.sol

pragma solidity 0.5.9;

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
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
}

contract XSCoin {

    struct UserStruct {  // user struct
        bool isExist;
        uint id;
        uint referrerID;
        uint actualReferrerID;
        uint totalEarning;
        uint initialInvest;
        uint binaryInvest;
        uint totalInvest;
        uint binaryEarned;
        uint weeklyEarned;
        uint referralCount;
        uint created;
        bool doubleBonus;
        address[] referral;
    }
    
    using SafeMath for uint256;
    
    TRC20 Token;
    
    XSCoin public oldXSCoin;
    
    address public ownerWallet;
    address public distribute;

    uint public currUserID = 0;
    uint public REFERRER_1_LEVEL_LIMIT = 2;
    uint public doubleBonusPeriod = 15 days;
    bool public lockStatus;
    uint public doubleBonusLockStatus = 1; // 1- enable 2 - disable

    mapping (address => UserStruct) public users;
    mapping (address => uint[]) public investments;
    mapping (uint => address) public userList;
    mapping (address => uint) public dailyPayout;
    mapping (address => uint) public dailyPayoutTime;
    

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _amount, uint _time);
    event investEvent(address indexed _user, uint _amount, uint _time);
    event directBonus(address indexed _user, address indexed _referrer, uint _directBonus, uint _time);
    event binaryComparisonEvent(address indexed _user, uint UserId, uint _payout, uint _time);
    event weeklyDistributionEvent(address indexed _user, uint UserId, uint _payout, bool _doubleBonus, uint _time);
    event ownerExtraPayoutEvent(address indexed _user, uint _extraPayout, uint _time);
    
    constructor(address _distribute, address _tokenAddress, address _oldContract) public {
        ownerWallet = msg.sender;
        distribute = _distribute;

        Token = TRC20(_tokenAddress);
        
        oldXSCoin = XSCoin(_oldContract);
        
        currUserID = oldXSCoin.currUserID();
        
        //  UserStruct memory userStruct;
        //  currUserID++;

        //  userStruct = UserStruct({
        //      isExist: true,
        //      id: currUserID,
        //      referrerID: 0,
        //      actualReferrerID:0,
        //      totalEarning:0,
        //      initialInvest:0,
        //      binaryInvest:0,
        //      totalInvest:0,
        //      binaryEarned:0,
        //      weeklyEarned:0,
        //      referralCount:0,
        //      created: now,
        //      doubleBonus:false,
        //      referral: new address[](0)
        //  });
        //  users[ownerWallet] = userStruct;
        //  userList[currUserID] = ownerWallet;
    }
    
    function regUser(uint _referrerID, uint _position, uint _amount, uint _flag) public  {
        require(lockStatus == false, "Contract Locked");
        require(!users[msg.sender].isExist, 'User exist');
        require(_position == 0 || _position == 1,"_position must be zero or one");
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(Token.balanceOf(msg.sender) >= _amount,"insufficient balance");
        require(Token.allowance(msg.sender,address(this)) >= _amount,"insufficient allowance");
        require(_flag == 1 || _flag == 2, "_flag must be 1 or 2");
        
        require(Token.transferFrom(msg.sender,address(this),_amount),"token transfer failed");
        
        uint originalRefID;
        
        if(_flag == 1)
            originalRefID = _referrerID;
        else    
            originalRefID = 1;
        
        
        if((users[userList[originalRefID]].initialInvest <= _amount))
            users[userList[originalRefID]].referralCount =  users[userList[originalRefID]].referralCount.add(1);
        
        if((users[userList[originalRefID]].referralCount == 3) 
        && (users[userList[originalRefID]].created <= users[userList[originalRefID]].created.add(doubleBonusPeriod))
        && (doubleBonusLockStatus == 1)){
            users[userList[originalRefID]].doubleBonus = true;
        }
            
        if(_position == 0 && users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT-1){
            if(users[userList[_referrerID]].referral[0] != address(0))
                _referrerID = users[findFreeReferrerLeft(userList[_referrerID])].id;
        }
        else if( _position == 1 && users[userList[_referrerID]].referral.length == REFERRER_1_LEVEL_LIMIT ){
            _referrerID = users[findFreeReferrerRight(userList[_referrerID])].id;
        }
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            actualReferrerID:originalRefID,
            totalEarning:0,
            initialInvest:_amount,
            binaryInvest:_amount,
            totalInvest:_amount,
            binaryEarned:0,
            weeklyEarned:0,
            referralCount:0,
            created: now,
            doubleBonus:false,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        
        userList[currUserID] = msg.sender;
        
        investments[msg.sender].push(_amount);
        dailyPayoutTime[msg.sender] = now;

        if(_position == 0){
            if(users[userList[_referrerID]].referral.length >= 1) 
                users[userList[_referrerID]].referral[0] = msg.sender;
            else 
                users[userList[_referrerID]].referral.push(msg.sender);
        }
        else{
            if(users[userList[_referrerID]].referral.length == 0){
                users[userList[_referrerID]].referral.push(address(0));
                users[userList[_referrerID]].referral.push(msg.sender);
            }
            else if(users[userList[_referrerID]].referral.length == 1)
                users[userList[_referrerID]].referral.push(msg.sender);
        }

        payForReferrer(users[msg.sender].id);
        

        emit regLevelEvent(msg.sender, userList[_referrerID], _amount, now);
    }
    
    function invest(uint _amount) public {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, 'User not exist');
        require(Token.balanceOf(msg.sender) >= _amount,"insufficient balance");
        require(Token.allowance(msg.sender,address(this)) >= _amount,"insufficient allowance");
        
        require(Token.transferFrom(msg.sender,address(this),_amount),"token transfer failed");

        users[msg.sender].binaryInvest = users[msg.sender].binaryInvest.add(_amount);
        users[msg.sender].totalInvest = users[msg.sender].totalInvest.add(_amount);
        
        investments[msg.sender].push(_amount);  
        
        emit investEvent(msg.sender, _amount, now);
    }
    
    function binaryCommission(uint[] memory _userID, uint[] memory _amount) public {
        require(lockStatus == false, "Contract Locked");
        require(distribute == msg.sender,"only distribute wallet");
        require(_userID.length == _amount.length, "invalid length");
        
        for(uint i=0;i<_userID.length;i++){
            
            address user = userList[_userID[i]];
            
            if(_amount[i] > 0){
                if(((block.timestamp.sub(dailyPayoutTime[user])).div(1 days)) >= 1){
                    dailyPayout[user] = 0;
                    dailyPayoutTime[user] = now;
                }
                
                uint _adminPayout;
                uint _userPayout = _amount[i];
                
                if(user != ownerWallet){
                    if(_amount[i].add(dailyPayout[user]) > users[user].totalInvest){
                        _userPayout  = users[user].totalInvest.sub(dailyPayout[user]);
                        _adminPayout = _amount[i].sub(_userPayout);
                    }
                }
                
                require(Token.transfer(user,((_userPayout.mul(98e18)).div(1e20))),"_binaryPayout transfer failed");
                    
                if(_adminPayout > 0){
                    emit ownerExtraPayoutEvent( user, _adminPayout, now);
                }
                
                _adminPayout = _adminPayout.add(((_userPayout.mul(2e18)).div(1e20)));
                
                require(Token.transfer(ownerWallet,_adminPayout),"_binaryPayout transfer failed");
                users[ownerWallet].totalEarning = users[ownerWallet].totalEarning.add(_adminPayout);
                
                users[user].totalEarning = users[user].totalEarning.add(((_userPayout.mul(98e18)).div(1e20)));
                users[user].binaryEarned = users[user].binaryEarned.add(((_userPayout.mul(98e18)).div(1e20)));
                dailyPayout[user] = dailyPayout[user].add(((_userPayout.mul(98e18)).div(1e20)));
                
                emit binaryComparisonEvent( user, _userID[i], ((_userPayout.mul(98e18)).div(1e20)), now);
            
            }
        }
        
    }
    
    function weeklyInvestCommission(uint[] memory _userID, uint[] memory amount) public {
        require(lockStatus == false, "Contract Locked");
        require(distribute == msg.sender,"only distribute wallet");
        require(_userID.length > 0 && _userID.length <= 50,"invalid length");
        
        for(uint i=0;i<_userID.length;i++){
            require( _userID[i] > 0, "_userID must be not be zero");
            address user = userList[_userID[i]];
            
            if(amount[i] > 0){
                uint _weeklyPayout = (amount[i].mul(98e18)).div(1e20);
                uint _adminPayout = (amount[i].mul(2e18)).div(1e20);
                
                require(Token.transfer(user,_weeklyPayout),"_weeklyPayout transfer failed");
                users[user].totalEarning = users[user].totalEarning.add(_weeklyPayout);
                users[user].weeklyEarned = users[user].weeklyEarned.add(_weeklyPayout);
                
                require(Token.transfer(ownerWallet,_adminPayout),"_weeklyPayout transfer failed");
                users[ownerWallet].totalEarning = users[ownerWallet].totalEarning.add(_adminPayout);
                
                emit weeklyDistributionEvent( user, _userID[i], _weeklyPayout, users[user].doubleBonus, now);
            }
        }  
    }
    
    function contractLock(bool _lockStatus) public returns(bool) {
        require(msg.sender == ownerWallet, "Invalid User");
        lockStatus = _lockStatus;
        return true;
    }
    
    function doubleBonusLock(uint _lockStatus) public returns(bool) {
        require(msg.sender == ownerWallet, "Invalid User");
        require((_lockStatus == 1) || (_lockStatus == 2),"invalid lock status");
        doubleBonusLockStatus = _lockStatus;
        return true;
    }
    
    function updateToken(address _newToken) public returns(bool) {
        require(msg.sender == ownerWallet, "Invalid User");
        Token = TRC20(_newToken);
        return true;
    }

    function failSafe(address _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerWallet, "Only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(Token.balanceOf(address(this)) >= _amount,"insufficient balance");

        require(Token.transfer(_toUser, _amount),"transfer failed");
        return true;
    }
    
    function getTotalEarned() public view returns(uint) {
        uint totalEth;
        
        for( uint _userIndex=1;_userIndex<= currUserID;_userIndex++) {
            totalEth = totalEth.add(users[userList[_userIndex]].totalEarning);
        }
        
        return totalEth;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
            return users[_user].referral;
    }  

    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;
        
        if(users[_user].referral.length == REFERRER_1_LEVEL_LIMIT){
            if(users[_user].referral[0] == address(0))
                return _user;
        }

        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if(users[referrals[i]].referral[0] == address(0)){
                    noFreeReferrer = false;
                    freeReferrer = referrals[i];
                    break;    
                }
                
                if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }
    
    
    function findFreeReferrerLeft(address _user) public view returns(address) {
        if(users[_user].referral[0] == address(0)) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referral[0];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if(users[referrals[i]].referral[0] != address(0)){
                    if(i < 62) {
                        referrals[(i+1)*1] = users[referrals[i]].referral[0];
                    }
                }
                else {
                    noFreeReferrer = false;
                    freeReferrer = referrals[i];
                    break;
                }
            }
            else if(users[referrals[i]].referral.length == 1){
                if(users[referrals[i]].referral[0] != address(0)){
                    if(i < 62) {
                        referrals[(i+1)*1] = users[referrals[i]].referral[0];
                    }
                }
                else {
                    noFreeReferrer = false;
                    freeReferrer = referrals[i];
                    break;
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }
    
    function findFreeReferrerRight(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;    
        
        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if(i < 62) {
                    referrals[(i+1)*1] = users[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }
    
    function payForReferrer( uint _userID)internal {
        address user = userList[_userID];
        uint _refPayout = (users[user].initialInvest.mul(5e18)).div(1e20);
        if(_refPayout > 0){
            address _ref = userList[users[user].actualReferrerID];
            uint _adminPayout;
            uint _userPayout = _refPayout;
            
            if(((block.timestamp.sub(dailyPayoutTime[_ref])).div(1 days)) >= 1){
                dailyPayout[_ref] = 0;
                dailyPayoutTime[_ref] = now;
            }
            
            if(_ref != ownerWallet){
                if(_refPayout.add(dailyPayout[_ref]) > users[_ref].totalInvest){
                    _userPayout  = users[_ref].totalInvest.sub(dailyPayout[_ref]);
                    _adminPayout = _refPayout.sub(_userPayout);
                }
            }
            
            require(Token.transfer(_ref,((_userPayout.mul(98e18)).div(1e20))),"referrer payout failed");
            
            if(_adminPayout > 0){
                emit ownerExtraPayoutEvent( _ref, _adminPayout, now);
            }
            
            _adminPayout = _adminPayout.add(((_userPayout.mul(2e18)).div(1e20)));
            
            require(Token.transfer(ownerWallet,_adminPayout),"referrer admin payout failed");
            users[ownerWallet].totalEarning = users[ownerWallet].totalEarning.add(_adminPayout);
            
            users[_ref].totalEarning = users[_ref].totalEarning.add(((_userPayout.mul(98e18)).div(1e20)));
            dailyPayout[_ref] = dailyPayout[_ref].add(((_userPayout.mul(98e18)).div(1e20)));
            
            emit directBonus( user, _ref, ((_userPayout.mul(98e18)).div(1e20)), now);
        }    
    }
    
    
    function syncUsers(
        address[] memory user,
        uint[] memory _userID,
        uint8[] memory _position,
        uint[] memory _referrerID,
        address[] memory _referrerAddress,
        uint[] memory _actualReferrerID
        ) public {
            require(address(oldXSCoin) != address(0), "Initialize closed");
            require(msg.sender == distribute, "Access denied");
            require(
                (user.length == _userID.length) &&
                (_position.length == _referrerID.length) &&
                (_referrerAddress.length == _actualReferrerID.length) && 
                (user.length == _actualReferrerID.length),
                "invalid array arguments"
            );
            
            for (uint i = 0; i < user.length; i++) {
            
                UserStruct  memory olduser;
                
                (olduser.isExist,olduser.id,olduser.referrerID,olduser.actualReferrerID,olduser.totalEarning,olduser.referralCount,olduser.doubleBonus) = getOldUserDetails( user[i]);
                (olduser.initialInvest,olduser.binaryInvest,olduser.totalInvest,olduser.binaryEarned,olduser.weeklyEarned,olduser.created) =  getOldUserInvestments(user[i]);
               
                if (olduser.isExist) {
                    if (!users[user[i]].isExist) {
                        if(olduser.id == 1)
                            user[i] = ownerWallet;
                            
                        users[user[i]].isExist = true;
                        users[user[i]].id = _userID[i];
                        users[user[i]].referrerID = _referrerID[i];
                        users[user[i]].actualReferrerID = _actualReferrerID[i];
                        users[user[i]].totalEarning = olduser.totalEarning;
                        users[user[i]].initialInvest = olduser.initialInvest;
                        users[user[i]].binaryInvest = olduser.binaryInvest;
                        users[user[i]].totalInvest = olduser.totalInvest;
                        users[user[i]].binaryEarned = olduser.binaryEarned;
                        users[user[i]].weeklyEarned = olduser.weeklyEarned;
                        users[user[i]].referralCount = olduser.referralCount;
                        users[user[i]].created = olduser.created;
                        users[user[i]].doubleBonus = olduser.doubleBonus;
                        userList[olduser.id] = user[i];
                        
                        investments[user[i]].push(olduser.totalInvest);
                        dailyPayoutTime[user[i]] = now;
                        
                        if(_referrerID[i] == 1)
                            _referrerAddress[i] = ownerWallet;
                            
                        if(_position[i] == 0){
                            if(users[_referrerAddress[i]].referral.length >= 1) 
                                users[_referrerAddress[i]].referral[0] = user[i];
                            else 
                                users[_referrerAddress[i]].referral.push(user[i]);
                        }
                        else{
                            if(users[_referrerAddress[i]].referral.length == 0){
                                users[_referrerAddress[i]].referral.push(address(0));
                                users[_referrerAddress[i]].referral.push(user[i]);
                            }
                            else if(users[_referrerAddress[i]].referral.length == 1){
                                users[_referrerAddress[i]].referral.push(user[i]);
                            }
                        }
                        
                        emit regLevelEvent( user[i], _referrerAddress[i], olduser.initialInvest, users[user[i]].created);
                    }
                    
                }
            }
    }
    
    function getOldUserDetails(address oldusers)public view returns(bool,uint,uint,uint,uint,uint,bool){
        bool[2] memory isExist;
        uint referralCount;
        uint id;
        uint refID;
        uint acRef;
        uint totalEarning;
        
        (isExist[0] , 
            id, 
            refID, 
            acRef,
            totalEarning,
            ,
            ,
            ,
            ,
            ,
            referralCount,
            ,
            isExist[1] ) = oldXSCoin.users(oldusers);
            return(isExist[0],id,refID,acRef,totalEarning,referralCount,isExist[1]);
    }
    
     function getOldUserInvestments(address oldusers)public view returns(uint,uint,uint,uint,uint, uint){
        uint initialInvest;
        uint binaryInvest;
        uint totalInvest;
        uint binaryEarned;
        uint weeklyEarned;
        uint created;
        
        ( , 
            , 
            , 
            ,
            ,
          initialInvest  ,
            binaryInvest,
            totalInvest,
            binaryEarned,
            weeklyEarned,
            ,
            created,
             ) = oldXSCoin.users(oldusers);
            return(initialInvest,binaryInvest,totalInvest,binaryEarned,weeklyEarned,created);
    }
    
}