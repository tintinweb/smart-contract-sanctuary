/**
 *Submitted for verification at Etherscan.io on 2020-11-13
*/

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: contracts/compound/ComptrollerInterface.sol

pragma solidity ^0.5.16;

contract ComptrollerInterface {
    // implemented, but missing from the interface
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint redeemTokens,
        uint borrowAmount) external view returns (uint, uint, uint);

    function claimComp(address holder) external;

    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);

    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);

    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);

    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);

    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);

    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);

    function markets(address cToken) external view returns (bool, uint);

    function compSpeeds(address cToken) external view returns (uint);
}

// File: contracts/compound/InterestRateModel.sol

pragma solidity ^0.5.16;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amnount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amnount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

// File: contracts/compound/CTokenInterfaces.sol

pragma solidity ^0.5.16;


contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping(address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrowRatePerBlock() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) public view returns (uint);

    function exchangeRateCurrent() public returns (uint);

    function exchangeRateStored() public view returns (uint);

    function getCash() external view returns (uint);

    function accrueInterest() public returns (uint);

    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);

    function _acceptAdmin() external returns (uint);

    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint);

    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);

    function _reduceReserves(uint reduceAmount) external returns (uint);

    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);
}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

contract CErc20Interface is CErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external returns (uint);
}

contract CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract CDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
}

contract CDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}

// File: contracts/strategies/compound/CompleteCToken.sol

pragma solidity 0.5.16;


contract CompleteCToken is CErc20Interface, CTokenInterface {}

// File: contracts/hardworkInterface/IStrategy.sol

pragma solidity 0.5.16;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);
}

// File: contracts/weth/WETH9.sol

// based on https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
*/

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.5.16;

contract WETH9 {

    function balanceOf(address target) public view returns (uint256);

    function deposit() public payable;

    function withdraw(uint wad) public;

    function totalSupply() public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);

    function transfer(address dst, uint wad) public returns (bool);

    function transferFrom(address src, address dst, uint wad) public returns (bool);

}

// File: @studydefi/money-legos/compound/contracts/ICEther.sol

pragma solidity ^0.5.0;

contract ICEther {
    function mint() external payable;

    function borrow(uint borrowAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint);

    function balanceOf(address owner) external view returns (uint256);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

// File: contracts/strategies/compound/CompoundInteractor.sol

pragma solidity 0.5.16;


contract CompoundInteractor is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public underlying;
    IERC20 public _weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    CompleteCToken public ctoken;
    ComptrollerInterface public comptroller;

    constructor(
        address _underlying,
        address _ctoken,
        address _comptroller
    ) public {
        // Comptroller:
        comptroller = ComptrollerInterface(_comptroller);

        underlying = IERC20(_underlying);
        ctoken = CompleteCToken(_ctoken);

        // Enter the market
        address[] memory cTokens = new address[](1);
        cTokens[0] = _ctoken;
        //        comptroller.enterMarkets(cTokens);
    }

    /**
    * Supplies Ether to Compound
    * Unwraps WETH to Ether, then invoke the special mint for cEther
    * We ask to supply "amount", if the "amount" we asked to supply is
    * more than balance (what we really have), then only supply balance.
    * If we the "amount" we want to supply is less than balance, then
    * only supply that amount.
    */
    function _supplyEtherInWETH(uint256 amountInWETH) internal nonReentrant {
        // underlying here is WETH
        uint256 balance = underlying.balanceOf(address(this));
        // supply at most "balance"
        if (amountInWETH < balance) {
            balance = amountInWETH;
            // only supply the "amount" if its less than what we have
        }
        WETH9 weth = WETH9(address(_weth));
        weth.withdraw(balance);
        // Unwrapping
        ICEther(address(ctoken)).mint.value(balance)();
    }

    /**
    * Redeems Ether from Compound
    * receives Ether. Wrap all the ether that is in this contract.
    */
    function _redeemEtherInCTokens(uint256 amountCTokens) internal nonReentrant {
        _redeemInCTokens(amountCTokens);
        WETH9 weth = WETH9(address(_weth));
        weth.deposit.value(address(this).balance)();
    }

    /**
    * Supplies to Compound
    */
    function _supply(uint256 amount) internal returns (uint256) {
        uint256 balance = underlying.balanceOf(address(this));
        if (amount < balance) {
            balance = amount;
        }
        underlying.safeApprove(address(ctoken), 0);
        underlying.safeApprove(address(ctoken), balance);
        uint256 mintResult = ctoken.mint(balance);
        require(mintResult == 0, "Supplying failed");
        return balance;
    }

    /**
    * Borrows against the collateral
    */
    function _borrow(
        uint256 amountUnderlying
    ) internal {
        // Borrow DAI, check the DAI balance for this contract's address
        uint256 result = ctoken.borrow(amountUnderlying);
        require(result == 0, "Borrow failed");
    }

    /**
    * Repays a loan
    */
    function _repay(uint256 amountUnderlying) internal {
        underlying.safeApprove(address(ctoken), 0);
        underlying.safeApprove(address(ctoken), amountUnderlying);
        ctoken.repayBorrow(amountUnderlying);
        underlying.safeApprove(address(ctoken), 0);
    }

    /**
    * Redeem liquidity in cTokens
    */
    function _redeemInCTokens(uint256 amountCTokens) internal {
        if (amountCTokens > 0) {
            ctoken.redeem(amountCTokens);
        }
    }

    /**
    * Redeem liquidity in underlying
    */
    function _redeemUnderlying(uint256 amountUnderlying) internal {
        if (amountUnderlying > 0) {
            ctoken.redeemUnderlying(amountUnderlying);
        }
    }

    /**
    * Redeem liquidity in underlying
    */
    function redeemUnderlyingInWeth(uint256 amountUnderlying) internal {
        _redeemUnderlying(amountUnderlying);
        WETH9 weth = WETH9(address(_weth));
        weth.deposit.value(address(this).balance)();
    }

    /**
    * Get COMP
    */
    function claimComp() public {
        comptroller.claimComp(address(this));
    }

    /**
    * Redeem the minimum of the WETH we own, and the WETH that the cToken can
    * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently
    */
    function redeemMaximumWeth() internal {
        // amount of WETH in contract
        uint256 available = ctoken.getCash();
        // amount of WETH we own
        uint256 owned = ctoken.balanceOfUnderlying(address(this));

        // redeem the most we can redeem
        redeemUnderlyingInWeth(available < owned ? available : owned);
    }

    function getLiquidity() external view returns (uint256) {
        return ctoken.getCash();
    }

    function redeemMaximumToken() internal {
        // amount of tokens in ctoken
        uint256 available = ctoken.getCash();
        // amount of tokens we own
        uint256 owned = ctoken.balanceOfUnderlying(address(this));

        // redeem the most we can redeem
        _redeemUnderlying(available < owned ? available : owned);
    }

    function() external payable {} // this is needed for the WETH unwrapping
}

// File: contracts/Storage.sol

pragma solidity 0.5.16;

contract Storage {

    address public governance;
    address public controller;

    constructor() public {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender), "Not governance");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "new governance shouldn't be empty");
        governance = _governance;
    }

    function setController(address _controller) public onlyGovernance {
        require(_controller != address(0), "new controller shouldn't be empty");
        controller = _controller;
    }

    function isGovernance(address account) public view returns (bool) {
        return account == governance;
    }

    function isController(address account) public view returns (bool) {
        return account == controller;
    }
}

// File: contracts/Governable.sol

pragma solidity 0.5.16;


contract Governable {

    Storage public store;

    constructor(address _store) public {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    modifier onlyGovernance() {
        require(store.isGovernance(msg.sender), "Not governance");
        _;
    }

    function setStorage(address _store) public onlyGovernance {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    function governance() public view returns (address) {
        return store.governance();
    }
}

// File: contracts/Controllable.sol

pragma solidity 0.5.16;


contract Controllable is Governable {

    constructor(address _storage) Governable(_storage) public {
    }

    modifier onlyController() {
        require(store.isController(msg.sender), "Not a controller");
        _;
    }

    modifier onlyControllerOrGovernance(){
        require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
            "The caller must be controller or governance");
        _;
    }

    function controller() public view returns (address) {
        return store.controller();
    }
}

// File: contracts/uniswap/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/uniswap/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.5.0;


interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/strategies/LiquidityRecipient.sol

pragma solidity 0.5.16;


contract LiquidityRecipient is Controllable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LiquidityProvided(uint256 farmIn, uint256 wethIn, uint256 lpOut);
    event LiquidityRemoved(uint256 lpIn, uint256 wethOut, uint256 farmOut);

    modifier onlyStrategy() {
        require(msg.sender == wethStrategy, "only the weth strategy");
        _;
    }

    modifier onlyStrategyOrGovernance() {
        require(msg.sender == wethStrategy || msg.sender == governance(),
            "only not the weth strategy or governance");
        _;
    }

    // Address for WETH
    address public weth;

    // Address for FARM
    address public farm;

    // The WETH strategy this contract is hooked up to. The strategy cannot be changed.
    address public wethStrategy;

    // The treasury to provide FARM, and to receive FARM or overdraft weth
    address public treasury;

    // The address of the uniswap router
    address public uniswap;

    // The UNI V2 LP token matching the pool
    address public uniLp;

    // These tokens cannot be claimed by the controller
    mapping(address => bool) public unsalvagableTokens;

    constructor(
        address _storage,
        address _weth,
        address _farm,
        address _treasury,
        address _uniswap,
        address _uniLp,
        address _wethStrategy
    )
    Controllable(_storage)
    public {
        weth = _weth;
        farm = _farm;
        require(_treasury != address(0), "treasury cannot be address(0)");
        treasury = _treasury;
        uniswap = _uniswap;
        require(_uniLp != address(0), "uniLp cannot be address(0)");
        uniLp = _uniLp;
        unsalvagableTokens[_weth] = true;
        unsalvagableTokens[_uniLp] = true;
        wethStrategy = _wethStrategy;
    }

    /**
    * Adds liquidity to Uniswap.
    */
    function addLiquidity() internal {
        uint256 farmBalance = IERC20(farm).balanceOf(address(this));
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));

        IERC20(farm).safeApprove(uniswap, 0);
        IERC20(farm).safeApprove(uniswap, farmBalance);
        IERC20(weth).safeApprove(uniswap, 0);
        IERC20(weth).safeApprove(uniswap, wethBalance);

        (uint256 amountFarm,
        uint256 amountWeth,
        uint256 liquidity) = IUniswapV2Router02(uniswap).addLiquidity(farm,
            weth,
            farmBalance,
            wethBalance,
            0,
            0,
            address(this),
            block.timestamp);

        emit LiquidityProvided(amountFarm, amountWeth, liquidity);
    }

    /**
    * Removes liquidity from Uniswap.
    */
    function removeLiquidity() internal {
        uint256 lpBalance = IERC20(uniLp).balanceOf(address(this));
        if (lpBalance > 0) {
            IERC20(uniLp).safeApprove(uniswap, 0);
            IERC20(uniLp).safeApprove(uniswap, lpBalance);
            (uint256 amountFarm, uint256 amountWeth) = IUniswapV2Router02(uniswap).removeLiquidity(farm,
                weth,
                lpBalance,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit LiquidityRemoved(lpBalance, amountWeth, amountFarm);
        } else {
            emit LiquidityRemoved(0, 0, 0);
        }
    }

    /**
    * Adds liquidity to Uniswap. There is no vault for this cannot be invoked via controller. It has
    * to be restricted for market manipulation reasons, so only governance can call this method.
    */
    function doHardWork() public onlyGovernance {
        addLiquidity();
    }

    /**
    * Borrows the set amount of WETH from the strategy, and will invest all available liquidity
    * to Uniswap. This assumes that an approval from the strategy exists.
    */
    function takeLoan(uint256 amount) public onlyStrategy {
        IERC20(weth).safeTransferFrom(wethStrategy, address(this), amount);
        addLiquidity();
    }

    /**
    * Prepares for settling the loan to the strategy by withdrawing all liquidity from Uniswap,
    * and providing approvals to the strategy (for WETH) and to treasury (for FARM). The strategy
    * will make the WETH withdrawal by the pull pattern, and so will the treasury.
    */
    function settleLoan() public onlyStrategyOrGovernance {
        removeLiquidity();
        IERC20(weth).safeApprove(wethStrategy, 0);
        IERC20(weth).safeApprove(wethStrategy, uint256(- 1));
        IERC20(farm).safeApprove(treasury, 0);
        IERC20(farm).safeApprove(treasury, uint256(- 1));
    }

    /**
    * If Uniswap returns less FARM and more WETH, the WETH excess will be present in this strategy.
    * The governance can send this WETH to the treasury by invoking this function through the
    * strategy. The strategy ensures that this function is not called unless the entire WETH loan
    * was settled.
    */
    function wethOverdraft() external onlyStrategy {
        IERC20(weth).safeTransfer(treasury, IERC20(weth).balanceOf(address(this)));
    }

    /**
    * Salvages a token.
    */
    function salvage(address recipient, address token, uint256 amount) external onlyGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens[token], "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }
}

// File: contracts/hardworkInterface/IController.sol

pragma solidity 0.5.16;

interface IController {
    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns (bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;

    function doHardWork(address _vault) external;

    function hasVault(address _vault) external returns (bool);

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;

    function profitSharingNumerator() external view returns (uint256);

    function profitSharingDenominator() external view returns (uint256);
}

// File: contracts/strategies/RewardTokenProfitNotifier.sol

pragma solidity 0.5.16;


contract RewardTokenProfitNotifier is Controllable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public profitSharingNumerator;
    uint256 public profitSharingDenominator;
    address public rewardToken;

    constructor(
        address _storage,
        address _rewardToken
    ) public Controllable(_storage){
        rewardToken = _rewardToken;
        // persist in the state for immutability of the fee
        profitSharingNumerator = 30;
        //IController(controller()).profitSharingNumerator();
        profitSharingDenominator = 100;
        //IController(controller()).profitSharingDenominator();
        require(profitSharingNumerator < profitSharingDenominator, "invalid profit share");
    }

    event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

    function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
        if (_rewardBalance > 0) {
            uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator).div(profitSharingDenominator);
            emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
            IERC20(rewardToken).safeApprove(controller(), 0);
            IERC20(rewardToken).safeApprove(controller(), feeAmount);

            IController(controller()).notifyFee(
                rewardToken,
                feeAmount
            );
        } else {
            emit ProfitLogInReward(0, 0, block.timestamp);
        }
    }

}

// File: contracts/hardworkInterface/IVault.sol

pragma solidity 0.5.16;

interface IVault {

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;

    function rebalance() external;
}

// File: contracts/strategies/compound/CompoundNoFoldStrategy.sol

pragma solidity 0.5.16;


contract CompoundNoFoldStrategy is IStrategy, RewardTokenProfitNotifier, CompoundInteractor {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ProfitNotClaimed();
    event TooLowBalance();

    ERC20Detailed public underlying;
    CompleteCToken public ctoken;
    ComptrollerInterface public comptroller;

    address public vault;
    ERC20Detailed public comp; // this will be Cream or Comp

    address public uniswapRouterV2;
    uint256 public suppliedInUnderlying;
    bool public liquidationAllowed = true;
    uint256 public sellFloor = 0;
    bool public allowEmergencyLiquidityShortage = false;

    // These tokens cannot be claimed by the controller
    mapping(address => bool) public unsalvagableTokens;

    modifier restricted() {
        require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
            "The sender has to be the controller or vault");
        _;
    }

    constructor(
        address _storage,
        address _underlying,
        address _ctoken,
        address _vault,
        address _comptroller,
        address _comp,
        address _uniswap
    )
    RewardTokenProfitNotifier(_storage, _comp)
    CompoundInteractor(_underlying, _ctoken, _comptroller) public {
        require(IVault(_vault).underlying() == _underlying, "vault does not support underlying");
        comptroller = ComptrollerInterface(_comptroller);
        comp = ERC20Detailed(_comp);
        underlying = ERC20Detailed(_underlying);
        ctoken = CompleteCToken(_ctoken);
        vault = _vault;
        uniswapRouterV2 = _uniswap;

        // set these tokens to be not salvagable
        unsalvagableTokens[_underlying] = true;
        unsalvagableTokens[_ctoken] = true;
        unsalvagableTokens[_comp] = true;
    }

    modifier updateSupplyInTheEnd() {
        _;
        suppliedInUnderlying = ctoken.balanceOfUnderlying(address(this));
    }

    function depositArbCheck() public view returns (bool) {
        // there's no arb here.
        return true;
    }

    /**
    * The strategy invests by supplying the underlying as a collateral.
    */
    function investAllUnderlying() public restricted updateSupplyInTheEnd {
        uint256 balance = underlying.balanceOf(address(this));
        _supply(balance);
    }

    /**
    * Exits Compound and transfers everything to the vault.
    */
    function withdrawAllToVault() external restricted updateSupplyInTheEnd {
        if (allowEmergencyLiquidityShortage) {
            withdrawMaximum();
        } else {
            withdrawAllWeInvested();
        }
        IERC20(address(underlying)).safeTransfer(vault, underlying.balanceOf(address(this)));
    }

    function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
        withdrawMaximum();
    }

    function withdrawMaximum() internal updateSupplyInTheEnd {
        if (liquidationAllowed) {
            claimComp();
            liquidateComp();
        } else {
            emit ProfitNotClaimed();
        }
        redeemMaximum();
    }

    function withdrawAllWeInvested() internal updateSupplyInTheEnd {
        if (liquidationAllowed) {
            claimComp();
            liquidateComp();
        } else {
            emit ProfitNotClaimed();
        }
        uint256 currentBalance = ctoken.balanceOfUnderlying(address(this));
        mustRedeemPartial(currentBalance);
    }

    function withdrawToVault(uint256 amountUnderlying) external restricted updateSupplyInTheEnd {
        if (amountUnderlying <= underlying.balanceOf(address(this))) {
            IERC20(address(underlying)).safeTransfer(vault, amountUnderlying);
            return;
        }

        // get some of the underlying
        mustRedeemPartial(amountUnderlying);

        // transfer the amount requested (or the amount we have) back to vault
        IERC20(address(underlying)).safeTransfer(vault, amountUnderlying);

        // invest back to cream
        investAllUnderlying();
    }

    /**
    * Withdraws all assets, liquidates COMP/CREAM, and invests again in the required ratio.
    */
    function doHardWork() public restricted {
        if (liquidationAllowed) {
            claimComp();
            liquidateComp();
        } else {
            emit ProfitNotClaimed();
        }
        investAllUnderlying();
    }

    /**
    * Redeems maximum that can be redeemed from Compound.
    * Redeem the minimum of the underlying we own, and the underlying that the cToken can
    * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently.
    *
    * DOES NOT ensure that the strategy cUnderlying balance becomes 0.
    */
    function redeemMaximum() internal {
        redeemMaximumToken();
    }

    /**
    * Redeems `amountUnderlying` or fails.
    */
    function mustRedeemPartial(uint256 amountUnderlying) internal {
        require(
            ctoken.getCash() >= amountUnderlying,
            "market cash cannot cover liquidity"
        );
        _redeemUnderlying(amountUnderlying);
    }

    /**
    * Salvages a token.
    */
    function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens[token], "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }

    function liquidateComp() internal {
        uint256 balance = comp.balanceOf(address(this));
        if (balance < sellFloor) {
            emit TooLowBalance();
            return;
        }

        // give a profit share to fee forwarder, which re-distributes this to
        // the profit sharing pools
        notifyProfitInRewardToken(balance);

        balance = comp.balanceOf(address(this));
        // we can accept 1 as minimum as this will be called by trusted roles only
        uint256 amountOutMin = 1;
        IERC20(address(comp)).safeApprove(address(uniswapRouterV2), 0);
        IERC20(address(comp)).safeApprove(address(uniswapRouterV2), balance);
        address[] memory path = new address[](3);
        path[0] = address(comp);
        path[1] = IUniswapV2Router02(uniswapRouterV2).WETH();
        path[2] = address(underlying);
        IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
            balance,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
    * Returns the current balance. Ignores COMP/CREAM that was not liquidated and invested.
    */
    function investedUnderlyingBalance() public view returns (uint256) {
        // underlying in this strategy + underlying redeemable from Compound/Cream
        return underlying.balanceOf(address(this)).add(suppliedInUnderlying);
    }

    /**
    * Allows liquidation
    */
    function setLiquidationAllowed(
        bool allowed
    ) external restricted {
        liquidationAllowed = allowed;
    }

    function setAllowLiquidityShortage(
        bool allowed
    ) external restricted {
        allowEmergencyLiquidityShortage = allowed;
    }

    function setSellFloor(uint256 value) external restricted {
        sellFloor = value;
    }
}

// File: contracts/strategies/compound/CompoundNoFoldStrategyUSDTMainnet.sol

pragma solidity 0.5.16;


contract CompoundNoFoldStrategyUSDTTestnet is CompoundNoFoldStrategy {

    // token addresses
    address constant public __underlying = address(0x87c74f9a8af61e2Ef33049E299dF919a17792115);
    address constant public __ctoken = address(0xfe7Dd879f9530a4F7aEf21829dBa7aD46259DF36);
    address constant public __comptroller = address(0x40824D002f62E6e7b6987ec98280834cA8fd037A);
    address constant public __comp = address(0x5d4046DBDAfdbB5B34861a266186e31d5F8B4920);
    address constant public __uniswap = address(0x5A5b39f6DA71F4C352c0525A8D9D32d49b294604);

    constructor(
        address _storage,
        address _vault
    )
    CompoundNoFoldStrategy(
        _storage,
        __underlying,
        __ctoken,
        _vault,
        __comptroller,
        __comp,
        __uniswap
    )
    public {
    }
    function changeVault(address _vault) public onlyGovernance {
        vault = _vault;
    }

}

