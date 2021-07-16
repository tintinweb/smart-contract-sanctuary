//SourceUnit: EtokenNetwork.sol

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
    function mint(address reciever, uint256 value) public returns(bool);
}

contract EtokenLink {

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint currentLevel;
        uint totalEarningTrx;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }
    
    using SafeMath for uint256;
    address public ownerAddress;
    address public dividentWallet;
    uint dividentPercent = 5 trx;
    uint public adminFee = 15 trx;
    uint public currentId = 0;
    uint referrer1Limit = 2;
    uint public PERIOD_LENGTH = 60 days;
    bool public lockStatus;
    TRC20 Token;

    mapping(uint => uint) public LEVEL_PRICE;
    mapping(uint => uint) public UPLINE_PERCENTAGE;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping(address => mapping (uint => uint)) public EarnedTrx;
    mapping(address=> uint) public loopCheck;
    mapping (address => uint) public createdDate;
    
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress,uint UserId,address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress,uint UserId,address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event Dividend(address UserAddress, uint Amount);
    event dividendTransferred(address indexed UserAddress, uint Amount, uint level);


    constructor(address _tokenAddress, address _dividentAddress) public {
        ownerAddress = msg.sender;
        Token = TRC20(_tokenAddress);
        dividentWallet = _dividentAddress;
        // Level_Price
        LEVEL_PRICE[1] = 450 trx;
        LEVEL_PRICE[2] = 660 trx;
        LEVEL_PRICE[3] = 1500 trx;
        LEVEL_PRICE[4] = 3300 trx;
        LEVEL_PRICE[5] = 7500 trx;
        LEVEL_PRICE[6] = 18000 trx;
        LEVEL_PRICE[7] = 42000 trx;
        LEVEL_PRICE[8] = 90000 trx;
        LEVEL_PRICE[9] = 180000 trx;
        
        UPLINE_PERCENTAGE[1] = 18 trx;
        UPLINE_PERCENTAGE[2] = 15 trx;
        UPLINE_PERCENTAGE[3] = 15 trx;
        UPLINE_PERCENTAGE[4] = 12 trx;
        UPLINE_PERCENTAGE[5] = 9 trx;
        UPLINE_PERCENTAGE[6] = 7 trx;
        UPLINE_PERCENTAGE[7] = 6 trx;
        UPLINE_PERCENTAGE[8] = 6 trx;
        UPLINE_PERCENTAGE[9] = 3 trx;
        UPLINE_PERCENTAGE[10] = 3 trx;
        UPLINE_PERCENTAGE[11] = 3 trx;
        UPLINE_PERCENTAGE[12] = 3 trx;
        
        UserStruct memory userStruct;
        currentId = currentId.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: 0,
            currentLevel:1,
            totalEarningTrx:0,
            referral: new address[](0)
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;

        for (uint i = 1; i <= 9; i++) {
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].levelExpired[i] = 55555555555;
        }
    }

    /**
     * @dev Revert statement
     */ 
    function () external payable {
        revert("Invalid Transaction");
    }
    
    /**
     * @dev To register the User
     * @param _referrerID id of user/referrer who is already in matrix
     */ 
    function regUser(uint _referrerID) public payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= currentId, "Incorrect referrer Id");        
        require(msg.value == LEVEL_PRICE[1], "Incorrect Value");

        if(users[userList[_referrerID]].referral.length >= referrer1Limit)
          _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currentId++;
        
        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningTrx:0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[msg.sender].levelExpired[1] = now.add(PERIOD_LENGTH);
        users[userList[_referrerID]].referral.push(msg.sender);
        createdDate[msg.sender] = now;
        loopCheck[msg.sender] = 0;

        require(address(uint160(dividentWallet)).send((LEVEL_PRICE[1].mul(dividentPercent)).div(10**8)),"Divident share failed");
        
        payForRegister(1, msg.sender, ((LEVEL_PRICE[1].mul(adminFee)).div(10**8)),(LEVEL_PRICE[1].mul(dividentPercent)).div(10**8));        

        emit dividendTransferred( msg.sender, (LEVEL_PRICE[1].mul(dividentPercent)).div(10**8), 1);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    /**
     * @dev To buy the next level by User
     * @param _level level wants to buy
     */ 
    function buyLevel(uint256 _level) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist");
        require(_level > 0 && _level <= 9, "Incorrect level");

        if (_level == 1) {
            require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
            users[msg.sender].levelExpired[1] =  users[msg.sender].levelExpired[1].add(PERIOD_LENGTH);
            users[msg.sender].currentLevel = 1;
        }else {
            require(msg.value == LEVEL_PRICE[_level], "Incorrect Value");
            
            users[msg.sender].currentLevel = _level;

            for (uint i =_level - 1; i > 0; i--) require(users[msg.sender].levelExpired[i] >= now, "Buy the previous level");
            
            if(users[msg.sender].levelExpired[_level] == 0)
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            else 
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
        }
       
        require(address(uint160(dividentWallet)).send((LEVEL_PRICE[_level].mul(dividentPercent)).div(10**8)),"Divident share failed");
        
        loopCheck[msg.sender] = 0;

        payForLevels(_level, msg.sender, ((LEVEL_PRICE[_level].mul(adminFee)).div(10**8)), (LEVEL_PRICE[_level].mul(dividentPercent)).div(10**8));             

        emit dividendTransferred( msg.sender, (LEVEL_PRICE[_level].mul(dividentPercent)).div(10**8), _level);
        emit buyLevelEvent(msg.sender, _level, now);
    }
    
    /**
     * @dev To update the admin fee percentage
     * @param _adminFee  feePercentage (in trx)
     */ 
    function updateFeePercentage(uint256 _adminFee) public returns(bool) {
        require(msg.sender == ownerAddress, "Only OwnerWallet");
        adminFee = _adminFee;
        return true;  
    }
    
    /**
     * @dev To update the upline fee percentage
     * @param _level Level which wants to change
     * @param _upline  feePercentage (in trx)
     */ 
    function updateUplineFee(uint256 _level,uint256 _upline) public returns(bool) {
        require(msg.sender == ownerAddress, "Only OwnerWallet");
         require(_level > 0 && _level <= 12, "Incorrect level");
        UPLINE_PERCENTAGE[_level] = _upline;
        return true;  
    }    
    
    /**
     * @dev To update the level price
     * @param _level Level which wants to change
     * @param _price Level price (in trx)
     */ 
    function updatePrice(uint _level, uint _price) public returns(bool) {
        require(msg.sender == ownerAddress, "Only OwnerWallet");
        require(_level > 0 && _level <= 9, "Incorrect level");
        LEVEL_PRICE[_level] = _price;
        return true;
    }


    /**
     * @dev To lock/unlock the contract
     * @param _lockStatus  status in bool
     */ 
    function contractLock(bool _lockStatus) public returns(bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        lockStatus = _lockStatus;
        return true;
    }
    
    /**
     * @dev To update the token contract address
     * @param _newToken  new Token Address 
     */ 
    function updateToken(address _newToken) public returns(bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        Token = TRC20(_newToken);
        return true;
    }

    function updateDividendAddress(address _dividentAddress) public returns(bool) {
          require(msg.sender == ownerAddress,"only OwnerWallet");
          dividentWallet = _dividentAddress;
          return true;
    }

    function dividendShare(address[] memory addresses, uint256[] memory _amount) public payable returns (bool) {
        require((msg.sender == dividentWallet) || (msg.sender == ownerAddress), "Unauthorized call");
        require(addresses.length == _amount.length, "Invalid length");
        require(msg.value > 0, "Invalid value");
        for(uint i =0 ; i < addresses.length; i++) {
            require(addresses[i] != address(0),"Invalid address");
            require(_amount[i] > 0, "Invalid amount");
            require(users[addresses[i]].isExist, "User not exist");
        }
        uint _divident = msg.value;
        for(uint i = 0; i < addresses.length; i++) {
            require(_divident >= _amount[i],"Insufficient divident");
            require(address(uint160(addresses[i])).send(_amount[i]), "Transfer failed");
            _divident = _divident.sub(_amount[i]);
            emit Dividend(addresses[i], _amount[i]);
        }
        return true;
    }

    /**
     * @dev Contract balance withdraw
     */ 
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "Only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
    
    
    /**
     * @dev View free Referrer Address
     */ 
    function findFreeReferrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].referral.length < referrer1Limit) 
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 254; i++) { 
            if (users[referrals[i]].referral.length == referrer1Limit) {
                if (i < 126) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }
    
   /**
     * @dev To view the referrals
     * @param _userAddress  User who is already in matrix
     */ 
    function viewUserReferral(address _userAddress) external view returns(address[] memory) {
        return users[_userAddress].referral;
    }
    
    /**
     * @dev To view the level expired time
     * @param _userAddress  User who is already in matrix
     * @param _level Level which is wants to view
     */ 
    function viewUserLevelExpired(address _userAddress,uint _level) public view returns(uint) {
        return users[_userAddress].levelExpired[_level];
    }    
         
    /**
     * @dev To get the total earning trx till now
     */
    function getTotalEarnedTrx() public view returns(uint) {
        uint totalTrx;
        
        for (uint i = 1; i <= currentId; i++) {
            totalTrx = totalTrx.add(users[userList[i]].totalEarningTrx);
        }
        
        return totalTrx;
    }          

    /**
     * @dev Internal function
     */ 
    function payForRegister(uint _level,address _userAddress,uint _adminPrice, uint _divident) internal {

        address referer;

        referer = userList[users[_userAddress].referrerID];

        if (!users[referer].isExist) referer = userList[1];

        if (users[referer].levelExpired[_level] >= now) {
            uint256 tobeminted = ((_adminPrice).mul(10**8)).div(0.005 trx);

            if(referer == ownerAddress) 
                require((address(uint160(ownerAddress)).send(LEVEL_PRICE[_level].sub(_divident)))  && Token.mint(msg.sender,tobeminted), "Transaction Failure");
            else 
                require((address(uint160(ownerAddress)).send(_adminPrice)) && address(uint160(referer)).send(LEVEL_PRICE[_level].sub((_adminPrice.add(_divident))))
                && Token.mint(msg.sender,tobeminted), "Transaction Failure");

            users[referer].totalEarningTrx = users[referer].totalEarningTrx.add(LEVEL_PRICE[_level].sub(_adminPrice.add(_divident)));
            EarnedTrx[referer][_level] =  EarnedTrx[referer][_level].add(LEVEL_PRICE[_level].sub(_adminPrice.add(_divident)));
            users[ownerAddress].totalEarningTrx = users[ownerAddress].totalEarningTrx.add(_adminPrice);
            EarnedTrx[ownerAddress][_level] =  EarnedTrx[ownerAddress][_level].add(_adminPrice);
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer, users[referer].id, _level, LEVEL_PRICE[_level], now);
        }else {
            emit lostMoneyForLevelEvent(msg.sender,users[msg.sender].id,referer,users[referer].id, _level, LEVEL_PRICE[_level],now);
            revert("Referer Not Active");
        }

    }
    
    /**
     * @dev Internal function
     */ 
    function payForLevels(uint _level, address _userAddress, uint _adminPrice, uint _divident) internal {

        address referer;

        referer = userList[users[_userAddress].referrerID];

        if (!users[referer].isExist) referer = userList[1];

        if (loopCheck[msg.sender] > 12) {
            referer = userList[1];
        }

        if (loopCheck[msg.sender] == 0) {
            require((address(uint160(ownerAddress)).send(_adminPrice)), "Transaction Failure");
            users[ownerAddress].totalEarningTrx = users[ownerAddress].totalEarningTrx.add(_adminPrice);
            EarnedTrx[ownerAddress][_level] =  EarnedTrx[ownerAddress][_level].add(_adminPrice);
            loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
        }


        if (users[referer].levelExpired[_level] >= now) {

            if (loopCheck[msg.sender] <= 12) {
                uint uplinePrice = LEVEL_PRICE[_level].sub((_adminPrice.add(_divident)));
                
                // transactions 
                if(referer != ownerAddress) {
                    uint256 tobeminted = ((_adminPrice).mul(10**8)).div(0.005 trx);
                    require((address(uint160(referer)).send(uplinePrice.mul(UPLINE_PERCENTAGE[loopCheck[msg.sender]]).div(10**8)))
                    && Token.mint(referer,tobeminted.mul(UPLINE_PERCENTAGE[loopCheck[msg.sender]]).div(10**8)),"Transaction Failure");
                    users[referer].totalEarningTrx = users[referer].totalEarningTrx.add(uplinePrice.mul(UPLINE_PERCENTAGE[loopCheck[msg.sender]]).div(10**8));
                    EarnedTrx[referer][_level] =  EarnedTrx[referer][_level].add(uplinePrice.mul(UPLINE_PERCENTAGE[loopCheck[msg.sender]]).div(10**8));
                    loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                }
                else {
                    require((address(uint160(referer)).send(address(this).balance)),"Transaction Failure");
                    users[referer].totalEarningTrx = users[referer].totalEarningTrx.add(address(this).balance);
                    EarnedTrx[referer][_level] =  EarnedTrx[referer][_level].add(address(this).balance);
                    loopCheck[msg.sender] = 13;
                }
                
                emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer, users[referer].id, _level, LEVEL_PRICE[_level], now);
                payForLevels(_level, referer, _adminPrice, _divident);
            }
        } else {
            if (loopCheck[msg.sender] <= 12) {
                emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer,users[referer].id, _level, LEVEL_PRICE[_level], now);
                payForLevels(_level, referer, _adminPrice, _divident);

            }
        }
    }
   
}