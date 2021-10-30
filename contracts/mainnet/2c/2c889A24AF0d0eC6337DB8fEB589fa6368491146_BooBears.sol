// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ERC721Essentials} from "ERC721Essentials.sol";
import {ERC721EssentialsWithdrawable} from "ERC721EssentialsWithdrawable.sol";
import {ERC721ClaimFromContracts} from "ERC721ClaimFromContracts.sol";
import {BaseErrorCodes} from "ErrorCodes.sol";

//=====================================================================================================================
/// 😈 OOGA BOOGA SPOOKY BEARA 😈
//=====================================================================================================================

contract BooBears is ERC721EssentialsWithdrawable, ERC721ClaimFromContracts {
    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    mapping(address => bool) internal hasMinted;
    string private constant kErrOnlyMintOne = "Only allowed to Mint 1 Boo Bear"; /* solhint-disable-line */

    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256[] memory uintArgs_,
        bool publicMintingEnabled_,
        address[] memory contractAddrs_,
        uint16 maxForPurchase_,
        uint16 maxForClaim_
    )
        ERC721EssentialsWithdrawable(name_, symbol_, baseURI_, uintArgs_, publicMintingEnabled_)
        ERC721ClaimFromContracts(contractAddrs_, maxForPurchase_, maxForClaim_)
    {
        return;
    }

    //=================================================================================================================
    /// Minting Functionality
    //=================================================================================================================

    /**
     * @dev Public function that mints a specified number of ERC721 tokens.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function mint(uint16 numMint)
        public
        payable
        virtual
        override(ERC721ClaimFromContracts, ERC721Essentials)
        limitToOneMint
    {
        super.mint(numMint); // ERC721ClaimFromContracts.sol, ERC721Essentials.sol
    }

    /**
     * @dev Modifier to limit the number of mints to one per user.
     */
    modifier limitToOneMint() {
        require(!hasMinted[_msgSender()], kErrOnlyMintOne);
        hasMinted[_msgSender()] = true;
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {AccessControl} from "AccessControl.sol";
import {ERC721} from "ERC721.sol";
import {ERC721Enumerable} from "ERC721Enumerable.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";

/* Internal Imports */
import {BaseErrorCodes} from "ErrorCodes.sol";
import {ERC721Metadata} from "ERC721Metadata.sol";
import {Modifiers} from "Modifiers.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

/**
 * @dev Essential state and behavior that every ERC721 contract should have.
 */
contract ERC721Essentials is AccessControl, ERC721Enumerable, ERC721Metadata, Modifiers, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    /* Internal */
    uint16 internal _maxSupply;
    uint16 internal _maxMintPerTx;
    uint256 internal _priceInWei;
    bool internal _publicMintingEnabled;

    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256[] memory uintArgs_,
        bool publicMintingEnabled_
    ) ERC721(name_, symbol_) {
        _maxSupply = uint16(uintArgs_[0]);
        _priceInWei = uintArgs_[1];
        _maxMintPerTx = uint16(uintArgs_[2]);
        _publicMintingEnabled = publicMintingEnabled_;

        _setBaseURI(baseURI_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //=================================================================================================================
    /// Minting Functionality
    //=================================================================================================================

    /**
     * @dev Public function that mints a specified number of ERC721 tokens.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function mint(uint16 numMint)
        public
        payable
        virtual
        nonReentrant
        whenPublicMintingOpen
        costs(numMint, _priceInWei)
    {
        _mint(numMint);
    }

    /**
     * @dev Internal function that mints a specified number of ERC721 tokens. Contains
     * safety checks related to supply.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function _mint(uint16 numMint) internal virtual _supplySafetyChecks(numMint) {
        _safeMintTokens(_msgSender(), numMint);
    }

    /**
     * @dev Public function that mints tokens to a set of wallet addresses. Each address has a specified number of
     * ERC721 tokens minted to it. Contains basic safety checks to ensure supply of tokens stays within limits.
     * This function is non-payable and thus is only callable by contract admins. The function is a naïve way to perform an
     * an airdrop and is pretty rough on gas. That being said, for small drops, the added surprise of users just "finding it"
     * in their wallet is kind of cool. Unless you don't mind eating a ton of gas, a merkle tree redemption method is recommended
     * for anything large scale.
     * @param addrs address[] memory: List of addresses to which tokens will be sent to. Setting this to an empty list will mint
     * the tokens to _msgSender().
     * @param numMint uint16: The number of tokens that are going to be minted to each address.
     */
    function mintAirDrop(address[] memory addrs, uint16 numMint)
        public
        virtual
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (addrs.length == 0) {
            // If no specified addresses, mint to the caller.
            address[] memory temp = new address[](1);
            temp[0] = _msgSender();
            _mintAirDrop(temp, numMint);
        } else {
            _mintAirDrop(addrs, numMint);
        }
    }

    /**
     * @dev Internal function that mints tokens to set a of wallet addresses.
     * @param addrs address[] memory: List of addresses to which tokens will be sent to. Setting this to an empty list will mint
     * the tokens to _msgSender().
     * @param numMint uint16: The number of tokens that are going to be minted to each address.
     */
    function _mintAirDrop(address[] memory addrs, uint16 numMint)
        internal
        virtual
        _supplySafetyChecks(uint16(addrs.length * numMint))
    {
        for (uint16 i = 0; i < addrs.length; i += 1) {
            _safeMintTokens(addrs[i], numMint);
        }
    }

    /**
     * @dev Internal function that mints a specified number of ERC721 tokens to a specific address.
     * contains NO SAFETY CHECKS and thus should be wrapped in a function that does.
     * @param to_ address: The address to mint the tokens to.
     * @param numMint uint16: The number of tokens to be minted.
     */
    function _safeMintTokens(address to_, uint16 numMint) internal {
        for (uint16 i = 0; i < numMint; i += 1) {
            _safeMint(to_, totalSupply() + 1);
        }
    }

    //=================================================================================================================
    /// Accessors
    //=================================================================================================================

    /**
     * @dev returns minting access.
     */
    function publicMintingEnabled() public view virtual returns (bool) {
        return _publicMintingEnabled;
    }

    /**
     * @dev Public function that returns the maximum number of ERC721 tokens that can exist under this contract.
     */
    function maxSupply() public view virtual returns (uint16) {
        return _maxSupply;
    }

    /**
     * @dev Public function that returns the price for the mint.
     */
    function priceInWei() public view virtual returns (uint256) {
        return _priceInWei;
    }

    /**
     * @dev Public function that returns the max number of mints per sent transaction.
     */
    function maxMintPerTx() public view virtual returns (uint16) {
        return _maxMintPerTx;
    }

    //=================================================================================================================
    /// Mutators
    //=================================================================================================================

    /**
     * @dev Set minting access. Only callable by contract admins.
     */
    function setPublicMinting(bool publicMintingEnabled_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _publicMintingEnabled = publicMintingEnabled_;
    }

    /**
     * @dev Public function that sets the maximum number of ERC721 tokens that can exist under this contract.
     * @param newSupply uint16: The new maximum number of tokens.
     */
    function setSupply(uint16 newSupply) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxSupply = newSupply;
    }

    /**
     * @dev Public function that sets the price for the mint. Only callable by contract admins.
     * @param newPrice uint256: The new price.
     */
    function setPriceInWei(uint256 newPrice) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _priceInWei = newPrice;
    }

    /**
     * @dev Public function that sets the max number of mints per sent transaction. Only callable by contract admins.
     * @param newMaxMintPerTx uint256: The new max.
     */
    function setMaxMintPerTx(uint16 newMaxMintPerTx) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxMintPerTx = newMaxMintPerTx;
    }

    //=================================================================================================================
    /// Metadata URI
    //=================================================================================================================

    /**
     * @dev Public function that sets the baseURI of this ERC721 token.
     * @param newBaseURI string memory: The baseURI of the contract.
     */
    function setBaseURI(string memory newBaseURI) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev Internal function that retrieves the baseURI of this ERC721 token.
     * @return string memory: The baseURI of the contract.
     */
    function _baseURI() internal view virtual override(ERC721, ERC721Metadata) returns (string memory) {
        return super._baseURI();
    }

    /**
     * @dev Public function that retrieves the tokenURI of a ERC721 token. For more info please view the
     * ERC721 spec: https://eips.ethereum.org/EIPS/eip-721.
     * @param tokenId uint256: The tokenId to be queried.
     * @return string memory: The tokenURI of the queried token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Metadata) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    //=================================================================================================================
    /// Required Overrides
    //=================================================================================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //=================================================================================================================
    /// Useful Checks & Modifiers
    //=================================================================================================================

    /**
     * @dev A function to verify that the token supply will is in a valid state and will remain in a valid
     * state after the creation of a set number of tokens.
     * @param numMint uint16: The number of tokens requested to be created.
     */
    function _requireBasicSupplySafetyChecks(uint16 numMint) internal view {
        require(totalSupply() < _maxSupply, kErrSoldOut);
        require(totalSupply() + numMint <= _maxSupply, kErrRequestTooLarge);
        require(
            (numMint > 0 && numMint <= _maxMintPerTx) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            kErrOutsideMintPerTransaction
        );
    }

    /**
     * See {ERC721BasicMint-_requireBasicSupplySafetyChecks}
     */
    modifier _supplySafetyChecks(uint16 numMint) {
        _requireBasicSupplySafetyChecks(numMint);
        _;
    }

    /**
     * @dev A modifier to guard the minting functions thus allowing minting to be enabled & disabled.
     */
    modifier whenPublicMintingOpen() {
        require(_publicMintingEnabled || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), kErrMintingIsDisabled);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* TODO: Refactor error codes from string -> bytes32 */

/* For ERC721Essentials.sol */
abstract contract BaseErrorCodes {
    /* solhint-disable const-name-snakecase */
    string internal constant kErrInsufficientFunds = "Insufficient Funds";
    string internal constant kErrSoldOut = "Sold Out";
    string internal constant kErrTokenDoesNotExist = "nonexistent token";
    string internal constant kErrRequestTooLarge = "Requested too many Tokens";
    string internal constant kErrOutsideMintPerTransaction = "Outside mint per tx range";
    string internal constant kErrMintingIsDisabled = "Minting is disabled";
    string internal constant kErrIncorrectConfirmationCode = "Bad confirmation";
    string internal constant kErrExternalCallFailed = "Failure calling external contract";
    /* solhint-enable const-name-snakecase */
}

/* For ERC721PresaleMintWithOffchainAllowlist.sol */
abstract contract AllowlistErrorCodes {
    /* solhint-disable const-name-snakecase */
    string internal constant kErrPublicMintSoldout = "Remaining Tokens are restricted";
    string internal constant kErrRestrictedRequestTooLarge = "Requested too many restricted Tokens";
    /* solhint-enable const-name-snakecase */
}

/* For ERC721ClaimFromContracts.sol */
abstract contract ClaimFromContractErrorCodes {
    /* solhint-disable const-name-snakecase */
    string internal constant kErrAlreadyClaimed = "Already redeemed your new tokens";
    string internal constant kErrOutOfPurchasable = "Remaining mints reserved for claims";
    string internal constant kErrOutOfClaimable = "Remaining mints reserved for purchases";
    string internal constant kErrClaimingNotEnabled = "Claiming is currently disabled";
    /* solhint-enable const-name-snakecase */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {ERC721} from "ERC721.sol";
import {Strings} from "Strings.sol";

/* Internal Imports */
import {BaseErrorCodes} from "ErrorCodes.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

/**
 * @dev Lightweight version of OpenZeppelin's ERC721URIStorage.sol
 */

abstract contract ERC721Metadata is BaseErrorCodes, ERC721 {
    using Strings for uint256;

    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    /* Private */
    string private baseURI_;

    /**
     * @dev Retrieves tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), kErrTokenDoesNotExist);
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev External function that retrieves the baseURI of this ERC721 token. Useful for 
     confirming the baseURI is correct and/or unit testing.
     * @return string memory: The baseURI of the contract.
     */
    function baseURI() external view virtual returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Retrieve `baseURI_`
     * @return string memory: The baseURI of the contract.
     */
    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI_;
    }

    /**
     * @dev Set `baseURI_`
     *
     */
    function _setBaseURI(string memory newBaseURI) internal virtual {
        baseURI_ = newBaseURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {BaseErrorCodes} from "ErrorCodes.sol";

abstract contract Modifiers is BaseErrorCodes {
    /**
     * @dev A modifier that verifies that the correct amount of Ether has been recieved prior to executing
     * the function is it applied to.
     */

    modifier requireTrue(bool x, string memory errMsg) {
        require(x, errMsg);
        _;
    }

    modifier requireFalse(bool x, string memory errMsg) {
        require(!x, errMsg);
        _;
    }

    modifier costs(uint16 num, uint256 price) {
        require(msg.value >= price * num, kErrInsufficientFunds);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {AccessControl} from "AccessControl.sol";
import {ERC721} from "ERC721.sol";
import {ERC721Enumerable} from "ERC721Enumerable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";

/* Internal Imports */
import {ERC721Essentials} from "ERC721Essentials.sol";
import {Constants} from "Constants.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

contract ERC721EssentialsWithdrawable is ERC721Essentials {
    using Strings for string;

    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256[] memory uintArgs_,
        bool publicMintingEnabled_
    ) ERC721Essentials(name_, symbol_, baseURI_, uintArgs_, publicMintingEnabled_) {
        return;
    }

    //=================================================================================================================
    /// Finance
    //=================================================================================================================

    /**
     * @dev Public function that pulls a set amount of Ether from the contract. Only callable by contract admins.
     * @param amount uint256: The amount of wei to withdraw from the contract.
     */
    function withdraw(uint256 amount) public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Public function that pulls the entire balance of Ether from the contract. Only callable by contract admins.
     */
    function withdrawAll() public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Constants {
    /* Constants */
    uint256 private constant _WEI_PER_ETH = 10**18;
    uint16 private constant _IPFS_URI_LENGTH = 54; // len("ipfs://") == 7, len(hash) == 46, len("/") == 1, sum => 54

    function getWeiPerEth() internal pure returns (uint256) {
        return _WEI_PER_ETH;
    }

    function getIpfsUriLength() internal pure returns (uint16) {
        return _IPFS_URI_LENGTH;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {AccessControl} from "AccessControl.sol";
import {Address} from "Address.sol";
import {ERC721} from "ERC721.sol";
import {ERC721Enumerable} from "ERC721Enumerable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

/* Internal Imports */
import {ERC721Essentials} from "ERC721Essentials.sol";
import {ClaimFromContractErrorCodes} from "ErrorCodes.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

/**
 * @dev Lightweight package to allow users to mint token(s) for free if they own tokens in
 * another set of contracts.
 */

abstract contract ERC721ClaimFromContracts is ERC721Essentials, ClaimFromContractErrorCodes {
    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    /* Internal */
    address[] internal _claimContractAddrs;
    bool internal _claimingEnabled;
    mapping(address => bool) internal _userHasClaimed;
    uint16 internal _numPurchased = 0;
    uint16 internal _numClaimed = 0;

    // TODO: Future we can calculate maxForClaim by reading other contracts totalSupply()
    uint16 internal _maxForPurchase;
    uint16 internal _maxForClaim;

    /* Private */
    string private constant kBalanceOfAbi = "balanceOf(address)"; /* solhint-disable-line */

    constructor(
        address[] memory contractAddrs_,
        uint16 maxForPurchase_,
        uint16 maxForClaim_
    ) {
        setContractAddrsForClaim(contractAddrs_);
        setMaxForPurchase(maxForPurchase_);
        setMaxForClaim(maxForClaim_);
        setClaimingEnabled(false);
    }

    //=================================================================================================================
    /// Claiming Functionality
    //=================================================================================================================

    /**
     * @dev Public function that claims new tokens based on owning tokens from other contracts.
     */
    function claim() public nonReentrant whenClaimingEnabled {
        _claim();
    }

    /**
     * @dev An internal function to claim a certain number of new ERC721 tokens based on ownership from a set of previous
     * contracts. This function calls the balanceof(address) function in each contract to determine the number of tokens a user holds
     * and then mints them the corresponding number of tokens in this contract. Contains NO safety checks, as it should be
     * implied that if all eligible users run the claim function token supply numbers for this contract stay valid.
     * You can add safety checks to an external / public wrapping of this function if you wish to do so.
     */
    function _claim() internal {
        require(!_userHasClaimed[_msgSender()], kErrAlreadyClaimed);
        bytes memory payload = abi.encodeWithSignature(kBalanceOfAbi, address(_msgSender()));
        uint16 length = uint16(_claimContractAddrs.length);
        uint16 sum = 0;
        _userHasClaimed[_msgSender()] = true;
        for (uint16 i = 0; i < length; i += 1) {
            bytes memory result = Address.functionStaticCall(_claimContractAddrs[i], payload); /* solhint-disable-line */
            sum += uint16(abi.decode(result, (uint256)));
        }
        _numClaimed += sum;
        require(_numClaimed <= _maxForClaim, kErrOutOfClaimable);
        _safeMintTokens(_msgSender(), uint16(sum));
    }

    /**
     * @dev Public function that mints a specified number of ERC721 tokens.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function mint(uint16 numMint) public payable virtual override(ERC721Essentials) limitAndTrackPurchases(numMint) {
        return super.mint(numMint); // ERC721Essentials.sol
    }

    //=================================================================================================================
    /// Mutators
    //=================================================================================================================

    /**
     * @dev A public function to set what contracts will be queired during the execution of _claim.
     * @param addrs address[] memory: The list of addresses to be queried
     */
    function setContractAddrsForClaim(address[] memory addrs) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _claimContractAddrs = addrs;
    }

    /**
     * @dev A public function to set the number of tokens that can be minted via a payment.
     * @param maxForPurchase_ uint16: The max number that can be payable minted.
     */
    function setMaxForPurchase(uint16 maxForPurchase_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxForPurchase = maxForPurchase_;
    }

    /**
     * @dev A public function to set the number of tokens that can be minted via a claim.
     * @param maxForClaim_ uint16: The max number that can be claim minted.
     */
    function setMaxForClaim(uint16 maxForClaim_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxForClaim = maxForClaim_;
    }
    
    /**
     * @dev A public function to enable/disable claiming.
     */
    function setClaimingEnabled(bool claiming_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _claimingEnabled = claiming_;
    }

    //=================================================================================================================
    /// Accessors
    //=================================================================================================================

    function contractAddrsForClaim() public view returns (address[] memory) {
        return _claimContractAddrs;
    }

    //=================================================================================================================
    /// Useful Checks & Modifiers
    //=================================================================================================================

    /**
     * @dev Modifier to limit the number of mints for purchase.
     */
    modifier limitAndTrackPurchases(uint16 numMint) {
        _numPurchased += numMint;
        require(_numPurchased <= _maxForPurchase, kErrOutOfPurchasable);
        _;
    }
    
    /**
     * @dev Modifier to ensure claiming is enabled
     */
    modifier whenClaimingEnabled() {
        require(_claimingEnabled, kErrClaimingNotEnabled);
        _;
    }
}