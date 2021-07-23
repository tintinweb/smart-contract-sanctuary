// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

/*
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

import "./IERC165.sol";

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

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title   BridgeManager contract
 * @dev     Registers ERC20, ERC721 and ERC1155 tokens to allow users swapping
 * them between Ethereum and PRIVI blockchains
 * @author  PRIVI
 **/
contract BridgeManager is AccessControl {
  bytes32 public constant REGISTER_ROLE = keccak256("REGISTER_ROLE");
  address private constant ZERO_ADDRESS =
    0x0000000000000000000000000000000000000000;

  // Structure to handle registered token data
  struct registeredToken {
    string name;
    string symbol;
    address deployedAddress;
  }

  // ERC20 token types
  registeredToken[] private erc20RegisteredArray;
  mapping(string => address) private contractAddressERC20;
  mapping(address => string) private symbolsERC20;

  // ERC721 token types
  registeredToken[] private erc721RegisteredArray;
  mapping(string => address) private contractAddressERC721;
  mapping(address => string) private symbolsERC721;

  // ERC1155 token types
  registeredToken[] private erc1155RegisteredArray;
  mapping(string => address) private contractAddressERC1155;
  mapping(address => string) private tokenURIsERC1155;

  // Events
  event RegisterERC20Token(string indexed name, address tokenAddress);
  event UnRegisterERC20Token(string indexed name);
  event RegisterERC721Token(string indexed name, address tokenAddress);
  event UnRegisterERC721Token(string indexed name);
  event RegisterERC1155Token(string indexed name, address tokenAddress);
  event UnRegisterERC1155Token(string indexed name);

  /**
   * @notice  Modifier to require 'tokenName' and 'tokenSymbol' are not empty
   * @param   tokenNameToCheck The token or symbol name to be checked
   * @dev     reverts if tokenNameToCheck is empty
   */
  modifier nameIsNotEmpty(string memory tokenNameToCheck) {
    bytes memory bytesTokenName = bytes(tokenNameToCheck);
    require(
      bytesTokenName.length != 0,
      "BridgeManager: token name and symbol can't be empty"
    );
    _;
  }

  /**
   * @notice Constructor to assign all roles to contract creator
   */
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(REGISTER_ROLE, _msgSender());
  }

  /**
   * @notice  Returns the contract address of a registered ERC20 token
   * @param   tokenSymbol The ERC20 token symbol (ticker)
   * @return  returnAddress The contract address of a registered ERC20 token
   */
  function getErc20AddressRegistered(string calldata tokenSymbol)
    external
    view
    returns (address returnAddress)
  {
    returnAddress = contractAddressERC20[tokenSymbol];
  }

  /**
   * @notice  Returns the symbol of a registered ERC20 token
   * @param   addr The address of ERC20 token
   * @return  returnSymbol The symbol of a registered ERC20 token
   */
  function getErc20SymbolRegistered(address addr)
    external
    view
    returns (string memory returnSymbol)
  {
    returnSymbol = symbolsERC20[addr];
  }

  /**
   * @notice  Returns an array of all registered ERC20 tokens
   */
  function getAllErc20Registered()
    external
    view
    returns (registeredToken[] memory)
  {
    return erc20RegisteredArray;
  }

  /**
   * @notice  Returns a count of all registered ERC20 tokens
   */
  function getAllErc20Count() external view returns (uint256) {
    return erc20RegisteredArray.length;
  }

  /**
   * @notice Returns the contract address of a registered ERC721 token
   */
  function getErc721AddressRegistered(string calldata tokenSymbol)
    external
    view
    returns (address returnAddress)
  {
    returnAddress = contractAddressERC721[tokenSymbol];
  }

  /**
   * @notice Returns the symbol of a registered ERC721 token
   */
  function getErc721SymbolRegistered(address addr)
    external
    view
    returns (string memory returnSymbol)
  {
    returnSymbol = symbolsERC721[addr];
  }

  /**
   * @notice Returns an array of all registered ERC721 tokens
   */
  function getAllErc721Registered()
    external
    view
    returns (registeredToken[] memory)
  {
    return erc721RegisteredArray;
  }

  /**
   * @notice Returns a count of all registered ERC721 tokens
   */
  function getAllErc721Count() external view returns (uint256) {
    return erc721RegisteredArray.length;
  }

  /**
   * @notice Returns the address of a registered ERC1155 token
   */
  function getErc1155AddressRegistered(string calldata tokenURI)
    external
    view
    returns (address returnAddress)
  {
    returnAddress = contractAddressERC1155[tokenURI];
  }

  /**
   * @notice Returns the token URI of a registered ERC1155 token
   */
  function getErc1155TokenURIRegistered(address addr)
    external
    view
    returns (string memory returnTokenURI)
  {
    returnTokenURI = tokenURIsERC1155[addr];
  }

  /**
   * @notice Returns an array of all registered ERC1155 tokens
   */
  function getAllErc1155Registered()
    external
    view
    returns (registeredToken[] memory)
  {
    return erc1155RegisteredArray;
  }

  /**
   * @notice Returns a count of all registered ERC1155 tokens
   */
  function getAllErc1155Count() external view returns (uint256) {
    return erc1155RegisteredArray.length;
  }

  /**
   * @notice  Registers the contract address of an ERC20 token
   * @dev     - Token can't be already registered
   *          - Length of token symbol can't be greater than 25 characters
   * @param   tokenName The name of the ERC20 token to be registered (e.g.: Uniswap)
   * @param   tokenSymbol The symbol of the ERC20 token to be registered (e.g.: UNI)
   * @param   tokenContractAddress The contract address of the ERC20 Token
   */
  function registerTokenERC20(
    string calldata tokenName,
    string calldata tokenSymbol,
    address tokenContractAddress
  ) external nameIsNotEmpty(tokenName) nameIsNotEmpty(tokenSymbol) {
    // TODO: Only Admin or Token Factories should be able to register tokens
    // require(hasRole(REGISTER_ROLE, _msgSender()),
    //     "BridgeManager: must have REGISTER_ROLE to register a token");
    require(
      contractAddressERC20[tokenSymbol] == ZERO_ADDRESS,
      "BridgeManager: token address is already registered"
    );
    require(
      bytes(symbolsERC20[tokenContractAddress]).length == 0,
      "BridgeManager: token symbol is already registered"
    );
    require(
      bytes(tokenSymbol).length < 25,
      "BridgeManager: token Symbol too long"
    );

    contractAddressERC20[tokenSymbol] = tokenContractAddress;
    symbolsERC20[tokenContractAddress] = tokenSymbol;

    registeredToken memory regToken;
    regToken.name = tokenName;
    regToken.symbol = tokenSymbol;
    regToken.deployedAddress = tokenContractAddress;
    erc20RegisteredArray.push(regToken);

    emit RegisterERC20Token(tokenSymbol, tokenContractAddress);
  }

  /**
   * @notice  Registers the contract address of an ERC721 Token
   * @dev     - Token can't be already registered
   *          - Length of token symbol can't be greater than 25 characters
   * @param   tokenName The name of the ERC721 token to be registered (e.g.: Uniswap)
   * @param   tokenSymbol The symbol of the ERC721 token to be registered (e.g.: UNI)
   * @param   tokenContractAddress The contract address of the ERC721 token
   */
  function registerTokenERC721(
    string calldata tokenName,
    string calldata tokenSymbol,
    address tokenContractAddress
  ) external nameIsNotEmpty(tokenName) nameIsNotEmpty(tokenSymbol) {
    // TODO: Only Admin or Token Factories should be able to register tokens
    // require(hasRole(REGISTER_ROLE, _msgSender()),
    //     "BridgeManager: must have REGISTER_ROLE to register a token");
    require(
      contractAddressERC721[tokenSymbol] == ZERO_ADDRESS,
      "BridgeManager: token address is already registered" //TODO: token symbol already registered
    );
    require(
      bytes(symbolsERC721[tokenContractAddress]).length == 0,
      "BridgeManager: token symbole is already registered"
    );
    require(
      bytes(tokenSymbol).length < 25,
      "BridgeManager: token Symbol too long"
    );

    contractAddressERC721[tokenSymbol] = tokenContractAddress;
    symbolsERC721[tokenContractAddress] = tokenSymbol;

    registeredToken memory regToken;
    regToken.name = tokenName;
    regToken.symbol = tokenSymbol;
    regToken.deployedAddress = tokenContractAddress;
    erc721RegisteredArray.push(regToken);

    emit RegisterERC721Token(tokenSymbol, tokenContractAddress);
  }

  /**
   * @notice  Registers the contract address of an ERC1155 Token
   * @dev     - Token can't be already registered
   * @param   tokenName The name of the ERC1155 token to be registered (e.g.: Kitty)
   * @param   tokenURI The URI of the ERC1155 token to be registered (e.g: ipfs://xx)
   * @param   tokenContractAddress The contract address of the ERC1155 token
   */
  function registerTokenERC1155(
    string calldata tokenName,
    string calldata tokenURI,
    address tokenContractAddress
  ) external nameIsNotEmpty(tokenURI) {
    // TODO: Only Admin or Token Factories should be able to register tokens
    // require(hasRole(REGISTER_ROLE, _msgSender()),
    //     "BridgeManager: must have REGISTER_ROLE to register a token");
    require(
      contractAddressERC1155[tokenURI] == ZERO_ADDRESS,
      "BridgeManager: token address is already registered"
    );

    require(
      bytes(tokenURIsERC1155[tokenContractAddress]).length == 0,
      "BridgeManager: token URI is already registered"
    );

    contractAddressERC1155[tokenURI] = tokenContractAddress;
    tokenURIsERC1155[tokenContractAddress] = tokenURI;

    registeredToken memory regToken;
    regToken.name = tokenName;
    regToken.symbol = tokenURI;
    regToken.deployedAddress = tokenContractAddress;
    erc1155RegisteredArray.push(regToken);

    emit RegisterERC1155Token(tokenURI, tokenContractAddress);
  }
}