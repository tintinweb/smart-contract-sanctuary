//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {
  IERC20,
  ILendingPoolAddressesProvider,
  ILendingPool,
  IProtocolDataProvider,
  IPriceOracleGetter,
  IDebtToken,
  IFlashloanAdapter
} from "./utils/Interfaces.sol";
import { SafeERC20, DataTypes } from "./utils/Libraries.sol";
import { DangoMath } from "./utils/DangoMath.sol";

contract FluidLeverage is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, DangoMath {
  using SafeMathUpgradeable for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant REBALANCE_DELAY = 8640;
  uint256 public constant REBALANCE_GRACE_PERIOD = 720;

  uint8 private immutable debtDecimals;
  uint8 private immutable collDecimals;

  ILendingPoolAddressesProvider public immutable AAVE_ADDRESSES_PROVIDER;
  IProtocolDataProvider public immutable AAVE_DATA_PROVIDER;
  IERC20 public immutable COLLATERAL_ASSET;
  IERC20 public immutable DEBT_ASSET;
  uint256 public immutable targetLeverageRatio;
  uint256 public immutable lowerLeverageLimit;
  uint256 public immutable upperLeverageLimit;

  ILendingPool public AAVE_LENDING_POOL;
  IPriceOracleGetter public AAVE_ORACLE;
  address public flashloanAdapter;
  address public feeCollector;
  uint256 public mintFee;
  uint256 public burnFee;
  uint256 public indexPrice;
  uint256 public lastRebalancingTime;

  constructor(
    ILendingPoolAddressesProvider _provider,
    IProtocolDataProvider _dataProvider,
    IERC20 _collateral,
    IERC20 _debt,
    uint256 _target,
    uint256 _lower,
    uint256 _upper
  ) {
    address _aToken;

    (_aToken, , ) = _dataProvider.getReserveTokensAddresses(address(_collateral));
    require(_aToken != address(0x0), "invalid-collateral-address");

    (_aToken, , ) = _dataProvider.getReserveTokensAddresses(address(_debt));
    require(_aToken != address(0x0), "invalid-collateral-address");

    require(_lower < _target && _upper > _target, "target-lev-out-of-range");
    require(_target > 1e18, "invalid-target-lev");

    AAVE_ADDRESSES_PROVIDER = _provider;
    AAVE_DATA_PROVIDER = _dataProvider;

    COLLATERAL_ASSET = _collateral;
    DEBT_ASSET = _debt;

    targetLeverageRatio = _target;
    lowerLeverageLimit = _lower;
    upperLeverageLimit = _upper;

    collDecimals = _collateral.decimals();
    debtDecimals = _debt.decimals();
  }

  function initialize(
    string calldata _name,
    string calldata _symbol,
    address _flashloanAdapter,
    address _feeCollector,
    uint256 _mintFee,
    uint256 _burnFee
  ) initializer public {
    require(_mintFee <= 1e16, "mint-fee-too-large");
    require(_burnFee <= 3e16, "burn-fee-too-large");

    __Ownable_init();
    __ERC20_init(_name, _symbol);
    __ReentrancyGuard_init();

    AAVE_LENDING_POOL = ILendingPool(AAVE_ADDRESSES_PROVIDER.getLendingPool());
    AAVE_ORACLE = IPriceOracleGetter(AAVE_ADDRESSES_PROVIDER.getPriceOracle());

    indexPrice = 1e18;
    flashloanAdapter = _flashloanAdapter;
    feeCollector = _feeCollector;
    mintFee = _mintFee;
    burnFee = _burnFee;
    lastRebalancingTime = block.timestamp;
  }

  modifier onlyFlashloanAdapter() {
    require(msg.sender == flashloanAdapter, "access-denied-not-flashloan-adapter");
    _;
  }

  function deposit(uint256 _amt) external nonReentrant {
    (uint256 _fee, uint256 _finalAmt) = _calculateMintFee(_amt);
    COLLATERAL_ASSET.safeTransferFrom(msg.sender, feeCollector, _fee);
    COLLATERAL_ASSET.safeTransferFrom(msg.sender, flashloanAdapter, _finalAmt);

    DataTypes.FlashloanData memory _data;

    _data.opType = 2;
    _data.userDepositAmt = _finalAmt;
    _data.flashAsset = address(DEBT_ASSET);
    _data.targetAsset = address(COLLATERAL_ASSET);

    if (collDecimals != 18) {
      _finalAmt = wdiv(_finalAmt, 10 ** collDecimals);
    }

    uint256 _flashMultiplier = getCurrentLeverRatio().sub(1e18);
    uint256 _flashloanAmt = wmul(wdiv(_finalAmt, getDebtPrice()), _flashMultiplier);
    if (debtDecimals != 18) {
      _flashloanAmt = wmul(_flashloanAmt, 10 ** debtDecimals);
    }
    uint256 _amtToMint = wdiv(_finalAmt, getIndex());

    _data.flashAmt = _flashloanAmt;

    (,, address _variableDebtToken) = AAVE_DATA_PROVIDER.getReserveTokensAddresses(address(DEBT_ASSET));
    IDebtToken(_variableDebtToken).approveDelegation(flashloanAdapter, _flashloanAmt);

    _flashloan(address(DEBT_ASSET), _flashloanAmt, abi.encode(_data));
    _mint(msg.sender, _amtToMint);

    // Event emission
  }

  function withdraw(uint256 _amt) external nonReentrant {
    require(balanceOf(msg.sender) >= _amt, "not-enough-bal");

    uint256 _amtToReturn = wmul(_amt, getIndex());
    uint256 _multiplier = getCurrentLeverRatio().sub(1e18);
    uint256 _amtToFlash = wmul(_amtToReturn, _multiplier);
    uint256 _totalWithdraw = _amtToReturn.add(_amtToFlash);

    if (collDecimals != 18) {
      _amtToFlash = wmul(_amtToFlash, 10 ** collDecimals);
      _amtToReturn = wmul(_amtToReturn, 10 ** collDecimals);
    }

    _withdrawCollateral(_totalWithdraw, address(this));
    COLLATERAL_ASSET.safeTransfer(flashloanAdapter, _amtToFlash);
    IFlashloanAdapter(flashloanAdapter).executeWithdraw(_amtToFlash);

    (uint256 _fee, uint256 _finalAmt) = _calculateBurnFee(_amtToReturn);
    COLLATERAL_ASSET.safeTransfer(feeCollector, _fee);
    COLLATERAL_ASSET.safeTransfer(msg.sender, _finalAmt);

    _burn(msg.sender, _amt);

    // Event emission
  }

  function withdrawViaFlashloan(uint256 _amt) external nonReentrant {
    require(balanceOf(msg.sender) >= _amt, "not-enough-bal");

    uint256 _scaledAmt = wmul(_amt, getIndex());
    uint256 _multiplier = getCurrentLeverRatio().sub(1e18);
    uint256 _amtToFlash = wmul(_scaledAmt, _multiplier);
    uint256 _flashPremium = _amtToFlash.mul(AAVE_LENDING_POOL.FLASHLOAN_PREMIUM_TOTAL()).div(10000);
    uint256 _amtToReturn = _scaledAmt.sub(_flashPremium);

    if (collDecimals != 18) {
      _amtToFlash = wmul(_amtToFlash, 10 ** collDecimals);
      _amtToReturn = wmul(_amtToReturn, 10 ** collDecimals);
    }

    DataTypes.FlashloanData memory _data;
    _data.opType = 3;
    _data.flashAmt = _amtToFlash;
    _data.flashAsset = address(COLLATERAL_ASSET);
    _data.targetAsset = address(DEBT_ASSET);

    _flashloan(address(COLLATERAL_ASSET), _amtToFlash, abi.encode(_data));
    _withdrawCollateral(_amtToReturn, address(this));

    (uint256 _fee, uint256 _finalAmt) = _calculateBurnFee(_amtToReturn);
    COLLATERAL_ASSET.safeTransfer(feeCollector, _fee);
    COLLATERAL_ASSET.safeTransfer(msg.sender, _finalAmt);

    _burn(msg.sender, _amt);

    // Event emission
  }

  function rebalance() external nonReentrant {
    require(block.timestamp > lastRebalancingTime.add(REBALANCE_DELAY).sub(REBALANCE_GRACE_PERIOD), "too-soon-to-rebalance");
    require(block.timestamp < lastRebalancingTime.add(REBALANCE_DELAY).add(REBALANCE_GRACE_PERIOD), "rebalancing-time-over");

    _rebalance();

    lastRebalancingTime = block.timestamp;

    // Event emission
  }

  function emergencyRebalance() external nonReentrant {
    bool _leverCondition = getCurrentLeverRatio() < lowerLeverageLimit || getCurrentLeverRatio() > upperLeverageLimit;
    bool _timeCondition = block.timestamp > lastRebalancingTime.add(REBALANCE_DELAY).add(REBALANCE_DELAY.div(2));

    require(_leverCondition || _timeCondition, "cannot-invoke-emergency-rebalance");

    _rebalance();

    lastRebalancingTime = block.timestamp;

    // Event emission
  }

  function getCurrentLeverRatio() public view returns (uint256 _leverRatio) {
    if (totalSupply() == 0) {
      return targetLeverageRatio;
    }

    uint256 _debtPrice = getDebtPrice();

    (uint256 _collBal,,,,,,,,) = AAVE_DATA_PROVIDER.getUserReserveData(address(COLLATERAL_ASSET), address(this));
    (,, uint256 _debtBal,,,,,,) = AAVE_DATA_PROVIDER.getUserReserveData(address(DEBT_ASSET), address(this));

    if (collDecimals != 18) {
      uint256 _tokenUnit = 10 ** collDecimals;
      _collBal = wdiv(_collBal, _tokenUnit);
    }
    if (debtDecimals != 18) {
      uint256 _tokenUnit = 10 ** debtDecimals;
      _debtBal = wdiv(_debtBal, _tokenUnit);
    }

    uint256 _realExposure = _collBal.sub(wmul(_debtBal, _debtPrice));

    _leverRatio = wdiv(_collBal, _realExposure);
  }

  function getDebtPrice() public view returns (uint256 _debtPrice) {
    uint256 _collateralPriceEth = AAVE_ORACLE.getAssetPrice(address(COLLATERAL_ASSET));
    uint256 _debtPriceEth = AAVE_ORACLE.getAssetPrice(address(DEBT_ASSET));

    _debtPrice = wdiv(_debtPriceEth, _collateralPriceEth);
  }

  function getIndex() public view returns (uint256 _newIndex) {
    if (totalSupply() == 0) {
      return 1e18;
    }

    uint256 _debtPrice = getDebtPrice();

    (uint256 _collBal,,,,,,,,) = AAVE_DATA_PROVIDER.getUserReserveData(address(COLLATERAL_ASSET), address(this));
    (,, uint256 _debtBal,,,,,,) = AAVE_DATA_PROVIDER.getUserReserveData(address(DEBT_ASSET), address(this));

    if (collDecimals != 18) {
      uint256 _tokenUnit = 10 ** collDecimals;
      _collBal = wdiv(_collBal, _tokenUnit);
    }
    if (debtDecimals != 18) {
      uint256 _tokenUnit = 10 ** debtDecimals;
      _debtBal = wdiv(_debtBal, _tokenUnit);
    }


    uint256 _realExposure = _collBal.sub(wmul(_debtBal, _debtPrice));
    uint256 _idealCollBal = wmul(targetLeverageRatio, _realExposure);

    if (_idealCollBal > _collBal) {
      uint256 _deltaDebt = wdiv(wmul(targetLeverageRatio, _realExposure).sub(_collBal), _debtPrice);
      uint256 _idealDeltaColl = wmul(_deltaDebt, _debtPrice);

      _newIndex = indexPrice.add(wdiv(_idealDeltaColl, totalSupply()));
    } else {
      uint256 _deltaDebt = wdiv(_collBal.sub(wmul(targetLeverageRatio, _realExposure)), _debtPrice);
      uint256 _idealDeltaColl = wmul(_deltaDebt, _debtPrice);

      _newIndex = indexPrice.sub(wdiv(_idealDeltaColl, totalSupply()));
    }
  }

  function _calculateMintFee(uint256 _amt) internal view returns (uint256 _feeAmt, uint256 _amtSubFee) {
    _feeAmt = wmul(_amt, mintFee);
    _amtSubFee = _amt.sub(_feeAmt);
  }

  function _calculateBurnFee(uint256 _amt) internal view returns (uint256 _feeAmt, uint256 _amtSubFee) {
    _feeAmt = wmul(_amt, burnFee);
    _amtSubFee = _amt.sub(_feeAmt);
  }

  function _flashloan(address _asset, uint256 _amt, bytes memory _data) internal {
    address[] memory assets = new address[](1);
    assets[0] = address(_asset);

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = _amt;

    uint256[] memory modes = new uint256[](1);
    modes[0] = _asset == address(DEBT_ASSET) ? 2 : 0;

    bytes memory params = _data;
    uint16 referralCode = 0;

    AAVE_LENDING_POOL.flashLoan(
        flashloanAdapter,
        assets,
        amounts,
        modes,
        address(this),
        params,
        referralCode
    );
  }

  function _withdrawCollateral(uint256 _amt, address _to) internal {
    AAVE_LENDING_POOL.withdraw(address(COLLATERAL_ASSET), _amt, _to);
  }

  function _rebalance() internal {
    (uint256 _collBal,,,,,,,,) = AAVE_DATA_PROVIDER.getUserReserveData(address(COLLATERAL_ASSET), address(this));
    (,, uint256 _debtBal,,,,,,) = AAVE_DATA_PROVIDER.getUserReserveData(address(DEBT_ASSET), address(this));

    uint256 _debtPrice = getDebtPrice();

    if (collDecimals != 18) {
      uint256 _tokenUnit = 10 ** collDecimals;
      _collBal = wdiv(_collBal, _tokenUnit);
    }
    if (debtDecimals != 18) {
      uint256 _tokenUnit = 10 ** debtDecimals;
      _debtBal = wdiv(_debtBal, _tokenUnit);
    }

    uint256 _realExposure = _collBal.sub(wmul(_debtBal, _debtPrice));
    uint256 _idealCollBal = wmul(targetLeverageRatio, _realExposure);

    if (_idealCollBal > _collBal) {
      uint256 _deltaDebt = wdiv(wmul(targetLeverageRatio, _realExposure).sub(_collBal), _debtPrice);

      if (debtDecimals != 18) {
        _deltaDebt = wmul(_deltaDebt, 10 ** debtDecimals);
      }

      DataTypes.FlashloanData memory _data;

      _data.flashAsset = address(DEBT_ASSET);
      _data.targetAsset = address(COLLATERAL_ASSET);
      _data.flashAmt = _deltaDebt;

      (,, address _variableDebtToken) = AAVE_DATA_PROVIDER.getReserveTokensAddresses(address(DEBT_ASSET));
    IDebtToken(_variableDebtToken).approveDelegation(flashloanAdapter, _deltaDebt);

      _flashloan(address(DEBT_ASSET), _deltaDebt, abi.encode(_data));
    } else {
      uint256 _deltaDebt = wdiv(_collBal.sub(wmul(targetLeverageRatio, _realExposure)), _debtPrice);
      uint256 _idealDeltaColl = wmul(_deltaDebt, _debtPrice);

      if (collDecimals != 18) {
        _idealDeltaColl = wmul(_idealDeltaColl, 10 ** collDecimals);
      }

      DataTypes.FlashloanData memory _data;

      _data.opType = 1;
      _data.flashAsset = address(COLLATERAL_ASSET);
      _data.targetAsset = address(DEBT_ASSET);
      _data.flashAmt = _idealDeltaColl;

      _flashloan(address(COLLATERAL_ASSET), _idealDeltaColl, abi.encode(_data));
    }

    (uint256 _newCollBal,,,,,,,,) = AAVE_DATA_PROVIDER.getUserReserveData(address(COLLATERAL_ASSET), address(this));

    if (collDecimals != 18) {
      uint256 _tokenUnit = 10 ** collDecimals;
      _newCollBal = wdiv(_newCollBal, _tokenUnit);
    }

    if (_newCollBal > _collBal) {
      indexPrice = indexPrice.add(wdiv(_newCollBal.sub(_collBal), totalSupply()));
    } else {
      indexPrice = indexPrice.sub(wdiv(_collBal.sub(_newCollBal), totalSupply()));
    }
  }

  function __updateAaveLendingPool() external onlyOwner {
    AAVE_LENDING_POOL = ILendingPool(AAVE_ADDRESSES_PROVIDER.getLendingPool());
  }

  function __updateAaveOracle() external onlyOwner {
    AAVE_ORACLE = IPriceOracleGetter(AAVE_ADDRESSES_PROVIDER.getPriceOracle());
  }

  function __changeFlashloanAdapter(address _newAdapter) external onlyOwner {
    require(_newAdapter != address(0x0), "invalid-address");
    flashloanAdapter = _newAdapter;
  }

  function __changeFeeCollector(address _newCollector) external onlyOwner {
    require(_newCollector != address(0x0), "invalid-address");
    feeCollector = _newCollector;
  }

  function __changeFees(uint256 _mintFee, uint256 _burnFee) external onlyOwner {
    require(_mintFee <= 1e16, "mint-fee-too-large");
    require(_burnFee <= 3e16, "burn-fee-too-large");

    mintFee = _mintFee;
    burnFee = _burnFee;
  }

  function __withdrawCollateral(uint256 _amt) external onlyFlashloanAdapter {
    _withdrawCollateral(_amt, flashloanAdapter);
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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
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
library SafeMathUpgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { DataTypes } from "./Libraries.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the decimals of the token
     */
    function decimals() external view returns (uint8);

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


/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

interface ILendingPool {
    /**
    * @dev Emitted on deposit()
    * @param reserve The address of the underlying asset of the reserve
    * @param user The address initiating the deposit
    * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
    * @param amount The amount deposited
    * @param referral The referral code used
    **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
    * @dev Emitted on withdraw()
    * @param reserve The address of the underlyng asset being withdrawn
    * @param user The address initiating the withdrawal, owner of aTokens
    * @param to Address that will receive the underlying
    * @param amount The amount to be withdrawn
    **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
    * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
    * @param reserve The address of the underlying asset being borrowed
    * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
    * initiator of the transaction on flashLoan()
    * @param onBehalfOf The address that will be getting the debt
    * @param amount The amount borrowed out
    * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
    * @param borrowRate The numeric rate at which the user has borrowed
    * @param referral The referral code used
    **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
    * @dev Emitted on repay()
    * @param reserve The address of the underlying asset of the reserve
    * @param user The beneficiary of the repayment, getting his debt reduced
    * @param repayer The address of the user initiating the repay(), providing the funds
    * @param amount The amount repaid
    **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
    * @dev Emitted on swapBorrowRateMode()
    * @param reserve The address of the underlying asset of the reserve
    * @param user The address of the user swapping his rate mode
    * @param rateMode The rate mode that the user wants to swap to
    **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
    * @dev Emitted on setUserUseReserveAsCollateral()
    * @param reserve The address of the underlying asset of the reserve
    * @param user The address of the user enabling the usage as collateral
    **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
    * @dev Emitted on setUserUseReserveAsCollateral()
    * @param reserve The address of the underlying asset of the reserve
    * @param user The address of the user enabling the usage as collateral
    **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
    * @dev Emitted on rebalanceStableBorrowRate()
    * @param reserve The address of the underlying asset of the reserve
    * @param user The address of the user for which the rebalance has been executed
    **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
    * @dev Emitted on flashLoan()
    * @param target The address of the flash loan receiver contract
    * @param initiator The address initiating the flash loan
    * @param asset The address of the asset being flash borrowed
    * @param amount The amount flash borrowed
    * @param premium The fee flash borrowed
    * @param referralCode The referral code used
    **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
    * @dev Emitted when the pause is triggered.
    */
    event Paused();

    /**
    * @dev Emitted when the pause is lifted.
    */
    event Unpaused();

    /**
    * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
    * LendingPoolCollateral manager using a DELEGATECALL
    * This allows to have the events in the generated ABI for LendingPool.
    * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
    * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
    * @param user The address of the borrower getting liquidated
    * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
    * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
    * @param liquidator The address of the liquidator
    * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
    * to receive the underlying collateral asset directly
    **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
    * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
    * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
    * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
    * gets added to the LendingPool ABI
    * @param reserve The address of the underlying asset of the reserve
    * @param liquidityRate The new liquidity rate
    * @param stableBorrowRate The new stable borrow rate
    * @param variableBorrowRate The new variable borrow rate
    * @param liquidityIndex The new liquidity index
    * @param variableBorrowIndex The new variable borrow index
    **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
    * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
    * @param asset The address of the underlying asset to deposit
    * @param amount The amount to be deposited
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    /**
    * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
    * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
    * corresponding debt token (StableDebtToken or VariableDebtToken)
    * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
    *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
    * @param asset The address of the underlying asset to borrow
    * @param amount The amount to be borrowed
    * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
    * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
    * if he has been given credit delegation allowance
    **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
    * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
    * @param asset The address of the borrowed underlying asset previously borrowed
    * @param amount The amount to repay
    * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
    * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
    * user calling the function if he wants to reduce/remove his own debt, or the address of any other
    * other borrower whose debt should be removed
    **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external;

    /**
    * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
    * @param asset The address of the underlying asset borrowed
    * @param rateMode The rate mode that the user wants to swap to
    **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
    * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
    * - Users can be rebalanced if the following conditions are satisfied:
    *     1. Usage ratio is above 95%
    *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
    *        borrowed at a stable rate and depositors are not earning enough
    * @param asset The address of the underlying asset borrowed
    * @param user The address of the user to be rebalanced
    **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
    * @dev Allows depositors to enable/disable a specific deposited asset as collateral
    * @param asset The address of the underlying asset deposited
    * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
    **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
    * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
    * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
    *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
    * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
    * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
    * @param user The address of the borrower getting liquidated
    * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
    * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
    * to receive the underlying collateral asset directly
    **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
    * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
    * as long as the amount taken plus a fee is returned.
    * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
    * For further details please visit https://developers.aave.com
    * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
    * @param assets The addresses of the assets being flash-borrowed
    * @param amounts The amounts amounts being flash-borrowed
    * @param modes Types of the debt to open if the flash loan is not returned:
    *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
    *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
    *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
    * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
    * @param params Variadic packed params to pass to the receiver as extra information
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
    * @dev Returns the user account data across all the reserves
    * @param user The address of the user
    * @return totalCollateralETH the total collateral in ETH of the user
    * @return totalDebtETH the total debt in ETH of the user
    * @return availableBorrowsETH the borrowing power left of the user
    * @return currentLiquidationThreshold the liquidation threshold of the user
    * @return ltv the loan to value of the user
    * @return healthFactor the current health factor of the user
    **/
    function getUserAccountData(address user)
        external
        view
        returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
        external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
    * @dev Returns the configuration of the reserve
    * @param asset The address of the underlying asset of the reserve
    * @return The configuration of the reserve
    **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
    * @dev Returns the configuration of the user across all the reserves
    * @param user The user address
    * @return The configuration of the user
    **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
    * @dev Returns the normalized income normalized income of the reserve
    * @param asset The address of the underlying asset of the reserve
    * @return The reserve's normalized income
    */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
    * @dev Returns the normalized variable debt per unit of asset
    * @param asset The address of the underlying asset of the reserve
    * @return The reserve normalized variable debt
    */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
    * @dev Returns the state and configuration of the reserve
    * @param asset The address of the underlying asset of the reserve
    * @return The state of the reserve
    **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
}

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(address asset) external view returns (uint256 decimals, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus, uint256 reserveFactor, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowRateEnabled, bool isActive, bool isFrozen);

    function getReserveData(address asset) external view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate, uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex, uint40 lastUpdateTimestamp);

    function getUserReserveData(address asset, address user) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);

    function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

interface IPriceOracleGetter {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);

    function getSourceOfAsset(address _asset) external view returns(address);
    
    function getFallbackOracle() external view returns(address);
}

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

interface IDebtToken {
    /**
    * @dev delegates borrowing power to a user on the specific debt token
    * @param delegatee the address receiving the delegated borrowing power
    * @param amount the maximum amount being delegated. Delegation will still
    * respect the liquidation constraints (even if delegated, a delegatee cannot
    * force a delegator HF to go below 1)
    **/
    function approveDelegation(address delegatee, uint256 amount) external;
}

interface IFluidLeverage {
    function deposit(uint256 _amt) external;

    function withdraw(uint256 _amt) external;

    function __withdrawCollateral(uint256 _amt) external;

    function getCurrentLeverRatio() external view returns (uint256 _leverRatio);

    function getDebtPrice() external view returns (uint256 _debtPrice);

    function getIndex() external view returns (uint256 _newIndex);

    function COLLATERAL_ASSET() external view returns (IERC20);

    function DEBT_ASSET() external view returns (IERC20);
}

interface IFlashloanAdapter {
    function executeWithdraw(uint256 _amt) external;
}

interface ISushiRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import { IERC20 } from "./Interfaces.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    struct FlashloanData {
        // opType: 0 = Rebalance Up, 1 = Rebalance Down, 2 = Deposit & 3 = Withdraw
        uint256 opType;
        uint256 userDepositAmt;
        uint256 flashAmt;
        address flashAsset;
        address targetAsset;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract DangoMath {

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = SafeMathUpgradeable.add(SafeMathUpgradeable.mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = SafeMathUpgradeable.add(SafeMathUpgradeable.mul(x, WAD), y / 2) / y;
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

