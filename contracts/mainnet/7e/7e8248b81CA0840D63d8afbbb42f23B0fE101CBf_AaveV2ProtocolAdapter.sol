// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "../../interfaces/AaveV2Interfaces.sol";
import "../../interfaces/ITokenAdapter.sol";
import "../../interfaces/IERC20.sol";
import "../../libraries/LowGasSafeMath.sol";
import "../../libraries/TransferHelper.sol";
import "../../libraries/SymbolHelper.sol";
import "../../libraries/RayMul.sol";
import "../../libraries/ReserveConfigurationLib.sol";
import "../../libraries/MinimalSignedMath.sol";
import "../../libraries/CloneLibrary.sol";


contract AaveV2Erc20Adapter is IErc20Adapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using RayMul for uint256;
  using SymbolHelper for address;
  using TransferHelper for address;

/* ========== Constants ========== */

  ILendingPoolAddressesProvider public immutable addressesProvider;
  address public constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  IAaveDistributionManager internal constant distributor = IAaveDistributionManager(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  ILendingPool public immutable pool;

/* ========== Storage ========== */

  address public userModuleImplementation;
  address public override underlying;
  address public override token;
  mapping(address => address) public userModules;
  // Pre-calculated and stored in the initializer to reduce gas costs in `getRewardsAPR`.
  uint256 internal _oneUnderlyingToken;

/* ========== Constructor & Initializer ========== */

  constructor(ILendingPoolAddressesProvider _addressesProvider) {
    addressesProvider = _addressesProvider;
    pool = _addressesProvider.getLendingPool();
  }

  function initialize(address _underlying, address _token) public virtual {
    require(underlying == address(0) && token == address(0), "initialized");
    require(_underlying != address(0) && _token != address(0), "bad address");
    underlying = _underlying;
    token = _token;
    userModuleImplementation = address(new AaveV2UserModule(
      addressesProvider,
      _underlying,
      _token
    ));
    _oneUnderlyingToken = 10 ** IERC20Metadata(_underlying).decimals();
  }

/* ========== Metadata ========== */

  function name() external view virtual override returns (string memory) {
    return string(abi.encodePacked(
      "Aave V2 ",
      bytes(underlying.getSymbol()),
      " Adapter"
    ));
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(token);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public pure override returns (uint256) {
    return tokenAmount;
  }

  function toWrappedAmount(uint256 underlyingAmount) public pure override returns (uint256) {
    return underlyingAmount;
  }

/* ========== User Modules ========== */

  function getOrCreateUserModule() internal returns (AaveV2UserModule) {
    address module = userModules[msg.sender];
    if (module == address(0)) {
      module = (userModules[msg.sender] = CloneLibrary.createClone(userModuleImplementation));
      AaveV2UserModule(payable(module)).initialize(msg.sender);
    }
    return AaveV2UserModule(payable(module));
  }

/* ========== Performance Queries ========== */

  function getRewardsAPR(uint256 _totalLiquidity) internal view returns (uint256) {
    address _token = token;
    (, uint256 emissionsPerSecond,) = distributor.getAssetData(_token);
    if (emissionsPerSecond == 0) return 0;
    IPriceOracle oracle = addressesProvider.getPriceOracle();
    uint256 aavePrice = oracle.getAssetPrice(aave);
    uint256 underlyingPrice = oracle.getAssetPrice(underlying);
    if (aavePrice == 0 || underlyingPrice == 0) {
      return 0;
    }
    uint256 underlyingValue = underlyingPrice.mul(_totalLiquidity) / _oneUnderlyingToken;
    uint256 rewardsValue = aavePrice.mul(emissionsPerSecond.mul(365 days));
    return rewardsValue / underlyingValue;
  }

  function getRewardsAPR() external view returns (uint256) {
    return getRewardsAPR(IERC20(token).totalSupply());
  }

  function getBaseAPR() internal view returns (uint256) {
    ILendingPool.ReserveData memory reserve = pool.getReserveData(underlying);
    return uint256(reserve.currentLiquidityRate) / 1e9;
  }

  function getAPR() public view virtual override returns (uint256 apr) {
    return getBaseAPR().add(getRewardsAPR(IERC20(token).totalSupply()));
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256 apr) {
    address reserve = underlying;
    ILendingPool.ReserveData memory data = pool.getReserveData(reserve);
    uint256 _availableLiquidity = IERC20(reserve).balanceOf(data.aTokenAddress).add(liquidityDelta);
    uint256 totalVariableDebt = data.variableDebtToken.scaledTotalSupply().rayMul(data.variableBorrowIndex);
    (uint256 totalStableDebt, uint256 avgStableRate) = data.stableDebtToken.getTotalSupplyAndAvgRate();
    (uint256 liquidityRate, ,) = data.interestRateStrategy.calculateInterestRates(
      reserve,
      _availableLiquidity,
      totalStableDebt,
      totalVariableDebt,
      avgStableRate,
      ReserveConfigurationLib.getReserveFactor(data.configuration)
    );
    uint256 newLiquidity = _availableLiquidity.add(totalVariableDebt).add(totalStableDebt);
    return (liquidityRate / 1e9).add(getRewardsAPR(newLiquidity));
  }

  function getRevenueBreakdown()
    external
    view
    override
    returns (
      address[] memory assets,
      uint256[] memory aprs
    )
  {
    uint256 rewardsAPR = getRewardsAPR(IERC20(token).totalSupply());
    uint256 size = rewardsAPR > 0 ? 2 : 1;
    assets = new address[](size);
    aprs = new uint256[](size);
    assets[0] = underlying;
    aprs[0] = getBaseAPR();
    if (rewardsAPR > 0) {
      assets[1] = aave;
      aprs[1] = rewardsAPR;
    }
  }

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() public view virtual override returns (uint256) {
    address module = userModules[msg.sender];
    return IERC20(token).balanceOf(module == address(0) ? msg.sender : module);
  }

  function balanceUnderlying() external view virtual override returns (uint256) {
    address module = userModules[msg.sender];
    return IERC20(token).balanceOf(module == address(0) ? msg.sender : module);
  }

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying) external virtual override returns (uint256 amountMinted) {
    require(amountUnderlying > 0, "deposit 0");
    AaveV2UserModule module = getOrCreateUserModule();
    underlying.safeTransferFrom(msg.sender, address(module), amountUnderlying);
    module.deposit(amountUnderlying);
    return amountUnderlying;
  }

  function withdraw(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    address module = userModules[msg.sender];
    if (module == address(0)) {
      token.safeTransferFrom(msg.sender, address(this), amountToken);
      pool.withdraw(underlying, amountToken, msg.sender);
      return amountToken;
    }
    AaveV2UserModule(payable(module)).withdraw(amountToken, true);
    amountReceived = amountToken;
  }

  function withdrawAll() external virtual override returns (uint256 amountReceived) {
    return withdraw(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    amountBurned = withdraw(amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    withdraw(amountReceived);
  }
}


contract AaveV2UserModule {
  using TransferHelper for address;

  IStakedAave internal constant stkAave = IStakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
  IAaveDistributionManager internal constant incentives = IAaveDistributionManager(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  ILendingPool internal immutable pool;
  address internal immutable underlying;
  address internal immutable aToken;
  address internal immutable adapter;

  address internal user;
  bool public assetHasRewards;
  uint32 public cooldownUnlockAt;

  constructor(
    ILendingPoolAddressesProvider addressesProvider,
    address _underlying,
    address _aToken
  ) {
    adapter = msg.sender;
    underlying = _underlying;
    aToken = _aToken;
    ILendingPool _pool = addressesProvider.getLendingPool();
    pool = _pool;
  }

  function initialize(address _user) external {
    require(msg.sender == adapter && user == address(0));
    user = _user;
    underlying.safeApproveMax(address(pool));
    (, uint256 emissionPerSecond,) = incentives.getAssetData(aToken);
    assetHasRewards = emissionPerSecond > 0;
  }

  function setHasRewards() external {
    (, uint256 emissionPerSecond,) = incentives.getAssetData(aToken);
    assetHasRewards = emissionPerSecond > 0;
  }

  function _claimAndTriggerCooldown() internal {
    address[] memory assets = new address[](1);
    assets[0] = aToken;
    uint256 r = incentives.getUserUnclaimedRewards(address(this));
    if (r > 0) {
      incentives.claimRewards(assets, r, address(this));
      stkAave.cooldown();
      uint256 cooldownDuration = stkAave.COOLDOWN_SECONDS();
      cooldownUnlockAt = uint32(block.timestamp + cooldownDuration);
    }
  }

  function poke() public {
    // We do not check if the asset has rewards inside of poke so that if
    // rewards are accrued and then the asset's incentives are set to zero,
    // the existing rewards can still be manually claimed.
    // If there's not a pending cooldown, claim any rewards and begin the cooldown
    // If there is a pending cooldown:
    // - If it is over, redeem stkAave, reset the timer, claim stkAave and begin new cooldown
    // - If it is not over, do nothing
    if (cooldownUnlockAt > 0) {
      if (cooldownUnlockAt < block.timestamp) {
        stkAave.redeem(user, type(uint256).max);
        cooldownUnlockAt = 0;
      } else {
        return;
      }
    }
    _claimAndTriggerCooldown();
  }

  function deposit(uint256 amount) external {
    require(msg.sender == adapter, "!adapter");
    pool.deposit(underlying, amount, address(this), 0);
    if (assetHasRewards) poke();
  }

  function withdraw(uint256 amount, bool toUser) external {
    require(msg.sender == adapter, "!adapter");
    pool.withdraw(underlying, amount, toUser ? user : adapter);
    if (assetHasRewards) poke();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./AaveV2Erc20Adapter.sol";
import "../../interfaces/IWETH.sol";


contract AaveV2EtherAdapter is IEtherAdapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using RayMul for uint256;
  using SymbolHelper for address;
  using TransferHelper for address;
  using TransferHelper for address payable;

/* ========== Constants ========== */

  ILendingPoolAddressesProvider public immutable addressesProvider;
  address public constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  IAaveDistributionManager internal constant distributor = IAaveDistributionManager(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  ILendingPool public immutable pool;
  address public immutable userModuleImplementation;
  address public immutable override underlying;
  address public immutable override token;

/* ========== Storage ========== */
  mapping(address => address) public userModules;

/* ========== Fallbacks ========== */

  receive() external payable { return; }

/* ========== Constructor & Initializer ========== */

  constructor(
    ILendingPoolAddressesProvider _addressesProvider,
    address _underlying,
    address _token
  ) {
    addressesProvider = _addressesProvider;
    pool = _addressesProvider.getLendingPool();
    underlying = _underlying;
    token = _token;
    userModuleImplementation = address(new AaveV2UserModule(
      _addressesProvider,
      _underlying,
      _token
    ));
  }

/* ========== Metadata ========== */

  function name() external view virtual override returns (string memory) {
    return string(abi.encodePacked(
      "Aave V2 ",
      bytes(underlying.getSymbol()),
      " Adapter"
    ));
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(token);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public pure override returns (uint256) {
    return tokenAmount;
  }

  function toWrappedAmount(uint256 underlyingAmount) public pure override returns (uint256) {
    return underlyingAmount;
  }

/* ========== User Modules ========== */

  function getOrCreateUserModule() internal returns (AaveV2UserModule) {
    address module = userModules[msg.sender];
    if (module == address(0)) {
      module = (userModules[msg.sender] = CloneLibrary.createClone(userModuleImplementation));
      AaveV2UserModule(payable(module)).initialize(msg.sender);
    }
    return AaveV2UserModule(payable(module));
  }

/* ========== Performance Queries ========== */

  function getRewardsAPR(uint256 _totalLiquidity) internal view returns (uint256) {
    address _token = token;
    (, uint256 emissionsPerSecond,) = distributor.getAssetData(_token);
    if (emissionsPerSecond == 0) return 0;
    IPriceOracle oracle = addressesProvider.getPriceOracle();
    uint256 aavePrice = oracle.getAssetPrice(aave);
    uint256 underlyingPrice = oracle.getAssetPrice(underlying);
    if (aavePrice == 0 || underlyingPrice == 0) {
      return 0;
    }
    return aavePrice.mul(emissionsPerSecond.mul(365 days)).mul(1e18) / underlyingPrice.mul(_totalLiquidity);
  }

  function getRewardsAPR() external view returns (uint256) {
    return getRewardsAPR(IERC20(token).totalSupply());
  }

  function getBaseAPR() internal view returns (uint256) {
    ILendingPool.ReserveData memory reserve = pool.getReserveData(underlying);
    return uint256(reserve.currentLiquidityRate) / 1e9;
  }

  function getAPR() public view virtual override returns (uint256 apr) {
    return getBaseAPR().add(getRewardsAPR(IERC20(token).totalSupply()));
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256 apr) {
    address reserve = underlying;
    ILendingPool.ReserveData memory data = pool.getReserveData(reserve);
    uint256 _availableLiquidity = IERC20(reserve).balanceOf(data.aTokenAddress).add(liquidityDelta);
    uint256 totalVariableDebt = data.variableDebtToken.scaledTotalSupply().rayMul(data.variableBorrowIndex);
    (uint256 totalStableDebt, uint256 avgStableRate) = data.stableDebtToken.getTotalSupplyAndAvgRate();
    (uint256 liquidityRate, ,) = data.interestRateStrategy.calculateInterestRates(
      reserve,
      _availableLiquidity,
      totalStableDebt,
      totalVariableDebt,
      avgStableRate,
      ReserveConfigurationLib.getReserveFactor(data.configuration)
    );
    uint256 newLiquidity = _availableLiquidity.add(totalVariableDebt).add(totalStableDebt);
    return (liquidityRate / 1e9).add(getRewardsAPR(newLiquidity));
  }

  function getRevenueBreakdown()
    external
    view
    override
    returns (
      address[] memory assets,
      uint256[] memory aprs
    )
  {
    uint256 rewardsAPR = getRewardsAPR(IERC20(token).totalSupply());
    uint256 size = rewardsAPR > 0 ? 2 : 1;
    assets = new address[](size);
    aprs = new uint256[](size);
    assets[0] = underlying;
    aprs[0] = getBaseAPR();
    if (rewardsAPR > 0) {
      assets[1] = aave;
      aprs[1] = rewardsAPR;
    }
  }

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() public view virtual override returns (uint256) {
    address module = userModules[msg.sender];
    return IERC20(token).balanceOf(module == address(0) ? msg.sender : module);
  }

  function balanceUnderlying() external view virtual override returns (uint256) {
    address module = userModules[msg.sender];
    return IERC20(token).balanceOf(module == address(0) ? msg.sender : module);
  }

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying) external virtual override returns (uint256 amountMinted) {
    require(amountUnderlying > 0, "deposit 0");
    AaveV2UserModule module = getOrCreateUserModule();
    underlying.safeTransferFrom(msg.sender, address(module), amountUnderlying);
    module.deposit(amountUnderlying);
    return amountUnderlying;
  }

  function depositETH() external payable virtual override returns (uint256 amountMinted) {
    require(msg.value > 0, "deposit 0");
    AaveV2UserModule module = getOrCreateUserModule();
    IWETH(underlying).deposit{value: msg.value}();
    underlying.safeTransfer(address(module), msg.value);
    module.deposit(msg.value);
    return msg.value;
  }

  function withdraw(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    address module = userModules[msg.sender];
    if (module == address(0)) {
      token.safeTransferFrom(msg.sender, address(this), amountToken);
      pool.withdraw(underlying, amountToken, msg.sender);
      return amountToken;
    }
    AaveV2UserModule(payable(module)).withdraw(amountToken, true);
    return amountToken;
  }

  function withdrawAsETH(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    address module = userModules[msg.sender];
    if (module == address(0)) {
      token.safeTransferFrom(msg.sender, address(this), amountToken);
      pool.withdraw(underlying, amountToken, address(this));
    } else {
      AaveV2UserModule(payable(module)).withdraw(amountToken, false);
    }
    IWETH(underlying).withdraw(amountToken);
    msg.sender.safeTransferETH(amountToken);
    return amountToken;
  }

  function withdrawAll() public virtual override returns (uint256 amountReceived) {
    return withdraw(balanceWrapped());
  }

  function withdrawAllAsETH() public virtual override returns (uint256 amountReceived) {
    return withdrawAsETH(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    return withdraw(amountUnderlying);
  }

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    return withdrawAsETH(amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    withdraw(amountReceived);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;


interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (ILendingPool);

  function getPriceOracle() external view returns (IPriceOracle);
}


interface IVariableDebtToken {
  function scaledTotalSupply() external view returns (uint256);
}


interface IReserveInterestRateStrategy {
  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  ) external
    view
    returns (
      uint256 liquidityRate,
      uint256 stableBorrowRate,
      uint256 variableBorrowRate
    );
}


interface IStableDebtToken {
  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);
}


interface ILendingPool {
  struct ReserveConfigurationMap {
    uint256 data;
  }

  struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 currentLiquidityRate;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    IStableDebtToken stableDebtToken;
    IVariableDebtToken variableDebtToken;
    IReserveInterestRateStrategy interestRateStrategy;
    uint8 id;
  }

  function getReserveNormalizedIncome(address asset) external view returns (uint128);

  function getReserveData(address asset) external view returns (ReserveData memory);

  function getReservesList() external view returns (address[] memory);

  function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;
}


interface IAaveDistributionManager {
  function getAssetData(address asset) external view returns (uint256 index, uint256 emissionPerSecond, uint256 lastUpdateTimestamp);

  function getUserUnclaimedRewards(address account) external view returns (uint256);

  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);
}


interface IPriceOracle {
  function getAssetPrice(address asset) external view returns (uint256);
}


interface IStakedAave {
  function COOLDOWN_SECONDS() external view returns (uint256);

  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;

  function stakerRewardsToClaim(address account) external view returns (uint256);

  function stakersCooldowns(address account) external view returns (uint256);

  function getTotalRewardsBalance(address staker) external view returns (uint256);

  function getNextCooldownTimestamp(
    uint256 fromCooldownTimestamp,
    uint256 amountToReceive,
    address toAddress,
    uint256 toBalance
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IAdapterRegistry {
/* ========== Events ========== */

  event ProtocolAdapterAdded(uint256 protocolId, address protocolAdapter);

  event ProtocolAdapterRemoved(uint256 protocolId);

  event TokenAdapterAdded(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenAdapterRemoved(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenSupportAdded(address underlying);

  event TokenSupportRemoved(address underlying);

  event VaultFactoryAdded(address factory);

  event VaultFactoryRemoved(address factory);

  event VaultAdded(address underlying, address vault);

  event VaultRemoved(address underlying, address vault);

/* ========== Structs ========== */

  struct TokenAdapter {
    address adapter;
    uint96 protocolId;
  }

/* ========== Storage ========== */

  function protocolsCount() external view returns (uint256);

  function protocolAdapters(uint256 id) external view returns (address protocolAdapter);

  function protocolAdapterIds(address protocolAdapter) external view returns (uint256 id);

  function vaultsByUnderlying(address underlying) external view returns (address vault);

  function approvedVaultFactories(address factory) external view returns (bool approved);

/* ========== Vault Factory Management ========== */

  function addVaultFactory(address _factory) external;

  function removeVaultFactory(address _factory) external;

/* ========== Vault Management ========== */

  function addVault(address vault) external;

  function removeVault(address vault) external;

/* ========== Protocol Adapter Management ========== */

  function addProtocolAdapter(address protocolAdapter) external returns (uint256 id);

  function removeProtocolAdapter(address protocolAdapter) external;

/* ========== Token Adapter Management ========== */

  function addTokenAdapter(address adapter) external;

  function addTokenAdapters(address[] calldata adapters) external;

  function removeTokenAdapter(address adapter) external;

/* ========== Vault Queries ========== */

  function getVaultsList() external view returns (address[] memory);

  function haveVaultFor(address underlying) external view returns (bool);

/* ========== Protocol Queries ========== */

  function getProtocolAdaptersAndIds() external view returns (address[] memory adapters, uint256[] memory ids);

  function getProtocolMetadata(uint256 id) external view returns (address protocolAdapter, string memory name);

  function getProtocolForTokenAdapter(address adapter) external view returns (address protocolAdapter);

/* ========== Supported Token Queries ========== */

  function isSupported(address underlying) external view returns (bool);

  function getSupportedTokens() external view returns (address[] memory list);

/* ========== Token Adapter Queries ========== */

  function isApprovedAdapter(address adapter) external view returns (bool);

  function getAdaptersList(address underlying) external view returns (address[] memory list);

  function getAdapterForWrapperToken(address wrapperToken) external view returns (address);

  function getAdaptersCount(address underlying) external view returns (uint256);

  function getAdaptersSortedByAPR(address underlying)
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdaptersSortedByAPRWithDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  )
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdapterWithHighestAPR(address underlying) external view returns (address adapter, uint256 apr);

  function getAdapterWithHighestAPRForDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  ) external view returns (address adapter, uint256 apr);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}


interface IERC20MetadataBytes32 {
  function name() external view returns (bytes32);
  function symbol() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IErc20Adapter {
/* ========== Metadata ========== */

  function underlying() external view returns (address);

  function token() external view returns (address);

  function name() external view returns (string memory);

  function availableLiquidity() external view returns (uint256);

/* ========== Conversion ========== */

  function toUnderlyingAmount(uint256 tokenAmount) external view returns (uint256);

  function toWrappedAmount(uint256 underlyingAmount) external view returns (uint256);

/* ========== Performance Queries ========== */

  function getAPR() external view returns (uint256);

  function getHypotheticalAPR(int256 liquidityDelta) external view returns (uint256);

  function getRevenueBreakdown()
    external
    view
    returns (
      address[] memory assets,
      uint256[] memory aprs
    );

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() external view returns (uint256);

  function balanceUnderlying() external view returns (uint256);

/* ========== Interactions ========== */

  function deposit(uint256 amountUnderlying) external returns (uint256 amountMinted);

  function withdraw(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAll() external returns (uint256 amountReceived);

  function withdrawUnderlying(uint256 amountUnderlying) external returns (uint256 amountBurned);

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external returns (uint256 amountReceived);
}

interface IEtherAdapter is IErc20Adapter {
  function depositETH() external payable returns (uint256 amountMinted);

  function withdrawAsETH(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAllAsETH() external returns (uint256 amountReceived);

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external returns (uint256 amountBurned); 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IWETH {
  function deposit() external payable;
  function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../libraries/LowGasSafeMath.sol";
import "../interfaces/ITokenAdapter.sol";


library ArrayHelper {
  using EnumerableSet for EnumerableSet.AddressSet;
  using LowGasSafeMath for uint256;

/* ========== Type Cast ========== */

  /**
   * @dev Cast an enumerable address set as an address array.
   * The enumerable set library stores the values as a bytes32 array, this function
   * casts it as an address array with a pointer assignment.
   */
  function toArray(EnumerableSet.AddressSet storage set) internal view returns (address[] memory arr) {
    bytes32[] memory bytes32Arr = set._inner._values;
    assembly { arr := bytes32Arr }
  }

  /**
   * @dev Cast an array of IErc20Adapter to an array of address using a pointer assignment.
   * Note: The resulting array is the same as the original, so all changes to one will be
   * reflected in the other.
   */
  function toAddressArray(IErc20Adapter[] memory _arr) internal pure returns (address[] memory arr) {
    assembly { arr := _arr }
  }

/* ========== Math ========== */

  /**
   * @dev Computes the sum of a uint256 array.
   */
  function sum(uint256[] memory arr) internal pure returns (uint256 _sum) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) _sum = _sum.add(arr[i]);
  }

/* ========== Removal ========== */

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(uint256[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      uint256 last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(address[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      address last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(IErc20Adapter[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      IErc20Adapter last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(bytes32[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    bytes32 last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(address[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    address last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

/* ========== Search ========== */

  /**
   * @dev Find the index of an address in an array.
   * If the address is not found, revert.
   */
  function indexOf(address[] memory arr, address find) internal pure returns (uint256) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return i;
    revert("element not found");
  }

  /**
   * @dev Determine whether an element is included in an array.
   */
  function includes(address[] memory arr, address find) internal pure returns (bool) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return true;
    return false;
  }

/* ========== Sorting ========== */

  /**
   * @dev Given an array of tokens and scores, sort by scores in descending order.
   * Maintains the relationship between elements of each array at the same index.
   */
  function sortByDescendingScore(
    address[] memory addresses,
    uint256[] memory scores
  ) internal pure {
    uint256 len = addresses.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 score = scores[i];
      address _address = addresses[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < score) {
        scores[j + 1] = scores[j];
        addresses[j + 1] = addresses[j];
        j--;
      }
      scores[j + 1] = score;
      addresses[j + 1] = _address;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * EIP 1167 Proxy Deployment
 * Originally from https://github.com/optionality/clone-factory/
 */
library CloneLibrary {
  function getCreateCode(address target) internal pure returns (bytes memory createCode) {
    // Reserve 55 bytes for the deploy code + 17 bytes as a buffer to prevent overwriting
    // other memory in the final mstore
    createCode = new bytes(72);
    assembly {
      let clone := add(createCode, 32)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), shl(96, target))
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      mstore(createCode, 55)
    }
  }

  function createClone(address target) internal returns (address result) {
    bytes memory createCode = getCreateCode(target);
    assembly { result := create(0, add(createCode, 32), 55) }
  }

  function createClone(address target, bytes32 salt) internal returns (address result) {
    bytes memory createCode = getCreateCode(target);
    assembly { result := create2(0, add(createCode, 32), 55, salt) }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), shl(96, target))
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/LowGasSafeMath.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0 license
*************************************************************************************************/


/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x + y) >= x, errorMessage);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y <= x);
    z = x - y;
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require(y <= x, errorMessage);
    z = x - y;
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x == 0) return 0;
    z = x * y;
    require(z / x == y);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    if (x == 0) return 0;
    z = x * y;
    require(z / x == y, errorMessage);
  }

  /// @notice Returns ceil(x / y)
  /// @param x The numerator
  /// @param y The denominator
  /// @return z The quotient of x and y
  function divCeil(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x % y == 0 ? x / y : (x/y) + 1;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;


library MinimalSignedMath {
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  function add(uint256 a, int256 b) internal pure returns (uint256) {
    require(a < 2**255);
    int256 _a = int256(a);
    int256 c = _a + b;
    require((b >= 0 && c >= _a) || (b < 0 && c < _a));
    if (c < 0) return 0;
    return uint256(c);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


library RayMul {
  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, "rayMul overflow");

    return (a * b + halfRAY) / RAY;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../interfaces/AaveV2Interfaces.sol";


library ReserveConfigurationLib {
  uint256 internal constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK                  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  /**
   * @dev Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(ILendingPool.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  function isFrozen(ILendingPool.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~FROZEN_MASK) != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../interfaces/IERC20Metadata.sol";


library SymbolHelper {

  /**
   * @dev Returns the index of the lowest bit set in `self`.
   * Note: Requires that `self != 0`
   */
  function lowestBitSet(uint256 self) internal pure returns (uint256 _z) {
    require (self > 0, "Bits::lowestBitSet: Value 0 has no bits set");
    uint256 _magic = 0x00818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    uint256 val = (self & -self) * _magic >> 248;
    uint256 _y = val >> 5;
    _z = (
      _y < 4
        ? _y < 2
          ? _y == 0
            ? 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            : 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
          : _y == 2
            ? 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            : 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
        : _y < 6
          ? _y == 4
            ? 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            : 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
          : _y == 6
            ? 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            : 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
    );
    _z >>= (val & 0x1f) << 3;
    return _z & 0xff;
  }

  function getSymbol(address token) internal view returns (string memory) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
    if (!success) return "UNKNOWN";
    if (data.length != 32) return abi.decode(data, (string));
    uint256 symbol = abi.decode(data, (uint256));
    if (symbol == 0) return "UNKNOWN";
    uint256 emptyBits = 255 - lowestBitSet(symbol);
    uint256 size = (emptyBits / 8) + (emptyBits % 8 > 0 ? 1 : 0);
    assembly { mstore(data, size) }
    return string(data);
  }

  function getName(address token) internal view returns (string memory) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("name()"));
    if (!success) return "UNKNOWN";
    if (data.length != 32) return abi.decode(data, (string));
    uint256 symbol = abi.decode(data, (uint256));
    if (symbol == 0) return "UNKNOWN";
    uint256 emptyBits = 255 - lowestBitSet(symbol);
    uint256 size = (emptyBits / 8) + (emptyBits % 8 > 0 ? 1 : 0);
    assembly { mstore(data, size) }
    return string(data);
  }

  function getPrefixedSymbol(string memory prefix, address token) internal view returns (string memory prefixedSymbol) {
    prefixedSymbol = string(abi.encodePacked(
      prefix,
      getSymbol(token)
    ));
  }

  function getPrefixedName(string memory prefix, address token) internal view returns (string memory prefixedName) {
    prefixedName = string(abi.encodePacked(
      prefix,
      getName(token)
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash cfedb1f55864dcf8cc0831fdd8ec18eb045b7fd1.

Subject to the MIT license
*************************************************************************************************/


library TransferHelper {
  function safeApproveMax(address token, address to) internal {
    safeApprove(token, to, type(uint256).max);
  }

  function safeUnapprove(address token, address to) internal {
    safeApprove(token, to, 0);
  }

  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:SA");
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:ST");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:STF");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}("");
    require(success, "TH:STE");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "../interfaces/AaveV2Interfaces.sol";
import "../adapters/aave-v2/AaveV2Erc20Adapter.sol";
import "../adapters/aave-v2/AaveV2EtherAdapter.sol";
import "../libraries/ReserveConfigurationLib.sol";
import "./AbstractProtocolAdapter.sol";


contract AaveV2ProtocolAdapter is AbstractProtocolAdapter {
  using ReserveConfigurationLib for ILendingPool.ReserveConfigurationMap;

/* ========== Constants ========== */

  ILendingPoolAddressesProvider public constant aave = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
  ILendingPool public immutable pool;
  address public immutable erc20AdapterImplementation;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) AbstractProtocolAdapter(_registry) {
    erc20AdapterImplementation = address(new AaveV2Erc20Adapter(aave));
    pool = aave.getLendingPool();
  }

/* ========== Internal Actions ========== */

  function deployAdapter(address underlying) internal override returns (address adapter) {
    address aToken = pool.getReserveData(underlying).aTokenAddress;
    if (underlying == weth) {
      adapter = address(new AaveV2EtherAdapter(aave, underlying, aToken));
    } else {
      adapter = CloneLibrary.createClone(erc20AdapterImplementation);
      AaveV2Erc20Adapter(adapter).initialize(underlying, aToken);
    }
  }

/* ========== Public Queries ========== */

  function protocol() external pure virtual override returns (string memory) {
    return "Aave V2";
  }

  function getUnmapped() public view virtual override returns (address[] memory tokens) {
    tokens = pool.getReservesList();
    uint256 len = tokens.length;
    uint256 prevLen = totalMapped;
    if (len == prevLen) {
      assembly { mstore(tokens, 0) }
    } else {
      assembly {
        tokens := add(tokens, mul(prevLen, 32))
        mstore(tokens, sub(len, prevLen))
      }
    }
  }

/* ========== Internal Queries ========== */

  function isAdapterMarketFrozen(address adapter) internal view virtual override returns (bool) {
    return isTokenMarketFrozen(IErc20Adapter(adapter).underlying());
  }

  function isTokenMarketFrozen(address underlying) internal view virtual override returns (bool) {
    return pool.getConfiguration(underlying).isFrozen();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "../interfaces/IAdapterRegistry.sol";
import "../libraries/CloneLibrary.sol";
import "../libraries/ArrayHelper.sol";


abstract contract AbstractProtocolAdapter {
  using ArrayHelper for address[];

/* ========== Events ========== */

  event MarketFrozen(address token);

  event MarketUnfrozen(address token);

  event AdapterFrozen(address adapter);

  event AdapterUnfrozen(address adapter);

/* ========== Constants ========== */

  /**
   * @dev WETH address used for deciding whether to deploy an ERC20 or Ether adapter.
   */
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Global registry of adapters.
   */
  IAdapterRegistry public immutable registry;

/* ========== Storage ========== */

  /**
   * @dev List of adapters which have been deployed and then frozen.
   */
  address[] public frozenAdapters;

  /**
   * @dev List of tokens which have been frozen and which do not have an adapter.
   */
  address[] public frozenTokens;

  /**
   * @dev Number of tokens which have been mapped by the adapter.
   */
  uint256 public totalMapped;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) {
    registry = _registry;
  }

/* ========== Public Actions ========== */

  /**
   * @dev Map up to `max` tokens, starting at `totalMapped`.
   */
  function map(uint256 max) external virtual {
    address[] memory tokens = getUnmappedUpTo(max);
    uint256 len = tokens.length;
    address[] memory adapters = new address[](len);
    uint256 skipped;
    for (uint256 i; i < len; i++) {
      address token = tokens[i];
      if (isTokenMarketFrozen(token)) {
        skipped++;
        frozenTokens.push(token);
        emit MarketFrozen(token);
        continue;
      }
      address adapter = deployAdapter(token);
      adapters[i - skipped] = adapter;
    }
    totalMapped += len;
    assembly { if gt(skipped, 0) { mstore(adapters, sub(len, skipped)) } }
    registry.addTokenAdapters(adapters);
  }

  /**
   * @dev Unfreeze adapter at `index` in `frozenAdapters`.
   * Market for the adapter must not be frozen by the protocol.
   */
  function unfreezeAdapter(uint256 index) external virtual {
    address adapter = frozenAdapters[index];
    require(!isAdapterMarketFrozen(adapter), "Market still frozen");
    frozenAdapters.remove(index);
    registry.addTokenAdapter(adapter);
    emit AdapterUnfrozen(adapter);
  }

  /**
   * @dev Unfreeze token at `index` in `frozenTokens` and create a new adapter for it.
   * Market for the token must not be frozen by the protocol.
   */
  function unfreezeToken(uint256 index) external virtual {
    address token = frozenTokens[index];
    require(!isTokenMarketFrozen(token), "Market still frozen");
    frozenTokens.remove(index);
    address adapter = deployAdapter(token);
    registry.addTokenAdapter(adapter);
    emit MarketUnfrozen(token);
  }

  /**
   * @dev Freeze `adapter` - add it to `frozenAdapters` and remove it from the registry.
   * Does not verify adapter exists or has been registered by this contract because the
   * registry handles that.
   */
  function freezeAdapter(address adapter) external virtual {
    require(isAdapterMarketFrozen(adapter), "Market not frozen");
    frozenAdapters.push(adapter);
    registry.removeTokenAdapter(adapter);
    emit AdapterFrozen(adapter);
  }

/* ========== Internal Actions ========== */

  /**
   * @dev Deploys an adapter for `token`, which will either be an underlying token
   * or a wrapper token, whichever is returned by `getUnmapped`.
   */
  function deployAdapter(address token) internal virtual returns (address);

/* ========== Public Queries ========== */

  /**
   * @dev Name of the protocol the adapter is for.
   */
  function protocol() external view virtual returns (string memory);

  /**
   * @dev Get the list of tokens which have not already been mapped by the adapter.
   * Tokens may be underlying tokens or wrapper tokens for a lending market.
   */
  function getUnmapped() public view virtual returns (address[] memory tokens);

  /**
   * @dev Get up to `max` tokens which have not already been mapped by the adapter.
   * Tokens may be underlying tokens or wrapper tokens for a lending market.
   */
  function getUnmappedUpTo(uint256 max) public view virtual returns (address[] memory tokens) {
    tokens = getUnmapped();
    if (tokens.length > max) {
      assembly { mstore(tokens, max) }
    }
  }

  function getFrozenAdapters() external view returns (address[] memory tokens) {
    tokens = frozenAdapters;
  }

  function getFrozenTokens() external view returns (address[] memory tokens) {
    tokens = frozenTokens;
  }

/* ========== Internal Queries ========== */

  /**
   * @dev Check whether the market for an adapter is frozen.
   */
  function isAdapterMarketFrozen(address adapter) internal view virtual returns (bool);

  /**
   * @dev Check whether the market for a token is frozen.
   */
  function isTokenMarketFrozen(address token) internal view virtual returns (bool);
}

