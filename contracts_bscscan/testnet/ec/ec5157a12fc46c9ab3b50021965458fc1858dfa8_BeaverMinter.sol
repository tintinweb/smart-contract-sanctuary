/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

/*
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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// Dependency file: contracts/interfaces/IBeaverChef.sol

// pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

interface IBeaverChef {
    struct UserInfo {
        uint256 balance;
        uint256 pending;
        uint256 rewardPaid;
    }

    struct VaultInfo {
        address token;
        uint256 allocPoint; // How many allocation points assigned to this pool. BEAVERs to distribute per block.
        uint256 lastRewardBlock; // Last block number that BEAVERs distribution occurs.
        uint256 accBeaverPerShare; // Accumulated BEAVERs per share, times 1e12. See below.
    }

    function bulkUpdateRewards() external;

    function beaverPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function vaultInfoOf(address vault) external view returns (VaultInfo memory);

    function vaultUserInfoOf(address vault, address user) external view returns (UserInfo memory);

    function pendingBeaver(address vault, address user) external view returns (uint256);

    function notifyDeposited(address user, uint256 amount) external;

    function notifyWithdrawn(address user, uint256 amount) external;

    function safeBeaverTransfer(address user) external returns (uint256);
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// Dependency file: contracts/interfaces/IBeaverToken.sol

// pragma solidity 0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBeaverToken is IERC20 {
    function mint(address account, uint256 amount) external;
}


// Dependency file: contracts/interfaces/IBeaverMinter.sol

// pragma solidity 0.8.0;

interface IBeaverMinter {
    function deflationMode() external view returns (uint256);

    function beaverPerBlock() external view returns (uint256);

    function updateBeaverPerBlock() external;

    function mintFor(
        address account,
        address pool,
        uint256 amount
    ) external;
}


// Root file: contracts/beaver/BeaverMinter.sol

pragma solidity 0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "contracts/interfaces/IBeaverChef.sol";
// import "contracts/interfaces/IBeaverToken.sol";
// import "contracts/interfaces/IBeaverMinter.sol";

interface IRewardStaking {
    function depositFor(address account, uint256 amount) external;
}

interface IRewardLocking {
    function setLockPeriod(uint256 duration) external;

    function deposit(
        address account,
        address pool,
        uint256 amount
    ) external;
}

contract BeaverMinter is IBeaverMinter, Ownable {
    using SafeMath for uint256;

    address public beaverDev;
    uint256 public lockRatio;
    uint256 public blockPerDay;
    uint256 public expansionRate; // max 10000, ex 0.5% -> 50
    uint256 public lastUpdateTime;
    uint256 public supplyTarget;
    IBeaverChef public beaverChef;
    IBeaverToken public beaverToken;
    IRewardStaking public rewardStaking;
    IRewardLocking public rewardLocking;

    uint256 public override deflationMode; // 1: liquidity, 2: burn
    uint256 public override beaverPerBlock;

    modifier onlyBeaverChef() {
        require(msg.sender == address(beaverChef), "BeaverMinter: only BeaverChef");
        _;
    }

    constructor(
        address _beaverDev,
        IBeaverToken _beaverToken
    ) {
        beaverDev = _beaverDev;
        beaverToken = _beaverToken;

        lockRatio = 7000; // 70%
        blockPerDay = 28800;
        expansionRate = 50; // 0.5%
        supplyTarget = 10000000e18; // 10M
        deflationMode = 1;

        updateBeaverPerBlock();
    }

    function setLockRatio(uint256 _lockRate) external onlyOwner {
        require(_lockRate < 9000, "BeaverMinter: require rate max is 9000");
        lockRatio = _lockRate;
    }

    function setBlockPerDay(uint256 _blockPerDay) external onlyOwner {
        blockPerDay = _blockPerDay;
    }

    function setExpansionRate(uint256 _exRate) external onlyOwner {
        require(_exRate < 5000, "BeaverMinter: require rate max is 5000");
        expansionRate = _exRate;
    }

    function setSupplyTarget(uint256 _target) external onlyOwner {
        require(_target > supplyTarget, "BeaverMinter: must be greater than current target");
        supplyTarget = _target;
    }

    function setRewardStaking(IRewardStaking _stakingPool) external onlyOwner {
        rewardStaking = _stakingPool;
    }

    function setRewardLocking(IRewardLocking _lockingPool) external onlyOwner {
        rewardLocking = _lockingPool;
    }

    function setBeaverChef(IBeaverChef _beaverChef) external onlyOwner {
        beaverChef = _beaverChef;
    }

    function setBeaverDev(address _dev) external onlyOwner {
        beaverDev = _dev;
    }

    function setDeflationMode(uint256 _mode) external onlyOwner {
        deflationMode = _mode;
    }

    function mintFor(
        address account,
        address pool,
        uint256 amount
    ) external override onlyBeaverChef {
        mint(account, pool, amount);
    }

    function mint(
        address account,
        address pool,
        uint256 amount
    ) private {
        uint256 beaverForDev = amount.div(10);

        beaverToken.mint(address(this), amount.add(beaverForDev));
        if (address(rewardStaking) != address(0)) {
            rewardStaking.depositFor(beaverDev, beaverForDev);
        } else {
            beaverToken.transfer(beaverDev, beaverForDev);
        }

        uint256 bal = beaverToken.balanceOf(address(this));
        if (bal < amount) {
            amount = bal;
        }

        if (address(rewardLocking) != address(0)) {
            // lock reward
            uint256 lockAmount = amount.mul(lockRatio).div(10000);
            beaverToken.transfer(address(rewardLocking), lockAmount);
            rewardLocking.deposit(account, pool, lockAmount);

            beaverToken.transfer(account, amount.sub(lockAmount));
        } else {
            // transfer all
            beaverToken.transfer(address(rewardLocking), amount);
        }

        updateBeaverPerBlock();
    }

    function updateBeaverPerBlock() public override {
        uint256 duration = block.timestamp.sub(lastUpdateTime);
        if (duration > 1 hours) {
            uint256 remain = supplyTarget.sub(beaverToken.totalSupply());
            beaverPerBlock = remain.mul(expansionRate).div(10000).div(blockPerDay);

            if (address(beaverChef) != address(0)) {
                beaverChef.bulkUpdateRewards();
            }
        }
    }
}