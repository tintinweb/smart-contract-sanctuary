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
        assembly { codehash := extcodehash(account) }
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
        (bool success, ) = recipient.call.value(amount)("");
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

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// File: contracts/strategies/curve/interfaces/Gauge.sol

pragma solidity 0.5.16;

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
    function user_checkpoint(address) external;
}

interface VotingEscrow {
    function create_lock(uint256 v, uint256 time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
}

interface Mintr {
    function mint(address) external;
}

// File: contracts/strategies/curve/interfaces/ICurveFi.sol

pragma solidity 0.5.16;

interface ICurveFi {
  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
  function calc_token_amount(
    uint256[4] calldata amounts,
    bool deposit
  ) external view returns(uint);
}

// File: contracts/strategies/curve/interfaces/yVault.sol

pragma solidity 0.5.16;

interface yERC20 {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
  function getPricePerFullShare() external view returns (uint256);
}

// File: contracts/strategies/curve/interfaces/IPriceConvertor.sol

pragma solidity 0.5.16;

interface IPriceConvertor {
  function yCrvToUnderlying(uint256 _token_amount, uint256 i) external view returns (uint256);
}

// File: contracts/hardworkInterface/IVault.sol

pragma solidity 0.5.16;


interface IVault {
    // the IERC20 part is the share

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

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
    function greyList(address _target) external returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault) external;
    function hasVault(address _vault) external returns(bool);

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}

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
    function depositArbCheck() external view returns(bool);
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

// File: contracts/strategies/curve/CRVStrategyStable.sol

pragma solidity 0.5.16;















/**
* The goal of this strategy is to take a stable asset (DAI, USDC, USDT), turn it into ycrv using
* the curve mechanisms, and supply ycrv into the ycrv vault. The ycrv vault will likely not have
* a reward token distribution pool to avoid double dipping. All the calls to functions from this
* strategy will be routed to the controller which should then call the respective methods on the
* ycrv vault. This strategy will not be liquidating any yield crops (CRV), because the strategy
* of the ycrv vault will do that for us.
*/
contract CRVStrategyStable is IStrategy, Controllable {

  enum TokenIndex {DAI, USDC, USDT}

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  // underlying asset
  address public underlying;

  // the matching enum record used to determine the index
  TokenIndex tokenIndex;

  // our vault holding the underlying asset
  address public vault;

  // the y-vault (yield tokens from Curve) corresponding to our asset
  address public yVault;

  // our vault for depositing the yCRV tokens
  address public ycrvVault;

  // the address of yCRV token
  address public ycrv;

  // the address of the Curve protocol
  address public curve;

  // the address of the IPriceConvertor
  address public convertor;

  // these tokens cannot be claimed by the governance
  mapping(address => bool) public unsalvagableTokens;

  uint256 public curvePriceCheckpoint;
  uint256 public ycrvUnit;
  uint256 public arbTolerance = 3;

  modifier restricted() {
    require(msg.sender == vault || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  constructor(
    address _storage,
    address _underlying,
    address _vault,
    address _ycrvVault,
    address _yVault,
    uint256 _tokenIndex,
    address _ycrv,
    address _curveProtocol,
    address _convertor
  )
  Controllable(_storage) public {
    vault = _vault;
    ycrvVault = _ycrvVault;
    underlying = _underlying;
    tokenIndex = TokenIndex(_tokenIndex);
    yVault = _yVault;
    ycrv = _ycrv;
    curve = _curveProtocol;
    convertor = _convertor;

    // set these tokens to be not salvageable
    unsalvagableTokens[underlying] = true;
    unsalvagableTokens[yVault] = true;
    unsalvagableTokens[ycrv] = true;
    unsalvagableTokens[ycrvVault] = true;

    ycrvUnit = 10 ** 18;
    // starting with a stable price, the mainnet will override this value
    curvePriceCheckpoint = ycrvUnit;
  }

  function depositArbCheck() public view returns(bool) {
    uint256 currentPrice = underlyingValueFromYCrv(ycrvUnit);
    if (currentPrice > curvePriceCheckpoint) {
      return currentPrice.mul(100).div(curvePriceCheckpoint) > 100 - arbTolerance;
    } else {
      return curvePriceCheckpoint.mul(100).div(currentPrice) > 100 - arbTolerance;
    }
  }

  function setArbTolerance(uint256 tolerance) external onlyGovernance {
    require(tolerance <= 100, "at most 100");
    arbTolerance = tolerance;
  }

  /**
  * Uses the Curve protocol to convert the underlying asset into yAsset and then to yCRV.
  */
  function yCurveFromUnderlying() internal {
    // convert underlying asset to yAsset
    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeApprove(yVault, 0);
      IERC20(underlying).safeApprove(yVault, underlyingBalance);
      yERC20(yVault).deposit(underlyingBalance);
    }
    // convert yAsset to yCRV
    uint256 yBalance = IERC20(yVault).balanceOf(address(this));
    if (yBalance > 0) {
      IERC20(yVault).safeApprove(curve, 0);
      IERC20(yVault).safeApprove(curve, yBalance);
      // we can accept 0 as minimum because this is called only by a trusted role
      uint256 minimum = 0;
      uint256[4] memory coinAmounts = wrapCoinAmount(yBalance);
      ICurveFi(curve).add_liquidity(
        coinAmounts, minimum
      );
    }
    // now we have yCRV
  }

  /**
  * Uses the Curve protocol to convert the yCRV back into the underlying asset. If it cannot acquire
  * the limit amount, it will acquire the maximum it can.
  */
  function yCurveToUnderlying(uint256 underlyingLimit) internal {
    uint256 ycrvBalance = IERC20(ycrv).balanceOf(address(this));

    // this is the maximum number of y-tokens we can get for our yCRV
    uint256 yTokenMaximumAmount = yTokenValueFromYCrv(ycrvBalance);
    if (yTokenMaximumAmount == 0) {
      return;
    }

    // ensure that we will not overflow in the conversion
    uint256 yTokenDesiredAmount = underlyingLimit == uint256(~0) ?
      yTokenMaximumAmount : yTokenValueFromUnderlying(underlyingLimit);

    uint256[4] memory yTokenAmounts = wrapCoinAmount(
      Math.min(yTokenMaximumAmount, yTokenDesiredAmount));
    uint256 yUnderlyingBalanceBefore = IERC20(yVault).balanceOf(address(this));
    IERC20(ycrv).safeApprove(curve, 0);
    IERC20(ycrv).safeApprove(curve, ycrvBalance);
    ICurveFi(curve).remove_liquidity_imbalance(
      yTokenAmounts, ycrvBalance
    );
    // now we have yUnderlying asset
    uint256 yUnderlyingBalanceAfter = IERC20(yVault).balanceOf(address(this));
    if (yUnderlyingBalanceAfter > yUnderlyingBalanceBefore) {
      // we received new yUnderlying tokens for yCRV
      yERC20(yVault).withdraw(yUnderlyingBalanceAfter.sub(yUnderlyingBalanceBefore));
    }
  }

  /**
  * Withdraws an underlying asset from the strategy to the vault in the specified amount by asking
  * the yCRV vault for yCRV (currently all of it), and then removing imbalanced liquidity from
  * the Curve protocol. The rest is deposited back to the yCRV vault. If the amount requested cannot
  * be obtained, the method will get as much as we have.
  */
  function withdrawToVault(uint256 amountUnderlying) external restricted {
    // If we want to be more accurate, we need to calculate how much yCRV we will need here
    uint256 shares = IERC20(ycrvVault).balanceOf(address(this));
    IVault(ycrvVault).withdraw(shares);
    yCurveToUnderlying(amountUnderlying);
    // we can transfer the asset to the vault
    uint256 actualBalance = IERC20(underlying).balanceOf(address(this));
    if (actualBalance > 0) {
      IERC20(underlying).safeTransfer(vault, Math.min(amountUnderlying, actualBalance));
    }

    // invest back the rest
    investAllUnderlying();
  }

  /**
  * Withdraws all assets from the vault. We ask the yCRV vault to give us our entire yCRV balance
  * and then convert it to the underlying asset using the Curve protocol.
  */
  function withdrawAllToVault() external restricted {
    uint256 shares = IERC20(ycrvVault).balanceOf(address(this));
    IVault(ycrvVault).withdraw(shares);
    // withdraw everything until there is only dust left
    yCurveToUnderlying(uint256(~0));
    uint256 actualBalance = IERC20(underlying).balanceOf(address(this));
    if (actualBalance > 0) {
      IERC20(underlying).safeTransfer(vault, actualBalance);
    }
  }

  /**
  * Invests all underlying assets into our yCRV vault.
  */
  function investAllUnderlying() internal {
    // convert the entire balance not yet invested into yCRV first
    yCurveFromUnderlying();

    // then deposit into the yCRV vault
    uint256 ycrvBalance = IERC20(ycrv).balanceOf(address(this));
    if (ycrvBalance > 0) {
      IERC20(ycrv).safeApprove(ycrvVault, 0);
      IERC20(ycrv).safeApprove(ycrvVault, ycrvBalance);
      // deposits the entire balance and also asks the vault to invest it (public function)
      IVault(ycrvVault).deposit(ycrvBalance);
    }
  }

  /**
  * The hard work only invests all underlying assets, and then tells the controller to call hard
  * work on the yCRV vault.
  */
  function doHardWork() public restricted {
    investAllUnderlying();
    curvePriceCheckpoint = underlyingValueFromYCrv(ycrvUnit);
  }

  /**
  * Salvages a token. We cannot salvage the shares in the yCRV pool, yCRV tokens, or underlying
  * assets.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvageable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /**
  * Returns the underlying invested balance. This is the amount of yCRV that we are entitled to
  * from the yCRV vault (based on the number of shares we currently have), converted to the
  * underlying assets by the Curve protocol, plus the current balance of the underlying assets.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    uint256 shares = IERC20(ycrvVault).balanceOf(address(this));
    uint256 price = IVault(ycrvVault).getPricePerFullShare();
    // the price is in yCRV units, because this is a yCRV vault
    // the multiplication doubles the number of decimals for shares, so we need to divide
    // the precision is always 10 ** 18 as the yCRV vault has 18 decimals
    uint256 precision = 10 ** 18;
    uint256 ycrvBalance = shares.mul(price).div(precision);
    // now we can convert the balance to the token amount
    uint256 ycrvValue = underlyingValueFromYCrv(ycrvBalance);
    return ycrvValue.add(IERC20(underlying).balanceOf(address(this)));
  }

  /**
  * Returns the value of yCRV in underlying token accounting for slippage and fees.
  */
  function yTokenValueFromYCrv(uint256 ycrvBalance) public view returns (uint256) {
    return underlyingValueFromYCrv(ycrvBalance) // this is in DAI, we will convert to yDAI
    .mul(10 ** 18)
    .div(yERC20(yVault).getPricePerFullShare()); // function getPricePerFullShare() has 18 decimals for all tokens
  }

  /**
  * Returns the value of yCRV in y-token (e.g., yCRV -> yDai) accounting for slippage and fees.
  */
  function underlyingValueFromYCrv(uint256 ycrvBalance) public view returns (uint256) {
    return IPriceConvertor(convertor).yCrvToUnderlying(ycrvBalance, uint256(tokenIndex));
  }

  /**
  * Returns the value of the underlying token in yToken
  */
  function yTokenValueFromUnderlying(uint256 amountUnderlying) public view returns (uint256) {
    // 1 yToken = this much underlying, 10 ** 18 precision for all tokens
    return amountUnderlying
      .mul(10 ** 18)
      .div(yERC20(yVault).getPricePerFullShare());
  }

  /**
  * Wraps the coin amount in the array for interacting with the Curve protocol
  */
  function wrapCoinAmount(uint256 amount) internal view returns (uint256[4] memory) {
    uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
    amounts[uint56(tokenIndex)] = amount;
    return amounts;
  }

  /**
  * Replaces the price convertor
  */
  function setConvertor(address _convertor) public onlyGovernance {
    // different price conversion from yCurve to yToken can help in emergency recovery situation
    // or if there is a bug discovered in the price computation
    convertor = _convertor;
  }
}

// File: contracts/strategies/curve/PriceConvertor.sol

pragma solidity 0.5.16;


interface IConvertor {
  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

contract PriceConvertor is IPriceConvertor {

  IConvertor public zap = IConvertor(0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3);

  function yCrvToUnderlying(uint256 _token_amount, uint256 i) public view returns (uint256) {
    // this returning the DAI amount, not yDAI
    return zap.calc_withdraw_one_coin(_token_amount, int128(i));
  }
}

contract MockPriceConvertor is IPriceConvertor {
  function yCrvToUnderlying(uint256 _token_amount, uint256 /* i */) public view returns (uint256) {
    // counting 1:1
    return _token_amount;
  }
}

// File: contracts/strategies/curve/CRVStrategyStableMainnet.sol

pragma solidity 0.5.16;



/**
* Adds the mainnet addresses to the CRVStrategyStable
*/
contract CRVStrategyStableMainnet is CRVStrategyStable {

  // token addresses
  // y-addresses are taken from: https://docs.yearn.finance/yearn.finance/yearn-1
  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address constant public ydai = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);
  address constant public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public yusdc = address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e);
  address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address constant public yusdt = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);

  // pre-defined constant mapping: underlying -> y-token
  mapping(address => address) public yVaults;

  // yDAIyUSDCyUSDTyTUSD
  address constant public __ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);

  // protocols
  address constant public __curve = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);

  constructor(
    address _storage,
    address _underlying,
    address _vault,
    address _ycrvVault
  )
  CRVStrategyStable(_storage, _underlying, _vault, _ycrvVault, address(0), 0,
    __ycrv,
    __curve,
    address(0)
  )
  public {
    yVaults[dai] = ydai;
    yVaults[usdc] = yusdc;
    yVaults[usdt] = yusdt;
    yVault = yVaults[underlying];
    require(yVault != address(0), "underlying not supported: yVault is not defined");
    if (_underlying == dai) {
      tokenIndex = TokenIndex.DAI;
    } else if (_underlying == usdc) {
      tokenIndex = TokenIndex.USDC;
    } else if (_underlying == usdt) {
      tokenIndex = TokenIndex.USDT;
    } else {
      revert("What is this asset?");
    }
    convertor = address(new PriceConvertor());
    curvePriceCheckpoint = underlyingValueFromYCrv(ycrvUnit);
  }
}