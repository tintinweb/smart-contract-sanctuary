/**
 *Submitted for verification at FtmScan.com on 2022-01-16
*/

// Dependency file: contracts/interfaces/ITreasury.sol

// SPDX-License-Identifier: MIT
// pragma solidity 0.8.4;

interface ITreasury {
    function amountToMint(address _pair, uint256 _amount) external view returns (uint256);

    function mintRewards() external;

    function mintBonus(
        address _token,
        uint256 _principal,
        uint256 _bonus
    ) external returns (uint256);
}


// Dependency file: contracts/interfaces/IBonding.sol

// pragma solidity 0.8.4;

interface IBonding {
    struct PoolInfo {
        address lpToken; // principal LP token
        uint256 bonus; // 0 - 10000, 0 - 100%
        bool enabled;
    }

    struct UserInfo {
        uint256 payout; // sAPE remaining to be paid
        uint256 vesting; // Seconds left to vest
        uint256 lastTime; // Last interaction
    }

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 bonus,
            bool enabled
        );

    function userInfo(uint256 _pid, address _account)
        external
        view
        returns (
            uint256 payout,
            uint256 vesting,
            uint256 lastTime
        );

    event Purchased(uint256 indexed pid, address indexed account, uint256 principal, uint256 reward);
    event Redeemed(uint256 indexed pid, address indexed account, uint256 amount);
}


// Dependency file: contracts/interfaces/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// Dependency file: contracts/libraries/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// Dependency file: contracts/libraries/utils/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "contracts/libraries/utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// Dependency file: contracts/libraries/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Root file: contracts/Bonding.sol

pragma solidity 0.8.4;

// import "contracts/interfaces/ITreasury.sol";
// import "contracts/interfaces/IBonding.sol";
// import "contracts/interfaces/ERC20/IERC20.sol";
// import "contracts/libraries/utils/Ownable.sol";
// import "contracts/libraries/math/SafeMath.sol";

contract HominidBonding is IBonding, Ownable {
    using SafeMath for uint256;

    address public APE;
    address public treasury;
    address public staking;
    uint256 public vestingTerm;
    uint256 public controlVariable;

    PoolInfo[] public override poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function percentVestedFor(uint256 _pid, address _depositor) public view returns (uint256 percentVested_) {
        UserInfo memory info = userInfo[_pid][_depositor];
        uint256 secsSinceLast = block.timestamp.sub(info.lastTime);
        uint256 vesting = info.vesting;

        if (vesting > 0) {
            percentVested_ = secsSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    function pendingPayoutFor(uint256 _pid, address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_pid, _depositor);
        uint256 payout = userInfo[_pid][_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }

    function purchase(
        uint256 _pid,
        address _depositor,
        uint256 _amount
    ) external {
        PoolInfo memory pool = poolInfo[_pid];
        require(pool.enabled, "not enabled");

        IERC20(pool.lpToken).transferFrom(msg.sender, address(this), _amount);

        uint256 bonus = _amount.mul(pool.bonus).mul(controlVariable).div(10_1000).div(10_000);

        IERC20(pool.lpToken).approve(treasury, 0);
        IERC20(pool.lpToken).approve(treasury, _amount);
        uint256 stakeAmount = ITreasury(treasury).mintBonus(pool.lpToken, _amount, bonus);

        UserInfo memory user = userInfo[_pid][_depositor];
        userInfo[_pid][_depositor] = UserInfo({
            payout: user.payout.add(stakeAmount),
            vesting: vestingTerm,
            lastTime: block.timestamp
        });

        emit Purchased(_pid, _depositor, _amount, stakeAmount);
    }

    function redeem(uint256 _pid, address _recipient) external {
        UserInfo memory info = userInfo[_pid][_recipient];
        uint256 percentVested = percentVestedFor(_pid, _recipient);

        if (percentVested >= 10000) {
            delete userInfo[_pid][_recipient]; // delete user info
            emit Redeemed(_pid, _recipient, info.payout);
            IERC20(staking).transfer(_recipient, info.payout);
        } else {
            uint256 payout = info.payout.mul(percentVested).div(10000);

            // store updated deposit info
            userInfo[_pid][_recipient] = UserInfo({
                payout: info.payout.sub(payout),
                vesting: info.vesting.sub(block.timestamp.sub(info.lastTime)),
                lastTime: block.timestamp
            });

            emit Redeemed(_pid, _recipient, payout);
            IERC20(staking).transfer(_recipient, payout);
        }
    }

    function initialize(
        address _APE,
        address _treasury,
        address _staking,
        uint256 _vestingTerm,
        uint256 _controlVariable
    ) external onlyOwner {
        require(APE == address(0), "already initialized");

        APE = _APE;
        treasury = _treasury;
        staking = _staking;
        vestingTerm = _vestingTerm;
        controlVariable = _controlVariable;
    }

    function add(address _lpToken, uint256 _bonus) external onlyOwner {
        poolInfo.push(PoolInfo({lpToken: _lpToken, bonus: _bonus, enabled: true}));
    }

    function set(
        uint256 _pid,
        uint256 _bonus,
        bool _enabled
    ) external onlyOwner {
        poolInfo[_pid].bonus = _bonus;
        poolInfo[_pid].enabled = _enabled;
    }

    function setVesting(uint256 _vestingTerm) external onlyOwner {
        vestingTerm = _vestingTerm;
    }

    function setVariable(uint256 _controlVariable) external onlyOwner {
        controlVariable = _controlVariable;
    }
}