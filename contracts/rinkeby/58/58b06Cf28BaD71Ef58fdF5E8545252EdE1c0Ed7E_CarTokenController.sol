/*
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */

pragma solidity ^0.5.13;

import "@galtproject/whitelisted-tokensale/contracts/traits/Pausable.sol";
import "@galtproject/whitelisted-tokensale/contracts/traits/Managed.sol";
import "./interfaces/ICarToken.sol";
import "./interfaces/ICarTokenController.sol";


contract CarTokenController is ICarTokenController, Managed, Pausable {

  ICarToken public token;

  struct Investor {
    address addr;
    bool active;
  }

  mapping(bytes32 => Investor) public investors;
  mapping(address => bytes32) public keyOfInvestor;

  constructor () public {}

  function initialize(address _owner) public initializer {
    Ownable.initialize(_owner);
  }

  function setToken(ICarToken _token) external onlyOwner {
    token = _token;

    emit SetToken(address(_token));
  }

  function addNewInvestors(bytes32[] calldata _keys, address[] calldata _addrs) external onlyAdminOrManager {
    uint256 len = _keys.length;
    require(len == _addrs.length, "Lengths of keys and address does not match");

    for (uint256 i = 0; i < len; i++) {
      _setInvestorAddress(_keys[i], _addrs[i]);

      emit AddNewInvestor(_keys[i], _addrs[i]);
    }
  }

  function setInvestorActive(bytes32 _key, bool _active) external onlyAdminOrManager {
    require(investors[_key].addr != address(0), "Investor does not exists");
    investors[_key].active = _active;

    emit SetInvestorActive(_key, _active);
  }

  function migrateBalance(address _from, address _to) public onlyAdmin {
    _migrateBalance(_from, _to);
  }

  function changeInvestorAddress(bytes32 _investorKey, address _newAddr) external onlyAdmin {
    _changeInvestorAddress(_investorKey, _newAddr);
  }

  function changeInvestorAddressAndMigrateBalance(bytes32 _investorKey, address _newAddr) external onlyAdmin {
    address oldAddress = investors[_investorKey].addr;
    _changeInvestorAddress(_investorKey, _newAddr);
    _migrateBalance(oldAddress, _newAddr);
  }

  function changeMyAddress(bytes32 _investorKey, address _newAddr) external whenNotPaused {
    require(investors[_investorKey].addr == msg.sender, "Investor address and msg.sender does not match");

    _changeInvestorAddress(_investorKey, _newAddr);
  }

  function changeMyAddressAndMigrateBalance(bytes32 _investorKey, address _newAddr) external whenNotPaused {
    require(investors[_investorKey].addr == msg.sender, "Investor address and msg.sender does not match");

    address oldAddress = investors[_investorKey].addr;
    _changeInvestorAddress(_investorKey, _newAddr);
    _migrateBalance(oldAddress, _newAddr);
  }

  function mintTokens(address _addr, uint256 _amount) external onlyAdmin {
    token.mint(_addr, _amount);

    emit MintTokens(msg.sender, _addr, _amount);
  }

  function isInvestorAddressActive(address _addr) public view returns (bool) {
    return investors[keyOfInvestor[_addr]].active;
  }

  function requireInvestorsAreActive(address _investor1, address _investor2) public whenNotPaused view {
    require(
      isInvestorAddressActive(_investor1) && isInvestorAddressActive(_investor2),
      "The address has no Car token transfer permission"
    );
  }

  function _migrateBalance(address _from, address _to) internal {
    require(isInvestorAddressActive(_to), "Recipient investor does not active");

    uint256 fromBalance = token.balanceOf(_from);
    token.burn(_from, fromBalance);
    token.mint(_to, fromBalance);

    emit MigrateBalance(msg.sender, _from, _to);
  }

  function _changeInvestorAddress(bytes32 _investorKey, address _newAddr) internal {
    address oldAddress = investors[_investorKey].addr;
    require(oldAddress != _newAddr, "Old address and new address the same");

    keyOfInvestor[investors[_investorKey].addr] = bytes32(0);
    investors[_investorKey] = Investor(address(0), false);

    _setInvestorAddress(_investorKey, _newAddr);

    emit ChangeInvestorAddress(msg.sender, _investorKey, oldAddress, _newAddr);
  }

  function _setInvestorAddress(bytes32 _key, address _addr) internal {
    require(investors[_key].addr == address(0), "Investor already exists");
    require(keyOfInvestor[_addr] == bytes32(0), "Address already claimed");

    investors[_key] = Investor(_addr, true);
    keyOfInvestor[_addr] = _key;
  }

  function checkTransfer(address from, address to, uint256 amount) public view returns(bool success, string memory error) {
    if (from == address(0)) {
      return (false, "ERC20: transfer from the zero address");
    }
    if (to == address(0)) {
      return (false, "ERC20: transfer to the zero address");
    }
    if (token.balanceOf(from) < amount) {
      return (false, "ERC20: transfer amount exceeds balance");
    }
    if (!isInvestorAddressActive(from) || !isInvestorAddressActive(to)) {
      return (false, "The address has no Car token transfer permission");
    }
    if (paused()) {
      return (false, "Pausable: paused");
    }
    return (true, "");
  }

  function checkTransferFrom(
    address sender,
    address from,
    address to,
    uint256 amount
  )
    external
    view
    returns (bool success, string memory error)
  {
    (bool success, string memory error) = checkTransfer(from, to, amount);
    if (!success) {
      return (success, error);
    }
    if (token.allowance(from, sender) < amount) {
      return (false, "ERC20: transfer amount exceeds allowance");
    }
    return (true, "");
  }
}

/*
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */

pragma solidity ^0.5.13;


interface ICarToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function allowance(address owner, address spender) external view returns (uint256);
}

/*
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */

pragma solidity ^0.5.13;


interface ICarTokenController {
  event SetToken(address indexed token);
  event AddNewInvestor(bytes32 indexed key, address indexed addr);
  event SetInvestorActive(bytes32 indexed key, bool active);
  event MigrateBalance(address indexed sender, address indexed from, address indexed to);
  event ChangeInvestorAddress(address indexed sender, bytes32 indexed key, address indexed oldAddr, address newAddr);
  event MintTokens(address indexed sender, address indexed addr, uint256 amount);

  function requireInvestorsAreActive(address _investor1, address _investor2) external view;
}

/*
 * Copyright ©️ 2018-2020 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018-2020 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */

pragma solidity ^0.5.13;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";


contract Administrated is Initializable, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  event AddAdmin(address indexed admin);
  event RemoveAdmin(address indexed admin);

  EnumerableSet.AddressSet internal admins;

  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Administrated: Msg sender is not admin");
    _;
  }
  constructor() public {
  }

  function addAdmin(address _admin) external onlyOwner {
    admins.add(_admin);
    emit AddAdmin(_admin);
  }

  function removeAdmin(address _admin) external onlyOwner {
    admins.remove(_admin);
    emit RemoveAdmin(_admin);
  }

  function isAdmin(address _admin) public view returns (bool) {
    return admins.contains(_admin);
  }

  function getAdminList() external view returns (address[] memory) {
    return admins.enumerate();
  }

  function getAdminCount() external view returns (uint256) {
    return admins.length();
  }
}

/*
 * Copyright ©️ 2018-2020 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018-2020 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */

pragma solidity ^0.5.13;

import "./Administrated.sol";


contract Managed is Administrated {

  event AddManager(address indexed manager, address indexed admin);
  event RemoveManager(address indexed manager, address indexed admin);

  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet internal managers;

  modifier onlyAdminOrManager() {
    require(isAdmin(msg.sender) || isManager(msg.sender), "Managered: Msg sender is not admin or manager");
    _;
  }

  modifier onlyManager() {
    require(isManager(msg.sender), "Managered: Msg sender is not manager");
    _;
  }

  function addManager(address _manager) external onlyAdmin {
    managers.add(_manager);
    emit AddManager(_manager, msg.sender);
  }

  function removeManager(address _manager) external onlyAdmin {
    managers.remove(_manager);
    emit RemoveManager(_manager, msg.sender);
  }

  function isManager(address _manager) public view returns (bool) {
    return managers.contains(_manager);
  }

  function getManagerList() external view returns (address[] memory) {
    return managers.enumerate();
  }

  function getManagerCount() external view returns (uint256) {
    return managers.length();
  }
}

/*
 * Copyright ©️ 2018-2020 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018-2020 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */

pragma solidity ^0.5.13;

import "./Administrated.sol";


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Administrated {
  /**
   * @dev Emitted when the pause is triggered by an admin (`account`).
   */
  event Paused(address admin);

  /**
   * @dev Emitted when the pause is lifted by an admin (`account`).
   */
  event Unpaused(address admin);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state. Assigns the Pauser role
   * to the deployer.
   */
  constructor () internal {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused, "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused, "Pausable: not paused");
    _;
  }

  /**
   * @dev Called by a pauser to pause, triggers stopped state.
   */
  function pause() public onlyAdmin whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Called by a pauser to unpause, returns to normal state.
   */
  function unpause() public onlyAdmin whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

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
 * As of v2.5.0, only `address` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.AddressSet;`.
 *
 * _Available since v2.5.0._
 *
 * @author Alberto Cuesta Cañada
 */
library EnumerableSet {

    struct AddressSet {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (address => uint256) index;
        address[] values;
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                address lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        address[] memory output = new address[](set.values.length);
        for (uint256 i; i < set.values.length; i++){
            output[i] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(AddressSet storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return set.values[index];
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}