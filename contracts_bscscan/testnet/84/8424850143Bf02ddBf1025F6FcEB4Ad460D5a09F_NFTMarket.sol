// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IRainiNft1155 is IERC1155 {
  struct TokenVars {
    uint128 cardId;
    uint32 level;
    uint32 number; // to assign a numbering to NFTs
    bytes1 mintedContractChar;
  }

  function tokenVars(uint256 _tokenId) external view returns (TokenVars memory);
}

contract NFTMarket is AccessControl, ReentrancyGuard {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  struct Listing {
    uint96 itemId;
    uint32 amount;
    uint32 expiryDate;
    uint16 cardLevel;
    bool isOffer;
    bool usesCardId;
    bool exists;
    address contractAddress;
    address owner;
    uint256 unitPrice;
  }

  uint256 public maxListingId = 0;

  uint256 public feesCollected;

  mapping(address => bool) public approvedTokenContracts;  
  
  mapping(uint256 => Listing) public listings;

  uint256 feeBasisPoints;

  address public feeRecipient;

  event ItemListed(uint96 listingId, uint96 itemId, uint16 cardLevel, bool usesCardId, address contractAddress, uint32 amount, uint256 unitPrice, bool isOffer, uint32 expiryDate);

  event TokenSold(uint96 tokenId, address contractAddress, uint32 amount, uint256 unitPrice, address seller, address buyer, uint256 listingId);

  event PriceChanged(uint256 listingId, uint256 unitPrice);

  event ListingRemoved(uint256 listingId);

  constructor(address _feeRecipient){
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(BURNER_ROLE, _msgSender());
    feeRecipient = _feeRecipient;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NFTMarket: caller is not an admin");
    _;
  }

  function addTokenContract(address _tokenContract) 
    external onlyOwner {
      approvedTokenContracts[_tokenContract] = true;
  }

  function setFeeBasisPoints(uint256 _feeBasisPoints) 
    external onlyOwner {
      feeBasisPoints = _feeBasisPoints;
  }

  function setFeeRecipient(address _feeRecipient) 
    external onlyOwner {
      feeRecipient = _feeRecipient;
  }

  struct listItemsData {
    uint256 maxListingId;
    uint256 escrowAmount;
  }

  //List a number of items for sale at a fixed price.
  function listItems(uint96[] memory _id, uint16[] memory _cardLevel, bool[] memory _usesCardId, address[] memory _contractAddress, uint32[] memory _amount, uint256[] memory _unitPrice, bool _isOffer, uint32 _expiryDate) 
    external payable nonReentrant {
      listItemsData memory _locals = listItemsData({
        maxListingId: maxListingId,
        escrowAmount: 0
      });

      for (uint256 i = 0; i < _id.length; i++) {
        require((approvedTokenContracts[_contractAddress[i]]), "NFTMarket: invalid token contract");
        IRainiNft1155 tokenContract = IRainiNft1155(_contractAddress[i]);

        require(_isOffer || tokenContract.isApprovedForAll(_msgSender(), address(this)), "NFTMarket: Not approved for all");
        require(_isOffer || tokenContract.balanceOf(_msgSender(), _id[i]) >=  _amount[i], "NFTMarket: Not enough balance");

        _locals.maxListingId++;
        listings[_locals.maxListingId] = Listing({
          itemId: _id[i],
          usesCardId: _isOffer && _usesCardId[i],
          cardLevel: _isOffer && _usesCardId[i] ? _cardLevel[i] : 0,
          contractAddress: _contractAddress[i],
          amount: _amount[i],
          unitPrice: _unitPrice[i],
          expiryDate: _expiryDate,
          isOffer: _isOffer,
          exists: true,
          owner: _msgSender()
        });

        emit ItemListed(uint96(_locals.maxListingId), _id[i], _isOffer && _usesCardId[i] ? _cardLevel[i] : 0, _isOffer && _usesCardId[i], _contractAddress[i], _amount[i], _unitPrice[i], _isOffer,  _expiryDate);

        if (_isOffer) {
          _locals.escrowAmount += _unitPrice[i] * _amount[i];
        }
      }

      maxListingId = _locals.maxListingId;

      require(_locals.escrowAmount <= msg.value, "Not enough ETH");

      // refund excess Eth
      (bool success, ) = _msgSender().call{ value: msg.value - _locals.escrowAmount }(""); 
      require(success, "transfer failed");
  }

  function unlistItems(uint256[] memory _listingId) 
    external nonReentrant {
      uint256 refundAmount = 0;
      for (uint256 i = 0; i < _listingId.length; i++) {
        Listing memory _listing = listings[_listingId[i]];

        require(_listing.owner == _msgSender(), "Not listing owner");
        delete listings[_listingId[i]];
        emit ListingRemoved(_listingId[i]);
        if (_listing.isOffer) {
          // refund escrow
          refundAmount += _listing.amount * _listing.unitPrice;
        }
      }
      (bool success, ) = _msgSender().call{ value: refundAmount}(""); 
      require(success, "transfer failed");
  }

  function repriceItems(uint256[] memory _listingId, uint256[] memory _unitPrice) 
    external payable nonReentrant {
      int256 escrowDiff = 0;

      for (uint256 i = 0; i < _listingId.length; i++) {
        Listing memory _listing = listings[_listingId[i]];

        require(_listing.owner == _msgSender(), "Not listing owner");

        if (_unitPrice[i] != 0) {
          if (_listing.isOffer) {
            escrowDiff += int256(_unitPrice[i]) - int256(_listing.unitPrice);
          }
          listings[_listingId[i]].unitPrice = _unitPrice[i];
          emit PriceChanged(_listingId[i], _unitPrice[i]);
        }
      }

      require(escrowDiff < 0 || uint256(escrowDiff) <= msg.value, "Not enough ETH");

      uint256 refund = (escrowDiff > 0)  ? msg.value - uint256(escrowDiff) : msg.value + uint256(-escrowDiff);
      (bool success, ) = _msgSender().call{ value: refund }(""); 
      require(success, "transfer failed");
  }

  struct BuySellData {
    uint256 totalCost;
    uint256 totalIncome;
    uint256 price;
    uint256 fee;
    uint256 feesCollected;
    uint256 count;
    address owner;
    uint256 i;
    uint256 j;
    bool success;
  }

  // price is required because items can be repriced
  function buySell(uint256[] memory _listingId, uint256[][] memory _tokenIds, uint32[] memory _amount, uint256[] memory _unitPrice, bool _allOrNothing) 
    external payable nonReentrant {
      BuySellData memory _locals = BuySellData({
        totalCost: 0,
        totalIncome: 0,
        price: 0,
        fee: 0,
        owner: address(0),
        feesCollected: 0,
        count: 0,
        i: 0,
        j: 0,
        success: false
      });

      Listing memory _listing;

      for (_locals.i = 0; _locals.i < _listingId.length; _locals.i++) {
        _listing = listings[_listingId[_locals.i]];
        if (_listing.exists 
              && (_listing.unitPrice == _unitPrice[_locals.i]) 
              && _listing.amount >= _amount[_locals.i]
              && (_listing.expiryDate == 0 || block.timestamp < _listing.expiryDate)) {
          IRainiNft1155 tokenContract = IRainiNft1155(_listing.contractAddress);
          _locals.owner = _listing.isOffer ? _msgSender() : _listing.owner;

          _locals.success = false;
          if (tokenContract.isApprovedForAll(_locals.owner, address(this))) {
            if (_listing.usesCardId) {
              _locals.count = 0;
              for (_locals.j = 0; _locals.j < _tokenIds.length; _locals.j++) {
                IRainiNft1155.TokenVars memory _tokenVars =  tokenContract.tokenVars(_tokenIds[_locals.i][_locals.j]);
                if (_tokenVars.cardId == _listing.itemId && _tokenVars.level == _listing.cardLevel 
                      && tokenContract.balanceOf(_locals.owner, _listing.itemId) >= 1) {
                    _locals.count++;
                  } else {
                    require(false, "Bad token");
                    break;
                  }
              }
              _locals.success = (_locals.count == _amount[_locals.i]);
              require(_locals.success, "Not enough tokens");
            } else {
              _locals.success = (tokenContract.balanceOf(_locals.owner, _listing.itemId) >=  _amount[_locals.i]);
              require(_locals.success, "Not enough tokens");
            }
          } else {
            require(!_allOrNothing, "Transaction failed - seller not approved");
          }

          if (_locals.success) {
            if (_listing.amount == _amount[_locals.i]) {
              delete listings[_listingId[_locals.i]];
            } else {
              listings[_listingId[_locals.i]].amount -= _amount[_locals.i];
            }
            
            _locals.price = _listing.unitPrice * _amount[_locals.i];
            _locals.fee = _locals.price * feeBasisPoints / 10000;

            _locals.feesCollected += _locals.fee;

            if (!_listing.isOffer) {
              _locals.totalCost += _locals.price;
              require(_locals.totalCost <= msg.value + _locals.totalIncome, "Not enough ETH");
              tokenContract.safeTransferFrom(_listing.owner, _msgSender(), _listing.itemId, _amount[_locals.i], bytes('0x0'));
              emit TokenSold(_listing.itemId, address(tokenContract), _amount[_locals.i], _listing.unitPrice, _listing.owner, _msgSender(), _listingId[_locals.i]);
              // send Eth to seller
              (_locals.success, ) = _listing.owner.call{ value: _locals.totalCost - _locals.fee }("");
              require(_locals.success, "transfer failed");
            } else {
              _locals.totalIncome += _locals.price - _locals.fee;
              if (_listing.usesCardId) {
                for (_locals.j = 0; _locals.j < _tokenIds.length; _locals.j++) {
                  tokenContract.safeTransferFrom(_msgSender(), _listing.owner, _tokenIds[_locals.i][_locals.j], 1, bytes('0x0'));
                  emit TokenSold(uint96(_tokenIds[_locals.i][_locals.j]), address(tokenContract), 1, _listing.unitPrice, _msgSender(), _listing.owner, _listingId[_locals.i]);
                }
              } else {
                tokenContract.safeTransferFrom(_msgSender(), _listing.owner, _listing.itemId, _amount[_locals.i], bytes('0x0'));
                emit TokenSold(_listing.itemId, address(tokenContract), _amount[_locals.i], _listing.unitPrice, _msgSender(), _listing.owner, _listingId[_locals.i]);
              }
            }

          } else {
            // TODO delete listing
            require(!_allOrNothing, "Transaction failed");
          }
        } else {
          // TODO delete listing
          require(!_allOrNothing, "Transaction failed");
        }
      }

      (_locals.success, ) = feeRecipient.call{ value: _locals.feesCollected }(""); 
      require(_locals.success, "transfer failed");

      // Payout income and refund excess Eth
      (_locals.success, ) = _msgSender().call{ value: msg.value + _locals.totalIncome - _locals.totalCost }(""); 
      require(_locals.success, "transfer failed");

      
  }
}

