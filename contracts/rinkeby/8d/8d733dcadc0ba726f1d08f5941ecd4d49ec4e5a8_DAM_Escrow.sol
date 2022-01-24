/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]


// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)



/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)



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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)



/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)



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


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]


// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;




/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)




/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}


// File contracts/DAM_escrow.sol


interface IERC20 {
        function transfer(address _to, uint256 _amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
        function mint(uint numTokens, address owner) external;
        function burn(uint numTokens) external;
        function tokenID() external view returns(uint);
        function ownerOf(uint tokenId) external returns (address);
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
  {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
          return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
          r := mload(add(signature, 0x20))
          s := mload(add(signature, 0x40))
          v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
          v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
          return (address(0));
        } else {
          // solium-disable-next-line arg-overflow
          return ecrecover(hash, v, r, s);
        }
  }

  /**
        * toEthSignedMessageHash
        * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
        * and hash the result
        */
  function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
  {
        return keccak256(
          abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
  }
}

contract DAM_Escrow is UUPSUpgradeable {
        uint public _tokenIds;
        mapping(uint => uint) public tokenMarketID;

        address[] paymentTokenAddress; //ERC20 payment token required to buy in (wETH/USDT?)
        mapping(uint => address) delegate; //minion
        address[] public owner;

        uint[][] public otherMarkets; //list of MarketIDs of other markets that can participate in local audits

        struct transactionData {
                address buyer;
                address seller;
                bytes32 spec;
                address paymentTokenAddress;
                uint paymentAmount;
                uint expiry; //block number
                bytes buyerSignature;
                bytes sellerSignature;
                uint[] auditIDs;

                bool finished;
        }

        struct assayerInput{
                uint marketAddressID;
                uint tokenID;
                bytes32 commit;
                bool revealed;
        }

        struct auditData{
                bytes32 buyerEvidence;
                bytes32 sellerEvidence;
                uint expiry; //block number
                uint price;
                bool resolved; // set true if delegate/minion decides
                bool refund; // minions decision

                bool resolvedByVerdict;
                assayerInput[] commits;
                bool[] verdicts; // false in favor of seller, true in favor of buyer - refund

                mapping(uint => bool) assayerPaid;//commits# => true/false
                uint marketID;
        }

        uint[] transactionID;
        transactionData[] emptyT;// used for initialization
        transactionData[][] transactions;

        uint auditID;
        auditData[] audits;

        uint[] mintingNewAssayerCost;// = 1000000000000000; // starting price 0.001
        uint16[] feePercent;// = 100; //1%
        uint[] auditTimeExtension;// = 5760; // 1 day
        bytes32[] public receipts;

        IERC721 public damToken;
        address public deployer;


        event Transaction(address indexed buyer, address indexed seller, bytes32 spec, address indexed _paymentTokenAddress, uint paymentAmount, uint expiry, uint transactionID, uint marketID);
        event Audit(address indexed initator, uint _transactionID, uint expiry, uint price, uint auditID);
        event CommittedAssay(address indexed assayer, uint auditID, uint assayID);
        event RevealedAssay(address indexed assayer, uint auditID, uint assayID, bool refund);
        event NewMarket(uint MarketID);
        event TransactionReceipt(uint transactionID, uint marketID, uint receiptID);

        function initialize(address _paymentTokenAddress, address _owner, uint _mintingNewAssayerCost, uint16 _feePercent, uint _auditTimeExtension) initializer public {
                __UUPSUpgradeable_init();
                paymentTokenAddress.push(_paymentTokenAddress); //Test token - wETH
                owner.push(_owner); //multisig contract / gnosis safe
                mintingNewAssayerCost.push(_mintingNewAssayerCost);
                feePercent.push(_feePercent);
                auditTimeExtension.push(_auditTimeExtension);
                uint[] memory emptyOM;
                otherMarkets.push(emptyOM);
                transactions.push(emptyT);
                transactionID.push(0);
                deployer=msg.sender;
        }
        function _authorizeUpgrade(address newImplementation)
        internal
        override
    {
                require(msg.sender == deployer);
        }

        function createMarket(address _paymentTokenAddress, uint _mintingNewAssayerCost, uint16 _feePercent, uint _auditTimeExtension) public {
                emit NewMarket(owner.length);
                paymentTokenAddress.push(_paymentTokenAddress);
                owner.push(msg.sender);
                mintingNewAssayerCost.push(_mintingNewAssayerCost);
                feePercent.push(_feePercent);
                auditTimeExtension.push(_auditTimeExtension);
                uint[] memory emptyOM;
                otherMarkets.push(emptyOM);
                transactions.push(emptyT);
                transactionID.push(0);
        }

        function specifySeller(uint _transactionID, uint marketID, bytes32 receipt) public {
                require(transactions[marketID][_transactionID].seller == address(0), "26");
                receipts.push(receipt);
                transactions[marketID][_transactionID].seller=msg.sender;
                transactions[marketID][_transactionID].expiry+=block.number;
                emit TransactionReceipt(_transactionID, marketID, receipts.length-1);
        }

        function createTransaction(address buyer, address seller, bytes32 spec, address _paymentTokenAddress, uint paymentAmount, uint blocks, bytes memory  buyerSignature, bytes memory  sellerSignature, uint marketID)
        public {
                require(IERC20(_paymentTokenAddress).transferFrom(buyer, address(this), paymentAmount), "1");

                // messageHash = keccak256(abi.encodePacked( SPEC, PAYMENT TOKEN ADDRESS, PAYMENT AMOUNTH, BLOCKS - TIME )
                // require(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(spec, _paymentTokenAddress, paymentAmount, blocks ))), sellerSignature)==seller, "2");
                if(msg.sender != owner[marketID] && msg.sender != buyer) // alowing multisig / market owner to burn treasury - since contract addresses cannot sign messages
                require(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(spec, _paymentTokenAddress, paymentAmount, blocks ))), buyerSignature)==buyer, "3");

                transactionData memory temp;
                temp.buyer = buyer;
                temp.seller = seller;
                temp.spec = spec;
                temp.paymentTokenAddress = _paymentTokenAddress;
                temp.paymentAmount = paymentAmount;
                temp.expiry = (seller == address(0) ? 0 : block.number) + blocks;
                temp.buyerSignature = buyerSignature;
                temp.sellerSignature = sellerSignature;
                temp.finished = false;
                transactions[marketID].push(temp);

                emit Transaction(temp.buyer, temp.seller,  temp.spec, _paymentTokenAddress, temp.paymentAmount, temp.expiry, transactionID[marketID], marketID);
                transactionID[marketID]++;
        }

        function mintingNewAssayersCost(uint number, uint marketID) public view returns(uint) {
                uint price;
                for (uint i; i < number; i++)
                        price += mintingNewAssayerCost[marketID]*2**i;
                return price;
        }

        function addAssayer(uint marketID) public {
                require(IERC20(paymentTokenAddress[marketID]).transferFrom(msg.sender, owner[marketID], mintingNewAssayerCost[marketID]), "1");
                tokenMarketID[damToken.tokenID()] = marketID;
                mintingNewAssayerCost[marketID] *= 2;
                damToken.mint(1,msg.sender);
        }

        function addAssayers(uint number, uint marketID) external {
                require(IERC20(paymentTokenAddress[marketID]).transferFrom(msg.sender, owner[marketID], mintingNewAssayersCost(number, marketID)), "1");
                for (uint i; i < number; i++) {
                        tokenMarketID[damToken.tokenID()] = marketID;
                        mintingNewAssayerCost[marketID] *= 2;
                }
                damToken.mint(number,msg.sender);
        }

        function payWithFee(uint _transactionID, uint marketID) internal {
                if(transactions[marketID][_transactionID].buyer==owner[marketID]) //without fee if buyer is market owner
                        IERC20(transactions[marketID][_transactionID].paymentTokenAddress).transfer(msg.sender, transactions[marketID][_transactionID].paymentAmount);
                else {
                        IERC20(transactions[marketID][_transactionID].paymentTokenAddress).transfer(msg.sender, transactions[marketID][_transactionID].paymentAmount - transactions[marketID][_transactionID].paymentAmount/10000*feePercent[marketID]);
                        IERC20(transactions[marketID][_transactionID].paymentTokenAddress).transfer(owner[marketID], transactions[marketID][_transactionID].paymentAmount/10000*feePercent[marketID]);
                }
                transactions[marketID][_transactionID].finished = true;
        }

        function withdraw(uint _transactionID, uint marketID) public {
                require(transactions[marketID][_transactionID].expiry < block.number, "4");
                require(!transactions[marketID][_transactionID].finished, "5");
                if (msg.sender == transactions[marketID][_transactionID].seller) { //checking if withdraw was called by seller
                        if (transactions[marketID][_transactionID].auditIDs.length == 0) { //checking if no audits were called
                                payWithFee(_transactionID, marketID);
                        } else { //checking if all audits were resolved and in favor of seller
                                uint resolved;
                                for (uint i; i < transactions[marketID][_transactionID].auditIDs.length; i++) { // first we check if audit was ruled by delegate / minion
                                        if (audits[transactions[marketID][_transactionID].auditIDs[i]].resolved && !audits[transactions[marketID][_transactionID].auditIDs[i]].refund)
                                                resolved++;
                                        else { //then we check if all assayers voted in the favor of the seller
                                                require(audits[transactions[marketID][_transactionID].auditIDs[i]].expiry < block.number, "6");
                                                require(audits[transactions[marketID][_transactionID].auditIDs[i]].commits.length == audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts.length , "7");
                                                uint verdicts;
                                                for(uint j; j < audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts.length; j++){
                                                        if (!audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts[j])
                                                                verdicts++;
                                                }
                                                if (verdicts != 0 && verdicts == audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts.length){
                                                        resolved++;
                                                        audits[transactions[marketID][_transactionID].auditIDs[i]].resolvedByVerdict = true;
                                                }
                                        }
                                }
                                require(resolved == transactions[marketID][_transactionID].auditIDs.length, "8");
                                payWithFee(_transactionID, marketID);
                        }
                }
                else if (msg.sender == transactions[marketID][_transactionID].buyer && transactions[marketID][_transactionID].auditIDs.length > 0) {// checking if withdraw was called by buyer
                        uint resolved;//checking if all audits were resolved and in favor of seller
                        for (uint i; i < transactions[marketID][_transactionID].auditIDs.length; i++) { // first we check if audit was ruled by delegate / minion
                                if (audits[transactions[marketID][_transactionID].auditIDs[i]].resolved && audits[transactions[marketID][_transactionID].auditIDs[i]].refund)
                                        resolved++;
                                else { //then we check if all assayers voted in the favor of the buyer
                                        require(audits[transactions[marketID][_transactionID].auditIDs[i]].expiry < block.number, "6");
                                        require(audits[transactions[marketID][_transactionID].auditIDs[i]].commits.length == audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts.length , "7");
                                        uint verdicts;
                                        for(uint j; j < audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts.length; j++){
                                                if (audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts[j])
                                                        verdicts++;
                                        }
                                        if (verdicts != 0 && verdicts == audits[transactions[marketID][_transactionID].auditIDs[i]].verdicts.length) {
                                                resolved++;
                                                audits[transactions[marketID][_transactionID].auditIDs[i]].resolvedByVerdict = true;
                                        }
                                }
                        }
                        require(resolved == transactions[marketID][_transactionID].auditIDs.length, "8");
                        payWithFee(_transactionID, marketID);
                }
        }

        modifier auditNotExpired(uint _auditID) {
                require(audits[_auditID].expiry > block.number, "10");
                _;
        }

        function audit(uint _transactionID, uint blocks, uint auditPrice, uint marketID)
        public {//require some payment?
                require(IERC20(paymentTokenAddress[marketID]).transferFrom(msg.sender, address(this),auditPrice), "1");
                require(transactions[marketID][_transactionID].expiry > block.number, "9");
                transactions[marketID][_transactionID].auditIDs.push(auditID);
                audits.push();
                audits[auditID].expiry = block.number + blocks;
                audits[auditID].price = auditPrice;
                audits[auditID].marketID = marketID;
                emit Audit(msg.sender, _transactionID, audits[auditID].expiry, audits[auditID].price, auditID);
                auditID++;
        }

        function fillEvidence(uint _transactionID, uint _auditID, bytes32 evidence, uint marketID)
        auditNotExpired(_auditID)
        public {
                if(transactions[marketID][_transactionID].buyer == msg.sender) audits[_auditID].buyerEvidence = evidence;
                else if(transactions[marketID][_transactionID].seller == msg.sender) audits[_auditID].sellerEvidence = evidence;
                else revert("13");
        }

        function resolveAudit(uint _auditID, bool refund, uint marketID) public onlyOwner(marketID) {
                require(!audits[_auditID].resolvedByVerdict && !audits[_auditID].resolved, "15");
                audits[_auditID].resolved = true;
                audits[_auditID].refund = refund;
                IERC20(paymentTokenAddress[marketID]).transfer(msg.sender, audits[_auditID].price);
        }

        function burn(uint tokenID, uint marketID) public onlyOwnerOrDelegate(marketID) {
                damToken.burn(tokenID);
        }

        function tokenID() public returns(uint) {
                return damToken.tokenID();
        }

        function mint(uint numTokens, uint marketID) public onlyOwner(marketID){
                for (uint i; i < numTokens; i++) {
                        tokenMarketID[damToken.tokenID()] = marketID;
                        mintingNewAssayerCost[marketID] *= 2;
                }
                damToken.mint(numTokens, msg.sender);
        }

        function commitAssay(uint _auditID, bytes32 saltedCommit, uint _marketAddressID, uint _tokenID)
        auditNotExpired(_auditID)
        public {
                if(_marketAddressID == 0) require(damToken.ownerOf(_tokenID)==msg.sender && audits[_auditID].marketID==tokenMarketID[_tokenID],"16"); // _marketAddressID = 0 in cases when assayers are only from local market and not from "otherMarkets"
                //else require(ERC721Upgradeable(otherMarkets[audits[_auditID].marketID][_marketAddressID-1]).ownerOf(_tokenID)==msg.sender,"17");
                else require(damToken.ownerOf(_tokenID)==msg.sender && tokenMarketID[_tokenID]==otherMarkets[audits[_auditID].marketID][_marketAddressID-1],"17");
                for(uint i; i < audits[_auditID].commits.length; i++){
                        require(!(audits[_auditID].commits[i].marketAddressID == _marketAddressID && audits[_auditID].commits[i].tokenID == _tokenID),"18");
                }
                emit CommittedAssay(msg.sender, _auditID, audits[_auditID].commits.length);
                audits[_auditID].commits.push(assayerInput(_marketAddressID, _tokenID, saltedCommit, false));
        }

        modifier trueAssayer(uint _auditID, uint assayID) {
                if(audits[_auditID].commits[assayID].marketAddressID==0) require(damToken.ownerOf(audits[_auditID].commits[assayID].tokenID)==msg.sender,"19");
                //else require(ERC721Upgradeable(]).ownerOf(audits[_auditID].commits[assayID].tokenID)==msg.sender,"20");
                else require(damToken.ownerOf(audits[_auditID].commits[assayID].tokenID)==msg.sender && tokenMarketID[audits[_auditID].commits[assayID].tokenID]==otherMarkets[audits[_auditID].marketID][audits[_auditID].commits[assayID].marketAddressID-1],"20");
                _;
        }

        function revealAssay(uint _auditID, bool refund, bytes32 salt, uint assayID)
        trueAssayer(_auditID, assayID)
        auditNotExpired(_auditID)
        public {
                require(!audits[_auditID].commits[assayID].revealed, "21");
                require(getSaltedHash(refund,salt)==audits[_auditID].commits[assayID].commit,"22");
                audits[_auditID].commits[assayID].revealed=true;
                audits[_auditID].verdicts.push(refund);
                emit RevealedAssay(msg.sender, _auditID, assayID, refund);
                if(audits[_auditID].expiry < (block.number + auditTimeExtension[audits[_auditID].marketID]))
                        audits[_auditID].expiry = block.number + auditTimeExtension[audits[_auditID].marketID];
        }

        function assayerWithdrawFee(uint _auditID, uint assayID)
        trueAssayer(_auditID, assayID)
        public {
                require(audits[_auditID].resolvedByVerdict, "23");
                require(!audits[_auditID].assayerPaid[assayID], "24");
                IERC20(paymentTokenAddress[audits[_auditID].marketID]).transfer(msg.sender, audits[_auditID].price / audits[_auditID].verdicts.length);
                audits[_auditID].assayerPaid[assayID] = true;
        }

        function assayerWithdrawFees(uint[2][] memory assays) public {
                for(uint i; i<assays.length; i++)
                        assayerWithdrawFee(assays[i][0], assays[i][1]);
        }

        function assignDelegate(address _delegate, uint marketID) public onlyOwner(marketID){// assign delegate / minion address
                delegate[marketID]=_delegate;
        }

        function getSaltedHash(bool refund,bytes32 salt) public view returns(bytes32){
                return keccak256(abi.encodePacked(address(this), refund, salt));
        }

        modifier onlyOwner(uint marketID) {
                require(msg.sender == owner[marketID], "25");
                _;
        }
        modifier onlyOwnerOrDelegate(uint marketID) {
                require(msg.sender == owner[marketID] || msg.sender == delegate[marketID] , "25");
                _;
        }
        function transferOwnership(address newowner, uint marketID) public onlyOwner(marketID) {
                owner[marketID] = newowner;
        }

        function updateAuditTimeExtension(uint _auditTimeExtension, uint marketID) public onlyOwner(marketID){
                auditTimeExtension[marketID] = _auditTimeExtension;
        }

        function updateOtherMarkets(uint[] memory newSet, uint marketID) public onlyOwnerOrDelegate(marketID){
                otherMarkets[marketID] = newSet;
        }

        function addOtherMarket(uint newMarket, uint marketID) public onlyOwnerOrDelegate(marketID){
                otherMarkets[marketID].push(newMarket);
        }

        function setDAM(address damTokenAddress) external{
                if(msg.sender==owner[0])
                        damToken=IERC721(damTokenAddress);
        }


}