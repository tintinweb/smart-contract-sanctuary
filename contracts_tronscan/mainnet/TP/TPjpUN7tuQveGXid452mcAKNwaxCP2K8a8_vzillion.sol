//SourceUnit: Vzillion (1).sol

 

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

 

contract vzillion {
    using SafeMath for uint256;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint refCount;
        uint p1referrerID;
        uint p2referrerID;
        uint currentLevel;
        uint totalEarning;
        address[] referral;
        address[] p1referral;
        address[] p2referral;
        mapping(uint => uint) levelExpired;
    }
    
 
    address public ownerAddress;
    uint public adminFee = 10;
    uint public currentId = 0; 
    uint public PERIOD_LENGTH = 3650 days;
    bool public lockStatus;
    
    mapping (uint => uint) public LEVEL_PRICE;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => uint)) public EarnedTrx;
    mapping (address => uint) public loopCheck;
    mapping (address => uint) public createdDate;
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time, uint LevelPrice);
    event getMoneyForRefLevelEvent(address indexed _user, address indexed _referral, uint _buylevel, uint _level, uint _time, uint LevelPrice);
    event getMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);    
    
    constructor() public {
        ownerAddress = msg.sender;
         
         //A1
        LEVEL_PRICE[1] = 100 trx;
        LEVEL_PRICE[2] = 150 trx;
        LEVEL_PRICE[3] = 250 trx;
        //A2
        LEVEL_PRICE[4] = 300 trx;
        LEVEL_PRICE[5] = 325 trx;
        LEVEL_PRICE[6] = 375 trx;
        //A3
        LEVEL_PRICE[7] = 750 trx;
        LEVEL_PRICE[8] = 1000 trx;
        LEVEL_PRICE[9] = 1500 trx;
        LEVEL_PRICE[10] = 1750 trx;
       //A4
        LEVEL_PRICE[11] = 2500 trx;
        LEVEL_PRICE[12] = 5000 trx;
        LEVEL_PRICE[13] = 7500 trx;
        LEVEL_PRICE[14] = 10000 trx;
        LEVEL_PRICE[15] = 15000 trx;
        //B1
        LEVEL_PRICE[16] = 20000 trx;
        LEVEL_PRICE[17] = 23000 trx;
        LEVEL_PRICE[18] = 27000 trx;
        LEVEL_PRICE[19] = 30000 trx;
        //B2
        LEVEL_PRICE[20] = 32000 trx;
        LEVEL_PRICE[21] = 35000 trx;
        LEVEL_PRICE[22] = 40000 trx;
        LEVEL_PRICE[23] = 43000 trx;
        //B3
        LEVEL_PRICE[24] = 50000 trx;
        LEVEL_PRICE[25] = 55000 trx;
        LEVEL_PRICE[26] = 60000 trx;
        LEVEL_PRICE[27] = 65000 trx;
        LEVEL_PRICE[28] = 70000 trx;
        //B4
        LEVEL_PRICE[29] = 100000 trx;
        LEVEL_PRICE[30] = 110000 trx;
        LEVEL_PRICE[31] = 120000 trx;
        LEVEL_PRICE[32] = 130000 trx;
        LEVEL_PRICE[33] = 140000 trx;
        
        
        //C1
        LEVEL_PRICE[34] = 200000 trx;
        LEVEL_PRICE[35] = 200000 trx;
        LEVEL_PRICE[36] = 200000 trx;
        LEVEL_PRICE[37] = 200000 trx;
        LEVEL_PRICE[38] = 200000 trx;
        
        //C2
        LEVEL_PRICE[39] = 300000 trx;
        LEVEL_PRICE[40] = 300000 trx;
        LEVEL_PRICE[41] = 300000 trx;
        LEVEL_PRICE[42] = 300000 trx;
        LEVEL_PRICE[43] = 300000 trx;
        
        //C3
        LEVEL_PRICE[44] = 500000 trx;
        LEVEL_PRICE[45] = 500000 trx;
        LEVEL_PRICE[46] = 500000 trx;
        LEVEL_PRICE[47] = 500000 trx;
        LEVEL_PRICE[48] = 500000 trx;
        
        UserStruct memory userStruct;
        currentId = currentId.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: 0,
            refCount: 0,
            p1referrerID: 0,
            p2referrerID: 0,
            currentLevel:1,
            totalEarning:0,
            referral: new address[](0),
            p1referral: new address[](0),
            p2referral: new address[](0)
            
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;

        for(uint i = 1; i <= 48; i++) {
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].levelExpired[i] = 55555555555;
        }
        
    } 

    /**
     * @dev User registration
     */ 
    function regUser(uint _referrerID) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= currentId, "Incorrect referrer Id");
        require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
         
        uint p1referrerID = _referrerID;
        uint p2referrerID = _referrerID;

        if(users[userList[_referrerID]].p1referral.length >= 3) 
            p1referrerID = users[findFreep1Referrer(userList[_referrerID])].id;

        if(users[userList[_referrerID]].p2referral.length >= 3) 
            p2referrerID = users[findFreep2Referrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currentId++;
        
        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            p1referrerID: p1referrerID,
            p2referrerID: p2referrerID,
            refCount: 0,
            currentLevel: 1,
            totalEarning:0,
            referral: new address[](0),
            p1referral: new address[](0),
            p2referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[msg.sender].levelExpired[1] = now.add(PERIOD_LENGTH);
        users[userList[_referrerID]].referral.push(msg.sender);
        users[userList[_referrerID]].refCount++;
        loopCheck[msg.sender] = 0;
        createdDate[msg.sender] = now;

        payForLevel(0, 1, msg.sender, msg.value);

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
    
    /**
     * @dev To buy the next level by User
     */ 
    function buyLevel(uint256 _level) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 48, "Incorrect level");
        require(users[msg.sender].levelExpired[_level] == 0, 'Level activated already');

        if (_level == 1) 
        {
            require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
            users[msg.sender].levelExpired[1] = users[msg.sender].levelExpired[1].add(PERIOD_LENGTH);
            users[msg.sender].currentLevel = 1;
        } 
        else
        {
            require(msg.value == LEVEL_PRICE[_level], "Incorrect Value");
            users[msg.sender].currentLevel = _level;
            for (uint i = _level - 1; i > 0; i--) 
                require(users[msg.sender].levelExpired[i] >= now, "Buy the previous level");
            
            if (users[msg.sender].levelExpired[_level] == 0)
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            else 
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
        }
        loopCheck[msg.sender] = 0;
        if(_level <= 15)
            payForLevel(0, _level, msg.sender,  msg.value);
        else if(_level >= 16 && _level <= 33)
            payForLevelP1(0, _level, msg.sender,  msg.value);
        else if(_level >= 34 && _level <= 48)
            payForLevelP2(0, _level, msg.sender,  msg.value);

        emit buyLevelEvent(msg.sender, _level, now, LEVEL_PRICE[_level]);
    }
    
    /**
     * @dev Internal function for payment
     */ 
    function payForLevel(uint _flag, uint _level, address _userAddress, uint256 _amt) internal {
        address[6] memory referer;       
        
        address referer1;
        address referer2;
        address referer3; 
        
        if (_flag == 0) 
        {
            if (_level == 1 || _level == 2 || _level == 3 || _level == 16 || _level == 17 || _level == 18 || _level == 19 || _level == 34 || _level == 35 || _level == 36 || _level == 37 || _level == 38) 
            {
                referer[0] = userList[users[_userAddress].referrerID];
            } 
            else if (_level == 4 || _level == 5 || _level == 6 || _level == 20 || _level == 21  || _level == 22 || _level == 23 || _level == 39 || _level == 40 || _level == 41 || _level == 42 || _level == 43) 
            {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[0] = userList[users[referer[1]].referrerID];
            } 
            else if (_level == 7 || _level == 8 || _level == 9 || _level == 10 || _level == 24 || _level == 25 || _level == 26 || _level == 27 || _level == 28 || _level == 44 || _level == 45 || _level == 46 || _level == 47 || _level == 48  ) 
            {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[0] = userList[users[referer[2]].referrerID];
            } 
            else if (_level == 11 || _level == 12 || _level == 13 || _level == 14 || _level == 15 || _level == 29 || _level == 30 || _level == 31  || _level == 32 || _level == 33) 
            {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[0] = userList[users[referer[3]].referrerID];
            } 
            
        } else if (_flag == 1) {
            referer[0] = userList[users[_userAddress].referrerID];
        }
        if (!users[referer[0]].isExist) referer[0] = userList[1];
        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= now) {          
            uint refAmountPrimary = (LEVEL_PRICE[_level]/100)*70;
            uint refAmountSecondry =(LEVEL_PRICE[_level]/100)*10;
            // transactions 
            require((address(uint160(referer[0])).send(refAmountPrimary)) , "Transaction Failure");
           
            users[referer[0]].totalEarning = users[referer[0]].totalEarning.add(refAmountPrimary);
            EarnedTrx[referer[0]][_level] = EarnedTrx[referer[0]][_level].add(refAmountPrimary);
          
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, refAmountPrimary, now);
            
            referer1 = userList[users[referer[0]].referrerID]; 
            if (users[referer1].currentLevel < _level) 
            {
             referer1 =  payForLevelSponsor(referer1, _level);   
            } 
            referer2 = userList[users[referer1].referrerID];
            if (users[referer2].currentLevel < _level) 
            {
             referer2 =  payForLevelSponsor(referer2, _level);   
            } 
            referer3 = userList[users[referer2].referrerID];
            if (users[referer3].currentLevel < _level) 
            {
             referer3 =  payForLevelSponsor(referer3, _level);   
            } 
 
            if(!users[referer1].isExist) referer1 = userList[1];
            if(!users[referer2].isExist) referer2 = userList[1];
            if(!users[referer3].isExist) referer3 = userList[1];
            
            require(address(uint160(referer1)).send(refAmountSecondry), "Referrer level 1 transfer failed");
            emit getMoneyForRefLevelEvent(referer1, msg.sender,1, _level, now,refAmountSecondry);

            require(address(uint160(referer2)).send(refAmountSecondry), "Referrer level 2 transfer failed");
            emit getMoneyForRefLevelEvent(referer2, msg.sender,2, _level, now,refAmountSecondry);

            require(address(uint160(referer3)).send(refAmountSecondry), "Referrer level 3 transfer failed");
            emit getMoneyForRefLevelEvent(referer3, msg.sender,3, _level, now,refAmountSecondry);


            users[referer1].totalEarning += refAmountSecondry; 
            users[referer2].totalEarning += refAmountSecondry; 
            users[referer3].totalEarning += refAmountSecondry; 
            
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);

            emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, LEVEL_PRICE[_level],now);
                
            payForLevel(0, _level, referer[0], _amt);
            }
        }
    }   
    function payForLevelP1(uint _flag, uint _level, address _userAddress, uint256 _amt) internal {
        address[6] memory referer; 
        
        if (_flag == 0) 
        {
            if (_level == 1 || _level == 2 || _level == 3 || _level == 16 || _level == 17 || _level == 18 || _level == 19 || _level == 34 || _level == 35 || _level == 36 || _level == 37 || _level == 38) 
            {
                referer[0] = userList[users[_userAddress].p1referrerID];
            } 
            else if (_level == 4 || _level == 5 || _level == 6 || _level == 20 || _level == 21  || _level == 22 || _level == 23 || _level == 39 || _level == 40 || _level == 41 || _level == 42 || _level == 43) 
            {
                referer[1] = userList[users[_userAddress].p1referrerID];
                referer[0] = userList[users[referer[1]].p1referrerID];
            } 
            else if (_level == 7 || _level == 8 || _level == 9 || _level == 10 || _level == 24 || _level == 25 || _level == 26 || _level == 27 || _level == 28 || _level == 44 || _level == 45 || _level == 46 || _level == 47 || _level == 48  ) 
            {
                referer[1] = userList[users[_userAddress].p1referrerID];
                referer[2] = userList[users[referer[1]].p1referrerID];
                referer[0] = userList[users[referer[2]].p1referrerID];
            } 
            else if (_level == 11 || _level == 12 || _level == 13 || _level == 14 || _level == 15 || _level == 29 || _level == 30 || _level == 31  || _level == 32 || _level == 33) 
            {
                referer[1] = userList[users[_userAddress].p1referrerID];
                referer[2] = userList[users[referer[1]].p1referrerID];
                referer[3] = userList[users[referer[2]].p1referrerID];
                referer[0] = userList[users[referer[3]].p1referrerID];
            } 
            
        } else if (_flag == 1) {
            referer[0] = userList[users[_userAddress].p1referrerID];
        }
        if (!users[referer[0]].isExist) referer[0] = userList[1];
        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= now) {          
            uint refAmountPrimary = (LEVEL_PRICE[_level]/100)*90;
            uint refAmountSecondry =(LEVEL_PRICE[_level]/100)*10;
            // transactions 
            require((address(uint160(referer[0])).send(refAmountPrimary)) , "Transaction Failure");
           
            users[referer[0]].totalEarning = users[referer[0]].totalEarning.add(refAmountPrimary);
            EarnedTrx[referer[0]][_level] = EarnedTrx[referer[0]][_level].add(refAmountPrimary);
            if(_level == 16){
                users[referer[0]].p1referral.push(msg.sender);
            }            
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, refAmountPrimary, now);           

            require(address(uint160(ownerAddress)).send(refAmountSecondry), "Owner level transfer failed");
            emit getMoneyForRefLevelEvent(ownerAddress, msg.sender,1, _level, now, refAmountSecondry);


            users[ownerAddress].totalEarning += refAmountSecondry; 
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);

            emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, LEVEL_PRICE[_level],now);
                
            payForLevelP1(0, _level, referer[0], _amt);
            }
        }
    }
    function payForLevelP2(uint _flag, uint _level, address _userAddress, uint256 _amt) internal {
        address[6] memory referer; 
        
        if (_flag == 0) 
        {
            if (_level == 1 || _level == 2 || _level == 3 || _level == 16 || _level == 17 || _level == 18 || _level == 19 || _level == 34 || _level == 35 || _level == 36 || _level == 37 || _level == 38) 
            {
                referer[0] = userList[users[_userAddress].p2referrerID];
            } 
            else if (_level == 4 || _level == 5 || _level == 6 || _level == 20 || _level == 21  || _level == 22 || _level == 23 || _level == 39 || _level == 40 || _level == 41 || _level == 42 || _level == 43) 
            {
                referer[1] = userList[users[_userAddress].p2referrerID];
                referer[0] = userList[users[referer[1]].p2referrerID];
            } 
            else if (_level == 7 || _level == 8 || _level == 9 || _level == 10 || _level == 24 || _level == 25 || _level == 26 || _level == 27 || _level == 28 || _level == 44 || _level == 45 || _level == 46 || _level == 47 || _level == 48  ) 
            {
                referer[1] = userList[users[_userAddress].p2referrerID];
                referer[2] = userList[users[referer[1]].p2referrerID];
                referer[0] = userList[users[referer[2]].p2referrerID];
            } 
            else if (_level == 11 || _level == 12 || _level == 13 || _level == 14 || _level == 15 || _level == 29 || _level == 30 || _level == 31  || _level == 32 || _level == 33) 
            {
                referer[1] = userList[users[_userAddress].p2referrerID];
                referer[2] = userList[users[referer[1]].p2referrerID];
                referer[3] = userList[users[referer[2]].p2referrerID];
                referer[0] = userList[users[referer[3]].p2referrerID];
            } 
            
        } else if (_flag == 1) {
            referer[0] = userList[users[_userAddress].p2referrerID];
        }
        if (!users[referer[0]].isExist) referer[0] = userList[1];
        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= now) {          
            uint refAmountPrimary = (LEVEL_PRICE[_level]/100)*90;
            uint refAmountSecondry =(LEVEL_PRICE[_level]/100)*10;
            // transactions 
            require((address(uint160(referer[0])).send(refAmountPrimary)) , "Transaction Failure");
           
            users[referer[0]].totalEarning = users[referer[0]].totalEarning.add(refAmountPrimary);
            EarnedTrx[referer[0]][_level] = EarnedTrx[referer[0]][_level].add(refAmountPrimary);
            if(_level == 34){
                users[referer[0]].p2referral.push(msg.sender);
            }
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, refAmountPrimary, now);
            
            require(address(uint160(ownerAddress)).send(refAmountSecondry), "Owner level transfer failed");
            emit getMoneyForRefLevelEvent(ownerAddress, msg.sender,1, _level, now, refAmountSecondry);


            users[ownerAddress].totalEarning += refAmountSecondry; 
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);

            emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, LEVEL_PRICE[_level],now);
                
            payForLevelP2(0, _level, referer[0], _amt);
            }
        }
    }
    
    function payForLevelSponsor(address _userAddress, uint _level) private returns(address){
        address[6] memory referer;         
            referer[0] = userList[users[_userAddress].referrerID];        
        if (!users[referer[0]].isExist) referer[0] = userList[1];        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].currentLevel >= _level) {          
            return referer[0];
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);     
                return payForLevelSponsor(referer[0], _level);
            }
        }
    } 
    function payForLevelSponsorP1(address _userAddress, uint _level) private returns(address){
        address[6] memory referer;         
            referer[0] = userList[users[_userAddress].p1referrerID];        
        if (!users[referer[0]].isExist) referer[0] = userList[1];        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].currentLevel >= _level) {          
            return referer[0];
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);     
                return payForLevelSponsorP1(referer[0], _level);
            }
        }
    }
    function payForLevelSponsorP2(address _userAddress, uint _level) private returns(address){
        address[6] memory referer;         
            referer[0] = userList[users[_userAddress].p2referrerID];        
        if (!users[referer[0]].isExist) referer[0] = userList[1];        
        if (loopCheck[msg.sender] >= 48) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].currentLevel >= _level) {          
            return referer[0];
        } 
        else 
        {
            if (loopCheck[msg.sender] < 48) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);     
                return payForLevelSponsorP2(referer[0], _level);
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
    
    /**
     * @dev Update level price
     */ 
    function updatePrice(uint _level, uint _price) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        LEVEL_PRICE[_level] = _price;
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
    function findFreep1Referrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].p1referral.length < 3) 
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].p1referral[0];
        referrals[1] = users[_userAddress].p1referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 254; i++) { 
            if (users[referrals[i]].p1referral.length == 3) {
                if (i < 126) {
                    referrals[(i+1)*2] = users[referrals[i]].p1referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].p1referral[1];
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
    function findFreep2Referrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].p2referral.length < 3) 
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].p2referral[0];
        referrals[1] = users[_userAddress].p2referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 254; i++) { 
            if (users[referrals[i]].p2referral.length == 3) {
                if (i < 126) {
                    referrals[(i+1)*2] = users[referrals[i]].p2referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].p2referral[1];
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
    function viewPassiveOneUserReferral(address _userAddress) external view returns (address[] memory) {
        return users[_userAddress].p1referral;
    }
    function viewPassiveTwoUserReferral(address _userAddress) external view returns (address[] memory) {
        return users[_userAddress].p2referral;
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