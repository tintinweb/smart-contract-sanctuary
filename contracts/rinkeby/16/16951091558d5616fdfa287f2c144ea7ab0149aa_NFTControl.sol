/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]



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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]



pragma solidity ^0.8.0;


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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]



pragma solidity ^0.8.0;





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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File contracts/IWinterElfNFT.sol



pragma solidity ^0.8.0;
interface IWinterElfNFT is IERC721Upgradeable, IAccessControlUpgradeable {
    event NFTMinted(address to, string tokenURI);

    function getAllOwners() external view returns (address[] memory);
    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external;
    function burn(uint256 _tokenId) external;
}


// File contracts/ISpaceYetiNFT.sol



pragma solidity ^0.8.0;
interface ISpaceYetiNFT is IERC721Upgradeable, IAccessControlUpgradeable {
    event NFTMinted(address to, string tokenURI);

    function getAllOwners() external view returns (address[] memory);
    function mint(address _to, string memory _tokenURI) external;
    function burn(uint256 _tokenId) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]



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


// File contracts/IRewardToken.sol



pragma solidity ^0.8.0;
interface IRewardToken is IERC20Upgradeable {
	function mint(address account, uint256 amount) external;
	function burn(address account, uint256 amount) external;
}


// File contracts/IRandomNumberConsumer.sol


pragma solidity ^0.8.0;

interface IRandomNumberConsumer {
    function getRandomNumber() external returns (bytes32);
    function getResult() external view returns(uint256);
}


// File contracts/NFTControl.sol



pragma solidity ^0.8.0;
contract NFTControl is AccessControlUpgradeable {
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant EXCLUSIVE_ROLE = keccak256("EXCLUSIVE_ROLE");
    address public rewardToken;                         // Reward token address
    address public elfContract;                         // Winter Elf Nft Contract 
    address public yetiContract;                        // Space Yeti Contract
    uint256 public totalSupply;                         // Total supply of NFTs
    uint256 public currentSupply;                       // Current supply of NFTs
    uint256 public DECIMAL;                             // Decimals for reward token
    mapping(address => uint256) public winners;         // List of winners in present 2
    address[] public betters;                           // List of betters for present 3
    mapping(address => uint256[2]) public bettersToNFTs;// Betters to NFTs
    uint256 public winnersCount;                        // Count of present 2 winners
    address public finalWinner;                         // Address of present 3 winner 
    // mapping(address => Stake[]) public OwnerToTokens;   // Owners to owned Elves
    uint256 public BETTING_PERIOD;                      // Duration of betting
    uint256 public initTime;                            // First bet time
    address public randomContract;

    // struct Stake {
    //     uint256 tokenId;
    //     uint256 locktime;
    // }

    event NFTMinted(address to, string tokenURI);

    /**
     * @dev Checks for overflow of the total supply.
     */
    modifier totalSupplyCheck() {
        require(
            currentSupply <= totalSupply,
            "The maximum number of tokens has already been minted"
        );
        _;
    }

    /**
     * @dev Checks the balance of the reward token for the current contract.
     */
    modifier rewardTokenCheck() {
        require(
            IERC20Upgradeable(rewardToken).balanceOf(address(this)) >= 1000,
            "The contract does not have much tokens for providing this operation"
        );
        _;
    }

    /**
     * @dev Initializes the contract by setting a `_name`, `_symbol` and a `_rewardToken`.
     * @param _rewardToken   Already deployed Reward token's address (ERC20)
     * @param _elfContract   Already deployed Elves token's address (ERC721)
     * @param _yetiContract  Already deployed Space Yetis token's address (ERC721)
     * @param _bettingPeriod Duration of betting counteed after first bet 
     */
    function initialize(address _rewardToken, address _elfContract, address _yetiContract, uint256 _bettingPeriod, address _randomContract)
        public
        initializer
    {
        // Initialization of AccessControl
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WHITELISTED_ROLE, _msgSender());
        _setupRole(EXCLUSIVE_ROLE, _msgSender());

        // Initialization of variables
        rewardToken = _rewardToken;
        elfContract = _elfContract;
        yetiContract = _yetiContract;
        totalSupply = 8894;
        currentSupply = 0;
        DECIMAL = 2;
        winnersCount = 0;
        BETTING_PERIOD = _bettingPeriod;
        randomContract = _randomContract;
    }

    /**
     * @dev Withdraws `_amount` of ethers from contract to `_to`
     * @param _to The destination address
     * @param _amount The amount of ethers
     */
    function withdrawEthers(address _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(this).balance >= _amount, "Insufficient funds");

        (bool success, ) = payable(address(_to)).call{value: _amount}('');
        require(success);
    }

    /**
     * @dev Withdraws `_amount` of reward tokens from contract to `_to`
     * @param _to The destination address
     * @param _amount Te amount of tokens
     */
    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            IERC20Upgradeable(_token).balanceOf(address(this)) >= _amount,
            "Insufficient funds"
        );

        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    /**
     * @dev Sale without Minter Role requirement
     * @param to The address at which the NFT will be minted
     * @param tokenURI Already generated token's IPFS URI
     */
    function publicSale(address to, string memory tokenURI)
        external
        payable
        totalSupplyCheck
        rewardTokenCheck
    {
        require(
            IWinterElfNFT(elfContract).balanceOf(to) < 10,
            "You have maximum amount of NFTs"
        );
        require(msg.value == 0.06 ether, "Send the correct amount of ether");

        // Mints Elf to `to`
        currentSupply += 1;
        IWinterElfNFT(elfContract).mint(to, currentSupply, tokenURI);
        emit NFTMinted(to, tokenURI);
    }

    /**
     * @dev Pre-sale with `WHITELISTED_ROLE` requirement
     * @param to The address at which the NFT will be minted
     * @param tokenURI Already generated token's IPFS URI
     */
    function preSale(address to, string memory tokenURI)
        external
        payable
        onlyRole(WHITELISTED_ROLE)
        totalSupplyCheck
        rewardTokenCheck
    {
        if (hasRole(EXCLUSIVE_ROLE, to)) {
            require(
                IWinterElfNFT(elfContract).balanceOf(to) < 4,
                "You have maximum amount of NFTs"
            );
        } else {
            require(
                IWinterElfNFT(elfContract).balanceOf(to) < 3,
                "You have maximum amount of NFTs"
            );
        }
        require(msg.value == 0.055 ether, "Send the correct amount of ether");

        // Mints Elf to `to`
        currentSupply += 1;
        IWinterElfNFT(elfContract).mint(to, currentSupply, tokenURI);
        emit NFTMinted(to, tokenURI);
    }

    /**
     * @dev Mints Space Yeti
     * Msg.sender must have at least 2 Elves to call the function 
     * @param _tokenId1 First NFT
     * @param _tokenId2 Second NFT
     */
    function mintGenesis(uint256 _tokenId1, uint256 _tokenId2) external {
        require(
            IWinterElfNFT(elfContract).ownerOf(_tokenId1) == _msgSender() &&
                IWinterElfNFT(elfContract).ownerOf(_tokenId2) == _msgSender(),
            "msg.sender is not the owner of the tokens"
        );
        require(ISpaceYetiNFT(yetiContract).balanceOf(_msgSender()) == 0, "The token has already been minted");
        require(IRewardToken(rewardToken).balanceOf(_msgSender()) >= 500 * (10 ** DECIMAL), "msg.sender balance should be above 50000 tokens to run this function");
        
        ISpaceYetiNFT(yetiContract).mint(_msgSender(), '');
    }

    /**
     * @dev Claims reward ether (1 eth / 0.2 eth)
     * Msg.sender must approve `_tokenId1` & `_tokenId2` to run this function
     * @param _tokenId1 Burns Elf with Id `_tokenId1`
     * @param _tokenId2 Burns Elf with Id `_tokenId2`
     */
    function claimPresent2(uint256 _tokenId1, uint256 _tokenId2) external {
        require(
            IWinterElfNFT(elfContract).getApproved(_tokenId1) == address(this) &&
                IWinterElfNFT(elfContract).getApproved(_tokenId2) == address(this),
            "Approve those tokens before calling the function"
        );
        require(IRewardToken(rewardToken).allowance(_msgSender(), address(this)) >= 800 * (10 ** DECIMAL), "msg.sender should approve 800 tokens to run this function");
        IRandomNumberConsumer(randomContract).getRandomNumber();
        if (IRandomNumberConsumer(randomContract).getResult() % 10 == 0) {
            payable(_msgSender()).transfer(1 ether);
            winners[_msgSender()] = winnersCount + 1;
            winnersCount++;
        } else {
            payable(_msgSender()).transfer(0.2 ether);
        }

        IWinterElfNFT(elfContract).burn(_tokenId1);
        IWinterElfNFT(elfContract).burn(_tokenId2);
        IRewardToken(rewardToken).burn(_msgSender(), 800 * (10 ** DECIMAL));
    }

    /**
     * @dev Bets NFTs and RewardTokens for Present 3
     * Msg.sender must approve `_tokenId1` & `_tokenId2` to run this function
     * @param _tokenId1 Burns Elf with Id `_tokenId1`
     * @param _tokenId2 Burns Elf with Id `_tokenId2`
     */
    function betForPresent3(uint256 _tokenId1, uint256 _tokenId2) external {
        require(winners[_msgSender()] != 0, "msg.sender is not a winner of present 2");
        IWinterElfNFT(elfContract).transferFrom(_msgSender(), address(this), _tokenId1);
        IWinterElfNFT(elfContract).transferFrom(_msgSender(), address(this), _tokenId2);
        IRewardToken(rewardToken).transferFrom(_msgSender(), address(this), 800 * (10 ** DECIMAL));
    
        betters.push(_msgSender());
        bettersToNFTs[_msgSender()] = [_tokenId1, _tokenId2];
        initTime = block.timestamp;
    }

    /**
     * @dev Claims the betted NFTs 
     */
    function claimBetted() external {
        require(finalWinner != address(0x0) && finalWinner != _msgSender());
        require(bettersToNFTs[_msgSender()][0] != 0);

        IWinterElfNFT(elfContract).transferFrom(address(this), _msgSender(), bettersToNFTs[_msgSender()][0]);
        IWinterElfNFT(elfContract).transferFrom(address(this), _msgSender(), bettersToNFTs[_msgSender()][1]);
        IRewardToken(rewardToken).transfer(_msgSender(), 800 * (10 ** DECIMAL));
        delete bettersToNFTs[_msgSender()];
    }

    /**
     * @dev Selects the winner from `betters` list (only for DEFAULT_ADMIN_ROLE)
     */
    function selectPresent3Winner() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(block.timestamp >= initTime + BETTING_PERIOD, "");
        require(finalWinner == address(0x0), "The winner has already been announced");
       
        IRandomNumberConsumer(randomContract).getRandomNumber();
        finalWinner = betters[(IRandomNumberConsumer(randomContract).getResult() % betters.length)];
    }

    /**
     * @dev `finalWinner` calls the function and claims Present 3
     */
    function claimPresent3() external {
        require(_msgSender() == finalWinner, "msg.sender is not the winner");
        // Reward present 3
        IWinterElfNFT(elfContract).burn(bettersToNFTs[_msgSender()][0]);
        IWinterElfNFT(elfContract).burn(bettersToNFTs[_msgSender()][1]);
        IRewardToken(rewardToken).burn(address(this), 800);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}