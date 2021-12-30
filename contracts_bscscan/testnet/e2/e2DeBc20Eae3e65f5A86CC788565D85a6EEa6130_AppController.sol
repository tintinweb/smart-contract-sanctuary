//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IMintVault.sol";
import "./interfaces/IController.sol";
import "./interfaces/IStrategy.sol";
import "./Constants.sol";

contract AppController is Constants, IController, OwnableUpgradeable {

  using EnumerableSet for EnumerableSet.AddressSet;

  uint constant JOINED_VAULT_LIMIT = 20;

  // underlying => dToken
  mapping(address => address) public override dyTokens;
  // underlying => IStratege
  mapping(address => address) public strategies;

  struct ValueConf {
    address oracle;
    uint16 dr;  // discount rate 
    uint16 pr;  // premium rate 
  }

  // underlying => orcale 
  mapping(address => ValueConf ) internal valueConfs;

  //  dyToken => valut
  mapping(address => address) public override dyTokenVaults;

  // 用户已进入的Vault
  // user => vaults 
  mapping(address => EnumerableSet.AddressSet) internal userJoinedDepositVaults;

  mapping(address => EnumerableSet.AddressSet) internal userJoinedBorrowVaults;

  // 处于风控需要，管理 Vault 状态 
  struct VaultState {
    bool enabled;
    bool enableDeposit;
    bool enableWithdraw;
    bool enableBorrow;
    bool enableRepay;
    bool enableLiquidate;
  }

  // Vault => VaultStatus 
  mapping(address => VaultState) public vaultStates;


  // depost value / borrow value >= liquidateRate
  uint public liquidateRate;
  uint public collateralRate;

  // is anyone can call Liquidate.
  bool public isOpenLiquidate;

  mapping(address => bool) public allowedLiquidator;  


  // EVENT
  event UnderlyingDTokenChanged(address indexed underlying, address oldDToken, address newDToken);
  event UnderlyingStrategyChanged(address indexed underlying, address oldStrage, address newDToken, uint stype);
  event DTokenVaultChanged(address indexed dToken, address oldVault, address newVault, uint vtype);
  
  event ValueConfChanged(address indexed underlying, address oracle, uint discount, uint premium);

  event LiquidateRateChanged(uint liquidateRate);
  event CollateralRateChanged(uint collateralRate);

  event OpenLiquidateChanged(bool open);
  event AllowedLiquidatorChanged(address liquidator, bool allowed);

  constructor() {  
  }

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    liquidateRate  = 11000;  // PercentBase * 1.1;
    collateralRate = 13000;  // PercentBase * 1.3;
    isOpenLiquidate = true;
  }

  // ======  yield =======
  function setDYToken(address _underlying, address _dToken) external onlyOwner {
    require(_dToken != address(0), "INVALID_DTOKEN");
    address oldDToken = dyTokens[_underlying];
    dyTokens[_underlying] = _dToken;
    emit UnderlyingDTokenChanged(_underlying, oldDToken, _dToken);
  }


  // set or update strategy
  // stype: 1: pancakeswap 
  function setStrategy(address _underlying, address _strategy, uint stype) external onlyOwner {
    require(_strategy != address(0), "Strategies Disabled");

    address _current = strategies[_underlying];
    if (_current != address(0)) {
      IStrategy(_current).withdrawAll();
    }
    strategies[_underlying] = _strategy;

    emit UnderlyingStrategyChanged(_underlying, _current, _strategy, stype);
  }

  function emergencyWithdrawAll(address _underlying) public onlyOwner {
    IStrategy(strategies[_underlying]).withdrawAll();
  }

  // ======  vault  =======
  function setOpenLiquidate(bool _open) external onlyOwner {
    isOpenLiquidate = _open;
    emit OpenLiquidateChanged(_open);
  }

  function updateAllowedLiquidator(address liquidator, bool allowed) external onlyOwner {
    allowedLiquidator[liquidator] = allowed;
    emit AllowedLiquidatorChanged(liquidator, allowed);
  } 

  function setLiquidateRate(uint _liquidateRate) external onlyOwner {
    liquidateRate = _liquidateRate;
    emit LiquidateRateChanged(liquidateRate);
  }

  function setCollateralRate(uint _collateralRate) external onlyOwner {
    collateralRate = _collateralRate;
    emit CollateralRateChanged(collateralRate);
  }

  // @dev 允许为每个底层资产设置不同的价格预言机 折扣率、溢价率
  function setOracles(address _underlying, address _oracle, uint16 _discount, uint16 _premium) external onlyOwner {
    require(_oracle != address(0), "INVALID_ORACLE");
    require(_discount <= PercentBase, "DISCOUT_TOO_BIG");
    require(_premium >= PercentBase, "PREMIUM_TOO_SMALL");

    ValueConf storage conf = valueConfs[_underlying];
    conf.oracle = _oracle;
    conf.dr = _discount;
    conf.pr = _premium;

    emit ValueConfChanged(_underlying, _oracle, _discount, _premium);
  }

  function getValueConfs(address token0, address token1) external view returns (
    address oracle0, uint16 dr0, uint16 pr0,
    address oracle1, uint16 dr1, uint16 pr1) {
      (oracle0, dr0, pr0) = getValueConf(token0);
      (oracle1, dr1, pr1) = getValueConf(token1);
  } 

  // get DiscountRate and PremiumRate
  function getValueConf(address _underlying) public view returns (address oracle, uint16 dr, uint16 pr) {
    ValueConf memory conf = valueConfs[_underlying];
    oracle = conf.oracle;
    dr = conf.dr;
    pr = conf.pr;
  }

  // vtype 1 : for deposit vault 2: for mint vault
  function setVault(address _dyToken, address _vault, uint vtype) external onlyOwner {
    require(IVault(_vault).isDuetVault(), "INVALIE_VALUT");
    address old = dyTokenVaults[_dyToken];
    dyTokenVaults[_dyToken] = _vault;
    emit DTokenVaultChanged(_dyToken, old, _vault, vtype);
  }

  function joinVault(address _user, bool isDepositVault) external {
    address vault = msg.sender;
    require(vaultStates[vault].enabled, "INVALID_CALLER");

    EnumerableSet.AddressSet storage set = isDepositVault ? userJoinedDepositVaults[_user] : userJoinedBorrowVaults[_user];
    require(set.length() <= JOINED_VAULT_LIMIT, "JOIN_TOO_MUCH");
    set.add(vault);
  }

  function exitVault(address _user, bool isDepositVault) external {
    address vault = msg.sender;
    require(vaultStates[vault].enabled, "INVALID_CALLER");

    EnumerableSet.AddressSet storage set = isDepositVault ? userJoinedDepositVaults[_user] : userJoinedBorrowVaults[_user];
    set.remove(vault);
  }

  function setVaultStates(address _vault, VaultState memory _state) external onlyOwner {
    vaultStates[_vault] = _state;
  }

  function userJoinedVaultInfoAt(address _user, bool isDepositVault, uint256 index) external view returns (address vault, VaultState memory state) {
    EnumerableSet.AddressSet storage set = isDepositVault ? userJoinedDepositVaults[_user] : userJoinedBorrowVaults[_user];
    vault = set.at(index);
    state = vaultStates[vault];
  }

  function userJoinedVaultCount(address _user, bool isDepositVault) external view returns (uint256) {
    return isDepositVault ? userJoinedDepositVaults[_user].length() : userJoinedBorrowVaults[_user].length();
  }

  /**
  * @notice  用户最大可借某 Vault 的资产数量
  */
  function maxBorrow(address _user, address vault) public view returns(uint) {
    uint totalDepositValue = accVaultVaule(_user, userJoinedDepositVaults[_user], true);
    uint totalBorrowValue = accVaultVaule( _user, userJoinedBorrowVaults[_user], true);

    uint validValue = totalDepositValue * PercentBase / collateralRate;
    if (validValue >= totalBorrowValue) {
      uint canBorrowValue = validValue - totalBorrowValue;
      return IMintVault(vault).valueToAmount(canBorrowValue, true);
    } else {
      return 0;
    }

  }

  /**
    * @notice  获取用户Vault价值
    * @param  _user 存款人
    * @param _dp  是否折价(Discount) 和 溢价(Premium)
    */
  function userValues(address _user, bool _dp) public view returns(uint totalDepositValue, uint totalBorrowValue) {
    totalDepositValue = accVaultVaule(_user, userJoinedDepositVaults[_user], _dp);
    totalBorrowValue = accVaultVaule( _user, userJoinedBorrowVaults[_user], _dp);
  }

  /**
    * @notice  预测用户更改Vault后的价值
    * @param  _user 存款人
    * @param  _vault 拟修改的Vault
    * @param  _amount 拟修改的数量
    * @param _dp  是否折价(Discount) 和 溢价(Premium)
    */
  function userPendingValues(address _user, IVault _vault, uint _amount, bool _dp) public view returns(uint pendingDepositValue, uint pendingBrorowValue) {
    pendingDepositValue = accPendingValue(_user, userJoinedDepositVaults[_user], IVault(_vault), _amount, _dp);
    pendingBrorowValue = accPendingValue(_user, userJoinedBorrowVaults[_user], IVault(_vault), _amount, _dp);
  }

  /**
  * @notice  判断该用户是否需要清算
  */
  function isNeedLiquidate(address _borrower) public view returns(bool) {
    (uint totalDepositValue, uint totalBorrowValue) = userValues(_borrower, true);
    return totalDepositValue * PercentBase < totalBorrowValue * liquidateRate;
  }

  function accVaultVaule(address _user, EnumerableSet.AddressSet storage set, bool _dp) internal view returns(uint totalValue) {
    uint len = set.length();
    for (uint256 i = 0; i < len; i++) {
      address vault = set.at(i);
      totalValue += IVault(vault).userValue(_user, _dp);
    }
  }

  function accPendingValue(address _user, EnumerableSet.AddressSet storage set, IVault vault, uint amount, bool _dp) internal view returns(uint totalValue) {
    uint len = set.length();
    for (uint256 i = 0; i < len; i++) {
      IVault v = IVault(set.at(i));
      if (vault == v) {
        totalValue += v.pendingValue(_user, amount);
      } else {
        totalValue += v.userValue(_user, _dp);
      }
    }
  }

  /**
    * @notice 存款前风控检查
    * param  user 存款人
    * @param _vault Vault地址
    * param  amount 存入的标的资产数量
    */
  function beforeDeposit(address , address _vault, uint) external view {
    VaultState memory state =  vaultStates[_vault];
    require(state.enabled && state.enableDeposit, "DEPOSITE_DISABLE");
  }

  /**
    @notice 借款前风控检查
    @param _user 借款人
    @param _vault 借贷市场地址
    @param _amount 待借标的资产数量
    */
  function beforeBorrow(address _user, address _vault, uint256 _amount) external view {
    VaultState memory state =  vaultStates[_vault];
    require(state.enabled && state.enableBorrow, "BORROW_DISABLED");

    uint totalDepositValue = accVaultVaule(_user, userJoinedDepositVaults[_user], true);
    uint pendingBrorowValue = accPendingValue(_user, userJoinedBorrowVaults[_user], IVault(_vault), _amount, true);

    require(totalDepositValue * PercentBase >= pendingBrorowValue * collateralRate, "LOW_COLLATERAL");
  }

  function beforeWithdraw(address _user, address _vault, uint256 _amount) external view {
    VaultState memory state = vaultStates[_vault];
    require(state.enabled && state.enableWithdraw, "WITHDRAW_DISABLED");

    uint pendingDepositValue = accPendingValue(_user, userJoinedDepositVaults[_user], IVault(_vault), _amount, true);
    uint totalBorrowValue = accVaultVaule(_user, userJoinedBorrowVaults[_user], true);
    require(pendingDepositValue * PercentBase >= totalBorrowValue * collateralRate, "LOW_COLLATERAL");
  }

  function beforeRepay(address _repayer, address _vault, uint256 _amount) external view {
    VaultState memory state =  vaultStates[_vault];
    require(state.enabled && state.enableRepay, "REPAY_DISABLED");
  }

  function liquidate(address _borrower, bytes calldata data) external {
    address liquidator = msg.sender;

    require(isOpenLiquidate || allowedLiquidator[liquidator], "INVALID_LIQUIDATOR");
    require(isNeedLiquidate(_borrower),  "COLLATERAL_ENOUGH");

    EnumerableSet.AddressSet storage set = userJoinedDepositVaults[_borrower];
    uint len = set.length();

    for (uint256 i = 0; i < len; i++) {
      IVault v = IVault(set.at(i));
      beforeLiquidate(_borrower, address(v));
      v.liquidate(liquidator, _borrower, data);
    }

    EnumerableSet.AddressSet storage set2 = userJoinedBorrowVaults[_borrower];
    uint len2 = set2.length();

    for (uint256 i = 0; i < len2; i++) {
      IVault v = IVault(set2.at(i));
      beforeLiquidate(_borrower, address(v));
      v.liquidate(liquidator, _borrower, data);
    }
  }

  function beforeLiquidate(address _borrower, address _vault) internal view {
    VaultState memory state =  vaultStates[_vault];
    require(state.enabled && state.enableLiquidate, "LIQ_DISABLED");
  }
  //  ======   vault end =======

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVault {
  // call from controller must impl.
  function underlying() external view returns (address);
  function isDuetVault() external view returns (bool);
  function liquidate(address liquidator, address borrower, bytes calldata data) external;
  function userValue(address user, bool dp) external view returns(uint);
  function pendingValue(address user, uint pending) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMintVault {

  function borrows(address user) external view returns(uint amount);
  function borrow(uint256 amount) external;
  function repay(uint256 amount) external;
  function repayTo(address to, uint256 amount) external;

  function valueToAmount(uint value, bool dp) external view returns(uint amount);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IController {
  function dyTokens(address) external view returns (address);
  function getValueConf(address _underlying) external view returns (address oracle, uint16 dr, uint16 pr);
  function getValueConfs(address token0, address token1) external view returns (address oracle0, uint16 dr0, uint16 pr0, address oracle1, uint16 dr1, uint16 pr1);

  function strategies(address) external view returns (address);
  function dyTokenVaults(address) external view returns (address);

  function beforeDeposit(address , address _vault, uint) external view;
  function beforeBorrow(address _borrower, address _vault, uint256 _amount) external view;
  function beforeWithdraw(address _redeemer, address _vault, uint256 _amount) external view;
  function beforeRepay(address _repayer , address _vault, uint256 _amount) external view;

  function joinVault(address _user, bool isDeposit) external;
  function exitVault(address _user, bool isDeposit) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IStrategy {

    function controller() external view returns (address);
    function getWant() external view returns (address);
    function deposit() external;
    function harvest() external;
    function withdraw(uint) external;
    function withdrawAll() external returns (uint256);
    function balanceOf() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Constants {
  uint public constant PercentBase = 10000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}