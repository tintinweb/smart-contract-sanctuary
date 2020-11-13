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

// File: contracts/IAUSC.sol

pragma solidity 0.5.16;

interface IAUSC {
  function rebase(uint256 epoch, uint256 supplyDelta, bool positive) external;
  function mint(address to, uint256 amount) external;
}

// File: contracts/IPoolEscrow.sol

pragma solidity 0.5.16;

interface IPoolEscrow {
  function notifySecondaryTokens(uint256 number) external;
}

// File: contracts/BasicRebaser.sol

pragma solidity 0.5.16;






contract BasicRebaser {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Updated(uint256 xau, uint256 ausc);
  event NoUpdateXAU();
  event NoUpdateAUSC();
  event NoSecondaryMint();
  event NoRebaseNeeded();

  uint256 public constant BASE = 1e18;
  uint256 public constant WINDOW_SIZE = 12;

  address public ausc;
  uint256[] public pricesXAU = new uint256[](12);
  uint256[] public pricesAUSC = new uint256[](12);
  uint256 public pendingXAUPrice = 0;
  uint256 public pendingAUSCPrice = 0;
  bool public noPending = true;
  uint256 public averageXAU;
  uint256 public averageAUSC;
  uint256 public lastUpdate;
  uint256 public frequency = 1 hours;
  uint256 public counter = 0;
  uint256 public epoch = 1;
  address public secondaryPool;
  address public governance;

  uint256 public nextRebase = 0;
  uint256 public constant REBASE_DELAY = 12 hours;

  modifier onlyGov() {
    require(msg.sender == governance, "only gov");
    _;
  }

  constructor (address token, address _secondaryPool) public {
    ausc = token;
    secondaryPool = _secondaryPool;
    governance = msg.sender;
  }

  function setNextRebase(uint256 next) external onlyGov {
    require(nextRebase == 0, "Only one time activation");
    nextRebase = next;
  }

  function setGovernance(address account) external onlyGov {
    governance = account;
  }

  function setSecondaryPool(address pool) external onlyGov {
    secondaryPool = pool;
  }

  function checkRebase() external {
    // ausc ensures that we do not have smart contracts rebasing
    require (msg.sender == address(ausc), "only through ausc");
    rebase();
    recordPrice();
  }

  function recordPrice() public {
    if (msg.sender != tx.origin && msg.sender != address(ausc)) {
      // smart contracts could manipulate data via flashloans,
      // thus we forbid them from updating the price
      return;
    }

    if (block.timestamp < lastUpdate + frequency) {
      // addition is running on timestamps, this will never overflow
      // we leave at least the specified period between two updates
      return;
    }

    (bool successXAU, uint256 priceXAU) = getPriceXAU();
    (bool successAUSC, uint256 priceAUSC) = getPriceAUSC();
    if (!successAUSC) {
      // price of AUSC was not returned properly
      emit NoUpdateAUSC();
      return;
    }
    if (!successXAU) {
      // price of XAU was not returned properly
      emit NoUpdateXAU();
      return;
    }
    lastUpdate = block.timestamp;

    if (noPending) {
      // we start recording with 1 hour delay
      pendingXAUPrice = priceXAU;
      pendingAUSCPrice = priceAUSC;
      noPending = false;
    } else if (counter < WINDOW_SIZE) {
      // still in the warming up phase
      averageXAU = averageXAU.mul(counter).add(pendingXAUPrice).div(counter.add(1));
      averageAUSC = averageAUSC.mul(counter).add(pendingAUSCPrice).div(counter.add(1));
      pricesXAU[counter] = pendingXAUPrice;
      pricesAUSC[counter] = pendingAUSCPrice;
      pendingXAUPrice = priceXAU;
      pendingAUSCPrice = priceAUSC;
      counter++;
    } else {
      uint256 index = counter % WINDOW_SIZE;
      averageXAU = averageXAU.mul(WINDOW_SIZE).sub(pricesXAU[index]).add(pendingXAUPrice).div(WINDOW_SIZE);
      averageAUSC = averageAUSC.mul(WINDOW_SIZE).sub(pricesAUSC[index]).add(pendingAUSCPrice).div(WINDOW_SIZE);
      pricesXAU[index] = pendingXAUPrice;
      pricesAUSC[index] = pendingAUSCPrice;
      pendingXAUPrice = priceXAU;
      pendingAUSCPrice = priceAUSC;
      counter++;
    }
    emit Updated(pendingXAUPrice, pendingAUSCPrice);
  }

  function rebase() public {
    // We want to rebase only at 1pm UTC and 12 hours later
    if (block.timestamp < nextRebase) {
      return;
    } else {
      nextRebase = nextRebase + REBASE_DELAY;
    }

    // only rebase if there is a 5% difference between the price of XAU and AUSC
    uint256 highThreshold = averageXAU.mul(105).div(100);
    uint256 lowThreshold = averageXAU.mul(95).div(100);

    if (averageAUSC > highThreshold) {
      // AUSC is too expensive, this is a positive rebase increasing the supply
      uint256 currentSupply = IERC20(ausc).totalSupply();
      uint256 desiredSupply = currentSupply.mul(averageAUSC).div(averageXAU);
      uint256 secondaryPoolBudget = desiredSupply.sub(currentSupply).mul(10).div(100);
      desiredSupply = desiredSupply.sub(secondaryPoolBudget);

      // Cannot underflow as desiredSupply > currentSupply, the result is positive
      // delta = (desiredSupply / currentSupply) * 100 - 100
      uint256 delta = desiredSupply.mul(BASE).div(currentSupply).sub(BASE);
      IAUSC(ausc).rebase(epoch, delta, true);

      if (secondaryPool != address(0)) {
        // notify the pool escrow that tokens are available
        IAUSC(ausc).mint(address(this), secondaryPoolBudget);
        IERC20(ausc).safeApprove(secondaryPool, 0);
        IERC20(ausc).safeApprove(secondaryPool, secondaryPoolBudget);
        IPoolEscrow(secondaryPool).notifySecondaryTokens(secondaryPoolBudget);
      } else {
        emit NoSecondaryMint();
      }
      epoch++;
    } else if (averageAUSC < lowThreshold) {
      // AUSC is too cheap, this is a negative rebase decreasing the supply
      uint256 currentSupply = IERC20(ausc).totalSupply();
      uint256 desiredSupply = currentSupply.mul(averageAUSC).div(averageXAU);

      // Cannot overflow as desiredSupply > currentSupply
      // delta = 100 - (desiredSupply / currentSupply) * 100
      uint256 delta = uint256(BASE).sub(desiredSupply.mul(BASE).div(currentSupply));
      IAUSC(ausc).rebase(epoch, delta, false);
      epoch++;
    } else {
      // else the price is within bounds
      emit NoRebaseNeeded();
    }
  }

  /**
  * Calculates how a rebase would look if it was triggered now.
  */
  function calculateRealTimeRebase() public view returns (uint256, uint256) {
    // only rebase if there is a 5% difference between the price of XAU and AUSC
    uint256 highThreshold = averageXAU.mul(105).div(100);
    uint256 lowThreshold = averageXAU.mul(95).div(100);

    if (averageAUSC > highThreshold) {
      // AUSC is too expensive, this is a positive rebase increasing the supply
      uint256 currentSupply = IERC20(ausc).totalSupply();
      uint256 desiredSupply = currentSupply.mul(averageAUSC).div(averageXAU);
      uint256 secondaryPoolBudget = desiredSupply.sub(currentSupply).mul(10).div(100);
      desiredSupply = desiredSupply.sub(secondaryPoolBudget);

      // Cannot underflow as desiredSupply > currentSupply, the result is positive
      // delta = (desiredSupply / currentSupply) * 100 - 100
      uint256 delta = desiredSupply.mul(BASE).div(currentSupply).sub(BASE);
      return (delta, secondaryPool == address(0) ? 0 : secondaryPoolBudget);
    } else if (averageAUSC < lowThreshold) {
      // AUSC is too cheap, this is a negative rebase decreasing the supply
      uint256 currentSupply = IERC20(ausc).totalSupply();
      uint256 desiredSupply = currentSupply.mul(averageAUSC).div(averageXAU);

      // Cannot overflow as desiredSupply > currentSupply
      // delta = 100 - (desiredSupply / currentSupply) * 100
      uint256 delta = uint256(BASE).sub(desiredSupply.mul(BASE).div(currentSupply));
      return (delta, 0);
    } else {
      return (0,0);
    }
  }

  function getPriceXAU() public view returns (bool, uint256);
  function getPriceAUSC() public view returns (bool, uint256);
}

// File: @chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.5.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/ChainlinkOracle.sol

pragma solidity 0.5.16;



contract ChainlinkOracle {

  using SafeMath for uint256;

  address public constant oracle = 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;
  uint256 public constant ozToMg = 311035000;
  uint256 public constant ozToMgPrecision = 1e4;

  constructor () public {
  }

  function getPriceXAU() public view returns (bool, uint256) {
    // answer has 8 decimals, it is the price of 1 oz of gold in USD
    // if the round is not completed, updated at is 0
    (,int256 answer,,uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();
    // add 10 decimals at the end
    return (updatedAt != 0, uint256(answer).mul(10).mul(ozToMgPrecision).div(ozToMg).mul(1e10));
  }
}

// File: contracts/UniswapOracle.sol

pragma solidity 0.5.16;




contract IUniswapRouterV2 {
  function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256[] memory amounts);
}

contract UniswapOracle {

  using SafeMath for uint256;

  address public constant oracle = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public ausc;
  address[] public path;

  constructor (address token) public {
    ausc = token;
    path = [ausc, weth, usdc];
  }

  function getPriceAUSC() public view returns (bool, uint256) {
    // returns the price with 6 decimals, but we want 18
    uint256[] memory amounts = IUniswapRouterV2(oracle).getAmountsOut(1e18, path);
    return (ausc != address(0), amounts[2].mul(1e12));
  }
}

// File: contracts/Rebaser.sol

pragma solidity 0.5.16;




contract Rebaser is BasicRebaser, UniswapOracle, ChainlinkOracle {

  constructor (address token, address _treasury)
  BasicRebaser(token, _treasury)
  UniswapOracle(token) public {
  }

}