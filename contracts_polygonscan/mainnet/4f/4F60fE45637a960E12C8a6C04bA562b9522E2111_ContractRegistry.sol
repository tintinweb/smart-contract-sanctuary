// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity >=0.6.12 <0.8.0;

library ArrayLib {

    string constant NOT_IN_ARRAY     = "Not in array";
    string constant ALREADY_IN_ARRAY = "Already in array";

    // address array

    function inArray(address[] storage array, address _item)
    internal view returns (bool) {
        uint len = array.length;
        for (uint i=0; i<len; i++) {
            if (array[i]==_item) return true;
        }
        return false;
    }

    function addUnique(address[] storage array, address _item)
    internal {
        require(!inArray(array, _item), ALREADY_IN_ARRAY);
        array.push(_item);
    }

    function removeByIndex(address[] storage array, uint256 index)
    internal {
        uint256 len_1 = array.length - 1;
        require(index<=len_1, NOT_IN_ARRAY);
        for (uint256 i = index; i < len_1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();
    }

    function removeFirst(address[] storage array, address _item)
    internal {
        require(inArray(array, _item), NOT_IN_ARRAY);
        uint last = array.length-1;
        for (uint i=0; i<=last; i++) {
            if (array[i]==_item) {
                removeByIndex(array, i);
                return;
            }
        }
    }

    function addArrayUnique(address[] storage array, address[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            addUnique(array, _items[i]);
        }
    }

    function removeArrayFirst(address[] storage array, address[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            removeFirst(array, _items[i]);
        }
    }

    function inArray(uint256[] storage array, uint256 _item)
    internal view returns (bool) {
        uint len = array.length;
        for (uint i=0; i<len; i++) {
            if (array[i]==_item) return true;
        }
        return false;
    }

    function addUnique(uint256[] storage array, uint256 _item)
    internal {
        require(!inArray(array, _item), ALREADY_IN_ARRAY);
        array.push(_item);
    }


    function removeByIndex(uint256[] storage array, uint256 index)
    internal {
        uint256 len_1 = array.length - 1;
        require(index<=len_1, NOT_IN_ARRAY);
        for (uint256 i = index; i < len_1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();
    }

    function removeFirst(uint256[] storage array, uint256 _item)
    internal {
        require(inArray(array, _item), NOT_IN_ARRAY);
        uint last = array.length-1;
        for (uint i=0; i<=last; i++) {
            if (array[i]==_item) {
                removeByIndex(array, i);
                return;
            }
        }
    }

    function addArrayUnique(uint256[] storage array, uint256[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            addUnique(array, _items[i]);
        }
    }

    function removeArrayFirst(uint256[] storage array, uint256[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            removeFirst(array, _items[i]);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./Governable.sol";
import "./ArrayLib.sol";

contract ContractRegistry is Governable, Initializable {
    using Address for address;
    using ArrayLib for address[];

    uint public constant POOLS_FOLDER = 1;
    uint public constant VAULTS_FOLDER = 2;

    mapping (uint => address[]) public addresses;

    event AddressesAdded(address[] addresses);
    event AddressesRemoved(address[] addresses);
    event PoolsAdded(address[] addresses);
    event PoolsRemoved(address[] addresses);
    event VaultsAdded(address[] addresses);
    event VaultsRemoved(address[] addresses);

    address[] private singleAddress;

    constructor(address[] memory _pools, address[] memory _vaults)
    public Governable(msg.sender) {
        singleAddress.push(address(0));
    }

    function initialize(address[] memory _pools, address[] memory _vaults)
    public onlyGovernance initializer {
        Governable.setGovernance(msg.sender);
        singleAddress.push(address(0));

        addPoolsArray(_pools);
        addVaultsArray(_vaults);
    }

    function list(uint folder) public view returns (address[] memory) {
        return addresses[folder];
    }

    function add(uint folder, address _address) public onlyGovernance {
        addresses[folder].addUnique(_address);

        singleAddress[0] = _address;
        emit AddressesAdded(singleAddress);
    }

    function remove(uint folder, address _address) public onlyGovernance {
        addresses[folder].removeFirst(_address);

        singleAddress[0] = _address;
        emit AddressesRemoved(singleAddress);
    }

    function addArray(uint folder, address[] memory _addresses) public onlyGovernance {
        addresses[folder].addArrayUnique(_addresses);
        emit AddressesAdded(_addresses);
    }

    function removeArray(uint folder, address[] memory _addresses) public onlyGovernance {
        addresses[folder].removeArrayFirst(_addresses);
        emit AddressesRemoved(_addresses);
    }

    // Pools

    function listPools() public view returns (address[] memory) {
        return addresses[POOLS_FOLDER];
    }

    function addPool(address _address) public onlyGovernance {
        addresses[POOLS_FOLDER].addUnique(_address);

        singleAddress[0] = _address;
        emit PoolsAdded(singleAddress);
    }

    function removePool(address _address) public onlyGovernance {
        addresses[POOLS_FOLDER].removeFirst(_address);

        singleAddress[0] = _address;
        emit PoolsRemoved(singleAddress);
    }

    function addPoolsArray(address[] memory _addresses) public onlyGovernance {
        addresses[POOLS_FOLDER].addArrayUnique(_addresses);
        emit PoolsAdded(_addresses);
    }

    function removePoolsArray(address[] memory _addresses) public onlyGovernance {
        addresses[POOLS_FOLDER].removeArrayFirst(_addresses);
        emit PoolsRemoved(_addresses);
    }


    // Vaults

    function listVaults() public view returns (address[] memory) {
        return addresses[VAULTS_FOLDER];
    }

    function addVault(address _address) public onlyGovernance {
        addresses[VAULTS_FOLDER].addUnique(_address);

        singleAddress[0] = _address;
        emit VaultsAdded(singleAddress);
    }

    function removeVault(address _address) public onlyGovernance {
        addresses[VAULTS_FOLDER].removeFirst(_address);

        singleAddress[0] = _address;
        emit VaultsRemoved(singleAddress);
    }

    function addVaultsArray(address[] memory _addresses) public onlyGovernance {
        addresses[VAULTS_FOLDER].addArrayUnique(_addresses);
        emit VaultsAdded(_addresses);
    }

    function removeVaultsArray(address[] memory _addresses) public onlyGovernance {
        addresses[VAULTS_FOLDER].removeArrayFirst(_addresses);
        emit VaultsRemoved(_addresses);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract Governable {

  address public governance;

  constructor(address _governance) public {
    setGovernance(_governance);
  }

  modifier onlyGovernance() {
    // pass check while governance might not initialized (i.e. in proxy)
    require((governance==address(0)) || (msg.sender==governance), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

}

