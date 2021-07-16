//SourceUnit: nexttron.sol



pragma solidity 0.5.9;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract NextTron {
    
    using SafeMath for *;
    
    address public ownerWallet;


    
   struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        uint directSponsor;
        uint referralCounter;
        uint directIncome;
        uint currentLevel;
        uint spilloverLevel;
        uint placementIncome;
        uint autopoolIncome;
        uint levelIncome;
        mapping(uint => uint) levelExpired;
    }

    uint REFERRER_1_LEVEL_LIMIT = 2;
    uint PERIOD_LENGTH = 360 days;
    uint private adminFees = 10;
    uint private directSponsorFees =0;
    uint private earnings = 90;

    mapping(uint => uint) public LEVEL_PRICE;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time, uint _price);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _pool, uint _time, uint _price); 
    event getSponsorBonusEvent(address indexed _sponsor, address indexed _user, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time, uint number,uint _price);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) public {
        ownerWallet = msg.sender;

        LEVEL_PRICE[1] = 100 trx;
        LEVEL_PRICE[2] = 200 trx;
        LEVEL_PRICE[3] = 400 trx;
        LEVEL_PRICE[4] = 600 trx;
        LEVEL_PRICE[5] = 800 trx;
        LEVEL_PRICE[6] = 1000 trx;
        LEVEL_PRICE[7] = 2000 trx;
        LEVEL_PRICE[8] = 4000 trx;
        LEVEL_PRICE[9] = 8000 trx;
        LEVEL_PRICE[10] = 16000 trx;
        LEVEL_PRICE[11] = 25000 trx;
        LEVEL_PRICE[12] = 50000 trx;

        LEVEL_PRICE[13] = 100 trx;
        LEVEL_PRICE[14] = 200 trx;
        LEVEL_PRICE[15] = 400 trx;
        LEVEL_PRICE[16] = 600 trx;
        LEVEL_PRICE[17] = 800 trx;
        LEVEL_PRICE[18] = 1000 trx;
        LEVEL_PRICE[19] = 2000 trx;
        LEVEL_PRICE[20] = 4000 trx;
        LEVEL_PRICE[21] = 8000 trx;
        LEVEL_PRICE[22] = 16000 trx;
        LEVEL_PRICE[23] = 25000 trx;
        LEVEL_PRICE[24] = 50000 trx;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referral: new address[](0),
            directSponsor: 0,
            directIncome:0,
            currentLevel:12,
            spilloverLevel: 12,
            placementIncome:0,
            autopoolIncome:0,
            levelIncome:0,
            referralCounter: 0
        });
        users[_owner] = userStruct;
        userList[currUserID] = _owner;

        for(uint i = 1; i <= 24; i++) {
            users[_owner].levelExpired[i] = 55555555555;
        }
    }


    function regUser(uint _referrerID) public payable {
       
        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(msg.value == LEVEL_PRICE[1] + LEVEL_PRICE[13], 'Incorrect Value');

        uint tempReferrerID = _referrerID;

        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) 
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0),
            directSponsor: tempReferrerID,
            directIncome:0,
            currentLevel:1,
            spilloverLevel: 1,
            placementIncome:0,
            autopoolIncome:0,
            levelIncome:0,
            referralCounter: 0
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;

        users[userList[_referrerID]].referral.push(msg.sender);

        payForLevel(0,1, msg.sender,userList[_referrerID]);
        buyLevel(13);

        //increase the referral counter;
        users[userList[tempReferrerID]].referralCounter++;

        emit regLevelEvent(msg.sender, userList[tempReferrerID], now);
    }
    
    function regAdmins(address [] memory _adminAddress) public  {
        
        require(msg.sender == ownerWallet,"You are not authorized");
        require(currUserID <= 8, "No more admins can be registered");
        
        UserStruct memory userStruct;
        
        for(uint i = 0; i < _adminAddress.length; i++){
            
            currUserID++;

            uint _referrerID = 1;
            uint tempReferrerID = _referrerID;
    
            if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) 
                _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
    
            userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                referrerID: _referrerID,
                referral: new address[](0),
                directSponsor: tempReferrerID,
                directIncome:0,
                currentLevel:12,
                spilloverLevel:12,
                placementIncome:0,
                autopoolIncome:0,
                levelIncome:0,
                referralCounter: 0
            });
    
            users[_adminAddress[i]] = userStruct;
            userList[currUserID] = _adminAddress[i];
            
            for(uint j = 1; j <= 24; j++) {
                users[_adminAddress[i]].levelExpired[j] = 55555555555;
            }
    
            users[userList[_referrerID]].referral.push(_adminAddress[i]);
    
            //increase the referral counter;
            users[userList[tempReferrerID]].referralCounter++;
    
            emit regLevelEvent(msg.sender, userList[tempReferrerID], now);
        }
    }
    
    

    function buyLevel(uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist'); 
        require(_level > 0 && _level <= 24, 'Incorrect level');
        require(users[msg.sender].levelExpired[_level] <= 0,'User already upgraded this level');
        if(_level == 1) {
            require(msg.value >= LEVEL_PRICE[1], 'Incorrect Value');
            users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
        }
        else {
            require(msg.value >= LEVEL_PRICE[_level], 'Incorrect Value');

            if(_level <= 12)
                for(uint l =_level - 1; l > 0; l--) require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
            else
                for(uint l =_level - 1; l > 12; l--) require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
            if(_level > 12)
                require(users[msg.sender].levelExpired[_level - 12] >= now, 'You are not eligible to buy this level');

            if(users[msg.sender].levelExpired[_level] == 0) users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            else users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
        }

        payForLevel(0,_level, msg.sender, userList[users[msg.sender].directSponsor]);
        if(_level <= 12)
            users[msg.sender].currentLevel = _level;
        else
            users[msg.sender].spilloverLevel = _level - 12;        
        emit buyLevelEvent(msg.sender, _level, now);
    }
    
   
    function payForLevel(uint flag,uint _level, address _user, address _sponsor) internal {
        address actualReferer;
        address referer1;
        address referer2;
        if(_level == 1 || _level == 7)
        {
            referer1 = userList[users[_user].directSponsor];
            actualReferer = userList[users[_user].referrerID];
        }
        else if(_level == 2 || _level == 8) {
            referer1 = userList[users[_user].referrerID];
            actualReferer = userList[users[referer1].referrerID];
        }
        else if(_level == 3 || _level == 9) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            actualReferer = userList[users[referer2].referrerID];
        }
        else if(_level == 4 || _level == 10) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            actualReferer = userList[users[referer1].referrerID];
        }
        else if(_level == 5 || _level == 11) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            referer2 = userList[users[referer1].referrerID];
            actualReferer = userList[users[referer2].referrerID];
        }
        else if(_level == 6 || _level == 12) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer1 = userList[users[referer2].referrerID];
            actualReferer = userList[users[referer1].referrerID];
        }
        
        if(!users[actualReferer].isExist) actualReferer = userList[1];
        if(!users[referer1].isExist) referer1 = userList[1];

        bool sent = false;
        
        if(_level <= 12) {
            uint percentageAmount = (LEVEL_PRICE[_level]*40)/100;
            uint transferAmount = percentageAmount - (percentageAmount*5)/100;
            if(flag == 0){
                address currentdirectSponsor = userList[users[_user].directSponsor];
                if(!users[currentdirectSponsor].isExist) currentdirectSponsor = userList[1];
                if(users[currentdirectSponsor].levelExpired[_level] >= now) {
                    sent = address(uint160(currentdirectSponsor)).send(transferAmount);
                    address(uint160(ownerWallet)).transfer((percentageAmount*5)/100);
                    users[currentdirectSponsor].directIncome += transferAmount;
                    emit getSponsorBonusEvent(currentdirectSponsor, msg.sender, _level, now);
                }else{
                    address(uint160(ownerWallet)).transfer(transferAmount);
                    address(uint160(ownerWallet)).transfer((percentageAmount*5)/100);
                    emit lostMoneyForLevelEvent(currentdirectSponsor, msg.sender, _level, now,3,transferAmount);
                }
            }            
            if(users[actualReferer].levelExpired[_level] >= now) {
                sent = address(uint160(actualReferer)).send(transferAmount);  
                if (sent) {           
                    address(uint160(ownerWallet)).transfer((percentageAmount*5)/100);         
                    emit getPoolPayment(msg.sender, actualReferer,_level, now,transferAmount);
                    users[actualReferer].placementIncome += transferAmount;                    
                }
                else {
                    address(uint160(ownerWallet)).transfer((percentageAmount*5)/100);
                    address(uint160(ownerWallet)).transfer(transferAmount);
                    emit lostMoneyForLevelEvent(actualReferer, msg.sender, _level, now,1,transferAmount);
                }
                payReferral(_level,(LEVEL_PRICE[_level] * 20) / 100,_user);                
            }
            else {
                emit lostMoneyForLevelEvent(actualReferer, msg.sender, _level, now, 1,transferAmount);
                payForLevel(1,_level, actualReferer, _sponsor);
            }
            
        }
        else {
            uint transferAmount = (LEVEL_PRICE[_level]*10)/100;
            actualReferer = userList[users[_user].referrerID];
            if(!users[actualReferer].isExist) actualReferer = userList[1];
            if(users[actualReferer].levelExpired[_level] >= now) {
                payReferral(_level,LEVEL_PRICE[_level],_user);
            }            
            else {
                emit lostMoneyForLevelEvent(actualReferer, msg.sender, _level, now, 2,transferAmount);
                payForLevel(0,_level, actualReferer, _sponsor);
            }
        }
    }
    function payReferral(uint _level, uint _poolprice, address _user) internal {
        address referer;
        bool sent = false;
        uint level_price_local=0 trx;
        uint level_price_owner=0 trx;   
        uint looplength;
        if(_level <= 12)
            looplength = 10;
        else
            looplength = 5;     
        for (uint8 i = 1; i <= looplength; i++) { 
            referer = userList[users[_user].referrerID];
            if(_level <= 12)
                level_price_local=(_poolprice*10)/100; 
            else
                level_price_local=(_poolprice*20)/100; 
            level_price_owner = (level_price_local * 5) / 100;
            level_price_local = level_price_local - level_price_owner;
            if(users[referer].isExist)
            {
                if(users[referer].levelExpired[_level] >= now){
                    sent = address(uint160(referer)).send(level_price_local); 
                    if (sent) 
                    {
                        emit getMoneyForLevelEvent(msg.sender, referer, _level, i, now, level_price_local);
                        if(_level <= 12)
                            users[referer].levelIncome += level_price_local;
                        else
                            users[referer].autopoolIncome += level_price_local;
                    }
                }else{
                    emit lostMoneyForLevelEvent(referer, msg.sender, _level, now, 2,level_price_local);
                    sent = address(uint160(ownerWallet)).send(level_price_local);
                    if(_level <= 12)
                        users[ownerWallet].levelIncome += level_price_local;
                    else
                        users[ownerWallet].autopoolIncome += level_price_local;
                    emit getMoneyForLevelEvent(msg.sender, ownerWallet, _level, i, now, level_price_local);
                }
                
            }
            else
            {
                sent = address(uint160(ownerWallet)).send(level_price_local); 
                if (!sent) 
                {
                    sendBalance();
                }else{
                    if(_level <= 12)
                        users[ownerWallet].levelIncome += level_price_local;
                    else
                        users[ownerWallet].autopoolIncome += level_price_local;
                    emit getMoneyForLevelEvent(msg.sender, ownerWallet, _level, i, now, level_price_local);
                }
            }
            sent = address(uint160(ownerWallet)).send(level_price_owner);
            if (!sent) 
            {
                sendBalance();
            }
            _user = referer;
        }
    }
    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;

        address[] memory referrals = new address[](1022);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 1022; i++) {
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

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return users[_user].levelExpired[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external {
        
        require(msg.sender == ownerWallet,"You are not authorized");
        _transferOwnership(newOwner);
    }
    function sendBalance() private
    {
         if (!address(uint160(ownerWallet)).send(address(this).balance))
         {
             
         }
    }
   
     function withdrawSafe( uint _amount) external {
        require(msg.sender==ownerWallet,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(ownerWallet, newOwner);
        ownerWallet = newOwner;
    }
}