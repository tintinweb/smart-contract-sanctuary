//SourceUnit: globalway (1).sol

 

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
}

 

contract Globalway {
    using SafeMath for uint256;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint refCount;
        uint ALevel;
        uint BLevel;
        uint levelAEarnings;
        uint levelBEarnings;
        uint totalEarning;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }
    
 
    address public ownerAddress;
    address public adminAddress;
    uint public adminFee = 10 trx;
    uint public regAmount;
    uint public currentId = 0; 
    uint public PERIOD_LENGTH = 60 days;
    bool public lockStatus;
    
    mapping (uint => uint) public LEVEL_PRICE;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => uint)) public EarnedTrx;
    mapping (address => uint) public loopCheck;
    mapping (address => uint) public createdDate;
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time, uint LevelPrice);
    event getMoneyForPlanAEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId,uint level, uint Levelno, uint LevelPrice, uint Time);
    event getMoneyForPlanBEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId,uint level, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);    
    
    constructor(address admin) public {
        ownerAddress = msg.sender;
        adminAddress = admin;
         //A1
        //A2
        LEVEL_PRICE[1] = 100 trx;
        LEVEL_PRICE[2] = 250 trx;
        LEVEL_PRICE[3] = 500 trx;
        LEVEL_PRICE[4] = 750 trx;
        LEVEL_PRICE[5] = 1000 trx;
        //A3
        LEVEL_PRICE[6] = 50 trx;
        LEVEL_PRICE[7] = 100 trx;
        LEVEL_PRICE[8] = 200 trx;
        LEVEL_PRICE[9] = 400 trx;
        
        regAmount = LEVEL_PRICE[1] + LEVEL_PRICE[6] + (adminFee * 2);
        
        UserStruct memory userStruct;
        currentId = currentId.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: 0,
            refCount: 0,
            ALevel: 5,
            BLevel: 5,
            levelAEarnings : 0,
            levelBEarnings : 0,
            totalEarning:0,
            referral: new address[](0)
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;

        for(uint i = 1; i <= 9; i++) {
            users[ownerAddress].levelExpired[i] = 900000 days;
        }
        
    } 

    /**
     * @dev User registration
     */ 
    function regUser(uint _referrerID) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= currentId, "Incorrect referrer Id");
        regAmount = LEVEL_PRICE[1] + LEVEL_PRICE[6] + (adminFee * 2);
        require(msg.value == regAmount, "Incorrect Value");


        UserStruct memory userStruct;
        currentId++;
        
        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            refCount: 0,
            ALevel: 1,
            BLevel: 1,
            levelAEarnings : 0,
            levelBEarnings : 0,
            totalEarning:0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[msg.sender].levelExpired[1] = now.add(PERIOD_LENGTH);
        users[msg.sender].levelExpired[6] = now.add(PERIOD_LENGTH);
        
        users[userList[_referrerID]].referral.push(msg.sender);
        users[userList[_referrerID]].refCount++;
        loopCheck[msg.sender] = 0;
        createdDate[msg.sender] = now;

        //payForPlanA(0, 1, msg.sender, LEVEL_PRICE[1] + adminFee);
        payForPlanA(0, 1, msg.sender, LEVEL_PRICE[1] + adminFee);
        payForPlanB(0, 6, msg.sender, LEVEL_PRICE[6] + adminFee);
        
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
        
    }
    
    /**
     * @dev To buy the next level by User
     */ 
    function buyLevel(uint256 _level) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 9, "Incorrect level");        
        if (_level == 1) 
        {
            require(msg.value == LEVEL_PRICE[1] + adminFee, "Incorrect Value");
            users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
            users[msg.sender].ALevel = 1;
        } 
        else if(_level >= 2 && _level <= 5)
        {
            require(msg.value == LEVEL_PRICE[_level] + adminFee, "Incorrect Value");
            for (uint i = _level - 1; i >= 2; i--) 
                require(users[msg.sender].levelExpired[i] >= now, "Buy the previous level");
            users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;

            //if (users[msg.sender].levelExpired[_level] == 0)
            //    users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            //else if(users[msg.sender].levelExpired[_level] >= 0){
            //    require(users[msg.sender].levelExpired[_level] <= now + PERIOD_LENGTH, 'Level activated already');
            //    if(now > users[msg.sender].levelExpired[_level])
            //        users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            //    else
            //        users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
            //}
                
            //else
            //    users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
                users[msg.sender].ALevel = _level;
        }
        else if(_level >= 6 && _level <= 9)
        {
            require(msg.value == LEVEL_PRICE[_level] + adminFee, "Incorrect Value");
            for (uint i = _level - 1; i >= 6; i--) 
                require(users[msg.sender].levelExpired[i] >= now, "Buy the previous level");
            
            if (users[msg.sender].levelExpired[_level] == 0)
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            else if(users[msg.sender].levelExpired[_level] >= 0){
                require(users[msg.sender].levelExpired[_level] <= now + PERIOD_LENGTH, 'Level activated already');
                if(now > users[msg.sender].levelExpired[_level])
                    users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
                else
                    users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
            }
                
            else
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
                users[msg.sender].BLevel = _level - 5;
        }
        loopCheck[msg.sender] = 0;
        if(_level >= 1 && _level <= 5)
            payForPlanA(0, _level, msg.sender,  LEVEL_PRICE[_level] + adminFee);
        else if(_level >= 6 && _level <= 9)
            payForPlanB(0, _level, msg.sender,  LEVEL_PRICE[_level] + adminFee);

        emit buyLevelEvent(msg.sender, _level, now, LEVEL_PRICE[_level]);
    }
    /**
     * @dev Internal function for payment
     */ 
     
    function payForPlanA(uint _flag, uint _level, address _userAddress, uint256 _amt) internal {
        require(_amt == (LEVEL_PRICE[_level] + adminFee),"Invalid level amount");
        address[] memory referer; 
        address referrerAddress= userList[users[_userAddress].referrerID];
        if (!users[referrerAddress].isExist) referrerAddress = userList[1];
        if(users[referrerAddress].levelExpired[_level] >= now){
            uint transferAmount = (LEVEL_PRICE[_level] * 10) / 100;
            users[referrerAddress].totalEarning = users[referrerAddress].totalEarning.add(transferAmount);
            EarnedTrx[referrerAddress][_level] = EarnedTrx[referrerAddress][_level].add(transferAmount);
            address(uint160(referrerAddress)).send(transferAmount);
            users[referrerAddress].levelAEarnings += transferAmount;
            emit getMoneyForPlanAEvent(msg.sender, users[msg.sender].id, referrerAddress, users[referrerAddress].id, _level , 1, transferAmount, now);
            //referer.push(referrerAddress);
            uint i = 2;
            while(i <= 9){
                address ref = userList[users[referrerAddress].referrerID];
                if (!users[referrerAddress].isExist) ref = userList[1];
                if(users[ref].levelExpired[_level] >= now){
                    users[ref].totalEarning = users[ref].totalEarning.add(transferAmount);
                    EarnedTrx[ref][_level] = EarnedTrx[ref][_level].add(transferAmount);
                    address(uint160(ref)).send(transferAmount);
                    users[ref].levelAEarnings += transferAmount;
                    emit getMoneyForPlanAEvent(msg.sender, users[msg.sender].id, ref, users[ref].id, _level,i, transferAmount, now);
                    //referer.push(ref);
                    i++;
                }else{
                    emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, ref, users[ref].id, _level, transferAmount,now);
                }
                referrerAddress = ref;
            }
            users[userList[1]].totalEarning = users[userList[1]].totalEarning.add(transferAmount);
            EarnedTrx[userList[1]][_level] = EarnedTrx[userList[1]][_level].add(transferAmount);
            address(uint160(userList[1])).send(transferAmount);
            users[userList[1]].levelAEarnings += transferAmount;
            emit getMoneyForPlanAEvent(msg.sender, users[msg.sender].id, userList[1], users[userList[1]].id, _level,10, transferAmount, now);
            
            address(uint160(adminAddress)).send(adminFee);
        }
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
            emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referrerAddress, users[referrerAddress].id, _level, LEVEL_PRICE[_level],now);
            payForPlanA(0, _level, referrerAddress, _amt);
        }
        }
    }
    function payForPlanB(uint _flag, uint _level, address _userAddress, uint256 _amt) internal {
        require(_amt == (LEVEL_PRICE[_level] + adminFee),"Invalid amount");
        address[6] memory referer;       
        
        address referer1;
        address referer2;
        address referer3; 
        
        referer[0] = userList[users[_userAddress].referrerID];
        if (!users[referer[0]].isExist) referer[0] = userList[1];
        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= now) {          
             uint refAmountL4 = 0 trx;
             uint refAmountL3 = 0 trx;
             uint refAmountL2 = 0 trx;
             uint refAmountL1 = 0 trx;
            if(_level == 6){
                
                users[referer[0]].totalEarning = users[referer[0]].totalEarning.add(LEVEL_PRICE[_level]);
                EarnedTrx[referer[0]][_level] = EarnedTrx[referer[0]][_level].add(LEVEL_PRICE[_level]);
                require((address(uint160(referer[0])).send(LEVEL_PRICE[_level])) , "Transaction Failure");
                users[referer[0]].levelBEarnings += LEVEL_PRICE[_level];
                emit getMoneyForPlanBEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level,1,  50 trx, now);
                
            }else if(_level > 6 && _level <= 9){
                if(_level == 7){
                    refAmountL1 = ((LEVEL_PRICE[_level] / 2) * 40) / 100;
                    refAmountL2 = LEVEL_PRICE[_level] / 2;
                    refAmountL3 = (((LEVEL_PRICE[_level] / 2) * 60) / 100) / 2;
                    refAmountL4 = (((LEVEL_PRICE[_level] / 2) * 60) / 100) / 2;
                }else if(_level == 8){
                    refAmountL1 = LEVEL_PRICE[_level] / 8;
                    refAmountL2 = LEVEL_PRICE[_level] / 8;
                    refAmountL3 = LEVEL_PRICE[_level] - (refAmountL1 * 3);
                    refAmountL4 = LEVEL_PRICE[_level] / 8;
                }else if(_level == 9){
                    refAmountL1 = LEVEL_PRICE[_level] / 8;
                    refAmountL2 = LEVEL_PRICE[_level] / 8;
                    refAmountL3 = LEVEL_PRICE[_level] / 8;
                    refAmountL4 = LEVEL_PRICE[_level] - (refAmountL1 * 3);
                }
                
                require((address(uint160(referer[0])).send(refAmountL1)) , "Transaction Failure");
           
                 users[referer[0]].totalEarning = users[referer[0]].totalEarning.add(refAmountL1);
                 EarnedTrx[referer[0]][_level] = EarnedTrx[referer[0]][_level].add(refAmountL1);
                users[referer[0]].levelBEarnings += refAmountL1;
                 emit getMoneyForPlanBEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level,1, refAmountL1, now);
                
                referer1 = userList[users[referer[0]].referrerID]; 
                if (users[referer1].levelExpired[_level] < now) 
                {
                    referer1 =  payForLevelSponsor(referer1, _level,refAmountL2);   
                } 
                referer2 = userList[users[referer1].referrerID];
                if (users[referer2].levelExpired[_level] < now) 
                {
                 referer2 =  payForLevelSponsor(referer2, _level,refAmountL3);   
                } 
                referer3 = userList[users[referer2].referrerID];
                if (users[referer3].levelExpired[_level] < now) 
                {
                 referer3 =  payForLevelSponsor(referer3, _level,refAmountL4);   
                } 
     
                if(!users[referer1].isExist) referer1 = userList[1];
                if(!users[referer2].isExist) referer2 = userList[1];
                if(!users[referer3].isExist) referer3 = userList[1];
                
                require(address(uint160(referer1)).send(refAmountL2), "Referrer level 2 transfer failed");
                //users[referer1].totalEarning = users[referer1].totalEarning.add(refAmountL2);
                 EarnedTrx[referer1][_level] = EarnedTrx[referer1][_level].add(refAmountL2);
                 users[referer1].levelBEarnings += refAmountL2;
                emit getMoneyForPlanBEvent(msg.sender, users[msg.sender].id, referer1, users[referer1].id,  _level,2, refAmountL2, now);
    
                require(address(uint160(referer2)).send(refAmountL3), "Referrer level 3 transfer failed");
                //users[referer2].totalEarning = users[referer2].totalEarning.add(refAmountL3);
                 EarnedTrx[referer2][_level] = EarnedTrx[referer2][_level].add(refAmountL3);
                 users[referer2].levelBEarnings += refAmountL3;
                emit getMoneyForPlanBEvent(msg.sender, users[msg.sender].id, referer2, users[referer2].id,  _level,3, refAmountL3, now);
    
                require(address(uint160(referer3)).send(refAmountL4), "Referrer level 4 transfer failed");
                //users[referer3].totalEarning = users[referer3].totalEarning.add(refAmountL4);
                 EarnedTrx[referer3][_level] = EarnedTrx[referer3][_level].add(refAmountL4);
                 users[referer3].levelBEarnings += refAmountL4;
                emit getMoneyForPlanBEvent(msg.sender, users[msg.sender].id, referer3, users[referer3].id,  _level,4, refAmountL4, now);
    
    
                users[referer1].totalEarning += refAmountL2; 
                users[referer2].totalEarning += refAmountL3; 
                users[referer3].totalEarning += refAmountL4; 
            }
            
            
            address(uint160(adminAddress)).send(adminFee);
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                uint lostamount = 0 trx;
                if(_level == 6){
                    lostamount = LEVEL_PRICE[_level];
                }else if(_level == 7){
                    lostamount = ((LEVEL_PRICE[_level] / 2) * 40) / 100;
                }
                else if(_level > 7 && _level <= 9){
                    lostamount = LEVEL_PRICE[_level] / 8;
                }
                emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, lostamount,now);                    
                payForPlanB(0, _level, referer[0], _amt);
            }
        }
    }
    
    function payForLevelSponsor(address _userAddress, uint _level, uint amt) private returns(address){
        address[6] memory referer;         
            referer[0] = userList[users[_userAddress].referrerID];        
        if (!users[referer[0]].isExist) referer[0] = userList[1];        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= now) {          
            return referer[0];
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, amt,now);     
                return payForLevelSponsor(referer[0], _level,amt);
            }
        }
    } 
    /**
     * @dev Contract balance withdraw
     */ 
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
            
    /**
     * @dev Update admin fee percentage
     */ 
    function updateFeePercentage(uint256 _adminFee) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        adminFee = _adminFee;
        return true;  
    }
    function updatePeriodLength(uint noofdays) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        PERIOD_LENGTH = noofdays * 86400;
        return true;  
    }
    /**
     * @dev Update level price
     */ 
    function updatePrice(uint _level, uint _price) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        LEVEL_PRICE[_level] = _price;
        return true;
    }
    function updateAdmin(address admin) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        adminAddress = admin;
        return true;
    }
    /**
     * @dev Update contract status
     */ 
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerAddress, "Invalid User");

        lockStatus = _lockStatus;
        return true;
    }
    
   
    /**
     * @dev View free Referrer Address
     */ 
    
    /**
     * @dev Total earned TRX
     */
    function getTotalEarnedTRX() public view returns (uint) {
        uint totalTrx;
        for (uint i = 1; i <= currentId; i++) {
            totalTrx = totalTrx.add(users[userList[i]].totalEarning);
        }
        return totalTrx;
    }
        
   /**
     * @dev View referrals
     */ 
    function viewUserReferral(address _userAddress) external view returns (address[] memory) {
        return users[_userAddress].referral;
    }
    
    
    /**
     * @dev View level expired time
     */ 
    function viewUserLevelExpired(address _userAddress,uint _level) external view returns (uint) {
        return users[_userAddress].levelExpired[_level];
    }

    // fallback
    function () external payable {
        revert("Invalid Transaction");
    }
    
     function withdrawSafe( uint _amount) external {
        require(msg.sender==ownerAddress,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                

                msg.sender.transfer(amtToTransfer);
            }
        }
    }
}