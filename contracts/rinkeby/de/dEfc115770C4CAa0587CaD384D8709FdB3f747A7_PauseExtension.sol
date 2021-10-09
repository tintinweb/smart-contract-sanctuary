pragma solidity ^0.8.0;

import {IERC20Extension, TransferData} from "../IERC20Extension.sol";
import {Roles} from "../../roles/Roles.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract PauseExtension is IERC20Extension {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    event Paused(address account);
    event Unpaused(address account);

    bytes32 constant IS_PAUSED_SLOT = keccak256("ext.pause");
    bytes32 constant PAUSER_ROLE = keccak256("roles.pausers");

    modifier onlyPauser() {
        require(Roles.roleStorage(PAUSER_ROLE).has(msg.sender), "Only pausers can use this function");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!isPaused(), "Token must not be paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(isPaused(), "Token must be paused");
        _;
    }

    function isPaused() public returns (bool) {
        return StorageSlot.getBooleanSlot(IS_PAUSED_SLOT).value;
    }

    function initalize() external override {
        StorageSlot.getBooleanSlot(IS_PAUSED_SLOT).value = false;
        Roles.roleStorage(PAUSER_ROLE).add(msg.sender);
    }

    function pause() external onlyPauser whenNotPaused {
        StorageSlot.getBooleanSlot(IS_PAUSED_SLOT).value = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyPauser whenPaused {
        StorageSlot.getBooleanSlot(IS_PAUSED_SLOT).value = false;
        emit Unpaused(msg.sender);
    }

    function addPauser(address account) external onlyPauser {
        _addPauser(account);
    }

    function removePauser(address account) external onlyPauser {
        _removePauser(account);
    }

    function renouncePauser() external {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        Roles.roleStorage(PAUSER_ROLE).add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        Roles.roleStorage(PAUSER_ROLE).remove(account);
        emit PauserRemoved(account);
    }

    function validateTransfer(TransferData memory data) external override view returns (bool) {
        bool isPaused = StorageSlot.getBooleanSlot(IS_PAUSED_SLOT).value;

        require(!isPaused, "Transfers are paused");

        return true;
    }

    function onTransferExecuted(TransferData memory data) external override returns (bool) {
        bool isPaused = StorageSlot.getBooleanSlot(IS_PAUSED_SLOT).value;

        require(!isPaused, "Transfers are paused");

        return true;
    }

    function externalFunctions() external override pure returns (bytes4[] memory) {
        bytes4[] memory funcSigs = new bytes4[](5);
        
        funcSigs[0] = PauseExtension.addPauser.selector;
        funcSigs[1] = PauseExtension.removePauser.selector;
        funcSigs[2] = PauseExtension.renouncePauser.selector;
        funcSigs[3] = PauseExtension.pause.selector;
        funcSigs[4] = PauseExtension.unpause.selector;

        return funcSigs;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return interfaceId == type(IERC20Extension).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function roleStorage(bytes32 _rolePosition) internal pure returns (Role storage ds) {
        bytes32 position = _rolePosition;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
* @dev Verify if a token transfer can be executed or not, on the validator's perspective.
* @param token Token address that is executing this extension. If extensions are being called via delegatecall then address(this) == token
* @param payload The full payload of the initial transaction.
* @param partition Name of the partition (left empty for ERC20 transfer).
* @param operator Address which triggered the balance decrease (through transfer or redemption).
* @param from Token holder.
* @param to Token recipient for a transfer and 0x for a redemption.
* @param value Number of tokens the token holder balance is decreased by.
* @param data Extra information (if any).
* @param operatorData Extra information, attached by the operator (if any).
*/
struct TransferData {
    address token;
    bytes payload;
    bytes32 partition;
    address operator;
    address from;
    address to;
    uint value;
    bytes data;
    bytes operatorData;
}

interface IERC20Extension is IERC165 {

    function initalize() external;

    function validateTransfer(TransferData memory data) external view returns (bool);

    function onTransferExecuted(TransferData memory data) external returns (bool);

    function externalFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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