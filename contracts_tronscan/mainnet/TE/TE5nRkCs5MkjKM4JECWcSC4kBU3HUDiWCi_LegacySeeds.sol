//SourceUnit: LegacySeeds.sol

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

contract LegacySeeds {
    using SafeMath for uint;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint8 currentLevel;
        uint totalEarningTrx;
        address[] referral;
        mapping(uint8 => uint) levelExpired;
    }
    
    address public ownerAddress;
    uint public adminFee = 5 trx;
    uint public currentId = 0;
    uint public expiryDays = 60 days;
    uint8 refLimit = 2;
    bool public lockStatus;
    
    mapping (uint8 => uint) public levelPrice;
    mapping (uint => address) public userList;
    mapping (address => uint) public loopCheck;
    mapping (address => uint) public createdDate;
    mapping (address => UserStruct) public users;
    mapping (address => mapping (uint8 => uint)) public earnedTrx;
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);    
    
    constructor() public {
        ownerAddress = msg.sender;
        
         // levelPrice
        levelPrice[1] = 600 trx;
        levelPrice[2] = 1000 trx;
        levelPrice[3] = 2000 trx;
        levelPrice[4] = 8500 trx;
        levelPrice[5] = 20000 trx;
        levelPrice[6] = 50000 trx;
        levelPrice[7] = 100000 trx;
        levelPrice[8] = 200000 trx;
        levelPrice[9] = 400000 trx;
        levelPrice[10] = 800000 trx;
        
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

        for(uint8 i = 1; i <= 10; i++) {
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].levelExpired[i] = 55555555555;
        }
    }
    
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function regUser(uint _referrerID) public payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= currentId, "Incorrect referrer Id");
        
        uint adminProfit = (levelPrice[1].mul(adminFee)).div(10**8);
        require(msg.value == levelPrice[1].add(adminProfit), "Incorrect Value");
        
        // check 
        address UserAddress = msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract");
        
        
        if (users[userList[_referrerID]].referral.length >= refLimit) 
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currentId = currentId.add(1);
        
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
        users[msg.sender].levelExpired[1] = now.add(expiryDays);
        users[userList[_referrerID]].referral.push(msg.sender);
        loopCheck[msg.sender] = 0;
        createdDate[msg.sender] = now;
        
        payForLevel(0, 1, msg.sender, adminProfit, msg.value);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
    
    function buyLevel(uint8 _level) public payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 10, "Incorrect level");

        uint adminProfit = (levelPrice[_level].mul(adminFee)).div(10**8);
        require(msg.value == levelPrice[_level].add(adminProfit), "Incorrect Value");
        
        if (_level == 1) 
            users[msg.sender].levelExpired[1] = users[msg.sender].levelExpired[1].add(expiryDays);
        
        else {
            
            for (uint8 i = _level - 1; i > 0; i--) 
                require(users[msg.sender].levelExpired[i] >= now, "Buy the previous level");
            
            if (users[msg.sender].levelExpired[_level] == 0) {
                users[msg.sender].levelExpired[_level] = now.add(expiryDays);
                users[msg.sender].currentLevel = _level;
            }
                
            else 
                users[msg.sender].levelExpired[_level] = users[msg.sender].levelExpired[_level].add(expiryDays);
        }
        
        loopCheck[msg.sender] = 0;
        payForLevel(0, _level, msg.sender, adminProfit, msg.value);
        emit buyLevelEvent(msg.sender, _level, now);
    }
     
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
    
    function updateFeePercentage(uint256 _adminFee) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        adminFee = _adminFee;
        return true;  
    }
    
    function updatePrice(uint8 _level, uint _price) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        levelPrice[_level] = _price;
        return true;
    }
    
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerAddress, "Invalid User");

        lockStatus = _lockStatus;
        return true;
    }
    
    function findFreeReferrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].referral.length < refLimit) 
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 254; i++) { 
            if (users[referrals[i]].referral.length == refLimit) {
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
    
    function getTotalEarnedTrx() public view returns (uint) {
        uint totalTrx;
        
        for (uint i = 1; i <= currentId; i++) {
            totalTrx = totalTrx.add(users[userList[i]].totalEarningTrx);
        }
        
        return totalTrx;
    }
    
    function viewUserReferral(address _userAddress) public view returns (address[] memory) {
        return users[_userAddress].referral;
    }
    
    function viewUserLevelExpired(address _userAddress,uint8 _level) public view returns (uint) {
        return users[_userAddress].levelExpired[_level];
    }
    
    function payForLevel(uint8 _flag, uint8 _level, address _userAddress, uint _adminPrice, uint _amt) internal {
        address[6] memory referer;
        
        if (_flag == 0) {
            if (_level == 1 || _level == 6) {
                referer[0] = userList[users[_userAddress].referrerID];
            } else if (_level == 2 || _level == 7) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[0] = userList[users[referer[1]].referrerID];
            } else if (_level == 3 || _level == 8) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[0] = userList[users[referer[2]].referrerID];
            } else if (_level == 4 || _level == 9) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[0] = userList[users[referer[3]].referrerID];
            } else if (_level == 5 || _level == 10) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[0] = userList[users[referer[4]].referrerID];
            }
        } else if (_flag == 1) {
            referer[0] = userList[users[_userAddress].referrerID];
        }
        
        if (!users[referer[0]].isExist)
            referer[0] = userList[1];
        
        if (loopCheck[msg.sender] >= 12) 
            referer[0] = userList[1];
        
        if (users[referer[0]].levelExpired[_level] >= now) {
            
            require((address(uint160(referer[0])).send(levelPrice[_level])) && (address(uint160(ownerAddress)).send(_adminPrice)) ,"Transaction Failure");
            users[referer[0]].totalEarningTrx = users[referer[0]].totalEarningTrx.add(levelPrice[_level]);
            earnedTrx[referer[0]][_level] = earnedTrx[referer[0]][_level].add(levelPrice[_level]);
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, levelPrice[_level], now);
            
        } else {
            
            if (loopCheck[msg.sender] < 12) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, levelPrice[_level], now);
                payForLevel(1, _level, referer[0], _adminPrice, _amt);
            }
            
        }
    }
    
}