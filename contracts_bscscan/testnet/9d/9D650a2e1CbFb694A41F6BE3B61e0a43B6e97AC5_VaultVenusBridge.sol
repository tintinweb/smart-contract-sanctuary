// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

import '../interfaces/IBank.sol';
import '../library/SafeToken.sol';

import './BankBridge.sol';
import '../vaults/venus/VaultVenus.sol';

contract BankBNB is IBank, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address public constant TREASURY = 0x0989091F27708Bc92ea4cA60073e03592B94C0eE;

  /* ========== STATE VARIABLES ========== */

  IBankConfig public config;
  BankBridge public bankBridge;
  VaultVenus public vaultVenus;

  uint256 public lastAccrueTime;
  uint256 public reserved;
  uint256 public totalDebt;
  uint256 public totalShares;
  mapping(address => mapping(address => uint256)) private _shares;

  /* ========== EVENTS ========== */

  event DebtAdded(address indexed pool, address indexed account, uint256 share);
  event DebtRemoved(
    address indexed pool,
    address indexed account,
    uint256 share
  );
  event DebtHandedOver(
    address indexed pool,
    address indexed from,
    address indexed to,
    uint256 share
  );

  /* ========== MODIFIERS ========== */

  modifier accrue() {
    vaultVenus.updateVenusFactors();
    if (block.timestamp > lastAccrueTime) {
      uint256 interest = pendingInterest();
      uint256 reserve = interest.mul(config.getReservePoolBps()).div(10000);
      totalDebt = totalDebt.add(interest);
      reserved = reserved.add(reserve);
      lastAccrueTime = block.timestamp;
    }
    _;
    vaultVenus.updateVenusFactors();
  }

  modifier onlyBridge() {
    require(
      msg.sender == address(bankBridge),
      'BankBNB: caller is not the bridge'
    );
    _;
  }

  receive() external payable {}

  /* ========== INITIALIZER ========== */

  function initialize() external initializer {
    __ReentrancyGuard_init();
    __WhitelistUpgradeable_init();

    lastAccrueTime = block.timestamp;
  }

  /* ========== VIEW FUNCTIONS ========== */

  function pendingInterest() public view returns (uint256) {
    if (block.timestamp <= lastAccrueTime) return 0;

    uint256 ratePerSec = config.getInterestRate(
      totalDebt,
      vaultVenus.balance()
    );
    return
      ratePerSec.mul(totalDebt).mul(block.timestamp.sub(lastAccrueTime)).div(
        1e18
      );
  }

  function pendingDebtOf(address pool, address account)
    public
    view
    override
    returns (uint256)
  {
    uint256 share = sharesOf(pool, account);
    if (totalShares == 0) return share;

    return share.mul(totalDebt.add(pendingInterest())).div(totalShares);
  }

  function pendingDebtOfBridge() external view override returns (uint256) {
    return pendingDebtOf(address(this), address(bankBridge));
  }

  function sharesOf(address pool, address account)
    public
    view
    override
    returns (uint256)
  {
    return _shares[pool][account];
  }

  function shareToAmount(uint256 share) public view override returns (uint256) {
    if (totalShares == 0) return share;
    return share.mul(totalDebt).div(totalShares);
  }

  function amountToShare(uint256 amount)
    public
    view
    override
    returns (uint256)
  {
    if (totalShares == 0) return amount;
    return amount.mul(totalShares).div(totalDebt);
  }

  function debtToProviders() public view override returns (uint256) {
    return totalDebt.sub(reserved);
  }

  function getUtilizationInfo()
    public
    view
    override
    returns (uint256 liquidity, uint256 utilized)
  {
    return (vaultVenus.balance(), totalDebt);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function accruedDebtOf(address pool, address account)
    public
    override
    accrue
    returns (uint256)
  {
    return shareToAmount(sharesOf(pool, account));
  }

  function accruedDebtOfBridge() public override accrue returns (uint256) {
    return shareToAmount(sharesOf(address(this), address(bankBridge)));
  }

  function executeAccrue() external override {
    if (block.timestamp > lastAccrueTime) {
      uint256 interest = pendingInterest();
      uint256 reserve = interest.mul(config.getReservePoolBps()).div(10000);
      totalDebt = totalDebt.add(interest);
      reserved = reserved.add(reserve);
      lastAccrueTime = block.timestamp;
    }
  }

  /* ========== RESTRICTED FUNCTIONS - CONFIGURATION ========== */

  function setBankBridge(address payable newBridge) external onlyOwner {
    require(
      address(bankBridge) == address(0),
      'BankBNB: bridge is already set'
    );
    require(newBridge != address(0), 'BankBNB: invalid bridge address');
    bankBridge = BankBridge(newBridge);
  }

  function setVaultVenus(address payable newVaultVenus) external onlyOwner {
    require(
      address(vaultVenus) == address(0),
      'BankBNB: VaultVenus is already set'
    );
    require(
      newVaultVenus != address(0) &&
        VaultVenus(newVaultVenus).stakingToken() == WBNB,
      'BankBNB: invalid VaultVenus'
    );
    vaultVenus = VaultVenus(newVaultVenus);
  }

  function updateConfig(address newConfig) external onlyOwner {
    require(newConfig != address(0), 'BankBNB: invalid config address');
    config = IBankConfig(newConfig);
  }

  /* ========== RESTRICTED FUNCTIONS - BANKING ========== */

  function borrow(
    address pool,
    address account,
    uint256 amount
  ) external override accrue onlyWhitelisted returns (uint256 debtInBNB) {
    amount = Math.min(amount, vaultVenus.balance());
    amount = vaultVenus.borrow(amount);
    uint256 share = amountToShare(amount);

    _shares[pool][account] = _shares[pool][account].add(share);
    totalShares = totalShares.add(share);
    totalDebt = totalDebt.add(amount);

    SafeToken.safeTransferETH(msg.sender, amount);
    emit DebtAdded(pool, account, share);
    return amount;
  }

  //    function repayPartial(address pool, address account) public override payable accrue onlyWhitelisted {
  //        uint debt = accruedDebtOf(pool, account);
  //        uint available = Math.min(msg.value, debt);
  //        vaultVenus.repay{value : available}();
  //
  //        uint share = Math.min(amountToShare(available), _shares[pool][account]);
  //        _shares[pool][account] = _shares[pool][account].sub(share);
  //        totalShares = totalShares.sub(share);
  //        totalDebt = totalDebt.sub(available);
  //        emit DebtRemoved(pool, account, share);
  //
  //        if (totalDebt < reserved) {
  //            _decreaseReserved(TREASURY, reserved);
  //        }
  //    }

  function repayAll(address pool, address account)
    public
    payable
    override
    accrue
    onlyWhitelisted
    returns (uint256 profitInETH, uint256 lossInETH)
  {
    uint256 received = msg.value;
    uint256 bnbBefore = address(this).balance;

    uint256 debt = accruedDebtOf(pool, account);
    uint256 profit = received > debt ? received.sub(debt) : 0;
    uint256 loss = received < debt ? debt.sub(received) : 0;

    profitInETH = profit > 0 ? bankBridge.realizeProfit{ value: profit }() : 0;
    lossInETH = loss > 0 ? bankBridge.realizeLoss(loss) : 0;
    received = loss > 0
      ? received.add(address(this).balance).sub(bnbBefore)
      : received.sub(profit);

    uint256 available = Math.min(received, debt);
    vaultVenus.repay{ value: available }();

    uint256 share = _shares[pool][account];
    if (loss > 0) {
      uint256 unpaidDebtShare = Math.min(amountToShare(loss), share);
      _shares[address(this)][address(bankBridge)] = _shares[address(this)][
        address(bankBridge)
      ].add(unpaidDebtShare);
      emit DebtHandedOver(pool, account, msg.sender, unpaidDebtShare);

      share = share.sub(unpaidDebtShare);
    }

    delete _shares[pool][account];
    totalShares = totalShares.sub(share);
    totalDebt = totalDebt.sub(available);
    emit DebtRemoved(pool, account, share);

    _cleanupDust();

    if (totalDebt < reserved) {
      _decreaseReserved(TREASURY, reserved);
    }
  }

  function repayBridge() external payable override {
    uint256 debtInBNB = accruedDebtOfBridge();
    if (debtInBNB == 0) return;
    require(msg.value >= debtInBNB, 'BankBNB: not enough value');

    vaultVenus.repay{ value: debtInBNB }();

    uint256 share = _shares[address(this)][address(bankBridge)];
    delete _shares[address(this)][address(bankBridge)];
    totalShares = totalShares.sub(share);
    totalDebt = totalDebt.sub(debtInBNB);
    emit DebtRemoved(address(this), address(bankBridge), share);

    _cleanupDust();

    if (totalDebt < reserved) {
      _decreaseReserved(TREASURY, reserved);
    }

    if (msg.value > debtInBNB) {
      SafeToken.safeTransferETH(msg.sender, msg.value.sub(debtInBNB));
    }
  }

  function bridgeETH(address to, uint256 amount)
    external
    override
    onlyWhitelisted
  {
    bankBridge.bridgeETH(to, amount);
  }

  /* ========== RESTRICTED FUNCTIONS - OPERATION ========== */

  function withdrawReserved(address to, uint256 amount)
    external
    onlyOwner
    accrue
    nonReentrant
  {
    require(amount <= reserved, 'BankBNB: amount exceeded');
    _decreaseReserved(to, amount);
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _decreaseReserved(address to, uint256 amount) private {
    reserved = reserved.sub(amount);
    amount = vaultVenus.borrow(amount);
    SafeToken.safeTransferETH(to, amount);
  }

  function _cleanupDust() private {
    if (totalDebt < 1000 && totalShares < 1000) {
      totalShares = 0;
      totalDebt = 0;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBank {
  function pendingDebtOf(address pool, address account)
    external
    view
    returns (uint256);

  function pendingDebtOfBridge() external view returns (uint256);

  function sharesOf(address pool, address account)
    external
    view
    returns (uint256);

  function debtToProviders() external view returns (uint256);

  function getUtilizationInfo()
    external
    view
    returns (uint256 liquidity, uint256 utilized);

  function shareToAmount(uint256 share) external view returns (uint256);

  function amountToShare(uint256 share) external view returns (uint256);

  function accruedDebtOf(address pool, address account)
    external
    returns (uint256 debt);

  function accruedDebtOfBridge() external returns (uint256 debt);

  function executeAccrue() external;

  function borrow(
    address pool,
    address account,
    uint256 amount
  ) external returns (uint256 debtInBNB);

  //    function repayPartial(address pool, address account) external payable;
  function repayAll(address pool, address account)
    external
    payable
    returns (uint256 profitInETH, uint256 lossInETH);

  function repayBridge() external payable;

  function bridgeETH(address to, uint256 amount) external;
}

interface IBankBridge {
  function realizeProfit() external payable returns (uint256 profitInETH);

  function realizeLoss(uint256 debt) external returns (uint256 lossInETH);
}

interface IBankConfig {
  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating)
    external
    view
    returns (uint256);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);
}

interface InterestModel {
  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user)
    internal
    view
    returns (uint256)
  {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x095ea7b3, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      '!safeApprove'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0xa9059cbb, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      '!safeTransfer'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x23b872dd, from, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      '!safeTransferFrom'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, '!safeTransferETH');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/Math.sol';

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';

import '../library/SafeToken.sol';
import '../library/PausableUpgradeable.sol';
import '../library/WhitelistUpgradeable.sol';
import '../interfaces/IPancakeRouter02.sol';
import '../interfaces/IBank.sol';

contract BankBridge is IBankBridge, PausableUpgradeable, WhitelistUpgradeable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  uint256 private constant RESERVE_RATIO_UNIT = 10000;
  uint256 private constant RESERVE_RATIO_LIMIT = 5000;

  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
  IPancakeRouter02 private constant ROUTER =
    IPancakeRouter02(0x6bE66bd6A15c8b0e6d5F40DC4056b14dA3cc48dE);

  /* ========== STATE VARIABLES ========== */

  address public bank;

  uint256 public reserveRatio;
  uint256 public reserved;

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  function initialize() external initializer {
    __PausableUpgradeable_init();
    __WhitelistUpgradeable_init();

    reserveRatio = 1000;
  }

  /* ========== VIEW FUNCTIONS ========== */

  function balance() public view returns (uint256) {
    return IBEP20(ETH).balanceOf(address(this));
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setReserveRatio(uint256 newReserveRatio) external onlyOwner {
    require(
      newReserveRatio <= RESERVE_RATIO_LIMIT,
      'BankBridge: invalid reserve ratio'
    );
    reserveRatio = newReserveRatio;
  }

  function setBank(address payable newBank) external onlyOwner {
    require(address(bank) == address(0), 'BankBridge: bank exists');
    bank = newBank;
  }

  function approveETH() external onlyOwner {
    IBEP20(ETH).approve(address(ROUTER), uint256(-1));
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function realizeProfit()
    external
    payable
    override
    onlyWhitelisted
    returns (uint256 profitInETH)
  {
    if (msg.value == 0) return 0;

    uint256 reserve = msg.value.mul(reserveRatio).div(RESERVE_RATIO_UNIT);
    reserved = reserved.add(reserve);

    address[] memory path = new address[](2);
    path[0] = WBNB;
    path[1] = ETH;

    return
      ROUTER.swapExactETHForTokens{ value: msg.value.sub(reserve) }(
        0,
        path,
        address(this),
        block.timestamp
      )[1];
  }

  function realizeLoss(uint256 loss)
    external
    override
    onlyWhitelisted
    returns (uint256 lossInETH)
  {
    if (loss == 0) return 0;

    address[] memory path = new address[](2);
    path[0] = ETH;
    path[1] = WBNB;

    lossInETH = ROUTER.getAmountsIn(loss, path)[0];
    uint256 ethBalance = IBEP20(ETH).balanceOf(address(this));
    if (ethBalance >= lossInETH) {
      uint256 bnbOut = ROUTER.swapTokensForExactETH(
        loss,
        lossInETH,
        path,
        address(this),
        block.timestamp
      )[1];
      SafeToken.safeTransferETH(bank, bnbOut);
      return 0;
    } else {
      if (ethBalance > 0) {
        uint256 bnbOut = ROUTER.swapExactTokensForETH(
          ethBalance,
          0,
          path,
          address(this),
          block.timestamp
        )[1];
        SafeToken.safeTransferETH(bank, bnbOut);
      }
      lossInETH = lossInETH.sub(ethBalance);
    }
  }

  function bridgeETH(address to, uint256 amount) external onlyWhitelisted {
    if (IBEP20(ETH).allowance(address(this), address(to)) == 0) {
      IBEP20(ETH).safeApprove(address(to), uint256(-1));
    }
    IBEP20(ETH).safeTransfer(to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import 'hardhat/console.sol';

import '@openzeppelin/contracts/math/Math.sol';

import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

import '../../library/PausableUpgradeable.sol';
import '../../library/SafeToken.sol';
import '../../library/SafeVenus.sol';

import '../../interfaces/IStrategy.sol';
import '../../interfaces/IVToken.sol';
import '../../interfaces/IVenusDistribution.sol';
import '../../interfaces/IVaultVenusBridge.sol';
import '../../interfaces/IBank.sol';
import '../VaultController.sol';
import './VaultVenusBridgeOwner.sol';
import './VaultVenusBridge.sol';

contract VaultVenus is VaultController, IStrategy, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  uint256 public constant override pid = 9999;
  PoolConstant.PoolTypes public constant override poolType =
    PoolConstant.PoolTypes.Venus;

  IVenusDistribution private constant VENUS_UNITROLLER =
    IVenusDistribution(0x94d1820b2D1c7c7452A163983Dc888CEC546b77D);

  VaultVenusBridgeOwner private constant VENUS_BRIDGE_OWNER =
    VaultVenusBridgeOwner(0xd386dD9EA89785862182026e547C1C2e0f7A3aC3);

  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address private constant XVS = 0xB9e0E753630434d7863528cc73CB7AC638a7c8ff;

  uint256 private constant COLLATERAL_RATIO_INIT = 975;
  uint256 private constant COLLATERAL_RATIO_EMERGENCY = 998;
  uint256 private constant COLLATERAL_RATIO_SYSTEM_DEFAULT = 6e17;
  uint256 private constant DUST = 1000;

  uint256 private constant VENUS_EXIT_BASE = 10000;

  /* ========== STATE VARIABLES ========== */

  IVToken public vToken;
  IVaultVenusBridge public venusBridge;
  SafeVenus public safeVenus;
  address public bank;

  uint256 public venusBorrow;
  uint256 public venusSupply;

  uint256 public collateralDepth;
  uint256 public collateralRatioFactor;
  uint256 public collateralRatio;
  uint256 public collateralRatioLimit;
  uint256 public collateralRatioEmergency;

  uint256 public reserveRatio;

  uint256 public totalShares;
  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _principal;
  mapping(address => uint256) private _depositedAt;

  uint256 public venusExitRatio;
  uint256 public collateralRatioSystem;

  /* ========== EVENTS ========== */

  event CollateralFactorsUpdated(
    uint256 collateralRatioFactor,
    uint256 collateralDepth
  );
  event DebtAdded(address bank, uint256 amount);
  event DebtRemoved(address bank, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier onlyBank() {
    require(
      bank != address(0) && msg.sender == bank,
      'VaultVenus: caller is not the bank'
    );
    _;
  }

  modifier accrueBank() {
    if (bank != address(0)) {
      IBank(bank).executeAccrue();
    }
    _;
  }

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  function initialize(address _token, address _vToken) external initializer {
    require(_token != address(0), 'VaultVenus: invalid token');
    __VaultController_init(IBEP20(_token));
    __ReentrancyGuard_init();
    vToken = IVToken(_vToken);

    (, uint256 collateralFactorMantissa, ) = VENUS_UNITROLLER.markets(_vToken);
    collateralFactorMantissa = Math.min(
      collateralFactorMantissa,
      Math.min(collateralRatioSystem, COLLATERAL_RATIO_SYSTEM_DEFAULT)
    );

    collateralDepth = 8;
    collateralRatioFactor = COLLATERAL_RATIO_INIT;

    collateralRatio = 0;
    collateralRatioEmergency = collateralFactorMantissa
      .mul(COLLATERAL_RATIO_EMERGENCY)
      .div(1000);
    collateralRatioLimit = collateralFactorMantissa
      .mul(collateralRatioFactor)
      .div(1000);

    reserveRatio = 10;
  }

  /* ========== VIEW FUNCTIONS ========== */

  function totalSupply() external view override returns (uint256) {
    return totalShares;
  }

  function balance() public view override returns (uint256) {
    uint256 debtOfBank = bank == address(0) ? 0 : IBank(bank).debtToProviders();
    return balanceAvailable().add(venusSupply).sub(venusBorrow).add(debtOfBank);
  }

  function balanceAvailable() public view returns (uint256) {
    return venusBridge.availableOf(address(this));
  }

  function balanceReserved() public view returns (uint256) {
    return Math.min(balanceAvailable(), balance().mul(reserveRatio).div(1000));
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (totalShares == 0) return 0;
    return balance().mul(sharesOf(account)).div(totalShares);
  }

  function withdrawableBalanceOf(address account)
    public
    view
    override
    returns (uint256)
  {
    return balanceOf(account);
  }

  function sharesOf(address account) public view override returns (uint256) {
    return _shares[account];
  }

  function principalOf(address account) public view override returns (uint256) {
    return _principal[account];
  }

  function earned(address account) public view override returns (uint256) {
    uint256 accountBalance = balanceOf(account);
    uint256 accountPrincipal = principalOf(account);
    if (accountBalance >= accountPrincipal + DUST) {
      return accountBalance.sub(accountPrincipal);
    } else {
      return 0;
    }
  }

  function depositedAt(address account)
    external
    view
    override
    returns (uint256)
  {
    return _depositedAt[account];
  }

  function rewardsToken() external view override returns (address) {
    return address(_stakingToken);
  }

  function priceShare() external view override returns (uint256) {
    if (totalShares == 0) return 1e18;
    return balance().mul(1e18).div(totalShares);
  }

  function getUtilizationInfo()
    external
    view
    returns (uint256 liquidity, uint256 utilized)
  {
    liquidity = balance();
    utilized = balance().sub(balanceReserved());
  }

  function setCollateralFactors(
    uint256 _collateralRatioFactor,
    uint256 _collateralDepth
  ) external onlyOwner {
    require(
      _collateralRatioFactor < COLLATERAL_RATIO_EMERGENCY,
      'VenusVault: invalid collateral ratio factor'
    );

    collateralRatioFactor = _collateralRatioFactor;
    collateralDepth = _collateralDepth;
    _increaseCollateral(safeVenus.safeCompoundDepth(address(this)));
    emit CollateralFactorsUpdated(_collateralRatioFactor, _collateralDepth);
  }

  function setCollateralRatioSystem(uint256 _collateralRatioSystem)
    external
    onlyOwner
  {
    require(
      _collateralRatioSystem <= COLLATERAL_RATIO_SYSTEM_DEFAULT,
      'VenusVault: invalid collateral ratio system'
    );
    collateralRatioSystem = _collateralRatioSystem;
  }

  function setReserveRatio(uint256 _reserveRatio) external onlyOwner {
    require(_reserveRatio < 1000, 'VaultVenus: invalid reserve ratio');
    reserveRatio = _reserveRatio;
  }

  function setVenusExitRatio(uint256 _ratio) external onlyOwner {
    require(_ratio <= VENUS_EXIT_BASE);
    venusExitRatio = _ratio;
  }

  function setSafeVenus(address payable _safeVenus) public onlyOwner {
    safeVenus = SafeVenus(_safeVenus);
  }

  function setVenusBridge(address payable _venusBridge) public onlyOwner {
    venusBridge = VaultVenusBridge(_venusBridge);
  }

  function setBank(address newBank) external onlyOwner {
    require(address(bank) == address(0), 'VaultVenus: bank exists');
    bank = newBank;
  }

  function increaseCollateral() external onlyKeeper {
    _increaseCollateral(safeVenus.safeCompoundDepth(address(this)));
  }

  function decreaseCollateral(uint256 amountMin, uint256 supply)
    external
    payable
    onlyKeeper
  {
    updateVenusFactors();

    uint256 _balanceBefore = balance();

    supply = msg.value > 0 ? msg.value : supply;
    if (address(_stakingToken) == WBNB) {
      venusBridge.deposit{ value: supply }(address(this), supply);
    } else {
      _stakingToken.safeTransferFrom(msg.sender, address(venusBridge), supply);
      venusBridge.deposit(address(this), supply);
    }

    venusBridge.mint(balanceAvailable());
    _decreaseCollateral(amountMin);
    venusBridge.withdraw(msg.sender, supply);

    updateVenusFactors();
    uint256 _balanceAfter = balance();
    if (_balanceAfter < _balanceBefore && address(_stakingToken) != WBNB) {
      uint256 migrationCost = _balanceBefore.sub(_balanceAfter);
      _stakingToken.transferFrom(owner(), address(venusBridge), migrationCost);
      venusBridge.deposit(address(this), migrationCost);
    }
  }

  /* ========== BANKING FUNCTIONS ========== */

  function borrow(uint256 amount) external onlyBank returns (uint256) {
    updateVenusFactors();
    uint256 available = balanceAvailable();
    if (available < amount) {
      _decreaseCollateral(amount);
      available = balanceAvailable();
    }

    amount = Math.min(amount, available);
    venusBridge.withdraw(bank, amount);

    emit DebtAdded(bank, amount);
    return amount;
  }

  function repay() external payable onlyBank returns (uint256) {
    uint256 amount = msg.value;
    venusBridge.deposit{ value: amount }(address(this), amount);

    emit DebtRemoved(bank, amount);
    return amount;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function updateVenusFactors() public {
    (venusBorrow, venusSupply) = safeVenus.venusBorrowAndSupply(address(this));
    (, uint256 collateralFactorMantissa, ) = VENUS_UNITROLLER.markets(
      address(vToken)
    );
    collateralFactorMantissa = Math.min(
      collateralFactorMantissa,
      Math.min(collateralRatioSystem, COLLATERAL_RATIO_SYSTEM_DEFAULT)
    );
    collateralRatio = venusBorrow == 0
      ? 0
      : venusBorrow.mul(1e18).div(venusSupply);
    collateralRatioLimit = collateralFactorMantissa
      .mul(collateralRatioFactor)
      .div(1000);
    collateralRatioEmergency = collateralFactorMantissa
      .mul(COLLATERAL_RATIO_EMERGENCY)
      .div(1000);
  }

  function deposit(uint256 amount)
    public
    override
    accrueBank
    notPaused
    nonReentrant
  {
    require(address(_stakingToken) != WBNB, 'VaultVenus: invalid asset');
    updateVenusFactors(); // notice

    uint256 _balance = balance();
    uint256 _before = balanceAvailable();
    IBEP20(_stakingToken).safeTransferFrom(
      msg.sender,
      address(venusBridge),
      amount
    );
    venusBridge.deposit(address(this), amount);
    amount = balanceAvailable().sub(_before);

    uint256 shares = totalShares == 0
      ? amount
      : amount.mul(totalShares).div(_balance);
    if (address(_bunnyChef) != address(0)) {
      _bunnyChef.updateRewardsOf(address(this));
    }

    totalShares = totalShares.add(shares);
    _shares[msg.sender] = _shares[msg.sender].add(shares);
    _principal[msg.sender] = _principal[msg.sender].add(amount);
    _depositedAt[msg.sender] = block.timestamp;

    if (address(_bunnyChef) != address(0)) {
      _bunnyChef.notifyDeposited(msg.sender, shares);
    }
    emit Deposited(msg.sender, amount);
  }

  function depositAll() external override {
    deposit(_stakingToken.balanceOf(msg.sender));
  }

  function depositBNB() public payable accrueBank notPaused nonReentrant {
    require(address(_stakingToken) == WBNB, 'VaultVenus: invalid asset');
    updateVenusFactors();

    uint256 _balance = balance();
    uint256 amount = msg.value;
    venusBridge.deposit{ value: amount }(address(this), amount);

    uint256 shares = totalShares == 0
      ? amount
      : amount.mul(totalShares).div(_balance);
    if (address(_bunnyChef) != address(0)) {
      _bunnyChef.updateRewardsOf(address(this));
    }

    totalShares = totalShares.add(shares);
    _shares[msg.sender] = _shares[msg.sender].add(shares);
    _principal[msg.sender] = _principal[msg.sender].add(amount);
    _depositedAt[msg.sender] = block.timestamp;

    if (address(_bunnyChef) != address(0)) {
      _bunnyChef.notifyDeposited(msg.sender, shares);
    }
    emit Deposited(msg.sender, amount);
  }

  function withdrawAll() external override accrueBank {
    updateVenusFactors();
    uint256 amount = balanceOf(msg.sender);
    require(_hasSufficientBalance(amount), 'VaultVenus: insufficient balance');

    uint256 principal = principalOf(msg.sender);
    uint256 available = balanceAvailable();
    uint256 depositTimestamp = _depositedAt[msg.sender];
    if (available < amount) {
      _decreaseCollateral(_getBufferedAmountMin(amount));
      amount = balanceOf(msg.sender);
      available = balanceAvailable();
    }

    amount = Math.min(amount, available);
    uint256 shares = _shares[msg.sender];
    if (address(_bunnyChef) != address(0)) {
      _bunnyChef.notifyWithdrawn(msg.sender, shares);
      uint256 bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
      emit BunnyPaid(msg.sender, bunnyAmount, 0);
    }

    totalShares = totalShares.sub(shares);
    delete _shares[msg.sender];
    delete _principal[msg.sender];
    delete _depositedAt[msg.sender];

    uint256 profit = amount > principal ? amount.sub(principal) : 0;
    uint256 withdrawalFee = canMint()
      ? _minter.withdrawalFee(principal, depositTimestamp)
      : 0;
    uint256 performanceFee = canMint() ? _minter.performanceFee(profit) : 0;
    if (withdrawalFee.add(performanceFee) > DUST) {
      venusBridge.withdraw(address(this), withdrawalFee.add(performanceFee));
      if (address(_stakingToken) == WBNB) {
        _minter.mintFor{ value: withdrawalFee.add(performanceFee) }(
          address(0),
          withdrawalFee,
          performanceFee,
          msg.sender,
          depositTimestamp
        );
      } else {
        _minter.mintFor(
          address(_stakingToken),
          withdrawalFee,
          performanceFee,
          msg.sender,
          depositTimestamp
        );
      }

      if (performanceFee > 0) {
        emit ProfitPaid(msg.sender, profit, performanceFee);
      }
      amount = amount.sub(withdrawalFee).sub(performanceFee);
    }

    amount = _getAmountWithExitRatio(amount);
    venusBridge.withdraw(msg.sender, amount);
    if (collateralRatio > collateralRatioLimit) {
      _decreaseCollateral(0);
    }
    emit Withdrawn(msg.sender, amount, withdrawalFee);
  }

  function withdraw(uint256) external override {
    revert('N/A');
  }

  function withdrawUnderlying(uint256 _amount) external accrueBank {
    updateVenusFactors();
    uint256 amount = Math.min(_amount, _principal[msg.sender]);
    uint256 available = balanceAvailable();
    if (available < amount) {
      _decreaseCollateral(_getBufferedAmountMin(amount));
      available = balanceAvailable();
    }

    amount = Math.min(amount, available);
    uint256 shares = balance() == 0
      ? 0
      : Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
    if (address(_bunnyChef) != address(0)) {
      _bunnyChef.notifyWithdrawn(msg.sender, shares);
    }

    totalShares = totalShares.sub(shares);
    _shares[msg.sender] = _shares[msg.sender].sub(shares);
    _principal[msg.sender] = _principal[msg.sender].sub(amount);

    uint256 depositTimestamp = _depositedAt[msg.sender];
    uint256 withdrawalFee = canMint()
      ? _minter.withdrawalFee(amount, depositTimestamp)
      : 0;
    if (withdrawalFee > DUST) {
      venusBridge.withdraw(address(this), withdrawalFee);
      if (address(_stakingToken) == WBNB) {
        _minter.mintFor{ value: withdrawalFee }(
          address(0),
          withdrawalFee,
          0,
          msg.sender,
          depositTimestamp
        );
      } else {
        _minter.mintFor(
          address(_stakingToken),
          withdrawalFee,
          0,
          msg.sender,
          depositTimestamp
        );
      }
      amount = amount.sub(withdrawalFee);
    }

    amount = _getAmountWithExitRatio(amount);
    venusBridge.withdraw(msg.sender, amount);
    if (collateralRatio >= collateralRatioLimit) {
      _decreaseCollateral(0);
    }
    emit Withdrawn(msg.sender, amount, withdrawalFee);
  }

  function getReward() public override accrueBank nonReentrant {
    updateVenusFactors();
    uint256 amount = earned(msg.sender);
    uint256 available = balanceAvailable();
    if (available < amount) {
      _decreaseCollateral(_getBufferedAmountMin(amount));
      amount = earned(msg.sender);
      available = balanceAvailable();
    }

    amount = Math.min(amount, available);
    if (address(_bunnyChef) != address(0)) {
      uint256 bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
      emit BunnyPaid(msg.sender, bunnyAmount, 0);
    }

    uint256 shares = balance() == 0
      ? 0
      : Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
    if (address(_bunnyChef) != address(0)) {
      _bunnyChef.notifyWithdrawn(msg.sender, shares);
    }

    totalShares = totalShares.sub(shares);
    _shares[msg.sender] = _shares[msg.sender].sub(shares);

    // cleanup dust
    if (_shares[msg.sender] > 0 && _shares[msg.sender] < DUST) {
      if (address(_bunnyChef) != address(0)) {
        _bunnyChef.notifyWithdrawn(msg.sender, _shares[msg.sender]);
      }
      totalShares = totalShares.sub(_shares[msg.sender]);
      delete _shares[msg.sender];
    }

    uint256 depositTimestamp = _depositedAt[msg.sender];
    uint256 performanceFee = canMint() ? _minter.performanceFee(amount) : 0;
    if (performanceFee > DUST) {
      venusBridge.withdraw(address(this), performanceFee);
      if (address(_stakingToken) == WBNB) {
        _minter.mintFor{ value: performanceFee }(
          address(0),
          0,
          performanceFee,
          msg.sender,
          depositTimestamp
        );
      } else {
        _minter.mintFor(
          address(_stakingToken),
          0,
          performanceFee,
          msg.sender,
          depositTimestamp
        );
      }
      amount = amount.sub(performanceFee);
    }

    amount = _getAmountWithExitRatio(amount);
    venusBridge.withdraw(msg.sender, amount);
    if (collateralRatio >= collateralRatioLimit) {
      _decreaseCollateral(0);
    }
    emit ProfitPaid(msg.sender, amount, performanceFee);
  }

  function harvest() public override accrueBank notPaused onlyKeeper {
    VENUS_BRIDGE_OWNER.harvestBehalf(address(this));
    _increaseCollateral(3);
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _hasSufficientBalance(uint256 amount) private view returns (bool) {
    return balanceAvailable().add(venusSupply).sub(venusBorrow) >= amount;
  }

  function _getBufferedAmountMin(uint256 amount)
    private
    view
    returns (uint256)
  {
    return venusExitRatio > 0 ? amount.mul(1005).div(1000) : amount;
  }

  function _getAmountWithExitRatio(uint256 amount)
    private
    view
    returns (uint256)
  {
    uint256 redeemFee = amount.mul(1005).mul(venusExitRatio).div(1000).div(
      VENUS_EXIT_BASE
    );
    return amount.sub(redeemFee);
  }

  function _increaseCollateral(uint256 compound) private {
    updateVenusFactors();
    (uint256 mintable, uint256 mintableInUSD) = safeVenus.safeMintAmount(
      address(this)
    );
    if (mintableInUSD > 1e18) {
      venusBridge.mint(2);
    }

    updateVenusFactors();
    uint256 borrowable = safeVenus.safeBorrowAmount(address(this));
    while (!paused && compound > 0 && borrowable > 0.000001 ether) {
      if (borrowable == 0 || collateralRatio >= collateralRatioLimit) {
        return;
      }

      venusBridge.borrow(borrowable);
      updateVenusFactors();
      (mintable, mintableInUSD) = safeVenus.safeMintAmount(address(this));
      if (mintableInUSD > 1e18) {
        venusBridge.mint(mintable);
      }

      updateVenusFactors();
      borrowable = safeVenus.safeBorrowAmount(address(this));
      compound--;
    }
  }

  function _decreaseCollateral(uint256 amountMin) private {
    updateVenusFactors();

    uint256 marketSupply = vToken
      .totalSupply()
      .mul(vToken.exchangeRateCurrent())
      .div(1e18);
    uint256 marketLiquidity = marketSupply > vToken.totalBorrowsCurrent()
      ? marketSupply.sub(vToken.totalBorrowsCurrent())
      : 0;
    require(
      marketLiquidity >= amountMin,
      'VaultVenus: not enough market liquidity'
    );

    if (
      amountMin != uint256(-1) &&
      collateralRatio == 0 &&
      collateralRatioLimit == 0
    ) {
      venusBridge.redeemUnderlying(Math.min(venusSupply, amountMin));
      updateVenusFactors();
    } else {
      uint256 redeemable = safeVenus.safeRedeemAmount(address(this));
      while (venusBorrow > 0 && redeemable > 0) {
        uint256 redeemAmount = amountMin > 0
          ? Math.min(venusSupply, Math.min(redeemable, amountMin))
          : Math.min(venusSupply, redeemable);
        venusBridge.redeemUnderlying(redeemAmount);
        venusBridge.repayBorrow(Math.min(venusBorrow, balanceAvailable()));
        updateVenusFactors();

        redeemable = safeVenus.safeRedeemAmount(address(this));
        uint256 available = balanceAvailable().add(redeemable);
        if (collateralRatio <= collateralRatioLimit && available >= amountMin) {
          uint256 remain = amountMin > balanceAvailable()
            ? amountMin.sub(balanceAvailable())
            : 0;
          if (remain > 0) {
            venusBridge.redeemUnderlying(Math.min(remain, redeemable));
          }
          updateVenusFactors();
          return;
        }
      }

      if (amountMin == uint256(-1) && venusBorrow == 0) {
        venusBridge.redeemAll();
        updateVenusFactors();
      }
    }
  }

  /* ========== SALVAGE PURPOSE ONLY ========== */

  function recoverToken(address tokenAddress, uint256 tokenAmount)
    external
    override
    onlyOwner
  {
    require(
      tokenAddress != address(0) &&
        tokenAddress != address(_stakingToken) &&
        tokenAddress != address(vToken) &&
        tokenAddress != XVS,
      'VaultVenus: cannot recover token'
    );

    IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract PausableUpgradeable is OwnableUpgradeable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "PausableUpgradeable: cannot be performed while the contract is paused");
        _;
    }

    function __PausableUpgradeable_init() internal initializer {
        __Ownable_init();
        require(owner() != address(0), "PausableUpgradeable: owner must be set");
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;
        if (paused) {
            lastPauseTime = now;
        }

        emit PauseChanged(paused);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract WhitelistUpgradeable is OwnableUpgradeable {
  mapping(address => bool) private _whitelist;
  bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

  event Whitelisted(address indexed _address, bool whitelist);
  event EnableWhitelist();
  event DisableWhitelist();

  modifier onlyWhitelisted() {
    require(
      _disable || _whitelist[msg.sender],
      'Whitelist: caller is not on the whitelist'
    );
    _;
  }

  function __WhitelistUpgradeable_init() internal initializer {
    __Ownable_init();
  }

  function isWhitelist(address _address) public view returns (bool) {
    return _whitelist[_address];
  }

  function setWhitelist(address _address, bool _on) external onlyOwner {
    _whitelist[_address] = _on;

    emit Whitelisted(_address, _on);
  }

  function disableWhitelist(bool disable) external onlyOwner {
    _disable = disable;
    if (disable) {
      emit DisableWhitelist();
    } else {
      emit EnableWhitelist();
    }
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import './IPancakeRouter01.sol';

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

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import '@openzeppelin/contracts/math/Math.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './SafeDecimal.sol';
import '../interfaces/IPriceCalculator.sol';
import '../interfaces/IVenusDistribution.sol';
import '../interfaces/IVenusPriceOracle.sol';
import '../interfaces/IVToken.sol';
import '../interfaces/IVaultVenusBridge.sol';

import '../vaults/venus/VaultVenus.sol';

contract SafeVenus is OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeDecimal for uint256;

  IPriceCalculator private constant PRICE_CALCULATOR =
    IPriceCalculator(0xF5BF8A9249e3cc4cB684E3f23db9669323d4FB7d); //
  IVenusDistribution private constant VENUS_UNITROLLER =
    IVenusDistribution(0x94d1820b2D1c7c7452A163983Dc888CEC546b77D);

  address private constant XVS = 0xB9e0E753630434d7863528cc73CB7AC638a7c8ff;
  uint256 private constant BLOCK_PER_DAY = 28800;

  /* ========== INITIALIZER ========== */

  function initialize() external initializer {
    __Ownable_init();
  }

  function valueOfUnderlying(IVToken vToken, uint256 amount)
    internal
    view
    returns (uint256)
  {
    IVenusPriceOracle venusOracle = IVenusPriceOracle(
      VENUS_UNITROLLER.oracle()
    );
    return venusOracle.getUnderlyingPrice(vToken).mul(amount).div(1e18);
  }

  /* ========== safeMintAmount ========== */

  function safeMintAmount(address payable vault)
    public
    view
    returns (uint256 mintable, uint256 mintableInUSD)
  {
    VaultVenus vaultVenus = VaultVenus(vault);
    mintable = vaultVenus.balanceAvailable().sub(vaultVenus.balanceReserved());
    mintableInUSD = valueOfUnderlying(vaultVenus.vToken(), mintable);
  }

  /* ========== safeBorrowAndRedeemAmount ========== */

  function safeBorrowAndRedeemAmount(address payable vault)
    public
    returns (uint256 borrowable, uint256 redeemable)
  {
    VaultVenus vaultVenus = VaultVenus(vault);
    uint256 collateralRatioLimit = vaultVenus.collateralRatioLimit();

    (, uint256 accountLiquidityInUSD, ) = VENUS_UNITROLLER.getAccountLiquidity(
      address(vaultVenus.venusBridge())
    );
    uint256 stakingTokenPriceInUSD = valueOfUnderlying(
      vaultVenus.vToken(),
      1e18
    );
    uint256 safeLiquidity = accountLiquidityInUSD
      .mul(1e18)
      .div(stakingTokenPriceInUSD)
      .mul(990)
      .div(1000);

    (uint256 accountBorrow, uint256 accountSupply) = venusBorrowAndSupply(
      vault
    );
    uint256 supplyFactor = collateralRatioLimit.mul(accountSupply).div(1e18);
    uint256 borrowAmount = supplyFactor > accountBorrow
      ? supplyFactor.sub(accountBorrow).mul(1e18).div(
        uint256(1e18).sub(collateralRatioLimit)
      )
      : 0;
    uint256 redeemAmount = accountBorrow > supplyFactor
      ? accountBorrow.sub(supplyFactor).mul(1e18).div(
        uint256(1e18).sub(collateralRatioLimit)
      )
      : uint256(-1);
    return (
      Math.min(borrowAmount, safeLiquidity),
      Math.min(redeemAmount, safeLiquidity)
    );
  }

  function safeBorrowAmount(address payable vault)
    public
    returns (uint256 borrowable)
  {
    VaultVenus vaultVenus = VaultVenus(vault);
    IVToken vToken = vaultVenus.vToken();
    uint256 collateralRatioLimit = vaultVenus.collateralRatioLimit();
    uint256 stakingTokenPriceInUSD = valueOfUnderlying(vToken, 1e18);

    (, uint256 accountLiquidityInUSD, ) = VENUS_UNITROLLER.getAccountLiquidity(
      address(vaultVenus.venusBridge())
    );
    uint256 accountLiquidity = accountLiquidityInUSD.mul(1e18).div(
      stakingTokenPriceInUSD
    );
    uint256 marketSupply = vToken
      .totalSupply()
      .mul(vToken.exchangeRateCurrent())
      .div(1e18);
    uint256 marketLiquidity = marketSupply > vToken.totalBorrowsCurrent()
      ? marketSupply.sub(vToken.totalBorrowsCurrent())
      : 0;
    uint256 safeLiquidity = Math
      .min(marketLiquidity, accountLiquidity)
      .mul(990)
      .div(1000);

    (uint256 accountBorrow, uint256 accountSupply) = venusBorrowAndSupply(
      vault
    );
    uint256 supplyFactor = collateralRatioLimit.mul(accountSupply).div(1e18);
    uint256 borrowAmount = supplyFactor > accountBorrow
      ? supplyFactor.sub(accountBorrow).mul(1e18).div(
        uint256(1e18).sub(collateralRatioLimit)
      )
      : 0;
    return Math.min(borrowAmount, safeLiquidity);
  }

  function safeRedeemAmount(address payable vault)
    public
    returns (uint256 redeemable)
  {
    VaultVenus vaultVenus = VaultVenus(vault);
    IVToken vToken = vaultVenus.vToken();

    (, uint256 collateralFactorMantissa, ) = VENUS_UNITROLLER.markets(
      address(vToken)
    );
    uint256 collateralRatioLimit = collateralFactorMantissa
      .mul(vaultVenus.collateralRatioFactor())
      .div(1000);
    uint256 stakingTokenPriceInUSD = valueOfUnderlying(vToken, 1e18);

    (, uint256 accountLiquidityInUSD, ) = VENUS_UNITROLLER.getAccountLiquidity(
      address(vaultVenus.venusBridge())
    );
    uint256 accountLiquidity = accountLiquidityInUSD.mul(1e18).div(
      stakingTokenPriceInUSD
    );
    uint256 marketSupply = vToken
      .totalSupply()
      .mul(vToken.exchangeRateCurrent())
      .div(1e18);
    uint256 marketLiquidity = marketSupply > vToken.totalBorrowsCurrent()
      ? marketSupply.sub(vToken.totalBorrowsCurrent())
      : 0;
    uint256 safeLiquidity = Math
      .min(marketLiquidity, accountLiquidity)
      .mul(990)
      .div(1000);

    (uint256 accountBorrow, uint256 accountSupply) = venusBorrowAndSupply(
      vault
    );
    uint256 supplyFactor = collateralRatioLimit.mul(accountSupply).div(1e18);
    uint256 redeemAmount = accountBorrow > supplyFactor
      ? accountBorrow.sub(supplyFactor).mul(1e18).div(
        uint256(1e18).sub(collateralRatioLimit)
      )
      : uint256(-1);
    return Math.min(redeemAmount, safeLiquidity);
  }

  function venusBorrowAndSupply(address payable vault)
    public
    returns (uint256 borrow, uint256 supply)
  {
    VaultVenus vaultVenus = VaultVenus(vault);
    borrow = vaultVenus.vToken().borrowBalanceCurrent(
      address(vaultVenus.venusBridge())
    );
    supply = IVaultVenusBridge(vaultVenus.venusBridge()).balanceOfUnderlying(
      vault
    );
  }

  /* ========== safeCompoundDepth ========== */

  function safeCompoundDepth(address payable vault) public returns (uint256) {
    VaultVenus vaultVenus = VaultVenus(vault);
    IVToken vToken = vaultVenus.vToken();
    address stakingToken = vaultVenus.stakingToken();

    (uint256 apyBorrow, bool borrowWithDebt) = _venusAPYBorrow(
      vToken,
      stakingToken
    );
    return 1;
    // return
    //   borrowWithDebt &&
    //     _venusAPYSupply(vToken, stakingToken) <= apyBorrow + 2e15
    //     ? 0
    //     : vaultVenus.collateralDepth();
  }

  function _venusAPYBorrow(IVToken vToken, address stakingToken)
    private
    returns (uint256 apy, bool borrowWithDebt)
  {
    (, uint256 xvsValueInUSD) = PRICE_CALCULATOR.valueOfAsset(
      XVS,
      VENUS_UNITROLLER.venusSpeeds(address(vToken)).mul(BLOCK_PER_DAY)
    );
    (, uint256 borrowValueInUSD) = PRICE_CALCULATOR.valueOfAsset(
      stakingToken,
      vToken.totalBorrowsCurrent()
    );

    uint256 apyBorrow = vToken
      .borrowRatePerBlock()
      .mul(BLOCK_PER_DAY)
      .add(1e18)
      .power(365)
      .sub(1e18);
    uint256 apyBorrowXVS = xvsValueInUSD
      .mul(1e18)
      .div(borrowValueInUSD)
      .add(1e18)
      .power(365)
      .sub(1e18);
    apy = apyBorrow > apyBorrowXVS
      ? apyBorrow.sub(apyBorrowXVS)
      : apyBorrowXVS.sub(apyBorrow);
    borrowWithDebt = apyBorrow > apyBorrowXVS;
  }

  function _venusAPYSupply(IVToken vToken, address stakingToken)
    private
    returns (uint256 apy)
  {
    (, uint256 xvsValueInUSD) = PRICE_CALCULATOR.valueOfAsset(
      XVS,
      VENUS_UNITROLLER.venusSpeeds(address(vToken)).mul(BLOCK_PER_DAY)
    );
    (, uint256 supplyValueInUSD) = PRICE_CALCULATOR.valueOfAsset(
      stakingToken,
      vToken.totalSupply().mul(vToken.exchangeRateCurrent()).div(1e18)
    );

    uint256 apySupply = vToken
      .supplyRatePerBlock()
      .mul(BLOCK_PER_DAY)
      .add(1e18)
      .power(365)
      .sub(1e18);
    uint256 apySupplyXVS = xvsValueInUSD
      .mul(1e18)
      .div(supplyValueInUSD)
      .add(1e18)
      .power(365)
      .sub(1e18);
    apy = apySupply.add(apySupplyXVS);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import './IStrategyCompact.sol';

interface IStrategy is IStrategyCompact {
  // rewardsToken
  function sharesOf(address account) external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  /* ========== Interface ========== */

  function depositAll() external;

  function withdrawAll() external;

  function getReward() external;

  function harvest() external;

  function pid() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function poolType() external view returns (PoolConstant.PoolTypes);

  event Deposited(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount, uint256 withdrawalFee);
  event ProfitPaid(
    address indexed user,
    uint256 profit,
    uint256 performanceFee
  );
  event BunnyPaid(address indexed user, uint256 profit, uint256 performanceFee);
  event Harvested(uint256 profit);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';

interface IVToken is IBEP20 {
  function underlying() external returns (address);

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVenusDistribution {
  function oracle() external view returns (address);

  function enterMarkets(address[] memory _vtokens) external;

  function exitMarket(address _vtoken) external;

  function getAssetsIn(address account)
    external
    view
    returns (address[] memory);

  function markets(address vTokenAddress)
    external
    view
    returns (
      bool,
      uint256,
      bool
    );

  function getAccountLiquidity(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function claimVenus(address holder, address[] memory vTokens) external;

  function venusSpeeds(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

interface IVaultVenusBridge {
  struct MarketInfo {
    address token;
    address vToken;
    uint256 available;
    uint256 vTokenAmount;
  }

  function infoOf(address vault) external view returns (MarketInfo memory);

  function availableOf(address vault) external view returns (uint256);

  function migrateTo(address payable target) external;

  function deposit(address vault, uint256 amount) external payable;

  function withdraw(address account, uint256 amount) external;

  function harvest() external;

  function balanceOfUnderlying(address vault) external returns (uint256);

  function mint(uint256 amount) external;

  function redeemUnderlying(uint256 amount) external;

  function redeemAll() external;

  function borrow(uint256 amount) external;

  function repayBorrow(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';

import '../interfaces/IPancakeRouter02.sol';
import '../interfaces/IPancakePair.sol';
import '../interfaces/IStrategy.sol';
import '../interfaces/IMasterChef.sol';
import '../interfaces/IGoenMinterV2.sol';
import '../interfaces/IGoenChef.sol';
import '../library/PausableUpgradeable.sol';
import '../library/WhitelistUpgradeable.sol';

abstract contract VaultController is
  IVaultController,
  PausableUpgradeable,
  WhitelistUpgradeable
{
  using SafeBEP20 for IBEP20;

  /* ========== CONSTANT VARIABLES ========== */
  BEP20 private constant GOEN =
    BEP20(0xa093D11E9B4aB850B77f64307F55640A75c580d2);

  /* ========== STATE VARIABLES ========== */

  address public keeper;
  IBEP20 internal _stakingToken;
  IGoenMinterV2 internal _minter;
  IGoenChef internal _bunnyChef;

  /* ========== VARIABLE GAP ========== */

  uint256[49] private __gap;

  /* ========== Event ========== */

  event Recovered(address token, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier onlyKeeper() {
    require(
      msg.sender == keeper || msg.sender == owner(),
      'VaultController: caller is not the owner or keeper'
    );
    _;
  }

  /* ========== INITIALIZER ========== */

  function __VaultController_init(IBEP20 token) internal initializer {
    __PausableUpgradeable_init();
    __WhitelistUpgradeable_init();

    keeper = 0xce2Be8b93E2d832b51C7a5dd296FAC6c39a67872;
    _stakingToken = token;
  }

  /* ========== VIEWS FUNCTIONS ========== */

  function minter() external view override returns (address) {
    return canMint() ? address(_minter) : address(0);
  }

  function canMint() internal view returns (bool) {
    return address(_minter) != address(0) && _minter.isMinter(address(this));
  }

  function bunnyChef() external view override returns (address) {
    return address(_bunnyChef);
  }

  function stakingToken() external view override returns (address) {
    return address(_stakingToken);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setKeeper(address _keeper) external onlyKeeper {
    require(_keeper != address(0), 'VaultController: invalid keeper address');
    keeper = _keeper;
  }

  function setMinter(address newMinter) public virtual onlyOwner {
    // can zero
    if (newMinter != address(0)) {
      require(newMinter == GOEN.getOwner(), 'VaultController: not goen minter');
      _stakingToken.safeApprove(newMinter, 0);
      _stakingToken.safeApprove(newMinter, uint256(-1));
    }
    if (address(_minter) != address(0))
      _stakingToken.safeApprove(address(_minter), 0);
    _minter = IGoenMinterV2(newMinter);
  }

  function setBunnyChef(IGoenChef newBunnyChef) public virtual onlyOwner {
    require(
      address(_bunnyChef) == address(0),
      'VaultController: setBunnyChef only once'
    );
    _bunnyChef = newBunnyChef;
  }

  /* ========== SALVAGE PURPOSE ONLY ========== */

  function recoverToken(address _token, uint256 amount)
    external
    virtual
    onlyOwner
  {
    require(
      _token != address(_stakingToken),
      'VaultController: cannot recover underlying token'
    );
    IBEP20(_token).safeTransfer(owner(), amount);

    emit Recovered(_token, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '../../library/WhitelistUpgradeable.sol';
import '../../library/SafeToken.sol';

import '../../interfaces/IPancakeRouter02.sol';
import '../../interfaces/IVenusDistribution.sol';
import './VaultVenusBridge.sol';

contract VaultVenusBridgeOwner is WhitelistUpgradeable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  IPancakeRouter02 private constant PANCAKE_ROUTER =
    IPancakeRouter02(0xaa200B43D5b3337E30bFEA24f0B5eC03c795a9c2);
  IVenusDistribution private constant VENUS_UNITROLLER =
    IVenusDistribution(0x94d1820b2D1c7c7452A163983Dc888CEC546b77D);
  VaultVenusBridge private constant VENUS_BRIDGE =
    VaultVenusBridge(0xd08eC332eD0e1B0aE9133A08d2073fA2eb62595b);

  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address private constant BUSD = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;

  IBEP20 private constant XVS =
    IBEP20(0xB9e0E753630434d7863528cc73CB7AC638a7c8ff);
  IBEP20 private constant vBUSD =
    IBEP20(0x08e0A5575De71037aE36AbfAfb516595fE68e5e4);

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  function initialize() external initializer {
    __WhitelistUpgradeable_init();
    XVS.safeApprove(address(PANCAKE_ROUTER), uint256(-1));
    vBUSD.safeApprove(address(PANCAKE_ROUTER), uint256(-1));
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addVaultBehalf(
    address vault,
    address token,
    address vToken
  ) public onlyOwner {
    VENUS_BRIDGE.addVault(vault, token, vToken);
    VENUS_BRIDGE.setWhitelist(vault, true);
  }

  function setWhitelistBehalf(address _address, bool _on) external onlyOwner {
    VENUS_BRIDGE.setWhitelist(_address, _on);
  }

  function deposit(address vault, uint256 amount) external payable onlyOwner {
    VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
    address[] memory vTokens = new address[](1);
    vTokens[0] = market.vToken;
    if (market.token == WBNB) {
      amount = msg.value;
      VENUS_BRIDGE.deposit{ value: amount }(vault, amount);
    } else {
      IBEP20(market.token).safeTransferFrom(
        owner(),
        address(VENUS_BRIDGE),
        amount
      );
      VENUS_BRIDGE.deposit(vault, amount);
    }
  }

  function getMarket(address vault) public view returns (address marketToken) {
    VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
    address[] memory vTokens = new address[](1);
    return market.vToken;
  }

  uint96 public testAmount;

  function setTestXVSClaim(uint96 _testAmount) public {
    testAmount = _testAmount;
  }

  function harvestBehalf(address vault) public returns (uint256 XVSBalance) {
    VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
    address[] memory vTokens = new address[](1);
    vTokens[0] = market.vToken;

    uint256 xvsBefore = XVS.balanceOf(address(VENUS_BRIDGE));
    uint256 vBUSDBefore = vTokens[0].balanceOf(address(VENUS_BRIDGE));

    VENUS_UNITROLLER.claimVenus(address(VENUS_BRIDGE), vTokens);
    uint256 xvsBalance = XVS.balanceOf(address(VENUS_BRIDGE)).sub(xvsBefore);
    uint256 vBUSDBalance = vTokens[0].balanceOf(address(VENUS_BRIDGE)).sub(
      vBUSDBefore
    );
    xvsBalance = 10000;
    if (xvsBalance > 0) {
      VENUS_BRIDGE.recoverToken(address(XVS), xvsBalance);
      if (market.token == BUSD) {
        uint256 swapBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(XVS);
        path[1] = WBNB;
        PANCAKE_ROUTER.swapExactTokensForETH(
          xvsBalance,
          0,
          path,
          address(this),
          block.timestamp
        );

        uint256 swapAmount = address(this).balance.sub(swapBefore);
        SafeToken.safeTransferETH(address(VENUS_BRIDGE), swapAmount);
        // VENUS_BRIDGE.deposit{ value: swapAmount }(vault, swapAmount);
      }
    }
    if (vBUSDBalance > 0) {
      VENUS_BRIDGE.recoverToken(address(vTokens[0]), vBUSDBalance);
      if (market.token == BUSD) {
        uint256 swapBefore = address(this).balance;
        address[] memory pathVToken = new address[](2);
        pathVToken[0] = address(vTokens[0]);
        pathVToken[1] = WBNB;
        PANCAKE_ROUTER.swapExactTokensForETH(
          vBUSDBalance,
          0,
          pathVToken,
          address(this),
          block.timestamp
        );

        uint256 swapAmount = address(this).balance.sub(swapBefore);
        SafeToken.safeTransferETH(
          address(VENUS_BRIDGE),
          swapAmount.mul(95).div(100)
        );
        // VENUS_BRIDGE.deposit{ value: swapAmount }(vault, swapAmount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';

import '../../library/SafeToken.sol';
import '../../library/Whitelist.sol';
import '../../library/Exponential.sol';

import '../../interfaces/IVaultVenusBridge.sol';
import '../../interfaces/IPancakeRouter02.sol';
import '../../interfaces/IVenusDistribution.sol';
import '../../interfaces/IVBNB.sol';
import '../../interfaces/IVToken.sol';

contract VaultVenusBridge is Whitelist, Exponential, IVaultVenusBridge {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  IPancakeRouter02 private constant PANCAKE_ROUTER =
    IPancakeRouter02(0xaa200B43D5b3337E30bFEA24f0B5eC03c795a9c2);
  IVenusDistribution private constant VENUS_UNITROLLER =
    IVenusDistribution(0x94d1820b2D1c7c7452A163983Dc888CEC546b77D);

  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address private constant BUSD = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;
  IBEP20 private constant XVS =
    IBEP20(0xB9e0E753630434d7863528cc73CB7AC638a7c8ff);
  IBEP20 private constant vBUSD =
    IBEP20(0x08e0A5575De71037aE36AbfAfb516595fE68e5e4);
  IVBNB public constant vBNB =
    IVBNB(0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c);

  /* ========== STATE VARIABLES ========== */

  MarketInfo[] private _marketList;
  mapping(address => MarketInfo) markets;

  /* ========== EVENTS ========== */

  event Recovered(address token, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier updateAvailable(address vault) {
    MarketInfo storage market = markets[vault];
    uint256 tokenBalanceBefore = market.token != WBNB
      ? IBEP20(market.token).balanceOf(address(this))
      : address(this).balance;
    uint256 vTokenAmountBefore = IBEP20(market.vToken).balanceOf(address(this));

    _;

    uint256 tokenBalance = market.token != WBNB
      ? IBEP20(market.token).balanceOf(address(this))
      : address(this).balance;
    uint256 vTokenAmount = IBEP20(market.vToken).balanceOf(address(this));
    market.available = market.available.add(tokenBalance).sub(
      tokenBalanceBefore
    );
    market.vTokenAmount = market.vTokenAmount.add(vTokenAmount).sub(
      vTokenAmountBefore
    );
  }

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  constructor() public {
    XVS.safeApprove(address(PANCAKE_ROUTER), uint256(-1));
    vBUSD.safeApprove(address(PANCAKE_ROUTER), uint256(-1));
  }

  /* ========== VIEW FUNCTIONS ========== */

  function infoOf(address vault)
    public
    view
    override
    returns (MarketInfo memory)
  {
    return markets[vault];
  }

  function availableOf(address vault) public view override returns (uint256) {
    return markets[vault].available;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addVault(
    address vault,
    address token,
    address vToken
  ) public onlyOwner {
    require(
      markets[vault].token == address(0),
      'VaultVenusBridge: vault is already set'
    );
    require(
      token != address(0) && vToken != address(0),
      'VaultVenusBridge: invalid tokens'
    );

    MarketInfo memory market = MarketInfo(token, vToken, 0, 0);
    _marketList.push(market);
    markets[vault] = market;

    IBEP20(token).safeApprove(address(PANCAKE_ROUTER), uint256(-1));
    IBEP20(token).safeApprove(vToken, uint256(-1));

    address[] memory venusMarkets = new address[](1);
    venusMarkets[0] = vToken;
    VENUS_UNITROLLER.enterMarkets(venusMarkets);
  }

  function migrateTo(address payable target) external override {
    MarketInfo storage market = markets[msg.sender];
    IVaultVenusBridge newBridge = IVaultVenusBridge(target);

    if (market.token == WBNB) {
      newBridge.deposit{ value: market.available }(
        msg.sender,
        market.available
      );
    } else {
      IBEP20 token = IBEP20(market.token);
      token.safeApprove(address(newBridge), uint256(-1));
      token.safeTransfer(address(newBridge), market.available);
      token.safeApprove(address(newBridge), 0);
      newBridge.deposit(msg.sender, market.available);
    }
    market.available = 0;
    market.vTokenAmount = 0;
  }

  function deposit(address vault, uint256 amount) external payable override {
    MarketInfo storage market = markets[vault];
    market.available = market.available.add(msg.value > 0 ? msg.value : amount);
  }

  function withdraw(address account, uint256 amount) external override {
    MarketInfo storage market = markets[msg.sender];
    market.available = market.available.sub(amount);
    if (market.token == WBNB || market.token == BUSD) {
      SafeToken.safeTransferETH(account, amount);
    } else {
      IBEP20(market.token).safeTransfer(account, amount);
    }
  }

  function harvest() public override updateAvailable(msg.sender) {
    MarketInfo memory market = markets[msg.sender];

    address[] memory vTokens = new address[](1);
    vTokens[0] = market.vToken;

    uint256 before = XVS.balanceOf(address(this));
    uint256 vBUSDBefore = vTokens[0].balanceOf(address(this));

    VENUS_UNITROLLER.claimVenus(address(this), vTokens);
    uint256 vBUSDBalance = vTokens[0].balanceOf(address(this)).sub(vBUSDBefore);
    uint256 xvsBalance = XVS.balanceOf(address(this)).sub(before);
    if (xvsBalance > 0) {
      if (market.token == BUSD) {
        address[] memory path = new address[](2);
        path[0] = address(XVS);
        path[1] = WBNB;
        PANCAKE_ROUTER.swapExactTokensForETH(
          xvsBalance,
          0,
          path,
          address(this),
          block.timestamp
        );
      }
    }
    if (vBUSDBalance > 0) {
      if (market.token == BUSD) {
        address[] memory pathVToken = new address[](2);
        pathVToken[0] = address(vTokens[0]);
        pathVToken[1] = WBNB;
        PANCAKE_ROUTER.swapExactTokensForETH(
          vBUSDBalance,
          0,
          pathVToken,
          address(this),
          block.timestamp
        );
      }
    }
  }

  function balanceOfUnderlying(address vault)
    external
    override
    returns (uint256)
  {
    MarketInfo memory market = markets[vault];
    Exp memory exchangeRate = Exp({
      mantissa: IVToken(market.vToken).exchangeRateCurrent()
    });
    (MathError mErr, uint256 balance) = mulScalarTruncate(
      exchangeRate,
      market.vTokenAmount
    );
    require(mErr == MathError.NO_ERROR, 'balance could not be calculated');
    return balance;
  }

  /* ========== VENUS FUNCTIONS ========== */

  function mint(uint256 amount) external override updateAvailable(msg.sender) {
    MarketInfo memory market = markets[msg.sender];
    if (market.token == WBNB) {
      vBNB.mint{ value: amount }();
    } else {
      IVToken(market.vToken).mint(amount);
    }
  }

  function redeemUnderlying(uint256 amount)
    external
    override
    updateAvailable(msg.sender)
  {
    MarketInfo memory market = markets[msg.sender];
    IVToken vToken = IVToken(market.vToken);
    vToken.redeemUnderlying(amount);
  }

  function redeemAll() external override updateAvailable(msg.sender) {
    MarketInfo memory market = markets[msg.sender];
    IVToken vToken = IVToken(market.vToken);
    vToken.redeem(market.vTokenAmount);
  }

  function borrow(uint256 amount)
    external
    override
    updateAvailable(msg.sender)
  {
    MarketInfo memory market = markets[msg.sender];
    IVToken vToken = IVToken(market.vToken);
    vToken.borrow(amount);
  }

  function repayBorrow(uint256 amount)
    external
    override
    updateAvailable(msg.sender)
  {
    MarketInfo memory market = markets[msg.sender];
    if (market.vToken == address(vBNB)) {
      vBNB.repayBorrow{ value: amount }();
    } else {
      IVToken(market.vToken).repayBorrow(amount);
    }
  }

  function recoverToken(address token, uint256 amount) external onlyOwner {
    // case0) WBNB salvage
    if (token == WBNB && IBEP20(WBNB).balanceOf(address(this)) >= amount) {
      IBEP20(token).safeTransfer(owner(), amount);
      emit Recovered(token, amount);
      return;
    }

    // case1) vault token - WBNB=>BNB
    for (uint256 i = 0; i < _marketList.length; i++) {
      MarketInfo memory market = _marketList[i];

      if (market.vToken == token) {
        revert('VaultVenusBridge: cannot recover');
      }

      if (market.token == token) {
        uint256 balance = token == WBNB
          ? address(this).balance
          : IBEP20(token).balanceOf(address(this));
        require(
          balance.sub(market.available) >= amount,
          'VaultVenusBridge: cannot recover'
        );

        if (token == WBNB) {
          SafeToken.safeTransferETH(owner(), amount);
        } else {
          IBEP20(token).safeTransfer(owner(), amount);
        }

        emit Recovered(token, amount);
        return;
      }
    }

    // case2) not vault token
    IBEP20(token).safeTransfer(owner(), amount);
    emit Recovered(token, amount);
  }
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";


library SafeDecimal {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint public constant UNIT = 10 ** uint(decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function multiply(uint x, uint y) internal pure returns (uint) {
        return x.mul(y).div(UNIT);
    }

    // https://mpark.github.io/programming/2014/08/18/exponentiation-by-squaring/
    function power(uint x, uint n) internal pure returns (uint) {
        uint result = UNIT;
        while (n > 0) {
            if (n % 2 != 0) {
                result = multiply(result, x);
            }
            x = multiply(x, x);
            n /= 2;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPriceCalculator {
  struct ReferenceData {
    uint256 lastData;
    uint256 lastUpdated;
  }

  function pricesInUSD(address[] memory assets)
    external
    view
    returns (uint256[] memory);

  function valueOfAsset(address asset, uint256 amount)
    external
    view
    returns (uint256 valueInBNB, uint256 valueInUSD);

  function priceOfBunny() external view returns (uint256);

  function priceOfBNB() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './IVToken.sol';

interface IVenusPriceOracle {
  function getUnderlyingPrice(IVToken vToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '../library/PoolConstant.sol';
import './IVaultController.sol';

interface IStrategyCompact is IVaultController {
  /* ========== Dashboard ========== */

  function balance() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function principalOf(address account) external view returns (uint256);

  function withdrawableBalanceOf(address account)
    external
    view
    returns (uint256);

  function earned(address account) external view returns (uint256);

  function priceShare() external view returns (uint256);

  function depositedAt(address account) external view returns (uint256);

  function rewardsToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library PoolConstant {
  enum PoolTypes {
    BunnyStake_deprecated, // no perf fee
    BunnyFlip_deprecated, // deprecated
    CakeStake,
    FlipToFlip,
    FlipToCake,
    Bunny, // no perf fee
    BunnyBNB,
    Venus,
    Collateral,
    BunnyToBunny,
    FlipToReward,
    BunnyV2,
    Qubit,
    bQBT,
    flipToQBT
  }

  struct PoolInfo {
    address pool;
    uint256 balance;
    uint256 principal;
    uint256 available;
    uint256 tvl;
    uint256 utilized;
    uint256 liquidity;
    uint256 pBASE;
    uint256 pBUNNY;
    uint256 depositedAt;
    uint256 feeDuration;
    uint256 feePercentage;
    uint256 portfolio;
  }

  struct RelayInfo {
    address pool;
    uint256 balanceInUSD;
    uint256 debtInUSD;
    uint256 earnedInUSD;
  }

  struct RelayWithdrawn {
    address pool;
    address account;
    uint256 profitInETH;
    uint256 lossInETH;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVaultController {
  function minter() external view returns (address);

  function bunnyChef() external view returns (address);

  function stakingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '../../access/Ownable.sol';
import '../../GSN/Context.sol';
import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMasterChef {
  function cakePerBlock() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function poolInfo(uint256 _pid)
    external
    view
    returns (
      address lpToken,
      uint256 allocPoint,
      uint256 lastRewardBlock,
      uint256 accCakePerShare
    );

  function userInfo(uint256 _pid, address _account)
    external
    view
    returns (uint256 amount, uint256 rewardDebt);

  function poolLength() external view returns (uint256);

  function deposit(uint256 _pid, uint256 _amount) external;

  function withdraw(uint256 _pid, uint256 _amount) external;

  function emergencyWithdraw(uint256 _pid) external;

  function enterStaking(uint256 _amount) external;

  function leaveStaking(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IGoenMinterV2 {
  function isMinter(address) external view returns (bool);

  function amountBunnyToMint(uint256 bnbProfit) external view returns (uint256);

  function amountBunnyToMintForBunnyBNB(uint256 amount, uint256 duration)
    external
    view
    returns (uint256);

  function withdrawalFee(uint256 amount, uint256 depositedAt)
    external
    view
    returns (uint256);

  function performanceFee(uint256 profit) external view returns (uint256);

  function mintFor(
    address flip,
    uint256 _withdrawalFee,
    uint256 _performanceFee,
    address to,
    uint256 depositedAt
  ) external payable;

  function mintForV2(
    address flip,
    uint256 _withdrawalFee,
    uint256 _performanceFee,
    address to,
    uint256 depositedAt
  ) external payable;

  function WITHDRAWAL_FEE_FREE_PERIOD() external view returns (uint256);

  function WITHDRAWAL_FEE() external view returns (uint256);

  function setMinter(address minter, bool canMint) external;

  // V2 functions
  function mint(uint256 amount) external;

  function safeBunnyTransfer(address to, uint256 amount) external;

  function mintGov(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IGoenChef {
  struct UserInfo {
    uint256 balance;
    uint256 pending;
    uint256 rewardPaid;
  }

  struct VaultInfo {
    address token;
    uint256 allocPoint; // How many allocation points assigned to this pool. BUNNYs to distribute per block.
    uint256 lastRewardBlock; // Last block number that BUNNYs distribution occurs.
    uint256 accBunnyPerShare; // Accumulated BUNNYs per share, times 1e12. See below.
  }

  function goenPerBlock() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function vaultInfoOf(address vault) external view returns (VaultInfo memory);

  function vaultUserInfoOf(address vault, address user)
    external
    view
    returns (UserInfo memory);

  function pendingGoen(address vault, address user)
    external
    view
    returns (uint256);

  function notifyDeposited(address user, uint256 amount) external;

  function notifyWithdrawn(address user, uint256 amount) external;

  function safeBunnyTransfer(address user) external returns (uint256);

  function updateRewardsOf(address vault) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

contract Whitelist is Ownable {
  mapping(address => bool) private _whitelist;
  bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

  event Whitelisted(address indexed _address, bool whitelist);
  event EnableWhitelist();
  event DisableWhitelist();

  modifier onlyWhitelisted() {
    require(
      _disable || _whitelist[msg.sender],
      'Whitelist: caller is not on the whitelist'
    );
    _;
  }

  function isWhitelist(address _address) public view returns (bool) {
    return _whitelist[_address];
  }

  function setWhitelist(address _address, bool _on) external onlyOwner {
    _whitelist[_address] = _on;

    emit Whitelisted(_address, _on);
  }

  function disableWhitelist(bool disable) external onlyOwner {
    _disable = disable;
    if (disable) {
      emit DisableWhitelist();
    } else {
      emit EnableWhitelist();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './CarefulMath.sol';

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Venus
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
  uint256 constant expScale = 1e18;
  uint256 constant doubleScale = 1e36;
  uint256 constant halfExpScale = expScale / 2;
  uint256 constant mantissaOne = expScale;

  struct Exp {
    uint256 mantissa;
  }

  struct Double {
    uint256 mantissa;
  }

  /**
   * @dev Creates an exponential from numerator and denominator values.
   *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
   *            or if `denom` is zero.
   */
  function getExp(uint256 num, uint256 denom)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    (MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({ mantissa: 0 }));
    }

    return (MathError.NO_ERROR, Exp({ mantissa: rational }));
  }

  /**
   * @dev Adds two exponentials, returning a new exponential.
   */
  function addExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

    return (error, Exp({ mantissa: result }));
  }

  /**
   * @dev Subtracts two exponentials, returning a new exponential.
   */
  function subExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

    return (error, Exp({ mantissa: result }));
  }

  /**
   * @dev Multiply an Exp by a scalar, returning a new Exp.
   */
  function mulScalar(Exp memory a, uint256 scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    return (MathError.NO_ERROR, Exp({ mantissa: scaledMantissa }));
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mulScalarTruncate(Exp memory a, uint256 scalar)
    internal
    pure
    returns (MathError, uint256)
  {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(product));
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mulScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return addUInt(truncate(product), addend);
  }

  /**
   * @dev Divide an Exp by a scalar, returning a new Exp.
   */
  function divScalar(Exp memory a, uint256 scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 descaledMantissa) = divUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    return (MathError.NO_ERROR, Exp({ mantissa: descaledMantissa }));
  }

  /**
   * @dev Divide a scalar by an Exp, returning a new Exp.
   */
  function divScalarByExp(uint256 scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, Exp memory)
  {
    /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
    (MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }
    return getExp(numerator, divisor.mantissa);
  }

  /**
   * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
   */
  function divScalarByExpTruncate(uint256 scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, uint256)
  {
    (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(fraction));
  }

  /**
   * @dev Multiplies two exponentials, returning a new exponential.
   */
  function mulExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 doubleScaledProduct) = mulUInt(
      a.mantissa,
      b.mantissa
    );
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    // We add half the scale before dividing so that we get rounding instead of truncation.
    //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
    // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
    (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(
      halfExpScale,
      doubleScaledProduct
    );
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({ mantissa: 0 }));
    }

    (MathError err2, uint256 product) = divUInt(
      doubleScaledProductWithHalfScale,
      expScale
    );
    // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
    assert(err2 == MathError.NO_ERROR);

    return (MathError.NO_ERROR, Exp({ mantissa: product }));
  }

  /**
   * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
   */
  function mulExp(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return mulExp(Exp({ mantissa: a }), Exp({ mantissa: b }));
  }

  /**
   * @dev Multiplies three exponentials, returning a new exponential.
   */
  function mulExp3(
    Exp memory a,
    Exp memory b,
    Exp memory c
  ) internal pure returns (MathError, Exp memory) {
    (MathError err, Exp memory ab) = mulExp(a, b);
    if (err != MathError.NO_ERROR) {
      return (err, ab);
    }
    return mulExp(ab, c);
  }

  /**
   * @dev Divides two exponentials, returning a new exponential.
   *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
   *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
   */
  function divExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return getExp(a.mantissa, b.mantissa);
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint256) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint224)
  {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: add_(a.mantissa, b.mantissa) });
  }

  function add_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: add_(a.mantissa, b.mantissa) });
  }

  function add_(uint256 a, uint256 b) internal pure returns (uint256) {
    return add_(a, b, 'addition overflow');
  }

  function add_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: sub_(a.mantissa, b.mantissa) });
  }

  function sub_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: sub_(a.mantissa, b.mantissa) });
  }

  function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub_(a, b, 'subtraction underflow');
  }

  function sub_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: mul_(a.mantissa, b.mantissa) / expScale });
  }

  function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({ mantissa: mul_(a.mantissa, b) });
  }

  function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: mul_(a.mantissa, b.mantissa) / doubleScale });
  }

  function mul_(Double memory a, uint256 b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: mul_(a.mantissa, b) });
  }

  function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
    return mul_(a, b, 'multiplication overflow');
  }

  function mul_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: div_(mul_(a.mantissa, expScale), b.mantissa) });
  }

  function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({ mantissa: div_(a.mantissa, b) });
  }

  function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return
      Double({ mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa) });
  }

  function div_(Double memory a, uint256 b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: div_(a.mantissa, b) });
  }

  function div_(uint256 a, Double memory b) internal pure returns (uint256) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint256 a, uint256 b) internal pure returns (uint256) {
    return div_(a, b, 'divide by zero');
  }

  function div_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function fraction(uint256 a, uint256 b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: div_(mul_(a, doubleScale), b) });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVBNB {
  function totalSupply() external view returns (uint256);

  function mint() external payable;

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow() external payable;

  function balanceOfUnderlying(address owner) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Careful Math
 * @author Venus
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
  /**
   * @dev Possible error codes that we can return
   */
  enum MathError {
    NO_ERROR,
    DIVISION_BY_ZERO,
    INTEGER_OVERFLOW,
    INTEGER_UNDERFLOW
  }

  /**
   * @dev Multiplies two numbers, returns an error on overflow.
   */
  function mulUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    if (a == 0) {
      return (MathError.NO_ERROR, 0);
    }

    uint256 c = a * b;

    if (c / a != b) {
      return (MathError.INTEGER_OVERFLOW, 0);
    } else {
      return (MathError.NO_ERROR, c);
    }
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function divUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    if (b == 0) {
      return (MathError.DIVISION_BY_ZERO, 0);
    }

    return (MathError.NO_ERROR, a / b);
  }

  /**
   * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
   */
  function subUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    if (b <= a) {
      return (MathError.NO_ERROR, a - b);
    } else {
      return (MathError.INTEGER_UNDERFLOW, 0);
    }
  }

  /**
   * @dev Adds two numbers, returns an error on overflow.
   */
  function addUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    uint256 c = a + b;

    if (c >= a) {
      return (MathError.NO_ERROR, c);
    } else {
      return (MathError.INTEGER_OVERFLOW, 0);
    }
  }

  /**
   * @dev add a and b and then subtract c
   */
  function addThenSubUInt(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (MathError, uint256) {
    (MathError err0, uint256 sum) = addUInt(a, b);

    if (err0 != MathError.NO_ERROR) {
      return (err0, 0);
    }

    return subUInt(sum, c);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

abstract contract BEP20Upgradeable is IBEP20, OwnableUpgradeable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  uint256[50] private __gap;

  /**
   * @dev sets initials supply and the owner
   */
  function __BEP20__init(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal initializer {
    __Ownable_init();
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view override returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the token name.
   */
  function name() external view override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        'BEP20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'BEP20: decreased allowance below zero'
      )
    );
    return true;
  }

  /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
  function burn(uint256 amount) public returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), 'BEP20: transfer from the zero address');
    require(recipient != address(0), 'BEP20: transfer to the zero address');

    _balances[sender] = _balances[sender].sub(
      amount,
      'BEP20: transfer amount exceeds balance'
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), 'BEP20: mint to the zero address');

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), 'BEP20: burn from the zero address');

    _balances[account] = _balances[account].sub(
      amount,
      'BEP20: burn amount exceeds balance'
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), 'BEP20: approve from the zero address');
    require(spender != address(0), 'BEP20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(
      account,
      _msgSender(),
      _allowances[account][_msgSender()].sub(
        amount,
        'BEP20: burn amount exceeds allowance'
      )
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';

library HomoraMath {
  using SafeMath for uint256;

  function divCeil(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
    return lhs.add(rhs).sub(1) / rhs;
  }

  function fmul(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
    return lhs.mul(rhs) / (2**112);
  }

  function fdiv(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
    return lhs.mul(2**112) / rhs;
  }

  // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
  // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
  function sqrt(uint256 x) internal pure returns (uint256) {
    if (x == 0) return 0;
    uint256 xx = x;
    uint256 r = 1;

    if (xx >= 0x100000000000000000000000000000000) {
      xx >>= 128;
      r <<= 64;
    }

    if (xx >= 0x10000000000000000) {
      xx >>= 64;
      r <<= 32;
    }
    if (xx >= 0x100000000) {
      xx >>= 32;
      r <<= 16;
    }
    if (xx >= 0x10000) {
      xx >>= 16;
      r <<= 8;
    }
    if (xx >= 0x100) {
      xx >>= 8;
      r <<= 4;
    }
    if (xx >= 0x10) {
      xx >>= 4;
      r <<= 2;
    }
    if (xx >= 0x8) {
      r <<= 1;
    }

    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1; // Seven iterations should be enough
    uint256 r1 = x / r;
    return (r < r1 ? r : r1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../../interfaces/IPancakePair.sol';
import '../../interfaces/IPancakeFactory.sol';
import '../../interfaces/AggregatorV3Interface.sol';
import '../../interfaces/IPriceCalculator.sol';
import '../../library/HomoraMath.sol';

contract PriceCalculatorBSC is IPriceCalculator, OwnableUpgradeable {
  using SafeMath for uint256;
  using HomoraMath for uint256;

  // address public constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  // address public constant CAKE = 0xf73D010412Fb5835C310728F0Ba1b7DFDe88379A;
  // address public constant GOEN = 0xa093D11E9B4aB850B77f64307F55640A75c580d2;
  // address public constant VAI = 0x5fFbE5302BadED40941A403228E6AD03f93752d9;
  // address public constant BUSD = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;

  address public constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
  // address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
  address public constant GOEN = 0xa093D11E9B4aB850B77f64307F55640A75c580d2;

  address public constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
  address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

  address public constant BUNNY_BNB_V1 =
    0x7Bb89460599Dbf32ee3Aa50798BBcEae2A5F7f6a;
  address public constant BUNNY_BNB_V2 =
    0x5aFEf8567414F29f0f927A0F2787b188624c10E2;

  IPancakeFactory private constant factory =
    IPancakeFactory(0xE1Af51c1Bd825B8EBF1f88F2d649B2369912B837);

  /* ========== STATE VARIABLES ========== */

  mapping(address => address) private pairTokens;
  mapping(address => address) private tokenFeeds;
  mapping(address => ReferenceData) public references;

  address public keeper;

  /* ========== MODIFIERS ========== */

  modifier onlyKeeper() {
    require(
      msg.sender == keeper || msg.sender == owner(),
      'Qore: caller is not the owner or keeper'
    );
    _;
  }

  /* ========== INITIALIZER ========== */

  function initialize() external initializer {
    __Ownable_init();
    setPairToken(VAI, BUSD);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setKeeper(address _keeper) external onlyKeeper {
    require(
      _keeper != address(0),
      'PriceCalculatorBSC: invalid keeper address'
    );
    keeper = _keeper;
  }

  function setPairToken(address asset, address pairToken) public onlyKeeper {
    pairTokens[asset] = pairToken;
  }

  function setTokenFeed(address asset, address feed) public onlyKeeper {
    tokenFeeds[asset] = feed;
  }

  function setPrices(address[] memory assets, uint256[] memory prices)
    external
    onlyKeeper
  {
    for (uint256 i = 0; i < assets.length; i++) {
      references[assets[i]] = ReferenceData({
        lastData: prices[i],
        lastUpdated: block.timestamp
      });
    }
  }

  /* ========== VIEWS ========== */

  function priceOfBNB() public view override returns (uint256) {
    (, int256 price, , , ) = AggregatorV3Interface(tokenFeeds[WBNB])
      .latestRoundData();
    return uint256(price).mul(1e10);
  }

  function priceOfCake() public view returns (uint256) {
    (, int256 price, , , ) = AggregatorV3Interface(tokenFeeds[CAKE])
      .latestRoundData();
    return uint256(price).mul(1e10);
  }

  function priceOfBunny() public view override returns (uint256) {
    (, uint256 price) = valueOfAsset(GOEN, 1e18);
    return price;
  }

  function pricesInUSD(address[] memory assets)
    public
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      (, uint256 valueInUSD) = valueOfAsset(assets[i], 1e18);
      prices[i] = valueInUSD;
    }
    return prices;
  }

  function valueOfAsset(address asset, uint256 amount)
    public
    view
    override
    returns (uint256 valueInBNB, uint256 valueInUSD)
  {
    if (asset == address(0) || asset == WBNB) {
      return _oracleValueOf(asset, amount);
    } else if (
      keccak256(abi.encodePacked(IPancakePair(asset).symbol())) ==
      keccak256('Cake-LP')
    ) {
      return _getPairPrice(asset, amount);
    } else {
      return _oracleValueOf(asset, amount);
    }
  }

  function unsafeValueOfAsset(address asset, uint256 amount)
    public
    view
    returns (uint256 valueInBNB, uint256 valueInUSD)
  {
    valueInBNB = 0;
    valueInUSD = 0;

    if (asset == address(0) || asset == WBNB) {
      valueInBNB = amount;
      valueInUSD = amount.mul(priceOfBNB()).div(1e18);
    } else if (
      keccak256(abi.encodePacked(IPancakePair(asset).symbol())) ==
      keccak256('Cake-LP')
    ) {
      if (IPancakePair(asset).totalSupply() == 0) return (0, 0);

      (uint256 reserve0, uint256 reserve1, ) = IPancakePair(asset)
        .getReserves();
      if (IPancakePair(asset).token0() == WBNB) {
        valueInBNB = amount.mul(reserve0).mul(2).div(
          IPancakePair(asset).totalSupply()
        );
        valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
      } else if (IPancakePair(asset).token1() == WBNB) {
        valueInBNB = amount.mul(reserve1).mul(2).div(
          IPancakePair(asset).totalSupply()
        );
        valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
      } else {
        (uint256 token0PriceInBNB, ) = valueOfAsset(
          IPancakePair(asset).token0(),
          1e18
        );
        valueInBNB = amount
          .mul(reserve0)
          .mul(2)
          .mul(token0PriceInBNB)
          .div(1e18)
          .div(IPancakePair(asset).totalSupply());
        valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
      }
    } else {
      address pairToken = pairTokens[asset] == address(0)
        ? WBNB
        : pairTokens[asset];
      address pair = factory.getPair(asset, pairToken);
      if (IBEP20(asset).balanceOf(pair) == 0) return (0, 0);

      (uint256 reserve0, uint256 reserve1, ) = IPancakePair(pair).getReserves();
      if (IPancakePair(pair).token0() == pairToken) {
        valueInBNB = reserve0.mul(amount).div(reserve1);
      } else if (IPancakePair(pair).token1() == pairToken) {
        valueInBNB = reserve1.mul(amount).div(reserve0);
      } else {
        return (0, 0);
      }

      if (pairToken != WBNB) {
        (uint256 pairValueInBNB, ) = valueOfAsset(pairToken, 1e18);
        valueInBNB = valueInBNB.mul(pairValueInBNB).div(1e18);
      }
      valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
    }
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _getPairPrice(address pair, uint256 amount)
    private
    view
    returns (uint256 valueInBNB, uint256 valueInUSD)
  {
    address token0 = IPancakePair(pair).token0();
    address token1 = IPancakePair(pair).token1();
    uint256 totalSupply = IPancakePair(pair).totalSupply();
    (uint256 r0, uint256 r1, ) = IPancakePair(pair).getReserves();

    uint256 sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply);
    (uint256 px0, ) = _oracleValueOf(token0, 1e18);
    (uint256 px1, ) = _oracleValueOf(token1, 1e18);
    uint256 fairPriceInBNB = sqrtK
      .mul(2)
      .mul(HomoraMath.sqrt(px0))
      .div(2**56)
      .mul(HomoraMath.sqrt(px1))
      .div(2**56);

    valueInBNB = fairPriceInBNB.mul(amount).div(1e18);
    valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
  }

  function _oracleValueOf(address asset, uint256 amount)
    private
    view
    returns (uint256 valueInBNB, uint256 valueInUSD)
  {
    valueInUSD = 0;
    if (tokenFeeds[asset] != address(0)) {
      (, int256 price, , , ) = AggregatorV3Interface(tokenFeeds[asset])
        .latestRoundData();
      valueInUSD = uint256(price).mul(1e10).mul(amount).div(1e18);
    } else if (references[asset].lastUpdated > block.timestamp.sub(1 days)) {
      valueInUSD = references[asset].lastData.mul(amount).div(1e18);
    }
    valueInBNB = valueInUSD.mul(1e18).div(priceOfBNB());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPancakeFactory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@openzeppelin/contracts/math/Math.sol';

import '../../library/PausableUpgradeable.sol';
import '../../library/SafeToken.sol';

import '../../interfaces/IPriceCalculator.sol';

contract VaultCompensation is PausableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeBEP20 for IBEP20;
  using SafeMath for uint256;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  IPriceCalculator public constant priceCalculator =
    IPriceCalculator(0xF5BF8A9249e3cc4cB684E3f23db9669323d4FB7d);

  address public constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;

  struct RewardInfo {
    address token;
    uint256 rewardPerTokenStored;
    uint256 rewardRate;
    uint256 lastUpdateTime;
  }

  struct DepositRequest {
    address to;
    uint256 amount;
  }

  struct UserStatus {
    uint256 balance;
    uint256 totalRewardsPaidInUSD;
    uint256 userTotalRewardsPaidInUSD;
    uint256[] pendingRewards;
  }

  /* ========== STATE VARIABLES ========== */

  address public stakingToken;
  address public rewardsDistribution;

  uint256 public periodFinish;
  uint256 public rewardsDuration;
  uint256 public totalRewardsPaidInUSD;

  address[] private _rewardTokens;
  mapping(address => RewardInfo) public rewards;
  mapping(address => mapping(address => uint256)) public userRewardPerToken;
  mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _compensations;

  /* ========== EVENTS ========== */

  event Deposited(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);

  event RewardsAdded(uint256 value);
  event RewardsPaid(address indexed user, address token, uint256 amount);
  event Recovered(address token, uint256 amount);

  receive() external payable {}

  /* ========== MODIFIERS ========== */

  modifier onlyRewardsDistribution() {
    require(msg.sender == rewardsDistribution, 'onlyRewardsDistribution');
    _;
  }

  modifier updateRewards(address account) {
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      RewardInfo storage rewardInfo = rewards[_rewardTokens[i]];
      rewardInfo.rewardPerTokenStored = rewardPerToken(rewardInfo.token);
      rewardInfo.lastUpdateTime = lastTimeRewardApplicable();

      if (account != address(0)) {
        userRewardPerToken[account][rewardInfo.token] = earned(
          account,
          rewardInfo.token
        );
        userRewardPerTokenPaid[account][rewardInfo.token] = rewardInfo
          .rewardPerTokenStored;
      }
    }
    _;
  }

  /* ========== INITIALIZER ========== */

  function initialize() external initializer {
    __PausableUpgradeable_init();
    __ReentrancyGuard_init();

    rewardsDuration = 1 days;
  }

  /* ========== VIEW FUNCTIONS ========== */

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function statusOf(address account) public view returns (UserStatus memory) {
    UserStatus memory status;
    status.balance = _balances[account];
    status.totalRewardsPaidInUSD = totalRewardsPaidInUSD;
    status.userTotalRewardsPaidInUSD = _compensations[account];
    status.pendingRewards = new uint256[](_rewardTokens.length);
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      status.pendingRewards[i] = earned(account, _rewardTokens[i]);
    }
    return status;
  }

  function earned(address account, address token)
    public
    view
    returns (uint256)
  {
    return
      _balances[account]
        .mul(rewardPerToken(token).sub(userRewardPerTokenPaid[account][token]))
        .div(1e18)
        .add(userRewardPerToken[account][token]);
  }

  function rewardTokens() public view returns (address[] memory) {
    return _rewardTokens;
  }

  function rewardPerToken(address token) public view returns (uint256) {
    if (totalSupply() == 0) return rewards[token].rewardPerTokenStored;
    return
      rewards[token].rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(rewards[token].lastUpdateTime)
          .mul(rewards[token].rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setStakingToken(address _stakingToken) public onlyOwner {
    require(stakingToken == address(0), 'VaultComp: stakingToken set already');
    stakingToken = _stakingToken;
  }

  function addRewardsToken(address _rewardsToken) public onlyOwner {
    require(_rewardsToken != address(0), 'VaultComp: BNB uses WBNB address');
    require(
      rewards[_rewardsToken].token == address(0),
      'VaultComp: duplicated rewards token'
    );
    rewards[_rewardsToken] = RewardInfo(_rewardsToken, 0, 0, 0);
    _rewardTokens.push(_rewardsToken);
  }

  function setRewardsDistribution(address _rewardsDistribution)
    public
    onlyOwner
  {
    rewardsDistribution = _rewardsDistribution;
  }

  function depositOnBehalf(uint256 _amount, address _to) external onlyOwner {
    _deposit(_amount, _to);
  }

  function _deposit(uint256 _amount, address _to) private updateRewards(_to) {
    require(stakingToken != address(0), 'VaultComp: staking token must be set');
    IBEP20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
    _totalSupply = _totalSupply.add(_amount);
    _balances[_to] = _balances[_to].add(_amount);
    emit Deposited(_to, _amount);
  }

  function depositOnBehalfBulk(DepositRequest[] memory request)
    external
    onlyOwner
  {
    uint256 sum;
    for (uint256 i = 0; i < request.length; i++) {
      sum += request[i].amount;
    }

    _totalSupply = _totalSupply.add(sum);
    IBEP20(stakingToken).safeTransferFrom(msg.sender, address(this), sum);

    for (uint256 i = 0; i < request.length; i++) {
      address to = request[i].to;
      uint256 amount = request[i].amount;
      _balances[to] = _balances[to].add(amount);
      emit Deposited(to, amount);
    }
  }

  function updateCompensationsBulk(
    address[] memory _accounts,
    uint256[] memory _values
  ) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      _compensations[_accounts[i]] = _compensations[_accounts[i]].add(
        _values[i]
      );
    }
  }

  /* ========== RESTRICTED FUNCTIONS - COMPENSATION ========== */

  function notifyRewardAmounts(uint256[] memory amounts)
    external
    onlyRewardsDistribution
    updateRewards(address(0))
  {
    uint256 accRewardsPaidInUSD = 0;
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      RewardInfo storage rewardInfo = rewards[_rewardTokens[i]];
      if (block.timestamp >= periodFinish) {
        rewardInfo.rewardRate = amounts[i].div(rewardsDuration);
      } else {
        uint256 remaining = periodFinish.sub(block.timestamp);
        uint256 leftover = remaining.mul(rewardInfo.rewardRate);
        rewardInfo.rewardRate = amounts[i].add(leftover).div(rewardsDuration);
      }
      rewardInfo.lastUpdateTime = block.timestamp;

      // Ensure the provided reward amount is not more than the balance in the contract.
      // This keeps the reward rate in the right range, preventing overflows due to
      // very high values of rewardRate in the earned and rewardsPerToken functions;
      // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.

      uint256 _balance = rewardInfo.token == WBNB
        ? address(this).balance
        : IBEP20(rewardInfo.token).balanceOf(address(this));
      require(
        rewardInfo.rewardRate <= _balance.div(rewardsDuration),
        'VaultComp: invalid rewards amount'
      );

      (, uint256 valueInUSD) = priceCalculator.valueOfAsset(
        rewardInfo.token,
        amounts[i]
      );
      accRewardsPaidInUSD = accRewardsPaidInUSD.add(valueInUSD);
    }

    totalRewardsPaidInUSD = totalRewardsPaidInUSD.add(accRewardsPaidInUSD);
    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardsAdded(accRewardsPaidInUSD);
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(
      periodFinish == 0 || block.timestamp > periodFinish,
      'VaultComp: invalid rewards duration'
    );
    rewardsDuration = _rewardsDuration;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function deposit(uint256 _amount) public notPaused updateRewards(msg.sender) {
    require(stakingToken != address(0), 'VaultComp: staking token must be set');
    IBEP20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);

    _totalSupply = _totalSupply.add(_amount);
    _balances[msg.sender] = _balances[msg.sender].add(_amount);
    emit Deposited(msg.sender, _amount);
  }

  function withdraw(uint256 _amount)
    external
    notPaused
    updateRewards(msg.sender)
  {
    require(stakingToken != address(0), 'VaultComp: staking token must be set');

    _totalSupply = _totalSupply.sub(_amount);
    _balances[msg.sender] = _balances[msg.sender].sub(_amount);
    IBEP20(stakingToken).safeTransfer(msg.sender, _amount);
    emit Withdrawn(msg.sender, _amount);
  }

  function getReward() public nonReentrant updateRewards(msg.sender) {
    require(stakingToken != address(0), 'VaultComp: staking token must be set');
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      if (msg.sender != address(0)) {
        uint256 reward = userRewardPerToken[msg.sender][_rewardTokens[i]];
        if (reward > 0) {
          userRewardPerToken[msg.sender][_rewardTokens[i]] = 0;
          (, uint256 valueInUSD) = priceCalculator.valueOfAsset(
            _rewardTokens[i],
            reward
          );
          _compensations[msg.sender] = _compensations[msg.sender].add(
            valueInUSD
          );

          if (_rewardTokens[i] == WBNB) {
            SafeToken.safeTransferETH(msg.sender, reward);
          } else {
            IBEP20(_rewardTokens[i]).safeTransfer(msg.sender, reward);
          }
          emit RewardsPaid(msg.sender, _rewardTokens[i], reward);
        }
      }
    }
  }

  /* ========== SALVAGE PURPOSE ONLY ========== */

  function recoverToken(address _token, uint256 amount) external onlyOwner {
    require(stakingToken != address(0), 'VaultComp: staking token must be set');
    require(
      _token != address(stakingToken),
      'VaultComp: cannot recover underlying token'
    );
    IBEP20(_token).safeTransfer(owner(), amount);
    emit Recovered(_token, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

import '../library/SafeToken.sol';
import '../interfaces/IWETH.sol';

contract safeSwapBNB {
  using SafeBEP20 for IBEP20;
  using SafeMath for uint256;

  /* ========== CONSTANTS ============= */

  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;

  /* ========== CONSTRUCTOR ========== */

  constructor() public {}

  receive() external payable {}

  /* ========== FUNCTIONS ========== */

  function withdraw(uint256 amount) external {
    require(IBEP20(WBNB).balanceOf(msg.sender) >= amount, 'Not enough Tokens!');

    IBEP20(WBNB).transferFrom(msg.sender, address(this), amount);

    IWETH(WBNB).withdraw(amount);

    SafeToken.safeTransferETH(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IWETH {
  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function deposit() external payable;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/Math.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

import '../interfaces/IStrategy.sol';
import '../interfaces/IGoenMinter.sol';
import '../interfaces/IGoenChef.sol';
import './VaultController.sol';
import { PoolConstant } from '../library/PoolConstant.sol';

contract VaultGoen is VaultController, IStrategy, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  /* ========== CONSTANTS ============= */

  address private constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
  PoolConstant.PoolTypes public constant override poolType =
    PoolConstant.PoolTypes.Bunny;

  /* ========== STATE VARIABLES ========== */

  uint256 public override pid;
  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _depositedAt;

  /* ========== INITIALIZER ========== */

  function initialize() external initializer {
    __VaultController_init(IBEP20(BUNNY));
    __ReentrancyGuard_init();
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balance() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function sharesOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function principalOf(address account)
    external
    view
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function depositedAt(address account)
    external
    view
    override
    returns (uint256)
  {
    return _depositedAt[account];
  }

  function withdrawableBalanceOf(address account)
    public
    view
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function rewardsToken() external view override returns (address) {
    return BUNNY;
  }

  function priceShare() external view override returns (uint256) {
    return 1e18;
  }

  function earned(address) public view override returns (uint256) {
    return 0;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function deposit(uint256 amount) public override {
    _deposit(amount, msg.sender);
  }

  function depositAll() external override {
    deposit(_stakingToken.balanceOf(msg.sender));
  }

  function withdraw(uint256 amount) public override nonReentrant {
    require(amount > 0, 'VaultBunny: amount must be greater than zero');
    _bunnyChef.notifyWithdrawn(msg.sender, amount);

    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);

    uint256 withdrawalFee;
    if (canMint()) {
      uint256 depositTimestamp = _depositedAt[msg.sender];
      withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
      if (withdrawalFee > 0) {
        _minter.mintFor(
          address(_stakingToken),
          withdrawalFee,
          0,
          msg.sender,
          depositTimestamp
        );
        amount = amount.sub(withdrawalFee);
      }
    }

    _stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount, withdrawalFee);
  }

  function withdrawAll() external override {
    uint256 _withdraw = withdrawableBalanceOf(msg.sender);
    if (_withdraw > 0) {
      withdraw(_withdraw);
    }
    getReward();
  }

  function getReward() public override nonReentrant {
    uint256 bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
    emit BunnyPaid(msg.sender, bunnyAmount, 0);
  }

  function harvest() public override {}

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setMinter(address newMinter) public override onlyOwner {
    VaultController.setMinter(newMinter);
  }

  function setBunnyChef(IGoenChef _chef) public override onlyOwner {
    require(
      address(_bunnyChef) == address(0),
      'VaultBunny: setBunnyChef only once'
    );
    VaultController.setBunnyChef(IGoenChef(_chef));
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _deposit(uint256 amount, address _to)
    private
    nonReentrant
    notPaused
  {
    require(amount > 0, 'VaultBunny: amount must be greater than zero');
    _bunnyChef.updateRewardsOf(address(this));

    _totalSupply = _totalSupply.add(amount);
    _balances[_to] = _balances[_to].add(amount);
    _depositedAt[_to] = block.timestamp;
    _stakingToken.safeTransferFrom(msg.sender, address(this), amount);

    _bunnyChef.notifyDeposited(msg.sender, amount);
    emit Deposited(_to, amount);
  }

  /* ========== SALVAGE PURPOSE ONLY ========== */

  function recoverToken(address tokenAddress, uint256 tokenAmount)
    external
    override
    onlyOwner
  {
    require(
      tokenAddress != address(_stakingToken),
      'VaultBunny: cannot recover underlying token'
    );
    IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
pragma solidity ^0.6.12;

interface IGoenMinter {
  function isMinter(address) external view returns (bool);

  function amountBunnyToMint(uint256 bnbProfit) external view returns (uint256);

  function amountBunnyToMintForBunnyBNB(uint256 amount, uint256 duration)
    external
    view
    returns (uint256);

  function withdrawalFee(uint256 amount, uint256 depositedAt)
    external
    view
    returns (uint256);

  function performanceFee(uint256 profit) external view returns (uint256);

  function mintFor(
    address flip,
    uint256 _withdrawalFee,
    uint256 _performanceFee,
    address to,
    uint256 depositedAt
  ) external;

  function mintForBunnyBNB(
    uint256 amount,
    uint256 duration,
    address to
  ) external;

  function bunnyPerProfitBNB() external view returns (uint256);

  function WITHDRAWAL_FEE_FREE_PERIOD() external view returns (uint256);

  function WITHDRAWAL_FEE() external view returns (uint256);

  function setMinter(address minter, bool canMint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../interfaces/IGoenMinterV2.sol';
import '../interfaces/IGoenChef.sol';
import '../interfaces/IStrategy.sol';
import './GoenToken.sol';

contract GoenChef is IGoenChef, OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  /* ========== CONSTANTS ============= */

  GoenToken public constant GOEN =
    GoenToken(0xa093D11E9B4aB850B77f64307F55640A75c580d2); // change address token GOEN ( current is BUNNY)

  /* ========== STATE VARIABLES ========== */

  address[] private _vaultList;
  mapping(address => VaultInfo) vaults;
  mapping(address => mapping(address => UserInfo)) vaultUsers;

  IGoenMinterV2 public minter;

  uint256 public startBlock;
  uint256 public override goenPerBlock;
  uint256 public override totalAllocPoint;

  /* ========== MODIFIERS ========== */

  modifier onlyVaults() {
    require(
      vaults[msg.sender].token != address(0),
      'BunnyChef: caller is not on the vault'
    );
    _;
  }

  modifier updateRewards(address vault) {
    VaultInfo storage vaultInfo = vaults[vault];
    if (block.number > vaultInfo.lastRewardBlock) {
      uint256 tokenSupply = tokenSupplyOf(vault);
      if (tokenSupply > 0) {
        uint256 multiplier = timeMultiplier(
          vaultInfo.lastRewardBlock,
          block.number
        );
        uint256 rewards = multiplier
          .mul(goenPerBlock)
          .mul(vaultInfo.allocPoint)
          .div(totalAllocPoint);
        vaultInfo.accBunnyPerShare = vaultInfo.accBunnyPerShare.add(
          rewards.mul(1e12).div(tokenSupply)
        );
      }
      vaultInfo.lastRewardBlock = block.number;
    }
    _;
  }

  /* ========== EVENTS ========== */

  event NotifyDeposited(
    address indexed user,
    address indexed vault,
    uint256 amount
  );
  event NotifyWithdrawn(
    address indexed user,
    address indexed vault,
    uint256 amount
  );
  event BunnyRewardPaid(
    address indexed user,
    address indexed vault,
    uint256 amount
  );

  /* ========== INITIALIZER ========== */

  function initialize(uint256 _startBlock, uint256 _bunnyPerBlock)
    external
    initializer
  {
    __Ownable_init();

    startBlock = _startBlock;
    goenPerBlock = _bunnyPerBlock;
  }

  /* ========== VIEWS ========== */

  function timeMultiplier(uint256 from, uint256 to)
    public
    pure
    returns (uint256)
  {
    return to.sub(from);
  }

  function tokenSupplyOf(address vault) public view returns (uint256) {
    return IStrategy(vault).totalSupply();
  }

  function vaultInfoOf(address vault)
    external
    view
    override
    returns (VaultInfo memory)
  {
    return vaults[vault];
  }

  function vaultUserInfoOf(address vault, address user)
    external
    view
    override
    returns (UserInfo memory)
  {
    return vaultUsers[vault][user];
  }

  function pendingGoen(address vault, address user)
    public
    view
    override
    returns (uint256)
  {
    UserInfo storage userInfo = vaultUsers[vault][user];
    VaultInfo storage vaultInfo = vaults[vault];

    uint256 accBunnyPerShare = vaultInfo.accBunnyPerShare;
    uint256 tokenSupply = tokenSupplyOf(vault);
    if (block.number > vaultInfo.lastRewardBlock && tokenSupply > 0) {
      uint256 multiplier = timeMultiplier(
        vaultInfo.lastRewardBlock,
        block.number
      );
      uint256 bunnyRewards = multiplier
        .mul(goenPerBlock)
        .mul(vaultInfo.allocPoint)
        .div(totalAllocPoint);
      accBunnyPerShare = accBunnyPerShare.add(
        bunnyRewards.mul(1e12).div(tokenSupply)
      );
    }
    return
      userInfo.pending.add(
        userInfo.balance.mul(accBunnyPerShare).div(1e12).sub(
          userInfo.rewardPaid
        )
      );
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addVault(
    address vault,
    address token,
    uint256 allocPoint
  ) public onlyOwner {
    require(
      vaults[vault].token == address(0),
      'BunnyChef: vault is already set'
    );
    bulkUpdateRewards();

    uint256 lastRewardBlock = block.number > startBlock
      ? block.number
      : startBlock;
    totalAllocPoint = totalAllocPoint.add(allocPoint);
    vaults[vault] = VaultInfo(token, allocPoint, lastRewardBlock, 0);
    _vaultList.push(vault);
  }

  function updateVault(address vault, uint256 allocPoint) public onlyOwner {
    require(vaults[vault].token != address(0), 'BunnyChef: vault must be set');
    bulkUpdateRewards();

    uint256 lastAllocPoint = vaults[vault].allocPoint;
    if (lastAllocPoint != allocPoint) {
      totalAllocPoint = totalAllocPoint.sub(lastAllocPoint).add(allocPoint);
    }
    vaults[vault].allocPoint = allocPoint;
  }

  function setMinter(address _minter) external onlyOwner {
    require(address(minter) == address(0), 'BunnyChef: setMinter only once');
    minter = IGoenMinterV2(_minter);
  }

  function setBunnyPerBlock(uint256 _bunnyPerBlock) external onlyOwner {
    bulkUpdateRewards();
    goenPerBlock = _bunnyPerBlock;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function notifyDeposited(address user, uint256 amount)
    external
    override
    onlyVaults
    updateRewards(msg.sender)
  {
    UserInfo storage userInfo = vaultUsers[msg.sender][user];
    VaultInfo storage vaultInfo = vaults[msg.sender];

    uint256 pending = userInfo
      .balance
      .mul(vaultInfo.accBunnyPerShare)
      .div(1e12)
      .sub(userInfo.rewardPaid);
    userInfo.pending = userInfo.pending.add(pending);
    userInfo.balance = userInfo.balance.add(amount);
    userInfo.rewardPaid = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(
      1e12
    );
    emit NotifyDeposited(user, msg.sender, amount);
  }

  function notifyWithdrawn(address user, uint256 amount)
    external
    override
    onlyVaults
    updateRewards(msg.sender)
  {
    UserInfo storage userInfo = vaultUsers[msg.sender][user];
    VaultInfo storage vaultInfo = vaults[msg.sender];

    uint256 pending = userInfo
      .balance
      .mul(vaultInfo.accBunnyPerShare)
      .div(1e12)
      .sub(userInfo.rewardPaid);
    userInfo.pending = userInfo.pending.add(pending);
    userInfo.balance = userInfo.balance.sub(amount);
    userInfo.rewardPaid = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(
      1e12
    );
    emit NotifyWithdrawn(user, msg.sender, amount);
  }

  function safeBunnyTransfer(address user)
    external
    override
    onlyVaults
    updateRewards(msg.sender)
    returns (uint256)
  {
    UserInfo storage userInfo = vaultUsers[msg.sender][user];
    VaultInfo storage vaultInfo = vaults[msg.sender];

    uint256 pending = userInfo
      .balance
      .mul(vaultInfo.accBunnyPerShare)
      .div(1e12)
      .sub(userInfo.rewardPaid);
    uint256 amount = userInfo.pending.add(pending);
    userInfo.pending = 0;
    userInfo.rewardPaid = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(
      1e12
    );

    minter.mint(amount);
    minter.safeBunnyTransfer(user, amount);
    emit BunnyRewardPaid(user, msg.sender, amount);
    return amount;
  }

  function bulkUpdateRewards() public {
    for (uint256 idx = 0; idx < _vaultList.length; idx++) {
      if (
        _vaultList[idx] != address(0) &&
        vaults[_vaultList[idx]].token != address(0)
      ) {
        updateRewardsOf(_vaultList[idx]);
      }
    }
  }

  function updateRewardsOf(address vault)
    public
    override
    updateRewards(vault)
  {}

  /* ========== SALVAGE PURPOSE ONLY ========== */

  function recoverToken(address _token, uint256 amount)
    external
    virtual
    onlyOwner
  {
    require(_token != address(GOEN), 'BunnyChef: cannot recover GOEN token');
    IBEP20(_token).safeTransfer(owner(), amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';


// BunnyToken with Governance.
contract GoenToken is BEP20('Goen Token', 'GOEN') {

  // @dev Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
  function mint(address to, uint256 amount) public onlyOwner {
    (uint totalSupply) = totalSupply();
    require(totalSupply + amount < 55555555 ether, "GOEN::mint: exceeding the permitted limits");
    _mint(to, amount);
    _moveDelegates(address(0), _delegates[to], amount);
  }

  function burn(uint256 amount) public onlyOwner {
    _burn(_msgSender(), amount);
    _moveDelegates(_delegates[_msgSender()], address(0), amount);
  }

  function burnFrom(address account, uint256 amount) public onlyOwner {
    _burnFrom(account, amount);
    _moveDelegates(_delegates[account], address(0), amount);
  }

  // Copied and modified from YAM code:
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  // Which is copied and modified from COMPOUND:
  // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

  // @dev A record of each accounts delegate
  mapping(address => address) internal _delegates;

  // @dev A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  // @dev A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  // @dev The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  // @dev The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      'EIP712Domain(string name,uint256 chainId,address verifyingContract)'
    );

  // @dev The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

  // @dev A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  // @dev An event thats emitted when an account changes its delegate
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  // @dev An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  /**
   * @dev Delegate votes from `msg.sender` to `delegatee`
   * @param delegator The address to get delegatee for
   */
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  /**
   * @dev Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
   * @dev Delegates votes from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name())),
        getChainId(),
        address(this)
      )
    );

    bytes32 structHash = keccak256(
      abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
    );

    bytes32 digest = keccak256(
      abi.encodePacked('\x19\x01', domainSeparator, structHash)
    );

    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), 'GOEN::delegateBySig: invalid signature');
    require(nonce == nonces[signatory]++, 'GOEN::delegateBySig: invalid nonce');
    require(now <= expiry, 'GOEN::delegateBySig: signature expired');
    return _delegate(signatory, delegatee);
  }

  /**
   * @dev Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
   * @dev Determine the prior number of votes for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param blockNumber The block number to get the vote balance at
   * @return The number of votes the account had as of the given block
   */
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint256)
  {
    require(
      blockNumber < block.number,
      'GOEN::getPriorVotes: not yet determined'
    );

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying BUNNYs (not scaled);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0
          ? checkpoints[srcRep][srcRepNum - 1].votes
          : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0
          ? checkpoints[dstRep][dstRepNum - 1].votes
          : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(
      block.number,
      'GOEN::_writeCheckpoint: block number exceeds 32 bits'
    );

    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

import '../interfaces/IGoenMinterV2.sol';
import '../interfaces/IGoenPool.sol';
import '../interfaces/IPriceCalculator.sol';

import '../zap/ZapBSC.sol';
import '../library/SafeToken.sol';

contract GoenMinterV2 is IGoenMinterV2, OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  /* ========== CONSTANTS ============= */

  address public constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address public constant GOEN = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
  address public constant GOEN_POOL_V1 =
    0xCADc8CB26c8C7cB46500E61171b5F27e9bd7889D;

  address public constant FEE_BOX = 0x3749f69B2D99E5586D95d95B6F9B5252C71894bb;
  address private constant TIMELOCK =
    0x85c9162A51E03078bdCd08D4232Bab13ed414cC3;
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address private constant DEPLOYER =
    0xe87f02606911223C2Cf200398FFAF353f60801F7;

  uint256 public constant FEE_MAX = 100000;

  IPriceCalculator public constant priceCalculator =
    IPriceCalculator(0xF5BF8A9249e3cc4cB684E3f23db9669323d4FB7d);
  ZapBSC private constant zap =
    ZapBSC(0xdC2bBB0D33E0e7Dea9F5b98F46EDBaC823586a0C);
  IPancakeRouter02 private constant router =
    IPancakeRouter02(0xaa200B43D5b3337E30bFEA24f0B5eC03c795a9c2);

  /* ========== STATE VARIABLES ========== */

  address public goenChef;
  mapping(address => bool) private _minters;
  address public _deprecated_helper; // deprecated

  uint256 public PERFORMANCE_FEE;
  uint256 public override WITHDRAWAL_FEE_FREE_PERIOD;
  uint256 public override WITHDRAWAL_FEE;

  uint256 public _deprecated_goenPerProfitBNB; // deprecated
  uint256 public _deprecated_goenPerBunnyBNBFlip; // deprecated

  uint256 private _floatingRateEmission;
  uint256 private _freThreshold;

  address public goenPool;

  /* ========== MODIFIERS ========== */

  modifier onlyMinter() {
    require(
      isMinter(msg.sender) == true,
      'GoenMinterV2: caller is not the minter'
    );
    _;
  }

  modifier onlyBunnyChef() {
    require(msg.sender == goenChef, 'GoenMinterV2: caller not the goen chef');
    _;
  }

  /* ========== EVENTS ========== */

  event PerformanceFee(address indexed asset, uint256 amount, uint256 value);

  receive() external payable {}

  /* ========== INITIALIZER ========== */

  function initialize() external initializer {
    WITHDRAWAL_FEE_FREE_PERIOD = 3 days;
    WITHDRAWAL_FEE = 50;
    PERFORMANCE_FEE = 3000;

    _deprecated_goenPerProfitBNB = 5e18;
    _deprecated_goenPerBunnyBNBFlip = 6e18;

    IBEP20(GOEN).approve(GOEN_POOL_V1, uint256(-1));
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function transferBunnyOwner(address _owner) external onlyOwner {
    Ownable(GOEN).transferOwnership(_owner);
  }

  function setWithdrawalFee(uint256 _fee) external onlyOwner {
    require(_fee < 500, 'wrong fee');
    // less 5%
    WITHDRAWAL_FEE = _fee;
  }

  function setPerformanceFee(uint256 _fee) external onlyOwner {
    require(_fee < 5000, 'wrong fee');
    PERFORMANCE_FEE = _fee;
  }

  function setWithdrawalFeeFreePeriod(uint256 _period) external onlyOwner {
    WITHDRAWAL_FEE_FREE_PERIOD = _period;
  }

  function setMinter(address minter, bool canMint) external override onlyOwner {
    if (canMint) {
      _minters[minter] = canMint;
    } else {
      delete _minters[minter];
    }
  }

  function setBunnyChef(address _bunnyChef) external onlyOwner {
    require(goenChef == address(0), 'GoenMinterV2: setBunnyChef only once');
    goenChef = _bunnyChef;
  }

  function setFloatingRateEmission(uint256 floatingRateEmission)
    external
    onlyOwner
  {
    require(
      floatingRateEmission > 1e18 && floatingRateEmission < 10e18,
      'GoenMinterV2: floatingRateEmission wrong range'
    );
    _floatingRateEmission = floatingRateEmission;
  }

  function setFREThreshold(uint256 threshold) external onlyOwner {
    _freThreshold = threshold;
  }

  function setBunnyPool(address _bunnyPool) external onlyOwner {
    IBEP20(GOEN).approve(GOEN_POOL_V1, 0);
    goenPool = _bunnyPool;
    IBEP20(GOEN).approve(_bunnyPool, uint256(-1));
  }

  /* ========== VIEWS ========== */

  function isMinter(address account) public view override returns (bool) {
    if (IBEP20(GOEN).getOwner() != address(this)) {
      return false;
    }
    return _minters[account];
  }

  function amountBunnyToMint(uint256 bnbProfit)
    public
    view
    override
    returns (uint256)
  {
    return
      bnbProfit
        .mul(priceCalculator.priceOfBNB())
        .div(priceCalculator.priceOfBunny())
        .mul(floatingRateEmission())
        .div(1e18);
  }

  function amountBunnyToMintForBunnyBNB(uint256 amount, uint256 duration)
    public
    view
    override
    returns (uint256)
  {
    return
      amount
        .mul(_deprecated_goenPerBunnyBNBFlip)
        .mul(duration)
        .div(365 days)
        .div(1e18);
  }

  function withdrawalFee(uint256 amount, uint256 depositedAt)
    external
    view
    override
    returns (uint256)
  {
    if (depositedAt.add(WITHDRAWAL_FEE_FREE_PERIOD) > block.timestamp) {
      return amount.mul(WITHDRAWAL_FEE).div(FEE_MAX);
    }
    return 0;
  }

  function performanceFee(uint256 profit)
    public
    view
    override
    returns (uint256)
  {
    return profit.mul(PERFORMANCE_FEE).div(FEE_MAX);
  }

  function floatingRateEmission() public view returns (uint256) {
    return _floatingRateEmission == 0 ? 120e16 : _floatingRateEmission;
  }

  function freThreshold() public view returns (uint256) {
    return _freThreshold == 0 ? 18e18 : _freThreshold;
  }

  function shouldMarketBuy() public view returns (bool) {
    return
      priceCalculator.priceOfBunny().mul(freThreshold()).div(
        priceCalculator.priceOfBNB()
      ) < 1e18;
  }

  /* ========== V1 FUNCTIONS ========== */

  function mintFor(
    address asset,
    uint256 _withdrawalFee,
    uint256 _performanceFee,
    address to,
    uint256
  ) public payable override onlyMinter {
    uint256 feeSum = _performanceFee.add(_withdrawalFee);
    _transferAsset(asset, feeSum);

    if (asset == GOEN) {
      IBEP20(GOEN).safeTransfer(DEAD, feeSum);
      return;
    }

    bool marketBuy = shouldMarketBuy();
    if (marketBuy == false) {
      if (asset == address(0)) {
        // means BNB
        SafeToken.safeTransferETH(FEE_BOX, feeSum);
      } else {
        IBEP20(asset).safeTransfer(FEE_BOX, feeSum);
      }
    } else {
      if (_withdrawalFee > 0) {
        if (asset == address(0)) {
          // means BNB
          SafeToken.safeTransferETH(FEE_BOX, _withdrawalFee);
        } else {
          IBEP20(asset).safeTransfer(FEE_BOX, _withdrawalFee);
        }
      }

      if (_performanceFee == 0) return;

      _marketBuy(asset, _performanceFee, to);
      _performanceFee = _performanceFee
        .mul(floatingRateEmission().sub(1e18))
        .div(floatingRateEmission());
    }

    (uint256 contributionInBNB, uint256 contributionInUSD) = priceCalculator
      .valueOfAsset(asset, _performanceFee);
    uint256 mintBunny = amountBunnyToMint(contributionInBNB);
    if (mintBunny == 0) return;
    _mint(mintBunny, to);

    if (marketBuy) {
      uint256 usd = contributionInUSD.mul(floatingRateEmission()).div(
        floatingRateEmission().sub(1e18)
      );
      emit PerformanceFee(asset, _performanceFee, usd);
    } else {
      emit PerformanceFee(asset, _performanceFee, contributionInUSD);
    }
  }

  /* ========== PancakeSwap V2 FUNCTIONS ========== */

  function mintForV2(
    address asset,
    uint256 _withdrawalFee,
    uint256 _performanceFee,
    address to,
    uint256 timestamp
  ) external payable override onlyMinter {
    mintFor(asset, _withdrawalFee, _performanceFee, to, timestamp);
  }

  /* ========== BunnyChef FUNCTIONS ========== */

  function mint(uint256 amount) external override onlyBunnyChef {
    if (amount == 0) return;
    _mint(amount, address(this));
  }

  function safeBunnyTransfer(address _to, uint256 _amount)
    external
    override
    onlyBunnyChef
  {
    if (_amount == 0) return;

    uint256 bal = IBEP20(GOEN).balanceOf(address(this));
    if (_amount <= bal) {
      IBEP20(GOEN).safeTransfer(_to, _amount);
    } else {
      IBEP20(GOEN).safeTransfer(_to, bal);
    }
  }

  // @dev should be called when determining mint in governance. Bunny is transferred to the timelock contract.
  function mintGov(uint256 amount) external override onlyOwner {
    if (amount == 0) return;
    _mint(amount, TIMELOCK);
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _marketBuy(
    address asset,
    uint256 amount,
    address to
  ) private {
    uint256 _initBunnyAmount = IBEP20(GOEN).balanceOf(address(this));

    if (asset == address(0)) {
      zap.zapIn{ value: amount }(GOEN);
    } else if (
      keccak256(abi.encodePacked(IPancakePair(asset).symbol())) ==
      keccak256('Cake-LP')
    ) {
      if (IBEP20(asset).allowance(address(this), address(router)) == 0) {
        IBEP20(asset).safeApprove(address(router), uint256(-1));
      }

      IPancakePair pair = IPancakePair(asset);
      address token0 = pair.token0();
      address token1 = pair.token1();

      // burn
      if (IPancakePair(asset).balanceOf(asset) > 0) {
        IPancakePair(asset).burn(address(zap));
      }

      (uint256 amountToken0, uint256 amountToken1) = router.removeLiquidity(
        token0,
        token1,
        amount,
        0,
        0,
        address(this),
        block.timestamp
      );

      if (IBEP20(token0).allowance(address(this), address(zap)) == 0) {
        IBEP20(token0).safeApprove(address(zap), uint256(-1));
      }
      if (IBEP20(token1).allowance(address(this), address(zap)) == 0) {
        IBEP20(token1).safeApprove(address(zap), uint256(-1));
      }

      if (token0 != GOEN) {
        zap.zapInToken(token0, amountToken0, GOEN);
      }

      if (token1 != GOEN) {
        zap.zapInToken(token1, amountToken1, GOEN);
      }
    } else {
      if (IBEP20(asset).allowance(address(this), address(zap)) == 0) {
        IBEP20(asset).safeApprove(address(zap), uint256(-1));
      }

      zap.zapInToken(asset, amount, GOEN);
    }

    uint256 bunnyAmount = IBEP20(GOEN).balanceOf(address(this)).sub(
      _initBunnyAmount
    );
    IBEP20(GOEN).safeTransfer(to, bunnyAmount);
  }

  function _transferAsset(address asset, uint256 amount) private {
    if (asset == address(0)) {
      // case) transferred BNB
      require(msg.value >= amount);
    } else {
      IBEP20(asset).safeTransferFrom(msg.sender, address(this), amount);
    }
  }

  function _mint(uint256 amount, address to) private {
    BEP20 tokenBUNNY = BEP20(GOEN);

    tokenBUNNY.mint(amount);
    if (to != address(this)) {
      tokenBUNNY.transfer(to, amount);
    }

    uint256 bunnyForDev = amount.mul(15).div(100);
    tokenBUNNY.mint(bunnyForDev);
    if (goenPool == address(0)) {
      tokenBUNNY.transfer(DEPLOYER, bunnyForDev);
    } else {
      IGoenPool(goenPool).depositOnBehalf(bunnyForDev, DEPLOYER);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

interface IGoenPool {
  function balanceOf(address account) external view returns (uint256);

  function earned(address account) external view returns (uint256[] memory);

  function rewardTokens() external view returns (address[] memory);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function withdrawAll() external;

  function getReward() external;

  function depositOnBehalf(uint256 _amount, address _to) external;

  function notifyRewardAmounts(uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../interfaces/IPancakePair.sol';
import '../interfaces/IPancakeRouter02.sol';
import '../interfaces/IZap.sol';
import '../interfaces/ISafeSwapBNB.sol';

contract ZapBSC is IZap, OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  /* ========== CONSTANT VARIABLES ========== */

  address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
  address private constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
  address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
  address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  address private constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
  address private constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
  address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
  address private constant DOT = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402;

  IPancakeRouter02 private constant ROUTER =
    IPancakeRouter02(0xaa200B43D5b3337E30bFEA24f0B5eC03c795a9c2);

  /* ========== STATE VARIABLES ========== */

  mapping(address => bool) private notFlip;
  mapping(address => address) private routePairAddresses;
  address[] public tokens;
  address public safeSwapBNB;

  /* ========== INITIALIZER ========== */

  function initialize() external initializer {
    __Ownable_init();
    require(owner() != address(0), 'Zap: owner must be set');

    setNotFlip(CAKE);
    setNotFlip(BUNNY);
    setNotFlip(WBNB);
    setNotFlip(BUSD);
    setNotFlip(USDT);
    setNotFlip(DAI);
    setNotFlip(USDC);
    setNotFlip(VAI);
    setNotFlip(BTCB);
    setNotFlip(ETH);
    setNotFlip(DOT);

    setRoutePairAddress(VAI, BUSD);
    setRoutePairAddress(USDC, BUSD);
    setRoutePairAddress(DAI, BUSD);
  }

  receive() external payable {}

  /* ========== View Functions ========== */

  function isFlip(address _address) public view returns (bool) {
    return !notFlip[_address];
  }

  function routePair(address _address) external view returns (address) {
    return routePairAddresses[_address];
  }

  /* ========== External Functions ========== */

  function zapInToken(
    address _from,
    uint256 amount,
    address _to
  ) external override {
    IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
    _approveTokenIfNeeded(_from);

    if (isFlip(_to)) {
      IPancakePair pair = IPancakePair(_to);
      address token0 = pair.token0();
      address token1 = pair.token1();
      if (_from == token0 || _from == token1) {
        // swap half amount for other
        address other = _from == token0 ? token1 : token0;
        _approveTokenIfNeeded(other);
        uint256 sellAmount = amount.div(2);
        uint256 otherAmount = _swap(_from, sellAmount, other, address(this));
        ROUTER.addLiquidity(
          _from,
          other,
          amount.sub(sellAmount),
          otherAmount,
          0,
          0,
          msg.sender,
          block.timestamp
        );
      } else {
        uint256 bnbAmount = _from == WBNB
          ? _safeSwapToBNB(amount)
          : _swapTokenForBNB(_from, amount, address(this));
        _swapBNBToFlip(_to, bnbAmount, msg.sender);
      }
    } else {
      _swap(_from, amount, _to, msg.sender);
    }
  }

  function zapIn(address _to) external payable override {
    _swapBNBToFlip(_to, msg.value, msg.sender);
  }

  function zapOut(address _from, uint256 amount) external override {
    IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
    _approveTokenIfNeeded(_from);

    if (!isFlip(_from)) {
      _swapTokenForBNB(_from, amount, msg.sender);
    } else {
      IPancakePair pair = IPancakePair(_from);
      address token0 = pair.token0();
      address token1 = pair.token1();
      if (token0 == WBNB || token1 == WBNB) {
        ROUTER.removeLiquidityETH(
          token0 != WBNB ? token0 : token1,
          amount,
          0,
          0,
          msg.sender,
          block.timestamp
        );
      } else {
        ROUTER.removeLiquidity(
          token0,
          token1,
          amount,
          0,
          0,
          msg.sender,
          block.timestamp
        );
      }
    }
  }

  /* ========== Private Functions ========== */

  function _approveTokenIfNeeded(address token) private {
    if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
      IBEP20(token).safeApprove(address(ROUTER), uint256(-1));
    }
  }

  function _swapBNBToFlip(
    address flip,
    uint256 amount,
    address receiver
  ) private {
    if (!isFlip(flip)) {
      _swapBNBForToken(flip, amount, receiver);
    } else {
      // flip
      IPancakePair pair = IPancakePair(flip);
      address token0 = pair.token0();
      address token1 = pair.token1();
      if (token0 == WBNB || token1 == WBNB) {
        address token = token0 == WBNB ? token1 : token0;
        uint256 swapValue = amount.div(2);
        uint256 tokenAmount = _swapBNBForToken(token, swapValue, address(this));

        _approveTokenIfNeeded(token);
        ROUTER.addLiquidityETH{ value: amount.sub(swapValue) }(
          token,
          tokenAmount,
          0,
          0,
          receiver,
          block.timestamp
        );
      } else {
        uint256 swapValue = amount.div(2);
        uint256 token0Amount = _swapBNBForToken(
          token0,
          swapValue,
          address(this)
        );
        uint256 token1Amount = _swapBNBForToken(
          token1,
          amount.sub(swapValue),
          address(this)
        );

        _approveTokenIfNeeded(token0);
        _approveTokenIfNeeded(token1);
        ROUTER.addLiquidity(
          token0,
          token1,
          token0Amount,
          token1Amount,
          0,
          0,
          receiver,
          block.timestamp
        );
      }
    }
  }

  function _swapBNBForToken(
    address token,
    uint256 value,
    address receiver
  ) private returns (uint256) {
    address[] memory path;

    if (routePairAddresses[token] != address(0)) {
      path = new address[](3);
      path[0] = WBNB;
      path[1] = routePairAddresses[token];
      path[2] = token;
    } else {
      path = new address[](2);
      path[0] = WBNB;
      path[1] = token;
    }

    uint256[] memory amounts = ROUTER.swapExactETHForTokens{ value: value }(
      0,
      path,
      receiver,
      block.timestamp
    );
    return amounts[amounts.length - 1];
  }

  function _swapTokenForBNB(
    address token,
    uint256 amount,
    address receiver
  ) private returns (uint256) {
    address[] memory path;
    if (routePairAddresses[token] != address(0)) {
      path = new address[](3);
      path[0] = token;
      path[1] = routePairAddresses[token];
      path[2] = WBNB;
    } else {
      path = new address[](2);
      path[0] = token;
      path[1] = WBNB;
    }

    uint256[] memory amounts = ROUTER.swapExactTokensForETH(
      amount,
      0,
      path,
      receiver,
      block.timestamp
    );
    return amounts[amounts.length - 1];
  }

  function _swap(
    address _from,
    uint256 amount,
    address _to,
    address receiver
  ) private returns (uint256) {
    address intermediate = routePairAddresses[_from];
    if (intermediate == address(0)) {
      intermediate = routePairAddresses[_to];
    }

    address[] memory path;
    if (intermediate != address(0) && (_from == WBNB || _to == WBNB)) {
      // [WBNB, BUSD, VAI] or [VAI, BUSD, WBNB]
      path = new address[](3);
      path[0] = _from;
      path[1] = intermediate;
      path[2] = _to;
    } else if (
      intermediate != address(0) &&
      (_from == intermediate || _to == intermediate)
    ) {
      // [VAI, BUSD] or [BUSD, VAI]
      path = new address[](2);
      path[0] = _from;
      path[1] = _to;
    } else if (
      intermediate != address(0) &&
      routePairAddresses[_from] == routePairAddresses[_to]
    ) {
      // [VAI, DAI] or [VAI, USDC]
      path = new address[](3);
      path[0] = _from;
      path[1] = intermediate;
      path[2] = _to;
    } else if (
      routePairAddresses[_from] != address(0) &&
      routePairAddresses[_to] != address(0) &&
      routePairAddresses[_from] != routePairAddresses[_to]
    ) {
      // routePairAddresses[xToken] = xRoute
      // [VAI, BUSD, WBNB, xRoute, xToken]
      path = new address[](5);
      path[0] = _from;
      path[1] = routePairAddresses[_from];
      path[2] = WBNB;
      path[3] = routePairAddresses[_to];
      path[4] = _to;
    } else if (
      intermediate != address(0) && routePairAddresses[_from] != address(0)
    ) {
      // [VAI, BUSD, WBNB, BUNNY]
      path = new address[](4);
      path[0] = _from;
      path[1] = intermediate;
      path[2] = WBNB;
      path[3] = _to;
    } else if (
      intermediate != address(0) && routePairAddresses[_to] != address(0)
    ) {
      // [BUNNY, WBNB, BUSD, VAI]
      path = new address[](4);
      path[0] = _from;
      path[1] = WBNB;
      path[2] = intermediate;
      path[3] = _to;
    } else if (_from == WBNB || _to == WBNB) {
      // [WBNB, BUNNY] or [BUNNY, WBNB]
      path = new address[](2);
      path[0] = _from;
      path[1] = _to;
    } else {
      // [USDT, BUNNY] or [BUNNY, USDT]
      path = new address[](3);
      path[0] = _from;
      path[1] = WBNB;
      path[2] = _to;
    }

    uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
      amount,
      0,
      path,
      receiver,
      block.timestamp
    );
    return amounts[amounts.length - 1];
  }

  function _safeSwapToBNB(uint256 amount) private returns (uint256) {
    require(
      IBEP20(WBNB).balanceOf(address(this)) >= amount,
      'Zap: Not enough WBNB balance'
    );
    require(safeSwapBNB != address(0), 'Zap: safeSwapBNB is not set');
    uint256 beforeBNB = address(this).balance;
    ISafeSwapBNB(safeSwapBNB).withdraw(amount);
    return (address(this).balance).sub(beforeBNB);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setRoutePairAddress(address asset, address route) public onlyOwner {
    routePairAddresses[asset] = route;
  }

  function setNotFlip(address token) public onlyOwner {
    bool needPush = notFlip[token] == false;
    notFlip[token] = true;
    if (needPush) {
      tokens.push(token);
    }
  }

  function removeToken(uint256 i) external onlyOwner {
    address token = tokens[i];
    notFlip[token] = false;
    tokens[i] = tokens[tokens.length - 1];
    tokens.pop();
  }

  function sweep() external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      if (token == address(0)) continue;
      uint256 amount = IBEP20(token).balanceOf(address(this));
      if (amount > 0) {
        _swapTokenForBNB(token, amount, owner());
      }
    }
  }

  function withdraw(address token) external onlyOwner {
    if (token == address(0)) {
      payable(owner()).transfer(address(this).balance);
      return;
    }

    IBEP20(token).transfer(owner(), IBEP20(token).balanceOf(address(this)));
  }

  function setSafeSwapBNB(address _safeSwapBNB) external onlyOwner {
    require(safeSwapBNB == address(0), 'Zap: safeSwapBNB already set!');
    safeSwapBNB = _safeSwapBNB;
    IBEP20(WBNB).approve(_safeSwapBNB, uint256(-1));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IZap {
  function zapOut(address _from, uint256 amount) external;

  function zapIn(address _to) external payable;

  function zapInToken(
    address _from,
    uint256 amount,
    address _to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ISafeSwapBNB {
  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '../../library/WhitelistUpgradeable.sol';

import '../../interfaces/IPriceCalculator.sol';
import '../../zap/ZapBSC.sol';
import './VaultCompensation.sol';

contract CompensationTreasury is WhitelistUpgradeable {
  using SafeBEP20 for IBEP20;
  using SafeMath for uint256;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  address public constant keeper = 0xF49AD469e4A12921d0373C1EFDE108469Bac652f;

  IPriceCalculator public constant priceCalculator =
    IPriceCalculator(0xF5BF8A9249e3cc4cB684E3f23db9669323d4FB7d);
  ZapBSC public constant zapBSC =
    ZapBSC(0xdC2bBB0D33E0e7Dea9F5b98F46EDBaC823586a0C);

  address public constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
  address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
  address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
  address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address public constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
  address public constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
  address public constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

  address public constant BUNNY_BNB =
    0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
  address public constant CAKE_BNB = 0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;
  address public constant USDT_BNB = 0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE;
  address public constant BUSD_BNB = 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;
  address public constant USDT_BUSD =
    0x7EFaEf62fDdCCa950418312c6C91Aef321375A00;
  address public constant VAI_BUSD = 0x133ee93FE93320e1182923E1a640912eDE17C90C;
  address public constant ETH_BNB = 0x74E4716E431f45807DCF19f284c7aA99F18a4fbc;
  address public constant BTCB_BNB = 0x61EB789d75A95CAa3fF50ed7E47b96c132fEc082;

  /* ========== STATE VARIABLES ========== */

  VaultCompensation public vaultCompensation;

  /* ========== MODIFIERS ========== */

  modifier onlyKeeper() {
    require(
      msg.sender == keeper || msg.sender == owner(),
      'CompTreasury: caller is not the owner or keeper'
    );
    _;
  }

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  function initialize() external initializer {
    __Ownable_init();
  }

  /* ========== VIEW FUNCTIONS ========== */

  function redundantTokens() public pure returns (address[5] memory) {
    return [USDT, BUSD, VAI, ETH, BTCB];
  }

  function flips() public pure returns (address[8] memory) {
    return [
      BUNNY_BNB,
      CAKE_BNB,
      USDT_BNB,
      BUSD_BNB,
      USDT_BUSD,
      VAI_BUSD,
      ETH_BNB,
      BTCB_BNB
    ];
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setVaultCompensation(address payable _vaultCompensation)
    public
    onlyKeeper
  {
    vaultCompensation = VaultCompensation(_vaultCompensation);
  }

  function compensate() public onlyKeeper {
    require(
      address(vaultCompensation) != address(0),
      'CompTreasury: vault compensation must be set'
    );
    _convertTokens();

    address[] memory _tokens = vaultCompensation.rewardTokens();
    uint256[] memory _amounts = new uint256[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _amount = _tokens[i] == WBNB
        ? address(this).balance
        : IBEP20(_tokens[i]).balanceOf(address(this));
      if (_amount > 0) {
        if (_tokens[i] == WBNB) {
          SafeToken.safeTransferETH(address(vaultCompensation), _amount);
        } else {
          IBEP20(_tokens[i]).safeTransfer(address(vaultCompensation), _amount);
        }
      }
      _amounts[i] = _amount;
    }
    vaultCompensation.notifyRewardAmounts(_amounts);
  }

  function buyback() public onlyKeeper {
    uint256 balance = Math.min(IBEP20(CAKE).balanceOf(address(this)), 2000e18);
    if (balance > 0) {
      if (IBEP20(CAKE).allowance(address(this), address(zapBSC)) == 0) {
        IBEP20(CAKE).approve(address(zapBSC), uint256(-1));
      }
      zapBSC.zapInToken(CAKE, balance, BUNNY);
    }
  }

  function splitPairs() public onlyKeeper {
    address[8] memory _flips = flips();
    for (uint256 i = 0; i < _flips.length; i++) {
      address flip = _flips[i];
      uint256 balance = IBEP20(flip).balanceOf(address(this));
      if (balance > 0) {
        if (IBEP20(flip).allowance(address(this), address(zapBSC)) == 0) {
          IBEP20(flip).approve(address(zapBSC), uint256(-1));
        }
        zapBSC.zapOut(_flips[i], IBEP20(_flips[i]).balanceOf(address(this)));
      }
    }
  }

  function covertTokensPartial(
    address[] memory _tokens,
    uint256[] memory _amounts
  ) public onlyKeeper {
    for (uint256 i = 0; i < _tokens.length; i++) {
      address token = _tokens[i];
      uint256 balance = IBEP20(token).balanceOf(address(this));
      if (balance >= _amounts[i]) {
        if (IBEP20(token).allowance(address(this), address(zapBSC)) == 0) {
          IBEP20(token).approve(address(zapBSC), uint256(-1));
        }
        zapBSC.zapOut(_tokens[i], _amounts[i]);
      }
    }
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _convertTokens() private {
    splitPairs();

    address[5] memory _tokens = redundantTokens();
    for (uint256 i = 0; i < _tokens.length; i++) {
      address token = _tokens[i];
      uint256 balance = IBEP20(token).balanceOf(address(this));
      if (balance > 0) {
        if (IBEP20(token).allowance(address(this), address(zapBSC)) == 0) {
          IBEP20(token).approve(address(zapBSC), uint256(-1));
        }
        zapBSC.zapOut(_tokens[i], balance);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';

import '../library/WhitelistUpgradeable.sol';
import '../library/SafeToken.sol';

import '../interfaces/IGoenPool.sol';
import '../interfaces/ISafeSwapBNB.sol';
import '../interfaces/IZap.sol';

contract BunnyFeeBox is WhitelistUpgradeable {
  using SafeBEP20 for IBEP20;
  using SafeMath for uint256;
  using SafeToken for address;

  /* ========== CONSTANT ========== */

  ISafeSwapBNB public constant safeSwapBNB =
    ISafeSwapBNB(0x8D36CB4C0aEa63ca095d9E26aeFb360D279176B0);
  IZap public constant zapBSC =
    IZap(0xdC2bBB0D33E0e7Dea9F5b98F46EDBaC823586a0C);

  address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address private constant GOEN = 0xa093D11E9B4aB850B77f64307F55640A75c580d2;
  address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
  address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
  address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address private constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
  address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
  address private constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
  address private constant DOT = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402;
  address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;

  address private constant BUNNY_BNB =
    0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
  address private constant CAKE_BNB =
    0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;
  address private constant USDT_BNB =
    0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE;
  address private constant BUSD_BNB =
    0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;
  address private constant USDT_BUSD =
    0x7EFaEf62fDdCCa950418312c6C91Aef321375A00;
  address private constant VAI_BUSD =
    0x133ee93FE93320e1182923E1a640912eDE17C90C;
  address private constant ETH_BNB = 0x74E4716E431f45807DCF19f284c7aA99F18a4fbc;
  address private constant BTCB_BNB =
    0x61EB789d75A95CAa3fF50ed7E47b96c132fEc082;
  address private constant DOT_BNB = 0xDd5bAd8f8b360d76d12FdA230F8BAF42fe0022CF;
  address private constant BTCB_BUSD =
    0xF45cd219aEF8618A92BAa7aD848364a158a24F33;
  address private constant DAI_BUSD =
    0x66FDB2eCCfB58cF098eaa419e5EfDe841368e489;
  address private constant USDC_BUSD =
    0x2354ef4DF11afacb85a5C7f98B624072ECcddbB1;

  /* ========== STATE VARIABLES ========== */

  address public keeper;
  address public bunnyPool;

  /* ========== MODIFIERS ========== */

  modifier onlyKeeper() {
    require(
      msg.sender == keeper || msg.sender == owner(),
      'BunnyFeeBox: caller is not the owner or keeper'
    );
    _;
  }

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  function initialize() external initializer {
    __WhitelistUpgradeable_init();
  }

  /* ========== VIEWS ========== */

  function redundantTokens() public pure returns (address[8] memory) {
    return [USDT, BUSD, VAI, ETH, BTCB, USDC, DAI, DOT];
  }

  function flips() public pure returns (address[12] memory) {
    return [
      BUNNY_BNB,
      CAKE_BNB,
      USDT_BNB,
      BUSD_BNB,
      USDT_BUSD,
      VAI_BUSD,
      ETH_BNB,
      BTCB_BNB,
      DOT_BNB,
      BTCB_BUSD,
      DAI_BUSD,
      USDC_BUSD
    ];
  }

  function pendingRewards()
    public
    view
    returns (
      uint256 bnb,
      uint256 cake,
      uint256 bunny
    )
  {
    bnb = address(this).balance;
    cake = IBEP20(CAKE).balanceOf(address(this));
    bunny = IBEP20(GOEN).balanceOf(address(this));
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setKeeper(address _keeper) external onlyOwner {
    keeper = _keeper;
  }

  function setBunnyPool(address _bunnyPool) external onlyOwner {
    bunnyPool = _bunnyPool;
  }

  function swapToRewards() public onlyKeeper {
    require(bunnyPool != address(0), 'BunnyFeeBox: BunnyPool must be set');

    address[] memory _tokens = IGoenPool(bunnyPool).rewardTokens();
    uint256[] memory _amounts = new uint256[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _amount = _tokens[i] == WBNB
        ? address(this).balance
        : IBEP20(_tokens[i]).balanceOf(address(this));
      if (_amount > 0) {
        if (_tokens[i] == WBNB) {
          SafeToken.safeTransferETH(bunnyPool, _amount);
        } else {
          IBEP20(_tokens[i]).safeTransfer(bunnyPool, _amount);
        }
      }
      _amounts[i] = _amount;
    }

    IGoenPool(bunnyPool).notifyRewardAmounts(_amounts);
  }

  function harvest() external onlyKeeper {
    splitPairs();

    address[8] memory _tokens = redundantTokens();
    for (uint256 i = 0; i < _tokens.length; i++) {
      _convertToken(_tokens[i], IBEP20(_tokens[i]).balanceOf(address(this)));
    }

    swapToRewards();
  }

  function splitPairs() public onlyKeeper {
    address[12] memory _flips = flips();
    for (uint256 i = 0; i < _flips.length; i++) {
      _convertToken(_flips[i], IBEP20(_flips[i]).balanceOf(address(this)));
    }
  }

  function covertTokensPartial(
    address[] memory _tokens,
    uint256[] memory _amounts
  ) external onlyKeeper {
    for (uint256 i = 0; i < _tokens.length; i++) {
      _convertToken(_tokens[i], _amounts[i]);
    }
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _convertToken(address token, uint256 amount) private {
    uint256 balance = IBEP20(token).balanceOf(address(this));
    if (amount > 0 && balance >= amount) {
      if (IBEP20(token).allowance(address(this), address(zapBSC)) == 0) {
        IBEP20(token).approve(address(zapBSC), uint256(-1));
      }
      zapBSC.zapOut(token, amount);
    }
  }

  // @dev use when WBNB received from minter
  function _unwrap(uint256 amount) private {
    uint256 balance = IBEP20(WBNB).balanceOf(address(this));
    if (amount > 0 && balance >= amount) {
      if (IBEP20(WBNB).allowance(address(this), address(safeSwapBNB)) == 0) {
        IBEP20(WBNB).approve(address(safeSwapBNB), uint256(-1));
      }

      safeSwapBNB.withdraw(amount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/Math.sol';

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

import '../library/SafeToken.sol';

import '../interfaces/IGoenPool.sol';

import './VaultController.sol';

contract GoenPoolV2 is IGoenPool, VaultController, ReentrancyGuardUpgradeable {
  using SafeBEP20 for IBEP20;
  using SafeMath for uint256;
  using SafeToken for address;

  /* ========== CONSTANT ========== */

  address public constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F;
  address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
  address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
  address public constant MINTER = 0x8cB88701790F650F273c8BB2Cc4c5f439cd65219;
  address public constant FEE_BOX = 0x3749f69B2D99E5586D95d95B6F9B5252C71894bb;

  struct RewardInfo {
    address token;
    uint256 rewardPerTokenStored;
    uint256 rewardRate;
    uint256 lastUpdateTime;
  }

  /* ========== STATE VARIABLES ========== */

  address public rewardsDistribution;

  uint256 public periodFinish;
  uint256 public rewardsDuration;
  uint256 public totalSupply;

  address[] private _rewardTokens;
  mapping(address => RewardInfo) public rewards;
  mapping(address => mapping(address => uint256)) public userRewardPerToken;
  mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;

  mapping(address => uint256) private _balances;

  /* ========== EVENTS ========== */

  event Deposited(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);

  event RewardsAdded(uint256[] amounts);
  event RewardsPaid(address indexed user, address token, uint256 amount);
  event BunnyPaid(address indexed user, uint256 profit, uint256 performanceFee);
  event Recovered(address token, uint256 amount);

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  function initialize() external initializer {
    __VaultController_init(IBEP20(BUNNY));
    __ReentrancyGuard_init();

    rewardsDuration = 30 days;
    rewardsDistribution = FEE_BOX;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyRewardsDistribution() {
    require(
      msg.sender == rewardsDistribution,
      'BunnyPoolV2: caller is not the rewardsDistribution'
    );
    _;
  }

  modifier updateRewards(address account) {
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      RewardInfo storage rewardInfo = rewards[_rewardTokens[i]];
      rewardInfo.rewardPerTokenStored = rewardPerToken(rewardInfo.token);
      rewardInfo.lastUpdateTime = lastTimeRewardApplicable();

      if (account != address(0)) {
        userRewardPerToken[account][rewardInfo.token] = earnedPerToken(
          account,
          rewardInfo.token
        );
        userRewardPerTokenPaid[account][rewardInfo.token] = rewardInfo
          .rewardPerTokenStored;
      }
    }
    _;
  }

  modifier canStakeTo() {
    require(
      msg.sender == owner() || msg.sender == MINTER,
      'BunnyPoolV2: no auth'
    );
    _;
  }

  /* ========== VIEWS ========== */

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function earned(address account)
    public
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory pendingRewards = new uint256[](_rewardTokens.length);
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      pendingRewards[i] = earnedPerToken(account, _rewardTokens[i]);
    }
    return pendingRewards;
  }

  function earnedPerToken(address account, address token)
    public
    view
    returns (uint256)
  {
    return
      _balances[account]
        .mul(rewardPerToken(token).sub(userRewardPerTokenPaid[account][token]))
        .div(1e18)
        .add(userRewardPerToken[account][token]);
  }

  function rewardTokens() public view override returns (address[] memory) {
    return _rewardTokens;
  }

  function rewardPerToken(address token) public view returns (uint256) {
    if (totalSupply == 0) return rewards[token].rewardPerTokenStored;
    return
      rewards[token].rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(rewards[token].lastUpdateTime)
          .mul(rewards[token].rewardRate)
          .mul(1e18)
          .div(totalSupply)
      );
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addRewardsToken(address _rewardsToken) public onlyOwner {
    require(_rewardsToken != address(0), 'BunnyPoolV2: BNB uses WBNB address');
    require(
      rewards[_rewardsToken].token == address(0),
      'BunnyPoolV2: duplicated rewards token'
    );
    rewards[_rewardsToken] = RewardInfo(_rewardsToken, 0, 0, 0);
    _rewardTokens.push(_rewardsToken);
  }

  function setRewardsDistribution(address _rewardsDistribution)
    public
    onlyOwner
  {
    rewardsDistribution = _rewardsDistribution;
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(
      periodFinish == 0 || block.timestamp > periodFinish,
      'BunnyPoolV2: invalid rewards duration'
    );
    rewardsDuration = _rewardsDuration;
  }

  function notifyRewardAmounts(uint256[] memory amounts)
    external
    override
    onlyRewardsDistribution
    updateRewards(address(0))
  {
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      RewardInfo storage rewardInfo = rewards[_rewardTokens[i]];
      if (block.timestamp >= periodFinish) {
        rewardInfo.rewardRate = amounts[i].div(rewardsDuration);
      } else {
        uint256 remaining = periodFinish.sub(block.timestamp);
        uint256 leftover = remaining.mul(rewardInfo.rewardRate);
        rewardInfo.rewardRate = amounts[i].add(leftover).div(rewardsDuration);
      }
      rewardInfo.lastUpdateTime = block.timestamp;

      // Ensure the provided reward amount is not more than the balance in the contract.
      // This keeps the reward rate in the right range, preventing overflows due to
      // very high values of rewardRate in the earned and rewardsPerToken functions;
      // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
      uint256 _balance;
      if (rewardInfo.token == WBNB) {
        _balance = address(this).balance;
      } else if (rewardInfo.token == BUNNY) {
        _balance = IBEP20(BUNNY).balanceOf(address(this)).sub(totalSupply);
      } else {
        _balance = IBEP20(rewardInfo.token).balanceOf(address(this));
      }

      require(
        rewardInfo.rewardRate <= _balance.div(rewardsDuration),
        'BunnyPoolV2: invalid rewards amount'
      );
    }

    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardsAdded(amounts);
  }

  function depositOnBehalf(uint256 _amount, address _to)
    external
    override
    canStakeTo
  {
    _deposit(_amount, _to);
  }

  /* ========== MUTATE FUNCTIONS ========== */

  function deposit(uint256 _amount) public override nonReentrant {
    _deposit(_amount, msg.sender);
  }

  function depositAll() public nonReentrant {
    _deposit(IBEP20(_stakingToken).balanceOf(msg.sender), msg.sender);
  }

  function withdraw(uint256 _amount)
    public
    override
    nonReentrant
    notPaused
    updateRewards(msg.sender)
  {
    require(_amount > 0, 'BunnyPoolV2: invalid amount');
    _bunnyChef.notifyWithdrawn(msg.sender, _amount);

    totalSupply = totalSupply.sub(_amount);
    _balances[msg.sender] = _balances[msg.sender].sub(_amount);
    IBEP20(_stakingToken).safeTransfer(msg.sender, _amount);
    emit Withdrawn(msg.sender, _amount);
  }

  function withdrawAll() external override {
    uint256 amount = _balances[msg.sender];
    if (amount > 0) {
      withdraw(amount);
    }

    getReward();
  }

  function getReward() public override nonReentrant updateRewards(msg.sender) {
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 reward = userRewardPerToken[msg.sender][_rewardTokens[i]];
      if (reward > 0) {
        userRewardPerToken[msg.sender][_rewardTokens[i]] = 0;

        if (_rewardTokens[i] == WBNB) {
          SafeToken.safeTransferETH(msg.sender, reward);
        } else {
          IBEP20(_rewardTokens[i]).safeTransfer(msg.sender, reward);
        }
        emit RewardsPaid(msg.sender, _rewardTokens[i], reward);
      }
    }

    uint256 bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
    emit BunnyPaid(msg.sender, bunnyAmount, 0);
  }

  /* ========== PRIVATE FUNCTIONS ========== */

  function _deposit(uint256 _amount, address _to)
    private
    notPaused
    updateRewards(_to)
  {
    IBEP20(_stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
    _bunnyChef.updateRewardsOf(address(this));

    totalSupply = totalSupply.add(_amount);
    _balances[_to] = _balances[_to].add(_amount);

    _bunnyChef.notifyDeposited(_to, _amount);
    emit Deposited(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/Math.sol';

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../library/legacy/RewardsDistributionRecipient.sol';
import '../library/legacy/Pausable.sol';
import '../interfaces/legacy/IStrategyHelper.sol';
import '../interfaces/IPancakeRouter02.sol';
import '../interfaces/legacy/IStrategyLegacy.sol';

interface IPresale {
  function totalBalance() external view returns (uint256);

  function flipToken() external view returns (address);
}

contract GoenPool is
  IStrategyLegacy,
  RewardsDistributionRecipient,
  ReentrancyGuard,
  Pausable
{
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  /* ========== STATE VARIABLES ========== */

  IBEP20 public rewardsToken; // bunny/bnb flip
  IBEP20 public constant stakingToken =
    IBEP20(0xa093D11E9B4aB850B77f64307F55640A75c580d2); // bunny
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration = 90 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  mapping(address => bool) private _stakePermission;

  /* ========== PRESALE ============== */
  address private constant presaleContract =
    0x641414e2a04c8f8EbBf49eD47cc87dccbA42BF07;
  address private constant deadAddress =
    0x000000000000000000000000000000000000dEaD;
  mapping(address => uint256) private _presaleBalance;
  uint256 private constant timestamp2HoursAfterPresaleEnds =
    1605585600 + (2 hours);
  uint256 private constant timestamp90DaysAfterPresaleEnds =
    1605585600 + (90 days);

  /* ========== BUNNY HELPER ========= */

  IStrategyHelper public helper =
    IStrategyHelper(0xA84c09C1a2cF4918CaEf625682B429398b97A1a0);
  IPancakeRouter02 private constant ROUTER_V1_DEPRECATED =
    IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);

  /* ========== CONSTRUCTOR ========== */

  constructor() public {
    rewardsDistribution = msg.sender;

    _stakePermission[msg.sender] = true;
    _stakePermission[presaleContract] = true;

    stakingToken.safeApprove(address(ROUTER_V1_DEPRECATED), uint256(-1));
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balance() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function presaleBalanceOf(address account) external view returns (uint256) {
    return _presaleBalance[account];
  }

  function principalOf(address account)
    external
    view
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function withdrawableBalanceOf(address account)
    public
    view
    override
    returns (uint256)
  {
    if (block.timestamp > timestamp90DaysAfterPresaleEnds) {
      // unlock all presale bunny after 90 days of presale
      return _balances[account];
    } else if (block.timestamp < timestamp2HoursAfterPresaleEnds) {
      return _balances[account].sub(_presaleBalance[account]);
    } else {
      uint256 soldInPresale = IPresale(presaleContract)
        .totalBalance()
        .div(2)
        .mul(3); // mint 150% of presale for making flip token
      uint256 bunnySupply = stakingToken.totalSupply().sub(
        stakingToken.balanceOf(deadAddress)
      );
      if (soldInPresale >= bunnySupply) {
        return _balances[account].sub(_presaleBalance[account]);
      }
      uint256 bunnyNewMint = bunnySupply.sub(soldInPresale);
      if (bunnyNewMint >= soldInPresale) {
        return _balances[account];
      }

      uint256 lockedRatio = (soldInPresale.sub(bunnyNewMint)).mul(1e18).div(
        soldInPresale
      );
      uint256 lockedBalance = _presaleBalance[account].mul(lockedRatio).div(
        1e18
      );
      return _balances[account].sub(lockedBalance);
    }
  }

  function profitOf(address account)
    public
    view
    override
    returns (
      uint256 _usd,
      uint256 _bunny,
      uint256 _bnb
    )
  {
    _usd = 0;
    _bunny = 0;
    _bnb = helper.tvlInBNB(address(rewardsToken), earned(account));
  }

  function tvl() public view override returns (uint256) {
    uint256 price = helper.tokenPriceInBNB(address(stakingToken));
    return _totalSupply.mul(price).div(1e18);
  }

  function apy()
    public
    view
    override
    returns (
      uint256 _usd,
      uint256 _bunny,
      uint256 _bnb
    )
  {
    uint256 tokenDecimals = 1e18;
    uint256 __totalSupply = _totalSupply;
    if (__totalSupply == 0) {
      __totalSupply = tokenDecimals;
    }

    uint256 rewardPerTokenPerSecond = rewardRate.mul(tokenDecimals).div(
      __totalSupply
    );
    uint256 bunnyPrice = helper.tokenPriceInBNB(address(stakingToken));
    uint256 flipPrice = helper.tvlInBNB(address(rewardsToken), 1e18);

    _usd = 0;
    _bunny = 0;
    _bnb = rewardPerTokenPerSecond.mul(365 days).mul(flipPrice).div(bunnyPrice);
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(_totalSupply)
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function _deposit(uint256 amount, address _to)
    private
    nonReentrant
    updateReward(_to)
  {
    require(amount > 0, 'amount');
    _totalSupply = _totalSupply.add(amount);
    _balances[_to] = _balances[_to].add(amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(_to, amount);
  }

  function deposit(uint256 amount) public override {
    _deposit(amount, msg.sender);
  }

  function depositAll() external override {
    deposit(stakingToken.balanceOf(msg.sender));
  }

  function withdraw(uint256 amount)
    public
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, 'amount');
    require(amount <= withdrawableBalanceOf(msg.sender), 'locked');
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function withdrawAll() external override {
    uint256 _withdraw = withdrawableBalanceOf(msg.sender);
    if (_withdraw > 0) {
      withdraw(_withdraw);
    }
    getReward();
  }

  function getReward() public override nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      reward = _flipToWBNB(reward);
      IBEP20(ROUTER_V1_DEPRECATED.WETH()).safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function _flipToWBNB(uint256 amount) private returns (uint256 reward) {
    address wbnb = ROUTER_V1_DEPRECATED.WETH();
    (uint256 rewardBunny, ) = ROUTER_V1_DEPRECATED.removeLiquidity(
      address(stakingToken),
      wbnb,
      amount,
      0,
      0,
      address(this),
      block.timestamp
    );
    address[] memory path = new address[](2);
    path[0] = address(stakingToken);
    path[1] = wbnb;
    ROUTER_V1_DEPRECATED.swapExactTokensForTokens(
      rewardBunny,
      0,
      path,
      address(this),
      block.timestamp
    );

    reward = IBEP20(wbnb).balanceOf(address(this));
  }

  function harvest() external override {}

  function info(address account)
    external
    view
    override
    returns (UserInfo memory)
  {
    UserInfo memory userInfo;

    userInfo.balance = _balances[account];
    userInfo.principal = _balances[account];
    userInfo.available = withdrawableBalanceOf(account);

    Profit memory profit;
    (uint256 usd, uint256 bunny, uint256 bnb) = profitOf(account);
    profit.usd = usd;
    profit.bunny = bunny;
    profit.bnb = bnb;
    userInfo.profit = profit;

    userInfo.poolTVL = tvl();

    APY memory poolAPY;
    (usd, bunny, bnb) = apy();
    poolAPY.usd = usd;
    poolAPY.bunny = bunny;
    poolAPY.bnb = bnb;
    userInfo.poolAPY = poolAPY;

    return userInfo;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  function setRewardsToken(address _rewardsToken) external onlyOwner {
    require(address(rewardsToken) == address(0), 'set rewards token already');

    rewardsToken = IBEP20(_rewardsToken);
    IBEP20(_rewardsToken).safeApprove(
      address(ROUTER_V1_DEPRECATED),
      uint256(-1)
    );
  }

  function setHelper(IStrategyHelper _helper) external onlyOwner {
    require(address(_helper) != address(0), 'zero address');
    helper = _helper;
  }

  function setStakePermission(address _address, bool permission)
    external
    onlyOwner
  {
    _stakePermission[_address] = permission;
  }

  function stakeTo(uint256 amount, address _to) external canStakeTo {
    _deposit(amount, _to);
    if (msg.sender == presaleContract) {
      _presaleBalance[_to] = _presaleBalance[_to].add(amount);
    }
  }

  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyRewardsDistribution
    updateReward(address(0))
  {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 _balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= _balance.div(rewardsDuration), 'reward');

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardAdded(reward);
  }

  function recoverBEP20(address tokenAddress, uint256 tokenAmount)
    external
    onlyOwner
  {
    require(
      tokenAddress != address(stakingToken) &&
        tokenAddress != address(rewardsToken),
      'tokenAddress'
    );
    IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(periodFinish == 0 || block.timestamp > periodFinish, 'period');
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  modifier canStakeTo() {
    require(_stakePermission[msg.sender], 'auth');
    _;
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address token, uint256 amount);
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

abstract contract RewardsDistributionRecipient is Ownable {
  address public rewardsDistribution;

  modifier onlyRewardsDistribution() {
    require(msg.sender == rewardsDistribution, 'onlyRewardsDistribution');
    _;
  }

  function notifyRewardAmount(uint256 reward) external virtual;

  function setRewardsDistribution(address _rewardsDistribution)
    external
    onlyOwner
  {
    rewardsDistribution = _rewardsDistribution;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';

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
  constructor() public {
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
    require(!paused(), 'Pausable: paused');
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
    require(paused(), 'Pausable: not paused');
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
pragma solidity ^0.6.12;

import '../IGoenMinter.sol';

interface IStrategyHelper {
  function tokenPriceInBNB(address _token) external view returns (uint256);

  function cakePriceInBNB() external view returns (uint256);

  function bnbPriceInUSD() external view returns (uint256);

  function flipPriceInBNB(address _flip) external view returns (uint256);

  function flipPriceInUSD(address _flip) external view returns (uint256);

  function profitOf(
    IGoenMinter minter,
    address _flip,
    uint256 amount
  )
    external
    view
    returns (
      uint256 _usd,
      uint256 _bunny,
      uint256 _bnb
    );

  function tvl(address _flip, uint256 amount) external view returns (uint256); // in USD

  function tvlInBNB(address _flip, uint256 amount)
    external
    view
    returns (uint256); // in BNB

  function apy(IGoenMinter minter, uint256 pid)
    external
    view
    returns (
      uint256 _usd,
      uint256 _bunny,
      uint256 _bnb
    );

  function compoundingAPY(uint256 pid, uint256 compoundUnit)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

interface IStrategyLegacy {
  struct Profit {
    uint256 usd;
    uint256 bunny;
    uint256 bnb;
  }

  struct APY {
    uint256 usd;
    uint256 bunny;
    uint256 bnb;
  }

  struct UserInfo {
    uint256 balance;
    uint256 principal;
    uint256 available;
    Profit profit;
    uint256 poolTVL;
    APY poolAPY;
  }

  function deposit(uint256 _amount) external;

  function depositAll() external;

  function withdraw(uint256 _amount) external; // BUNNY STAKING POOL ONLY

  function withdrawAll() external;

  function getReward() external; // BUNNY STAKING POOL ONLY

  function harvest() external;

  function balance() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function principalOf(address account) external view returns (uint256);

  function withdrawableBalanceOf(address account)
    external
    view
    returns (uint256); // BUNNY STAKING POOL ONLY

  function profitOf(address account)
    external
    view
    returns (
      uint256 _usd,
      uint256 _bunny,
      uint256 _bnb
    );

  //    function earned(address account) external view returns (uint);
  function tvl() external view returns (uint256); // in USD

  function apy()
    external
    view
    returns (
      uint256 _usd,
      uint256 _bunny,
      uint256 _bnb
    );

  /* ========== Strategy Information ========== */
  //    function pid() external view returns (uint);
  //    function poolType() external view returns (PoolTypes);
  //    function isMinter() external view returns (bool, address);
  //    function getDepositedAt(address account) external view returns (uint);
  //    function getRewardsToken() external view returns (address);

  function info(address account) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

import '../interfaces/IBank.sol';

contract BankConfig is IBankConfig, Ownable {
  /// The portion of interests allocated to the reserve pool.
  uint256 public override getReservePoolBps;

  /// Interest rate model
  InterestModel public interestModel;

  constructor(uint256 _reservePoolBps, InterestModel _interestModel) public {
    setParams(_reservePoolBps, _interestModel);
  }

  /// @dev Set all the basic parameters. Must only be called by the owner.
  /// @param _reservePoolBps The new interests allocated to the reserve pool value.
  /// @param _interestModel The new interest rate model contract.
  function setParams(uint256 _reservePoolBps, InterestModel _interestModel)
    public
    onlyOwner
  {
    getReservePoolBps = _reservePoolBps;
    interestModel = _interestModel;
  }

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating)
    external
    view
    override
    returns (uint256)
  {
    return interestModel.getInterestRate(debt, floating);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

contract TripleSlopeModel {
  using SafeMath for uint256;

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating)
    external
    pure
    returns (uint256)
  {
    uint256 total = debt.add(floating);
    if (total == 0) return 0;

    uint256 utilization = debt.mul(10000).div(total);
    if (utilization < 5000) {
      // Less than 50% utilization - 10% APY
      return uint256(10e16) / 365 days;
    } else if (utilization < 9500) {
      // Between 50% and 95% - 10%-25% APY
      return (10e16 + utilization.sub(5000).mul(15e16).div(4500)) / 365 days;
    } else if (utilization < 10000) {
      // Between 95% and 100% - 25%-100% APY
      return (25e16 + utilization.sub(9500).mul(75e16).div(500)) / 365 days;
    } else {
      // Not possible, but just in case - 100% APY
      return uint256(100e16) / 365 days;
    }
  }
}

