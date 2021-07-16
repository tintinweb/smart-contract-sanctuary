//SourceUnit: XscoinTron.sol

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
    
    address public ownerWallet;
    address public distribute;

    uint public currUserID = 0;
    uint public REFERRER_1_LEVEL_LIMIT = 2;
    uint public weeklyDistributionPercent_1 = 2500000000000000000;
    uint public weeklyDistributionPercent_2 = 3000000000000000000;
    uint public doubleBonusPeriod = 15 days;
    bool public lockStatus;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _amount, uint _time);
    event investlEvent(address indexed _user, uint _amount, uint _time);
    event getMoneyForLevelEvent(address indexed _user, uint UserId, uint _type, uint _payout, bool _doubleBonus, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, uint UserId, uint _type, uint _payout, bool _doubleBonus, uint _time);
    
    constructor(address _distribute, address _tokenAddress) public {
        ownerWallet = msg.sender;
        distribute = _distribute;

        Token = TRC20(_tokenAddress);
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            actualReferrerID:0,
            totalEarning:0,
            initialInvest:0,
            binaryInvest:0,
            totalInvest:0,
            binaryEarned:0,
            weeklyEarned:0,
            referralCount:0,
            created: now,
            doubleBonus:false,
            referral: new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
    }
    
    function regUser(uint _referrerID, uint _amount) public  {
        require(lockStatus == false, "Contract Locked");
        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(Token.balanceOf(msg.sender) >= _amount,"insufficient balance");
        require(Token.allowance(msg.sender,address(this)) >= _amount,"insufficient allowance");
        
        require(Token.transferFrom(msg.sender,address(this),_amount),"token transfer failed");
        
        uint originalRefID = _referrerID;
        
        if((users[userList[originalRefID]].initialInvest <= _amount))
            users[userList[originalRefID]].referralCount =  users[userList[originalRefID]].referralCount.add(1);
        
         if((users[userList[originalRefID]].referralCount == 3) 
         && (users[userList[originalRefID]].created <= users[userList[originalRefID]].created.add(doubleBonusPeriod))
         ){
             users[userList[originalRefID]].doubleBonus = true;
         }
            
        
        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) 
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        
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

        users[userList[_referrerID]].referral.push(msg.sender);

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
        
        emit investlEvent(msg.sender, _amount, now);
    }
    
    function binaryCommission(uint _userID,uint _endUserID) public {
        require(distribute == msg.sender,"only distribute wallet");
        
        uint _comparisonPayout = binaryComparison(_userID);
        address user = userList[_userID];
        
        if(_comparisonPayout > 0){
            
            uint _binaryPayout = (_comparisonPayout.mul(8000000000000000000)).div(100000000000000000000);
            
            require(Token.transfer(user,_binaryPayout),"_binaryPayout transfer failed");
            
            
            users[users[user].referral[0]].binaryInvest = users[users[user].referral[0]].binaryInvest.sub(_comparisonPayout);
            users[users[user].referral[1]].binaryInvest = users[users[user].referral[1]].binaryInvest.sub(_comparisonPayout);
            
            users[user].totalEarning = users[user].totalEarning.add(_binaryPayout);
            users[user].binaryEarned = users[user].binaryEarned.add(_binaryPayout);
            users[user].binaryInvest = users[user].binaryInvest.add(_comparisonPayout);
            
            emit getMoneyForLevelEvent( user, _userID, 2, _binaryPayout,users[user].doubleBonus, now);
        }
        else{
            emit lostMoneyForLevelEvent( userList[_userID], _userID, 2, 0,users[user].doubleBonus, now);
        }
        
        if(_userID < _endUserID){
            _userID = _userID.add(1);
            binaryCommission(_userID,_endUserID);
        }   
    }
    
    function weeklyInvestCommission(uint _usdPrice, uint _userID,uint _endUserID) public {
        require(distribute == msg.sender,"only distribute wallet");
        require( _userID > 0, "_userID must be greather than 1");
        require(_usdPrice > 0,"_usdPrice must be greather than zero");
        
        address user = userList[_userID];
        
        uint _weeklyPayout = investDistribution(_usdPrice, _userID);
        
        if(_weeklyPayout > 0){
            require(Token.transfer(user,_weeklyPayout),"_weeklyPayout transfer failed");
            users[user].totalEarning = users[user].totalEarning.add(_weeklyPayout);
            users[user].weeklyEarned = users[user].weeklyEarned.add(_weeklyPayout);
            
            emit getMoneyForLevelEvent( user, _userID, 3, _weeklyPayout,users[user].doubleBonus, now);
        }
        else{
            emit lostMoneyForLevelEvent( userList[_userID], _userID, 3, 0,users[user].doubleBonus, now);
        }
        
        if(_userID < _endUserID){
            _userID = _userID.add(1);
            weeklyInvestCommission( _usdPrice, _userID,_endUserID);
        }   
        
    }
    
    
    function contractLock(bool _lockStatus) public returns(bool) {
        require(msg.sender == ownerWallet, "Invalid User");
        lockStatus = _lockStatus;
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
    
    function getAllUserBinaryCommission(uint _userID, uint _endUserID, uint totalCommission) public view returns(uint){
        totalCommission = totalCommission.add(binaryComparison(_userID));
        if(_userID < _endUserID){
           _userID = _userID.add(1);
           return this.getAllUserBinaryCommission( _userID, _endUserID,  totalCommission);
        }
        return totalCommission;
    }
    
    function getAllUserWeeklyCommission(uint _userID, uint _endUserID, uint _usdPrice, uint totalCommission) public view returns(uint){
        totalCommission = totalCommission.add(investDistribution(_usdPrice, _userID));
        if(_userID < _endUserID){
           _userID = _userID.add(1);
           return this.getAllUserWeeklyCommission( _userID, _endUserID, _usdPrice, totalCommission);
        }
        return totalCommission;
    }
    
    function getTotalEarned() public view returns(uint) {
        uint totalEth;
        
        for( uint _userIndex=1;_userIndex<= currUserID;_userIndex++) {
            totalEth = totalEth.add(users[userList[_userIndex]].totalEarning);
        }
        
        return totalEth;
    }

    function viewWPUserReferral(address _user) public view returns(address[] memory) {
            return users[_user].referral;
    }  

    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
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
    
    function investDistribution(uint _usdPrice, uint _userID)internal view returns(uint){
        address user = userList[_userID];
        if(users[user].totalInvest > 0){
            if(users[user].totalInvest < _usdPrice){
                uint bonus150Percent = users[user].totalInvest.add(users[user].totalInvest.div(2));
                uint percent = weeklyDistributionPercent_1;
                
                if(users[user].doubleBonus == true)
                    percent = weeklyDistributionPercent_1.mul(2);
                    
                if(users[user].weeklyEarned < bonus150Percent){
                    uint _weekPayout = (users[user].totalInvest).mul(percent).div(100000000000000000000);
                    
                    if(users[user].weeklyEarned.add(_weekPayout) > bonus150Percent)
                        return bonus150Percent.sub(users[user].weeklyEarned);
                    
                    return _weekPayout;
                }
            }
            else if(users[user].totalInvest >= _usdPrice){
                uint bonus200Percent = users[user].totalInvest.add(users[user].totalInvest);
                uint percent = weeklyDistributionPercent_2;
                
                if(users[user].doubleBonus == true)
                    percent = weeklyDistributionPercent_2.mul(2);
                
                if(users[user].weeklyEarned < bonus200Percent){
                    uint _weekPayout = (users[user].totalInvest).mul(percent).div(100000000000000000000);
                    
                    if(users[user].weeklyEarned.add(_weekPayout) > bonus200Percent)
                        return bonus200Percent.sub(users[user].weeklyEarned);
                        
                    return _weekPayout;
                }
            }
        }
        return 0;
    }
    
    function binaryComparison(uint _userID)internal view returns(uint){
        address user = userList[_userID];
        
        if(users[user].referral.length < 2)
            return 0;
        
        if((users[users[user].referral[0]].binaryInvest == 0) || (users[users[user].referral[1]].binaryInvest == 0))
            return 0;
        
        if(users[users[user].referral[0]].binaryInvest > users[users[user].referral[1]].binaryInvest)
            return users[users[user].referral[1]].binaryInvest; 
        else
            return users[users[user].referral[0]].binaryInvest;
    }
    
    function payForReferrer( uint _userID)internal {
        address user = userList[_userID];
        uint _refPayout = (users[user].initialInvest.mul(5000000000000000000)).div(100000000000000000000);
        if(_refPayout > 0){
            address _ref = userList[users[user].actualReferrerID];
            require(Token.transfer(_ref,_refPayout),"referrer payout failed");
            users[_ref].totalEarning = users[_ref].totalEarning.add(_refPayout);
            emit getMoneyForLevelEvent( _ref, users[user].actualReferrerID, 1, _refPayout, users[user].doubleBonus, now);
        }    
    }
    
    
    
    
}