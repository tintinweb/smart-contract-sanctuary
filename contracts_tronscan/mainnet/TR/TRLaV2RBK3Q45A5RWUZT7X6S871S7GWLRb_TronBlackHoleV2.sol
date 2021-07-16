//SourceUnit: TronBlackHoleV2.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

interface IPool {
    function deposit() external payable;

    function withdraw(address payable to, uint256 amount) external returns (uint8 coinType);

    function withdrawCoin(address payable to, uint256 amount) external;

    function staticStatistics(
        bool _in,
        uint256 _releaseTime,
        uint256 _amount
    ) external;

    function dynamicStatistics(bool _in, uint256 _amount) external;
}

interface ITronBlackHole {
    function totalAmount() external view returns (uint256);

    function totalUser() external view returns (uint256);

    function totalDepositCount() external view returns (uint256);

    function userBase(address _user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function userExtra(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function userInfo(address _user)
        external
        view
        returns (
            bool,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );

    function depositInfo(address _user, uint8 _type) external view returns (uint256, uint256);
}

contract TronBlackHoleV2 {
    using SafeMath for uint256;

    address public owner;
    IPool pool;
    ITronBlackHole v1;

    uint256 constant DAY_SECONDS = 86400;
    uint256 constant MIN_DEPOSIT = 3000000000;
    uint8 constant MAX_DAY = 15;
    uint16[MAX_DAY] STATIC_PERCENTS = [6, 20, 30, 50, 60, 80, 100, 120, 150, 170, 190, 210, 230, 250, 300]; // 1000 times
    uint8 constant MAX_REFERRER = 10;
    uint8[MAX_REFERRER] DYNAMIC_PERCENTS = [30, 20, 12, 2, 3, 4, 5, 6, 7, 8];
    uint256 constant COIN_RATE = 1000;

    struct UserInfo {
        bool register;
        address referrer;
        uint256 recommendedCount;
        uint256 activatedCount;
        uint256 maxGenerations;
        uint256 dynamicReward;
        uint256 coinReward;
        uint256 totalAmount;
        uint256 totalStatement;
        uint256 totalStatic;
        uint256 totalDynamic;
        bool hasAmount;
        address[] invitees;
    }

    struct DepositInfo {
        uint256 amount;
        uint256 releaseTimestamp;
    }

    uint256 public totalAmount;
    uint256 public totalUser;
    uint256 public totalDepositCount;
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint8 => DepositInfo)) public depositInfo;
    address[] public userAddresses;

    event Doposit(address indexed addr, uint256 amount, uint8 day);
    event Redoposit(address indexed addr, uint256 amount, uint8 day);
    event Withdraw(address indexed addr, uint256 amount, uint256 reward, uint8 coinType);
    event WithdrawCoin(address indexed addr, uint256 amount);

    constructor(address payable _pool, address _v1) public {
        owner = msg.sender;
        pool = IPool(_pool);
        v1 = ITronBlackHole(_v1);
    }

    function transferV1Data() public {
        require(msg.sender == owner, "Only owner");
        if (totalAmount == 0) {
            totalAmount = totalAmount.add(v1.totalAmount());
            totalUser = totalUser.add(v1.totalUser());
            totalDepositCount = totalDepositCount.add(v1.totalDepositCount());
        }
    }

    function transferV1User(address _user) public {
        require(msg.sender == owner, "Only owner");
        transferV1Info(_user);
    }

    function getUserAddresses(uint256 _index) public view returns (address) {
        if (userAddresses.length <= _index) {
            return address(0);
        }
        return userAddresses[_index];
    }

    function getUserLength() public view returns (uint256) {
        return userAddresses.length;
    }

    function getUserAddressesMulti(uint256 _offset, uint256 _size) public view returns (address[] memory) {
        uint256 length = userAddresses.length;
        if (length <= _offset) {
            return new address[](0);
        }
        uint256 end = length.min(_offset.add(_size));
        uint256 size = end.sub(_offset);
        address[] memory results = new address[](size);
        uint256 c = 0;
        for (uint256 i = _offset; i < end; i++) {
            results[c] = userAddresses[i];
            c++;
        }
        return results;
    }

    function getInvitees(address _user, uint256 _index) public view returns (address) {
        if (userInfo[_user].invitees.length <= _index) {
            return address(0);
        }
        return userInfo[_user].invitees[_index];
    }

    function getInviteesLength(address _user) public view returns (uint256) {
        return userInfo[_user].invitees.length;
    }

    function getInviteesMulti(
        address _user,
        uint256 _offset,
        uint256 _size
    ) public view returns (address[] memory) {
        UserInfo storage user = userInfo[_user];
        uint256 length = user.invitees.length;
        if (length <= _offset) {
            return new address[](0);
        }
        uint256 end = length.min(_offset.add(_size));
        uint256 size = end.sub(_offset);
        address[] memory results = new address[](size);
        uint256 c = 0;
        for (uint256 i = _offset; i < end; i++) {
            results[c] = user.invitees[i];
            c++;
        }
        return results;
    }

    function totalInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (totalAmount, totalUser, totalDepositCount);
    }

    function userWarning(address _user) public view returns (bool) {
        UserInfo storage u = userInfo[_user];
        return u.maxGenerations > 0 && (u.activatedCount < u.maxGenerations || !u.hasAmount);
    }

    function userBase(address _user)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        UserInfo storage u = userInfo[_user];
        return (u.referrer, u.activatedCount, u.maxGenerations, u.totalAmount, u.totalStatement, u.totalDynamic);
    }

    function userExtra(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        UserInfo storage u = userInfo[_user];
        uint256 total = 0;
        uint256 amount = 0;

        for (uint8 i = 1; i <= MAX_DAY; i++) {
            DepositInfo storage info = depositInfo[_user][i];
            total = total.add(info.amount);
            if (info.amount > 0 && info.releaseTimestamp <= block.timestamp) {
                amount = amount.add(info.amount);
                amount = amount.add(info.amount.mul(STATIC_PERCENTS[i - 1]).div(1000));
            }
        }
        return (u.dynamicReward.add(amount), u.coinReward, u.totalStatic.add(amount), total);
    }

    function userDeposit(address _user) public view returns (uint256[2][] memory) {
        uint256[2][] memory results = new uint256[2][](15);
        for (uint8 i = 1; i <= MAX_DAY; i++) {
            DepositInfo storage info = depositInfo[_user][i];
            if (info.amount > 0 && info.releaseTimestamp > block.timestamp) {
                results[i - 1] = [info.amount, info.releaseTimestamp];
            }
        }
        return results;
    }

    function userDepositAll(address _user) public view returns (uint256[2][] memory) {
        uint256[2][] memory results = new uint256[2][](15);
        for (uint8 i = 1; i <= MAX_DAY; i++) {
            DepositInfo storage info = depositInfo[_user][i];
            results[i - 1] = [info.amount, info.releaseTimestamp];
        }
        return results;
    }

    function deposit(address _referrer, uint8 _day) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        UserInfo storage u = userInfo[msg.sender];

        if (!u.register) {
            if (_referrer != address(0)) {
                UserInfo storage referer = userInfo[_referrer];
                require(referer.register, "Invalid referrer");

                u.referrer = _referrer;
                referer.invitees.push(msg.sender);
                referer.recommendedCount++;
            }
            u.register = true;
            totalUser++;
            userAddresses.push(msg.sender);

            address ref = u.referrer;
            for (uint8 i = 1; i <= MAX_REFERRER; i++) {
                if (ref == address(0)) {
                    break;
                }
                UserInfo storage referrer = userInfo[ref];
                if (i > referrer.maxGenerations) {
                    referrer.maxGenerations = i;
                }

                ref = referrer.referrer;
            }
        }

        depositInner(msg.value, _day);

        pool.deposit.value(msg.value)();

        emit Doposit(msg.sender, msg.value, _day);
    }

    function redeposit(uint8 _day) public {
        (uint256 amount, uint256 reward, uint256 dyReward) = withdrawInner();
        amount = amount.add(reward).add(dyReward);

        depositInner(amount, _day);

        emit Redoposit(msg.sender, amount, _day);
    }

    function withdraw() public {
        (uint256 amount, uint256 reward, uint256 dyReward) = withdrawInner();

        uint8 coinType = pool.withdraw(msg.sender, amount.add(reward).add(dyReward));

        emit Withdraw(msg.sender, amount, reward, coinType);
    }

    function withdrawCoin() public {
        UserInfo storage u = userInfo[msg.sender];
        require(u.register, "Register first");

        uint256 cReward = u.coinReward;
        require(cReward > 0, "No coin reward");

        u.coinReward = 0;

        pool.withdrawCoin(msg.sender, cReward);

        emit WithdrawCoin(msg.sender, cReward);
    }

    function depositInner(uint256 _amount, uint8 _day) private {
        require(_amount >= MIN_DEPOSIT, "Insufficient value");
        require(_day >= 1 && _day <= MAX_DAY, "Invalid day");

        UserInfo storage u = userInfo[msg.sender];
        DepositInfo storage info = depositInfo[msg.sender][_day];
        require(info.amount == 0, "Only once a time");

        if (!u.hasAmount) {
            u.hasAmount = true;
            if (u.referrer != address(0)) {
                UserInfo storage referrer = userInfo[u.referrer];
                referrer.activatedCount++;
            }
        }

        totalAmount = totalAmount.add(_amount);
        totalDepositCount++;

        u.totalAmount = u.totalAmount.add(_amount);

        info.amount = _amount;
        info.releaseTimestamp = block.timestamp.add(DAY_SECONDS * _day);

        u.coinReward = u.coinReward.add(_amount.div(COIN_RATE));

        address ref = u.referrer;
        for (uint8 i = 1; i <= MAX_REFERRER; i++) {
            if (ref == address(0)) {
                break;
            }

            UserInfo storage referrer = userInfo[ref];

            if (referrer.activatedCount >= i) {
                referrer.totalStatement = referrer.totalStatement.add(_amount);
            }

            ref = referrer.referrer;
        }

        uint256 r = _amount.mul(STATIC_PERCENTS[_day - 1]).div(1000);
        pool.staticStatistics(true, info.releaseTimestamp, _amount.add(r));
    }

    function withdrawInner()
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        UserInfo storage u = userInfo[msg.sender];
        require(u.register, "Register first");

        bool hasAmount = false;
        uint256 amount = 0;
        uint256 reward = 0;
        uint256 dyReward = 0;
        for (uint8 i = 1; i <= MAX_DAY; i++) {
            DepositInfo storage info = depositInfo[msg.sender][i];
            if (info.amount > 0 && info.releaseTimestamp <= block.timestamp) {
                uint256 r = info.amount.mul(STATIC_PERCENTS[i - 1]).div(1000);
                pool.staticStatistics(false, info.releaseTimestamp, info.amount.add(r));
                amount = amount.add(info.amount);
                reward = reward.add(r);
                info.amount = 0;
                info.releaseTimestamp = 0;
            } else if (info.amount > 0 && info.releaseTimestamp > block.timestamp) {
                hasAmount = true;
            }
        }

        if (reward > 0) {
            address ref = u.referrer;
            for (uint8 i = 1; i <= MAX_REFERRER; i++) {
                if (ref == address(0)) {
                    break;
                }

                UserInfo storage referrer = userInfo[ref];

                if (referrer.hasAmount && referrer.activatedCount >= i) {
                    uint256 r = reward.mul(DYNAMIC_PERCENTS[i - 1]).div(100);
                    pool.dynamicStatistics(true, r);
                    referrer.dynamicReward = referrer.dynamicReward.add(r);
                }

                ref = referrer.referrer;
            }
        }

        if (!hasAmount && u.hasAmount) {
            u.hasAmount = false;
            if (u.referrer != address(0)) {
                UserInfo storage referrer = userInfo[u.referrer];
                if (referrer.activatedCount > 0) {
                    referrer.activatedCount--;
                }
            }
        }

        if (u.dynamicReward > 0) {
            dyReward = u.dynamicReward;
            u.dynamicReward = 0;
            pool.dynamicStatistics(false, dyReward);
        }

        u.totalStatic = u.totalStatic.add(amount).add(reward);
        u.totalDynamic = u.totalDynamic.add(dyReward);

        return (amount, reward, dyReward);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function transferV1Info(address _user) internal {
        UserInfo storage user = userInfo[_user];
        if (user.register) {
            return;
        }
        (bool register, , , , , , , , , , , ) = v1.userInfo(_user);

        if (!register) {
            return;
        }
        user.register = true;
        // Stack too deep, try removing local variables.
        saveV1UserInfoPart1(user, _user);
        saveV1UserInfoPart2(user, _user);
        userAddresses.push(_user);

        bool hasAmount = false;
        for (uint8 i = 1; i <= MAX_DAY; i++) {
            (uint256 amount, uint256 releaseTimestamp) = v1.depositInfo(_user, i);
            if (amount == 0) {
                continue;
            }
            DepositInfo storage info = depositInfo[_user][i];
            info.amount = amount;
            info.releaseTimestamp = releaseTimestamp;
            hasAmount = true;
        }
        user.hasAmount = hasAmount;

        if (user.referrer != address(0)) {
            UserInfo storage referrer = userInfo[user.referrer];
            referrer.recommendedCount++;
            if (hasAmount) {
                referrer.activatedCount++;
            }
            referrer.invitees.push(_user);
        }
    }

    function saveV1UserInfoPart1(UserInfo storage _user, address _userAddr) internal {
        address referrer = address(0);
        (, referrer, , , _user.maxGenerations, _user.dynamicReward, , , , , ,) = v1.userInfo(
            _userAddr
        );
        if (referrer != _userAddr) {
            _user.referrer = referrer;
        }
    }

    function saveV1UserInfoPart2(UserInfo storage _user, address _userAddr) internal {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            _user.coinReward,
            _user.totalAmount,
            _user.totalStatement,
            _user.totalStatic,
            _user.totalDynamic,
        ) = v1.userInfo(_userAddr);
    }
}

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

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}