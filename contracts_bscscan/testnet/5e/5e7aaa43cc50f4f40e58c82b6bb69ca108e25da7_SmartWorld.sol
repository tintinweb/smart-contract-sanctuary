/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

pragma solidity >=0.4.23 <= 0.6.0;

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

contract SmartWorld {
    using SafeMath for uint256;

    struct USER {
        bool joined;
        uint id;
        address payable upline;
        uint personalCount;
        uint256 originalReferrer;
        mapping(uint256 => uint) activeLevel;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only Deployer");
        _;
    }
 
    uint public lastIDCount = 0;
    uint public LAST_LEVEL = 6;

    mapping(address => USER) public users;
    mapping(uint256 => uint256) public LevelPrice;

    event Registration(address userAddress, uint256 accountId, uint256 refId, uint side, uint256 _level);
    event BuyLevel(uint256 accountId, uint level);
    event Withdraw(uint256 accountId, uint256 amount);
    
    address public implementation;
    address payable public deployer;
    address payable public owner;
    address payable public admin;
    mapping(uint256 => address payable) public userAddressByID;
    
    constructor(address payable owneraddress, address payable _admin) public {
        owner = owneraddress;
        admin = _admin;
        deployer = msg.sender;

        LevelPrice[1] =  1e18;
        LevelPrice[2] =  2e18;
        LevelPrice[3] =  4e18;
        LevelPrice[4] =  6e18;
        LevelPrice[5] =  8e18;
        LevelPrice[6] =  10e18;
        
        USER memory user;
        lastIDCount++;

        user = USER({joined: true, id: lastIDCount, originalReferrer: 1, personalCount : 0, upline:address(0)});

        users[owneraddress] = user;
        
        userAddressByID[lastIDCount] = owneraddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[owneraddress].activeLevel[i]++;
        }
    }
    
    function regUser(uint256 _referrerID, uint side, uint256 _level) external payable {
        require(msg.value == LevelPrice[_level], "Incorrect Value");
        regUserInternal(msg.sender, _referrerID, side, _level);
    }
    
    function regUserInternal(address payable userAddress, uint256 _referrerID, uint side, uint256 _level) internal {
        uint256 originalReferrer = _referrerID;

        require(!users[userAddress].joined, "User exist");
        require(_referrerID > 0 && _referrerID <= lastIDCount,"Incorrect referrer Id");
        
        users[userAddressByID[originalReferrer]].personalCount++;
        
        USER memory UserInfo;
        lastIDCount++;
        
        UserInfo = USER({
            joined: true,
            id: lastIDCount,
            upline : userAddressByID[originalReferrer],
            originalReferrer: originalReferrer,
            personalCount:0
        });

        users[userAddress] = UserInfo;
        userAddressByID[lastIDCount] = userAddress;
        users[userAddress].activeLevel[_level]++;
        
        admin.transfer(msg.value);
        
        emit Registration(userAddress, lastIDCount, originalReferrer, side, _level);
    }
    
    function buyLevel(uint8 _level) public payable {
        require(msg.value == LevelPrice[_level], "Incorrect Value");
        buyLevelInternal(msg.sender, _level);
    }
    
    function adjustment(address payable userAddress , uint256 _referrerID) public onlyDeployer {
        
        uint256 originalReferrer = _referrerID;
        require(!users[userAddress].joined, "User exist");
        require(_referrerID > 0 && _referrerID <= lastIDCount,"Incorrect referrer Id");
        users[userAddressByID[originalReferrer]].personalCount++;
        USER memory UserInfo;
        lastIDCount++;
        
        UserInfo = USER({
            joined: true,
            id: lastIDCount,
            upline : userAddressByID[originalReferrer],
            originalReferrer: originalReferrer,
            personalCount:0
        });
        
        users[userAddress] = UserInfo;
        userAddressByID[lastIDCount] = userAddress;
        emit Registration(userAddress, lastIDCount, originalReferrer, 1, 1);

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[userAddress].activeLevel[i]++;
            emit BuyLevel(users[userAddress].id, i);
        }
    }
    
    function buyLevelInternal(address payable userAddress, uint8 _level) internal {
        require(users[userAddress].joined, "User Not Joined");
        require(_level >= 1 && _level <= LAST_LEVEL, "Incorrect Level");
        
        users[userAddress].activeLevel[_level]++;
        admin.transfer(msg.value);
        emit BuyLevel(users[userAddress].id, _level);
    }
    

    function withdrawByDeployer(address payable userAddress, uint256 _amount) public onlyDeployer {
        require(users[userAddress].joined, "User Not exist");
        userAddress.transfer(_amount);
        emit Withdraw(users[msg.sender].id, _amount);
    }
    
    function check_slot_status(address userAddress, uint8 _level) public view returns (uint) {
        return users[userAddress].activeLevel[_level];
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
}