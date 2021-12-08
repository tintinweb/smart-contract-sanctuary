// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title GremlinsAirdrops
/// @author jpegmint.xyz

import "@jpegmint/contracts/gremlins/GremlinsAirdrop.sol";

/**
████████╗███████╗███████╗████████╗ █████╗ ██╗██████╗ ██████╗ ██████╗  ██████╗ ██████╗ 
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
   ██║   █████╗  ███████╗   ██║   ███████║██║██████╔╝██║  ██║██████╔╝██║   ██║██████╔╝
   ██║   ██╔══╝  ╚════██║   ██║   ██╔══██║██║██╔══██╗██║  ██║██╔══██╗██║   ██║██╔═══╝ 
   ██║   ███████╗███████║   ██║   ██║  ██║██║██║  ██║██████╔╝██║  ██║╚██████╔╝██║     
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     
*/                                                                                      
contract TestAirdrop is GremlinsAirdrop {
    constructor(address logic) GremlinsAirdrop(logic, "Test Airdrop", "TEST") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author jpegmint.xyz

import "./GremlinsERC721Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/*
 ██████╗ ██████╗ ███████╗███╗   ███╗██╗     ██╗███╗   ██╗███████╗     █████╗ ██╗██████╗ ██████╗ ██████╗  ██████╗ ██████╗ 
██╔════╝ ██╔══██╗██╔════╝████╗ ████║██║     ██║████╗  ██║██╔════╝    ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
██║  ███╗██████╔╝█████╗  ██╔████╔██║██║     ██║██╔██╗ ██║███████╗    ███████║██║██████╔╝██║  ██║██████╔╝██║   ██║██████╔╝
██║   ██║██╔══██╗██╔══╝  ██║╚██╔╝██║██║     ██║██║╚██╗██║╚════██║    ██╔══██║██║██╔══██╗██║  ██║██╔══██╗██║   ██║██╔═══╝ 
╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║███████╗██║██║ ╚████║███████║    ██║  ██║██║██║  ██║██████╔╝██║  ██║╚██████╔╝██║     
 ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝    ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     
*/
contract GremlinsAirdrop is GremlinsERC721Proxy {

    // Base Roles
    bytes32 private constant _AIRDROP_ADMIN_ROLE = keccak256("AIRDROP_ADMIN_ROLE");

    // Max planned supply
    uint16 public constant TOKEN_MAX_SUPPLY = 100;

    // App storage structure
    struct AppStorage {
        uint16 totalSupply;
        uint16[TOKEN_MAX_SUPPLY] tokenIdTracker;
    }

    //  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗ ██████╗████████╗ ██████╗ ██████╗ 
    // ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
    // ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ██████╔╝██║   ██║██║        ██║   ██║   ██║██████╔╝
    // ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██╗██║   ██║██║        ██║   ██║   ██║██╔══██╗
    // ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║╚██████╔╝╚██████╗   ██║   ╚██████╔╝██║  ██║
    //  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

    // Constructor
    constructor(address baseContract, string memory name_, string memory symbol_)
    GremlinsERC721Proxy(baseContract, name_, symbol_) {}


    // ███████╗████████╗ ██████╗ ██████╗  █████╗  ██████╗ ███████╗
    // ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗██╔════╝ ██╔════╝
    // ███████╗   ██║   ██║   ██║██████╔╝███████║██║  ███╗█████╗  
    // ╚════██║   ██║   ██║   ██║██╔══██╗██╔══██║██║   ██║██╔══╝  
    // ███████║   ██║   ╚██████╔╝██║  ██║██║  ██║╚██████╔╝███████╗
    // ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

    /**
     * @dev Gets app storage struct from defined storage slot.
     */
    function _appStorage() internal pure returns(AppStorage storage app) {
        bytes32 storagePosition = bytes32(uint256(keccak256("app.storage")) - 1);
        assembly {
            app.slot := storagePosition
        }
    }

    // █████╗ ██╗██████╗ ██████╗ ██████╗  ██████╗ ██████╗ 
    // ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
    // ███████║██║██████╔╝██║  ██║██████╔╝██║   ██║██████╔╝
    // ██╔══██║██║██╔══██╗██║  ██║██╔══██╗██║   ██║██╔═══╝ 
    // ██║  ██║██║██║  ██║██████╔╝██║  ██║╚██████╔╝██║     
    // ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     

    /**
     * @dev Mints tokens to the specified wallets.
     */
    function airdrop(address[] calldata wallets, uint8[] calldata indexes) public {
        require(IAccessControl(_implementation()).hasRole(_AIRDROP_ADMIN_ROLE, msg.sender), "!R");
        require(wallets.length == indexes.length, "?");
        require(availableSupply() >= wallets.length, "#");

        for (uint8 i = 0; i < wallets.length; i++) {
            _airdrop(wallets[i], _generateTokenId(indexes[i]));
        }
    }

    /**
     * @dev Process airdrop by delegating to base contract.
     */
    function _airdrop(address to, uint256 tokenId) internal {
        _appStorage().totalSupply += 1;
        
        bytes memory data = abi.encodeWithSignature("mint(address,uint256,string)", to, tokenId, "");
        Address.functionDelegateCall(_implementation(), data);
    }

    /**
     * @dev Generate random tokenIds using Meebits random ID strategy, with ability to override.
     */
    function _generateTokenId(uint256 index) private returns (uint256) {

        uint256 remainingQty = availableSupply();

        // Generate a randomIndex or use given specId as index.
        require(index <= remainingQty, "ID");
        uint256 randomIndex = (index != 0 ? index - 1 : _generateRandomNum(remainingQty) % remainingQty);

        // If array value exists at random index, use value, otherwise use generated index as tokenId.
        AppStorage storage app = _appStorage();
        uint256 existingValue = app.tokenIdTracker[randomIndex];
        uint256 tokenId = existingValue != 0 ? existingValue : randomIndex;

        // Keep track of seen indexes for black magic.
        uint16 endIndex = uint16(remainingQty - 1);
        uint16 endValue = app.tokenIdTracker[endIndex];
        app.tokenIdTracker[randomIndex] = endValue != 0 ? endValue : endIndex;

        return tokenId + 1; // Start tokens at #1
    }

    /**
     * @dev Generate pseudorandom number via various transaction properties.
     */
    function _generateRandomNum(uint256 seed) internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, tx.gasprice, block.timestamp, seed)));
    }


    // ███████╗██╗   ██╗██████╗ ██████╗ ██╗  ██╗   ██╗
    // ██╔════╝██║   ██║██╔══██╗██╔══██╗██║  ╚██╗ ██╔╝
    // ███████╗██║   ██║██████╔╝██████╔╝██║   ╚████╔╝ 
    // ╚════██║██║   ██║██╔═══╝ ██╔═══╝ ██║    ╚██╔╝  
    // ███████║╚██████╔╝██║     ██║     ███████╗██║   
    // ╚══════╝ ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝   

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _appStorage().totalSupply;
    }

    /**
     * @dev Helper function to pair with total supply.
     */
    function availableSupply() public view returns (uint256) {
        return TOKEN_MAX_SUPPLY - totalSupply();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author jpegmint.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/*
 ██████╗ ██████╗ ███████╗███╗   ███╗██╗     ██╗███╗   ██╗███████╗    ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
██╔════╝ ██╔══██╗██╔════╝████╗ ████║██║     ██║████╗  ██║██╔════╝    ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
██║  ███╗██████╔╝█████╗  ██╔████╔██║██║     ██║██╔██╗ ██║███████╗    ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ 
██║   ██║██╔══██╗██╔══╝  ██║╚██╔╝██║██║     ██║██║╚██╗██║╚════██║    ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  
╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║███████╗██║██║ ╚████║███████║    ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   
 ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   
*/                                                                                               
abstract contract GremlinsERC721Proxy is Proxy {

    /// Storage slot with the address of the gremlins contract
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;


    //  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗ ██████╗████████╗ ██████╗ ██████╗ 
    // ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
    // ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ██████╔╝██║   ██║██║        ██║   ██║   ██║██████╔╝
    // ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██╗██║   ██║██║        ██║   ██║   ██║██╔══██╗
    // ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║╚██████╔╝╚██████╗   ██║   ╚██████╔╝██║  ██║
    //  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

    /// Constructor
    constructor(address logic, string memory name_, string memory symbol_) {
        
        // Store logic address
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = logic;

        // Initialize contract
        bytes memory data = abi.encodeWithSignature("initialize(string,string)", name_, symbol_);
        Address.functionDelegateCall(_implementation(), data);
    }


    // ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
    // ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
    // ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ 
    // ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  
    // ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   
    // ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   

    /**
     * @dev Returns the stored implementation address.
     */
    function _implementation() internal view virtual override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Check if function is supported via beforeFallback hook.
     */
    function _beforeFallback() internal virtual override {
        require(supportsFunction(msg.sig), "?");
        super._beforeFallback();
    }

    /**
     * @dev Returns whether function selector is in known set of proxied functions.
     */
    function supportsFunction(bytes4 functionId) public pure returns(bool) {
        return
            // ERC721 Functions
            functionId == 0x70a08231 || // _FUNCTION_ID_BALANCE_OF = bytes4(keccak256("balanceOf(address)"))
            functionId == 0x6352211e || // _FUNCTION_ID_OWNER_OF = bytes4(keccak256("ownerOf(uint256)"))
            functionId == 0x42842e0e || // _FUNCTION_ID_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"))
            functionId == 0xb88d4fde || // _FUNCTION_ID_SAFE_TRANSFER_FROM_DATA = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"))
            functionId == 0x23b872dd || // _FUNCTION_ID_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"))
            functionId == 0x095ea7b3 || // _FUNCTION_ID_APPROVE = bytes4(keccak256("approve(address,uint256)"))
            functionId == 0xa22cb465 || // _FUNCTION_ID_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"))
            functionId == 0x081812fc || // _FUNCTION_ID_GET_APPROVED = bytes4(keccak256("getApproved(uint256)"))
            functionId == 0xe985e9c5 || // _FUNCTION_ID_IS_APPROVED_FOR_ALL = bytes4(keccak256("isApprovedForAll(address,address)"))

            // ERC721Metadata Functions
            functionId == 0x06fdde03 || // _FUNCTION_ID_NAME = bytes4(keccak256("name()"))
            functionId == 0x95d89b41 || // _FUNCTION_ID_SYMBOL = bytes4(keccak256("symbol()"))
            functionId == 0xc87b56dd || // _FUNCTION_ID_TOKEN_URI = bytes4(keccak256("tokenURI(uint256)"))
            functionId == 0x162094c4 || // _FUNCTION_ID_SET_TOKEN_URI = bytes4(keccak256("setTokenURI(uint256,string)"))
            functionId == 0x6c0360eb || // _FUNCTION_ID_BASE_URI = bytes4(keccak256("baseURI()"))
            functionId == 0x55f804b3 || // _FUNCTION_ID_SET_BASE_URI = bytes4(keccak256("setBaseURI(string)"))

            // ERC721Burnable Function
            functionId == 0x42966c68 || // _FUNCTION_ID_BURN = bytes4(keccak256("burn(uint256)"))

            // Ownable Functions
            functionId == 0x8da5cb5b || // _FUNCTION_ID_OWNER = bytes4(keccak256("owner()"))
            functionId == 0x715018a6 || // _FUNCTION_ID_RENOUNCE_OWNERSHIP = bytes4(keccak256("renounceOwnership()"))
            functionId == 0xf2fde38b || // _FUNCTION_ID_TRANSFER_OWNERSHIP = bytes4(keccak256("transferOwnership(address)"))

            // Royalties
            functionId == 0xbb3bafd6 || // _FUNCTION_ID_GET_ROYALTIES = bytes4(keccak256("getRoyalties(uint256)"))
            functionId == 0x2a55205a || // _FUNCTION_ID_ROYALTY_INFO = bytes4(keccak256("royaltyInfo(uint256,uint256)"))
            functionId == 0x8c7ea24b || // _FUNCTION_ID_SET_ROYALTIES = bytes4(keccak256("setRoyalties(address,uint256)"))

            // ERC165 Functions
            functionId == 0x01ffc9a7    // _FUNCTION_ID_SUPPORTS_INTERFACE = bytes4(keccak256("supportsInterface(bytes4)"))
        ;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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