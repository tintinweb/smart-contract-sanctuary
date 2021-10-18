// SPDX-License-Identifier: UNLICENSED
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./TetuSwapPair.sol";
import "../base/interface/ISmartVault.sol";
import "../base/governance/Controllable.sol";
import "./FactoryStorage.sol";

/// @title Tetu swap factory based on Uniswap code
/// @dev Use with TetuProxyControlled.sol
/// @author belbix
contract TetuSwapFactory is Controllable, FactoryStorage {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";
  uint256 public constant TIME_LOCK = 48 hours;
  uint256 public constant DEFAULT_FEE = 10;

  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  /// @dev Operations allowed for Governance or HardWorker addresses
  modifier onlyHardWorker() {
    require(IController(controller()).isHardWorker(msg.sender), "TSF: Forbidden");
    _;
  }

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  ///      Initialize Controllable with sender address
  function initialize(address _controller) external initializer {
    Controllable.initializeControllable(_controller);
  }

  function allPairsLength() external view override returns (uint) {
    return allPairs.length;
  }

  function createPair(address vaultA, address vaultB) external override onlyHardWorker returns (address pair) {
    address tokenA = ISmartVault(vaultA).underlying();
    address tokenB = ISmartVault(vaultB).underlying();
    require(tokenA != tokenB, "TSF: IDENTICAL_ADDRESSES");
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "TSF: ZERO_ADDRESS");
    require(getPair[token0][token1] == address(0), "TSF: PAIR_EXISTS");
    // single check is sufficient
    bytes memory bytecode = type(TetuSwapPair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    assembly {
      pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    TetuSwapPair(pair).initialize(token0, token1, DEFAULT_FEE);
    getPair[token0][token1] = pair;
    // populate mapping in the reverse direction
    getPair[token1][token0] = pair;
    allPairs.push(pair);
    validPairs[pair] = true;
    _setVaultsForPair(pair, vaultA, vaultB);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }

  function setPairFee(address _pair, uint256 _fee) external onlyControllerOrGovernance {
    require(validPairs[_pair], "TSF: Pair not found");
    TetuSwapPair(_pair).setFee(_fee);
  }

  function setPairRewardRecipient(address _pair, address _recipient) external onlyControllerOrGovernance {
    require(validPairs[_pair], "TSF: Pair not found");
    TetuSwapPair(_pair).setRewardRecipient(_recipient);
  }

  function announceVaultsChange(address _vaultA, address _vaultB) external onlyControllerOrGovernance {
    address _tokenA = ISmartVault(_vaultA).underlying();
    address _tokenB = ISmartVault(_vaultB).underlying();
    address _pair = getPair[_tokenA][_tokenB];
    require(_pair != address(0), "TSF: Pair not found");

    require(timeLocks[_pair] == 0, "TSF: Time-lock already defined");

    timeLocks[_pair] = block.timestamp + TIME_LOCK;
  }

  function setVaultsForPair(address _vaultA, address _vaultB) external onlyControllerOrGovernance {
    address _tokenA = ISmartVault(_vaultA).underlying();
    address _tokenB = ISmartVault(_vaultB).underlying();
    address _pair = getPair[_tokenA][_tokenB];
    require(_pair != address(0), "TSF: Pair not found");

    require(timeLocks[_pair] != 0 && timeLocks[_pair] < block.timestamp, "TSF: Too early");
    _setVaultsForPair(_pair, _vaultA, _vaultB);
    timeLocks[_pair] = 0;
  }

  function _setVaultsForPair(address _pair, address _vaultA, address _vaultB) private {
    address _tokenA = ISmartVault(_vaultA).underlying();
    address _tokenB = ISmartVault(_vaultB).underlying();
    (address _vault0, address _vault1) = _tokenA < _tokenB ? (_vaultA, _vaultB) : (_vaultB, _vaultA);
    TetuSwapPair(_pair).setVaults(_vault0, _vault1);
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./TetuSwapERC20.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/Math.sol";
import "./libraries/TetuSwapLibrary.sol";
import "../third_party/uniswap/IUniswapV2Callee.sol";
import "../third_party/uniswap/IUniswapV2Factory.sol";
import "../third_party/IERC20Name.sol";
import "../base/interface/ISmartVault.sol";
import "./interfaces/ITetuSwapPair.sol";

/// @title Tetu swap pair based on Uniswap solution
///        Invest underlying assets to Tetu SmartVaults
/// @author belbix
contract TetuSwapPair is TetuSwapERC20, ITetuSwapPair, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using UQ112x112 for uint224;

  // ********** CONSTANTS ********************
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";
  uint public constant PRECISION = 10000;
  uint public constant MAX_FEE = 30;
  uint public constant override MINIMUM_LIQUIDITY = 10 ** 3;

  // ********** VARIABLES ********************
  address public override factory;
  address public override rewardRecipient;
  address public override token0;
  address public override token1;
  address public override vault0;
  address public override vault1;

  uint112 private reserve0;
  uint112 private reserve1;

  uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves
  uint public override price0CumulativeLast;
  uint public override price1CumulativeLast;
  string private _symbol;
  uint public override fee;
  uint public createdTs;
  uint public createdBlock;

  // ********** EVENTS ********************

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);
  event FeeChanged(uint oldFee, uint newFee);
  event VaultsChanged(address vault0, address vault1);
  event RewardRecipientChanged(address oldRecipient, address newRecipient);
  event Claimed(uint blockTs);

  /// @dev Should be create only from factory
  constructor() {
    factory = msg.sender;
  }

  modifier onlyFactory() {
    require(msg.sender == factory, "TSP: Not factory");
    _;
  }

  /// @dev Called once by the factory at time of deployment
  function initialize(
    address _token0,
    address _token1,
    uint _fee
  ) external override onlyFactory {
    require(_fee <= MAX_FEE, "TSP: Too high fee");
    require(token0 == address(0), "TSP: Already initialized");
    require(token1 == address(0), "TSP: Already initialized");
    token0 = _token0;
    token1 = _token1;
    fee = _fee;
    _symbol = createPairSymbol(IERC20Name(_token0).symbol(), IERC20Name(_token1).symbol());
    createdTs = block.timestamp;
    createdBlock = block.number;
  }

  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /// @dev Return saved reserves. Be aware that reserves always fluctuate!
  ///      For actual values need to call update
  function getReserves() public view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _blockTimestampLast = blockTimestampLast;
  }

  /// @dev Update reserves and, on the first call per block, price accumulators
  function _update() private {
    uint _balance0 = vaultReserve0();
    uint _balance1 = vaultReserve1();
    require(_balance0 <= type(uint112).max && _balance1 <= type(uint112).max, "TSP: OVERFLOW");

    uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
    uint32 timeElapsed = blockTimestamp - blockTimestampLast;

    if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
      price0CumulativeLast += uint(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
      price1CumulativeLast += uint(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
    }

    reserve0 = uint112(_balance0);
    reserve1 = uint112(_balance1);
    blockTimestampLast = blockTimestamp;
    emit Sync(reserve0, reserve1);
  }

  /// @dev Assume underlying tokens already sent to this contract
  ///      Mint new LP tokens to sender. Based on vault shares
  function mint(address to) external nonReentrant override returns (uint liquidity) {
    uint shareAmount0 = IERC20(vault0).balanceOf(address(this));
    uint shareAmount1 = IERC20(vault1).balanceOf(address(this));

    uint underlyingAmount0 = depositAllToVault(vault0);
    uint underlyingAmount1 = depositAllToVault(vault1);

    uint depositedAmount0 = IERC20(vault0).balanceOf(address(this)) - shareAmount0;
    uint depositedAmount1 = IERC20(vault1).balanceOf(address(this)) - shareAmount1;

    uint _totalSupply = totalSupply;
    if (_totalSupply == 0) {
      liquidity = Math.sqrt(depositedAmount0 * depositedAmount1) - MINIMUM_LIQUIDITY;
      // permanently lock the first MINIMUM_LIQUIDITY tokens
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = Math.min(
        depositedAmount0 * _totalSupply / shareAmount0,
        depositedAmount1 * _totalSupply / shareAmount1
      );
    }

    require(liquidity > 0, "TSP: Insufficient liquidity minted");
    _mint(to, liquidity);

    _update();
    emit Mint(msg.sender, underlyingAmount0, underlyingAmount1);
  }

  /// @dev Assume lp token already sent to this contract
  ///      Burn LP tokens and send back underlying assets. Based on vault shares
  function burn(address to) external nonReentrant override returns (uint amount0, uint amount1) {
    uint shareAmount0 = IERC20(vault0).balanceOf(address(this));
    uint shareAmount1 = IERC20(vault1).balanceOf(address(this));
    uint liquidity = balanceOf[address(this)];

    uint shareToWithdraw0 = liquidity * shareAmount0 / totalSupply;
    uint shareToWithdraw1 = liquidity * shareAmount1 / totalSupply;

    require(shareToWithdraw0 > 0 && shareToWithdraw1 > 0, "TSP: Insufficient liquidity burned");
    _burn(address(this), liquidity);

    require(shareToWithdraw0 <= IERC20(vault0).balanceOf(address(this)), "TSP: Insufficient shares 0");
    require(shareToWithdraw1 <= IERC20(vault1).balanceOf(address(this)), "TSP: Insufficient shares 1");

    ISmartVault(vault0).withdraw(shareToWithdraw0);
    ISmartVault(vault1).withdraw(shareToWithdraw1);

    amount0 = IERC20(token0).balanceOf(address(this));
    amount1 = IERC20(token1).balanceOf(address(this));

    IERC20(token0).safeTransfer(to, amount0);
    IERC20(token1).safeTransfer(to, amount1);

    _update();
    emit Burn(msg.sender, amount0, amount1, to);
  }

  /// @dev Assume tokenIn already sent to this contract
  ///      During swap process underlying assets will be deposited and withdrew from vaults
  ///      Depends on vault logic, underlying asset can be deposited with little reducing of amount
  ///      For keeping healthy K we are auto-compounding 1/10 of fees
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external nonReentrant override {
    require(amount0Out > 0 || amount1Out > 0, "TSP: Insufficient output amount");
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    require(amount0Out < _reserve0 && amount1Out < _reserve1, "TSP: Insufficient liquidity");

    uint expectedAmountIn0 = getAmountIn(amount1Out, _reserve0, _reserve1);
    uint expectedAmountIn1 = getAmountIn(amount0Out, _reserve1, _reserve0);

    // assume we invested all funds and have on balance only new tokens for current swap
    uint amount0In = IERC20(token0).balanceOf(address(this));
    uint amount1In = IERC20(token1).balanceOf(address(this));
    // check amountIn for cases of vault reserves fluctuations
    // we check accurate input value with required fees
    require(amount0In >= expectedAmountIn0 && amount1In >= expectedAmountIn1, "TSP: Insufficient input amount");

    if (amount0In > 0) {
      ISmartVault(vault0).deposit(amount0In);
    }
    if (amount1In > 0) {
      ISmartVault(vault1).deposit(amount1In);
    }

    {// scope for optimistically transfer output amount
      uint amountFee = 0;
      if (amount0In > amount1In) {
        amountFee = getFeeAmount(amount0In, _reserve0, _reserve1, amount1Out);
      } else {
        amountFee = getFeeAmount(amount1In, _reserve1, _reserve0, amount0Out);
      }
      _optimisticallyTransfer(amount0Out, amount1Out, to, data, amountFee);
    }

    // K value should be in a healthy range
    // in a normal circumstance not required after input amount checking
    // but kept for excluding for any possibilities of vault reserve manipulation
    {// scope for K checking
      uint balance0 = vaultReserve0();
      uint balance1 = vaultReserve1();
      // check K without fees
      require(balance0 * balance1 >= uint(_reserve0) * uint(_reserve1), "TSP: K too low");
    }

    _update();
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }

  /// @dev Force update
  function sync() external nonReentrant override {
    _update();
  }

  // ******************************************************
  // ************ NON UNISWAP FUNCTIONS *******************
  // ******************************************************

  /// @dev Returns expected input amount for given output amount
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public view returns (uint amountIn){
    if (amountOut == 0) {
      return 0;
    }
    return TetuSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut, fee);
  }

  /// @dev Calculates fee amount assuming that amountOutWithFee includes actual fee
  ///      Keep 1/10 of fee for auto-compounding
  ///      In case of 0 fees we will not able to use vaults with deposited amount fluctuations
  function getFeeAmount(uint amountIn, uint reserveIn, uint reserveOut, uint amountOutWithFee) public pure returns (uint amountFee){
    if (amountIn == 0) {
      return 0;
    }
    uint amountOutWithoutFee = TetuSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut, 0);
    if (amountOutWithoutFee <= amountOutWithFee) {
      return 0;
    }
    // keep 10% for auto compounding
    amountFee = (amountOutWithoutFee - amountOutWithFee) * 9 / 10;
  }

  /// @dev Returns vault underlying balance, or zero if it is not a underlying token
  function balanceOfVaultUnderlying(address _token) external view override returns (uint){
    if (_token == ISmartVault(vault0).underlying()) {
      return ISmartVault(vault0).underlyingBalanceWithInvestmentForHolder(address(this));
    } else if (_token == ISmartVault(vault1).underlying()) {
      return ISmartVault(vault1).underlyingBalanceWithInvestmentForHolder(address(this));
    }
    return 0;
  }

  /// @dev Returns vault underlying balance for this contract
  function vaultReserve0() public view returns (uint112) {
    return uint112(ISmartVault(vault0).underlyingBalanceWithInvestmentForHolder(address(this)));
  }

  /// @dev Returns vault underlying balance for this contract
  function vaultReserve1() public view returns (uint112){
    return uint112(ISmartVault(vault1).underlyingBalanceWithInvestmentForHolder(address(this)));
  }

  // ********* GOVERNANCE FUNCTIONS ****************

  /// @dev Set fee in range 0-0.3%
  function setFee(uint _fee) external override onlyFactory {
    require(_fee <= MAX_FEE, "TSP: Too high fee");
    emit FeeChanged(fee, _fee);
    fee = _fee;
  }

  /// @dev Called by fee setter after pair initialization
  function setVaults(address _vault0, address _vault1) external override onlyFactory {
    require(ISmartVault(_vault0).underlying() == token0, "TSP: Wrong vault0 underlying");
    require(ISmartVault(_vault1).underlying() == token1, "TSP: Wrong vault1 underlying");

    exitFromVault(vault0);
    exitFromVault(vault1);

    vault0 = _vault0;
    vault1 = _vault1;

    IERC20(token0).safeApprove(_vault0, type(uint).max);
    IERC20(token1).safeApprove(_vault1, type(uint).max);

    depositAllToVault(vault0);
    depositAllToVault(vault1);
    emit VaultsChanged(vault0, vault1);
  }

  /// @dev Set rewards recipient. This address will able to claim vault rewards and get swap fees
  function setRewardRecipient(address _recipient) external override onlyFactory {
    emit RewardRecipientChanged(rewardRecipient, _recipient);
    rewardRecipient = _recipient;
  }

  /// @dev Only reward recipient able to call it
  ///      Claims vaults rewards and send it to recipient
  function claimAll() external override {
    require(msg.sender == rewardRecipient, "TSP: Only recipient can claim");
    _claim(vault0);
    _claim(vault1);
    emit Claimed(block.timestamp);
  }

  // ***************** INTERNAL LOGIC ****************

  /// @dev Transfers output amount + fees
  function _optimisticallyTransfer(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data,
    uint amountFee
  ) private {
    address _token0 = token0;
    address _token1 = token1;
    require(to != _token0 && to != _token1, "TSP: Invalid to");
    if (amount0Out > 0) {
      withdrawFromVault(vault0, amount0Out + amountFee);
      IERC20(_token0).safeTransfer(to, amount0Out);
      if (amountFee > 0) {
        IERC20(_token0).safeTransfer(rewardRecipient, amountFee);
      }
    }
    if (amount1Out > 0) {
      withdrawFromVault(vault1, amount1Out + amountFee);
      IERC20(_token1).safeTransfer(to, amount1Out);
      if (amountFee > 0) {
        IERC20(_token1).safeTransfer(rewardRecipient, amountFee);
      }
    }
    if (data.length > 0) {
      IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
    }
  }

  /// @dev Deposit all underlying tokens to given vault
  function depositAllToVault(address _vault) private returns (uint) {
    uint underlyingAmount = IERC20(ISmartVault(_vault).underlying()).balanceOf(address(this));
    if (underlyingAmount > 0) {
      ISmartVault(_vault).deposit(underlyingAmount);
    }
    return underlyingAmount;
  }

  /// @dev Exit from given vault and set approve to zero for underlying token
  function exitFromVault(address _vault) private {
    if (_vault == address(0)) {
      return;
    }
    uint balance = IERC20(_vault).balanceOf(address(this));
    if (balance > 0) {
      ISmartVault(_vault).withdraw(balance);
    }
    IERC20(ISmartVault(_vault).underlying()).safeApprove(_vault, 0);
  }

  /// @dev Withdraw approx amount of underlying amount from given vault
  function withdrawFromVault(address _vault, uint _underlyingAmount) private {
    ISmartVault sv = ISmartVault(_vault);
    uint shareBalance = IERC20(_vault).balanceOf(address(this));
    uint shareToWithdraw = _underlyingAmount * sv.underlyingUnit() / sv.getPricePerFullShare();
    // add 1 for avoiding rounding issues
    shareToWithdraw = Math.min(shareToWithdraw + 1, shareBalance);
    require(shareToWithdraw <= shareBalance, "TSP: Insufficient shares");
    sv.withdraw(shareToWithdraw);
  }

  /// @dev Creates symbol string from given names
  function createPairSymbol(string memory name0, string memory name1) private pure returns (string memory) {
    return string(abi.encodePacked("TLP_", name0, "_", name1));
  }

  /// @dev Claim all rewards from given vault and send to reward recipient
  function _claim(address _vault) private {
    require(_vault != address(0), "TSP: Zero vault");
    ISmartVault sv = ISmartVault(_vault);

    for (uint i = 0; i < sv.rewardTokensLength(); i++) {
      address rt = sv.rewardTokens()[i];
      uint bal = IERC20(rt).balanceOf(address(this));
      sv.getReward(rt);
      uint claimed = IERC20(rt).balanceOf(address(this)) - bal;
      if (claimed > 0) {
        IERC20(rt).safeTransfer(rewardRecipient, claimed);
      }
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function changeActivityStatus(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function setLockPeriod(uint256 _value) external;

  function setLockPenalty(uint256 _value) external;

  function doHardWork() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);

  function userLastWithdrawTs(address _user) external returns (uint256);

  function userLastDepositTs(address _user) external returns (uint256);

  function userBoostTs(address _user) external returns (uint256);

  function userLockTs(address _user) external returns (uint256);

  function addRewardToken(address rt) external;

  function removeRewardToken(address rt) external;

  function stop() external;

  function ppfsDecreaseAllowed() external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function lockPenalty() external view returns (uint256);

  function lockAllowed() external view returns (bool);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ITetuSwapFactory.sol";

/// @title Eternal storage + getters and setters pattern
/// @dev If you will change a key value it will require setup it again
/// @author belbix
abstract contract FactoryStorage is Initializable, ITetuSwapFactory {


  mapping(address => mapping(address => address)) public override getPair;
  address[] public override allPairs;
  mapping(address => bool) public override validPairs;
  mapping(address => uint256) timeLocks;

  //slither-disable-next-line unused-state
  uint256[46] private ______gap;
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Uniswap implementation of ERC20 token with permit
///        https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2ERC20.sol
abstract contract TetuSwapERC20 {

  // ******** CONSTANTS ****************

  string private constant DEFAULT_SYMBOL = "TLP";
  string public constant name = "TetuSwap LP";
  uint8 public constant decimals = 18;

  // ******** VARIABLES ****************
  uint  public totalSupply;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;
  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;

  // ******** EVENTS ******************

  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  constructor() {
    uint _chainId;
    assembly {
      _chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes("1")),
        _chainId,
        address(this)
      )
    );
  }

  function symbol() external virtual view returns (string memory) {
    return DEFAULT_SYMBOL;
  }

  function _mint(address to, uint value) internal {
    totalSupply += value;
    balanceOf[to] += value;
    emit Transfer(address(0), to, value);
  }

  function _burn(address from, uint value) internal {
    balanceOf[from] -= value;
    totalSupply -= value;
    emit Transfer(from, address(0), value);
  }

  function _approve(address owner, address spender, uint value) private {
    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _transfer(address from, address to, uint value) private {
    balanceOf[from] -= value;
    balanceOf[to] += value;
    emit Transfer(from, to, value);
  }

  function approve(address spender, uint value) external returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transfer(address to, uint value) external returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint value) external returns (bool) {
    if (allowance[from][msg.sender] != type(uint).max) {
      allowance[from][msg.sender] -= value;
    }
    _transfer(from, to, value);
    return true;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, "TetuSwapERC20: EXPIRED");
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "TetuSwapERC20: INVALID_SIGNATURE");
    _approve(owner, spender, value);
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Uniswap UQ112x112 solution https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/UQ112x112.sol
///        A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
/// @dev range: [0, 2**112 - 1]
///      resolution: 1 / 2**112
library UQ112x112 {
  uint224 constant Q112 = 2 ** 112;

  /// @dev Encode a uint112 as a UQ112x112
  function encode(uint112 y) internal pure returns (uint224 z) {
    z = uint224(y) * Q112;
    // never overflows
  }

  /// @dev Divide a UQ112x112 by a uint112, returning a UQ112x112
  function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
    z = x / uint224(y);
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Uniswap Math https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
///        A library for performing various math operations
library Math {

  function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
  }

  /// @dev Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    z = 0;
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/ITetuSwapPair.sol";
import "../interfaces/ITetuSwapFactory.sol";

/// @title UniswapV2Library https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
library TetuSwapLibrary {
  using SafeMath for uint;

  uint constant private _PRECISION = 10000;
  uint constant private _FEE = 2;

  /// @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "TSL: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "TSL: ZERO_ADDRESS");
  }

  /// @dev use stored in factory pairs instead on the flay calculation
  ///      we have more flexible system and can't use old function
  function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
    return ITetuSwapFactory(factory).getPair(tokenA, tokenB);
  }

  /// @dev fetches and sorts the reserves for a pair
  function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = ITetuSwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  /// @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, "TSL: INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "TSL: INSUFFICIENT_LIQUIDITY");
    amountB = amountA.mul(reserveB) / reserveA;
  }

  /// @dev given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
    require(amountIn > 0, "TSL: INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "TSL: INSUFFICIENT_LIQUIDITY");
    uint amountInWithFee = amountIn.mul(_PRECISION - fee);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(_PRECISION).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  /// @dev given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountIn) {
    require(amountOut > 0, "TSL: INSUFFICIENT_OUTPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "TSL: INSUFFICIENT_LIQUIDITY");
    uint numerator = reserveIn.mul(amountOut).mul(_PRECISION);
    uint denominator = reserveOut.sub(amountOut).mul(_PRECISION - fee);
    amountIn = (numerator / denominator).add(1);
  }

  /// @dev performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, "TSL: INVALID_PATH");
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(
        amounts[i],
        reserveIn,
        reserveOut,
        ITetuSwapPair(pairFor(factory, path[i], path[i + 1])).fee()
      );
    }
  }

  /// @dev performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, "TSL: INVALID_PATH");
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(
        amounts[i],
        reserveIn,
        reserveOut,
        ITetuSwapPair(pairFor(factory, path[i - 1], path[i])).fee()
      );
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Callee {
  function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20Name {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ITetuSwapPair {

  function balanceOfVaultUnderlying(address _token) external view returns (uint);

  function setFee(uint _fee) external;

  function setVaults(address _vault0, address _vault1) external;

  function setRewardRecipient(address _recipient) external;

  function claimAll() external;

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function rewardRecipient() external view returns (address);

  function fee() external view returns (uint);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function vault0() external view returns (address);

  function vault1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function sync() external;

  function initialize(
    address _token0,
    address _token1,
    uint _fee
  ) external;

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ITetuSwapFactory {

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function validPairs(address _pair) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultAndStrategy(address _vault, address _strategy) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function addToWhiteListMulti(address[] calldata _targets) external;

  function addToWhiteList(address _target) external;

  function removeFromWhiteListMulti(address[] calldata _targets) external;

  function removeFromWhiteList(address _target) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);
}