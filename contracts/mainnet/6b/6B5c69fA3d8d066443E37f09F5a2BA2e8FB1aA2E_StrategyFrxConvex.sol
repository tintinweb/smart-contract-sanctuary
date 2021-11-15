pragma solidity ^0.5.17;

// yarn add @openzeppelin/[email protected]
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

interface IBooster {
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
}

interface IBaseRewardPool {
  function withdrawAndUnwrap(uint256 amount, bool claim)
    external
    returns (bool);

  function withdrawAllAndUnwrap(bool claim) external;

  function getReward(address _account, bool _claimExtras)
    external
    returns (bool);

  function balanceOf(address) external view returns (uint256);
}

interface IController {
  function withdraw(address, uint256) external;

  function balanceOf(address) external view returns (uint256);

  function earn(address, uint256) external;

  function want(address) external view returns (address);

  function rewards() external view returns (address);

  function vaults(address) external view returns (address);

  function strategies(address) external view returns (address);
}

interface IVoterProxy {
  function withdraw(
    address _gauge,
    address _token,
    uint256 _amount
  ) external returns (uint256);

  function balanceOf(address _gauge) external view returns (uint256);

  function withdrawAll(address _gauge, address _token)
    external
    returns (uint256);

  function deposit(address _gauge, address _token) external;

  function harvest(address _gauge, bool _snxRewards) external;

  function lock() external;
}

interface Sushi {
  function swapExactTokensForTokens(
    uint256,
    uint256,
    address[] calldata,
    address,
    uint256
  ) external;

  function getAmountsOut(uint256, address[] calldata)
    external
    returns (uint256[] memory);
}

interface ICurveFi {
  function add_liquidity(uint256[3] calldata, uint256) external;

  function calc_token_amount(uint256[3] calldata, bool)
    external
    returns (uint256);
}

interface IMetapool {
  function add_liquidity(uint256[2] calldata, uint256) external;

  function calc_token_amount(uint256[2] calldata, bool)
    external
    returns (uint256);
}

contract StrategyFrxConvex {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  // Frax3crv
  address public constant want =
    address(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);

  address public constant three_crv =
    address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

  address public constant frx =
    address(0x853d955aCEf822Db058eb8505911ED77F175b99e);

  address public constant fxs =
    address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

  address public constant crv =
    address(0xD533a949740bb3306d119CC777fa900bA034cd52);

  address public constant cvx =
    address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

  address public constant usdc =
    address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  address public constant weth =
    address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  address public constant voter =
    address(0x52f541764E6e90eeBc5c21Ff570De0e2D63766B6);

  address public constant sushiRouter =
    address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

  address public constant uniRouter =
    address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  address public constant metapool =
    address(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);

  address public constant three_pool =
    address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

  uint256 public keepCRV = 10000;
  uint256 public performanceFee = 0;
  uint256 public withdrawalFee = 50;
  uint256 public constant FEE_DENOMINATOR = 10000;

  address public proxy;

  address public governance;
  address public controller;
  address public strategist;

  uint256 public earned; // lifetime strategy earnings denominated in `want` token

  // convex booster
  address public booster;
  address public baseRewardPool;

  event Harvested(uint256 wantEarned, uint256 lifetimeEarned);

  modifier onlyGovernance() {
    require(msg.sender == governance, '!governance');
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller, '!controller');
    _;
  }

  constructor(address _controller, address _proxy) public {
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    proxy = _proxy;
    booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    baseRewardPool = address(0xB900EF131301B307dB5eFcbed9DBb50A3e209B2e);
  }

  function getName() external pure returns (string memory) {
    return 'StrategyFrxConvex';
  }

  function setStrategist(address _strategist) external {
    require(
      msg.sender == governance || msg.sender == strategist,
      '!authorized'
    );
    strategist = _strategist;
  }

  function setKeepCRV(uint256 _keepCRV) external onlyGovernance {
    keepCRV = _keepCRV;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external onlyGovernance {
    withdrawalFee = _withdrawalFee;
  }

  function setPerformanceFee(uint256 _performanceFee) external onlyGovernance {
    performanceFee = _performanceFee;
  }

  function setProxy(address _proxy) external onlyGovernance {
    proxy = _proxy;
  }

  function deposit() public {
    uint256 _want = IERC20(want).balanceOf(address(this));
    IERC20(want).safeApprove(booster, 0);
    IERC20(want).safeApprove(booster, _want);
    IBooster(booster).depositAll(32, true);
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset)
    external
    onlyController
    returns (uint256 balance)
  {
    require(want != address(_asset), 'want');
    require(cvx != address(_asset), 'cvx');
    require(crv != address(_asset), 'crv');
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  // Withdraw partial funds, normally used with a vault withdrawal
  function withdraw(uint256 _amount) external onlyController {
    uint256 _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }

    uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

    IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), '!vault'); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
  }

  function _withdrawSome(uint256 _amount) internal returns (uint256) {
    uint256 wantBefore = IERC20(want).balanceOf(address(this));
    IBaseRewardPool(baseRewardPool).withdrawAndUnwrap(_amount, false);
    uint256 wantAfter = IERC20(want).balanceOf(address(this));
    return wantAfter.sub(wantBefore);
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external onlyController returns (uint256 balance) {
    _withdrawAll();

    balance = IERC20(want).balanceOf(address(this));

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), '!vault'); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function _withdrawAll() internal {
    IBaseRewardPool(baseRewardPool).withdrawAllAndUnwrap(false);
  }

  // slippageCRV = 100 for 1% max slippage
  function harvest(
    uint256 maxSlippageCVX,
    uint256 maxSlippageCRV,
    uint256 maxSlippageFXS,
    uint256 maxSlippageCRVAddLiquidity
  ) public {
    require(
      msg.sender == strategist || msg.sender == governance,
      '!authorized'
    );
    IBaseRewardPool(baseRewardPool).getReward(address(this), true);

    uint256 _crv = IERC20(crv).balanceOf(address(this));
    uint256 _cvx = IERC20(cvx).balanceOf(address(this));
    uint256 _fxs = IERC20(fxs).balanceOf(address(this));

    // sending keepCRV to voter and swap the remaining
    if (_crv > 0) {
      uint256 _keepCRV = _crv.mul(keepCRV).div(FEE_DENOMINATOR);
      IERC20(crv).safeTransfer(voter, _keepCRV);
      _crv = _crv.sub(_keepCRV);

      if (_crv > 0) {
        IERC20(crv).safeApprove(sushiRouter, 0);
        IERC20(crv).safeApprove(sushiRouter, _crv);

        address[] memory path = new address[](3);
        path[0] = crv;
        path[1] = weth;
        path[2] = usdc;

        uint256[] memory _amounts =
          Sushi(sushiRouter).getAmountsOut(_crv, path);
        uint256 _minimalAmount =
          _amounts[2].mul(10000 - maxSlippageCRV).div(10000);

        Sushi(sushiRouter).swapExactTokensForTokens(
          _crv,
          _minimalAmount,
          path,
          address(this),
          now.add(1800)
        );
      }
    }

    // swapping fxs to frx on UniV2
    if (_fxs > 0) {
      IERC20(fxs).safeApprove(uniRouter, 0);
      IERC20(fxs).safeApprove(uniRouter, _fxs);

      address[] memory path = new address[](2);
      path[0] = fxs;
      path[1] = frx;

      uint256[] memory _amounts = Sushi(uniRouter).getAmountsOut(_fxs, path);
      uint256 _minimalAmount =
        _amounts[1].mul(10000 - maxSlippageFXS).div(10000);

      Sushi(uniRouter).swapExactTokensForTokens(
        _fxs,
        _minimalAmount,
        path,
        address(this),
        now.add(1800)
      );
    }
    uint256 _frx = IERC20(frx).balanceOf(address(this));

    // swapping cvx to usdc on Sushi
    if (_cvx > 0) {
      IERC20(cvx).safeApprove(sushiRouter, 0);
      IERC20(cvx).safeApprove(sushiRouter, _cvx);

      address[] memory path = new address[](3);
      path[0] = cvx;
      path[1] = weth;
      path[2] = usdc;

      uint256[] memory _amounts = Sushi(sushiRouter).getAmountsOut(_cvx, path);
      uint256 _minimalAmount =
        _amounts[2].mul(10000 - maxSlippageCVX).div(10000);

      Sushi(sushiRouter).swapExactTokensForTokens(
        _cvx,
        _minimalAmount,
        path,
        address(this),
        now.add(1800)
      );
      uint256 _usdc = IERC20(usdc).balanceOf(address(this));

      // add_liquidity'ing usdc to 3pool, to get 3CRV
      if (_usdc > 0) {
        IERC20(usdc).safeApprove(three_pool, 0);
        IERC20(usdc).safeApprove(three_pool, _usdc);

        uint256 _tokenAmount =
          ICurveFi(three_pool).calc_token_amount([0, _usdc, 0], true);

        uint256 __minimalAmount =
          _tokenAmount.mul(10000 - maxSlippageCRVAddLiquidity).div(10000);
        ICurveFi(three_pool).add_liquidity([0, _usdc, 0], __minimalAmount);
      }
    }
    uint256 _three_crv = IERC20(three_crv).balanceOf(address(this));

    // add_liquidity'ing frx and/or 3CRV to frax metapool for want
    if (_frx > 0 || _three_crv > 0) {
      IERC20(frx).safeApprove(metapool, 0);
      IERC20(frx).safeApprove(metapool, _frx);
      IERC20(three_crv).safeApprove(metapool, 0);
      IERC20(three_crv).safeApprove(metapool, _three_crv);

      uint256 _tokenAmount =
        IMetapool(metapool).calc_token_amount([_frx, _three_crv], true);

      uint256 _minimalAmount =
        _tokenAmount.mul(10000 - maxSlippageCRVAddLiquidity).div(10000);
      IMetapool(metapool).add_liquidity([_frx, _three_crv], _minimalAmount);
    }
    uint256 _want = IERC20(want).balanceOf(address(this));

    if (_want > 0) {
      uint256 _fee = _want.mul(performanceFee).div(FEE_DENOMINATOR);
      IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
      deposit();
    }

    IVoterProxy(proxy).lock();
    earned = earned.add(_want);
    emit Harvested(_want, earned);
  }

  function balanceOfWant() public view returns (uint256) {
    return IERC20(want).balanceOf(address(this));
  }

  function balanceOfPool() public view returns (uint256) {
    return IBaseRewardPool(baseRewardPool).balanceOf(address(this));
  }

  function balanceOf() public view returns (uint256) {
    return balanceOfWant().add(balanceOfPool());
  }

  function setGovernance(address _governance) external onlyGovernance {
    governance = _governance;
  }

  function setController(address _controller) external onlyGovernance {
    controller = _controller;
  }
}

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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

