/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.5.14;

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

contract Alexxeca {
    using SafeMath for uint256;

    uint256 public constant referrerLimit = 2;

    struct UserInfo {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 currentLevel;
        uint256 totalEarningEth;
        address[] referral;
        uint256 directReferral;
    }

    address public owner;
    address public charity; // charity wallet
    address public burner; // burner wallet
    uint256 public currentId = 0;
    bool public lockStatus;
    uint256 public loopLimit = 64;

    mapping(uint256 => uint256) public LEVEL_PRICE;
    mapping(uint256 => uint256) public profitPcent;
    mapping(address => UserInfo) public users;
    mapping(uint256 => address) public userList;
    mapping(address => mapping(uint256 => uint256)) public EarnedEth;
    mapping(address => uint256) public createdDate;

    event regLevelEvent(
        address indexed UserAddress,
        address indexed ReferrerAddress,
        uint256 Time
    );
    event buyLevelEvent(
        address indexed UserAddress,
        uint256 Levelno,
        uint256 Time
    );
    event getMoneyForLevelEvent(
        address indexed UserAddress,
        uint256 amount,
        uint256 UserId,
        address indexed ReferrerAddress,
        uint256 ReferrerId,
        uint256 Levelno,
        uint256 LevelPrice,
        uint256 Time
    );
    event SetLoopLimit(address caller, uint256 newLimit);

    constructor(
        address _owner,
        address _charity,
        address _burner
    ) public {
        require(
            (_owner != address(0x000)) &&
                (_charity != address(0x000)) &&
                (_burner != address(0x000)),
            "Zero address"
        );
        owner = _owner;
        charity = _charity;
        burner = _burner;

        LEVEL_PRICE[1] = 10 ether;
        LEVEL_PRICE[2] = 20 ether;
        LEVEL_PRICE[3] = 30 ether;
        LEVEL_PRICE[4] = 40 ether;
        LEVEL_PRICE[5] = 50 ether;
        LEVEL_PRICE[6] = 100 ether;
        LEVEL_PRICE[7] = 200 ether;
        LEVEL_PRICE[8] = 300 ether;
        LEVEL_PRICE[9] = 500 ether;
        LEVEL_PRICE[10] = 750 ether;
        LEVEL_PRICE[11] = 1000 ether;
        LEVEL_PRICE[12] = 2000 ether;

        profitPcent[1] = 36; // upline 1 profit
        profitPcent[2] = 27; // upline 2 profit
        profitPcent[3] = 18; // upline 3 profit
        profitPcent[4] = 9; // upline 4 profit
        profitPcent[5] = 5; // for charity
        profitPcent[6] = 5; // burnt out of circulation

        UserInfo memory userStruct;
        currentId = currentId + (1);

        userStruct = UserInfo({
            isExist: true,
            id: currentId,
            referrerID: 0,
            currentLevel: 12,
            totalEarningEth: 0,
            referral: new address[](0),
            directReferral: 0
        });

        users[_owner] = userStruct;
        userList[currentId] = _owner;
    }

    modifier isLock() {
        require(lockStatus == false, "Contract locked");
        _;
    }

    modifier checkPayment(uint256 level) {
        require((level >= 1) && (level <= 12), "Incorrect Level");
        require(msg.value == LEVEL_PRICE[level], "Incorrect value");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    /**
     * @dev User registration
     */
    function regUser(uint256 _referrerID)
        external
        payable
        isLock
        checkPayment(1)
    {
        address currentUser = msg.sender;
        uint256 amount = msg.value;
        require(users[currentUser].isExist == false, "User exist");
        require(
            _referrerID > 0 && _referrerID <= currentId,
            "Incorrect referrer Id"
        );

        uint256 directRef = _referrerID;
        if (users[userList[_referrerID]].referral.length >= referrerLimit)
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserInfo memory userStruct;
        currentId++;

        userStruct = UserInfo({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningEth: 0,
            referral: new address[](0),
            directReferral: directRef
        });

        users[currentUser] = userStruct;
        userList[currentId] = currentUser;
        users[userList[_referrerID]].referral.push(currentUser);
        createdDate[currentUser] = block.timestamp;

        payForLevelOne(1, currentUser, userList[directRef], amount);
        _takeFee(
            ((amount * profitPcent[5]) / 100),
            ((amount * profitPcent[6]) / 100)
        );

        emit regLevelEvent(currentUser, userList[_referrerID], block.timestamp);
    }

    function _takeFee(uint256 _charityFee, uint256 _burnerFee) internal {
        require(
            (address(uint160(charity)).send(_charityFee)) &&
                (address(uint160(burner)).send(_burnerFee)),
            "Transfer failed"
        );
    }

    /**
     * @dev To buy the next level by User
     */
    function buyLevel(uint256 _level)
        external
        payable
        isLock
        checkPayment(_level)
    {
        address currentUser = msg.sender;
        require(users[currentUser].isExist, "User not exist");
        require(
            (_level > 0) &&
                (_level <= 12) &&
                (users[currentUser].currentLevel + 1 == _level),
            "Incorrect level"
        );
        uint256 amount = msg.value;
        users[currentUser].currentLevel = _level;

        payForDirectRef(
            _level,
            userList[users[currentUser].directReferral],
            amount
        );
        payForLevel(
            _level,
            currentUser,
            userList[users[currentUser].directReferral],
            amount
        );
        _takeFee(
            ((amount * profitPcent[5]) / 100),
            ((amount * profitPcent[6]) / 100)
        );

        emit buyLevelEvent(currentUser, _level, block.timestamp);
    }

    function payForLevel(
        uint256 _level,
        address userAddress,
        address directRef,
        uint256 levelPrice
    ) internal returns (bool) {
        address ref = userList[users[userAddress].referrerID];
        uint256 maxProfit = 54;
        uint256 unsettled;

        for (uint256 i = 2; i <= 4; i++) {
            if ((ref == userList[1]) || ref == address(0x00)) {
                uint256 amount = unsettled + ((levelPrice * maxProfit) / 100);
                sendPayment(userList[1], amount, _level, levelPrice);
                return true;
            }

            if (ref == directRef) {
                if ((users[ref].currentLevel >= _level) && (unsettled > 0)) {
                    sendPayment(ref, unsettled, _level, levelPrice);
                    unsettled = 0;
                }
                ref = userList[users[ref].referrerID];
            }

            unsettled = unsettled + ((levelPrice * profitPcent[i]) / 100);
            maxProfit = maxProfit - profitPcent[i];

            if (ref != directRef && users[ref].currentLevel >= _level) {
                sendPayment(ref, unsettled, _level, levelPrice);
                unsettled = 0;
            }
            ref = userList[users[ref].referrerID];
        }

        if (unsettled > 0) {
            payForLevelUp(_level, ref, unsettled, levelPrice);
        }
        return true;
    }

    function payForLevelUp(
        uint256 _level,
        address ref,
        uint256 amount,
        uint256 levelPrice
    ) internal returns (bool) {
        for (uint256 i = 0; i <= loopLimit; i++) {
            if (
                (ref == userList[1]) ||
                (i == loopLimit) ||
                (ref == address(0x00))
            ) {
                sendPayment(userList[1], amount, _level, levelPrice);
                return true;
            } else if (users[ref].currentLevel >= _level) {
                sendPayment(ref, amount, _level, levelPrice);
                return true;
            }
            ref = userList[users[ref].referrerID];
        }
    }

    function payForDirectRef(
        uint256 _level,
        address _directRef,
        uint256 levelPrice
    ) internal {
        uint256 amount = ((levelPrice * profitPcent[1]) / 100);
        for (uint256 i = 1; i <= loopLimit; i++) {
            if (
                (_directRef == userList[1]) ||
                (i == loopLimit) ||
                _directRef == address(0x00)
            ) {
                sendPayment(userList[1], amount, _level, levelPrice);
                break;
            } else {
                if (users[_directRef].currentLevel >= _level) {
                    sendPayment(_directRef, amount, _level, levelPrice);
                    break;
                }
            }
            _directRef = userList[users[_directRef].directReferral];
        }
    }

    /**
     * @dev Internal function for payment
     */
    function payForLevelOne(
        uint256 _level,
        address _userAddress,
        address _directRef,
        uint256 levelPrice
    ) internal {
        uint256 maxProfit = 90;
        address ref = userList[users[_userAddress].referrerID];
        for (uint256 i = 1; i <= 4; i++) {
            if (ref == userList[1] || (ref == address(0x00))) {
                ref = userList[1];
                sendPayment(
                    ref,
                    ((levelPrice * maxProfit) / 100),
                    _level,
                    levelPrice
                );
                break;
            } else if (i == 1) {
                sendPayment(
                    _directRef,
                    ((levelPrice * profitPcent[i]) / 100),
                    _level,
                    levelPrice
                );
                maxProfit = maxProfit - profitPcent[i];
            } else {
                if (_directRef == ref) {
                    ref = userList[users[ref].referrerID];
                }
                sendPayment(
                    ref,
                    ((levelPrice * profitPcent[i]) / 100),
                    _level,
                    levelPrice
                );
                maxProfit = maxProfit - profitPcent[i];
                ref = userList[users[ref].referrerID];
            }
        }
    }

    function sendPayment(
        address _receiver,
        uint256 _amount,
        uint256 _level,
        uint256 levelPrice
    ) private {
        require((address(uint160(_receiver)).send(_amount)), "Transfer failed");
        users[_receiver].totalEarningEth = users[_receiver].totalEarningEth.add(
            _amount
        );
        EarnedEth[_receiver][_level] = EarnedEth[_receiver][_level].add(
            _amount
        );
        emit getMoneyForLevelEvent(
            msg.sender,
            _amount,
            users[msg.sender].id,
            _receiver,
            users[_receiver].id,
            _level,
            levelPrice,
            block.timestamp
        );
    }

    /**
     * @dev Contract balance withdraw
     */
    function failSafe(address payable _toUser, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(_toUser != address(0), "Zero address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }

    /**
     * @dev Update contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns (bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev Update the loop limit
     */
    function setLoopLimit(uint256 _newLimit) public returns (bool) {
        loopLimit = _newLimit;
        emit SetLoopLimit(msg.sender, _newLimit);
        return true;
    }

    /**
     * @dev View free Referrer Address
     */
    function findFreeReferrer(address _userAddress)
        public
        view
        returns (address)
    {
        if (users[_userAddress].referral.length < referrerLimit)
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 254; i++) {
            if (users[referrals[i]].referral.length == referrerLimit) {
                if (i < 126) {
                    referrals[(i + 1) * 2] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].referral[
                        1
                    ];
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
    function getTotalEarnedEther() public view returns (uint256) {
        uint256 totalEth;
        for (uint256 i = 1; i <= currentId; i++) {
            totalEth = totalEth.add(users[userList[i]].totalEarningEth);
        }
        return totalEth;
    }

    /**
     * @dev View referrals
     */
    function viewUserReferral(address _userAddress)
        external
        view
        returns (address[] memory)
    {
        return users[_userAddress].referral;
    }

    // fallback
    function() external payable {
        revert("Invalid Transaction");
    }
}