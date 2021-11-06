/**
 *Submitted for verification at polygonscan.com on 2021-11-06
*/

/**
 * 
    $$$$$$$\  $$$$$$\ $$$$$$$$\ $$\       $$$$$$$$\  $$$$$$\  $$\    $$\ $$$$$$$$\  $$$$$$\  
    $$  __$$\ \_$$  _|\__$$  __|$$ |      $$  _____|$$  __$$\ $$ |   $$ |$$  _____|$$  __$$\ 
    $$ |  $$ |  $$ |     $$ |   $$ |      $$ |      $$ /  $$ |$$ |   $$ |$$ |      $$ /  \__|
    $$$$$$$\ |  $$ |     $$ |   $$ |      $$$$$\    $$$$$$$$ |\$$\  $$  |$$$$$\    \$$$$$$\  
    $$  __$$\   $$ |     $$ |   $$ |      $$  __|   $$  __$$ | \$$\$$  / $$  __|    \____$$\ 
    $$ |  $$ |  $$ |     $$ |   $$ |      $$ |      $$ |  $$ |  \$$$  /  $$ |      $$\   $$ |
    $$$$$$$  |$$$$$$\    $$ |   $$$$$$$$\ $$$$$$$$\ $$ |  $$ |   \$  /   $$$$$$$$\ \$$$$$$  |
    \_______/ \______|   \__|   \________|\________|\__|  \__|    \_/    \________| \______/ 
                                                                                                 
**/                                                                        
// visit us on bitleaves.io

pragma solidity 0.5.14;


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


contract ERC20 {
    function mint(address to, uint256 value) public returns(bool);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);


}


contract Bitleaves {
    using SafeMath for uint256;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint currentLevel;
        uint totalEarningEth;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    ERC20 Token;
    address public ownerAddress;
    uint public adminFee = 10 ether;
    uint public currentId = 0;
    uint public PERIOD_LENGTH = 60 days;
    uint referrer1Limit = 2;
    bool public lockStatus;
    uint public kickback = 2000000000000000000;
    
    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) public TOKEN_DISTRIBUTION;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => uint)) public EarnedEth;
    mapping (address => uint) public loopCheck;

    event regLevelEvent(address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId,  uint Time);
    event buyLevelEvent(address indexed UserAddress,uint UserId, uint Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);

    constructor() public {
        ownerAddress = msg.sender;
        Token = ERC20(0xDFA24CFd481A70cF1c7098108Bb1f5D70d0E8EEE);

        LEVEL_PRICE[1] = 15 ether;
        LEVEL_PRICE[2] = 30 ether;
        LEVEL_PRICE[3] = 90 ether;
        LEVEL_PRICE[4] = 150 ether;
        LEVEL_PRICE[5] = 210 ether;
        LEVEL_PRICE[6] = 450 ether;
        LEVEL_PRICE[7] = 900 ether;
        LEVEL_PRICE[8] = 2100 ether;
        LEVEL_PRICE[9] = 4500 ether;
        LEVEL_PRICE[10] = 7500 ether;
        LEVEL_PRICE[11] = 9000 ether;
        LEVEL_PRICE[12] = 11700 ether;

        TOKEN_DISTRIBUTION[1] = 2000000000000000000;
        TOKEN_DISTRIBUTION[2] = 5000000000000000000;
        TOKEN_DISTRIBUTION[3] = 15000000000000000000;
        TOKEN_DISTRIBUTION[4] = 25000000000000000000;
        TOKEN_DISTRIBUTION[5] = 35000000000000000000;
        TOKEN_DISTRIBUTION[6] = 75000000000000000000;
        TOKEN_DISTRIBUTION[7] = 150000000000000000000;
        TOKEN_DISTRIBUTION[8] = 350000000000000000000;
        TOKEN_DISTRIBUTION[9] = 750000000000000000000;
        TOKEN_DISTRIBUTION[10] = 1250000000000000000000;
        TOKEN_DISTRIBUTION[11] = 1500000000000000000000;
        TOKEN_DISTRIBUTION[12] = 1750000000000000000000;

        UserStruct memory userStruct;
        currentId = currentId.add(1);

        userStruct = UserStruct({
        isExist: true,
        id: currentId,
        referrerID: 0,
        currentLevel:1,
        totalEarningEth:0,
        referral: new address[](0)
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;

        for(uint i = 1; i <= 12; i++) {
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
        address original = address(0);
        if (users[userList[_referrerID]].referral.length >= referrer1Limit){
            original = userList[_referrerID];
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }
        
        UserStruct memory userStruct;
        currentId++;

        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningEth:0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[msg.sender].levelExpired[1] = now.add(PERIOD_LENGTH);
        users[userList[_referrerID]].referral.push(msg.sender);
        loopCheck[msg.sender] = 0;
        
        payForLevel(0, 1, msg.sender, ((LEVEL_PRICE[1].mul(adminFee)).div(10**20)), msg.value);
        
        if(original != address(0)){
            sendToken(original,(kickback));
        }
        emit regLevelEvent(msg.sender,currentId, userList[_referrerID], _referrerID, now);
    }

    /**
     * @dev To buy the next level by User
     */
     function sendToken(address adr , uint256 amount) internal{
         Token.mint(adr, amount);
         
     }
    function buyLevel(uint256 _level) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist");
        require(_level > 0 && _level <= 12, "Incorrect level");

        if (_level == 1) {
            require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
            users[msg.sender].levelExpired[1] = users[msg.sender].levelExpired[1].add(PERIOD_LENGTH);
            users[msg.sender].currentLevel = 1;
        } else {
            require(msg.value == LEVEL_PRICE[_level], "Incorrect Value");
            users[msg.sender].currentLevel = _level;
            for (uint i = _level - 1; i > 0; i--)
                require(users[msg.sender].levelExpired[i] >= now, "Make sure to buy all previous levels and that they're not expired");

            if (users[msg.sender].levelExpired[_level] == 0)
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            else
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
        }
        loopCheck[msg.sender] = 0;

        payForLevel(0, _level, msg.sender, ((LEVEL_PRICE[_level].mul(adminFee)).div(10**20)), msg.value);

        emit buyLevelEvent(msg.sender, users[msg.sender].id, _level, now);
    }

    /**
     * @dev Internal function for payment
     */
    function payForLevel(uint _flag, uint _level, address _userAddress, uint _adminPrice, uint256 _amt) internal {
        address[6] memory referer;

        if (_flag == 0) {
            if (_level == 1 || _level == 7) {
                referer[0] = userList[users[_userAddress].referrerID];
            } else if (_level == 2 || _level == 8) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[0] = userList[users[referer[1]].referrerID];
            } else if (_level == 3 || _level == 9) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[0] = userList[users[referer[2]].referrerID];
            } else if (_level == 4 || _level == 10) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[0] = userList[users[referer[3]].referrerID];
            } else if (_level == 5 || _level == 11) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[0] = userList[users[referer[4]].referrerID];
            } else if (_level == 6 || _level == 12) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[5] = userList[users[referer[4]].referrerID];
                referer[0] = userList[users[referer[5]].referrerID];
            }
        } else if (_flag == 1) {
            referer[0] = userList[users[_userAddress].referrerID];
        }
        if (!users[referer[0]].isExist) referer[0] = userList[1];

        if (loopCheck[msg.sender] >= 12) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= now) {

            uint256 tobeminted = TOKEN_DISTRIBUTION[_level];
            // transactions
            require((address(uint160(referer[0])).send(LEVEL_PRICE[_level].sub(_adminPrice))) &&
                    (address(uint160(ownerAddress)).send(_adminPrice)) &&
                    Token.mint(msg.sender, tobeminted), "Transaction Failure");

            users[referer[0]].totalEarningEth = users[referer[0]].totalEarningEth.add(LEVEL_PRICE[_level]);
            EarnedEth[referer[0]][_level] = EarnedEth[referer[0]][_level].add(LEVEL_PRICE[_level]);

            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, LEVEL_PRICE[_level], now);
        } else {
            if (loopCheck[msg.sender] < 12) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);

            emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, LEVEL_PRICE[_level],now);

            payForLevel(1, _level, referer[0], _adminPrice, _amt);
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

    function updateTokenDistribution(uint _level, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        TOKEN_DISTRIBUTION[_level] = _amount;
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
    function setKickback(uint _kickback) public returns (bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        kickback = _kickback;
        return true;
    }

    /**
    * @dev Update token contract
    */
    function updateToken(address _newToken) public returns (bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        require(_newToken != address(0), "Invalid Token Address");

        Token = ERC20(_newToken);
        return true;
    }
    function withdraw(ERC20 _asset) external {
        require(msg.sender == ownerAddress, "only OwnerWallet");
        uint256 balance = _asset.balanceOf(address(this));
        _asset.approve(address(this),balance);
        _asset.transferFrom(address(this),msg.sender, balance);
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
     * @dev Total earned ETH
     */
    function getTotalEarnedEther() public view returns (uint) {
        uint totalEth;
        for (uint i = 1; i <= currentId; i++) {
            totalEth = totalEth.add(users[userList[i]].totalEarningEth);
        }
        return totalEth;
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
}