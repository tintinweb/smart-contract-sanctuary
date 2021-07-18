// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./traits/Managed.sol";
import "./traits/PausableOwnable.sol";
import "./interfaces/IWlController.sol";

/**
 * @title AssetWhitelist
 *
 * @dev The contract stores a whitelist of users (investors) and allows to
 * manage it. It is possible to check the whitelisted status of users from
 * the whitelist located in the separate CarTokenController contract.
 * All users checks can be disabled by owner.
 *
 * CarTokenController contract source: https://github.com/CurioTeam/security-token-contracts/blob/dd5c82e566d24d0e87639316a9420afdb9b30e71/contracts/CarTokenController.sol
 */
contract AssetWhitelist is Initializable, Managed, PausableOwnable {

    /// @notice CarTokenController contract
    IWlController public controller;

    struct Investor {
        address addr;
        bool active;
    }

    /// @notice Investor by key
    mapping(bytes32 => Investor) public investors;

    /// @notice Investor address to key
    mapping(address => bytes32) public keyOfInvestor;

    /// @notice Whitelist status: enabled/disabled
    bool public isWlActive;

    event SetController(address indexed controller);
    event SetWlActive(bool active);

    event AddNewInvestor(bytes32 indexed key, address indexed addr);
    event SetInvestorActive(bytes32 indexed key, bool active);
    event ChangeInvestorAddress(
        address indexed sender,
        bytes32 indexed key,
        address indexed oldAddr,
        address newAddr
    );


    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     * and in unpaused and WL active state.
     */
    function __AssetWhitelist_init() external initializer {
        __Ownable_init();
        __Pausable_init();

        isWlActive = true;
    }


    /**
     * @dev Checks if an investor's account is whitelisted. Check is done
     * in the whitelist of the contract and also in the CarTokenController.
     *
     * @param _addr The address of investor's account to check.
     */
    function isInvestorAddressActive(address _addr)
        external
        view
        returns (bool)
    {
        return
            !isWlActive ||
            investors[keyOfInvestor[_addr]].active ||
            (
                address(controller) != address(0)
                    ? controller.isInvestorAddressActive(_addr)
                    : false
            );
    }

    /**
     * @dev Allows the msg.sender change your address in whitelist.
     *
     * Requirements:
     * - the contract must not be paused.
     *
     * @param _investorKey The key of investor.
     * @param _newAddr The address of investor's account.
     */
    function changeMyAddress(bytes32 _investorKey, address _newAddr)
        external
        whenNotPaused
    {
        require(
            investors[_investorKey].addr == msg.sender,
            "Investor address and msg.sender does not match"
        );

        _changeInvestorAddress(_investorKey, _newAddr);
    }


    // ** ADMIN/MANAGER/OWNER role functions **

    /**
     * @dev Allows the admin or manager to add new investors
     * to whitelist.
     *
     * Requirements:
     * - lengths of keys and address arrays should be equal.
     *
     * @param _keys The keys of investors.
     * @param _addrs The addresses of investors accounts.
     */
    function addNewInvestors(
        bytes32[] calldata _keys,
        address[] calldata _addrs
    ) external onlyAdminOrManager {
        uint256 len = _keys.length;
        require(
            len == _addrs.length,
            "Lengths of keys and address does not match"
        );

        for (uint256 i = 0; i < len; i++) {
            _setInvestorAddress(_keys[i], _addrs[i]);

            emit AddNewInvestor(_keys[i], _addrs[i]);
        }
    }

    /**
     * @dev Allows the admin or manager to change investor's
     * whitelisted status.
     *
     * Emits a {SetInvestorActive} event with investor's key and new status.
     *
     * Requirements:
     * - the investor must be added to whitelist.
     *
     * @param _key The keys of investor.
     * @param _active The new status of investor's account.
     */
    function setInvestorActive(bytes32 _key, bool _active)
        external
        onlyAdminOrManager
    {
        require(investors[_key].addr != address(0), "Investor does not exists");
        investors[_key].active = _active;

        emit SetInvestorActive(_key, _active);
    }

    /**
     * @dev Allows the admin to change investor's address.
     *
     * @param _investorKey The keys of investor.
     * @param _newAddr The new address of investor's account.
     */
    function changeInvestorAddress(bytes32 _investorKey, address _newAddr)
        external
        onlyAdmin
    {
        _changeInvestorAddress(_investorKey, _newAddr);
    }

    /**
     * @dev Allows the owner to set CarTokenController contract.
     *
     * Emits a {SetController} event with `controller` set to
     * CarTokenController contract's address.
     *
     * @param _controller The address of CarTokenController contract.
     */
    function setController(IWlController _controller) external onlyOwner {
        controller = _controller;
        emit SetController(address(_controller));
    }

    /**
     * @dev Allows the owner to set enabled/disabled status of investor whitelist.
     *
     * Emits a {SetWlActive} event with a new status.
     *
     * @param _active Investor whitelist status.
     */
    function setWlActive(bool _active) external onlyOwner {
        isWlActive = _active;
        emit SetWlActive(_active);
    }


    // ** INTERNAL functions **

    /**
     * @dev Saves the investor's key and address and sets the status as whitelisted.
     *
     * Requirements:
     * - key and address must be empty.
     *
     * @param _key The key of investor.
     * @param _addr The address of investor.
     */
    function _setInvestorAddress(bytes32 _key, address _addr) internal {
        require(investors[_key].addr == address(0), "Investor already exists");
        require(keyOfInvestor[_addr] == bytes32(0), "Address already claimed");

        investors[_key] = Investor(_addr, true);
        keyOfInvestor[_addr] = _key;
    }

    /**
     * @dev Changes the address of the investor with the given key.
     *
     * Emits a {ChangeInvestorAddress} event with parameters: `sender` as msg.sender,
     * `key`, `oldAddr`, `newAddr`.
     *
     * Requirements:
     * - the new address must be different from the old one.
     *
     * @param _investorKey The key of investor.
     * @param _newAddr The new address of investor.
     */
    function _changeInvestorAddress(bytes32 _investorKey, address _newAddr)
        internal
    {
        address oldAddress = investors[_investorKey].addr;
        require(oldAddress != _newAddr, "Old address and new address the same");

        keyOfInvestor[investors[_investorKey].addr] = bytes32(0);
        investors[_investorKey] = Investor(address(0), false);

        _setInvestorAddress(_investorKey, _newAddr);

        emit ChangeInvestorAddress(
            msg.sender,
            _investorKey,
            oldAddress,
            _newAddr
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Interface of Whitelist controller.
 */
interface IWlController {
    function isInvestorAddressActive(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Administrated
 *
 * @dev Contract provides a basic access control mechanism for Admin role.
 */
abstract contract Administrated is Initializable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event AddAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);

    EnumerableSetUpgradeable.AddressSet internal admins;

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Administrated: sender is not admin");
        _;
    }

    /**
     * @dev Checks if an account is admin.
     * @param _admin The address of admin account to check.
     */
    function isAdmin(address _admin) public view returns (bool) {
        return admins.contains(_admin);
    }

    /**
     * @dev Returns count of added admins accounts.
     */
    function getAdminCount() external view returns (uint256) {
        return admins.length();
    }

    /**
     * @dev Allows the owner to add admin account.
     *
     * Emits a {AddAdmin} event with `admin` set to new added admin address.
     *
     * @param _admin The address of admin account to add.
     */
    function addAdmin(address _admin) external onlyOwner {
        admins.add(_admin);
        emit AddAdmin(_admin);
    }

    /**
     * @dev Allows the owner to remove admin account.
     *
     * Emits a {RemoveAdmin} event with `admin` set to removed admin address.
     *
     * @param _admin The address of admin account to remove.
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins.remove(_admin);
        emit RemoveAdmin(_admin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Administrated.sol";

/**
 * @title Managed
 *
 * @dev Contract provides a basic access control mechanism for Manager role.
 * The contract also includes control of access rights for Admin and Manager roles both.
 */
abstract contract Managed is Initializable, Administrated {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event AddManager(address indexed manager, address indexed admin);
    event RemoveManager(address indexed manager, address indexed admin);

    EnumerableSetUpgradeable.AddressSet internal managers;

    /**
     * @dev Throws if called by any account other than the admin or manager.
     */
    modifier onlyAdminOrManager() {
        require(
            isAdmin(msg.sender) || isManager(msg.sender),
            "Managered: sender is not admin or manager"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(isManager(msg.sender), "Managered: sender is not manager");
        _;
    }

    /**
     * @dev Checks if an account is manager.
     * @param _manager The address of manager account to check.
     */
    function isManager(address _manager) public view returns (bool) {
        return managers.contains(_manager);
    }

    /**
     * @dev Returns count of added managers accounts.
     */
    function getManagerCount() external view returns (uint256) {
        return managers.length();
    }

    /**
     * @dev Allows the admin to add manager account.
     *
     * Emits a {AddManager} event with `manager` set to new added manager address
     * and `admin` to who added it.
     *
     * @param _manager The address of manager account to add.
     */
    function addManager(address _manager) external onlyAdmin {
        managers.add(_manager);
        emit AddManager(_manager, msg.sender);
    }

    /**
     * @dev Allows the admin to remove manager account.
     *
     * Emits a {removeManager} event with `manager` set to removed manager address
     * and `admin` to who removed it.
     *
     * @param _manager The address of manager account to remove.
     */
    function removeManager(address _manager) external onlyAdmin {
        managers.remove(_manager);
        emit RemoveManager(_manager, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title PausableOwnable
 *
 * @dev Contract provides a stop emergency mechanism for owner.
 */
abstract contract PausableOwnable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    /**
     * @dev Allows the owner to pause, triggers stopped state.
     *
     * Emits a {Paused} event.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Allows the owner to do unpause, returns to normal state.
     *
     * Emits a {Unpaused} event.
     */
    function unpause() public onlyOwner {
        _unpause();
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
library EnumerableSetUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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