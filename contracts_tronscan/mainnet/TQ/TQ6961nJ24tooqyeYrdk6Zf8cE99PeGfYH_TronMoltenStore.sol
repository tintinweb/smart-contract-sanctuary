//SourceUnit: TronStore.sol

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v3.4.1

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v3.4.1





/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @openzeppelin/contracts/math/SafeMath.sol@v3.4.1





/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/math/Math.sol@v3.4.1





/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/utils/Roles.sol





library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


// File contracts/role/OperatorRole.sol





contract OperatorRole is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}


// File contracts/role/OwnableOperatorRole.sol





contract OwnableOperatorRole is Ownable, OperatorRole {
    function addOperator(address account) external onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) external onlyOwner {
        _removeOperator(account);
    }
}


// File contracts/StoreDomain.sol






contract StoreDomain {
    struct User {
        uint256 liquid;
        uint256 lastLiquid;
        address referrer;

        uint256 inviteeCount;
        uint256 groupCount;

        uint256 rewardTime;
        uint256 outTime;

        uint256 rounds;
    }

    struct Reward {
        uint256 liquid;
        uint256 invitee;
        uint256 group;
    }

    struct Withdrawn {
        uint256 liquid;
        uint256 invitee;
        uint256 group;
        uint256 prize;
    }

    struct Pool {
        uint256 total;
        uint256 withdraw;
    }

    struct DayPrize {
        uint256 liquid;
        uint256 invitee;
    }
}


// File contracts/TronStore.sol








interface ITronPools {
    function rounds() external view returns(uint256);
    function lastRiskTime() external view returns(uint256);
    function initTime() external view returns(uint256);

    function mining() external view returns(StoreDomain.Pool memory);

    function store() external view returns(StoreDomain.Pool memory);

    function prize() external view returns(StoreDomain.Pool memory);

    function total() external view returns(uint256);

    function totalWithdraw() external view returns(uint256);

    function deposit(uint256 _miningAmount, uint256 _storeAmount, uint256 _prizeAmount, uint256 _devAmount) external payable returns(bool);

    function withdraw(address payable _account, uint256 _miningAmount, uint256 _storeAmount, uint256 _prizeAmount) external returns(bool);

    function addRounds() external;

    function updateLastRiskTime() external;
}

interface ITronState {
    function holdUserNum() external view returns(uint256);
    function staticRate() external view returns(uint256);

    function getUser(address _account) external view returns(StoreDomain.User memory);
    function setUser(address _account, StoreDomain.User memory _user) external;

    function getReward(address _account) external view returns(StoreDomain.Reward memory);
    function setReward(address _account, StoreDomain.Reward memory _reward) external;

    function getWithdrawn(address _account) external view returns(StoreDomain.Withdrawn memory);
    function setWithdrawn(address _account, StoreDomain.Withdrawn memory _withdrawn) external;

    function getUserJoined(address _account) external view returns(bool);
    function setUserJoined(address _account, bool _joined) external;

    function getHoldUserNum() external view returns(uint256);
    function setHoldUserNum(uint256 num) external;
    function addHoldUserNum() external;
}

interface IPrizeState {
    function getDaySnap(uint256 _day) external view returns(uint256);
    function setDaySnap(uint256 _day, uint256 _amount) external;

    function getDayWithdrawed(uint256 _day, address _account) external view returns(bool);
    function setDayWithdrawed(uint256 _day, address _account, bool _withdrawed) external;

    function getDayInvitee(uint256 _day, address _account) external view returns(uint256);
    function setDayInvitee(uint256 _day, address _account, uint256 _amount) external;

    function getDayInviteeTotal(uint256 _day) external view returns(uint256);
    function setDayInviteeTotal(uint256 _day, uint256 _amount) external;

    function getDayInviteeRank(uint256 _day) external view returns(address[] memory);
    function setDayInviteeRank(uint256 _day, address[] memory _accounts) external;
    function addDayInviteeRank(uint256 _day, address _account) external;

    function getDayGroupTotal(uint256 _day) external view returns(uint256);
    function setDayGroupTotal(uint256 _day, uint256 _amount) external;

    function getDayGroupRank(uint256 _day) external view returns(address[] memory);
    function setDayGroupRank(uint256 _day, address[] memory _accounts) external;
    function addDayGroupRank(uint256 _day, address _account) external;
}

contract TronMoltenStore is Ownable, StoreDomain {
    using SafeMath for uint;

    ITronPools pools;
    ITronState state;
    IPrizeState prizeState;

    uint256 constant ONE_DAY = 1 days;
    uint256 public constant MIN_AMOUNT_FIRST = 100 * 10**6;
    uint256 public constant OLD_MIN_AMOUNT_FIRST = 10000 * 10**6;
    uint256 public constant MIN_AMOUNT_RISK = 100000 * 10**6;

    event Deposit(address indexed account, User user);
    event Withdraw(address indexed account, User user);
    event Risk(uint256 indexed rounds);

    struct IReward {
        uint256 liquid;
        uint256 invitee;
        uint256 group;
        uint256 prize;
    }

    struct IRank {
        address account;
        uint256 amount;
        uint256 reward;
    }

    mapping(address => bool) public isOld;

    constructor(ITronPools _pools, ITronState _state, IPrizeState _prizeState) {
        pools = _pools;
        state = _state;
        prizeState = _prizeState;
    }

    function sync(address _account, address referrer, uint256 liquid, uint256 inviteeCount, uint256 groupCount) external onlyOwner {
        User memory _user = User({
            liquid: liquid,
            lastLiquid: liquid,
            referrer: referrer,
            inviteeCount: inviteeCount,
            groupCount: groupCount,
            rewardTime: block.timestamp,
            outTime: 0,
            rounds: pools.rounds()
        });

        isOld[_account] = true;
        state.setUser(_account, _user);

        emit Deposit(_account, _user);
    }

    function _clearUser(address _account) private {
        User memory _user = state.getUser(_account);
        Reward memory _reward = state.getReward(_account);
        Withdrawn memory _withdrawn = state.getWithdrawn(_account);

        delete _reward.liquid;
        delete _withdrawn.liquid;

        _reward.invitee = _reward.invitee.sub(_withdrawn.invitee);
        delete _withdrawn.invitee;

        _reward.group = _reward.group.sub(_withdrawn.group);
        delete _withdrawn.group;

        delete _withdrawn.prize;

        delete _user.liquid;

        _user.outTime = _user.outTime == 0 ? block.timestamp : _user.outTime;

        state.setUser(_account, _user);
        state.setReward(_account, _reward);
        state.setWithdrawn(_account, _withdrawn);
    }

    function deposit(address _referrer) external payable {
        uint256 amount = msg.value;
        require(state.getUserJoined(_referrer) || _referrer == address(0x0), "TronStore: user not join");

        if (state.getUserJoined(msg.sender)) {
            updateLiquid(msg.sender);

            if (isOutWithRisk(msg.sender)) {
                _clearUser(msg.sender);
            }

            checkUpOneDay(msg.sender);
        }

        User memory user = state.getUser(msg.sender);

        if (isOld[msg.sender]) {
            require(amount >= OLD_MIN_AMOUNT_FIRST, "First must greater than 10000 trx");
            delete isOld[msg.sender];
        } else {
            if (!state.getUserJoined(msg.sender)) {
                require(amount >= MIN_AMOUNT_FIRST, "First must greater than 100 trx");
            } else {
                require(amount >= user.lastLiquid.mul(110).div(100), "Must 10% greater than last amount");
            }
        }

        pools.deposit{value:amount}(amount.mul(86).div(100), amount.mul(3).div(100), amount.mul(6).div(100), amount.mul(5).div(100));

        user.liquid = user.liquid.add(amount);
        user.lastLiquid = amount;
        user.rewardTime = block.timestamp;

        user.rounds = pools.rounds();
        user.outTime = 0;

        if (!state.getUserJoined(msg.sender) || (user.inviteeCount == 0 && user.referrer == address(0x0))) {
            user.referrer = _referrer;
            updateRef(_referrer, amount, true);
            updateGroupCount(_referrer);
        } else {
            updateRef(user.referrer, amount, false);
        }

        uint256 _day = currentDay();
        updatePrize(user.referrer, amount, _day);
        if (prizeState.getDayInvitee(_day, msg.sender) >= 50000 * 10**6 && user.groupCount >= 500 && user.liquid >= 100000 * 10**6 && user.liquid.sub(amount) < 100000 * 10**6) {
            prizeState.addDayGroupRank(_day, msg.sender);
            prizeState.setDayGroupTotal(_day, prizeState.getDayGroupTotal(_day).add(prizeState.getDayInvitee(_day, msg.sender)));
        }

        state.setUser(msg.sender, user);

        emit Deposit(msg.sender, user);
    }

    function checkUpOneDay(address _account) internal {
        User memory _user = state.getUser(msg.sender);
        Reward memory _reward = state.getReward(msg.sender);

        if (_user.outTime != 0 && block.timestamp.sub(_user.outTime) > ONE_DAY) {
            _reward.invitee = state.getWithdrawn(msg.sender).invitee;
            _reward.group = state.getWithdrawn(msg.sender).group;
        }
        state.setReward(_account, _reward);
    }

    function updateLiquid(address _account) internal {
        User memory _user = state.getUser(_account);
        Reward memory _reward = state.getReward(_account);

        _user.rewardTime = block.timestamp;
        _reward.liquid = liquidReward(_account);

        state.setUser(_account, _user);
        state.setReward(_account, _reward);
    }

    function updatePrize(address _ref, uint256 _amount, uint256 _day) internal {
        prizeState.setDaySnap(_day, pools.prize().total.sub(pools.prize().withdraw));

        if (_ref == address(0x0) || !state.getUserJoined(_ref)) return;

        uint256 _dayInvitee = prizeState.getDayInvitee(_day, _ref);
        uint256 _dayInviteeTotal = prizeState.getDayInviteeTotal(_day);

        prizeState.setDayInvitee(_day, _ref, _dayInvitee.add(_amount));

        if (_dayInvitee.add(_amount) >= 100000 * 10**6) {
            if (_dayInvitee < 100000 * 10**6) {
                prizeState.addDayInviteeRank(_day, _ref);
                prizeState.setDayInviteeTotal(_day, _dayInviteeTotal.add(_dayInvitee).add(_amount));
            } else {
                prizeState.setDayInviteeTotal(_day, _dayInviteeTotal.add(_amount));
            }
        }

        uint256 _dayGroupTotal = prizeState.getDayGroupTotal(_day);

        if (_dayInvitee.add(_amount) >= 50000 * 10**6 && state.getUser(_ref).groupCount >= 500 && state.getUser(_ref).liquid >= 100000 * 10**6) {
            if (_dayInvitee < 50000 * 10**6) {
                prizeState.addDayGroupRank(_day, _ref);
                prizeState.setDayGroupTotal(_day, _dayGroupTotal.add(_dayInvitee).add(_amount));
            } else {
                prizeState.setDayGroupTotal(_day, _dayGroupTotal.add(_amount));
            }
        }
    }

    function updateRef(address refAddr, uint256 amount, bool added) internal {
        if (refAddr == address(0x0)) return;

        User memory ref = state.getUser(refAddr);
        Reward memory refReward = state.getReward(refAddr);

        if (added) {
            ref.inviteeCount += 1;
        }

        if (canReward(refAddr)) {
            if (!state.getUserJoined(msg.sender)) {
                refReward.invitee = refReward.invitee.add(amount.mul(10).div(100));
            } else {
                refReward.invitee = refReward.invitee.add(amount.mul(8).div(100));
            }
        }

        state.setUser(refAddr, ref);
        state.setReward(refAddr, refReward);
    }

    function updateGroupCount(address _parent) private  {
        address parent = _parent;
        uint256 dis = 1;

        while(parent != address(0x0) && dis <= 21) {
            User memory user = state.getUser(parent);

            user.groupCount += 1;
            state.setUser(parent, user);

            parent = user.referrer;
            dis++;
        }
    }

    function _withdraw(address payable _account, uint256 _liquid, uint256 _invitee, uint256 _group, uint256 _prize, uint256 _store) private {
        User memory _user = state.getUser(_account);

        if (isOld[_account]) {
            pools.withdraw(_account, _invitee.add(_group), _store.add(_liquid), _prize);
        } else {
            pools.withdraw(_account, _liquid.add(_invitee).add(_group), _store, _prize);
        }

        Withdrawn memory _withdrawn = state.getWithdrawn(_account);

        _withdrawn.liquid = _withdrawn.liquid.add(_liquid);
        _withdrawn.invitee = _withdrawn.invitee.add(_invitee);
        _withdrawn.group = _withdrawn.group.add(_group);
        _withdrawn.prize = _withdrawn.prize.add(_prize);
        state.setWithdrawn(_account, _withdrawn);

        _user.rounds = pools.rounds();
        state.setUser(_account, _user);

        updateGroup(_account, _liquid);

        emit Withdraw(_account, _user);
    }

    function withdraw() external {
        if (isOutWithRisk(msg.sender)) {
            _clearUser(msg.sender);
            return;
        }

        updateLiquid(msg.sender);

        Reward memory _reward = state.getReward(msg.sender);
        Withdrawn memory _withdrawn = state.getWithdrawn(msg.sender);

        uint256 max = state.getUser(msg.sender).liquid.mul(25).div(10);
        uint256 _prizeReward = totalPrizeReward(msg.sender);

        uint256 _totalReward = _reward.liquid.add(_reward.invitee).add(_reward.group).add(_prizeReward);
        if (max >= _totalReward) {
            _withdraw(
                msg.sender,
                _reward.liquid.sub(_withdrawn.liquid),
                _reward.invitee.sub(_withdrawn.invitee),
                _reward.group.sub(_withdrawn.group),
                0,
                0
            );
        } else {
            _withdraw(
                msg.sender,
                _reward.liquid.mul(max).div(_totalReward).sub(_withdrawn.liquid),
                _reward.invitee.mul(max).div(_totalReward).sub(_withdrawn.invitee),
                _reward.group.mul(max).div(_totalReward).sub(_withdrawn.group),
                0,
                0
            );
        }

        bool clearFlag;
        if (isOut(msg.sender)) {
            clearFlag = true;
            _clearUser(msg.sender);
        }

        if ((block.timestamp - pools.lastRiskTime()) > 30 * ONE_DAY && pools.mining().total.sub(pools.mining().withdraw) < MIN_AMOUNT_RISK.add(pools.total().div(block.timestamp.sub(pools.initTime()).div(ONE_DAY).add(200)))) {
            emitRisk();
            if (isOutWithRisk(msg.sender) && !clearFlag) {
                _clearUser(msg.sender);
            }
        }
    }

    function withdrawPrize() external {
        if (isOutWithRisk(msg.sender)) {
            _clearUser(msg.sender);
            return;
        }

        updateLiquid(msg.sender);

        Reward memory _reward = state.getReward(msg.sender);
        Withdrawn memory _withdrawn = state.getWithdrawn(msg.sender);

        uint256 max = state.getUser(msg.sender).liquid.mul(25).div(10);
        uint256 _prizeReward = totalPrizeReward(msg.sender);

        uint256 _totalReward = _reward.liquid.add(_reward.invitee).add(_reward.group).add(_prizeReward);
        if (max >= _totalReward) {
            _withdraw(
                msg.sender,
                0,
                0,
                0,
                _prizeReward.sub(_withdrawn.prize),
                0
            );
        } else {
            _withdraw(
                msg.sender,
                0,
                0,
                0,
                _prizeReward.mul(max).div(_totalReward).sub(_withdrawn.prize),
                0
            );
        }
        prizeState.setDayWithdrawed(currentDay() - 1, msg.sender, true);
        prizeState.setDaySnap(currentDay(), pools.prize().total.sub(pools.prize().withdraw));

        bool clearFlag;
        if (isOut(msg.sender)) {
            clearFlag = true;
            _clearUser(msg.sender);
        }

        if ((block.timestamp - pools.lastRiskTime()) > 30 * ONE_DAY && pools.mining().total.sub(pools.mining().withdraw) < MIN_AMOUNT_RISK.add(pools.total().div(block.timestamp.sub(pools.initTime()).div(ONE_DAY).add(200)))) {
            emitRisk();
            if (isOutWithRisk(msg.sender) && !clearFlag) {
                _clearUser(msg.sender);
            }
        }
    }

    function updateGroup(address _account, uint256 _amount) private  {
        address parent = state.getUser(_account).referrer;
        uint256 dis = 1;

        while(parent != address(0x0) && dis <= 21) {
            User memory user = state.getUser(parent);
            Reward memory reward = state.getReward(parent);

            if (dis <= user.inviteeCount && user.liquid > 0 && canReward(parent)) {
                if (dis == 1) {
                    reward.group = reward.group
                        .add(_amount.mul(30).div(100));
                } else if (dis == 2) {
                    reward.group = reward.group
                        .add(_amount.mul(10).div(100));
                } else if (dis == 3) {
                    reward.group = reward.group
                        .add(_amount.mul(5).div(100));
                } else if (dis <= 21) {
                    reward.group = reward.group
                        .add(_amount.mul(3).div(100));
                }
            }

            state.setReward(parent, reward);

            parent = user.referrer;
            dis++;
        }
    }

    function emitRisk() private {
        pools.addRounds();
        pools.updateLastRiskTime();

        emit Risk(pools.rounds());
    }

    function liquidReward(address _account) public view returns(uint256) {
        User memory _user = state.getUser(_account);
        Reward memory _reward = state.getReward(_account);
        Withdrawn memory _withdrawn = state.getWithdrawn(_account);
        Pool memory _mining = pools.mining();
        Pool memory _store = pools.store();

        uint256 withdrawn = _reward.liquid
            .add(_reward.invitee)
            .add(_reward.group)
            .add(_withdrawn.prize);

        uint256 rewardPerDay;
        if (withdrawn >= _user.liquid.mul(25).div(10)) {
            rewardPerDay = 0;
        } else {
            if (isOld[_account]) {
                rewardPerDay = (_store.total.sub(_store.withdraw))
                    .mul(state.staticRate()).div(10000)
                    .mul(_user.liquid.mul(25).div(10).sub(withdrawn))
                    .div(pools.total().mul(25).div(10).sub(pools.totalWithdraw()));
            } else {
                rewardPerDay = (_mining.total.sub(_mining.withdraw))
                    .mul(state.staticRate()).div(10000)
                    .mul(_user.liquid.mul(25).div(10).sub(withdrawn))
                    .div(pools.total().mul(25).div(10).sub(pools.totalWithdraw()));
            }
        }

        return block.timestamp.sub(_user.rewardTime)
            .div(ONE_DAY).mul(rewardPerDay)
            .add(_reward.liquid);
    }

    function prizeGroupReward(address _account) public view returns(uint256) {
        User memory _user = state.getUser(_account);
        if (_user.liquid < 100000 * 10**6) return 0;
        if (_user.groupCount < 500) return 0;

        uint256 _day = currentDay() - 1;
        if (prizeState.getDayWithdrawed(_day, _account)) return 0;

        uint256 _dayInvitee = prizeState.getDayInvitee(_day, _account);
        uint256 _dayGroupTotal = prizeState.getDayGroupTotal(_day);

        if (_dayInvitee < 50000 * 10**6) return 0;
        if (_dayGroupTotal == 0) return 0;

        uint256 _totalPrize = prizeState.getDaySnap(_day).mul(30).div(100);
        uint256 _reward = _totalPrize.mul(Math.min(prizeState.getDayGroupRank(_day).length, 20)).div(20);

        return _reward.mul(_dayInvitee).div(_dayGroupTotal);
    }

    function prizeInviteeReward(address _account) public view returns(uint256) {
        uint256 _day = currentDay() - 1;

        if (prizeState.getDayWithdrawed(_day, _account)) return 0;

        uint256 _dayInvitee = prizeState.getDayInvitee(_day, _account);
        uint256 _dayInviteeTotal = prizeState.getDayInviteeTotal(_day);

        if (_dayInviteeTotal == 0) return 0;

        uint256 _totalPrize = prizeState.getDaySnap(_day).mul(8).div(100);
        uint256 _reward;
        if (_dayInvitee >= 300000 * 10**6) {
            _reward = _totalPrize.mul(40).div(100);
        } else if (_dayInvitee >= 200000 * 10**6) {
            _reward = _totalPrize.mul(30).div(100);
        } else if (_dayInvitee >= 100000 * 10**6) {
            _reward = _totalPrize.mul(30).div(100);
        } else {
            _reward = 0;
        }

        return _reward.mul(_dayInvitee).div(_dayInviteeTotal);
    }

    function totalPrizeReward(address _account) public view returns(uint256) {
        Withdrawn memory _withdrawn = state.getWithdrawn(_account);

        return prizeGroupReward(_account)
            .add(prizeInviteeReward(_account))
            .add(_withdrawn.prize);
    }

    function canReward(address _account) public view returns(bool) {
        User memory _user = state.getUser(_account);
        Reward memory _reward = state.getReward(_account);

        return _user.liquid.mul(25).div(10) > _reward.invitee.add(_reward.group).add(totalPrizeReward(_account)).add(liquidReward(_account));
    }

    function isOut(address _account) public view returns(bool) {
        User memory _user = state.getUser(_account);
        Withdrawn memory _withdrawn = state.getWithdrawn(_account);

        return _user.liquid.mul(25).div(10) <= _withdrawn.liquid.add(_withdrawn.invitee).add(_withdrawn.group).add(_withdrawn.prize);
    }

    function isOutWithRisk(address _account) public view returns(bool) {
        User memory _user = state.getUser(_account);
        Withdrawn memory _withdrawn = state.getWithdrawn(_account);

        return (pools.rounds() > _user.rounds) && (_withdrawn.liquid.add(_withdrawn.invitee).add(_withdrawn.group).add(_withdrawn.prize) >= _user.liquid);
    }

    function currentDay() public view returns(uint256) {
        return block.timestamp.div(ONE_DAY);
    }

    function getUser(address _account) external view returns(User memory) {
        return state.getUser(_account);
    }

    function getUser_liquid(address _account) external view returns(uint256) {
        return state.getUser(_account).liquid;
    }
    function getUser_lastLiquid(address _account) external view returns(uint256) {
        return state.getUser(_account).lastLiquid;
    }
    function getUser_referrer(address _account) external view returns(address) {
        return state.getUser(_account).referrer;
    }
    function getUser_inviteeCount(address _account) external view returns(uint256) {
        return state.getUser(_account).inviteeCount;
    }
    function getUser_groupCount(address _account) external view returns(uint256) {
        return state.getUser(_account).groupCount;
    }
    function getUser_rewardTime(address _account) external view returns(uint256) {
        return state.getUser(_account).rewardTime;
    }
    function getUser_outTime(address _account) external view returns(uint256) {
        return state.getUser(_account).outTime;
    }
    function getUser_rounds(address _account) external view returns(uint256) {
        return state.getUser(_account).rounds;
    }

    function getReward(address _account) external view returns(IReward memory) {
        Reward memory _reward = state.getReward(_account);

        return IReward({
            liquid: liquidReward(_account),
            invitee: _reward.invitee,
            group: _reward.group,
            prize: totalPrizeReward(_account)
        });
    }
    function getReward_liquid(address _account) external view returns(uint256) {
        return liquidReward(_account);
    }
    function getReward_invitee(address _account) external view returns(uint256) {
        Reward memory _reward = state.getReward(_account);
        return _reward.invitee;
    }
    function getReward_group(address _account) external view returns(uint256) {
        Reward memory _reward = state.getReward(_account);
        return _reward.group;
    }
    function getReward_prize(address _account) external view returns(uint256) {
        return totalPrizeReward(_account);
    }

    function getWithdrawn(address _account) external view returns(Withdrawn memory) {
        return state.getWithdrawn(_account);
    }
    function  getWithdrawn_liquid(address _account) external view returns(uint256) {
        return state.getWithdrawn(_account).liquid;
    }
    function  getWithdrawn_invitee(address _account) external view returns(uint256) {
        return state.getWithdrawn(_account).invitee;
    }
    function  getWithdrawn_group(address _account) external view returns(uint256) {
        return state.getWithdrawn(_account).group;
    }
    function  getWithdrawn_prize(address _account) external view returns(uint256) {
        return state.getWithdrawn(_account).prize;
    }

    function mining() external view returns(Pool memory) {
        return pools.mining();
    }
    function mining_total() external view returns(uint256) {
        return pools.mining().total;
    }
    function mining_withdraw() external view returns(uint256) {
        return pools.mining().withdraw;
    }

    function store() external view returns(Pool memory) {
        return pools.store();
    }
    function store_total() external view returns(uint256) {
        return pools.store().total;
    }
    function store_withdraw() external view returns(uint256) {
        return pools.store().withdraw;
    }

    function prize() external view returns(Pool memory) {
        return pools.prize();
    }
    function prize_total() external view returns(uint256) {
        return pools.prize().total;
    }
    function prize_withdraw() external view returns(uint256) {
        return pools.prize().withdraw;
    }

    function totalLiquid() external view returns(uint256) {
        return pools.total();
    }

    function getGroupTotal() external view returns(uint256) {
        return prizeState.getDayGroupTotal(currentDay() - 1);
    }

    function getDayInvitee(address _account) external view returns(uint256) {
        return prizeState.getDayInvitee(currentDay() - 1, _account);
    }

    function getDayInviteeTotal() external view returns(uint256) {
        return prizeState.getDayInviteeTotal(currentDay() - 1);
    }

    function getGroupRank() external view returns(IRank[] memory) {
        address[] memory accounts = prizeState.getDayGroupRank(currentDay() - 1);
        IRank[] memory rank = new IRank[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = prizeState.getDayInvitee(currentDay() - 1, accounts[i]);
            uint256 reward = prizeGroupReward(accounts[i]);
            rank[i] = IRank({
                account: accounts[i],
                amount: amount,
                reward: reward
            });
        }
        return rank;
    }
    function getGroupRank_accounts() external view returns(address[] memory) {
        address[] memory accounts = prizeState.getDayGroupRank(currentDay() - 1);
        return accounts;
    }
    function getGroupRank_amounts() external view returns(uint256[] memory) {
        address[] memory accounts = prizeState.getDayGroupRank(currentDay() - 1);
        uint256[] memory amounts = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            amounts[i] = prizeState.getDayInvitee(currentDay() - 1, accounts[i]);
        }
        return amounts;
    }
    function getGroupRank_rewards() external view returns(uint256[] memory) {
        address[] memory accounts = prizeState.getDayGroupRank(currentDay() - 1);
        uint256[] memory rewards = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            rewards[i] = prizeGroupReward(accounts[i]);
        }
        return rewards;
    }

    function getDayInviteeRank() external view returns(IRank[] memory) {
        address[] memory accounts = prizeState.getDayInviteeRank(currentDay() - 1);
        IRank[] memory rank = new IRank[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = prizeState.getDayInvitee(currentDay() - 1, accounts[i]);
            uint256 reward = prizeInviteeReward(accounts[i]);
            rank[i] = IRank({
                account: accounts[i],
                amount: amount,
                reward: reward
            });
        }
        return rank;
    }
    function getDayInviteeRank_accounts() external view returns(address[] memory) {
        address[] memory accounts = prizeState.getDayInviteeRank(currentDay() - 1);
        return accounts;
    }
    function getDayInviteeRank_amounts() external view returns(uint256[] memory) {
        address[] memory accounts = prizeState.getDayInviteeRank(currentDay() - 1);
        uint256[] memory amounts = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            amounts[i] = prizeState.getDayInvitee(currentDay() - 1, accounts[i]);
        }
        return amounts;
    }
    function getDayInviteeRank_rewards() external view returns(uint256[] memory) {
        address[] memory accounts = prizeState.getDayInviteeRank(currentDay() - 1);
        uint256[] memory rewards = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            rewards[i] = prizeInviteeReward(accounts[i]);
        }
        return rewards;
    }
}