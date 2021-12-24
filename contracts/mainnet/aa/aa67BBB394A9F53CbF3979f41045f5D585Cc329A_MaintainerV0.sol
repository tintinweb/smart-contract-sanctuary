/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../InitializableUpgrades.sol";
import "./ToonTokenMaintainerAccess.sol";

contract MaintainerV0 is
    OwnableUpgradeable,
    InitializableUpgrades,
    ToonTokenMaintainerAccess
{
    function upgrade(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }

    function initialize()
        external
        virtual
        override
        initializer
        implementationInitializer
    {
        __Ownable_init();
    }

    function onlyAuthorized() public virtual override returns (bool) {
        return owner() == _msgSender();
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./EIP1967/EIP1967Reader.sol";
import "./EIP1967/EIP1967Writer.sol";

abstract contract InitializableUpgrades is EIP1967Reader, EIP1967Writer {
    address private _implementationInitialized;

    modifier implementationInitializer() {
        require(
            _implementationInitialized != implementation(),
            "already upgraded"
        );

        _;

        _implementationInitialized = implementation();
    }

    // solhint-disable-next-line no-empty-blocks
    function initialize() external virtual implementationInitializer {}

    function implementation() public view returns (address) {
        return _implementationAddress();
    }

    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../v0Extended/ToonTokenV0Extended.sol";

abstract contract ToonTokenMaintainerAccess {
    address payable private _toonTokenContractAddress;

    modifier maintainerAuthorized() {
        require(onlyAuthorized(), "you shall not pass");

        _;
    }

    function setToonTokenContractAddress(
        address payable nextToonTokenContractAddress
    ) external maintainerAuthorized {
        _toonTokenContractAddress = nextToonTokenContractAddress;
    }

    function setWallets(address nextMaintainerWallet, address nextBountyWallet)
        external
        maintainerAuthorized
    {
        ToonTokenV0Extended(_toonTokenContractAddress).setWallets(
            nextMaintainerWallet,
            nextBountyWallet
        );
    }

    function setBountyObligationReferencePrice(uint256 referencePrice)
        external
        maintainerAuthorized
    {
        ToonTokenV0Extended(_toonTokenContractAddress)
            .setBountyObligationReferencePrice(referencePrice);
    }

    function proposeDistribution(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    ) external maintainerAuthorized {
        ToonTokenV0Extended(_toonTokenContractAddress).proposeDistribution(
            nextProposedDistributionAddress,
            nextProposedDistributionAmount
        );
    }

    function proposeUpgrade(address nextProposedUpgradeImpl)
        external
        maintainerAuthorized
    {
        ToonTokenV0Extended(_toonTokenContractAddress).proposeUpgrade(
            nextProposedUpgradeImpl
        );
    }

    function holdElectionsAndUpdate() external maintainerAuthorized {
        ToonTokenV0Extended(_toonTokenContractAddress).holdElectionsAndUpdate();
    }

    function confirmConsensusAndUpdate(
        address winningCandidate,
        address[] memory voters,
        address[] memory abstainedVoters
    ) external {
        ToonTokenV0Extended(_toonTokenContractAddress)
            .confirmConsensusAndUpdate(
                winningCandidate,
                voters,
                abstainedVoters
            );
    }

    function onlyAuthorized() public virtual returns (bool);

    function getToonTokenContractAddress()
        public
        view
        returns (address payable)
    {
        return _toonTokenContractAddress;
    }

    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

abstract contract EIP1967Reader {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    bytes4 internal constant _INITIALIZE_CALL =
        bytes4(keccak256("initialize()"));

    function _implementationAddress() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "./EIP1967Reader.sol";

abstract contract EIP1967Writer is EIP1967Reader {
    event Upgraded(address implementation);

    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        _initializeImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "implementation is not a contract"
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    function _initializeImplementation(address newImplementation) private {
        bytes memory data = abi.encodePacked(_INITIALIZE_CALL);
        Address.functionDelegateCall(newImplementation, data);
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

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
library StorageSlot {
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

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../v0/ToonTokenV0.sol";
import "./Obligations.sol";

contract ToonTokenV0Extended is ToonTokenV0, Obligations {
    uint256 private constant _UNMINTED_RESERVE_LIMIT = 10000 * 10**18;

    uint256 public maintainerBonusReserve;


    uint256 public bountyBonusReserve;

    uint256 public bountyObligationReferencePrice;

    event BountyObligationReferencePriceUpdated(uint256 referencePrice);

    function setBountyObligationReferencePrice(uint256 referencePrice)
        external
        onlyMaintainer
    {
        require(
            referencePrice > (currentPricePerToken * 2),
            "twice the current price"
        );
        bountyObligationReferencePrice = referencePrice;

        emit BountyObligationReferencePriceUpdated(referencePrice);
    }

    function lockTokens(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) external {
        _createObligation(
            _msgSender(),
            amount,
            recipient,
            releaseTime,
            targetPrice
        );
    }

    function mintAndLockMaintainerBonusReserves() public {
        _mint(maintainerWallet, maintainerBonusReserve);
        _createObligation(
            maintainerWallet,
            maintainerBonusReserve,
            maintainerWallet,
            block.timestamp + 365 days,
            currentPricePerToken * 2
        );
        maintainerBonusReserve = 0;
    }

    function mintAndLockBountyBonusReserves() public {
        _mint(bountyWallet, bountyBonusReserve);

        uint256 targetPrice = currentPricePerToken * 2;
        if (currentPricePerToken < bountyObligationReferencePrice) {
            targetPrice = Math.min(bountyObligationReferencePrice, targetPrice);
        }

        _createObligation(
            bountyWallet,
            bountyBonusReserve,
            bountyWallet,
            block.timestamp + 36500 days,
            targetPrice
        );
        bountyBonusReserve = 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return
            super.totalSupply() + maintainerBonusReserve + bountyBonusReserve;
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        _transfer(sender, recipient, amount);
    }

    function _mintMaintainerBonus(uint256 maintainerBonusTokensAmount)
        internal
        virtual
        override
    {
        maintainerBonusReserve += maintainerBonusTokensAmount;

        if (maintainerBonusReserve > _UNMINTED_RESERVE_LIMIT) {
            mintAndLockMaintainerBonusReserves();
        }
    }

    function _mintBountyBonus(uint256 bountyBonusTokensAmount)
        internal
        virtual
        override
    {
        bountyBonusReserve += bountyBonusTokensAmount;

        if (bountyBonusReserve > _UNMINTED_RESERVE_LIMIT) {
            mintAndLockBountyBonusReserves();
        }
    }

    function _currentPricePerToken()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return currentPricePerToken;
    }

    // solhint-disable-next-line ordering
    uint256[47] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./libraries/Calculator.sol";
import "./libraries/Elections.sol";
import "./libraries/ElectionsPrincipal.sol";
import "./libraries/Proposals.sol";

import "../InitializableUpgrades.sol";

import "./LUTs.sol";
import "./Voting.sol";
import "./ChainlinkETHUSD.sol";

// solhint-disable ordering
abstract contract ToonTokenV0 is
    ERC20Upgradeable,
    InitializableUpgrades,
    LUTs,
    Voting,
    ChainlinkETHUSD,
    ElectionsPrincipal
{
    uint256 public currentPricePerToken;

    bool public consensus;

    address public maintainer;

    address public maintainerWallet;

    address public bountyWallet;

    address payable public proposedDistributionAddress;

    uint256 public proposedDistributionAmount;

    uint256 public distributionProposedAt;

    address public proposedUpgradeImpl;

    uint256 public upgradeProposedAt;

    string private _overriddenName;

    event ConsensusChanged(bool newValue);

    event MaintainerChanged(address newValue);

    event MaintainerBonusWalletChanged(address nextMaintainerWallet);

    event BountyBonusWalletChanged(address nextBountyWallet);

    event DistributionProposed(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    );

    event UpgradeProposed(address nextProposedUpgradeImpl);

    event ProposedDistributionExecuted(uint256 amount, address recipient);

    event ProposedUpgradeExecuted(address newImplementation);

    function _onlyMaintainer() private view {
        require(_msgSender() == maintainer, "only maintainer");
    }

    modifier onlyMaintainer() {
        _onlyMaintainer();
        _;
    }

    function _hasConsensus() private view {
        require(consensus == true, "community must reach consensus");
    }

    modifier hasConsensus() {
        _hasConsensus();
        _;
    }

    function initialize()
        external
        virtual
        override
        initializer
        implementationInitializer
    {
        __ToonTokenV0_init();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ToonTokenV0_init()
        internal
        initializer
        implementationInitializer
    {
        __ERC20_init("Toon Token (ToonCoin)", "TOON");
        __ToonTokenV0_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ToonTokenV0_init_unchained()
        internal
        initializer
        implementationInitializer
    {
        consensus = true;
    }

    function name() public view virtual override returns (string memory) {
        if (bytes(_overriddenName).length == 0) return super.name();
        return _overriddenName;
    }

    function overrideName(string memory overriddenName_) external {
        require(
            address(0) == maintainer || _msgSender() == maintainer,
            "not authorized"
        );
        _overriddenName = overriddenName_;
    }

    function vote(address candidate) external {
        require(votesOf(_msgSender()) > 0, "voting for tokenholders");

        _vote(_msgSender(), candidate);
    }

    function candidateOf(address voter) public view override returns (address) {
        return _votersDecisions[voter];
    }

    function holdElectionsAndUpdate() external {
        (
            address winningCandidate,
            uint256 winningCandidateVotes,
            uint256 runnerUpCandidateVotes,
            uint256 totalVotes
        ) = Elections.findTop2(_voters, ElectionsPrincipal(this));

        bool newConsensus = Elections.calcConsensus(
            winningCandidateVotes,
            totalVotes
        );

        if (false == consensus && true == newConsensus) {
            require(
                msg.sender == winningCandidate,
                "only a winner can allow consensus to be restored"
            );
        }

        _finishElections(
            newConsensus,
            winningCandidate,
            runnerUpCandidateVotes,
            totalVotes
        );
    }

    function confirmConsensusAndUpdate(
        address winningCandidate,
        address[] memory voters,
        address[] memory abstainedVoters
    ) external {
        uint256 winningCandidateVotes = Elections.sumVotesFor(
            winningCandidate,
            voters,
            ElectionsPrincipal(this)
        );

        uint256 abstainedVotes = Elections.sumVotesFor(
            address(0),
            abstainedVoters,
            ElectionsPrincipal(this)
        );

        uint256 totalVotes = totalSupply() - abstainedVotes;

        if (Elections.calcConsensus(winningCandidateVotes, totalVotes)) {
            if (false == consensus) {
                require(
                    msg.sender == winningCandidate,
                    "only a winner can allow consensus to be restored"
                );
            }

            uint256 runnerUpCandidateVotes = totalVotes - winningCandidateVotes;
            _finishElections(
                true,
                winningCandidate,
                runnerUpCandidateVotes,
                totalVotes
            );
        }
    }

    function breakConsensus(
        address[] memory alternativeCandidateVoters,
        address[] memory abstainedVoters
    ) external hasConsensus {
        uint256 votes = Elections.sumVotesExceptZeroAnd(
            maintainer,
            alternativeCandidateVoters,
            ElectionsPrincipal(this)
        );

        uint256 abstainedVotes = Elections.sumVotesFor(
            address(0),
            abstainedVoters,
            ElectionsPrincipal(this)
        );

        uint256 totalVotes = totalSupply() - abstainedVotes;
        uint256 maintainerVotes = totalVotes - votes;

        if (!Elections.calcConsensus(maintainerVotes, totalVotes)) {
            _finishElections(false, maintainer, votes, totalVotes);
        }
    }

    function _finishElections(
        bool newConsensus,
        address winningCandidate,
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (consensus != newConsensus) {
            consensus = newConsensus;
            emit ConsensusChanged(newConsensus);
        }

        if (maintainer != winningCandidate) {
            _dropProposals();
            maintainer = winningCandidate;
            emit MaintainerChanged(winningCandidate);
        }

        if (consensus) {
            _performProposedDistribution(runnerUpCandidateVotes, totalVotes);
            _performProposedUpgrade(runnerUpCandidateVotes, totalVotes);
        }
    }

    function _performProposedDistribution(
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (
            consensus &&
            proposedDistributionAddress != address(0) &&
            Proposals.isExecutionAllowed(
                distributionProposedAt,
                runnerUpCandidateVotes,
                totalVotes
            )
        ) {
            address payable recipient = proposedDistributionAddress;
            uint256 amount = proposedDistributionAmount;

            proposedDistributionAddress = payable(0);
            proposedDistributionAmount = 0;

            (bool success, ) = recipient.call{value: amount}("");
            require(success, "proposed distribution failed");

            emit ProposedDistributionExecuted(amount, recipient);
        }
    }

    function _performProposedUpgrade(
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (
            consensus &&
            proposedUpgradeImpl != address(0) &&
            Proposals.isExecutionAllowed(
                upgradeProposedAt,
                runnerUpCandidateVotes,
                totalVotes
            )
        ) {
            address impl = proposedUpgradeImpl;
            proposedUpgradeImpl = address(0);

            _upgradeTo(impl);
            emit ProposedUpgradeExecuted(impl);
        }
    }

    function setWallets(address nextMaintainerWallet, address nextBountyWallet)
        external
        onlyMaintainer
    {
        if (maintainerWallet != nextMaintainerWallet) {
            maintainerWallet = nextMaintainerWallet;
            emit MaintainerBonusWalletChanged(maintainerWallet);
        }

        if (bountyWallet != nextBountyWallet) {
            bountyWallet = nextBountyWallet;
            emit BountyBonusWalletChanged(bountyWallet);
        }
    }

    function proposeDistribution(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    ) external onlyMaintainer {
        require(
            address(this).balance >= nextProposedDistributionAmount,
            "too much"
        );

        proposedDistributionAddress = nextProposedDistributionAddress;
        proposedDistributionAmount = nextProposedDistributionAmount;
        distributionProposedAt = block.timestamp;

        emit DistributionProposed(
            proposedDistributionAddress,
            proposedDistributionAmount
        );
    }

    function proposeUpgrade(address nextProposedUpgradeImpl)
        external
        onlyMaintainer
    {
        proposedUpgradeImpl = nextProposedUpgradeImpl;
        upgradeProposedAt = block.timestamp;
        emit UpgradeProposed(proposedUpgradeImpl);
    }

    function _dropProposals() private {
        proposedDistributionAddress = payable(0);
        proposedUpgradeImpl = address(0);
    }

    function votesOf(address account) public view override returns (uint256) {
        return balanceOf(account);
    }

    receive() external payable hasConsensus {
        address buyer = _msgSender();
        _purchase(buyer, _convertEthToUsd(msg.value));

        if (
            candidateOf(buyer) == address(0) &&
            balanceOf(buyer) > (1000 * 10**decimals())
        ) {
            _vote(buyer, maintainer);
        }
    }

    function purchase() external payable hasConsensus {
        _purchase(_msgSender(), _convertEthToUsd(msg.value));
    }

    function purchaseAndVote(address candidate) external payable hasConsensus {
        _purchase(_msgSender(), _convertEthToUsd(msg.value));
        _vote(_msgSender(), candidate);
    }

    function _purchase(address account, uint256 usdAmount) internal {
        require(account != address(0), "purchase from the zero address");
        require(usdAmount > 0, "no funds");

        Calculator.Result memory r = Calculator.calcTokens(
            usdAmount,
            totalSupply(),
            _nodeId,
            address(0) == maintainerWallet,
            address(0) == bountyWallet,
            _supplyLUT,
            _priceLUT
        );

        _nodeId = r.nextNodeId;
        currentPricePerToken = r.nextPricePerToken;

        _mint(account, r.tokensAmount);

        if (r.maintainerBonusTokensAmount > 0)
            _mintMaintainerBonus(r.maintainerBonusTokensAmount);

        if (r.bountyBonusTokensAmount > 0)
            _mintBountyBonus(r.bountyBonusTokensAmount);
    }

    function _mintMaintainerBonus(uint256 amount) internal virtual;

    function _mintBountyBonus(uint256 amount) internal virtual;

    uint256[40] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

abstract contract Obligations {
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _obligations;

    event ObligationCreated(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    );

    event ObligationPaidOff(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    );

    function payOffObligation(
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) public {
        require(
            block.timestamp >= releaseTime ||
                _currentPricePerToken() >= targetPrice,
            "too early"
        );
        require(
            _obligations[recipient][releaseTime][targetPrice] > 0,
            "nothing to pay off"
        );

        uint256 amount = _obligations[recipient][releaseTime][targetPrice];
        _obligations[recipient][releaseTime][targetPrice] = 0;

        _transferTokens(address(this), recipient, amount);
        emit ObligationPaidOff(amount, recipient, releaseTime, targetPrice);
    }

    function obligation(
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) public view returns (uint256) {
        return _obligations[recipient][releaseTime][targetPrice];
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual;

    function _currentPricePerToken() internal virtual returns (uint256);

    function _createObligation(
        address account,
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) internal {
        _transferTokens(account, address(this), amount);
        _obligations[recipient][releaseTime][targetPrice] += amount;
        emit ObligationCreated(
            _obligations[recipient][releaseTime][targetPrice],
            recipient,
            releaseTime,
            targetPrice
        );
    }

    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library Calculator {
    struct Result {
        uint256 tokensAmount;
        uint256 maintainerBonusTokensAmount;
        uint256 bountyBonusTokensAmount;
        uint256 nextNodeId;
        uint256 nextPricePerToken;
    }

    // solhint-disable-next-line contract-name-camelcase
    struct _LoopState {
        uint256 prev;
        uint256 curr;
        uint256 next;
    }

    uint8 public constant DECIMALS = 18;

    uint256 public constant MAINTAINER_BONUS_PRICE_THRESHOLD =
        10 * 10**DECIMALS;

    uint256 public constant BOUNTY_BONUS_PRICE_THRESHOLD = 20 * 10**DECIMALS;

    function adjustNodeId(
        uint256 nodeId,
        uint256 supply,
        uint256[] storage supplyLUT
    ) public view returns (uint256) {
        if (supply < supplyLUT[nodeId + 1]) {
            if (supply < supplyLUT[nodeId]) {
                while (true) {
                    nodeId -= 1;
                    if (supply >= supplyLUT[nodeId]) {
                        return nodeId;
                    }
                }
            }
        } else {
            while (true) {
                nodeId += 1;
                if (supply < supplyLUT[nodeId + 1]) {
                    return nodeId;
                }
            }
        }

        return nodeId;
    }

    // solhint-disable-next-line function-max-lines
    function calcTokens(
        uint256 usdAmount,
        uint256 supply,
        uint256 nodeId,
        bool suppressMaintainerBonus,
        bool suppressBountyBonus,
        uint256[] storage supplyLUT,
        uint256[] storage priceLUT
    ) public view returns (Result memory r) {
        require(
            supply >= supplyLUT[nodeId] && supply < supplyLUT[nodeId + 1],
            "nodeId is out of sync"
        );

        r.nextNodeId = nodeId;

        _LoopState memory supplyNode = _LoopState(0, supply, 0);
        _LoopState memory priceNode = _LoopState(0, 0, 0);

        while (true) {
            supplyNode.prev = supplyLUT[r.nextNodeId];
            supplyNode.next = supplyLUT[r.nextNodeId + 1];

            priceNode.prev = priceLUT[r.nextNodeId];
            priceNode.next = priceLUT[r.nextNodeId + 1];

            priceNode.curr = _approxPricePerToken(supplyNode, priceNode);

            uint256 usdAmountMaxed = usdAmount * 10**DECIMALS;
            uint256 tokensByIteration;

            if (
                supplyNode.next - supplyNode.curr >
                (2 * usdAmountMaxed) / (priceNode.next + priceNode.curr)
            ) {
                _LoopState memory adjustedSupplyNode = _LoopState(
                    supplyNode.prev,
                    supplyNode.curr +
                        usdAmountMaxed /
                        (priceNode.next + priceNode.curr),
                    supplyNode.next
                );

                tokensByIteration =
                    usdAmountMaxed /
                    _approxPricePerToken(adjustedSupplyNode, priceNode);

                r.tokensAmount += tokensByIteration;
                supplyNode.curr += tokensByIteration;

                usdAmount = 0;
            }
            else {
                tokensByIteration = supplyNode.next - supplyNode.curr;

                r.tokensAmount += tokensByIteration;
                supplyNode.curr = supplyNode.next;
                r.nextNodeId += 1;

                usdAmount -=
                    (tokensByIteration *
                        ((priceNode.curr + priceNode.next) / 2)) /
                    10**DECIMALS;
            }

            if (
                false == suppressMaintainerBonus &&
                priceNode.curr >= MAINTAINER_BONUS_PRICE_THRESHOLD
            ) {
                r.maintainerBonusTokensAmount += tokensByIteration / 10;
                supplyNode.curr += tokensByIteration / 10;
            }

            if (
                false == suppressBountyBonus &&
                priceNode.curr >= BOUNTY_BONUS_PRICE_THRESHOLD
            ) {
                r.bountyBonusTokensAmount += tokensByIteration / 10;
                supplyNode.curr += tokensByIteration / 10;
            }

            r.nextNodeId = adjustNodeId(
                r.nextNodeId,
                supplyNode.curr,
                supplyLUT
            );

            if (usdAmount == 0) break;
        }

        r.nextPricePerToken = _approxPricePerToken(supplyNode, priceNode);
    }

    function _approxPricePerToken(
        _LoopState memory supplyNode,
        _LoopState memory priceNode
    ) private pure returns (uint256) {
        return
            ((supplyNode.curr - supplyNode.prev) *
                (priceNode.next - priceNode.prev)) /
            (supplyNode.next - supplyNode.prev) +
            priceNode.prev;
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ElectionsPrincipal.sol";

library Elections {
    using EnumerableSet for EnumerableSet.AddressSet;

    function findTop2(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        public
        view
        returns (
            address winningCandidate,
            uint256 winningCandidateVotes,
            uint256 runnerUpCandidateVotes,
            uint256 totalVotes
        )
    {
        (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes_
        ) = _convertVotersList(voters, principal);

        require(candidatesCount > 0, "no candidates");

        totalVotes = totalVotes_;

        for (uint256 j = 0; j < candidatesCount; j++) {
            uint256 votes = candidatesVotes[j];

            if (votes > winningCandidateVotes) {
                runnerUpCandidateVotes = winningCandidateVotes;

                winningCandidate = candidatesList[j];
                winningCandidateVotes = votes;
            } else if (votes > runnerUpCandidateVotes) {
                runnerUpCandidateVotes = votes;
            }
        }
    }

    function sumVotesFor(
        address expectedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 j = 0; j < selectedVoters.length; j++) {
            address voter = selectedVoters[j];
            address candidate = principal.candidateOf(voter);
            if (
                candidate == expectedCandidate &&
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    function sumVotesExceptZeroAnd(
        address excludedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 i = 0; i < selectedVoters.length; i++) {
            address voter = selectedVoters[i];
            address candidate = principal.candidateOf(voter);
            if (
                candidate != excludedCandidate &&
                candidate != address(0) &&
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    function calcConsensus(uint256 votes, uint256 totalVotes)
        public
        pure
        returns (bool)
    {
        return votes > (totalVotes / 2);
    }

    function _convertVotersList(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        private
        view
        returns (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes
        )
    {
        for (uint256 i = 0; i < voters.length(); i++) {
            address voter = voters.at(i);
            uint256 voterBalance = principal.votesOf(voter);
            address candidate = principal.candidateOf(voter);

            if (voterBalance > 0 && candidate != address(0)) {
                totalVotes += voterBalance;

                (bool found, uint256 foundIndex) = _findIndex(
                    candidate,
                    candidatesList,
                    candidatesCount
                );

                if (found) {
                    candidatesVotes[foundIndex] += voterBalance;
                } else {
                    candidatesList[candidatesCount] = candidate;
                    candidatesVotes[candidatesCount] = voterBalance;
                    candidatesCount++;
                }
            }
        }
    }

    function _findIndex(
        address predicate,
        address[2500] memory array,
        uint256 length
    ) private pure returns (bool found, uint256 index) {
        for (uint256 j = 0; j < length; j++) {
            if (predicate == array[j]) {
                return (true, j);
            }
        }
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ElectionsPrincipal {
    function candidateOf(address account) external view returns (address);

    function votesOf(address account) external view returns (uint256);
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library Proposals {
    function isExecutionAllowed(
        uint256 proposedAt,
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) public view returns (bool) {
        if (
            proposedAt < (block.timestamp - 14 days) &&
            runnerUpCandidateVotes < (totalVotes / 10)
        ) return true;

        if (
            proposedAt < (block.timestamp - 30 days) &&
            runnerUpCandidateVotes < (totalVotes / 5)
        ) return true;

        if (
            proposedAt < (block.timestamp - 90 days) &&
            runnerUpCandidateVotes < ((totalVotes * 3) / 10)
        ) return true;

        if (proposedAt < (block.timestamp - 180 days)) return true;

        return false;
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./libraries/LUTsLoader.sol";

abstract contract LUTs {
    uint256[] internal _supplyLUT;

    uint256[] internal _priceLUT;

    uint256 internal _nodeId;

    function initSupplyLUT0() external {
        LUTsLoader.fillSupplyNodes0(_supplyLUT);
    }

    function initSupplyLUT1() external {
        LUTsLoader.fillSupplyNodes1(_supplyLUT);
    }

    function initSupplyLUT2() external {
        LUTsLoader.fillSupplyNodes2(_supplyLUT);
    }

    function initSupplyLUT3() external {
        LUTsLoader.fillSupplyNodes3(_supplyLUT);
    }

    function initPriceLUT0() external {
        LUTsLoader.fillPriceNodes0(_priceLUT);
    }

    function initPriceLUT1() external {
        LUTsLoader.fillPriceNodes1(_priceLUT);
    }

    function initPriceLUT2() external {
        LUTsLoader.fillPriceNodes2(_priceLUT);
    }

    function initPriceLUT3() external {
        LUTsLoader.fillPriceNodes3(_priceLUT);
    }

    // solhint-disable-next-line ordering
    uint256[47] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Voting {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => address) internal _votersDecisions;

    EnumerableSet.AddressSet internal _voters;

    event Vote(address voter, address candidate);

    function _vote(address voter, address candidate) internal {
        require(voter != address(0), "vote from the zero address");

        if (_votersDecisions[voter] != candidate) {
            _votersDecisions[voter] = candidate;

            if (candidate == address(0)) {
                _voters.remove(voter);
            } else {
                _voters.add(voter);
            }

            emit Vote(voter, candidate);
        }
    }

    // solhint-disable-next-line ordering
    uint256[48] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract ChainlinkETHUSD {
    address private _chainlinkDataFeed;

    function setChainlinkDataFeed(address dataFeed) external {
        require(_chainlinkDataFeed == address(0), "already set");

        _chainlinkDataFeed = dataFeed;
    }

    function getChainlinkDataFeed() external view returns (address) {
        return _chainlinkDataFeed;
    }

    function _convertEthToUsd(uint256 ethAmount)
        internal
        view
        virtual
        returns (uint256)
    {
        (
            uint80 roundId,
            int256 price,
            ,
            ,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_chainlinkDataFeed).latestRoundData();

        require(answeredInRound == roundId, "ChainLink ETHUSD outdated");

        require(price != 0, "ChainLink ETHUSD is not working");

        return (ethAmount * uint256(price)) / 10**8;
    }

    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

// solhint-disable function-max-lines
library LUTsLoader {
    function fillPriceNodes0(uint256[] storage table) public {
        require(table.length == 0, "fillPriceNodes0 initialized");
        table.push(1000000000000000000);
        table.push(1000000000000000000);
        table.push(1033606645623224470);
        table.push(1068342697876493930);
        table.push(1104246112328188820);
        table.push(1141356120106025580);
        table.push(1179713270764327210);
        table.push(1219359476591919000);
        table.push(1260338058409064100);
        table.push(1302693792903480290);
        table.push(1346472961557161720);
        table.push(1391723401217466800);
        table.push(1438494556367730870);
        table.push(1486837533154518710);
        table.push(1536805155230551890);
        table.push(1588452021474329500);
        table.push(1641834565649511820);
        table.push(1697011118069255650);
        table.push(1754041969332881080);
        table.push(1812989436204514000);
        table.push(1873917929705688630);
        table.push(1936894025496314190);
        table.push(2001986536620909530);
        table.push(2069266588699594950);
        table.push(2138807697646000820);
        table.push(2210685849997014580);
        table.push(2284979585942141040);
        table.push(2361770085143200780);
        table.push(2441141255438141000);
        table.push(2523179824525883880);
        table.push(2607975434732394970);
        table.push(2695620740961521310);
        table.push(2786211511937628940);
        table.push(2879846734850665300);
        table.push(2976628723517991680);
        table.push(3076663230181171820);
        table.push(3180059561059875540);
        table.push(3286930695789161540);
        table.push(3397393410870646550);
        table.push(3511568407272454180);
        table.push(3629580442317370290);
        table.push(3751558466003316470);
        table.push(3877635761905097530);
        table.push(4007950092811384140);
        table.push(4142643851256065920);
        table.push(4281864215108458380);
        table.push(4425763308392374480);
        table.push(4574498367509786500);
        table.push(4728231913050706700);
        table.push(4887131927377022510);
        table.push(5051372038174328040);
        table.push(5221131708172317770);
        table.push(5396596431241045490);
        table.push(5577957935077321170);
        table.push(5765414390702717620);
        table.push(5959170629002102420);
        table.push(6159438364539303700);
        table.push(6366436426894469410);
        table.push(6580390999775899300);
        table.push(6801535868167623740);
        table.push(7030112673782783500);
        table.push(7266371179101940510);
        table.push(7510569540284831100);
        table.push(7762974589253767290);
        table.push(8023862125256915240);
        table.push(8293517216230037150);
        table.push(8572234510285991150);
        table.push(8860318557672347560);
        table.push(9158084143548921540);
        table.push(9465856631948841370);
        table.push(9783972321298995170);
        table.push(10000000000000000000);
        table.push(10112778811888327300);
        table.push(10452635385685511300);
        table.push(10803913398921020600);
        table.push(11166996687862565900);
        table.push(11542281988227284500);
        table.push(11930179368688965600);
        table.push(12331112678953999500);
        table.push(12745520012895656700);
        table.push(13173854187252756300);
        table.push(13616583236415791500);
        table.push(14074190923841156000);
        table.push(14547177270652287900);
        table.push(15036059102005325000);
        table.push(15541370611816276600);
        table.push(16063663946466781400);
        table.push(16603509808126258000);
        table.push(17161498078349688800);
        table.push(17738238462632434500);
        table.push(18334361156626372800);
        table.push(18950517534745327200);
        table.push(19587380861912214700);
        table.push(20000000000000000000);
        table.push(20245647029225627600);
        table.push(20926035314349700600);
        table.push(21629289167458131500);
        table.push(22356177023591144600);
        table.push(23107493142313045200);
        table.push(23884058475587849400);
    }

    function fillPriceNodes1(uint256[] storage table) public {
        require(
            table[table.length - 1] < 24686721564821301100,
            "fillPriceNodes1 initialized"
        );
        table.push(24686721564821301100);
        table.push(25516359468049464100);
        table.push(26373878718287010700);
        table.push(27260216314082384000);
        table.push(28176340743362192900);
        table.push(29123253041683587000);
        table.push(30101987886050941400);
        table.push(31113614725492051300);
        table.push(32159238949629201000);
        table.push(33240003096521987000);
        table.push(34357088101101685300);
        table.push(35511714585561311700);
        table.push(36705144193111362400);
        table.push(37938680966558611200);
        table.push(39213672773214317400);
        table.push(40531512777688816900);
        table.push(41893640964181799500);
        table.push(43301545709931656800);
        table.push(44756765411543185700);
        table.push(46260890165970707900);
        table.push(47815563507993395200);
        table.push(49422484206081313100);
        table.push(51083408118614496100);
        table.push(52800150112483321000);
        table.push(54574586046166603400);
        table.push(56408654819454295500);
        table.push(58304360492054489000);
        table.push(60263774473399693700);
        table.push(62289037786045157700);
        table.push(64382363405132415600);
        table.push(66546038676474356100);
        table.push(68782427815904019300);
        table.push(71093974492618123100);
        table.push(73483204499338099900);
        table.push(75952728512206289100);
        table.push(78505244943432982500);
        table.push(81143542889811369200);
        table.push(83870505180322175600);
        table.push(86689111526158074600);
        table.push(89602441776609853000);
        table.push(92613679284371983900);
        table.push(95726114383944838100);
        table.push(98943147986934323100);
        table.push(102268295298177480000);
        table.push(105705189656754604000);
        table.push(109257586506084889000);
        table.push(112929367497443675000);
        table.push(116724544731385148000);
        table.push(120647265141705021000);
        table.push(124701815026733504000);
        table.push(128892624732909825000);
        table.push(133224273495755982000);
        table.push(137701494443539389000);
        table.push(142329179769091831000);
        table.push(147112386075435909000);
        table.push(152056339901060065000);
        table.push(157166443430879556000);
        table.push(162448280399123681000);
        table.push(167907622190599232000);
        table.push(173550434146996961000);
        table.push(179382882085131842000);
        table.push(185411339034239529000);
        table.push(191642392199690743000);
        table.push(198082850160732746000);
        table.push(204739750310122763000);
        table.push(211620366543782521000);
        table.push(218732217208876287000);
        table.push(226083073318997154000);
        table.push(233680967045438166000);
        table.push(241534200493826601000);
        table.push(249651354775711479000);
        table.push(258041299385016702000);
        table.push(266713201889605328000);
        table.push(275676537948544816000);
        table.push(284941101666018954000);
        table.push(294517016293200027000);
        table.push(304414745289775026000);
        table.push(314645103757212635000);
        table.push(325219270256263972000);
        table.push(336148799021609901000);
        table.push(347445632587001648000);
        table.push(359122114834690064000);
        table.push(371191004483402416000);
        table.push(383665489029604845000);
        table.push(396559199157283890000);
        table.push(409886223631992424000);
        table.push(423661124695434528000);
        table.push(437898953977410708000);
        table.push(452615268942510229000);
        table.push(467826149889521607000);
        table.push(483548217522136250000);
        table.push(499798651110144543000);
        table.push(516595207260968775000);
        table.push(533956239322044348000);
        table.push(551900717435249925000);
        table.push(570448249265299711000);
        table.push(589619101424747455000);
        table.push(609434221619012988000);
        table.push(629915261535628802000);
        table.push(651084600502717438000);
    }

    function fillPriceNodes2(uint256[] storage table) public {
        require(
            table[table.length - 1] < 672965369942550938000,
            "fillPriceNodes2 initialized"
        );
        table.push(672965369942550938000);
        table.push(695581478646912403000);
        table.push(718957638901877666000);
        table.push(743119393490563251000);
        table.push(768093143603346110000);
        table.push(793906177686052224000);
        table.push(820586701257636059000);
        table.push(848163867729932198000);
        table.push(876667810263155459000);
        table.push(906129674691957509000);
        table.push(936581653558017793000);
        table.push(968057021286355684000);
        table.push(1000590170543800500000);
        table.push(1034216649819347740000);
        table.push(1068973202267465000000);
        table.push(1104897805856791140000);
        table.push(1142029714868098590000);
        table.push(1180409502786862860000);
        table.push(1220079106637307550000);
        table.push(1261081872806367850000);
        table.push(1303462604407643680000);
        table.push(1347267610237096590000);
        table.push(1392544755373983200000);
        table.push(1439343513482316460000);
        table.push(1487715020870003480000);
        table.push(1537712132364729680000);
        table.push(1589389479067643980000);
        table.push(1642803528047951630000);
        table.push(1698012644043642040000);
        table.push(1755077153235771110000);
        table.push(1814059409165983300000);
        table.push(1875023860869300450000);
        table.push(1938037123296625170000);
        table.push(2003168050103908240000);
        table.push(2070487808887515830000);
        table.push(2140069958948005110000);
        table.push(2211990531667279270000);
        table.push(2286328113586949370000);
        table.push(2363163932278681310000);
        table.push(2442581945100356580000);
        table.push(2524668930935030560000);
        table.push(2609514585012929080000);
        table.push(2697211616920094230000);
        table.push(2787855851900772070000);
        table.push(2881546335564233860000);
        table.push(2978385442110442160000);
        table.push(3078478986192818510000);
        table.push(3181936338540343850000);
        table.push(3288870545465329570000);
        table.push(3399398452387443850000);
        table.push(3513640831508966390000);
        table.push(3631722513780779960000);
        table.push(3753772525303296530000);
        table.push(3879924228311360810000);
        table.push(4010315466897183390000);
        table.push(4145088717630532970000);
        table.push(4284391245240768280000);
        table.push(4428375263530820180000);
        table.push(4577198101698953770000);
        table.push(4731022376250046190000);
        table.push(4890016168684226850000);
        table.push(5054353209157035560000);
        table.push(5224213066311783450000);
        table.push(5399781343491542420000);
        table.push(5581249881545161590000);
        table.push(5768816968448913440000);
        table.push(5962687555972820090000);
        table.push(6163073483628409100000);
        table.push(6370193710142600580000);
        table.push(6584274552710656450000);
        table.push(6805549934289618220000);
        table.push(7034261639202447910000);
        table.push(7270659577332166550000);
        table.push(7515002057194671620000);
        table.push(7767556068188615790000);
        table.push(8028597572330757370000);
        table.push(8298411805795557410000);
        table.push(8577293590588510880000);
        table.push(8865547656693773630000);
        table.push(9163488975048089380000);
        table.push(9471443101704854970000);
        table.push(9789746533564384110000);
        table.push(10118747076059072500000);
        table.push(10458804223195228600000);
        table.push(10810289550366834100000);
        table.push(11173587120370458900000);
        table.push(11549093903064974000000);
        table.push(11937220209134620900000);
        table.push(12338390138429401400000);
        table.push(12753042043372685900000);
        table.push(13181629007942394300000);
        table.push(13624619342749130300000);
        table.push(14082497096752229700000);
        table.push(14555762586172869400000);
        table.push(15044932941182170300000);
        table.push(15550542670961655800000);
        table.push(16073144247753494600000);
        table.push(16613308710538715200000);
        table.push(17171626289003018000000);
        table.push(17748707048471987500000);
    }

    function fillPriceNodes3(uint256[] storage table) public {
        require(
            table[table.length - 1] < 18345181556520411900000,
            "fillPriceNodes3 initialized"
        );
        table.push(18345181556520411900000);
        table.push(18961701571984106700000);
        table.push(19598940757127115000000);
        table.push(20257595413742456400000);
        table.push(20938385243990756400000);
        table.push(21642054136808106000000);
        table.push(22369370980742455200000);
        table.push(23121130504106708000000);
        table.push(23898154143366547500000);
        table.push(24701290940711860400000);
        table.push(25531418471792529100000);
        table.push(26389443804632307700000);
        table.push(27276304490768581900000);
        table.push(28192969589701007700000);
        table.push(29140440727768433500000);
        table.push(30119753192611124600000);
        table.push(31131977064414190600000);
        table.push(32178218385168310200000);
        table.push(33259620367225387900000);
        table.push(34377364642469710500000);
        table.push(35532672553469556900000);
        table.push(36726806488020082600000);
        table.push(37961071258535714700000);
        table.push(39236815527799296200000);
        table.push(40555433282625878000000);
        table.push(41918365357051409000000);
        table.push(43327101006710684900000);
        table.push(44783179536124862800000);
        table.push(46288191980676648900000);
        table.push(47843782845111029500000);
        table.push(49451651900461181700000);
        table.push(51113556041363035200000);
        table.push(52831311205787946800000);
        table.push(54606794359291150300000);
        table.push(56441945545944141100000);
        table.push(58338770008192018300000);
        table.push(60299340377952123400000);
        table.push(62325798941348150400000);
        table.push(64420359979554376500000);
        table.push(66585312188307812300000);
        table.push(68823021178732041900000);
        table.push(71135932062205361600000);
        table.push(73526572122097668300000);
        table.push(75997553575295459800000);
        table.push(78551576426532429900000);
    }

    function fillSupplyNodes0(uint256[] storage table) public {
        require(table.length == 0, "fillSupplyNodes0 initialized");
        table.push(0);
        table.push(1000000000000000000000000);
        table.push(1010000000000000000000000);
        table.push(1020100000000000000000000);
        table.push(1030301000000000000000000);
        table.push(1040604010000000000000000);
        table.push(1051010050100000000000000);
        table.push(1061520150601000000000000);
        table.push(1072135352107010000000000);
        table.push(1082856705628080100000000);
        table.push(1093685272684360900000000);
        table.push(1104622125411204510000000);
        table.push(1115668346665316560000000);
        table.push(1126825030131969730000000);
        table.push(1138093280433289430000000);
        table.push(1149474213237622320000000);
        table.push(1160968955369998540000000);
        table.push(1172578644923698530000000);
        table.push(1184304431372935520000000);
        table.push(1196147475686664880000000);
        table.push(1208108950443531530000000);
        table.push(1220190039947966850000000);
        table.push(1232391940347446520000000);
        table.push(1244715859750920990000000);
        table.push(1257163018348430200000000);
        table.push(1269734648531914500000000);
        table.push(1282431995017233650000000);
        table.push(1295256314967405990000000);
        table.push(1308208878117080050000000);
        table.push(1321290966898250850000000);
        table.push(1334503876567233360000000);
        table.push(1347848915332905690000000);
        table.push(1361327404486234750000000);
        table.push(1374940678531097100000000);
        table.push(1388690085316408070000000);
        table.push(1402576986169572150000000);
        table.push(1416602756031267870000000);
        table.push(1430768783591580550000000);
        table.push(1445076471427496360000000);
        table.push(1459527236141771320000000);
        table.push(1474122508503189030000000);
        table.push(1488863733588220920000000);
        table.push(1503752370924103130000000);
        table.push(1518789894633344160000000);
        table.push(1533977793579677600000000);
        table.push(1549317571515474380000000);
        table.push(1564810747230629120000000);
        table.push(1580458854702935410000000);
        table.push(1596263443249964760000000);
        table.push(1612226077682464410000000);
        table.push(1628348338459289050000000);
        table.push(1644631821843881940000000);
        table.push(1661078140062320760000000);
        table.push(1677688921462943970000000);
        table.push(1694465810677573410000000);
        table.push(1711410468784349140000000);
        table.push(1728524573472192630000000);
        table.push(1745809819206914560000000);
        table.push(1763267917398983710000000);
        table.push(1780900596572973550000000);
        table.push(1798709602538703290000000);
        table.push(1816696698564090320000000);
        table.push(1834863665549731220000000);
        table.push(1853212302205228530000000);
        table.push(1871744425227280820000000);
        table.push(1890461869479553630000000);
        table.push(1909366488174349170000000);
        table.push(1928460153056092660000000);
        table.push(1947744754586653590000000);
        table.push(1967222202132520130000000);
        table.push(1986894424153845330000000);
        table.push(2000000000000000000000000);
        table.push(2006763368395383780000000);
        table.push(2026831002079337620000000);
        table.push(2047099312100131000000000);
        table.push(2067570305221132310000000);
        table.push(2088246008273343630000000);
        table.push(2109128468356077070000000);
        table.push(2130219753039637840000000);
        table.push(2151521950570034220000000);
        table.push(2173037170075734560000000);
        table.push(2194767541776491910000000);
        table.push(2216715217194256830000000);
        table.push(2238882369366199400000000);
        table.push(2261271193059861390000000);
        table.push(2283883904990460000000000);
        table.push(2306722744040364600000000);
        table.push(2329789971480768250000000);
        table.push(2353087871195575930000000);
        table.push(2376618749907531690000000);
        table.push(2400384937406607010000000);
        table.push(2424388786780673080000000);
        table.push(2448632674648479810000000);
        table.push(2464047377378012230000000);
        table.push(2473119001394964610000000);
        table.push(2497850191408914260000000);
        table.push(2522828693323003400000000);
        table.push(2548056980256233430000000);
        table.push(2573537550058795760000000);
        table.push(2599272925559383720000000);
    }

    function fillSupplyNodes1(uint256[] storage table) public {
        require(
            table[table.length - 1] < 2625265654814977560000000,
            "fillSupplyNodes1 initialized"
        );
        table.push(2625265654814977560000000);
        table.push(2651518311363127340000000);
        table.push(2678033494476758610000000);
        table.push(2704813829421526200000000);
        table.push(2731861967715741460000000);
        table.push(2759180587392898870000000);
        table.push(2786772393266827860000000);
        table.push(2814640117199496140000000);
        table.push(2842786518371491100000000);
        table.push(2871214383555206010000000);
        table.push(2899926527390758070000000);
        table.push(2928925792664665650000000);
        table.push(2958215050591312310000000);
        table.push(2987797201097225430000000);
        table.push(3017675173108197680000000);
        table.push(3047851924839279660000000);
        table.push(3078330444087672460000000);
        table.push(3109113748528549180000000);
        table.push(3140204886013834670000000);
        table.push(3171606934873973020000000);
        table.push(3203323004222712750000000);
        table.push(3235356234264939880000000);
        table.push(3267709796607589280000000);
        table.push(3300386894573665170000000);
        table.push(3333390763519401820000000);
        table.push(3366724671154595840000000);
        table.push(3400391917866141800000000);
        table.push(3434395837044803220000000);
        table.push(3468739795415251250000000);
        table.push(3503427193369403760000000);
        table.push(3538461465303097800000000);
        table.push(3573846079956128780000000);
        table.push(3609584540755690070000000);
        table.push(3645680386163246970000000);
        table.push(3682137190024879440000000);
        table.push(3718958561925128230000000);
        table.push(3756148147544379510000000);
        table.push(3793709629019823310000000);
        table.push(3831646725310021540000000);
        table.push(3869963192563121760000000);
        table.push(3908662824488752980000000);
        table.push(3947749452733640510000000);
        table.push(3987226947260976920000000);
        table.push(4027099216733586690000000);
        table.push(4067370208900922560000000);
        table.push(4108043910989931790000000);
        table.push(4149124350099831110000000);
        table.push(4190615593600829420000000);
        table.push(4232521749536837710000000);
        table.push(4274846967032206090000000);
        table.push(4317595436702528150000000);
        table.push(4360771391069553430000000);
        table.push(4404379104980248960000000);
        table.push(4448422896030051450000000);
        table.push(4492907124990351960000000);
        table.push(4537836196240255480000000);
        table.push(4583214558202658030000000);
        table.push(4629046703784684610000000);
        table.push(4675337170822531460000000);
        table.push(4722090542530756770000000);
        table.push(4769311447956064340000000);
        table.push(4817004562435624980000000);
        table.push(4865174608059981230000000);
        table.push(4913826354140581040000000);
        table.push(4962964617681986850000000);
        table.push(5012594263858806720000000);
        table.push(5062720206497394790000000);
        table.push(5113347408562368740000000);
        table.push(5164480882647992430000000);
        table.push(5216125691474472350000000);
        table.push(5268286948389217070000000);
        table.push(5320969817873109240000000);
        table.push(5374179516051840330000000);
        table.push(5427921311212358730000000);
        table.push(5482200524324482320000000);
        table.push(5537022529567727140000000);
        table.push(5592392754863404410000000);
        table.push(5648316682412038450000000);
        table.push(5704799849236158830000000);
        table.push(5761847847728520420000000);
        table.push(5819466326205805620000000);
        table.push(5877660989467863680000000);
        table.push(5936437599362542320000000);
        table.push(5995801975356167740000000);
        table.push(6055759995109729420000000);
        table.push(6116317595060826710000000);
        table.push(6177480771011434980000000);
        table.push(6239255578721549330000000);
        table.push(6301648134508764820000000);
        table.push(6364664615853852470000000);
        table.push(6428311262012390990000000);
        table.push(6492594374632514900000000);
        table.push(6557520318378840050000000);
        table.push(6623095521562628450000000);
        table.push(6689326476778254730000000);
        table.push(6756219741546037280000000);
        table.push(6823781938961497650000000);
        table.push(6892019758351112630000000);
        table.push(6960939955934623760000000);
        table.push(7030549355493970000000000);
    }

    function fillSupplyNodes2(uint256[] storage table) public {
        require(
            table[table.length - 1] < 7100854849048909700000000,
            "fillSupplyNodes2 initialized"
        );
        table.push(7100854849048909700000000);
        table.push(7171863397539398800000000);
        table.push(7243582031514792790000000);
        table.push(7316017851829940720000000);
        table.push(7389178030348240130000000);
        table.push(7463069810651722530000000);
        table.push(7537700508758239760000000);
        table.push(7613077513845822160000000);
        table.push(7689208288984280380000000);
        table.push(7766100371874123180000000);
        table.push(7843761375592864410000000);
        table.push(7922198989348793050000000);
        table.push(8001420979242280980000000);
        table.push(8081435189034703790000000);
        table.push(8162249540925050830000000);
        table.push(8243872036334301340000000);
        table.push(8326310756697644350000000);
        table.push(8409573864264620790000000);
        table.push(8493669602907267000000000);
        table.push(8578606298936339670000000);
        table.push(8664392361925703070000000);
        table.push(8751036285544960100000000);
        table.push(8838546648400409700000000);
        table.push(8926932114884413800000000);
        table.push(9016201436033257940000000);
        table.push(9106363450393590520000000);
        table.push(9197427084897526430000000);
        table.push(9289401355746501690000000);
        table.push(9382295369303966710000000);
        table.push(9476118322997006380000000);
        table.push(9570879506226976440000000);
        table.push(9666588301289246200000000);
        table.push(9763254184302138660000000);
        table.push(9860886726145160050000000);
        table.push(9959495593406611650000000);
        table.push(10059090549340677800000000);
        table.push(10159681454834084600000000);
        table.push(10261278269382425400000000);
        table.push(10363891052076249700000000);
        table.push(10467529962597012200000000);
        table.push(10572205262222982300000000);
        table.push(10677927314845212100000000);
        table.push(10784706587993664200000000);
        table.push(10892553653873600800000000);
        table.push(11001479190412336800000000);
        table.push(11111493982316460200000000);
        table.push(11222608922139624800000000);
        table.push(11334835011361021000000000);
        table.push(11448183361474631200000000);
        table.push(11562665195089377500000000);
        table.push(11678291847040271300000000);
        table.push(11795074765510674000000000);
        table.push(11913025513165780700000000);
        table.push(12032155768297438500000000);
        table.push(12152477325980412900000000);
        table.push(12274002099240217000000000);
        table.push(12396742120232619200000000);
        table.push(12520709541434945400000000);
        table.push(12645916636849294900000000);
        table.push(12772375803217787800000000);
        table.push(12900099561249965700000000);
        table.push(13029100556862465400000000);
        table.push(13159391562431090100000000);
        table.push(13290985478055401000000000);
        table.push(13423895332835955000000000);
        table.push(13558134286164314600000000);
        table.push(13693715629025957700000000);
        table.push(13830652785316217300000000);
        table.push(13968959313169379500000000);
        table.push(14108648906301073300000000);
        table.push(14249735395364084000000000);
        table.push(14392232749317724800000000);
        table.push(14536155076810902000000000);
        table.push(14681516627579011000000000);
        table.push(14828331793854801100000000);
        table.push(14976615111793349100000000);
        table.push(15126381262911282600000000);
        table.push(15277645075540395400000000);
        table.push(15430421526295799400000000);
        table.push(15584725741558757400000000);
        table.push(15740572998974345000000000);
        table.push(15897978728964088500000000);
        table.push(16056958516253729400000000);
        table.push(16217528101416266700000000);
        table.push(16379703382430429400000000);
        table.push(16543500416254733700000000);
        table.push(16708935420417281000000000);
        table.push(16876024774621453800000000);
        table.push(17044785022367668300000000);
        table.push(17215232872591345000000000);
        table.push(17387385201317258500000000);
        table.push(17561259053330431100000000);
        table.push(17736871643863735400000000);
        table.push(17914240360302372800000000);
        table.push(18093382763905396500000000);
        table.push(18274316591544450500000000);
        table.push(18457059757459895000000000);
        table.push(18641630355034494000000000);
        table.push(18828046658584838900000000);
        table.push(19016327125170687300000000);
    }

    function fillSupplyNodes3(uint256[] storage table) public {
        require(
            table[table.length - 1] < 19206490396422394200000000,
            "fillSupplyNodes3 initialized"
        );
        table.push(19206490396422394200000000);
        table.push(19398555300386618100000000);
        table.push(19592540853390484300000000);
        table.push(19788466261924389100000000);
        table.push(19986350924543633000000000);
        table.push(20186214433789069300000000);
        table.push(20388076578126960000000000);
        table.push(20591957343908229600000000);
        table.push(20797876917347311900000000);
        table.push(21005855686520785000000000);
        table.push(21215914243385992900000000);
        table.push(21428073385819852800000000);
        table.push(21642354119678051300000000);
        table.push(21858777660874831800000000);
        table.push(22077365437483580100000000);
        table.push(22298139091858415900000000);
        table.push(22521120482777000100000000);
        table.push(22746331687604770100000000);
        table.push(22973795004480817800000000);
        table.push(23203532954525626000000000);
        table.push(23435568284070882300000000);
        table.push(23669923966911591100000000);
        table.push(23906623206580707000000000);
        table.push(24145689438646514100000000);
        table.push(24387146333032979200000000);
        table.push(24631017796363309000000000);
        table.push(24877327974326942100000000);
        table.push(25126101254070211500000000);
        table.push(25377362266610913600000000);
        table.push(25631135889277022700000000);
        table.push(25887447248169792900000000);
        table.push(26146321720651490800000000);
        table.push(26407784937858005700000000);
        table.push(26671862787236585800000000);
        table.push(26938581415108951700000000);
        table.push(27207967229260041200000000);
        table.push(27480046901552641600000000);
        table.push(27754847370568168000000000);
        table.push(28032395844273849700000000);
        table.push(28312719802716588200000000);
        table.push(28595847000743754100000000);
        table.push(28881805470751191600000000);
        table.push(29170623525458703500000000);
        table.push(29462329760713290500000000);
        table.push(29756953058320423400000000);
    }
}
// solhint-enable

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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