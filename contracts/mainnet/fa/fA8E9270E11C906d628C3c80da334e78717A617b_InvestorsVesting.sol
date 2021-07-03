//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IOneUp.sol';
import './interfaces/IVesting.sol';


contract InvestorsVesting is IVesting, Ownable {
    using SafeMath for uint256;

    uint256 public start;
    uint256 public finish;

    uint256 public constant RATE_BASE = 10000; // 100%
    uint256 public constant VESTING_DELAY = 90 days;

    IOneUp public immutable oneUpToken;

    struct Investor {
        // If user keep his tokens during the all vesting delay
        // He becomes privileged user and will be allowed to do some extra stuff
        bool isPrivileged;

        // Tge tokens will be available for claiming immediately after UNI liquidity creation
        // Users will receive all available TGE tokens with 1 transaction
        uint256 tgeTokens;

        // Released locked tokens shows amount of tokens, which user already received
        uint256 releasedLockedTokens;

        // Total locked tokens shows total amount, which user should receive in general
        uint256 totalLockedTokens;
    }

    mapping(address => Investor) internal _investors;

    event NewPrivilegedUser(address investor);
    event TokensReceived(address investor, uint256 amount, bool isLockedTokens);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor(address token_) {
        oneUpToken = IOneUp(token_);
    }

    // ------------------------
    // SETTERS (ONLY PRE-SALE)
    // ------------------------

    /// @notice Add investor and receivable amount for future claiming
    /// @dev This method can be called only by Public sale contract, during the public sale
    /// @param investor Address of investor
    /// @param amount Tokens amount which investor should receive in general
    /// @param lockPercent Which percent of tokens should be available immediately (after start), and which should be locked
    function submit(
        address investor,
        uint256 amount,
        uint256 lockPercent
    ) public override onlyOwner {
        require(start == 0, 'submit: Can not be added after liquidity pool creation!');

        uint256 tgeTokens = amount.mul(lockPercent).div(RATE_BASE);
        uint256 lockedAmount = amount.sub(tgeTokens);

        _investors[investor].tgeTokens = _investors[investor].tgeTokens.add(tgeTokens);
        _investors[investor].totalLockedTokens = _investors[investor].totalLockedTokens.add(lockedAmount);
    }

    /// @notice Remove investor data
    /// @dev Owner will remove investors data if they called emergency exit method
    /// @param investor Address of investor
    function reset(address investor) public override onlyOwner {
      delete _investors[investor];
    }

    /// @notice The same as submit, but for multiply investors
    /// @dev Provided arrays should have the same length
    /// @param investors Array of investors
    /// @param amounts Array of receivable amounts
    /// @param lockPercent Which percent of tokens should be available immediately (after start), and which should be locked
    function submitMulti(
        address[] memory investors,
        uint256[] memory amounts,
        uint256 lockPercent
    ) external override onlyOwner {
        uint256 investorsLength = investors.length;

        for (uint i = 0; i < investorsLength; i++) {
            submit(investors[i], amounts[i], lockPercent);
        }
    }

    /// @notice Start vesting process
    /// @dev After this method investors can claim their tokens
    function setStart() external override onlyOwner {
        start = block.timestamp;
        finish = start.add(VESTING_DELAY);
    }

    // ------------------------
    // SETTERS (ONLY CONTRIBUTOR)
    // ------------------------

    /// @notice Claim TGE tokens immediately after start
    /// @dev Can be called once for each investor
    function claimTgeTokens() external override {
        require(start > 0, 'claimTgeTokens: TGE tokens not available now!');

        // Get user available TGE tokens
        uint256 amount = _investors[msg.sender].tgeTokens;
        require(amount > 0, 'claimTgeTokens: No available tokens!');

        // Update user available TGE balance
        _investors[msg.sender].tgeTokens = 0;

        // Mint tokens to user address
        oneUpToken.mint(msg.sender, amount);

        emit TokensReceived(msg.sender, amount, false);
    }

    /// @notice Claim locked tokens
    function claimLockedTokens() external override {
        require(start > 0, 'claimLockedTokens: Locked tokens not available now!');

        // Get user releasable tokens
        uint256 availableAmount = _releasableAmount(msg.sender);
        require(availableAmount > 0, 'claimLockedTokens: No available tokens!');

        // If investors claim all tokens after vesting finish they become privileged
        // No need to validate flag every time, as users will claim all tokens with this method
        if (_investors[msg.sender].releasedLockedTokens == 0 && block.timestamp > finish) {
            _investors[msg.sender].isPrivileged = true;

            emit NewPrivilegedUser(msg.sender);
        }

        // Update user released locked tokens amount
        _investors[msg.sender].releasedLockedTokens = _investors[msg.sender].releasedLockedTokens.add(availableAmount);

        // Mint tokens to user address
        oneUpToken.mint(msg.sender, availableAmount);

        emit TokensReceived(msg.sender, availableAmount, true);
    }

    // ------------------------
    // GETTERS
    // ------------------------

    /// @notice Get current available locked tokens
    /// @param investor address
    function getReleasableLockedTokens(address investor) external override view returns (uint256) {
        return _releasableAmount(investor);
    }

    /// @notice Get investor data
    /// @param investor address
    function getUserData(address investor) external override view returns (
        uint256 tgeAmount,
        uint256 releasedLockedTokens,
        uint256 totalLockedTokens
    ) {
        return (
            _investors[investor].tgeTokens,
            _investors[investor].releasedLockedTokens,
            _investors[investor].totalLockedTokens
        );
    }

    /// @notice Is investor privileged or not, it will be used from external contracts
    /// @param account user address
    function isPrivilegedInvestor(address account) external override view returns (bool) {
        return _investors[account].isPrivileged;
    }

    // ------------------------
    // INTERNAL
    // ------------------------

    function _releasableAmount(address investor) private view returns (uint256) {
        return _vestedAmount(investor).sub(_investors[investor].releasedLockedTokens);
    }

    function _vestedAmount(address investor) private view returns (uint256) {
        uint256 userMaxTokens = _investors[investor].totalLockedTokens;

        if (start == 0 || block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= finish) {
            return userMaxTokens;
        } else {
            uint256 timeSinceStart = block.timestamp.sub(start);
            return userMaxTokens.mul(timeSinceStart).div(VESTING_DELAY);
        }
    }

    function getStartTime() external view returns (uint256) {
        return start;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IOneUp is IERC20 {
    function burn(uint256 amount) external;
    function setTradingStart(uint256 time) external;
    function mint(address to, uint256 value) external;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


interface IVesting {
    function submit(address investor, uint256 amount, uint256 lockPercent) external;
    function submitMulti(address[] memory investors, uint256[] memory amounts, uint256 lockPercent) external;
    function setStart() external;
    function claimTgeTokens() external;
    function claimLockedTokens() external;
    function reset(address investor) external;
    function isPrivilegedInvestor(address account) external view returns (bool);
    function getReleasableLockedTokens(address investor) external view returns (uint256);
    function getUserData(address investor) external view returns (uint256 tgeAmount, uint256 releasedLockedTokens, uint256 totalLockedTokens);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}