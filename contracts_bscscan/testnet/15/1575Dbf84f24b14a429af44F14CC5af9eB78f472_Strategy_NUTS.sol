//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import './Strategy.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Strategy_NUTS is Strategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  address[] public users;
  mapping(address => uint256) public userLastDepositedTimestamp;
  uint256 public minTimeToWithdraw; // 604800 = 1 week
  uint256 public minTimeToWithdrawUL = 1209600; // 2 weeks

  event minTimeToWithdrawChanged(
    uint256 oldMinTimeToWithdraw,
    uint256 newMinTimeToWithdraw
  );

  event earned(uint256 oldWantLockedTotal, uint256 newWantLockedTotal);

  constructor(
    uint256 _pid,
    bool _isCAKEStaking,
    bool _isSameAssetDeposit,
    bool _isAutoComp,
    uint256[] memory _uints,
    address[] memory _addresses
  ) {
    wbnbAddress = _addresses[0];
    govAddress = _addresses[1];
    nutsFarmAddress = _addresses[2];
    NUTSAddress = _addresses[3];
    wantAddress = _addresses[4];
    pid = _pid;
    isCAKEStaking = _isCAKEStaking;
    isSameAssetDeposit = _isSameAssetDeposit;
    isAutoComp = _isAutoComp;

    controllerFee = _uints[0];
    buyBackRate = _uints[1];
    entranceFeeFactor = _uints[2];
    withdrawFeeFactor = _uints[3];

    minTimeToWithdraw = _uints[4];

    transferOwnership(nutsFarmAddress);
  }

  function deposit(address _userAddress, uint256 _wantAmt)
    public
    payable
    override
    onlyOwner
    nonReentrant
    whenNotPaused
    returns (uint256)
  {
    if (userLastDepositedTimestamp[_userAddress] == 0) {
      users.push(_userAddress);
    }
    userLastDepositedTimestamp[_userAddress] = block.timestamp;

    IERC20(wantAddress).safeTransferFrom(
      address(msg.sender),
      address(this),
      _wantAmt
    );

    uint256 sharesAdded = _wantAmt;
    if (wantLockedTotal > 0 && sharesTotal > 0) {
      sharesAdded = _wantAmt
        .mul(sharesTotal)
        .mul(entranceFeeFactor)
        .div(wantLockedTotal)
        .div(entranceFeeFactorMax);
    }
    sharesTotal = sharesTotal.add(sharesAdded);

    wantLockedTotal = IERC20(wantAddress).balanceOf(address(this));

    return sharesAdded;
  }

  function withdraw(address _userAddress, uint256 _wantAmt)
    public
    override
    onlyOwner
    nonReentrant
    returns (uint256)
  {
    // if the user never deposited, then they can't withdraw
    require(
      userLastDepositedTimestamp[_userAddress] != 0,
      'user has never deposited before'
    );
    require(
      (userLastDepositedTimestamp[_userAddress].add(minTimeToWithdraw)) <
        block.timestamp,
      'too early!'
    );

    require(_wantAmt > 0, '_wantAmt <= 0');

    uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
    if (sharesRemoved > sharesTotal) {
      sharesRemoved = sharesTotal;
    }
    sharesTotal = sharesTotal.sub(sharesRemoved);

    if (withdrawFeeFactor < withdrawFeeFactorMax) {
      _wantAmt = _wantAmt.mul(withdrawFeeFactor).div(withdrawFeeFactorMax);
    }

    uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
    if (_wantAmt > wantAmt) {
      _wantAmt = wantAmt;
    }

    if (wantLockedTotal < _wantAmt) {
      _wantAmt = wantLockedTotal;
    }

    wantLockedTotal = wantLockedTotal.sub(_wantAmt);

    IERC20(wantAddress).safeTransfer(nutsFarmAddress, _wantAmt);

    return sharesRemoved;
  }

  function _farm() internal override {}

  function _unfarm(uint256 _wantAmt) internal override {}

  function earn() public override nonReentrant whenNotPaused {}

  function setMinTimeToWithdraw(uint256 newMinTimeToWithdraw)
    public
    onlyAllowGov
  {
    require(newMinTimeToWithdraw <= minTimeToWithdrawUL, 'too high');
    emit minTimeToWithdrawChanged(minTimeToWithdraw, newMinTimeToWithdraw);
    minTimeToWithdraw = newMinTimeToWithdraw;
  }

  function userLength() public view returns (uint256) {
    return users.length;
  }

  receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// interfaces
// import "./interfaces/IERC20.sol";
import './interfaces/IPancakeswapFarm.sol';
import './interfaces/IPancakeRouter01.sol';
import './interfaces/IPancakeRouter02.sol';

interface IWBNB is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

abstract contract Strategy is Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // TODO organize the variables by type
  bool public isCAKEStaking; // only for staking CAKE using pancakeswap's native CAKE staking contract.
  bool public isSameAssetDeposit;
  bool public isAutoComp; // this vault is purely for staking. eg. WBNB-NUTS staking vault.

  address public farmContractAddress; // address of farm, eg, PCS, Thugs etc.
  uint256 public pid; // pid of pool in farmContractAddress
  address public wantAddress; // the address of the token we want to deposit and withdraw
  address public token0Address;
  address public token1Address;
  address public earnedAddress;
  address public uniRouterAddress; // uniswap, pancakeswap etc

  address public wbnbAddress; //wrapped bnb
  address public nutsFarmAddress; // address for nuts farm

  address public NUTSAddress;
  address public govAddress; // timelock contract
  bool public onlyGov = true;

  uint256 public lastEarnBlock = 0; // last block where the user earned
  uint256 public wantLockedTotal = 0;
  uint256 public sharesTotal = 0;

  uint256 public controllerFee = 0; // 70;
  uint256 public constant controllerFeeMax = 10000; // 100 = 1%
  uint256 public constant controllerFeeUL = 300;

  uint256 public buyBackRate = 0; // 250;
  uint256 public constant buyBackRateMax = 10000; // 100 = 1%
  uint256 public constant buyBackRateUL = 800;
  address public buyBackAddress = 0x000000000000000000000000000000000000dEaD;
  address public rewardsAddress;

  uint256 public entranceFeeFactor = 9990; // < 0.1% entrance fee - goes to pool + prevents front-running
  uint256 public constant entranceFeeFactorMax = 10000;
  uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

  uint256 public withdrawFeeFactor = 10000; // 0.1% withdraw fee - goes to pool
  uint256 public constant withdrawFeeFactorMax = 10000;
  uint256 public constant withdrawFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

  uint256 public slippageFactor = 950; // 5% default slippage tolerance
  uint256 public constant slippageFactorUL = 995;

  address[] public earnedToNUTSPath;
  address[] public earnedToToken0Path;
  address[] public earnedToToken1Path;
  address[] public token0ToEarnedPath;
  address[] public token1ToEarnedPath;

  event SetSettings(
    uint256 _entranceFeeFactor,
    uint256 _withdrawFeeFactor,
    uint256 _controllerFee,
    uint256 _buyBackRate,
    uint256 _slippageFactor
  );

  event SetGov(address _govAddress);
  event SetOnlyGov(bool _onlyGov);
  event SetUniRouterAddress(address _uniRouterAddress);
  event SetBuyBackAddress(address _buyBackAddress);
  event SetRewardsAddress(address _rewardsAddress);

  modifier onlyAllowGov() {
    require(msg.sender == govAddress, '!gov');
    _;
  }

  modifier onlyFarmOrAdmin() {
    require(
      msg.sender == nutsFarmAddress || msg.sender == owner(),
      'Caller is not vault or owner'
    );
    _;
  }

  /**
   * @dev Recieves new deposits from user
   * @param _userAddress address of the user
   * @param _wantAmt 'Want Amount' the amount of tokens the user wants to deposit
   */
  function deposit(address _userAddress, uint256 _wantAmt)
    public
    payable
    virtual
    onlyFarmOrAdmin
    whenNotPaused
    nonReentrant
    returns (uint256)
  {
    // transfer money from the user to this contract
    IERC20(wantAddress).safeTransferFrom(
      address(msg.sender),
      address(this),
      _wantAmt
    );
    // calculate new sharesTotal
    uint256 sharesAdded = _wantAmt;

    if (wantLockedTotal > 0 && sharesTotal > 0) {
      sharesAdded = _wantAmt
        .mul(sharesTotal)
        .mul(entranceFeeFactor)
        .div(wantLockedTotal)
        .div(entranceFeeFactorMax);
    }
    sharesTotal = sharesTotal.add(sharesAdded);

    // if it's auto compounding,
    if (isAutoComp) {
      _farm();
    } else {
      // if it's not auto compounding, lock the total amount
      wantLockedTotal = wantLockedTotal.add(_wantAmt);
    }

    return sharesAdded;
  }

  // enter pancake pools or farm
  function _farm() internal virtual {
    require(isAutoComp, '!isAutoComp');
    uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
    wantLockedTotal = wantLockedTotal.add(wantAmt);
    IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

    if (isCAKEStaking) {
      // stake CAKE tokens to MAsterChef
      IPancakeswapFarm(farmContractAddress).enterStaking(wantAmt); // Just for CAKE staking, we dont use deposit()
    } else {
      // deposit LP tokens to MasterChef for CAKE allocation
      IPancakeswapFarm(farmContractAddress).deposit(pid, wantAmt);
    }
  }

  // leave staking / withdraw
  function _unfarm(uint256 _wantAmt) internal virtual {
    if (isCAKEStaking) {
      // withdraw CAKE tokens from STAKING
      IPancakeswapFarm(farmContractAddress).leaveStaking(_wantAmt); // Just for CAKE staking, we dont use withdraw()
    } else {
      // withdraw LP tokens from MasterChef
      IPancakeswapFarm(farmContractAddress).withdraw(pid, _wantAmt);
    }
  }

  // withdraw tokens from staking / farms
  /**
   * @dev withdraw amount from staking / liquidity pools
   * @param _userAddress user address
   * @param _wantAmt (want amount) amount to withdraw
   */
  function withdraw(address _userAddress, uint256 _wantAmt)
    public
    virtual
    onlyFarmOrAdmin
    nonReentrant
    returns (uint256)
  {
    // must withdraw more than 0
    require(_wantAmt > 0, '_wantAmt <= 0');

    // calculate how many shares to remove
    uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
    if (sharesRemoved > sharesTotal) {
      sharesRemoved = sharesTotal;
    }
    // remove shares
    sharesTotal = sharesTotal.sub(sharesRemoved);

    // more calculations
    if (withdrawFeeFactor < withdrawFeeFactorMax) {
      _wantAmt = _wantAmt.mul(withdrawFeeFactor).div(withdrawFeeFactorMax);
    }

    // if auto compounding, withdraw AND reap the
    // rewards from pancake (or whatever platform)
    if (isAutoComp) {
      _unfarm(_wantAmt);
    }

    // get the balance of this token
    uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
    // if the user wants more than what this contract is holding, use the max value
    if (_wantAmt > wantAmt) {
      _wantAmt = wantAmt;
    }

    // if the wanted amount is greater than the total locked amount, use the max value
    if (wantLockedTotal < _wantAmt) {
      _wantAmt = wantLockedTotal;
    }

    wantLockedTotal = wantLockedTotal.sub(_wantAmt);

    // transfer the funds to nutsfarm to be processed further
    IERC20(wantAddress).safeTransfer(nutsFarmAddress, _wantAmt);

    return sharesRemoved;
  }

  // 1. Harvest farm tokens
  // 2. Converts farm tokens into want tokens
  // 3. Deposits want tokens

  function earn() public virtual nonReentrant whenNotPaused {
    require(isAutoComp, '!isAutoComp');
    if (onlyGov) {
      require(msg.sender == govAddress, '!gov');
    }

    // 1. Harvest farm tokens
    // call pancakeswap withdraw function with 0 dollars, so only the rewards are withdrawn
    _unfarm(0);

    if (earnedAddress == wbnbAddress) {
      _wrapBNB();
    }

    // Converts farm tokens into want tokens
    uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

    earnedAmt = distributeFees(earnedAmt);
    earnedAmt = buyBack(earnedAmt);

    if (isCAKEStaking || isSameAssetDeposit) {
      lastEarnBlock = block.number;
      _farm();
      return;
    }

    IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
    IERC20(earnedAddress).safeIncreaseAllowance(uniRouterAddress, earnedAmt);

    if (earnedAddress != token0Address) {
      // Swap half earned to token0
      _safeSwap(
        uniRouterAddress,
        earnedAmt.div(2),
        slippageFactor,
        earnedToToken0Path,
        address(this),
        block.timestamp.add(600)
      );
    }

    if (earnedAddress != token1Address) {
      // Swap half earned to token1
      _safeSwap(
        uniRouterAddress,
        earnedAmt.div(2),
        slippageFactor,
        earnedToToken1Path,
        address(this),
        block.timestamp.add(600)
      );
    }

    // Get want tokens, ie. add liquidity
    uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
    uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
    if (token0Amt > 0 && token1Amt > 0) {
      IERC20(token0Address).safeIncreaseAllowance(uniRouterAddress, token0Amt);
      IERC20(token1Address).safeIncreaseAllowance(uniRouterAddress, token1Amt);
      IPancakeRouter02(uniRouterAddress).addLiquidity(
        token0Address,
        token1Address,
        token0Amt,
        token1Amt,
        0,
        0,
        address(this),
        block.timestamp.add(600)
      );
    }

    lastEarnBlock = block.number;

    _farm();
  }

  function buyBack(uint256 _earnedAmt) internal virtual returns (uint256) {
    if (buyBackRate <= 0) {
      return _earnedAmt;
    }

    uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(buyBackRateMax);

    if (earnedAddress == NUTSAddress) {
      IERC20(earnedAddress).safeTransfer(buyBackAddress, buyBackAmt);
    } else {
      IERC20(earnedAddress).safeIncreaseAllowance(uniRouterAddress, buyBackAmt);

      _safeSwap(
        uniRouterAddress,
        buyBackAmt,
        slippageFactor,
        earnedToNUTSPath,
        buyBackAddress,
        block.timestamp.add(600)
      );
    }

    return _earnedAmt.sub(buyBackAmt);
  }

  function distributeFees(uint256 _earnedAmt)
    internal
    virtual
    returns (uint256)
  {
    if (_earnedAmt > 0) {
      // Performance fee
      if (controllerFee > 0) {
        uint256 fee = _earnedAmt.mul(controllerFee).div(controllerFeeMax);
        IERC20(earnedAddress).safeTransfer(rewardsAddress, fee);
        _earnedAmt = _earnedAmt.sub(fee);
      }
    }

    return _earnedAmt;
  }

  function convertDustToEarned() public virtual whenNotPaused {
    require(isAutoComp, '!isAutoComp');
    require(!isCAKEStaking, 'isCAKEStaking');

    // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

    // Converts token0 dust (if any) to earned tokens
    uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
    if (token0Address != earnedAddress && token0Amt > 0) {
      IERC20(token0Address).safeIncreaseAllowance(uniRouterAddress, token0Amt);

      // Swap all dust tokens to earned tokens
      _safeSwap(
        uniRouterAddress,
        token0Amt,
        slippageFactor,
        token0ToEarnedPath,
        address(this),
        block.timestamp.add(600)
      );
    }

    // Converts token1 dust (if any) to earned tokens
    uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
    if (token1Address != earnedAddress && token1Amt > 0) {
      IERC20(token1Address).safeIncreaseAllowance(uniRouterAddress, token1Amt);

      // Swap all dust tokens to earned tokens
      _safeSwap(
        uniRouterAddress,
        token1Amt,
        slippageFactor,
        token1ToEarnedPath,
        address(this),
        block.timestamp.add(600)
      );
    }
  }

  function pause() public virtual onlyAllowGov {
    _pause();
  }

  function unpause() public virtual onlyAllowGov {
    _unpause();
  }

  function setSettings(
    uint256 _entranceFeeFactor,
    uint256 _withdrawFeeFactor,
    uint256 _controllerFee,
    uint256 _buyBackRate,
    uint256 _slippageFactor
  ) public virtual onlyAllowGov {
    require(
      _entranceFeeFactor >= entranceFeeFactorLL,
      '_entranceFeeFactor too low'
    );
    require(
      _entranceFeeFactor <= entranceFeeFactorMax,
      '_entranceFeeFactor too high'
    );
    entranceFeeFactor = _entranceFeeFactor;

    require(
      _withdrawFeeFactor >= withdrawFeeFactorLL,
      '_withdrawFeeFactor too low'
    );
    require(
      _withdrawFeeFactor <= withdrawFeeFactorMax,
      '_withdrawFeeFactor too high'
    );
    withdrawFeeFactor = _withdrawFeeFactor;

    require(_controllerFee <= controllerFeeUL, '_controllerFee too high');
    controllerFee = _controllerFee;

    require(_buyBackRate <= buyBackRateUL, '_buyBackRate too high');
    buyBackRate = _buyBackRate;

    require(_slippageFactor <= slippageFactorUL, '_slippageFactor too high');
    slippageFactor = _slippageFactor;

    emit SetSettings(
      _entranceFeeFactor,
      _withdrawFeeFactor,
      _controllerFee,
      _buyBackRate,
      _slippageFactor
    );
  }

  function setGov(address _govAddress) public virtual onlyAllowGov {
    govAddress = _govAddress;
    emit SetGov(_govAddress);
  }

  function setOnlyGov(bool _onlyGov) public virtual onlyAllowGov {
    onlyGov = _onlyGov;
    emit SetOnlyGov(_onlyGov);
  }

  function setUniRouterAddress(address _uniRouterAddress)
    public
    virtual
    onlyAllowGov
  {
    uniRouterAddress = _uniRouterAddress;
    emit SetUniRouterAddress(_uniRouterAddress);
  }

  function setBuyBackAddress(address _buyBackAddress)
    public
    virtual
    onlyAllowGov
  {
    buyBackAddress = _buyBackAddress;
    emit SetBuyBackAddress(_buyBackAddress);
  }

  function setRewardsAddress(address _rewardsAddress)
    public
    virtual
    onlyAllowGov
  {
    rewardsAddress = _rewardsAddress;
    emit SetRewardsAddress(_rewardsAddress);
  }

  function inCaseTokensGetStuck(
    address _token,
    uint256 _amount,
    address _to
  ) public virtual onlyAllowGov {
    require(_token != earnedAddress, '!safe');
    require(_token != wantAddress, '!safe');
    IERC20(_token).safeTransfer(_to, _amount);
  }

  function _wrapBNB() internal virtual {
    // BNB -> WBNB
    uint256 bnbBal = address(this).balance;
    if (bnbBal > 0) {
      IWBNB(wbnbAddress).deposit{value: bnbBal}(); // BNB -> WBNB
    }
  }

  function wrapBNB() public virtual onlyAllowGov {
    _wrapBNB();
  }

  function _safeSwap(
    address _uniRouterAddress,
    uint256 _amountIn,
    uint256 _slippageFactor,
    address[] memory _path,
    address _to,
    uint256 _deadline
  ) internal virtual {
    uint256[] memory amounts = IPancakeRouter02(_uniRouterAddress)
      .getAmountsOut(_amountIn, _path);
    uint256 amountOut = amounts[amounts.length.sub(1)];

    IPancakeRouter02(_uniRouterAddress)
      .swapExactTokensForTokensSupportingFeeOnTransferTokens(
        _amountIn,
        amountOut.mul(_slippageFactor).div(1000),
        _path,
        _to,
        _deadline
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPancakeswapFarm {
    function poolLength() external view returns (uint256);

    function userInfo() external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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