/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity >=0.6.0 <0.7.0;

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


contract SmartProtocol {
    
    using SafeMath for uint256;
    
    struct UserStruct {
        uint id;
        uint orignalRefID;
        uint referrerID;
        uint currentLevel;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }
    
    struct LevelStruct {
        uint ethValue;
        uint tokenValue;
        uint tokenOrignalValue;
    }
    
    uint public currentId = 0;
    uint referrer1Limit = 5;
    address payable public ownerAddress;
    uint public PERIOD_LENGTH = 60 days;
    uint public adminFee = 20 ether;
    uint public directFee = 70 ether;
    uint public L1 = 5 ether;
    uint public L2 = 3 ether;
    uint public L3 = 2 ether;


    mapping (uint => LevelStruct) public LEVEL_PRICE;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => uint)) public EarnedEth;
    mapping (address => uint) public loopCheck;
    mapping (address => uint) public createdDate;

    event regLevelEvent(address indexed UserAddress, uint indexed UserId, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint orignalRefID, uint Time);

    constructor() public {
        
        ownerAddress =payable(msg.sender);
        LEVEL_PRICE[1] = LevelStruct({
            ethValue: 0.0001 ether,
            tokenOrignalValue: 2,
            tokenValue: 10
        });
        LEVEL_PRICE[2] = LevelStruct({
            ethValue: 0.0001 ether,
            tokenOrignalValue: 3,
            tokenValue: 15
        });
        LEVEL_PRICE[3] = LevelStruct({
            ethValue: 10 ether,
            tokenOrignalValue: 3,
            tokenValue: 15
        });
        LEVEL_PRICE[4] = LevelStruct({
            ethValue: 0.0001 ether,
            tokenOrignalValue: 3,
            tokenValue: 15
        });
        
        UserStruct memory userStruct;

        currentId = currentId.add(1);

        userStruct = UserStruct({
            id: currentId,
            orignalRefID: 1,
            referrerID: 0,
            currentLevel:1,
            referral: new address[](0)
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;
        for(uint i = 1; i <= 4; i++) {
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].levelExpired[i] = now + 36500 days;
        }
    }
    
     modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only owner");
        _;
    }
    
    function regUser(uint _referrerID, uint _orignalRef, address _userAddress) external onlyOwner payable {
        require(users[_userAddress].id == 0, "User exist");
        require(_referrerID <= currentId, "Incorrect parentID Id");
        require(_orignalRef <= currentId, "Incorrect referrer Id");
        require(msg.value == LEVEL_PRICE[1].ethValue, "Incorrect Value");
        require(users[userList[_referrerID]].referral.length  < referrer1Limit, "User already have 5 childs");
        UserStruct memory userStruct;
        currentId = currentId.add(1);
        userStruct = UserStruct({
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            orignalRefID: _orignalRef,
            referral: new address[](0)
        });
        users[_userAddress] = userStruct;
        userList[currentId] = _userAddress;
        users[userList[_referrerID]].referral.push(_userAddress);
        loopCheck[_userAddress] = 0;
        createdDate[_userAddress] = block.timestamp;
        loopCheck[_userAddress] = 0;
        users[_userAddress].levelExpired[1] =  block.timestamp.add(PERIOD_LENGTH);

        payForLevel(true, 1, _userAddress, ((LEVEL_PRICE[1].ethValue.mul(adminFee)).div(10**20)), _userAddress);
        emit regLevelEvent(_userAddress, currentId, block.timestamp);
        // Token.mint(msg.sender, LEVEL_PRICE[1].tokenValue, secretPhase);
        // Token.mint(userList[_orignalRef], LEVEL_PRICE[1].tokenOrignalValue, secretPhase);
    }
    function buyLevel(uint256 _level, address _userAddress) external onlyOwner payable {
        // require(lockStatus == false, "Contract Locked");
        require(users[_userAddress].id != 0, "User not exist"); 
        require(_level > 0 && _level <= 4, "Incorrect level");
        require(msg.value == LEVEL_PRICE[_level].ethValue, "Incorrect Value");
        if (_level == 1) {
            require(msg.value == LEVEL_PRICE[_level].ethValue, "Incorrect Value");
            users[_userAddress].levelExpired[1] = users[_userAddress].levelExpired[1].add(PERIOD_LENGTH);
            users[_userAddress].currentLevel = 1;
        } else {
            require(msg.value == LEVEL_PRICE[_level].ethValue, "Incorrect Value");
            users[_userAddress].currentLevel = _level;
            for (uint i = _level - 1; i > 0; i--) 
                require(users[_userAddress].levelExpired[i] >=  block.timestamp, "Buy the previous level");
            
            if (users[_userAddress].levelExpired[_level] == 0)
                users[_userAddress].levelExpired[_level] =  block.timestamp + PERIOD_LENGTH;
            else 
                users[_userAddress].levelExpired[_level] += PERIOD_LENGTH;
        }
        loopCheck[_userAddress] = 0;
       
        payForLevel(true, _level, _userAddress, ((LEVEL_PRICE[_level].ethValue.mul(adminFee)).div(10**20)), _userAddress);

        emit buyLevelEvent(_userAddress, _level,  block.timestamp);
    }
    
    function payUser(address referer, uint directP, address L1_address, address L2_address, address L3_address, uint _level) internal {
        (bool success, ) = payable(address(uint160(referer))).call{value: directP}("");
        require(success, "Transfer failed.");
        
        (bool L1_address_Success, ) = payable(address(uint160(L1_address))).call{value: LEVEL_PRICE[_level].ethValue.mul(L1).div(10**20)}("");
        require(L1_address_Success, "Transfer failed.");
        
        (bool L2_address_Success, ) = payable(address(uint160(L2_address))).call{value: LEVEL_PRICE[_level].ethValue.mul(L2).div(10**20)}("");
        require(L2_address_Success, "Transfer failed.");
        
        (bool L3_address_Success, ) = payable(address(uint160(L3_address))).call{value: LEVEL_PRICE[_level].ethValue.mul(L3).div(10**20)}("");
        require(L3_address_Success, "Transfer failed.");
    }
    
    function payForLevel(bool _isNew, uint _level, address _userAddress, uint _adminPrice, address _orUser) internal {
            address referer;
            address L1_address;
            address L2_address;
            address L3_address;
            if(_isNew) {
                if (_level == 1 || _level == 3) {
                    referer = userList[users[_userAddress].referrerID];
                    L1_address = userList[users[_userAddress].orignalRefID];
                    L2_address = userList[users[referer].orignalRefID];
                    // L3_address = userList[users[referer].referrerID];
                    L3_address = userList[users[L2_address].orignalRefID];
                } else if (_level == 2 || _level == 4) {
                    referer = userList[users[_userAddress].referrerID];
                    referer = userList[users[referer].referrerID];
                    // L1_address = userList[users[_userAddress].orignalRefID];
                    // L2_address = userList[users[_userAddress].referrerID];
                    // L2_address = userList[users[L2_address].orignalRefID];
                    // L3_address = userList[users[referer].orignalRefID];
                    
                    L1_address = userList[users[_userAddress].orignalRefID];
                    L2_address = userList[users[L1_address].orignalRefID];
                    // L3_address = userList[users[referer].referrerID];
                    L3_address = userList[users[L2_address].orignalRefID];
                }
            } else {
                referer = userList[users[_userAddress].referrerID];
                L1_address = userList[users[_userAddress].orignalRefID];
                L2_address = userList[users[L1_address].orignalRefID];
                L3_address = userList[users[L2_address].orignalRefID];
            }
            if (loopCheck[_orUser] >= 4) {
                referer = userList[1];
                L1_address = userList[1];
                L2_address = userList[1];
                L3_address = userList[1];
            }
            if (users[referer].currentLevel >= _level) {
                // uint256 tobeminted = ((_amt).mul(0**18)).div(0.01 ether);
                // transactions 
                uint directP = (LEVEL_PRICE[_level].ethValue.mul(directFee)).div(10**20);
                
                payUser(referer, directP, L1_address, L2_address, L3_address, _level);

                (bool success, ) = ownerAddress.call{value: _adminPrice}("");
                require(success, "Transfer failed.");
                // users[referer].totalEarningEth = users[referer].totalEarningEth.add(LEVEL_PRICE[_level].ethValue);
                EarnedEth[referer][_level] = EarnedEth[referer][_level].add(LEVEL_PRICE[_level].ethValue);
                EarnedEth[L1_address][_level] = EarnedEth[L1_address][_level].add(LEVEL_PRICE[_level].ethValue);
                EarnedEth[L2_address][_level] = EarnedEth[L2_address][_level].add(LEVEL_PRICE[_level].ethValue);
                EarnedEth[L3_address][_level] = EarnedEth[L3_address][_level].add(LEVEL_PRICE[_level].ethValue);

                emit getMoneyForLevelEvent(_orUser, users[_orUser].id, referer, users[referer].id, _level, users[_orUser].orignalRefID, block.timestamp);
        } else {
            if (loopCheck[_orUser] < 4) {
                loopCheck[_orUser] = loopCheck[_orUser].add(1);
                payForLevel(false, _level, referer, _adminPrice, _orUser);
            }
        }
    }
    
}