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

// File: contracts/StrategySwerveUSD.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;




/*
 A strategy must implement the following calls;

 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 - riskAnalysis()

 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
*/

interface SSUSDController {
  function vaults(address) external view returns (address);
  function rewards() external view returns (address);
}

interface SSUSDGauge {
  function deposit(uint) external;
  function balanceOf(address) external view returns (uint);
  function withdraw(uint) external;
}

interface SSUSDMintr {
  function mint(address) external;
}

interface SSUSDUniswapRouter {
  function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

interface ISwerveFi {
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
    int128 from,
    int128 to,
    uint256 _from_amount,
    uint256 _min_to_amount
  ) external;
  function calc_token_amount(
    uint256[4] calldata amounts,
    bool deposit
  ) external view returns(uint);
  function calc_withdraw_one_coin(
    uint256 _token_amount,
    int128 i) external view returns (uint256);
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount) external;
}

contract StrategySwerveUSD {
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  enum TokenIndex {
    DAI,
    USDC,
    USDT,
    TUSD
  }

  mapping(uint256 => address) public tokenIndexAddress;
  address public want;
  // the matching enum record used to determine the index
  TokenIndex tokenIndex;
  address constant public swusd = address(0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059); // (swerve combo Swerve.fi DAI/USDC/USDT/TUSD (swUSD))
  address constant public curve = address(0xa746c67eB7915Fa832a4C2076D403D4B68085431);
  address constant public gauge = address(0xb4d0C929cD3A1FbDc6d57E7D3315cF0C4d6B4bFa);
  address constant public mintr = address(0x2c988c3974AD7E604E276AE0294a7228DEf67974);
  address constant public swrv = address(0xB8BAa0e4287890a5F79863aB62b7F175ceCbD433);
  address constant public uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // used for swrv <> weth <> want route
  // liquidation path to be used
  address[] public uniswap_swrv2want;

  uint public performanceFee = 1000;
  uint constant public performanceMax = 10000;

  uint public arbMin = 995000;
  uint public arbMax = 1010000;

  address public governance;
  address public controller;

  constructor(uint256 _tokenIndex, address _controller) public {
    tokenIndexAddress[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    tokenIndexAddress[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    tokenIndexAddress[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    tokenIndexAddress[3] = address(0x0000000000085d4780B73119b644AE5ecd22b376);
    tokenIndex = TokenIndex(_tokenIndex);
    want = tokenIndexAddress[_tokenIndex];
    uniswap_swrv2want = [swrv, weth, want];
    governance = tx.origin;
    controller = _controller;
  }

  function getName() external pure returns (string memory) {
    return "StrategySwerveUSD";
  }

  function setPerformanceFee(uint _performanceFee) external {
    require(msg.sender == governance, "!governance");
    performanceFee = _performanceFee;
  }

  function setArbMin(uint _arbMin) external {
    require(msg.sender == governance, "!governance");
    arbMin = _arbMin;
  }

  function setArbMax(uint _arbMax) external {
    require(msg.sender == governance, "!governance");
    arbMax = _arbMax;
  }

  function wrapCoinAmount(uint256 amount) internal view returns (uint256[4] memory) {
    uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
    amounts[uint56(tokenIndex)] = amount;
    return amounts;
  }

  function swusdFromWant() internal {
    uint256 wantBalance = IERC20(want).balanceOf(address(this));
    if (wantBalance > 0) {
      IERC20(want).safeApprove(curve, 0);
      IERC20(want).safeApprove(curve, wantBalance);
      // we can accept 0 as minimum because this is called only by a trusted role
      uint256 minimum = 0;
      uint256[4] memory coinAmounts = wrapCoinAmount(wantBalance);
      ISwerveFi(curve).add_liquidity(coinAmounts, minimum);
    }
    // now we have the swusd token
  }

  function deposit() public {
    require(riskAnalysis(), 'risk!');

    // convert the entire balance not yet invested into swusd first
    swusdFromWant();

    // then deposit into the swusd vault
    uint256 swusdBalance = IERC20(swusd).balanceOf(address(this));
    if (swusdBalance > 0) {
      IERC20(swusd).safeApprove(gauge, 0);
      IERC20(swusd).safeApprove(gauge, swusdBalance);
      SSUSDGauge(gauge).deposit(swusdBalance);
    }
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset) external returns (uint balance) {
    require(msg.sender == controller, "!controller");
    require(want != address(_asset), "want");
    require(swusd != address(_asset), "swusd");
    require(swrv != address(_asset), "swrv");
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  function wantValueFromSWUSD(uint256 swusdBalance) public view returns (uint256) {
    return ISwerveFi(curve).calc_withdraw_one_coin(swusdBalance, int128(tokenIndex));
  }

  function swusdToWant(uint256 wantLimit) internal {
    uint256 swusdBalance = IERC20(swusd).balanceOf(address(this));

    // this is the maximum number of want we can get for our swusd token
    uint256 wantMaximumAmount = wantValueFromSWUSD(swusdBalance);
    if (wantMaximumAmount == 0) {
      return;
    }

    if (wantLimit < wantMaximumAmount) {
      // we want less than what we can get, we ask for the exact amount
      // now we can remove the liquidity
      uint256[4] memory tokenAmounts = wrapCoinAmount(wantLimit);
      IERC20(swusd).safeApprove(curve, 0);
      IERC20(swusd).safeApprove(curve, swusdBalance);
      ISwerveFi(curve).remove_liquidity_imbalance(tokenAmounts, swusdBalance);
    } else {
      // we want more than we can get, so we withdraw everything
      IERC20(swusd).safeApprove(curve, 0);
      IERC20(swusd).safeApprove(curve, swusdBalance);
      ISwerveFi(curve).remove_liquidity_one_coin(swusdBalance, int128(tokenIndex), 0);
    }
    // now we have want asset
  }

  // Withdraw partial funds, normally used with a vault withdrawal
  function withdraw(uint _amount) external {
    require(msg.sender == controller, "!controller");
    uint _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }

    address _vault = SSUSDController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    IERC20(want).safeTransfer(_vault, _amount);

    // invest back the rest
    deposit();
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external returns (uint balance) {
    require(msg.sender == controller, "!controller");
    _withdrawAll();

    // we can transfer the asset to the vault
    balance = IERC20(want).balanceOf(address(this));

    if (balance > 0) {
      address _vault = SSUSDController(controller).vaults(address(want));
      require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
      IERC20(want).safeTransfer(_vault, balance);
    }
  }

  function _withdrawAll() internal {
    // withdraw all from gauge
    uint _balance = SSUSDGauge(gauge).balanceOf(address(this));
    if (_balance > 0) {
      SSUSDGauge(gauge).withdraw(_balance);
    }
    // convert the swusd to want, we want the entire balance
    swusdToWant(uint256(~0));
  }

  function harvest() public {
    require(msg.sender == governance, "!authorized");
    SSUSDMintr(mintr).mint(gauge);
    uint _before = IERC20(want).balanceOf(address(this));
    // claiming rewards and liquidating them
    uint256 swrvBalance = IERC20(swrv).balanceOf(address(this));
    if (swrvBalance > 0) {
      IERC20(swrv).safeApprove(uni, 0);
      IERC20(swrv).safeApprove(uni, swrvBalance);
      SSUSDUniswapRouter(uni).swapExactTokensForTokens(swrvBalance, uint(0), uniswap_swrv2want, address(this), now.add(1800));
    }
    uint _after = IERC20(want).balanceOf(address(this));
    if (_after > _before) {
      uint profit = _after.sub(_before);
      uint _fee = profit.mul(performanceFee).div(performanceMax);
      IERC20(want).safeTransfer(SSUSDController(controller).rewards(), _fee);
      deposit();
    }
  }

  function _withdrawSome(uint256 _amount) internal returns (uint) {
    uint _before = IERC20(want).balanceOf(address(this));
    // withdraw all from gauge
    SSUSDGauge(gauge).withdraw(SSUSDGauge(gauge).balanceOf(address(this)));
    // convert the swusd to want, but get at most _amount
    swusdToWant(_amount);
    uint _after = IERC20(want).balanceOf(address(this));
    return _after.sub(_before);
  }

  function balanceOfWant() public view returns (uint) {
    return IERC20(want).balanceOf(address(this));
  }

  function balanceOfPool() public view returns (uint) {
    uint256 swusdBalance = SSUSDGauge(gauge).balanceOf(address(this));
    return ISwerveFi(curve).calc_withdraw_one_coin(swusdBalance, int128(tokenIndex));
  }

  function balanceOf() public view returns (uint) {
    return balanceOfWant().add(balanceOfPool());
  }

  function riskAnalysis() public view returns (bool) {
    uint256 price = ISwerveFi(curve).calc_withdraw_one_coin(10 ** 18, int128(tokenIndex));
    return (price >= arbMin) && (price <= arbMax);
  }

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setController(address _controller) external {
    require(msg.sender == governance, "!governance");
    controller = _controller;
  }
}