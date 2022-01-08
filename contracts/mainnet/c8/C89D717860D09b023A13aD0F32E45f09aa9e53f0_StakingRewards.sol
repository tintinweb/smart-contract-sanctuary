// SPDX-License-Identifier: MIT
// solhint-disable
/*
  This is copied from OZ preset: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.0.0/contracts/presets/ERC721PresetMinterPauserAutoId.sol
  Alterations:
   * Make the counter public, so that we can use it in our custom mint function
   * Removed ERC721Burnable parent contract, but added our own custom burn function.
   * Removed original "mint" function, because we have a custom one.
   * Removed default initialization functions, because they set msg.sender as the owner, which
     we do not want, because we use a deployer account, which is separate from the protocol owner.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC721PresetMinterPauserAutoIdUpgradeSafe is
  Initializable,
  ContextUpgradeSafe,
  AccessControlUpgradeSafe,
  ERC721PausableUpgradeSafe
{
  using Counters for Counters.Counter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  Counters.Counter public _tokenIdTracker;

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public {
    require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public {
    require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721PausableUpgradeSafe) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  uint256[49] private __gap;
}

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
 */
abstract contract AccessControlUpgradeSafe is Initializable, ContextUpgradeSafe {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

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

pragma solidity ^0.6.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";
import "../../Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721UpgradeSafe is Initializable, ContextUpgradeSafe, ERC165UpgradeSafe, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;


    function __ERC721_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
    }

    function __ERC721_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);

    }


    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If a base URI is set (via {_setBaseURI}), it is added as a prefix to the
     * token's own URI (via {_setTokenURI}).
     *
     * If there is a base URI but no token URI, the token's ID will be used as
     * its URI when appending it to the base URI. This pattern for autogenerated
     * token URIs can lead to large gas savings.
     *
     * .Examples
     * |===
     * |`_setBaseURI()` |`_setTokenURI()` |`tokenURI()`
     * | ""
     * | ""
     * | ""
     * | ""
     * | "token.uri/123"
     * | "token.uri/123"
     * | "token.uri/"
     * | "123"
     * | "token.uri/123"
     * | "token.uri/"
     * | ""
     * | "token.uri/<tokenId>"
     * |===
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: If all token IDs share a prefix (for example, if your URIs look like
     * `https://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - when `from` is zero, `tokenId` will be minted for `to`.
     * - when `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

    uint256[41] private __gap;
}

pragma solidity ^0.6.0;

import "./ERC721.sol";
import "../../utils/Pausable.sol";
import "../../Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeSafe is Initializable, ERC721UpgradeSafe, PausableUpgradeSafe {
    function __ERC721Pausable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
    }

    function __ERC721Pausable_init_unchained() internal initializer {


    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

pragma solidity ^0.6.0;

import "./IERC165.sol";
import "../Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165UpgradeSafe is Initializable, IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;


    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {


        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);

    }


    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
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
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

import "../external/ERC721PresetMinterPauserAutoId.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/ISeniorPool.sol";
import "../protocol/core/GoldfinchConfig.sol";
import "../protocol/core/ConfigHelper.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";

import "../library/StakingRewardsVesting.sol";

contract StakingRewards is ERC721PresetMinterPauserAutoIdUpgradeSafe, ReentrancyGuardUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20withDec;
  using ConfigHelper for GoldfinchConfig;

  using StakingRewardsVesting for StakingRewardsVesting.Rewards;

  enum LockupPeriod {
    SixMonths,
    TwelveMonths,
    TwentyFourMonths
  }

  struct StakedPosition {
    // @notice Staked amount denominated in `stakingToken().decimals()`
    uint256 amount;
    // @notice Struct describing rewards owed with vesting
    StakingRewardsVesting.Rewards rewards;
    // @notice Multiplier applied to staked amount when locking up position
    uint256 leverageMultiplier;
    // @notice Time in seconds after which position can be unstaked
    uint256 lockedUntil;
  }

  /* ========== EVENTS =================== */
  event RewardsParametersUpdated(
    address indexed who,
    uint256 targetCapacity,
    uint256 minRate,
    uint256 maxRate,
    uint256 minRateAtPercent,
    uint256 maxRateAtPercent
  );
  event TargetCapacityUpdated(address indexed who, uint256 targetCapacity);
  event VestingScheduleUpdated(address indexed who, uint256 vestingLength);
  event MinRateUpdated(address indexed who, uint256 minRate);
  event MaxRateUpdated(address indexed who, uint256 maxRate);
  event MinRateAtPercentUpdated(address indexed who, uint256 minRateAtPercent);
  event MaxRateAtPercentUpdated(address indexed who, uint256 maxRateAtPercent);
  event LeverageMultiplierUpdated(address indexed who, LockupPeriod lockupPeriod, uint256 leverageMultiplier);

  /* ========== STATE VARIABLES ========== */

  uint256 private constant MULTIPLIER_DECIMALS = 1e18;

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  GoldfinchConfig public config;

  /// @notice The block timestamp when rewards were last checkpointed
  uint256 public lastUpdateTime;

  /// @notice Accumulated rewards per token at the last checkpoint
  uint256 public accumulatedRewardsPerToken;

  /// @notice Total rewards available for disbursement at the last checkpoint, denominated in `rewardsToken()`
  uint256 public rewardsAvailable;

  /// @notice StakedPosition tokenId => accumulatedRewardsPerToken at the position's last checkpoint
  mapping(uint256 => uint256) public positionToAccumulatedRewardsPerToken;

  /// @notice Desired supply of staked tokens. The reward rate adjusts in a range
  ///   around this value to incentivize staking or unstaking to maintain it.
  uint256 public targetCapacity;

  /// @notice The minimum total disbursed rewards per second, denominated in `rewardsToken()`
  uint256 public minRate;

  /// @notice The maximum total disbursed rewards per second, denominated in `rewardsToken()`
  uint256 public maxRate;

  /// @notice The percent of `targetCapacity` at which the reward rate reaches `maxRate`.
  ///  Represented with `MULTIPLIER_DECIMALS`.
  uint256 public maxRateAtPercent;

  /// @notice The percent of `targetCapacity` at which the reward rate reaches `minRate`.
  ///  Represented with `MULTIPLIER_DECIMALS`.
  uint256 public minRateAtPercent;

  /// @notice The duration in seconds over which rewards vest
  uint256 public vestingLength;

  /// @dev Supply of staked tokens, excluding leverage due to lock-up boosting, denominated in
  ///   `stakingToken().decimals()`
  uint256 public totalStakedSupply;

  /// @dev Supply of staked tokens, including leverage due to lock-up boosting, denominated in
  ///   `stakingToken().decimals()`
  uint256 private totalLeveragedStakedSupply;

  /// @dev A mapping from lockup periods to leverage multipliers used to boost rewards.
  ///   See `stakeWithLockup`.
  mapping(LockupPeriod => uint256) private leverageMultipliers;

  /// @dev NFT tokenId => staked position
  mapping(uint256 => StakedPosition) public positions;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained("Goldfinch V2 LP Staking Tokens", "GFI-V2-LPS");
    __ERC721Pausable_init_unchained();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);

    config = _config;

    vestingLength = 365 days;

    // Set defaults for leverage multipliers (no boosting)
    leverageMultipliers[LockupPeriod.SixMonths] = MULTIPLIER_DECIMALS; // 1x
    leverageMultipliers[LockupPeriod.TwelveMonths] = MULTIPLIER_DECIMALS; // 1x
    leverageMultipliers[LockupPeriod.TwentyFourMonths] = MULTIPLIER_DECIMALS; // 1x
  }

  /* ========== VIEWS ========== */

  /// @notice Returns the staked balance of a given position token
  /// @param tokenId A staking position token ID
  /// @return Amount of staked tokens denominated in `stakingToken().decimals()`
  function stakedBalanceOf(uint256 tokenId) external view returns (uint256) {
    return positions[tokenId].amount;
  }

  /// @notice The address of the token being disbursed as rewards
  function rewardsToken() public view returns (IERC20withDec) {
    return config.getGFI();
  }

  /// @notice The address of the token that can be staked
  function stakingToken() public view returns (IERC20withDec) {
    return config.getFidu();
  }

  /// @notice The additional rewards earned per token, between the provided time and the last
  ///   time rewards were checkpointed, given the prevailing `rewardRate()`. This amount is limited
  ///   by the amount of rewards that are available for distribution; if there aren't enough
  ///   rewards in the balance of this contract, then we shouldn't be giving them out.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function additionalRewardsPerTokenSinceLastUpdate(uint256 time) internal view returns (uint256) {
    require(time >= lastUpdateTime, "Invalid end time for range");

    if (totalLeveragedStakedSupply == 0) {
      return 0;
    }
    uint256 rewardsSinceLastUpdate = Math.min(time.sub(lastUpdateTime).mul(rewardRate()), rewardsAvailable);
    uint256 additionalRewardsPerToken = rewardsSinceLastUpdate.mul(stakingTokenMantissa()).div(
      totalLeveragedStakedSupply
    );
    // Prevent perverse, infinite-mint scenario where totalLeveragedStakedSupply is a fraction of a token.
    // Since it's used as the denominator, this could make additionalRewardPerToken larger than the total number
    // of tokens that should have been disbursed in the elapsed time. The attacker would need to find
    // a way to reduce totalLeveragedStakedSupply while maintaining a staked position of >= 1.
    // See: https://twitter.com/Mudit__Gupta/status/1409463917290557440
    if (additionalRewardsPerToken > rewardsSinceLastUpdate) {
      return 0;
    }
    return additionalRewardsPerToken;
  }

  /// @notice Returns accumulated rewards per token up to the current block timestamp
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`
  function rewardPerToken() public view returns (uint256) {
    uint256 additionalRewardsPerToken = additionalRewardsPerTokenSinceLastUpdate(block.timestamp);
    return accumulatedRewardsPerToken.add(additionalRewardsPerToken);
  }

  /// @notice Returns rewards earned by a given position token from its last checkpoint up to the
  ///   current block timestamp.
  /// @param tokenId A staking position token ID
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`
  function earnedSinceLastCheckpoint(uint256 tokenId) public view returns (uint256) {
    StakedPosition storage position = positions[tokenId];
    uint256 leveredAmount = positionToLeveredAmount(position);
    return
      leveredAmount.mul(rewardPerToken().sub(positionToAccumulatedRewardsPerToken[tokenId])).div(
        stakingTokenMantissa()
      );
  }

  /// @notice Returns the rewards claimable by a given position token at the most recent checkpoint, taking into
  ///   account vesting schedule.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function claimableRewards(uint256 tokenId) public view returns (uint256 rewards) {
    return positions[tokenId].rewards.claimable();
  }

  /// @notice Returns the rewards that will have vested for some position with the given params.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 time,
    uint256 grantedAmount
  ) external pure returns (uint256 rewards) {
    return StakingRewardsVesting.totalVestedAt(start, end, time, grantedAmount);
  }

  /// @notice Number of rewards, in `rewardsToken().decimals()`, to disburse each second
  function rewardRate() internal view returns (uint256) {
    // The reward rate can be thought of as a piece-wise function:
    //
    //   let intervalStart = (maxRateAtPercent * targetCapacity),
    //       intervalEnd = (minRateAtPercent * targetCapacity),
    //       x = totalStakedSupply
    //   in
    //     if x < intervalStart
    //       y = maxRate
    //     if x > intervalEnd
    //       y = minRate
    //     else
    //       y = maxRate - (maxRate - minRate) * (x - intervalStart) / (intervalEnd - intervalStart)
    //
    // See an example here:
    // solhint-disable-next-line max-line-length
    // https://www.wolframalpha.com/input/?i=Piecewise%5B%7B%7B1000%2C+x+%3C+50%7D%2C+%7B100%2C+x+%3E+300%7D%2C+%7B1000+-+%281000+-+100%29+*+%28x+-+50%29+%2F+%28300+-+50%29+%2C+50+%3C+x+%3C+300%7D%7D%5D
    //
    // In that example:
    //   maxRateAtPercent = 0.5, minRateAtPercent = 3, targetCapacity = 100, maxRate = 1000, minRate = 100
    uint256 intervalStart = targetCapacity.mul(maxRateAtPercent).div(MULTIPLIER_DECIMALS);
    uint256 intervalEnd = targetCapacity.mul(minRateAtPercent).div(MULTIPLIER_DECIMALS);
    uint256 x = totalStakedSupply;

    // Subsequent computation would overflow
    if (intervalEnd <= intervalStart) {
      return 0;
    }

    if (x < intervalStart) {
      return maxRate;
    }

    if (x > intervalEnd) {
      return minRate;
    }

    return maxRate.sub(maxRate.sub(minRate).mul(x.sub(intervalStart)).div(intervalEnd.sub(intervalStart)));
  }

  function positionToLeveredAmount(StakedPosition storage position) internal view returns (uint256) {
    return toLeveredAmount(position.amount, position.leverageMultiplier);
  }

  function toLeveredAmount(uint256 amount, uint256 leverageMultiplier) internal pure returns (uint256) {
    return amount.mul(leverageMultiplier).div(MULTIPLIER_DECIMALS);
  }

  function stakingTokenMantissa() internal view returns (uint256) {
    return uint256(10)**stakingToken().decimals();
  }

  /// @notice The amount of rewards currently being earned per token per second. This amount takes into
  ///   account how many rewards are actually available for disbursal -- unlike `rewardRate()` which does not.
  ///   This function is intended for public consumption, to know the rate at which rewards are being
  ///   earned, and not as an input to the mutative calculations in this contract.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function currentEarnRatePerToken() public view returns (uint256) {
    uint256 time = block.timestamp == lastUpdateTime ? block.timestamp + 1 : block.timestamp;
    uint256 elapsed = time.sub(lastUpdateTime);
    return additionalRewardsPerTokenSinceLastUpdate(time).div(elapsed);
  }

  /// @notice The amount of rewards currently being earned per second, for a given position. This function
  ///   is intended for public consumption, to know the rate at which rewards are being earned
  ///   for a given position, and not as an input to the mutative calculations in this contract.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function positionCurrentEarnRate(uint256 tokenId) external view returns (uint256) {
    StakedPosition storage position = positions[tokenId];
    uint256 leveredAmount = positionToLeveredAmount(position);
    return currentEarnRatePerToken().mul(leveredAmount).div(stakingTokenMantissa());
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /// @notice Stake `stakingToken()` to earn rewards. When you call this function, you'll receive an
  ///   an NFT representing your staked position. You can present your NFT to `getReward` or `unstake`
  ///   to claim rewards or unstake your tokens respectively. Rewards vest over a schedule.
  /// @dev This function checkpoints rewards.
  /// @param amount The amount of `stakingToken()` to stake
  function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(0) {
    _stakeWithLockup(msg.sender, msg.sender, amount, 0, MULTIPLIER_DECIMALS);
  }

  /// @notice Stake `stakingToken()` and lock your position for a period of time to boost your rewards.
  ///   When you call this function, you'll receive an an NFT representing your staked position.
  ///   You can present your NFT to `getReward` or `unstake` to claim rewards or unstake your tokens
  ///   respectively. Rewards vest over a schedule.
  ///
  ///   A locked position's rewards are boosted using a multiplier on the staked balance. For example,
  ///   if I lock 100 tokens for a 2x multiplier, my rewards will be calculated as if I staked 200 tokens.
  ///   This mechanism is similar to curve.fi's CRV-boosting vote-locking. Locked positions cannot be
  ///   unstaked until after the position's lockedUntil timestamp.
  /// @dev This function checkpoints rewards.
  /// @param amount The amount of `stakingToken()` to stake
  /// @param lockupPeriod The period over which to lock staked tokens
  function stakeWithLockup(uint256 amount, LockupPeriod lockupPeriod)
    external
    nonReentrant
    whenNotPaused
    updateReward(0)
  {
    uint256 lockDuration = lockupPeriodToDuration(lockupPeriod);
    uint256 leverageMultiplier = getLeverageMultiplier(lockupPeriod);
    uint256 lockedUntil = block.timestamp.add(lockDuration);
    _stakeWithLockup(msg.sender, msg.sender, amount, lockedUntil, leverageMultiplier);
  }

  /// @notice Deposit to SeniorPool and stake your shares in the same transaction.
  /// @param usdcAmount The amount of USDC to deposit into the senior pool. All shares from deposit
  ///   will be staked.
  function depositAndStake(uint256 usdcAmount) public nonReentrant whenNotPaused updateReward(0) {
    uint256 fiduAmount = depositToSeniorPool(usdcAmount);
    uint256 lockedUntil = 0;
    uint256 tokenId = _stakeWithLockup(address(this), msg.sender, fiduAmount, lockedUntil, MULTIPLIER_DECIMALS);
    emit DepositedAndStaked(msg.sender, usdcAmount, tokenId, fiduAmount, lockedUntil, MULTIPLIER_DECIMALS);
  }

  function depositToSeniorPool(uint256 usdcAmount) internal returns (uint256 fiduAmount) {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    IERC20withDec usdc = config.getUSDC();
    usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

    ISeniorPool seniorPool = config.getSeniorPool();
    usdc.safeIncreaseAllowance(address(seniorPool), usdcAmount);
    return seniorPool.deposit(usdcAmount);
  }

  /// @notice Identical to `depositAndStake`, except it allows for a signature to be passed that permits
  ///   this contract to move funds on behalf of the user.
  /// @param usdcAmount The amount of USDC to deposit
  /// @param v secp256k1 signature component
  /// @param r secp256k1 signature component
  /// @param s secp256k1 signature component
  function depositWithPermitAndStake(
    uint256 usdcAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), usdcAmount, deadline, v, r, s);
    depositAndStake(usdcAmount);
  }

  /// @notice Deposit to the `SeniorPool` and stake your shares with a lock-up in the same transaction.
  /// @param usdcAmount The amount of USDC to deposit into the senior pool. All shares from deposit
  ///   will be staked.
  /// @param lockupPeriod The period over which to lock staked tokens
  function depositAndStakeWithLockup(uint256 usdcAmount, LockupPeriod lockupPeriod)
    public
    nonReentrant
    whenNotPaused
    updateReward(0)
  {
    uint256 fiduAmount = depositToSeniorPool(usdcAmount);
    uint256 lockDuration = lockupPeriodToDuration(lockupPeriod);
    uint256 leverageMultiplier = getLeverageMultiplier(lockupPeriod);
    uint256 lockedUntil = block.timestamp.add(lockDuration);
    uint256 tokenId = _stakeWithLockup(address(this), msg.sender, fiduAmount, lockedUntil, leverageMultiplier);
    emit DepositedAndStaked(msg.sender, usdcAmount, tokenId, fiduAmount, lockedUntil, leverageMultiplier);
  }

  function lockupPeriodToDuration(LockupPeriod lockupPeriod) internal pure returns (uint256 lockDuration) {
    if (lockupPeriod == LockupPeriod.SixMonths) {
      return 365 days / 2;
    } else if (lockupPeriod == LockupPeriod.TwelveMonths) {
      return 365 days;
    } else if (lockupPeriod == LockupPeriod.TwentyFourMonths) {
      return 365 days * 2;
    } else {
      revert("unsupported LockupPeriod");
    }
  }

  /// @notice Get the leverage multiplier used to boost rewards for a given lockup period.
  ///   See `stakeWithLockup`. The leverage multiplier is denominated in `MULTIPLIER_DECIMALS`.
  function getLeverageMultiplier(LockupPeriod lockupPeriod) public view returns (uint256) {
    uint256 leverageMultiplier = leverageMultipliers[lockupPeriod];
    require(leverageMultiplier > 0, "unsupported LockupPeriod");
    return leverageMultiplier;
  }

  /// @notice Identical to `depositAndStakeWithLockup`, except it allows for a signature to be passed that permits
  ///   this contract to move funds on behalf of the user.
  /// @param usdcAmount The amount of USDC to deposit
  /// @param lockupPeriod The period over which to lock staked tokens
  /// @param v secp256k1 signature component
  /// @param r secp256k1 signature component
  /// @param s secp256k1 signature component
  function depositWithPermitAndStakeWithLockup(
    uint256 usdcAmount,
    LockupPeriod lockupPeriod,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), usdcAmount, deadline, v, r, s);
    depositAndStakeWithLockup(usdcAmount, lockupPeriod);
  }

  function _stakeWithLockup(
    address staker,
    address nftRecipient,
    uint256 amount,
    uint256 lockedUntil,
    uint256 leverageMultiplier
  ) internal returns (uint256 tokenId) {
    require(amount > 0, "Cannot stake 0");

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    // Ensure we snapshot accumulatedRewardsPerToken for tokenId after it is available
    // We do this before setting the position, because we don't want `earned` to (incorrectly) account for
    // position.amount yet. This is equivalent to using the updateReward(msg.sender) modifier in the original
    // synthetix contract, where the modifier is called before any staking balance for that address is recorded
    _updateReward(tokenId);

    positions[tokenId] = StakedPosition({
      amount: amount,
      rewards: StakingRewardsVesting.Rewards({
        totalUnvested: 0,
        totalVested: 0,
        totalPreviouslyVested: 0,
        totalClaimed: 0,
        startTime: block.timestamp,
        endTime: block.timestamp.add(vestingLength)
      }),
      leverageMultiplier: leverageMultiplier,
      lockedUntil: lockedUntil
    });
    _mint(nftRecipient, tokenId);

    uint256 leveredAmount = positionToLeveredAmount(positions[tokenId]);
    totalLeveragedStakedSupply = totalLeveragedStakedSupply.add(leveredAmount);
    totalStakedSupply = totalStakedSupply.add(amount);

    // Staker is address(this) when using depositAndStake or other convenience functions
    if (staker != address(this)) {
      stakingToken().safeTransferFrom(staker, address(this), amount);
    }

    emit Staked(nftRecipient, tokenId, amount, lockedUntil, leverageMultiplier);

    return tokenId;
  }

  /// @notice Unstake an amount of `stakingToken()` associated with a given position and transfer to msg.sender.
  ///   Unvested rewards will be forfeited, but remaining staked amount will continue to accrue rewards.
  ///   Positions that are still locked cannot be unstaked until the position's lockedUntil time has passed.
  /// @dev This function checkpoints rewards
  /// @param tokenId A staking position token ID
  /// @param amount Amount of `stakingToken()` to be unstaked from the position
  function unstake(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused updateReward(tokenId) {
    _unstake(tokenId, amount);
    stakingToken().safeTransfer(msg.sender, amount);
  }

  function unstakeAndWithdraw(uint256 tokenId, uint256 usdcAmount) public nonReentrant whenNotPaused {
    (uint256 usdcReceivedAmount, uint256 fiduAmount) = _unstakeAndWithdraw(tokenId, usdcAmount);

    emit UnstakedAndWithdrew(msg.sender, usdcReceivedAmount, tokenId, fiduAmount);
  }

  function _unstakeAndWithdraw(uint256 tokenId, uint256 usdcAmount)
    internal
    updateReward(tokenId)
    returns (uint256 usdcAmountReceived, uint256 fiduUsed)
  {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    ISeniorPool seniorPool = config.getSeniorPool();
    IFidu fidu = config.getFidu();

    uint256 fiduBalanceBefore = fidu.balanceOf(address(this));

    usdcAmountReceived = seniorPool.withdraw(usdcAmount);

    fiduUsed = fiduBalanceBefore.sub(fidu.balanceOf(address(this)));

    _unstake(tokenId, fiduUsed);
    config.getUSDC().safeTransfer(msg.sender, usdcAmountReceived);

    return (usdcAmountReceived, fiduUsed);
  }

  function unstakeAndWithdrawMultiple(uint256[] calldata tokenIds, uint256[] calldata usdcAmounts)
    public
    nonReentrant
    whenNotPaused
  {
    require(tokenIds.length == usdcAmounts.length, "tokenIds and usdcAmounts must be the same length");

    uint256 usdcReceivedAmountTotal = 0;
    uint256[] memory fiduAmounts = new uint256[](usdcAmounts.length);
    for (uint256 i = 0; i < usdcAmounts.length; i++) {
      (uint256 usdcReceivedAmount, uint256 fiduAmount) = _unstakeAndWithdraw(tokenIds[i], usdcAmounts[i]);

      usdcReceivedAmountTotal = usdcReceivedAmountTotal.add(usdcReceivedAmount);
      fiduAmounts[i] = fiduAmount;
    }

    emit UnstakedAndWithdrewMultiple(msg.sender, usdcReceivedAmountTotal, tokenIds, fiduAmounts);
  }

  function unstakeAndWithdrawInFidu(uint256 tokenId, uint256 fiduAmount) public nonReentrant whenNotPaused {
    uint256 usdcReceivedAmount = _unstakeAndWithdrawInFidu(tokenId, fiduAmount);

    emit UnstakedAndWithdrew(msg.sender, usdcReceivedAmount, tokenId, fiduAmount);
  }

  function _unstakeAndWithdrawInFidu(uint256 tokenId, uint256 fiduAmount)
    internal
    updateReward(tokenId)
    returns (uint256 usdcReceivedAmount)
  {
    usdcReceivedAmount = config.getSeniorPool().withdrawInFidu(fiduAmount);
    _unstake(tokenId, fiduAmount);
    config.getUSDC().safeTransfer(msg.sender, usdcReceivedAmount);
    return usdcReceivedAmount;
  }

  function unstakeAndWithdrawMultipleInFidu(uint256[] calldata tokenIds, uint256[] calldata fiduAmounts)
    public
    nonReentrant
    whenNotPaused
  {
    require(tokenIds.length == fiduAmounts.length, "tokenIds and usdcAmounts must be the same length");

    uint256 usdcReceivedAmountTotal = 0;
    for (uint256 i = 0; i < fiduAmounts.length; i++) {
      uint256 usdcReceivedAmount = _unstakeAndWithdrawInFidu(tokenIds[i], fiduAmounts[i]);

      usdcReceivedAmountTotal = usdcReceivedAmountTotal.add(usdcReceivedAmount);
    }

    emit UnstakedAndWithdrewMultiple(msg.sender, usdcReceivedAmountTotal, tokenIds, fiduAmounts);
  }

  function _unstake(uint256 tokenId, uint256 amount) internal {
    require(ownerOf(tokenId) == msg.sender, "access denied");
    require(amount > 0, "Cannot unstake 0");

    StakedPosition storage position = positions[tokenId];
    uint256 prevAmount = position.amount;
    require(amount <= prevAmount, "cannot unstake more than staked balance");

    require(block.timestamp >= position.lockedUntil, "staked funds are locked");

    // By this point, leverageMultiplier should always be 1x due to the reset logic in updateReward.
    // But we subtract leveredAmount from totalLeveragedStakedSupply anyway, since that is technically correct.
    uint256 leveredAmount = toLeveredAmount(amount, position.leverageMultiplier);
    totalLeveragedStakedSupply = totalLeveragedStakedSupply.sub(leveredAmount);
    totalStakedSupply = totalStakedSupply.sub(amount);
    position.amount = prevAmount.sub(amount);

    // Slash unvested rewards
    uint256 slashingPercentage = amount.mul(StakingRewardsVesting.PERCENTAGE_DECIMALS).div(prevAmount);
    position.rewards.slash(slashingPercentage);

    emit Unstaked(msg.sender, tokenId, amount);
  }

  /// @notice "Kick" a user's reward multiplier. If they are past their lock-up period, their reward
  ///   multipler will be reset to 1x.
  /// @dev This will also checkpoint their rewards up to the current time.
  // solhint-disable-next-line no-empty-blocks
  function kick(uint256 tokenId) public nonReentrant whenNotPaused updateReward(tokenId) {}

  /// @notice Claim rewards for a given staked position
  /// @param tokenId A staking position token ID
  function getReward(uint256 tokenId) public nonReentrant whenNotPaused updateReward(tokenId) {
    require(ownerOf(tokenId) == msg.sender, "access denied");
    uint256 reward = claimableRewards(tokenId);
    if (reward > 0) {
      positions[tokenId].rewards.claim(reward);
      rewardsToken().safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, tokenId, reward);
    }
  }

  /// @notice Unstake the position's full amount and claim all rewards
  /// @param tokenId A staking position token ID
  function exit(uint256 tokenId) external {
    unstake(tokenId, positions[tokenId].amount);
    getReward(tokenId);
  }

  function exitAndWithdraw(uint256 tokenId) external {
    unstakeAndWithdrawInFidu(tokenId, positions[tokenId].amount);
    getReward(tokenId);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /// @notice Transfer rewards from msg.sender, to be used for reward distribution
  function loadRewards(uint256 rewards) public onlyAdmin updateReward(0) {
    rewardsToken().safeTransferFrom(msg.sender, address(this), rewards);
    rewardsAvailable = rewardsAvailable.add(rewards);
    emit RewardAdded(rewards);
  }

  function setRewardsParameters(
    uint256 _targetCapacity,
    uint256 _minRate,
    uint256 _maxRate,
    uint256 _minRateAtPercent,
    uint256 _maxRateAtPercent
  ) public onlyAdmin updateReward(0) {
    require(_maxRate >= _minRate, "maxRate must be >= then minRate");
    require(_maxRateAtPercent <= _minRateAtPercent, "maxRateAtPercent must be <= minRateAtPercent");
    targetCapacity = _targetCapacity;
    minRate = _minRate;
    maxRate = _maxRate;
    minRateAtPercent = _minRateAtPercent;
    maxRateAtPercent = _maxRateAtPercent;

    emit RewardsParametersUpdated(msg.sender, targetCapacity, minRate, maxRate, minRateAtPercent, maxRateAtPercent);
  }

  function setLeverageMultiplier(LockupPeriod lockupPeriod, uint256 leverageMultiplier)
    public
    onlyAdmin
    updateReward(0)
  {
    leverageMultipliers[lockupPeriod] = leverageMultiplier;
    emit LeverageMultiplierUpdated(msg.sender, lockupPeriod, leverageMultiplier);
  }

  function setVestingSchedule(uint256 _vestingLength) public onlyAdmin updateReward(0) {
    vestingLength = _vestingLength;
    emit VestingScheduleUpdated(msg.sender, vestingLength);
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(_msgSender(), address(config));
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(uint256 tokenId) {
    _updateReward(tokenId);
    _;
  }

  function _updateReward(uint256 tokenId) internal {
    uint256 prevAccumulatedRewardsPerToken = accumulatedRewardsPerToken;

    accumulatedRewardsPerToken = rewardPerToken();
    uint256 rewardsJustDistributed = totalLeveragedStakedSupply
      .mul(accumulatedRewardsPerToken.sub(prevAccumulatedRewardsPerToken))
      .div(stakingTokenMantissa());
    rewardsAvailable = rewardsAvailable.sub(rewardsJustDistributed);
    lastUpdateTime = block.timestamp;

    if (tokenId != 0) {
      uint256 additionalRewards = earnedSinceLastCheckpoint(tokenId);

      StakedPosition storage position = positions[tokenId];
      StakingRewardsVesting.Rewards storage rewards = position.rewards;
      rewards.totalUnvested = rewards.totalUnvested.add(additionalRewards);
      rewards.checkpoint();

      positionToAccumulatedRewardsPerToken[tokenId] = accumulatedRewardsPerToken;

      // If position is unlocked, reset its leverageMultiplier back to 1x
      uint256 lockedUntil = position.lockedUntil;
      uint256 leverageMultiplier = position.leverageMultiplier;
      uint256 amount = position.amount;
      if (lockedUntil > 0 && block.timestamp >= lockedUntil && leverageMultiplier > MULTIPLIER_DECIMALS) {
        uint256 prevLeveredAmount = toLeveredAmount(amount, leverageMultiplier);
        uint256 newLeveredAmount = toLeveredAmount(amount, MULTIPLIER_DECIMALS);
        position.leverageMultiplier = MULTIPLIER_DECIMALS;
        totalLeveragedStakedSupply = totalLeveragedStakedSupply.sub(prevLeveredAmount).add(newLeveredAmount);
      }
    }
  }

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 lockedUntil, uint256 multiplier);
  event DepositedAndStaked(
    address indexed user,
    uint256 depositedAmount,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 lockedUntil,
    uint256 multiplier
  );
  event Unstaked(address indexed user, uint256 indexed tokenId, uint256 amount);
  event UnstakedAndWithdrew(address indexed user, uint256 usdcReceivedAmount, uint256 indexed tokenId, uint256 amount);
  event UnstakedAndWithdrewMultiple(
    address indexed user,
    uint256 usdcReceivedAmount,
    uint256[] tokenIds,
    uint256[] amounts
  );
  event RewardPaid(address indexed user, uint256 indexed tokenId, uint256 reward);
  event GoldfinchConfigUpdated(address indexed who, address configAddress);
}

pragma solidity ^0.6.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/*
Only addition is the `decimals` function, which we need, and which both our Fidu and USDC use, along with most ERC20's.
*/

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20 {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ITranchedPool.sol";

abstract contract ISeniorPool {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  function withdrawInFidu(uint256 fiduAmount) external virtual returns (uint256 amount);

  function sweepToCompound() public virtual;

  function sweepFromCompound() public virtual;

  function invest(ITranchedPool pool) public virtual;

  function estimateInvestment(ITranchedPool pool) public view virtual returns (uint256);

  function redeem(uint256 tokenId) public virtual;

  function writedown(uint256 tokenId) public virtual;

  function calculateWritedown(uint256 tokenId) public view virtual returns (uint256 writedownAmount);

  function assets() public view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "../../interfaces/IGoldfinchConfig.sol";
import "./ConfigOptions.sol";

/**
 * @title GoldfinchConfig
 * @notice This contract stores mappings of useful "protocol config state", giving a central place
 *  for all other contracts to access it. For example, the TransactionLimit, or the PoolAddress. These config vars
 *  are enumerated in the `ConfigOptions` library, and can only be changed by admins of the protocol.
 *  Note: While this inherits from BaseUpgradeablePausable, it is not deployed as an upgradeable contract (this
 *    is mostly to save gas costs of having each call go through a proxy)
 * @author Goldfinch
 */

contract GoldfinchConfig is BaseUpgradeablePausable {
  bytes32 public constant GO_LISTER_ROLE = keccak256("GO_LISTER_ROLE");

  mapping(uint256 => address) public addresses;
  mapping(uint256 => uint256) public numbers;
  mapping(address => bool) public goList;

  event AddressUpdated(address owner, uint256 index, address oldValue, address newValue);
  event NumberUpdated(address owner, uint256 index, uint256 oldValue, uint256 newValue);

  event GoListed(address indexed member);
  event NoListed(address indexed member);

  bool public valuesInitialized;

  function initialize(address owner) public initializer {
    require(owner != address(0), "Owner address cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    _setupRole(GO_LISTER_ROLE, owner);

    _setRoleAdmin(GO_LISTER_ROLE, OWNER_ROLE);
  }

  function setAddress(uint256 addressIndex, address newAddress) public onlyAdmin {
    require(addresses[addressIndex] == address(0), "Address has already been initialized");

    emit AddressUpdated(msg.sender, addressIndex, addresses[addressIndex], newAddress);
    addresses[addressIndex] = newAddress;
  }

  function setNumber(uint256 index, uint256 newNumber) public onlyAdmin {
    emit NumberUpdated(msg.sender, index, numbers[index], newNumber);
    numbers[index] = newNumber;
  }

  function setTreasuryReserve(address newTreasuryReserve) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.TreasuryReserve);
    emit AddressUpdated(msg.sender, key, addresses[key], newTreasuryReserve);
    addresses[key] = newTreasuryReserve;
  }

  function setSeniorPoolStrategy(address newStrategy) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.SeniorPoolStrategy);
    emit AddressUpdated(msg.sender, key, addresses[key], newStrategy);
    addresses[key] = newStrategy;
  }

  function setCreditLineImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.CreditLineImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setTranchedPoolImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.TranchedPoolImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setBorrowerImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.BorrowerImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setGoldfinchConfig(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.GoldfinchConfig);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function initializeFromOtherConfig(
    address _initialConfig,
    uint256 numbersLength,
    uint256 addressesLength
  ) public onlyAdmin {
    require(!valuesInitialized, "Already initialized values");
    IGoldfinchConfig initialConfig = IGoldfinchConfig(_initialConfig);
    for (uint256 i = 0; i < numbersLength; i++) {
      setNumber(i, initialConfig.getNumber(i));
    }

    for (uint256 i = 0; i < addressesLength; i++) {
      if (getAddress(i) == address(0)) {
        setAddress(i, initialConfig.getAddress(i));
      }
    }
    valuesInitialized = true;
  }

  /**
   * @dev Adds a user to go-list
   * @param _member address to add to go-list
   */
  function addToGoList(address _member) public onlyGoListerRole {
    goList[_member] = true;
    emit GoListed(_member);
  }

  /**
   * @dev removes a user from go-list
   * @param _member address to remove from go-list
   */
  function removeFromGoList(address _member) public onlyGoListerRole {
    goList[_member] = false;
    emit NoListed(_member);
  }

  /**
   * @dev adds many users to go-list at once
   * @param _members addresses to ad to go-list
   */
  function bulkAddToGoList(address[] calldata _members) external onlyGoListerRole {
    for (uint256 i = 0; i < _members.length; i++) {
      addToGoList(_members[i]);
    }
  }

  /**
   * @dev removes many users from go-list at once
   * @param _members addresses to remove from go-list
   */
  function bulkRemoveFromGoList(address[] calldata _members) external onlyGoListerRole {
    for (uint256 i = 0; i < _members.length; i++) {
      removeFromGoList(_members[i]);
    }
  }

  /*
    Using custom getters in case we want to change underlying implementation later,
    or add checks or validations later on.
  */
  function getAddress(uint256 index) public view returns (address) {
    return addresses[index];
  }

  function getNumber(uint256 index) public view returns (uint256) {
    return numbers[index];
  }

  modifier onlyGoListerRole() {
    require(hasRole(GO_LISTER_ROLE, _msgSender()), "Must have go-lister role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./GoldfinchConfig.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IFidu.sol";
import "../../interfaces/ISeniorPool.sol";
import "../../interfaces/ISeniorPoolStrategy.sol";
import "../../interfaces/ICreditDesk.sol";
import "../../interfaces/IERC20withDec.sol";
import "../../interfaces/ICUSDCContract.sol";
import "../../interfaces/IPoolTokens.sol";
import "../../interfaces/IBackerRewards.sol";
import "../../interfaces/IGoldfinchFactory.sol";
import "../../interfaces/IGo.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigHelper {
  function getPool(GoldfinchConfig config) internal view returns (IPool) {
    return IPool(poolAddress(config));
  }

  function getSeniorPool(GoldfinchConfig config) internal view returns (ISeniorPool) {
    return ISeniorPool(seniorPoolAddress(config));
  }

  function getSeniorPoolStrategy(GoldfinchConfig config) internal view returns (ISeniorPoolStrategy) {
    return ISeniorPoolStrategy(seniorPoolStrategyAddress(config));
  }

  function getUSDC(GoldfinchConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }

  function getCreditDesk(GoldfinchConfig config) internal view returns (ICreditDesk) {
    return ICreditDesk(creditDeskAddress(config));
  }

  function getFidu(GoldfinchConfig config) internal view returns (IFidu) {
    return IFidu(fiduAddress(config));
  }

  function getCUSDCContract(GoldfinchConfig config) internal view returns (ICUSDCContract) {
    return ICUSDCContract(cusdcContractAddress(config));
  }

  function getPoolTokens(GoldfinchConfig config) internal view returns (IPoolTokens) {
    return IPoolTokens(poolTokensAddress(config));
  }

  function getBackerRewards(GoldfinchConfig config) internal view returns (IBackerRewards) {
    return IBackerRewards(backerRewardsAddress(config));
  }

  function getGoldfinchFactory(GoldfinchConfig config) internal view returns (IGoldfinchFactory) {
    return IGoldfinchFactory(goldfinchFactoryAddress(config));
  }

  function getGFI(GoldfinchConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(gfiAddress(config));
  }

  function getGo(GoldfinchConfig config) internal view returns (IGo) {
    return IGo(goAddress(config));
  }

  function oneInchAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.OneInch));
  }

  function creditLineImplementationAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CreditLineImplementation));
  }

  function trustedForwarderAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TrustedForwarder));
  }

  function configAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchConfig));
  }

  function poolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Pool));
  }

  function poolTokensAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PoolTokens));
  }

  function backerRewardsAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackerRewards));
  }

  function seniorPoolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SeniorPool));
  }

  function seniorPoolStrategyAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SeniorPoolStrategy));
  }

  function creditDeskAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CreditDesk));
  }

  function goldfinchFactoryAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchFactory));
  }

  function gfiAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GFI));
  }

  function fiduAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Fidu));
  }

  function cusdcContractAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CUSDCContract));
  }

  function usdcAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.USDC));
  }

  function tranchedPoolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TranchedPoolImplementation));
  }

  function migratedTranchedPoolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.MigratedTranchedPoolImplementation));
  }

  function reserveAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ProtocolAdmin));
  }

  function borrowerImplementationAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BorrowerImplementation));
  }

  function goAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Go));
  }

  function stakingRewardsAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.StakingRewards));
  }

  function getReserveDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessMaxDays));
  }

  function getDrawdownPeriodInSeconds(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.DrawdownPeriodInSeconds));
  }

  function getTransferRestrictionPeriodInDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.TransferRestrictionPeriodInDays));
  }

  function getLeverageRatio(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LeverageRatio));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./PauserPausable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like ugpradeability, pausability, access control, and re-entrancy guards.
 * @author Goldfinch
 */

contract BaseUpgradeablePausable is
  Initializable,
  AccessControlUpgradeSafe,
  PauserPausable,
  ReentrancyGuardUpgradeSafe
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  using SafeMath for uint256;
  // Pre-reserving a few slots in the base contract in case we need to add things in the future.
  // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
  // See OpenZeppelin's use of this pattern here:
  // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
  uint256[50] private __gap1;
  uint256[50] private __gap2;
  uint256[50] private __gap3;
  uint256[50] private __gap4;

  // solhint-disable-next-line func-name-mixedcase
  function __BaseUpgradeablePausable__init(address owner) public initializer {
    require(owner != address(0), "Owner cannot be the zero address");
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

library StakingRewardsVesting {
  using SafeMath for uint256;
  using StakingRewardsVesting for Rewards;

  uint256 internal constant PERCENTAGE_DECIMALS = 1e18;

  struct Rewards {
    uint256 totalUnvested;
    uint256 totalVested;
    uint256 totalPreviouslyVested;
    uint256 totalClaimed;
    uint256 startTime;
    uint256 endTime;
  }

  function claim(Rewards storage rewards, uint256 reward) internal {
    rewards.totalClaimed = rewards.totalClaimed.add(reward);
  }

  function claimable(Rewards storage rewards) internal view returns (uint256) {
    return rewards.totalVested.add(rewards.totalPreviouslyVested).sub(rewards.totalClaimed);
  }

  function currentGrant(Rewards storage rewards) internal view returns (uint256) {
    return rewards.totalUnvested.add(rewards.totalVested);
  }

  /// @notice Slash the vesting rewards by `percentage`. `percentage` of the unvested portion
  ///   of the grant is forfeited. The remaining unvested portion continues to vest over the rest
  ///   of the vesting schedule. The already vested portion continues to be claimable.
  ///
  ///   A motivating example:
  ///
  ///   Let's say we're 50% through vesting, with 100 tokens granted. Thus, 50 tokens are vested and 50 are unvested.
  ///   Now let's say the grant is slashed by 90% (e.g. for StakingRewards, because the user unstaked 90% of their
  ///   position). 45 of the unvested tokens will be forfeited. 5 of the unvested tokens and 5 of the vested tokens
  ///   will be considered as the "new grant", which is 50% through vesting. The remaining 45 vested tokens will be
  ///   still be claimable at any time.
  function slash(Rewards storage rewards, uint256 percentage) internal {
    require(percentage <= PERCENTAGE_DECIMALS, "slashing percentage cannot be greater than 100%");

    uint256 unvestedToSlash = rewards.totalUnvested.mul(percentage).div(PERCENTAGE_DECIMALS);
    uint256 vestedToMove = rewards.totalVested.mul(percentage).div(PERCENTAGE_DECIMALS);

    rewards.totalUnvested = rewards.totalUnvested.sub(unvestedToSlash);
    rewards.totalVested = rewards.totalVested.sub(vestedToMove);
    rewards.totalPreviouslyVested = rewards.totalPreviouslyVested.add(vestedToMove);
  }

  function checkpoint(Rewards storage rewards) internal {
    uint256 newTotalVested = totalVestedAt(rewards.startTime, rewards.endTime, block.timestamp, rewards.currentGrant());

    if (newTotalVested > rewards.totalVested) {
      uint256 difference = newTotalVested.sub(rewards.totalVested);
      rewards.totalUnvested = rewards.totalUnvested.sub(difference);
      rewards.totalVested = newTotalVested;
    }
  }

  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 time,
    uint256 grantedAmount
  ) internal pure returns (uint256) {
    if (end <= start) {
      return grantedAmount;
    }

    return Math.min(grantedAmount.mul(time.sub(start)).div(end.sub(start)), grantedAmount);
  }
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IV2CreditLine.sol";

abstract contract ITranchedPool {
  IV2CreditLine public creditLine;
  uint256 public createdAt;

  enum Tranches {
    Reserved,
    Senior,
    Junior
  }

  struct TrancheInfo {
    uint256 id;
    uint256 principalDeposited;
    uint256 principalSharePrice;
    uint256 interestSharePrice;
    uint256 lockedUntil;
  }

  struct PoolSlice {
    TrancheInfo seniorTranche;
    TrancheInfo juniorTranche;
    uint256 totalInterestAccrued;
    uint256 principalDeployed;
  }

  struct SliceInfo {
    uint256 reserveFeePercent;
    uint256 interestAccrued;
    uint256 principalAccrued;
  }

  struct ApplyResult {
    uint256 interestRemaining;
    uint256 principalRemaining;
    uint256 reserveDeduction;
    uint256 oldInterestSharePrice;
    uint256 oldPrincipalSharePrice;
  }

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public virtual;

  function getTranche(uint256 tranche) external view virtual returns (TrancheInfo memory);

  function pay(uint256 amount) external virtual;

  function lockJuniorCapital() external virtual;

  function lockPool() external virtual;

  function initializeNextSlice(uint256 _fundableAt) external virtual;

  function totalJuniorDeposits() external view virtual returns (uint256);

  function drawdown(uint256 amount) external virtual;

  function setFundableAt(uint256 timestamp) external virtual;

  function deposit(uint256 tranche, uint256 amount) external virtual returns (uint256 tokenId);

  function assess() external virtual;

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 tokenId);

  function availableToWithdraw(uint256 tokenId)
    external
    view
    virtual
    returns (uint256 interestRedeemable, uint256 principalRedeemable);

  function withdraw(uint256 tokenId, uint256 amount)
    external
    virtual
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMax(uint256 tokenId)
    external
    virtual
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMultiple(uint256[] calldata tokenIds, uint256[] calldata amounts) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ICreditLine.sol";

abstract contract IV2CreditLine is ICreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess()
    external
    virtual
    returns (
      uint256,
      uint256,
      uint256
    );

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;

  function updateGoldfinchConfig() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ICreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IGoldfinchConfig {
  function getNumber(uint256 index) external returns (uint256);

  function getAddress(uint256 index) external returns (address);

  function setAddress(uint256 index, address newAddress) external returns (address);

  function setNumber(uint256 index, uint256 newNumber) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit,
    TotalFundsLimit,
    MaxUnderwriterLimit,
    ReserveDenominator,
    WithdrawFeeDenominator,
    LatenessGracePeriodInDays,
    LatenessMaxDays,
    DrawdownPeriodInSeconds,
    TransferRestrictionPeriodInDays,
    LeverageRatio
  }
  enum Addresses {
    Pool,
    CreditLineImplementation,
    GoldfinchFactory,
    CreditDesk,
    Fidu,
    USDC,
    TreasuryReserve,
    ProtocolAdmin,
    OneInch,
    TrustedForwarder,
    CUSDCContract,
    GoldfinchConfig,
    PoolTokens,
    TranchedPoolImplementation,
    SeniorPool,
    SeniorPoolStrategy,
    MigratedTranchedPoolImplementation,
    BorrowerImplementation,
    GFI,
    Go,
    BackerRewards,
    StakingRewards
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

/**
 * @title PauserPausable
 * @notice Inheriting from OpenZeppelin's Pausable contract, this does small
 *  augmentations to make it work with a PAUSER_ROLE, leveraging the AccessControl contract.
 *  It is meant to be inherited.
 * @author Goldfinch
 */

contract PauserPausable is AccessControlUpgradeSafe, PausableUpgradeSafe {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __PauserPausable__init() public initializer {
    __Pausable_init_unchained();
  }

  /**
   * @dev Pauses all functions guarded by Pause
   *
   * See {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the PAUSER_ROLE.
   */

  function pause() public onlyPauserRole {
    _pause();
  }

  /**
   * @dev Unpauses the contract
   *
   * See {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the Pauser role
   */
  function unpause() public onlyPauserRole {
    _unpause();
  }

  modifier onlyPauserRole() {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract IPool {
  uint256 public sharePrice;

  function deposit(uint256 amount) external virtual;

  function withdraw(uint256 usdcAmount) external virtual;

  function withdrawInFidu(uint256 fiduAmount) external virtual;

  function collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) public virtual;

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool);

  function drawdown(address to, uint256 amount) public virtual returns (bool);

  function sweepToCompound() public virtual;

  function sweepFromCompound() public virtual;

  function distributeLosses(address creditlineAddress, int256 writedownDelta) external virtual;

  function assets() public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20withDec.sol";

interface IFidu is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;

  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ISeniorPool.sol";
import "./ITranchedPool.sol";

abstract contract ISeniorPoolStrategy {
  function getLeverageRatio(ITranchedPool pool) public view virtual returns (uint256);

  function invest(ISeniorPool seniorPool, ITranchedPool pool) public view virtual returns (uint256 amount);

  function estimateInvestment(ISeniorPool seniorPool, ITranchedPool pool) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract ICreditDesk {
  uint256 public totalWritedowns;
  uint256 public totalLoansOutstanding;

  function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit) external virtual;

  function drawdown(address creditLineAddress, uint256 amount) external virtual;

  function pay(address creditLineAddress, uint256 amount) external virtual;

  function assessCreditLine(address creditLineAddress) external virtual;

  function applyPayment(address creditLineAddress, uint256 amount) external virtual;

  function getNextPaymentAmount(address creditLineAddress, uint256 asOfBLock) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20withDec.sol";

interface ICUSDCContract is IERC20withDec {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function balanceOfUnderlying(address owner) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";

interface IPoolTokens is IERC721 {
  event TokenMinted(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 tranche
  );

  event TokenRedeemed(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    uint256 tranche
  );
  event TokenBurned(address indexed owner, address indexed pool, uint256 indexed tokenId);

  struct TokenInfo {
    address pool;
    uint256 tranche;
    uint256 principalAmount;
    uint256 principalRedeemed;
    uint256 interestRedeemed;
  }

  struct MintParams {
    uint256 principalAmount;
    uint256 tranche;
  }

  function mint(MintParams calldata params, address to) external returns (uint256);

  function redeem(
    uint256 tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed
  ) external;

  function burn(uint256 tokenId) external;

  function onPoolCreated(address newPool) external;

  function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory);

  function validPool(address sender) external view returns (bool);

  function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBackerRewards {
  function allocateRewards(uint256 _interestPaymentAmount) external;

  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IGoldfinchFactory {
  function createCreditLine() external returns (address);

  function createBorrower(address owner) external returns (address);

  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function createMigratedPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function updateGoldfinchConfig() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract IGo {
  uint256 public constant ID_TYPE_0 = 0;
  uint256 public constant ID_TYPE_1 = 1;
  uint256 public constant ID_TYPE_2 = 2;
  uint256 public constant ID_TYPE_3 = 3;
  uint256 public constant ID_TYPE_4 = 4;
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  /// @notice Returns the address of the UniqueIdentity contract.
  function uniqueIdentity() external virtual returns (address);

  function go(address account) public view virtual returns (bool);

  function goOnlyIdTypes(address account, uint256[] calldata onlyIdTypes) public view virtual returns (bool);

  function goSeniorPool(address account) public view virtual returns (bool);

  function updateGoldfinchConfig() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";
import "../protocol/core/Pool.sol";
import "../protocol/core/Accountant.sol";
import "../protocol/core/CreditLine.sol";
import "../protocol/core/GoldfinchConfig.sol";

contract FakeV2CreditDesk is BaseUpgradeablePausable {
  uint256 public totalWritedowns;
  uint256 public totalLoansOutstanding;
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;
  GoldfinchConfig public config;

  struct Underwriter {
    uint256 governanceLimit;
    address[] creditLines;
  }

  struct Borrower {
    address[] creditLines;
  }

  event PaymentMade(
    address indexed payer,
    address indexed creditLine,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount
  );
  event PrepaymentMade(address indexed payer, address indexed creditLine, uint256 prepaymentAmount);
  event DrawdownMade(address indexed borrower, address indexed creditLine, uint256 drawdownAmount);
  event CreditLineCreated(address indexed borrower, address indexed creditLine);
  event PoolAddressUpdated(address indexed oldAddress, address indexed newAddress);
  event GovernanceUpdatedUnderwriterLimit(address indexed underwriter, uint256 newLimit);
  event LimitChanged(address indexed owner, string limitType, uint256 amount);

  mapping(address => Underwriter) public underwriters;
  mapping(address => Borrower) private borrowers;

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    owner;
    _config;
    return;
  }

  function someBrandNewFunction() public pure returns (uint256) {
    return 5;
  }

  function getUnderwriterCreditLines(address underwriterAddress) public view returns (address[] memory) {
    return underwriters[underwriterAddress].creditLines;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";

/**
 * @title Goldfinch's Pool contract
 * @notice Main entry point for LP's (a.k.a. capital providers)
 *  Handles key logic for depositing and withdrawing funds from the Pool
 * @author Goldfinch
 */

contract Pool is BaseUpgradeablePausable, IPool {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  uint256 public compoundBalance;

  event DepositMade(address indexed capitalProvider, uint256 amount, uint256 shares);
  event WithdrawalMade(address indexed capitalProvider, uint256 userAmount, uint256 reserveAmount);
  event TransferMade(address indexed from, address indexed to, uint256 amount);
  event InterestCollected(address indexed payer, uint256 poolAmount, uint256 reserveAmount);
  event PrincipalCollected(address indexed payer, uint256 amount);
  event ReserveFundsCollected(address indexed user, uint256 amount);
  event PrincipalWrittendown(address indexed creditline, int256 amount);
  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  /**
   * @notice Run only once, on initialization
   * @param owner The address of who should have the "OWNER_ROLE" of this contract
   * @param _config The address of the GoldfinchConfig contract
   */
  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    config = _config;
    sharePrice = fiduMantissa();
    IERC20withDec usdc = config.getUSDC();
    // Sanity check the address
    usdc.totalSupply();

    // Unlock self for infinite amount
    bool success = usdc.approve(address(this), uint256(-1));
    require(success, "Failed to approve USDC");
  }

  /**
   * @notice Deposits `amount` USDC from msg.sender into the Pool, and returns you the equivalent value of FIDU tokens
   * @param amount The amount of USDC to deposit
   */
  function deposit(uint256 amount) external override whenNotPaused withinTransactionLimit(amount) nonReentrant {
    require(amount > 0, "Must deposit more than zero");
    // Check if the amount of new shares to be added is within limits
    uint256 depositShares = getNumShares(amount);
    uint256 potentialNewTotalShares = totalShares().add(depositShares);
    require(poolWithinLimit(potentialNewTotalShares), "Deposit would put the Pool over the total limit.");
    emit DepositMade(msg.sender, amount, depositShares);
    bool success = doUSDCTransfer(msg.sender, address(this), amount);
    require(success, "Failed to transfer for deposit");

    config.getFidu().mintTo(msg.sender, depositShares);
  }

  /**
   * @notice Withdraws USDC from the Pool to msg.sender, and burns the equivalent value of FIDU tokens
   * @param usdcAmount The amount of USDC to withdraw
   */
  function withdraw(uint256 usdcAmount) external override whenNotPaused nonReentrant {
    require(usdcAmount > 0, "Must withdraw more than zero");
    // This MUST happen before calculating withdrawShares, otherwise the share price
    // changes between calculation and burning of Fidu, which creates a asset/liability mismatch
    if (compoundBalance > 0) {
      _sweepFromCompound();
    }
    uint256 withdrawShares = getNumShares(usdcAmount);
    _withdraw(usdcAmount, withdrawShares);
  }

  /**
   * @notice Withdraws USDC (denominated in FIDU terms) from the Pool to msg.sender
   * @param fiduAmount The amount of USDC to withdraw in terms of fidu shares
   */
  function withdrawInFidu(uint256 fiduAmount) external override whenNotPaused nonReentrant {
    require(fiduAmount > 0, "Must withdraw more than zero");
    if (compoundBalance > 0) {
      _sweepFromCompound();
    }
    uint256 usdcAmount = getUSDCAmountFromShares(fiduAmount);
    uint256 withdrawShares = fiduAmount;
    _withdraw(usdcAmount, withdrawShares);
  }

  /**
   * @notice Collects `interest` USDC in interest and `principal` in principal from `from` and sends it to the Pool.
   *  This also increases the share price accordingly. A portion is sent to the Goldfinch Reserve address
   * @param from The address to take the USDC from. Implicitly, the Pool
   *  must be authorized to move USDC on behalf of `from`.
   * @param interest the interest amount of USDC to move to the Pool
   * @param principal the principal amount of USDC to move to the Pool
   *
   * Requirements:
   *  - The caller must be the Credit Desk. Not even the owner can call this function.
   */
  function collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) public override onlyCreditDesk whenNotPaused {
    _collectInterestAndPrincipal(from, interest, principal);
  }

  function distributeLosses(address creditlineAddress, int256 writedownDelta)
    external
    override
    onlyCreditDesk
    whenNotPaused
  {
    if (writedownDelta > 0) {
      uint256 delta = usdcToSharePrice(uint256(writedownDelta));
      sharePrice = sharePrice.add(delta);
    } else {
      // If delta is negative, convert to positive uint, and sub from sharePrice
      uint256 delta = usdcToSharePrice(uint256(writedownDelta * -1));
      sharePrice = sharePrice.sub(delta);
    }
    emit PrincipalWrittendown(creditlineAddress, writedownDelta);
  }

  /**
   * @notice Moves `amount` USDC from `from`, to `to`.
   * @param from The address to take the USDC from. Implicitly, the Pool
   *  must be authorized to move USDC on behalf of `from`.
   * @param to The address that the USDC should be moved to
   * @param amount the amount of USDC to move to the Pool
   *
   * Requirements:
   *  - The caller must be the Credit Desk. Not even the owner can call this function.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override onlyCreditDesk whenNotPaused returns (bool) {
    bool result = doUSDCTransfer(from, to, amount);
    require(result, "USDC Transfer failed");
    emit TransferMade(from, to, amount);
    return result;
  }

  /**
   * @notice Moves `amount` USDC from the pool, to `to`. This is similar to transferFrom except we sweep any
   * balance we have from compound first and recognize interest. Meant to be called only by the credit desk on drawdown
   * @param to The address that the USDC should be moved to
   * @param amount the amount of USDC to move to the Pool
   *
   * Requirements:
   *  - The caller must be the Credit Desk. Not even the owner can call this function.
   */
  function drawdown(address to, uint256 amount) public override onlyCreditDesk whenNotPaused returns (bool) {
    if (compoundBalance > 0) {
      _sweepFromCompound();
    }
    return transferFrom(address(this), to, amount);
  }

  function assets() public view override returns (uint256) {
    ICreditDesk creditDesk = config.getCreditDesk();
    return
      compoundBalance.add(config.getUSDC().balanceOf(address(this))).add(creditDesk.totalLoansOutstanding()).sub(
        creditDesk.totalWritedowns()
      );
  }

  function migrateToSeniorPool() external onlyAdmin {
    // Bring back all USDC
    if (compoundBalance > 0) {
      sweepFromCompound();
    }

    // Pause deposits/withdrawals
    if (!paused()) {
      pause();
    }

    // Remove special priveldges from Fidu
    bytes32 minterRole = keccak256("MINTER_ROLE");
    bytes32 pauserRole = keccak256("PAUSER_ROLE");
    config.getFidu().renounceRole(minterRole, address(this));
    config.getFidu().renounceRole(pauserRole, address(this));

    // Move all USDC to the SeniorPool
    address seniorPoolAddress = config.seniorPoolAddress();
    uint256 balance = config.getUSDC().balanceOf(address(this));
    bool success = doUSDCTransfer(address(this), seniorPoolAddress, balance);
    require(success, "Failed to transfer USDC balance to the senior pool");

    // Claim our COMP!
    address compoundController = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    bytes memory data = abi.encodeWithSignature("claimComp(address)", address(this));
    bytes memory _res;
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = compoundController.call(data);
    require(success, "Failed to claim COMP");

    // Send our balance of COMP!
    address compToken = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    data = abi.encodeWithSignature("balanceOf(address)", address(this));
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = compToken.call(data);
    uint256 compBalance = toUint256(_res);
    data = abi.encodeWithSignature("transfer(address,uint256)", seniorPoolAddress, compBalance);
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = compToken.call(data);
    require(success, "Failed to transfer COMP");
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }

  /**
   * @notice Moves any USDC still in the Pool to Compound, and tracks the amount internally.
   * This is done to earn interest on latent funds until we have other borrowers who can use it.
   *
   * Requirements:
   *  - The caller must be an admin.
   */
  function sweepToCompound() public override onlyAdmin whenNotPaused {
    IERC20 usdc = config.getUSDC();
    uint256 usdcBalance = usdc.balanceOf(address(this));

    ICUSDCContract cUSDC = config.getCUSDCContract();
    // Approve compound to the exact amount
    bool success = usdc.approve(address(cUSDC), usdcBalance);
    require(success, "Failed to approve USDC for compound");

    sweepToCompound(cUSDC, usdcBalance);

    // Remove compound approval to be extra safe
    success = config.getUSDC().approve(address(cUSDC), 0);
    require(success, "Failed to approve USDC for compound");
  }

  /**
   * @notice Moves any USDC from Compound back to the Pool, and recognizes interest earned.
   * This is done automatically on drawdown or withdraw, but can be called manually if necessary.
   *
   * Requirements:
   *  - The caller must be an admin.
   */
  function sweepFromCompound() public override onlyAdmin whenNotPaused {
    _sweepFromCompound();
  }

  /* Internal Functions */

  function _withdraw(uint256 usdcAmount, uint256 withdrawShares) internal withinTransactionLimit(usdcAmount) {
    IFidu fidu = config.getFidu();
    // Determine current shares the address has and the shares requested to withdraw
    uint256 currentShares = fidu.balanceOf(msg.sender);
    // Ensure the address has enough value in the pool
    require(withdrawShares <= currentShares, "Amount requested is greater than what this address owns");

    uint256 reserveAmount = usdcAmount.div(config.getWithdrawFeeDenominator());
    uint256 userAmount = usdcAmount.sub(reserveAmount);

    emit WithdrawalMade(msg.sender, userAmount, reserveAmount);
    // Send the amounts
    bool success = doUSDCTransfer(address(this), msg.sender, userAmount);
    require(success, "Failed to transfer for withdraw");
    sendToReserve(address(this), reserveAmount, msg.sender);

    // Burn the shares
    fidu.burnFrom(msg.sender, withdrawShares);
  }

  function sweepToCompound(ICUSDCContract cUSDC, uint256 usdcAmount) internal {
    // Our current design requires we re-normalize by withdrawing everything and recognizing interest gains
    // before we can add additional capital to Compound
    require(compoundBalance == 0, "Cannot sweep when we already have a compound balance");
    require(usdcAmount != 0, "Amount to sweep cannot be zero");
    uint256 error = cUSDC.mint(usdcAmount);
    require(error == 0, "Sweep to compound failed");
    compoundBalance = usdcAmount;
  }

  function sweepFromCompound(ICUSDCContract cUSDC, uint256 cUSDCAmount) internal {
    uint256 cBalance = compoundBalance;
    require(cBalance != 0, "No funds on compound");
    require(cUSDCAmount != 0, "Amount to sweep cannot be zero");

    IERC20 usdc = config.getUSDC();
    uint256 preRedeemUSDCBalance = usdc.balanceOf(address(this));
    uint256 cUSDCExchangeRate = cUSDC.exchangeRateCurrent();
    uint256 redeemedUSDC = cUSDCToUSDC(cUSDCExchangeRate, cUSDCAmount);

    uint256 error = cUSDC.redeem(cUSDCAmount);
    uint256 postRedeemUSDCBalance = usdc.balanceOf(address(this));
    require(error == 0, "Sweep from compound failed");
    require(postRedeemUSDCBalance.sub(preRedeemUSDCBalance) == redeemedUSDC, "Unexpected redeem amount");

    uint256 interestAccrued = redeemedUSDC.sub(cBalance);
    _collectInterestAndPrincipal(address(this), interestAccrued, 0);
    compoundBalance = 0;
  }

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal {
    uint256 reserveAmount = interest.div(config.getReserveDenominator());
    uint256 poolAmount = interest.sub(reserveAmount);
    uint256 increment = usdcToSharePrice(poolAmount);
    sharePrice = sharePrice.add(increment);

    if (poolAmount > 0) {
      emit InterestCollected(from, poolAmount, reserveAmount);
    }
    if (principal > 0) {
      emit PrincipalCollected(from, principal);
    }
    if (reserveAmount > 0) {
      sendToReserve(from, reserveAmount, from);
    }
    // Gas savings: No need to transfer to yourself, which happens in sweepFromCompound
    if (from != address(this)) {
      bool success = doUSDCTransfer(from, address(this), principal.add(poolAmount));
      require(success, "Failed to collect principal repayment");
    }
  }

  function _sweepFromCompound() internal {
    ICUSDCContract cUSDC = config.getCUSDCContract();
    sweepFromCompound(cUSDC, cUSDC.balanceOf(address(this)));
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  function fiduMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }

  function usdcToFidu(uint256 amount) internal pure returns (uint256) {
    return amount.mul(fiduMantissa()).div(usdcMantissa());
  }

  function cUSDCToUSDC(uint256 exchangeRate, uint256 amount) internal pure returns (uint256) {
    // See https://compound.finance/docs#protocol-math
    // But note, the docs and reality do not agree. Docs imply that that exchange rate is
    // scaled by 1e18, but tests and mainnet forking make it appear to be scaled by 1e16
    // 1e16 is also what Sheraz at Certik said.
    uint256 usdcDecimals = 6;
    uint256 cUSDCDecimals = 8;

    // We multiply in the following order, for the following reasons...
    // Amount in cToken (1e8)
    // Amount in USDC (but scaled by 1e16, cause that's what exchange rate decimals are)
    // Downscale to cToken decimals (1e8)
    // Downscale from cToken to USDC decimals (8 to 6)
    return amount.mul(exchangeRate).div(10**(18 + usdcDecimals - cUSDCDecimals)).div(10**2);
  }

  function totalShares() internal view returns (uint256) {
    return config.getFidu().totalSupply();
  }

  function usdcToSharePrice(uint256 usdcAmount) internal view returns (uint256) {
    return usdcToFidu(usdcAmount).mul(fiduMantissa()).div(totalShares());
  }

  function poolWithinLimit(uint256 _totalShares) internal view returns (bool) {
    return
      _totalShares.mul(sharePrice).div(fiduMantissa()) <=
      usdcToFidu(config.getNumber(uint256(ConfigOptions.Numbers.TotalFundsLimit)));
  }

  function transactionWithinLimit(uint256 amount) internal view returns (bool) {
    return amount <= config.getNumber(uint256(ConfigOptions.Numbers.TransactionLimit));
  }

  function getNumShares(uint256 amount) internal view returns (uint256) {
    return usdcToFidu(amount).mul(fiduMantissa()).div(sharePrice);
  }

  function getUSDCAmountFromShares(uint256 fiduAmount) internal view returns (uint256) {
    return fiduToUSDC(fiduAmount.mul(sharePrice).div(fiduMantissa()));
  }

  function fiduToUSDC(uint256 amount) internal pure returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  function sendToReserve(
    address from,
    uint256 amount,
    address userForEvent
  ) internal {
    emit ReserveFundsCollected(userForEvent, amount);
    bool success = doUSDCTransfer(from, config.reserveAddress(), amount);
    require(success, "Reserve transfer was not successful");
  }

  function doUSDCTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    require(to != address(0), "Can't send to zero address");
    IERC20withDec usdc = config.getUSDC();
    return usdc.transferFrom(from, to, amount);
  }

  modifier withinTransactionLimit(uint256 amount) {
    require(transactionWithinLimit(amount), "Amount is over the per-transaction limit");
    _;
  }

  modifier onlyCreditDesk() {
    require(msg.sender == config.creditDeskAddress(), "Only the credit desk is allowed to call this function");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./CreditLine.sol";
import "../../interfaces/ICreditLine.sol";
import "../../external/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title The Accountant
 * @notice Library for handling key financial calculations, such as interest and principal accrual.
 * @author Goldfinch
 */

library Accountant {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Signed;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for int256;
  using FixedPoint for uint256;

  // Scaling factor used by FixedPoint.sol. We need this to convert the fixed point raw values back to unscaled
  uint256 public constant FP_SCALING_FACTOR = 10**18;
  uint256 public constant INTEREST_DECIMALS = 1e18;
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;
  uint256 public constant SECONDS_PER_YEAR = (SECONDS_PER_DAY * 365);

  struct PaymentAllocation {
    uint256 interestPayment;
    uint256 principalPayment;
    uint256 additionalBalancePayment;
  }

  function calculateInterestAndPrincipalAccrued(
    CreditLine cl,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 balance = cl.balance(); // gas optimization
    uint256 interestAccrued = calculateInterestAccrued(cl, balance, timestamp, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, timestamp);
    return (interestAccrued, principalAccrued);
  }

  function calculateInterestAndPrincipalAccruedOverPeriod(
    CreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 interestAccrued = calculateInterestAccruedOverPeriod(cl, balance, startTime, endTime, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, endTime);
    return (interestAccrued, principalAccrued);
  }

  function calculatePrincipalAccrued(
    ICreditLine cl,
    uint256 balance,
    uint256 timestamp
  ) public view returns (uint256) {
    // If we've already accrued principal as of the term end time, then don't accrue more principal
    uint256 termEndTime = cl.termEndTime();
    if (cl.interestAccruedAsOf() >= termEndTime) {
      return 0;
    }
    if (timestamp >= termEndTime) {
      return balance;
    } else {
      return 0;
    }
  }

  function calculateWritedownFor(
    ICreditLine cl,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    return calculateWritedownForPrincipal(cl, cl.balance(), timestamp, gracePeriodInDays, maxDaysLate);
  }

  function calculateWritedownForPrincipal(
    ICreditLine cl,
    uint256 principal,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    FixedPoint.Unsigned memory amountOwedPerDay = calculateAmountOwedForOneDay(cl);
    if (amountOwedPerDay.isEqual(0)) {
      return (0, 0);
    }
    FixedPoint.Unsigned memory fpGracePeriod = FixedPoint.fromUnscaledUint(gracePeriodInDays);
    FixedPoint.Unsigned memory daysLate;

    // Excel math: =min(1,max(0,periods_late_in_days-graceperiod_in_days)/MAX_ALLOWED_DAYS_LATE) grace_period = 30,
    // Before the term end date, we use the interestOwed to calculate the periods late. However, after the loan term
    // has ended, since the interest is a much smaller fraction of the principal, we cannot reliably use interest to
    // calculate the periods later.
    uint256 totalOwed = cl.interestOwed().add(cl.principalOwed());
    daysLate = FixedPoint.fromUnscaledUint(totalOwed).div(amountOwedPerDay);
    if (timestamp > cl.termEndTime()) {
      uint256 secondsLate = timestamp.sub(cl.termEndTime());
      daysLate = daysLate.add(FixedPoint.fromUnscaledUint(secondsLate).div(SECONDS_PER_DAY));
    }

    FixedPoint.Unsigned memory maxLate = FixedPoint.fromUnscaledUint(maxDaysLate);
    FixedPoint.Unsigned memory writedownPercent;
    if (daysLate.isLessThanOrEqual(fpGracePeriod)) {
      // Within the grace period, we don't have to write down, so assume 0%
      writedownPercent = FixedPoint.fromUnscaledUint(0);
    } else {
      writedownPercent = FixedPoint.min(FixedPoint.fromUnscaledUint(1), (daysLate.sub(fpGracePeriod)).div(maxLate));
    }

    FixedPoint.Unsigned memory writedownAmount = writedownPercent.mul(principal).div(FP_SCALING_FACTOR);
    // This will return a number between 0-100 representing the write down percent with no decimals
    uint256 unscaledWritedownPercent = writedownPercent.mul(100).div(FP_SCALING_FACTOR).rawValue;
    return (unscaledWritedownPercent, writedownAmount.rawValue);
  }

  function calculateAmountOwedForOneDay(ICreditLine cl) public view returns (FixedPoint.Unsigned memory interestOwed) {
    // Determine theoretical interestOwed for one full day
    uint256 totalInterestPerYear = cl.balance().mul(cl.interestApr()).div(INTEREST_DECIMALS);
    interestOwed = FixedPoint.fromUnscaledUint(totalInterestPerYear).div(365);
    return interestOwed;
  }

  function calculateInterestAccrued(
    CreditLine cl,
    uint256 balance,
    uint256 timestamp,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256) {
    // We use Math.min here to prevent integer overflow (ie. go negative) when calculating
    // numSecondsElapsed. Typically this shouldn't be possible, because
    // the interestAccruedAsOf couldn't be *after* the current timestamp. However, when assessing
    // we allow this function to be called with a past timestamp, which raises the possibility
    // of overflow.
    // This use of min should not generate incorrect interest calculations, since
    // this function's purpose is just to normalize balances, and handing in a past timestamp
    // will necessarily return zero interest accrued (because zero elapsed time), which is correct.
    uint256 startTime = Math.min(timestamp, cl.interestAccruedAsOf());
    return calculateInterestAccruedOverPeriod(cl, balance, startTime, timestamp, lateFeeGracePeriodInDays);
  }

  function calculateInterestAccruedOverPeriod(
    CreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256 interestOwed) {
    uint256 secondsElapsed = endTime.sub(startTime);
    uint256 totalInterestPerYear = balance.mul(cl.interestApr()).div(INTEREST_DECIMALS);
    interestOwed = totalInterestPerYear.mul(secondsElapsed).div(SECONDS_PER_YEAR);
    if (lateFeeApplicable(cl, endTime, lateFeeGracePeriodInDays)) {
      uint256 lateFeeInterestPerYear = balance.mul(cl.lateFeeApr()).div(INTEREST_DECIMALS);
      uint256 additionalLateFeeInterest = lateFeeInterestPerYear.mul(secondsElapsed).div(SECONDS_PER_YEAR);
      interestOwed = interestOwed.add(additionalLateFeeInterest);
    }

    return interestOwed;
  }

  function lateFeeApplicable(
    CreditLine cl,
    uint256 timestamp,
    uint256 gracePeriodInDays
  ) public view returns (bool) {
    uint256 secondsLate = timestamp.sub(cl.lastFullPaymentTime());
    return cl.lateFeeApr() > 0 && secondsLate > gracePeriodInDays.mul(SECONDS_PER_DAY);
  }

  function allocatePayment(
    uint256 paymentAmount,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) public pure returns (PaymentAllocation memory) {
    uint256 paymentRemaining = paymentAmount;
    uint256 interestPayment = Math.min(interestOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(interestPayment);

    uint256 principalPayment = Math.min(principalOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(principalPayment);

    uint256 balanceRemaining = balance.sub(principalPayment);
    uint256 additionalBalancePayment = Math.min(paymentRemaining, balanceRemaining);

    return
      PaymentAllocation({
        interestPayment: interestPayment,
        principalPayment: principalPayment,
        additionalBalancePayment: additionalBalancePayment
      });
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./GoldfinchConfig.sol";
import "./ConfigHelper.sol";
import "./BaseUpgradeablePausable.sol";
import "./Accountant.sol";
import "../../interfaces/IERC20withDec.sol";
import "../../interfaces/ICreditLine.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

/**
 * @title CreditLine
 * @notice A contract that represents the agreement between Backers and
 *  a Borrower. Includes the terms of the loan, as well as the current accounting state, such as interest owed.
 *  A CreditLine belongs to a TranchedPool, and is fully controlled by that TranchedPool. It does not
 *  operate in any standalone capacity. It should generally be considered internal to the TranchedPool.
 * @author Goldfinch
 */

// solhint-disable-next-line max-states-count
contract CreditLine is BaseUpgradeablePausable, ICreditLine {
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  // Credit line terms
  address public override borrower;
  uint256 public currentLimit;
  uint256 public override maxLimit;
  uint256 public override interestApr;
  uint256 public override paymentPeriodInDays;
  uint256 public override termInDays;
  uint256 public override principalGracePeriodInDays;
  uint256 public override lateFeeApr;

  // Accounting variables
  uint256 public override balance;
  uint256 public override interestOwed;
  uint256 public override principalOwed;
  uint256 public override termEndTime;
  uint256 public override nextDueTime;
  uint256 public override interestAccruedAsOf;
  uint256 public override lastFullPaymentTime;
  uint256 public totalInterestAccrued;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public initializer {
    require(_config != address(0) && owner != address(0) && _borrower != address(0), "Zero address passed in");
    __BaseUpgradeablePausable__init(owner);
    config = GoldfinchConfig(_config);
    borrower = _borrower;
    maxLimit = _maxLimit;
    interestApr = _interestApr;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lateFeeApr = _lateFeeApr;
    principalGracePeriodInDays = _principalGracePeriodInDays;
    interestAccruedAsOf = block.timestamp;

    // Unlock owner, which is a TranchedPool, for infinite amount
    bool success = config.getUSDC().approve(owner, uint256(-1));
    require(success, "Failed to approve USDC");
  }

  function limit() external view override returns (uint256) {
    return currentLimit;
  }

  /**
   * @notice Updates the internal accounting to track a drawdown as of current block timestamp.
   * Does not move any money
   * @param amount The amount in USDC that has been drawndown
   */
  function drawdown(uint256 amount) external onlyAdmin {
    require(amount.add(balance) <= currentLimit, "Cannot drawdown more than the limit");
    require(amount > 0, "Invalid drawdown amount");
    uint256 timestamp = currentTime();

    if (balance == 0) {
      setInterestAccruedAsOf(timestamp);
      setLastFullPaymentTime(timestamp);
      setTotalInterestAccrued(0);
      setTermEndTime(timestamp.add(SECONDS_PER_DAY.mul(termInDays)));
    }

    (uint256 _interestOwed, uint256 _principalOwed) = updateAndGetInterestAndPrincipalOwedAsOf(timestamp);
    balance = balance.add(amount);

    updateCreditLineAccounting(balance, _interestOwed, _principalOwed);
    require(!_isLate(timestamp), "Cannot drawdown when payments are past due");
  }

  /**
   * @notice Migrates to a new goldfinch config address
   */
  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  function setLateFeeApr(uint256 newLateFeeApr) external onlyAdmin {
    lateFeeApr = newLateFeeApr;
  }

  function setLimit(uint256 newAmount) external onlyAdmin {
    require(newAmount <= maxLimit, "Cannot be more than the max limit");
    currentLimit = newAmount;
  }

  function setMaxLimit(uint256 newAmount) external onlyAdmin {
    maxLimit = newAmount;
  }

  function termStartTime() external view returns (uint256) {
    return _termStartTime();
  }

  function isLate() external view override returns (bool) {
    return _isLate(block.timestamp);
  }

  function withinPrincipalGracePeriod() external view override returns (bool) {
    if (termEndTime == 0) {
      // Loan hasn't started yet
      return true;
    }
    return block.timestamp < _termStartTime().add(principalGracePeriodInDays.mul(SECONDS_PER_DAY));
  }

  function setTermEndTime(uint256 newTermEndTime) public onlyAdmin {
    termEndTime = newTermEndTime;
  }

  function setNextDueTime(uint256 newNextDueTime) public onlyAdmin {
    nextDueTime = newNextDueTime;
  }

  function setBalance(uint256 newBalance) public onlyAdmin {
    balance = newBalance;
  }

  function setTotalInterestAccrued(uint256 _totalInterestAccrued) public onlyAdmin {
    totalInterestAccrued = _totalInterestAccrued;
  }

  function setInterestOwed(uint256 newInterestOwed) public onlyAdmin {
    interestOwed = newInterestOwed;
  }

  function setPrincipalOwed(uint256 newPrincipalOwed) public onlyAdmin {
    principalOwed = newPrincipalOwed;
  }

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) public onlyAdmin {
    interestAccruedAsOf = newInterestAccruedAsOf;
  }

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) public onlyAdmin {
    lastFullPaymentTime = newLastFullPaymentTime;
  }

  /**
   * @notice Triggers an assessment of the creditline. Any USDC balance available in the creditline is applied
   * towards the interest and principal.
   * @return Any amount remaining after applying payments towards the interest and principal
   * @return Amount applied towards interest
   * @return Amount applied towards principal
   */
  function assess()
    public
    onlyAdmin
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Do not assess until a full period has elapsed or past due
    require(balance > 0, "Must have balance to assess credit line");

    // Don't assess credit lines early!
    if (currentTime() < nextDueTime && !_isLate(currentTime())) {
      return (0, 0, 0);
    }
    uint256 timeToAssess = calculateNextDueTime();
    setNextDueTime(timeToAssess);

    // We always want to assess for the most recently *past* nextDueTime.
    // So if the recalculation above sets the nextDueTime into the future,
    // then ensure we pass in the one just before this.
    if (timeToAssess > currentTime()) {
      uint256 secondsPerPeriod = paymentPeriodInDays.mul(SECONDS_PER_DAY);
      timeToAssess = timeToAssess.sub(secondsPerPeriod);
    }
    return handlePayment(getUSDCBalance(address(this)), timeToAssess);
  }

  function calculateNextDueTime() internal view returns (uint256) {
    uint256 newNextDueTime = nextDueTime;
    uint256 secondsPerPeriod = paymentPeriodInDays.mul(SECONDS_PER_DAY);
    uint256 curTimestamp = currentTime();
    // You must have just done your first drawdown
    if (newNextDueTime == 0 && balance > 0) {
      return curTimestamp.add(secondsPerPeriod);
    }

    // Active loan that has entered a new period, so return the *next* newNextDueTime.
    // But never return something after the termEndTime
    if (balance > 0 && curTimestamp >= newNextDueTime) {
      uint256 secondsToAdvance = (curTimestamp.sub(newNextDueTime).div(secondsPerPeriod)).add(1).mul(secondsPerPeriod);
      newNextDueTime = newNextDueTime.add(secondsToAdvance);
      return Math.min(newNextDueTime, termEndTime);
    }

    // You're paid off, or have not taken out a loan yet, so no next due time.
    if (balance == 0 && newNextDueTime != 0) {
      return 0;
    }
    // Active loan in current period, where we've already set the newNextDueTime correctly, so should not change.
    if (balance > 0 && curTimestamp < newNextDueTime) {
      return newNextDueTime;
    }
    revert("Error: could not calculate next due time.");
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _isLate(uint256 timestamp) internal view returns (bool) {
    uint256 secondsElapsedSinceFullPayment = timestamp.sub(lastFullPaymentTime);
    return balance > 0 && secondsElapsedSinceFullPayment > paymentPeriodInDays.mul(SECONDS_PER_DAY);
  }

  function _termStartTime() internal view returns (uint256) {
    return termEndTime.sub(SECONDS_PER_DAY.mul(termInDays));
  }

  /**
   * @notice Applies `amount` of payment for a given credit line. This moves already collected money into the Pool.
   *  It also updates all the accounting variables. Note that interest is always paid back first, then principal.
   *  Any extra after paying the minimum will go towards existing principal (reducing the
   *  effective interest rate). Any extra after the full loan has been paid off will remain in the
   *  USDC Balance of the creditLine, where it will be automatically used for the next drawdown.
   * @param paymentAmount The amount, in USDC atomic units, to be applied
   * @param timestamp The timestamp on which accrual calculations should be based. This allows us
   *  to be precise when we assess a Credit Line
   */
  function handlePayment(uint256 paymentAmount, uint256 timestamp)
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 newInterestOwed, uint256 newPrincipalOwed) = updateAndGetInterestAndPrincipalOwedAsOf(timestamp);
    Accountant.PaymentAllocation memory pa = Accountant.allocatePayment(
      paymentAmount,
      balance,
      newInterestOwed,
      newPrincipalOwed
    );

    uint256 newBalance = balance.sub(pa.principalPayment);
    // Apply any additional payment towards the balance
    newBalance = newBalance.sub(pa.additionalBalancePayment);
    uint256 totalPrincipalPayment = balance.sub(newBalance);
    uint256 paymentRemaining = paymentAmount.sub(pa.interestPayment).sub(totalPrincipalPayment);

    updateCreditLineAccounting(
      newBalance,
      newInterestOwed.sub(pa.interestPayment),
      newPrincipalOwed.sub(pa.principalPayment)
    );

    assert(paymentRemaining.add(pa.interestPayment).add(totalPrincipalPayment) == paymentAmount);

    return (paymentRemaining, pa.interestPayment, totalPrincipalPayment);
  }

  function updateAndGetInterestAndPrincipalOwedAsOf(uint256 timestamp) internal returns (uint256, uint256) {
    (uint256 interestAccrued, uint256 principalAccrued) = Accountant.calculateInterestAndPrincipalAccrued(
      this,
      timestamp,
      config.getLatenessGracePeriodInDays()
    );
    if (interestAccrued > 0) {
      // If we've accrued any interest, update interestAccruedAsOf to the time that we've
      // calculated interest for. If we've not accrued any interest, then we keep the old value so the next
      // time the entire period is taken into account.
      setInterestAccruedAsOf(timestamp);
      totalInterestAccrued = totalInterestAccrued.add(interestAccrued);
    }
    return (interestOwed.add(interestAccrued), principalOwed.add(principalAccrued));
  }

  function updateCreditLineAccounting(
    uint256 newBalance,
    uint256 newInterestOwed,
    uint256 newPrincipalOwed
  ) internal nonReentrant {
    setBalance(newBalance);
    setInterestOwed(newInterestOwed);
    setPrincipalOwed(newPrincipalOwed);

    // This resets lastFullPaymentTime. These conditions assure that they have
    // indeed paid off all their interest and they have a real nextDueTime. (ie. creditline isn't pre-drawdown)
    uint256 _nextDueTime = nextDueTime;
    if (newInterestOwed == 0 && _nextDueTime != 0) {
      // If interest was fully paid off, then set the last full payment as the previous due time
      uint256 mostRecentLastDueTime;
      if (currentTime() < _nextDueTime) {
        uint256 secondsPerPeriod = paymentPeriodInDays.mul(SECONDS_PER_DAY);
        mostRecentLastDueTime = _nextDueTime.sub(secondsPerPeriod);
      } else {
        mostRecentLastDueTime = _nextDueTime;
      }
      setLastFullPaymentTime(mostRecentLastDueTime);
    }

    setNextDueTime(calculateNextDueTime());
  }

  function getUSDCBalance(address _address) internal view returns (uint256) {
    return config.getUSDC().balanceOf(_address);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
// solhint-disable
// Imported from https://github.com/UMAprotocol/protocol/blob/4d1c8cc47a4df5e79f978cb05647a7432e111a3d/packages/core/contracts/common/implementation/FixedPoint.sol
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
  // For unsigned values:
  //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
  uint256 private constant FP_SCALING_FACTOR = 10**18;

  // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
  struct Unsigned {
    uint256 rawValue;
  }

  /**
   * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5**18`.
   * @param a uint to convert into a FixedPoint.
   * @return the converted FixedPoint.
   */
  function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
    return Unsigned(a.mul(FP_SCALING_FACTOR));
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if equal, or False.
   */
  function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if equal, or False.
   */
  function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue == b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue > fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue >= fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue < fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a < b`, or False.
   */
  function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue <= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue <= fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue <= b.rawValue;
  }

  /**
   * @notice The minimum of `a` and `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the minimum of `a` and `b`.
   */
  function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return a.rawValue < b.rawValue ? a : b;
  }

  /**
   * @notice The maximum of `a` and `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the maximum of `a` and `b`.
   */
  function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return a.rawValue > b.rawValue ? a : b;
  }

  /**
   * @notice Adds two `Unsigned`s, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the sum of `a` and `b`.
   */
  function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.add(b.rawValue));
  }

  /**
   * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return the sum of `a` and `b`.
   */
  function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return add(a, fromUnscaledUint(b));
  }

  /**
   * @notice Subtracts two `Unsigned`s, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the difference of `a` and `b`.
   */
  function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.sub(b.rawValue));
  }

  /**
   * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return the difference of `a` and `b`.
   */
  function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return sub(a, fromUnscaledUint(b));
  }

  /**
   * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return the difference of `a` and `b`.
   */
  function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return sub(fromUnscaledUint(a), b);
  }

  /**
   * @notice Multiplies two `Unsigned`s, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the product of `a` and `b`.
   */
  function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as a uint256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FP_SCALING_FACTOR != 0.
    return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
  }

  /**
   * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return the product of `a` and `b`.
   */
  function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.mul(b));
  }

  /**
   * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the product of `a` and `b`.
   */
  function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    uint256 mulRaw = a.rawValue.mul(b.rawValue);
    uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
    uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
    if (mod != 0) {
      return Unsigned(mulFloor.add(1));
    } else {
      return Unsigned(mulFloor);
    }
  }

  /**
   * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the product of `a` and `b`.
   */
  function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    // Since b is an int, there is no risk of truncation and we can just mul it normally
    return Unsigned(a.rawValue.mul(b));
  }

  /**
   * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as a uint256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
  }

  /**
   * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b a uint256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.div(b));
  }

  /**
   * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a uint256 numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return div(fromUnscaledUint(a), b);
  }

  /**
   * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
    uint256 divFloor = aScaled.div(b.rawValue);
    uint256 mod = aScaled.mod(b.rawValue);
    if (mod != 0) {
      return Unsigned(divFloor.add(1));
    } else {
      return Unsigned(divFloor);
    }
  }

  /**
   * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b a uint256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
    // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
    // This creates the possibility of overflow if b is very large.
    return divCeil(a, fromUnscaledUint(b));
  }

  /**
   * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
   * @dev This will "floor" the result.
   * @param a a FixedPoint numerator.
   * @param b a uint256 denominator.
   * @return output is `a` to the power of `b`.
   */
  function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
    output = fromUnscaledUint(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }

  // ------------------------------------------------- SIGNED -------------------------------------------------------------
  // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
  // For signed values:
  //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
  int256 private constant SFP_SCALING_FACTOR = 10**18;

  struct Signed {
    int256 rawValue;
  }

  function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
    require(a.rawValue >= 0, "Negative value provided");
    return Unsigned(uint256(a.rawValue));
  }

  function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
    require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
    return Signed(int256(a.rawValue));
  }

  /**
   * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5**18`.
   * @param a int to convert into a FixedPoint.Signed.
   * @return the converted FixedPoint.Signed.
   */
  function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
    return Signed(a.mul(SFP_SCALING_FACTOR));
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a int256.
   * @return True if equal, or False.
   */
  function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if equal, or False.
   */
  function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue == b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue > fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue >= fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue < fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a < b`, or False.
   */
  function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue <= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue <= fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue <= b.rawValue;
  }

  /**
   * @notice The minimum of `a` and `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the minimum of `a` and `b`.
   */
  function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return a.rawValue < b.rawValue ? a : b;
  }

  /**
   * @notice The maximum of `a` and `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the maximum of `a` and `b`.
   */
  function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return a.rawValue > b.rawValue ? a : b;
  }

  /**
   * @notice Adds two `Signed`s, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the sum of `a` and `b`.
   */
  function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.add(b.rawValue));
  }

  /**
   * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return the sum of `a` and `b`.
   */
  function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return add(a, fromUnscaledInt(b));
  }

  /**
   * @notice Subtracts two `Signed`s, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the difference of `a` and `b`.
   */
  function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.sub(b.rawValue));
  }

  /**
   * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return the difference of `a` and `b`.
   */
  function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return sub(a, fromUnscaledInt(b));
  }

  /**
   * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return the difference of `a` and `b`.
   */
  function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
    return sub(fromUnscaledInt(a), b);
  }

  /**
   * @notice Multiplies two `Signed`s, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the product of `a` and `b`.
   */
  function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as an int256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
    return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
  }

  /**
   * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return the product of `a` and `b`.
   */
  function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.mul(b));
  }

  /**
   * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the product of `a` and `b`.
   */
  function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    int256 mulRaw = a.rawValue.mul(b.rawValue);
    int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
    // Manual mod because SignedSafeMath doesn't support it.
    int256 mod = mulRaw % SFP_SCALING_FACTOR;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(mulTowardsZero.add(valueToAdd));
    } else {
      return Signed(mulTowardsZero);
    }
  }

  /**
   * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the product of `a` and `b`.
   */
  function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
    // Since b is an int, there is no risk of truncation and we can just mul it normally
    return Signed(a.rawValue.mul(b));
  }

  /**
   * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as an int256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
  }

  /**
   * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b an int256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.div(b));
  }

  /**
   * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a an int256 numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
    return div(fromUnscaledInt(a), b);
  }

  /**
   * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
    int256 divTowardsZero = aScaled.div(b.rawValue);
    // Manual mod because SignedSafeMath doesn't support it.
    int256 mod = aScaled % b.rawValue;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(divTowardsZero.add(valueToAdd));
    } else {
      return Signed(divTowardsZero);
    }
  }

  /**
   * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b an int256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
    // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
    // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
    // This creates the possibility of overflow if b is very large.
    return divAwayFromZero(a, fromUnscaledInt(b));
  }

  /**
   * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
   * @dev This will "floor" the result.
   * @param a a FixedPoint.Signed.
   * @param b a uint256 (negative exponents are not allowed).
   * @return output is `a` to the power of `b`.
   */
  function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
    output = fromUnscaledInt(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20withDec.sol";
import "../protocol/core/GoldfinchConfig.sol";
import "../protocol/core/ConfigHelper.sol";
import "../protocol/core/TranchedPool.sol";

contract TestTranchedPool is TranchedPool {
  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) public {
    collectInterestAndPrincipal(from, interest, principal);
  }

  function _setSeniorTranchePrincipalDeposited(uint256 principalDeposited) public {
    poolSlices[poolSlices.length - 1].seniorTranche.principalDeposited = principalDeposited;
  }

  function _setLimit(uint256 limit) public {
    creditLine.setLimit(limit);
  }

  function _modifyJuniorTrancheLockedUntil(uint256 lockedUntil) public {
    poolSlices[poolSlices.length - 1].juniorTranche.lockedUntil = lockedUntil;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "../../interfaces/ITranchedPool.sol";
import "../../interfaces/IERC20withDec.sol";
import "../../interfaces/IV2CreditLine.sol";
import "../../interfaces/IPoolTokens.sol";
import "./GoldfinchConfig.sol";
import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "../../library/SafeERC20Transfer.sol";
import "./TranchingLogic.sol";

contract TranchedPool is BaseUpgradeablePausable, ITranchedPool, SafeERC20Transfer {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using TranchingLogic for PoolSlice;
  using TranchingLogic for TrancheInfo;

  bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
  bytes32 public constant SENIOR_ROLE = keccak256("SENIOR_ROLE");
  uint256 public constant FP_SCALING_FACTOR = 1e18;
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;
  uint256 public constant ONE_HUNDRED = 100; // Need this because we cannot call .div on a literal 100
  uint256 public constant NUM_TRANCHES_PER_SLICE = 2;
  uint256 public juniorFeePercent;
  bool public drawdownsPaused;
  uint256[] public allowedUIDTypes;
  uint256 public totalDeployed;
  uint256 public fundableAt;

  PoolSlice[] public poolSlices;

  event DepositMade(address indexed owner, uint256 indexed tranche, uint256 indexed tokenId, uint256 amount);
  event WithdrawalMade(
    address indexed owner,
    uint256 indexed tranche,
    uint256 indexed tokenId,
    uint256 interestWithdrawn,
    uint256 principalWithdrawn
  );

  event GoldfinchConfigUpdated(address indexed who, address configAddress);
  event TranchedPoolAssessed(address indexed pool);
  event PaymentApplied(
    address indexed payer,
    address indexed pool,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount,
    uint256 reserveAmount
  );
  // Note: This has to exactly match the even in the TranchingLogic library for events to be emitted
  // correctly
  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );
  event ReserveFundsCollected(address indexed from, uint256 amount);
  event CreditLineMigrated(address indexed oldCreditLine, address indexed newCreditLine);
  event DrawdownMade(address indexed borrower, uint256 amount);
  event DrawdownsPaused(address indexed pool);
  event DrawdownsUnpaused(address indexed pool);
  event EmergencyShutdown(address indexed pool);
  event TrancheLocked(address indexed pool, uint256 trancheId, uint256 lockedUntil);
  event SliceCreated(address indexed pool, uint256 sliceId);

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public override initializer {
    require(address(_config) != address(0) && address(_borrower) != address(0), "Config/borrower invalid");

    config = GoldfinchConfig(_config);
    address owner = config.protocolAdminAddress();
    require(owner != address(0), "Owner invalid");
    __BaseUpgradeablePausable__init(owner);
    _initializeNextSlice(_fundableAt);
    createAndSetCreditLine(
      _borrower,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );

    createdAt = block.timestamp;
    juniorFeePercent = _juniorFeePercent;
    if (_allowedUIDTypes.length == 0) {
      uint256[1] memory defaultAllowedUIDTypes = [config.getGo().ID_TYPE_0()];
      allowedUIDTypes = defaultAllowedUIDTypes;
    } else {
      allowedUIDTypes = _allowedUIDTypes;
    }

    _setupRole(LOCKER_ROLE, _borrower);
    _setupRole(LOCKER_ROLE, owner);
    _setRoleAdmin(LOCKER_ROLE, OWNER_ROLE);
    _setRoleAdmin(SENIOR_ROLE, OWNER_ROLE);

    // Give the senior pool the ability to deposit into the senior pool
    _setupRole(SENIOR_ROLE, address(config.getSeniorPool()));

    // Unlock self for infinite amount
    bool success = config.getUSDC().approve(address(this), uint256(-1));
    require(success, "Failed to approve USDC");
  }

  function setAllowedUIDTypes(uint256[] calldata ids) public onlyLocker {
    require(
      poolSlices[0].juniorTranche.principalDeposited == 0 && poolSlices[0].seniorTranche.principalDeposited == 0,
      "Must not have balance"
    );
    allowedUIDTypes = ids;
  }

  /**
   * @notice Deposit a USDC amount into the pool for a tranche. Mints an NFT to the caller representing the position
   * @param tranche The number representing the tranche to deposit into
   * @param amount The USDC amount to tranfer from the caller to the pool
   * @return tokenId The tokenId of the NFT
   */
  function deposit(uint256 tranche, uint256 amount)
    public
    override
    nonReentrant
    whenNotPaused
    returns (uint256 tokenId)
  {
    TrancheInfo storage trancheInfo = getTrancheInfo(tranche);
    require(trancheInfo.lockedUntil == 0, "Tranche locked");
    require(amount > 0, "Must deposit > zero");
    require(config.getGo().goOnlyIdTypes(msg.sender, allowedUIDTypes), "Address not go-listed");
    require(block.timestamp > fundableAt, "Not open for funding");
    // senior tranche ids are always odd numbered
    if (_isSeniorTrancheId(trancheInfo.id)) {
      require(hasRole(SENIOR_ROLE, _msgSender()), "Req SENIOR_ROLE");
    }

    trancheInfo.principalDeposited = trancheInfo.principalDeposited.add(amount);
    IPoolTokens.MintParams memory params = IPoolTokens.MintParams({tranche: tranche, principalAmount: amount});
    tokenId = config.getPoolTokens().mint(params, msg.sender);
    safeERC20TransferFrom(config.getUSDC(), msg.sender, address(this), amount);
    emit DepositMade(msg.sender, tranche, tokenId, amount);
    return tokenId;
  }

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override returns (uint256 tokenId) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(tranche, amount);
  }

  /**
   * @notice Withdraw an already deposited amount if the funds are available
   * @param tokenId The NFT representing the position
   * @param amount The amount to withdraw (must be <= interest+principal currently available to withdraw)
   * @return interestWithdrawn The interest amount that was withdrawn
   * @return principalWithdrawn The principal amount that was withdrawn
   */
  function withdraw(uint256 tokenId, uint256 amount)
    public
    override
    nonReentrant
    whenNotPaused
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = getTrancheInfo(tokenInfo.tranche);

    return _withdraw(trancheInfo, tokenInfo, tokenId, amount);
  }

  /**
   * @notice Withdraw from many tokens (that the sender owns) in a single transaction
   * @param tokenIds An array of tokens ids representing the position
   * @param amounts An array of amounts to withdraw from the corresponding tokenIds
   */
  function withdrawMultiple(uint256[] calldata tokenIds, uint256[] calldata amounts) public override {
    require(tokenIds.length == amounts.length, "TokensIds and Amounts mismatch");

    for (uint256 i = 0; i < amounts.length; i++) {
      withdraw(tokenIds[i], amounts[i]);
    }
  }

  /**
   * @notice Similar to withdraw but will withdraw all available funds
   * @param tokenId The NFT representing the position
   * @return interestWithdrawn The interest amount that was withdrawn
   * @return principalWithdrawn The principal amount that was withdrawn
   */
  function withdrawMax(uint256 tokenId)
    external
    override
    nonReentrant
    whenNotPaused
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = getTrancheInfo(tokenInfo.tranche);

    (uint256 interestRedeemable, uint256 principalRedeemable) = redeemableInterestAndPrincipal(trancheInfo, tokenInfo);

    uint256 amount = interestRedeemable.add(principalRedeemable);

    return _withdraw(trancheInfo, tokenInfo, tokenId, amount);
  }

  /**
   * @notice Draws down the funds (and locks the pool) to the borrower address. Can only be called by the borrower
   * @param amount The amount to drawdown from the creditline (must be < limit)
   */
  function drawdown(uint256 amount) external override onlyLocker whenNotPaused {
    require(!drawdownsPaused, "Drawdowns are paused");
    if (!locked()) {
      // Assumes the senior pool has invested already (saves the borrower a separate transaction to lock the pool)
      _lockPool();
    }
    // Drawdown only draws down from the current slice for simplicity. It's harder to account for how much
    // money is available from previous slices since depositors can redeem after unlock.
    PoolSlice storage currentSlice = poolSlices[poolSlices.length.sub(1)];
    uint256 amountAvailable = sharePriceToUsdc(
      currentSlice.juniorTranche.principalSharePrice,
      currentSlice.juniorTranche.principalDeposited
    );
    amountAvailable = amountAvailable.add(
      sharePriceToUsdc(currentSlice.seniorTranche.principalSharePrice, currentSlice.seniorTranche.principalDeposited)
    );

    require(amount <= amountAvailable, "Insufficient funds in slice");

    creditLine.drawdown(amount);

    // Update the share price to reflect the amount remaining in the pool
    uint256 amountRemaining = amountAvailable.sub(amount);
    uint256 oldJuniorPrincipalSharePrice = currentSlice.juniorTranche.principalSharePrice;
    uint256 oldSeniorPrincipalSharePrice = currentSlice.seniorTranche.principalSharePrice;
    currentSlice.juniorTranche.principalSharePrice = currentSlice.juniorTranche.calculateExpectedSharePrice(
      amountRemaining,
      currentSlice
    );
    currentSlice.seniorTranche.principalSharePrice = currentSlice.seniorTranche.calculateExpectedSharePrice(
      amountRemaining,
      currentSlice
    );
    currentSlice.principalDeployed = currentSlice.principalDeployed.add(amount);
    totalDeployed = totalDeployed.add(amount);

    address borrower = creditLine.borrower();
    safeERC20TransferFrom(config.getUSDC(), address(this), borrower, amount);
    emit DrawdownMade(borrower, amount);
    emit SharePriceUpdated(
      address(this),
      currentSlice.juniorTranche.id,
      currentSlice.juniorTranche.principalSharePrice,
      int256(oldJuniorPrincipalSharePrice.sub(currentSlice.juniorTranche.principalSharePrice)) * -1,
      currentSlice.juniorTranche.interestSharePrice,
      0
    );
    emit SharePriceUpdated(
      address(this),
      currentSlice.seniorTranche.id,
      currentSlice.seniorTranche.principalSharePrice,
      int256(oldSeniorPrincipalSharePrice.sub(currentSlice.seniorTranche.principalSharePrice)) * -1,
      currentSlice.seniorTranche.interestSharePrice,
      0
    );
  }

  /**
   * @notice Locks the junior tranche, preventing more junior deposits. Gives time for the senior to determine how
   * much to invest (ensure leverage ratio cannot change for the period)
   */
  function lockJuniorCapital() external override onlyLocker whenNotPaused {
    _lockJuniorCapital(poolSlices.length.sub(1));
  }

  /**
   * @notice Locks the pool (locks both senior and junior tranches and starts the drawdown period). Beyond the drawdown
   * period, any unused capital is available to withdraw by all depositors
   */
  function lockPool() external override onlyLocker whenNotPaused {
    _lockPool();
  }

  function setFundableAt(uint256 newFundableAt) external override onlyLocker {
    fundableAt = newFundableAt;
  }

  function initializeNextSlice(uint256 _fundableAt) external override onlyLocker whenNotPaused {
    require(locked(), "Current slice still active");
    require(!creditLine.isLate(), "Creditline is late");
    require(creditLine.withinPrincipalGracePeriod(), "Beyond principal grace period");
    _initializeNextSlice(_fundableAt);
    emit SliceCreated(address(this), poolSlices.length.sub(1));
  }

  /**
   * @notice Triggers an assessment of the creditline and the applies the payments according the tranche waterfall
   */
  function assess() external override whenNotPaused {
    _assess();
  }

  /**
   * @notice Allows repaying the creditline. Collects the USDC amount from the sender and triggers an assess
   * @param amount The amount to repay
   */
  function pay(uint256 amount) external override whenNotPaused {
    require(amount > 0, "Must pay more than zero");
    collectPayment(amount);
    _assess();
  }

  /**
   * @notice Migrates to a new goldfinch config address
   */
  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    creditLine.updateGoldfinchConfig();
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Pauses the pool and sweeps any remaining funds to the treasury reserve.
   */
  function emergencyShutdown() public onlyAdmin {
    if (!paused()) {
      pause();
    }

    IERC20withDec usdc = config.getUSDC();
    address reserveAddress = config.reserveAddress();
    // Sweep any funds to community reserve
    uint256 poolBalance = usdc.balanceOf(address(this));
    if (poolBalance > 0) {
      safeERC20Transfer(usdc, reserveAddress, poolBalance);
    }

    uint256 clBalance = usdc.balanceOf(address(creditLine));
    if (clBalance > 0) {
      safeERC20TransferFrom(usdc, address(creditLine), reserveAddress, clBalance);
    }
    emit EmergencyShutdown(address(this));
  }

  /**
   * @notice Pauses all drawdowns (but not deposits/withdraws)
   */
  function pauseDrawdowns() public onlyAdmin {
    drawdownsPaused = true;
    emit DrawdownsPaused(address(this));
  }

  /**
   * @notice Unpause drawdowns
   */
  function unpauseDrawdowns() public onlyAdmin {
    drawdownsPaused = false;
    emit DrawdownsUnpaused(address(this));
  }

  /**
   * @notice Migrates the accounting variables from the current creditline to a brand new one
   * @param _borrower The borrower address
   * @param _maxLimit The new max limit
   * @param _interestApr The new interest APR
   * @param _paymentPeriodInDays The new payment period in days
   * @param _termInDays The new term in days
   * @param _lateFeeApr The new late fee APR
   */
  function migrateCreditLine(
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public onlyAdmin {
    require(_borrower != address(0), "Borrower must not be empty");
    require(_paymentPeriodInDays != 0, "Payment period invalid");
    require(_termInDays != 0, "Term must not be empty");

    address originalClAddr = address(creditLine);

    createAndSetCreditLine(
      _borrower,
      _maxLimit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );

    address newClAddr = address(creditLine);
    TranchingLogic.migrateAccountingVariables(originalClAddr, newClAddr);
    TranchingLogic.closeCreditLine(originalClAddr);
    address originalBorrower = IV2CreditLine(originalClAddr).borrower();
    address newBorrower = IV2CreditLine(newClAddr).borrower();
    // Ensure Roles
    if (originalBorrower != newBorrower) {
      revokeRole(LOCKER_ROLE, originalBorrower);
      grantRole(LOCKER_ROLE, newBorrower);
    }
    // Transfer any funds to new CL
    uint256 clBalance = config.getUSDC().balanceOf(originalClAddr);
    if (clBalance > 0) {
      safeERC20TransferFrom(config.getUSDC(), originalClAddr, newClAddr, clBalance);
    }
    emit CreditLineMigrated(originalClAddr, newClAddr);
  }

  /**
   * @notice Migrates to a new creditline without copying the accounting variables
   */
  function migrateAndSetNewCreditLine(address newCl) public onlyAdmin {
    require(newCl != address(0), "Creditline cannot be empty");
    address originalClAddr = address(creditLine);
    // Transfer any funds to new CL
    uint256 clBalance = config.getUSDC().balanceOf(originalClAddr);
    if (clBalance > 0) {
      safeERC20TransferFrom(config.getUSDC(), originalClAddr, newCl, clBalance);
    }
    TranchingLogic.closeCreditLine(originalClAddr);
    // set new CL
    creditLine = IV2CreditLine(newCl);
    // sanity check that the new address is in fact a creditline
    creditLine.limit();

    emit CreditLineMigrated(originalClAddr, address(creditLine));
  }

  // CreditLine proxy method
  function setLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setLimit(newAmount);
  }

  function setMaxLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setMaxLimit(newAmount);
  }

  function getTranche(uint256 tranche) public view override returns (TrancheInfo memory) {
    return getTrancheInfo(tranche);
  }

  function numSlices() public view returns (uint256) {
    return poolSlices.length;
  }

  /**
   * @notice Converts USDC amounts to share price
   * @param amount The USDC amount to convert
   * @param totalShares The total shares outstanding
   * @return The share price of the input amount
   */
  function usdcToSharePrice(uint256 amount, uint256 totalShares) public pure returns (uint256) {
    return TranchingLogic.usdcToSharePrice(amount, totalShares);
  }

  /**
   * @notice Converts share price to USDC amounts
   * @param sharePrice The share price to convert
   * @param totalShares The total shares outstanding
   * @return The USDC amount of the input share price
   */
  function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares) public pure returns (uint256) {
    return TranchingLogic.sharePriceToUsdc(sharePrice, totalShares);
  }

  /**
   * @notice Returns the total junior capital deposited
   * @return The total USDC amount deposited into all junior tranches
   */
  function totalJuniorDeposits() external view override returns (uint256) {
    uint256 total;
    for (uint256 i = 0; i < poolSlices.length; i++) {
      total = total.add(poolSlices[i].juniorTranche.principalDeposited);
    }
    return total;
  }

  /**
   * @notice Determines the amount of interest and principal redeemable by a particular tokenId
   * @param tokenId The token representing the position
   * @return interestRedeemable The interest available to redeem
   * @return principalRedeemable The principal available to redeem
   */
  function availableToWithdraw(uint256 tokenId)
    public
    view
    override
    returns (uint256 interestRedeemable, uint256 principalRedeemable)
  {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = getTrancheInfo(tokenInfo.tranche);

    if (currentTime() > trancheInfo.lockedUntil) {
      return redeemableInterestAndPrincipal(trancheInfo, tokenInfo);
    } else {
      return (0, 0);
    }
  }

  /* Internal functions  */

  function _withdraw(
    TrancheInfo storage trancheInfo,
    IPoolTokens.TokenInfo memory tokenInfo,
    uint256 tokenId,
    uint256 amount
  ) internal returns (uint256 interestWithdrawn, uint256 principalWithdrawn) {
    require(config.getPoolTokens().isApprovedOrOwner(msg.sender, tokenId), "Not token owner");
    require(config.getGo().goOnlyIdTypes(msg.sender, allowedUIDTypes), "Address not go-listed");
    require(amount > 0, "Must withdraw more than zero");
    (uint256 interestRedeemable, uint256 principalRedeemable) = redeemableInterestAndPrincipal(trancheInfo, tokenInfo);
    uint256 netRedeemable = interestRedeemable.add(principalRedeemable);

    require(amount <= netRedeemable, "Invalid redeem amount");
    require(currentTime() > trancheInfo.lockedUntil, "Tranche is locked");

    // If the tranche has not been locked, ensure the deposited amount is correct
    if (trancheInfo.lockedUntil == 0) {
      trancheInfo.principalDeposited = trancheInfo.principalDeposited.sub(amount);
    }

    uint256 interestToRedeem = Math.min(interestRedeemable, amount);
    uint256 principalToRedeem = Math.min(principalRedeemable, amount.sub(interestToRedeem));

    config.getPoolTokens().redeem(tokenId, principalToRedeem, interestToRedeem);
    safeERC20TransferFrom(config.getUSDC(), address(this), msg.sender, principalToRedeem.add(interestToRedeem));

    emit WithdrawalMade(msg.sender, tokenInfo.tranche, tokenId, interestToRedeem, principalToRedeem);

    return (interestToRedeem, principalToRedeem);
  }

  function _isSeniorTrancheId(uint256 trancheId) internal pure returns (bool) {
    return trancheId.mod(NUM_TRANCHES_PER_SLICE) == 1;
  }

  function redeemableInterestAndPrincipal(TrancheInfo storage trancheInfo, IPoolTokens.TokenInfo memory tokenInfo)
    internal
    view
    returns (uint256 interestRedeemable, uint256 principalRedeemable)
  {
    // This supports withdrawing before or after locking because principal share price starts at 1
    // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
    uint256 maxPrincipalRedeemable = sharePriceToUsdc(trancheInfo.principalSharePrice, tokenInfo.principalAmount);
    // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
    // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
    uint256 maxInterestRedeemable = sharePriceToUsdc(trancheInfo.interestSharePrice, tokenInfo.principalAmount);

    interestRedeemable = maxInterestRedeemable.sub(tokenInfo.interestRedeemed);
    principalRedeemable = maxPrincipalRedeemable.sub(tokenInfo.principalRedeemed);

    return (interestRedeemable, principalRedeemable);
  }

  function _lockJuniorCapital(uint256 sliceId) internal {
    require(!locked(), "Pool already locked");
    require(poolSlices[sliceId].juniorTranche.lockedUntil == 0, "Junior tranche already locked");

    uint256 lockedUntil = currentTime().add(config.getDrawdownPeriodInSeconds());
    poolSlices[sliceId].juniorTranche.lockedUntil = lockedUntil;

    emit TrancheLocked(address(this), poolSlices[sliceId].juniorTranche.id, lockedUntil);
  }

  function _lockPool() internal {
    uint256 sliceId = poolSlices.length.sub(1);

    require(poolSlices[sliceId].juniorTranche.lockedUntil > 0, "Junior tranche must be locked");
    // Allow locking the pool only once; do not allow extending the lock of an
    // already-locked pool. Otherwise the locker could keep the pool locked
    // indefinitely, preventing withdrawals.
    require(poolSlices[sliceId].seniorTranche.lockedUntil == 0, "Lock cannot be extended");

    uint256 currentTotal = poolSlices[sliceId].juniorTranche.principalDeposited.add(
      poolSlices[sliceId].seniorTranche.principalDeposited
    );
    creditLine.setLimit(Math.min(creditLine.limit().add(currentTotal), creditLine.maxLimit()));

    // We start the drawdown period, so backers can withdraw unused capital after borrower draws down
    uint256 lockPeriod = config.getDrawdownPeriodInSeconds();
    poolSlices[sliceId].seniorTranche.lockedUntil = currentTime().add(lockPeriod);
    poolSlices[sliceId].juniorTranche.lockedUntil = currentTime().add(lockPeriod);
    emit TrancheLocked(
      address(this),
      poolSlices[sliceId].seniorTranche.id,
      poolSlices[sliceId].seniorTranche.lockedUntil
    );
    emit TrancheLocked(
      address(this),
      poolSlices[sliceId].juniorTranche.id,
      poolSlices[sliceId].juniorTranche.lockedUntil
    );
  }

  function _initializeNextSlice(uint256 newFundableAt) internal {
    uint256 numSlices = poolSlices.length;
    require(numSlices < 5, "Cannot exceed 5 slices");
    poolSlices.push(
      PoolSlice({
        seniorTranche: TrancheInfo({
          id: numSlices.mul(NUM_TRANCHES_PER_SLICE).add(1),
          principalSharePrice: usdcToSharePrice(1, 1),
          interestSharePrice: 0,
          principalDeposited: 0,
          lockedUntil: 0
        }),
        juniorTranche: TrancheInfo({
          id: numSlices.mul(NUM_TRANCHES_PER_SLICE).add(2),
          principalSharePrice: usdcToSharePrice(1, 1),
          interestSharePrice: 0,
          principalDeposited: 0,
          lockedUntil: 0
        }),
        totalInterestAccrued: 0,
        principalDeployed: 0
      })
    );
    fundableAt = newFundableAt;
  }

  function collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal returns (uint256 totalReserveAmount) {
    safeERC20TransferFrom(config.getUSDC(), from, address(this), principal.add(interest), "Failed to collect payment");
    uint256 reserveFeePercent = ONE_HUNDRED.div(config.getReserveDenominator()); // Convert the denonminator to percent

    ApplyResult memory result = TranchingLogic.applyToAllSeniorTranches(
      poolSlices,
      interest,
      principal,
      reserveFeePercent,
      totalDeployed,
      creditLine,
      juniorFeePercent
    );

    totalReserveAmount = result.reserveDeduction.add(
      TranchingLogic.applyToAllJuniorTranches(
        poolSlices,
        result.interestRemaining,
        result.principalRemaining,
        reserveFeePercent,
        totalDeployed,
        creditLine
      )
    );

    sendToReserve(totalReserveAmount);
    return totalReserveAmount;
  }

  // If the senior tranche of the current slice is locked, then the pool is not open to any more deposits
  // (could throw off leverage ratio)
  function locked() internal view returns (bool) {
    return poolSlices[poolSlices.length.sub(1)].seniorTranche.lockedUntil > 0;
  }

  function createAndSetCreditLine(
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) internal {
    address _creditLine = config.getGoldfinchFactory().createCreditLine();
    creditLine = IV2CreditLine(_creditLine);
    creditLine.initialize(
      address(config),
      address(this), // Set self as the owner
      _borrower,
      _maxLimit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );
  }

  function getTrancheInfo(uint256 trancheId) internal view returns (TrancheInfo storage) {
    require(trancheId > 0 && trancheId <= poolSlices.length.mul(NUM_TRANCHES_PER_SLICE), "Unsupported tranche");
    uint256 sliceId = ((trancheId.add(trancheId.mod(NUM_TRANCHES_PER_SLICE))).div(NUM_TRANCHES_PER_SLICE)).sub(1);
    PoolSlice storage slice = poolSlices[sliceId];
    TrancheInfo storage trancheInfo = trancheId.mod(NUM_TRANCHES_PER_SLICE) == 1
      ? slice.seniorTranche
      : slice.juniorTranche;
    return trancheInfo;
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function sendToReserve(uint256 amount) internal {
    emit ReserveFundsCollected(address(this), amount);
    safeERC20TransferFrom(
      config.getUSDC(),
      address(this),
      config.reserveAddress(),
      amount,
      "Failed to send to reserve"
    );
  }

  function collectPayment(uint256 amount) internal {
    safeERC20TransferFrom(config.getUSDC(), msg.sender, address(creditLine), amount, "Failed to collect payment");
  }

  function _assess() internal {
    // We need to make sure the pool is locked before we allocate rewards to ensure it's not
    // possible to game rewards by sandwiching an interest payment to an unlocked pool
    // It also causes issues trying to allocate payments to an empty slice (divide by zero)
    require(locked(), "Pool is not locked");

    uint256 interestAccrued = creditLine.totalInterestAccrued();
    (uint256 paymentRemaining, uint256 interestPayment, uint256 principalPayment) = creditLine.assess();
    interestAccrued = creditLine.totalInterestAccrued().sub(interestAccrued);

    // Split the interest accrued proportionally across slices so we know how much interest goes to each slice
    // We need this because the slice start at different times, so we cannot retroactively allocate the interest
    // linearly
    uint256[] memory principalPaymentsPerSlice = new uint256[](poolSlices.length);
    for (uint256 i = 0; i < poolSlices.length; i++) {
      uint256 interestForSlice = TranchingLogic.scaleByFraction(
        interestAccrued,
        poolSlices[i].principalDeployed,
        totalDeployed
      );
      principalPaymentsPerSlice[i] = TranchingLogic.scaleByFraction(
        principalPayment,
        poolSlices[i].principalDeployed,
        totalDeployed
      );
      poolSlices[i].totalInterestAccrued = poolSlices[i].totalInterestAccrued.add(interestForSlice);
    }

    if (interestPayment > 0 || principalPayment > 0) {
      uint256 reserveAmount = collectInterestAndPrincipal(
        address(creditLine),
        interestPayment,
        principalPayment.add(paymentRemaining)
      );

      for (uint256 i = 0; i < poolSlices.length; i++) {
        poolSlices[i].principalDeployed = poolSlices[i].principalDeployed.sub(principalPaymentsPerSlice[i]);
        totalDeployed = totalDeployed.sub(principalPaymentsPerSlice[i]);
      }

      config.getBackerRewards().allocateRewards(interestPayment);

      emit PaymentApplied(
        creditLine.borrower(),
        address(this),
        interestPayment,
        principalPayment,
        paymentRemaining,
        reserveAmount
      );
    }
    emit TranchedPoolAssessed(address(this));
  }

  modifier onlyLocker() {
    require(hasRole(LOCKER_ROLE, msg.sender), "Must have locker role");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @title Safe ERC20 Transfer
 * @notice Reverts when transfer is not successful
 * @author Goldfinch
 */
abstract contract SafeERC20Transfer {
  function safeERC20Transfer(
    IERC20 erc20,
    address to,
    uint256 amount,
    string memory message
  ) internal {
    require(to != address(0), "Can't send to zero address");
    bool success = erc20.transfer(to, amount);
    require(success, message);
  }

  function safeERC20Transfer(
    IERC20 erc20,
    address to,
    uint256 amount
  ) internal {
    safeERC20Transfer(erc20, to, amount, "Failed to transfer ERC20");
  }

  function safeERC20TransferFrom(
    IERC20 erc20,
    address from,
    address to,
    uint256 amount,
    string memory message
  ) internal {
    require(to != address(0), "Can't send to zero address");
    bool success = erc20.transferFrom(from, to, amount);
    require(success, message);
  }

  function safeERC20TransferFrom(
    IERC20 erc20,
    address from,
    address to,
    uint256 amount
  ) internal {
    string memory message = "Failed to transfer ERC20";
    safeERC20TransferFrom(erc20, from, to, amount, message);
  }

  function safeERC20Approve(
    IERC20 erc20,
    address spender,
    uint256 allowance,
    string memory message
  ) internal {
    bool success = erc20.approve(spender, allowance);
    require(success, message);
  }

  function safeERC20Approve(
    IERC20 erc20,
    address spender,
    uint256 allowance
  ) internal {
    string memory message = "Failed to approve ERC20";
    safeERC20Approve(erc20, spender, allowance, message);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../interfaces/IV2CreditLine.sol";
import "../../interfaces/ITranchedPool.sol";
import "../../interfaces/IPoolTokens.sol";
import "../../external/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title TranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Goldfinch
 */

library TranchingLogic {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for uint256;

  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );

  uint256 public constant FP_SCALING_FACTOR = 1e18;
  uint256 public constant ONE_HUNDRED = 100; // Need this because we cannot call .div on a literal 100

  function usdcToSharePrice(uint256 amount, uint256 totalShares) public pure returns (uint256) {
    return totalShares == 0 ? 0 : amount.mul(FP_SCALING_FACTOR).div(totalShares);
  }

  function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares) public pure returns (uint256) {
    return sharePrice.mul(totalShares).div(FP_SCALING_FACTOR);
  }

  function redeemableInterestAndPrincipal(
    ITranchedPool.TrancheInfo storage trancheInfo,
    IPoolTokens.TokenInfo memory tokenInfo
  ) public view returns (uint256 interestRedeemable, uint256 principalRedeemable) {
    // This supports withdrawing before or after locking because principal share price starts at 1
    // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
    uint256 maxPrincipalRedeemable = sharePriceToUsdc(trancheInfo.principalSharePrice, tokenInfo.principalAmount);
    // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
    // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
    uint256 maxInterestRedeemable = sharePriceToUsdc(trancheInfo.interestSharePrice, tokenInfo.principalAmount);

    interestRedeemable = maxInterestRedeemable.sub(tokenInfo.interestRedeemed);
    principalRedeemable = maxPrincipalRedeemable.sub(tokenInfo.principalRedeemed);

    return (interestRedeemable, principalRedeemable);
  }

  function calculateExpectedSharePrice(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) public pure returns (uint256) {
    uint256 sharePrice = usdcToSharePrice(amount, tranche.principalDeposited);
    return scaleByPercentOwnership(tranche, sharePrice, slice);
  }

  function scaleForSlice(
    ITranchedPool.PoolSlice memory slice,
    uint256 amount,
    uint256 totalDeployed
  ) public pure returns (uint256) {
    return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
  }

  // We need to create this struct so we don't run into a stack too deep error due to too many variables
  function getSliceInfo(
    ITranchedPool.PoolSlice memory slice,
    IV2CreditLine creditLine,
    uint256 totalDeployed,
    uint256 reserveFeePercent
  ) public view returns (ITranchedPool.SliceInfo memory) {
    (uint256 interestAccrued, uint256 principalAccrued) = getTotalInterestAndPrincipal(
      slice,
      creditLine,
      totalDeployed
    );
    return
      ITranchedPool.SliceInfo({
        reserveFeePercent: reserveFeePercent,
        interestAccrued: interestAccrued,
        principalAccrued: principalAccrued
      });
  }

  function getTotalInterestAndPrincipal(
    ITranchedPool.PoolSlice memory slice,
    IV2CreditLine creditLine,
    uint256 totalDeployed
  ) public view returns (uint256 interestAccrued, uint256 principalAccrued) {
    principalAccrued = creditLine.principalOwed();
    // In addition to principal actually owed, we need to account for early principal payments
    // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
    // 5K (balance- deployed) + 0 (principal owed)
    principalAccrued = totalDeployed.sub(creditLine.balance()).add(principalAccrued);
    // Now we need to scale that correctly for the slice we're interested in
    principalAccrued = scaleForSlice(slice, principalAccrued, totalDeployed);
    // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
    // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
    // share price starts at 1, and is decremented by what was drawn down.
    uint256 totalDeposited = slice.seniorTranche.principalDeposited.add(slice.juniorTranche.principalDeposited);
    principalAccrued = totalDeposited.sub(slice.principalDeployed).add(principalAccrued);
    return (slice.totalInterestAccrued, principalAccrued);
  }

  function scaleByFraction(
    uint256 amount,
    uint256 fraction,
    uint256 total
  ) public pure returns (uint256) {
    FixedPoint.Unsigned memory totalAsFixedPoint = FixedPoint.fromUnscaledUint(total);
    FixedPoint.Unsigned memory fractionAsFixedPoint = FixedPoint.fromUnscaledUint(fraction);
    return fractionAsFixedPoint.div(totalAsFixedPoint).mul(amount).div(FP_SCALING_FACTOR).rawValue;
  }

  function applyToAllSeniorTranches(
    ITranchedPool.PoolSlice[] storage poolSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine,
    uint256 juniorFeePercent
  ) public returns (ITranchedPool.ApplyResult memory) {
    ITranchedPool.ApplyResult memory seniorApplyResult;
    for (uint256 i = 0; i < poolSlices.length; i++) {
      ITranchedPool.SliceInfo memory sliceInfo = getSliceInfo(
        poolSlices[i],
        creditLine,
        totalDeployed,
        reserveFeePercent
      );

      // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
      // pro-rata across the slices. So we scale the interest and principal to the slice
      ITranchedPool.ApplyResult memory applyResult = applyToSeniorTranche(
        poolSlices[i],
        scaleForSlice(poolSlices[i], interest, totalDeployed),
        scaleForSlice(poolSlices[i], principal, totalDeployed),
        juniorFeePercent,
        sliceInfo
      );
      emitSharePriceUpdatedEvent(poolSlices[i].seniorTranche, applyResult);
      seniorApplyResult.interestRemaining = seniorApplyResult.interestRemaining.add(applyResult.interestRemaining);
      seniorApplyResult.principalRemaining = seniorApplyResult.principalRemaining.add(applyResult.principalRemaining);
      seniorApplyResult.reserveDeduction = seniorApplyResult.reserveDeduction.add(applyResult.reserveDeduction);
    }
    return seniorApplyResult;
  }

  function applyToAllJuniorTranches(
    ITranchedPool.PoolSlice[] storage poolSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine
  ) public returns (uint256 totalReserveAmount) {
    for (uint256 i = 0; i < poolSlices.length; i++) {
      ITranchedPool.SliceInfo memory sliceInfo = getSliceInfo(
        poolSlices[i],
        creditLine,
        totalDeployed,
        reserveFeePercent
      );
      // Any remaining interest and principal is then shared pro-rata with the junior slices
      ITranchedPool.ApplyResult memory applyResult = applyToJuniorTranche(
        poolSlices[i],
        scaleForSlice(poolSlices[i], interest, totalDeployed),
        scaleForSlice(poolSlices[i], principal, totalDeployed),
        sliceInfo
      );
      emitSharePriceUpdatedEvent(poolSlices[i].juniorTranche, applyResult);
      totalReserveAmount = totalReserveAmount.add(applyResult.reserveDeduction);
    }
    return totalReserveAmount;
  }

  function emitSharePriceUpdatedEvent(
    ITranchedPool.TrancheInfo memory tranche,
    ITranchedPool.ApplyResult memory applyResult
  ) internal {
    emit SharePriceUpdated(
      address(this),
      tranche.id,
      tranche.principalSharePrice,
      int256(tranche.principalSharePrice.sub(applyResult.oldPrincipalSharePrice)),
      tranche.interestSharePrice,
      int256(tranche.interestSharePrice.sub(applyResult.oldInterestSharePrice))
    );
  }

  function applyToSeniorTranche(
    ITranchedPool.PoolSlice storage slice,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 juniorFeePercent,
    ITranchedPool.SliceInfo memory sliceInfo
  ) public returns (ITranchedPool.ApplyResult memory) {
    // First determine the expected share price for the senior tranche. This is the gross amount the senior
    // tranche should receive.
    uint256 expectedInterestSharePrice = calculateExpectedSharePrice(
      slice.seniorTranche,
      sliceInfo.interestAccrued,
      slice
    );
    uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
      slice.seniorTranche,
      sliceInfo.principalAccrued,
      slice
    );

    // Deduct the junior fee and the protocol reserve
    uint256 desiredNetInterestSharePrice = scaleByFraction(
      expectedInterestSharePrice,
      ONE_HUNDRED.sub(juniorFeePercent.add(sliceInfo.reserveFeePercent)),
      ONE_HUNDRED
    );
    // Collect protocol fee interest received (we've subtracted this from the senior portion above)
    uint256 reserveDeduction = scaleByFraction(interestRemaining, sliceInfo.reserveFeePercent, ONE_HUNDRED);
    interestRemaining = interestRemaining.sub(reserveDeduction);
    uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice;
    uint256 oldPrincipalSharePrice = slice.seniorTranche.principalSharePrice;
    // Apply the interest remaining so we get up to the netInterestSharePrice
    (interestRemaining, principalRemaining) = applyBySharePrice(
      slice.seniorTranche,
      interestRemaining,
      principalRemaining,
      desiredNetInterestSharePrice,
      expectedPrincipalSharePrice
    );
    return
      ITranchedPool.ApplyResult({
        interestRemaining: interestRemaining,
        principalRemaining: principalRemaining,
        reserveDeduction: reserveDeduction,
        oldInterestSharePrice: oldInterestSharePrice,
        oldPrincipalSharePrice: oldPrincipalSharePrice
      });
  }

  function applyToJuniorTranche(
    ITranchedPool.PoolSlice storage slice,
    uint256 interestRemaining,
    uint256 principalRemaining,
    ITranchedPool.SliceInfo memory sliceInfo
  ) public returns (ITranchedPool.ApplyResult memory) {
    // Then fill up the junior tranche with all the interest remaining, upto the principal share price
    uint256 expectedInterestSharePrice = slice.juniorTranche.interestSharePrice.add(
      usdcToSharePrice(interestRemaining, slice.juniorTranche.principalDeposited)
    );
    uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
      slice.juniorTranche,
      sliceInfo.principalAccrued,
      slice
    );
    uint256 oldInterestSharePrice = slice.juniorTranche.interestSharePrice;
    uint256 oldPrincipalSharePrice = slice.juniorTranche.principalSharePrice;
    (interestRemaining, principalRemaining) = applyBySharePrice(
      slice.juniorTranche,
      interestRemaining,
      principalRemaining,
      expectedInterestSharePrice,
      expectedPrincipalSharePrice
    );

    // All remaining interest and principal is applied towards the junior tranche as interest
    interestRemaining = interestRemaining.add(principalRemaining);
    // Since any principal remaining is treated as interest (there is "extra" interest to be distributed)
    // we need to make sure to collect the protocol fee on the additional interest (we only deducted the
    // fee on the original interest portion)
    uint256 reserveDeduction = scaleByFraction(principalRemaining, sliceInfo.reserveFeePercent, ONE_HUNDRED);
    interestRemaining = interestRemaining.sub(reserveDeduction);
    principalRemaining = 0;

    (interestRemaining, principalRemaining) = applyByAmount(
      slice.juniorTranche,
      interestRemaining.add(principalRemaining),
      0,
      interestRemaining.add(principalRemaining),
      0
    );
    return
      ITranchedPool.ApplyResult({
        interestRemaining: interestRemaining,
        principalRemaining: principalRemaining,
        reserveDeduction: reserveDeduction,
        oldInterestSharePrice: oldInterestSharePrice,
        oldPrincipalSharePrice: oldPrincipalSharePrice
      });
  }

  function applyBySharePrice(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestSharePrice,
    uint256 desiredPrincipalSharePrice
  ) public returns (uint256, uint256) {
    uint256 desiredInterestAmount = desiredAmountFromSharePrice(
      desiredInterestSharePrice,
      tranche.interestSharePrice,
      tranche.principalDeposited
    );
    uint256 desiredPrincipalAmount = desiredAmountFromSharePrice(
      desiredPrincipalSharePrice,
      tranche.principalSharePrice,
      tranche.principalDeposited
    );
    return applyByAmount(tranche, interestRemaining, principalRemaining, desiredInterestAmount, desiredPrincipalAmount);
  }

  function applyByAmount(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestAmount,
    uint256 desiredPrincipalAmount
  ) public returns (uint256, uint256) {
    uint256 totalShares = tranche.principalDeposited;
    uint256 newSharePrice;

    (interestRemaining, newSharePrice) = applyToSharePrice(
      interestRemaining,
      tranche.interestSharePrice,
      desiredInterestAmount,
      totalShares
    );
    tranche.interestSharePrice = newSharePrice;

    (principalRemaining, newSharePrice) = applyToSharePrice(
      principalRemaining,
      tranche.principalSharePrice,
      desiredPrincipalAmount,
      totalShares
    );
    tranche.principalSharePrice = newSharePrice;
    return (interestRemaining, principalRemaining);
  }

  function migrateAccountingVariables(address originalClAddr, address newClAddr) public {
    IV2CreditLine originalCl = IV2CreditLine(originalClAddr);
    IV2CreditLine newCl = IV2CreditLine(newClAddr);

    // Copy over all accounting variables
    newCl.setBalance(originalCl.balance());
    newCl.setLimit(originalCl.limit());
    newCl.setInterestOwed(originalCl.interestOwed());
    newCl.setPrincipalOwed(originalCl.principalOwed());
    newCl.setTermEndTime(originalCl.termEndTime());
    newCl.setNextDueTime(originalCl.nextDueTime());
    newCl.setInterestAccruedAsOf(originalCl.interestAccruedAsOf());
    newCl.setLastFullPaymentTime(originalCl.lastFullPaymentTime());
    newCl.setTotalInterestAccrued(originalCl.totalInterestAccrued());
  }

  function closeCreditLine(address originalCl) public {
    // Close out old CL
    IV2CreditLine oldCreditLine = IV2CreditLine(originalCl);
    oldCreditLine.setBalance(0);
    oldCreditLine.setLimit(0);
    oldCreditLine.setMaxLimit(0);
  }

  function desiredAmountFromSharePrice(
    uint256 desiredSharePrice,
    uint256 actualSharePrice,
    uint256 totalShares
  ) public pure returns (uint256) {
    // If the desired share price is lower, then ignore it, and leave it unchanged
    if (desiredSharePrice < actualSharePrice) {
      desiredSharePrice = actualSharePrice;
    }
    uint256 sharePriceDifference = desiredSharePrice.sub(actualSharePrice);
    return sharePriceToUsdc(sharePriceDifference, totalShares);
  }

  function applyToSharePrice(
    uint256 amountRemaining,
    uint256 currentSharePrice,
    uint256 desiredAmount,
    uint256 totalShares
  ) public pure returns (uint256, uint256) {
    // If no money left to apply, or don't need any changes, return the original amounts
    if (amountRemaining == 0 || desiredAmount == 0) {
      return (amountRemaining, currentSharePrice);
    }
    if (amountRemaining < desiredAmount) {
      // We don't have enough money to adjust share price to the desired level. So just use whatever amount is left
      desiredAmount = amountRemaining;
    }
    uint256 sharePriceDifference = usdcToSharePrice(desiredAmount, totalShares);
    return (amountRemaining.sub(desiredAmount), currentSharePrice.add(sharePriceDifference));
  }

  function scaleByPercentOwnership(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) public pure returns (uint256) {
    uint256 totalDeposited = slice.juniorTranche.principalDeposited.add(slice.seniorTranche.principalDeposited);
    return scaleByFraction(amount, tranche.principalDeposited, totalDeposited);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/MerkleDistributor.sol.
pragma solidity 0.6.12;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/IMerkleDirectDistributor.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";

contract MerkleDirectDistributor is IMerkleDirectDistributor, BaseUpgradeablePausable {
  using SafeERC20 for IERC20withDec;

  address public override gfi;
  bytes32 public override merkleRoot;

  // @dev This is a packed array of booleans.
  mapping(uint256 => uint256) private acceptedBitMap;

  function initialize(
    address owner,
    address _gfi,
    bytes32 _merkleRoot
  ) public initializer {
    require(owner != address(0), "Owner address cannot be empty");
    require(_gfi != address(0), "GFI address cannot be empty");
    require(_merkleRoot != 0, "Invalid Merkle root");

    __BaseUpgradeablePausable__init(owner);

    gfi = _gfi;
    merkleRoot = _merkleRoot;
  }

  function isGrantAccepted(uint256 index) public view override returns (bool) {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    uint256 acceptedWord = acceptedBitMap[acceptedWordIndex];
    uint256 mask = (1 << acceptedBitIndex);
    return acceptedWord & mask == mask;
  }

  function _setGrantAccepted(uint256 index) private {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    acceptedBitMap[acceptedWordIndex] = acceptedBitMap[acceptedWordIndex] | (1 << acceptedBitIndex);
  }

  function acceptGrant(
    uint256 index,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override whenNotPaused {
    require(!isGrantAccepted(index), "Grant already accepted");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it accepted and perform the granting.
    _setGrantAccepted(index);
    IERC20withDec(gfi).safeTransfer(msg.sender, amount);

    emit GrantAccepted(index, msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/interfaces/IMerkleDistributor.sol.
pragma solidity 0.6.12;

/// @notice Enables the transfer of GFI rewards (referred to as a "grant"), if the grant details exist in this
/// contract's Merkle root.
interface IMerkleDirectDistributor {
  /// @notice Returns the address of the GFI contract that is the token distributed as rewards by
  ///   this contract.
  function gfi() external view returns (address);

  /// @notice Returns the merkle root of the merkle tree containing grant details available to accept.
  function merkleRoot() external view returns (bytes32);

  /// @notice Returns true if the index has been marked accepted.
  function isGrantAccepted(uint256 index) external view returns (bool);

  /// @notice Causes the sender to accept the grant consisting of the given details. Reverts if
  /// the inputs (which includes who the sender is) are invalid.
  function acceptGrant(
    uint256 index,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  /// @notice This event is triggered whenever a call to #acceptGrant succeeds.
  event GrantAccepted(uint256 indexed index, address indexed account, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/Pool.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";
import "../protocol/core/CreditLine.sol";

contract TestCreditLine is CreditLine {}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/Accountant.sol";
import "../protocol/core/CreditLine.sol";

contract TestAccountant {
  function calculateInterestAndPrincipalAccrued(
    address creditLineAddress,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    CreditLine cl = CreditLine(creditLineAddress);
    return Accountant.calculateInterestAndPrincipalAccrued(cl, timestamp, lateFeeGracePeriod);
  }

  function calculateWritedownFor(
    address creditLineAddress,
    uint256 blockNumber,
    uint256 gracePeriod,
    uint256 maxLatePeriods
  ) public view returns (uint256, uint256) {
    CreditLine cl = CreditLine(creditLineAddress);
    return Accountant.calculateWritedownFor(cl, blockNumber, gracePeriod, maxLatePeriods);
  }

  function calculateAmountOwedForOneDay(address creditLineAddress) public view returns (FixedPoint.Unsigned memory) {
    CreditLine cl = CreditLine(creditLineAddress);
    return Accountant.calculateAmountOwedForOneDay(cl);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

import "../../interfaces/ISeniorPool.sol";
import "../../interfaces/IPoolTokens.sol";
import "./Accountant.sol";
import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";

/**
 * @title Goldfinch's SeniorPool contract
 * @notice Main entry point for senior LPs (a.k.a. capital providers)
 *  Automatically invests across borrower pools using an adjustable strategy.
 * @author Goldfinch
 */
contract SeniorPool is BaseUpgradeablePausable, ISeniorPool {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using SafeMath for uint256;

  uint256 public compoundBalance;
  mapping(ITranchedPool => uint256) public writedowns;

  event DepositMade(address indexed capitalProvider, uint256 amount, uint256 shares);
  event WithdrawalMade(address indexed capitalProvider, uint256 userAmount, uint256 reserveAmount);
  event InterestCollected(address indexed payer, uint256 amount);
  event PrincipalCollected(address indexed payer, uint256 amount);
  event ReserveFundsCollected(address indexed user, uint256 amount);

  event PrincipalWrittenDown(address indexed tranchedPool, int256 amount);
  event InvestmentMadeInSenior(address indexed tranchedPool, uint256 amount);
  event InvestmentMadeInJunior(address indexed tranchedPool, uint256 amount);

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    config = _config;
    // Initialize sharePrice to be identical to the legacy pool. This is in the initializer
    // because it must only ever happen once.
    sharePrice = config.getPool().sharePrice();
    totalLoansOutstanding = config.getCreditDesk().totalLoansOutstanding();
    totalWritedowns = config.getCreditDesk().totalWritedowns();

    IERC20withDec usdc = config.getUSDC();
    // Sanity check the address
    usdc.totalSupply();

    bool success = usdc.approve(address(this), uint256(-1));
    require(success, "Failed to approve USDC");
  }

  /**
   * @notice Deposits `amount` USDC from msg.sender into the SeniorPool, and grants you the
   *  equivalent value of FIDU tokens
   * @param amount The amount of USDC to deposit
   */
  function deposit(uint256 amount) public override whenNotPaused nonReentrant returns (uint256 depositShares) {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    require(amount > 0, "Must deposit more than zero");
    // Check if the amount of new shares to be added is within limits
    depositShares = getNumShares(amount);
    uint256 potentialNewTotalShares = totalShares().add(depositShares);
    require(sharesWithinLimit(potentialNewTotalShares), "Deposit would put the senior pool over the total limit.");
    emit DepositMade(msg.sender, amount, depositShares);
    bool success = doUSDCTransfer(msg.sender, address(this), amount);
    require(success, "Failed to transfer for deposit");

    config.getFidu().mintTo(msg.sender, depositShares);
    return depositShares;
  }

  /**
   * @notice Identical to deposit, except it allows for a passed up signature to permit
   *  the Senior Pool to move funds on behalf of the user, all within one transaction.
   * @param amount The amount of USDC to deposit
   * @param v secp256k1 signature component
   * @param r secp256k1 signature component
   * @param s secp256k1 signature component
   */
  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override returns (uint256 depositShares) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(amount);
  }

  /**
   * @notice Withdraws USDC from the SeniorPool to msg.sender, and burns the equivalent value of FIDU tokens
   * @param usdcAmount The amount of USDC to withdraw
   */
  function withdraw(uint256 usdcAmount) external override whenNotPaused nonReentrant returns (uint256 amount) {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    require(usdcAmount > 0, "Must withdraw more than zero");
    // This MUST happen before calculating withdrawShares, otherwise the share price
    // changes between calculation and burning of Fidu, which creates a asset/liability mismatch
    if (compoundBalance > 0) {
      _sweepFromCompound();
    }
    uint256 withdrawShares = getNumShares(usdcAmount);
    return _withdraw(usdcAmount, withdrawShares);
  }

  /**
   * @notice Withdraws USDC (denominated in FIDU terms) from the SeniorPool to msg.sender
   * @param fiduAmount The amount of USDC to withdraw in terms of FIDU shares
   */
  function withdrawInFidu(uint256 fiduAmount) external override whenNotPaused nonReentrant returns (uint256 amount) {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    require(fiduAmount > 0, "Must withdraw more than zero");
    // This MUST happen before calculating withdrawShares, otherwise the share price
    // changes between calculation and burning of Fidu, which creates a asset/liability mismatch
    if (compoundBalance > 0) {
      _sweepFromCompound();
    }
    uint256 usdcAmount = getUSDCAmountFromShares(fiduAmount);
    uint256 withdrawShares = fiduAmount;
    return _withdraw(usdcAmount, withdrawShares);
  }

  /**
   * @notice Migrates to a new goldfinch config address
   */
  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Moves any USDC still in the SeniorPool to Compound, and tracks the amount internally.
   * This is done to earn interest on latent funds until we have other borrowers who can use it.
   *
   * Requirements:
   *  - The caller must be an admin.
   */
  function sweepToCompound() public override onlyAdmin whenNotPaused {
    IERC20 usdc = config.getUSDC();
    uint256 usdcBalance = usdc.balanceOf(address(this));

    ICUSDCContract cUSDC = config.getCUSDCContract();
    // Approve compound to the exact amount
    bool success = usdc.approve(address(cUSDC), usdcBalance);
    require(success, "Failed to approve USDC for compound");

    sweepToCompound(cUSDC, usdcBalance);

    // Remove compound approval to be extra safe
    success = config.getUSDC().approve(address(cUSDC), 0);
    require(success, "Failed to approve USDC for compound");
  }

  /**
   * @notice Moves any USDC from Compound back to the SeniorPool, and recognizes interest earned.
   * This is done automatically on drawdown or withdraw, but can be called manually if necessary.
   *
   * Requirements:
   *  - The caller must be an admin.
   */
  function sweepFromCompound() public override onlyAdmin whenNotPaused {
    _sweepFromCompound();
  }

  /**
   * @notice Invest in an ITranchedPool's senior tranche using the senior pool's strategy
   * @param pool An ITranchedPool whose senior tranche should be considered for investment
   */
  function invest(ITranchedPool pool) public override whenNotPaused nonReentrant {
    require(validPool(pool), "Pool must be valid");

    if (compoundBalance > 0) {
      _sweepFromCompound();
    }

    ISeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    uint256 amount = strategy.invest(this, pool);

    require(amount > 0, "Investment amount must be positive");

    approvePool(pool, amount);
    pool.deposit(uint256(ITranchedPool.Tranches.Senior), amount);

    emit InvestmentMadeInSenior(address(pool), amount);
    totalLoansOutstanding = totalLoansOutstanding.add(amount);
  }

  function estimateInvestment(ITranchedPool pool) public view override returns (uint256) {
    require(validPool(pool), "Pool must be valid");
    ISeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    return strategy.estimateInvestment(this, pool);
  }

  /**
   * @notice Redeem interest and/or principal from an ITranchedPool investment
   * @param tokenId the ID of an IPoolTokens token to be redeemed
   */
  function redeem(uint256 tokenId) public override whenNotPaused nonReentrant {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    (uint256 interestRedeemed, uint256 principalRedeemed) = pool.withdrawMax(tokenId);

    _collectInterestAndPrincipal(address(pool), interestRedeemed, principalRedeemed);
  }

  /**
   * @notice Write down an ITranchedPool investment. This will adjust the senior pool's share price
   *  down if we're considering the investment a loss, or up if the borrower has subsequently
   *  made repayments that restore confidence that the full loan will be repaid.
   * @param tokenId the ID of an IPoolTokens token to be considered for writedown
   */
  function writedown(uint256 tokenId) public override whenNotPaused nonReentrant {
    IPoolTokens poolTokens = config.getPoolTokens();
    require(address(this) == poolTokens.ownerOf(tokenId), "Only tokens owned by the senior pool can be written down");

    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    require(validPool(pool), "Pool must be valid");

    uint256 principalRemaining = tokenInfo.principalAmount.sub(tokenInfo.principalRedeemed);

    (uint256 writedownPercent, uint256 writedownAmount) = _calculateWritedown(pool, principalRemaining);

    uint256 prevWritedownAmount = writedowns[pool];

    if (writedownPercent == 0 && prevWritedownAmount == 0) {
      return;
    }

    int256 writedownDelta = int256(prevWritedownAmount) - int256(writedownAmount);
    writedowns[pool] = writedownAmount;
    distributeLosses(writedownDelta);
    if (writedownDelta > 0) {
      // If writedownDelta is positive, that means we got money back. So subtract from totalWritedowns.
      totalWritedowns = totalWritedowns.sub(uint256(writedownDelta));
    } else {
      totalWritedowns = totalWritedowns.add(uint256(writedownDelta * -1));
    }
    emit PrincipalWrittenDown(address(pool), writedownDelta);
  }

  /**
   * @notice Calculates the writedown amount for a particular pool position
   * @param tokenId The token reprsenting the position
   * @return The amount in dollars the principal should be written down by
   */
  function calculateWritedown(uint256 tokenId) public view override returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    ITranchedPool pool = ITranchedPool(tokenInfo.pool);

    uint256 principalRemaining = tokenInfo.principalAmount.sub(tokenInfo.principalRedeemed);

    (, uint256 writedownAmount) = _calculateWritedown(pool, principalRemaining);
    return writedownAmount;
  }

  /**
   * @notice Returns the net assests controlled by and owed to the pool
   */
  function assets() public view override returns (uint256) {
    return
      compoundBalance.add(config.getUSDC().balanceOf(address(this))).add(totalLoansOutstanding).sub(totalWritedowns);
  }

  /**
   * @notice Converts and USDC amount to FIDU amount
   * @param amount USDC amount to convert to FIDU
   */
  function getNumShares(uint256 amount) public view override returns (uint256) {
    return usdcToFidu(amount).mul(fiduMantissa()).div(sharePrice);
  }

  /* Internal Functions */

  function _calculateWritedown(ITranchedPool pool, uint256 principal)
    internal
    view
    returns (uint256 writedownPercent, uint256 writedownAmount)
  {
    return
      Accountant.calculateWritedownForPrincipal(
        pool.creditLine(),
        principal,
        currentTime(),
        config.getLatenessGracePeriodInDays(),
        config.getLatenessMaxDays()
      );
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function distributeLosses(int256 writedownDelta) internal {
    if (writedownDelta > 0) {
      uint256 delta = usdcToSharePrice(uint256(writedownDelta));
      sharePrice = sharePrice.add(delta);
    } else {
      // If delta is negative, convert to positive uint, and sub from sharePrice
      uint256 delta = usdcToSharePrice(uint256(writedownDelta * -1));
      sharePrice = sharePrice.sub(delta);
    }
  }

  function fiduMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }

  function usdcToFidu(uint256 amount) internal pure returns (uint256) {
    return amount.mul(fiduMantissa()).div(usdcMantissa());
  }

  function fiduToUSDC(uint256 amount) internal pure returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  function getUSDCAmountFromShares(uint256 fiduAmount) internal view returns (uint256) {
    return fiduToUSDC(fiduAmount.mul(sharePrice).div(fiduMantissa()));
  }

  function sharesWithinLimit(uint256 _totalShares) internal view returns (bool) {
    return
      _totalShares.mul(sharePrice).div(fiduMantissa()) <=
      usdcToFidu(config.getNumber(uint256(ConfigOptions.Numbers.TotalFundsLimit)));
  }

  function doUSDCTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    require(to != address(0), "Can't send to zero address");
    IERC20withDec usdc = config.getUSDC();
    return usdc.transferFrom(from, to, amount);
  }

  function _withdraw(uint256 usdcAmount, uint256 withdrawShares) internal returns (uint256 userAmount) {
    IFidu fidu = config.getFidu();
    // Determine current shares the address has and the shares requested to withdraw
    uint256 currentShares = fidu.balanceOf(msg.sender);
    // Ensure the address has enough value in the pool
    require(withdrawShares <= currentShares, "Amount requested is greater than what this address owns");

    uint256 reserveAmount = usdcAmount.div(config.getWithdrawFeeDenominator());
    userAmount = usdcAmount.sub(reserveAmount);

    emit WithdrawalMade(msg.sender, userAmount, reserveAmount);
    // Send the amounts
    bool success = doUSDCTransfer(address(this), msg.sender, userAmount);
    require(success, "Failed to transfer for withdraw");
    sendToReserve(reserveAmount, msg.sender);

    // Burn the shares
    fidu.burnFrom(msg.sender, withdrawShares);
    return userAmount;
  }

  function sweepToCompound(ICUSDCContract cUSDC, uint256 usdcAmount) internal {
    // Our current design requires we re-normalize by withdrawing everything and recognizing interest gains
    // before we can add additional capital to Compound
    require(compoundBalance == 0, "Cannot sweep when we already have a compound balance");
    require(usdcAmount != 0, "Amount to sweep cannot be zero");
    uint256 error = cUSDC.mint(usdcAmount);
    require(error == 0, "Sweep to compound failed");
    compoundBalance = usdcAmount;
  }

  function _sweepFromCompound() internal {
    ICUSDCContract cUSDC = config.getCUSDCContract();
    sweepFromCompound(cUSDC, cUSDC.balanceOf(address(this)));
  }

  function sweepFromCompound(ICUSDCContract cUSDC, uint256 cUSDCAmount) internal {
    uint256 cBalance = compoundBalance;
    require(cBalance != 0, "No funds on compound");
    require(cUSDCAmount != 0, "Amount to sweep cannot be zero");

    IERC20 usdc = config.getUSDC();
    uint256 preRedeemUSDCBalance = usdc.balanceOf(address(this));
    uint256 cUSDCExchangeRate = cUSDC.exchangeRateCurrent();
    uint256 redeemedUSDC = cUSDCToUSDC(cUSDCExchangeRate, cUSDCAmount);

    uint256 error = cUSDC.redeem(cUSDCAmount);
    uint256 postRedeemUSDCBalance = usdc.balanceOf(address(this));
    require(error == 0, "Sweep from compound failed");
    require(postRedeemUSDCBalance.sub(preRedeemUSDCBalance) == redeemedUSDC, "Unexpected redeem amount");

    uint256 interestAccrued = redeemedUSDC.sub(cBalance);
    uint256 reserveAmount = interestAccrued.div(config.getReserveDenominator());
    uint256 poolAmount = interestAccrued.sub(reserveAmount);

    _collectInterestAndPrincipal(address(this), poolAmount, 0);

    if (reserveAmount > 0) {
      sendToReserve(reserveAmount, address(cUSDC));
    }

    compoundBalance = 0;
  }

  function cUSDCToUSDC(uint256 exchangeRate, uint256 amount) internal pure returns (uint256) {
    // See https://compound.finance/docs#protocol-math
    // But note, the docs and reality do not agree. Docs imply that that exchange rate is
    // scaled by 1e18, but tests and mainnet forking make it appear to be scaled by 1e16
    // 1e16 is also what Sheraz at Certik said.
    uint256 usdcDecimals = 6;
    uint256 cUSDCDecimals = 8;

    // We multiply in the following order, for the following reasons...
    // Amount in cToken (1e8)
    // Amount in USDC (but scaled by 1e16, cause that's what exchange rate decimals are)
    // Downscale to cToken decimals (1e8)
    // Downscale from cToken to USDC decimals (8 to 6)
    return amount.mul(exchangeRate).div(10**(18 + usdcDecimals - cUSDCDecimals)).div(10**2);
  }

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal {
    uint256 increment = usdcToSharePrice(interest);
    sharePrice = sharePrice.add(increment);

    if (interest > 0) {
      emit InterestCollected(from, interest);
    }
    if (principal > 0) {
      emit PrincipalCollected(from, principal);
      totalLoansOutstanding = totalLoansOutstanding.sub(principal);
    }
  }

  function sendToReserve(uint256 amount, address userForEvent) internal {
    emit ReserveFundsCollected(userForEvent, amount);
    bool success = doUSDCTransfer(address(this), config.reserveAddress(), amount);
    require(success, "Reserve transfer was not successful");
  }

  function usdcToSharePrice(uint256 usdcAmount) internal view returns (uint256) {
    return usdcToFidu(usdcAmount).mul(fiduMantissa()).div(totalShares());
  }

  function totalShares() internal view returns (uint256) {
    return config.getFidu().totalSupply();
  }

  function validPool(ITranchedPool pool) internal view returns (bool) {
    return config.getPoolTokens().validPool(address(pool));
  }

  function approvePool(ITranchedPool pool, uint256 allowance) internal {
    IERC20withDec usdc = config.getUSDC();
    bool success = usdc.approve(address(pool), allowance);
    require(success, "Failed to approve USDC");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/SeniorPool.sol";

contract TestSeniorPool is SeniorPool {
  function _getNumShares(uint256 amount) public view returns (uint256) {
    return getNumShares(amount);
  }

  function _usdcMantissa() public pure returns (uint256) {
    return usdcMantissa();
  }

  function _fiduMantissa() public pure returns (uint256) {
    return fiduMantissa();
  }

  function _usdcToFidu(uint256 amount) public pure returns (uint256) {
    return usdcToFidu(amount);
  }

  function _setSharePrice(uint256 newSharePrice) public returns (uint256) {
    sharePrice = newSharePrice;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

import "../external/ERC721PresetMinterPauserAutoId.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/ICommunityRewards.sol";
import "../protocol/core/GoldfinchConfig.sol";
import "../protocol/core/ConfigHelper.sol";

import "../library/CommunityRewardsVesting.sol";

contract CommunityRewards is ICommunityRewards, ERC721PresetMinterPauserAutoIdUpgradeSafe, ReentrancyGuardUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20withDec;
  using ConfigHelper for GoldfinchConfig;

  using CommunityRewardsVesting for CommunityRewardsVesting.Rewards;

  /* ==========     EVENTS      ========== */

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  /* ========== STATE VARIABLES ========== */

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

  GoldfinchConfig public config;

  /// @notice Total rewards available for granting, denominated in `rewardsToken()`
  uint256 public rewardsAvailable;

  /// @notice Token launch time in seconds. This is used in vesting.
  uint256 public tokenLaunchTimeInSeconds;

  /// @dev NFT tokenId => rewards grant
  mapping(uint256 => CommunityRewardsVesting.Rewards) public grants;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(
    address owner,
    GoldfinchConfig _config,
    uint256 _tokenLaunchTimeInSeconds
  ) external initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained("Goldfinch V2 Community Rewards Tokens", "GFI-V2-CR");
    __ERC721Pausable_init_unchained();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(DISTRIBUTOR_ROLE, owner);

    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(DISTRIBUTOR_ROLE, OWNER_ROLE);

    tokenLaunchTimeInSeconds = _tokenLaunchTimeInSeconds;

    config = _config;
  }

  /* ========== VIEWS ========== */

  /// @notice The token being disbursed as rewards
  function rewardsToken() public view override returns (IERC20withDec) {
    return config.getGFI();
  }

  /// @notice Returns the rewards claimable by a given grant token, taking into
  ///   account vesting schedule.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function claimableRewards(uint256 tokenId) public view override returns (uint256 rewards) {
    return grants[tokenId].claimable();
  }

  /// @notice Returns the rewards that will have vested for some grant with the given params.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) external pure override returns (uint256 rewards) {
    return CommunityRewardsVesting.getTotalVestedAt(start, end, granted, cliffLength, vestingInterval, revokedAt, time);
  }

  /* ========== MUTATIVE, ADMIN-ONLY FUNCTIONS ========== */

  /// @notice Transfer rewards from msg.sender, to be used for reward distribution
  function loadRewards(uint256 rewards) external override onlyAdmin {
    require(rewards > 0, "Cannot load 0 rewards");

    rewardsAvailable = rewardsAvailable.add(rewards);

    rewardsToken().safeTransferFrom(msg.sender, address(this), rewards);

    emit RewardAdded(rewards);
  }

  /// @notice Revokes rewards that have not yet vested, for a grant. The unvested rewards are
  /// now considered available for allocation in another grant.
  /// @param tokenId The tokenId corresponding to the grant whose unvested rewards to revoke.
  function revokeGrant(uint256 tokenId) external override whenNotPaused onlyAdmin {
    CommunityRewardsVesting.Rewards storage grant = grants[tokenId];

    require(grant.totalGranted > 0, "Grant not defined for token id");
    require(grant.revokedAt == 0, "Grant has already been revoked");

    uint256 totalUnvested = grant.totalUnvestedAt(block.timestamp);
    require(totalUnvested > 0, "Grant has fully vested");

    rewardsAvailable = rewardsAvailable.add(totalUnvested);

    grant.revokedAt = block.timestamp;

    emit GrantRevoked(tokenId, totalUnvested);
  }

  function setTokenLaunchTimeInSeconds(uint256 _tokenLaunchTimeInSeconds) external onlyAdmin {
    tokenLaunchTimeInSeconds = _tokenLaunchTimeInSeconds;
  }

  /// @notice updates current config
  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(_msgSender(), address(config));
  }

  /* ========== MUTATIVE, NON-ADMIN-ONLY FUNCTIONS ========== */

  /// @notice Grant rewards to a recipient. The recipient address receives an
  ///   an NFT representing their rewards grant. They can present the NFT to `getReward()`
  ///   to claim their rewards. Rewards vest over a schedule.
  /// @param recipient The recipient of the grant.
  /// @param amount The amount of `rewardsToken()` to grant.
  /// @param vestingLength The duration (in seconds) over which the grant vests.
  /// @param cliffLength The duration (in seconds) from the start of the grant, before which has elapsed
  /// the vested amount remains 0.
  /// @param vestingInterval The interval (in seconds) at which vesting occurs. Must be a factor of `vestingLength`.
  function grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) external override nonReentrant whenNotPaused onlyDistributor returns (uint256 tokenId) {
    return _grant(recipient, amount, vestingLength, cliffLength, vestingInterval);
  }

  function _grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) internal returns (uint256 tokenId) {
    require(amount > 0, "Cannot grant 0 amount");
    require(cliffLength <= vestingLength, "Cliff length cannot exceed vesting length");
    require(vestingLength.mod(vestingInterval) == 0, "Vesting interval must be a factor of vesting length");
    require(amount <= rewardsAvailable, "Cannot grant amount due to insufficient funds");

    rewardsAvailable = rewardsAvailable.sub(amount);

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    grants[tokenId] = CommunityRewardsVesting.Rewards({
      totalGranted: amount,
      totalClaimed: 0,
      startTime: tokenLaunchTimeInSeconds,
      endTime: tokenLaunchTimeInSeconds.add(vestingLength),
      cliffLength: cliffLength,
      vestingInterval: vestingInterval,
      revokedAt: 0
    });

    _mint(recipient, tokenId);

    emit Granted(recipient, tokenId, amount, vestingLength, cliffLength, vestingInterval);

    return tokenId;
  }

  /// @notice Claim rewards for a given grant
  /// @param tokenId A grant token ID
  function getReward(uint256 tokenId) external override nonReentrant whenNotPaused {
    require(ownerOf(tokenId) == msg.sender, "access denied");
    uint256 reward = claimableRewards(tokenId);
    if (reward > 0) {
      grants[tokenId].claim(reward);
      rewardsToken().safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, tokenId, reward);
    }
  }

  /* ========== MODIFIERS ========== */

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }

  function isDistributor() public view returns (bool) {
    return hasRole(DISTRIBUTOR_ROLE, _msgSender());
  }

  modifier onlyDistributor() {
    require(isDistributor(), "Must have distributor role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IERC20withDec.sol";

interface ICommunityRewards is IERC721 {
  function rewardsToken() external view returns (IERC20withDec);

  function claimableRewards(uint256 tokenId) external view returns (uint256 rewards);

  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) external pure returns (uint256 rewards);

  function grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) external returns (uint256 tokenId);

  function loadRewards(uint256 rewards) external;

  function revokeGrant(uint256 tokenId) external;

  function getReward(uint256 tokenId) external;

  event RewardAdded(uint256 reward);
  event Granted(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  );
  event GrantRevoked(uint256 indexed tokenId, uint256 totalUnvested);
  event RewardPaid(address indexed user, uint256 indexed tokenId, uint256 reward);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

library CommunityRewardsVesting {
  using SafeMath for uint256;
  using CommunityRewardsVesting for Rewards;

  /// @dev All time values in the Rewards struct (i.e. `startTime`, `endTime`,
  /// `cliffLength`, `vestingInterval`, `revokedAt`) use the same units: seconds. All timestamp
  /// values (i.e. `startTime`, `endTime`, `revokedAt`) are seconds since the unix epoch.
  /// @dev `cliffLength` is the duration from the start of the grant, before which has elapsed
  /// the vested amount remains 0.
  /// @dev `vestingInterval` is the interval at which vesting occurs. For rewards to have
  /// vested fully only at `endTime`, `vestingInterval` must be a factor of
  /// `endTime.sub(startTime)`. If `vestingInterval` is not thusly a factor, the calculation
  /// of `totalVestedAt()` would calculate rewards to have fully vested as of the time of the
  /// last whole `vestingInterval`'s elapsing before `endTime`.
  struct Rewards {
    uint256 totalGranted;
    uint256 totalClaimed;
    uint256 startTime;
    uint256 endTime;
    uint256 cliffLength;
    uint256 vestingInterval;
    uint256 revokedAt;
  }

  function claim(Rewards storage rewards, uint256 reward) internal {
    rewards.totalClaimed = rewards.totalClaimed.add(reward);
  }

  function claimable(Rewards storage rewards) internal view returns (uint256) {
    return claimable(rewards, block.timestamp);
  }

  function claimable(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return rewards.totalVestedAt(time).sub(rewards.totalClaimed);
  }

  function totalUnvestedAt(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return rewards.totalGranted.sub(rewards.totalVestedAt(time));
  }

  function totalVestedAt(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return
      getTotalVestedAt(
        rewards.startTime,
        rewards.endTime,
        rewards.totalGranted,
        rewards.cliffLength,
        rewards.vestingInterval,
        rewards.revokedAt,
        time
      );
  }

  function getTotalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) internal pure returns (uint256) {
    if (time < start.add(cliffLength)) {
      return 0;
    }

    if (end <= start) {
      return granted;
    }

    uint256 elapsedVestingTimestamp = revokedAt > 0 ? Math.min(revokedAt, time) : time;
    uint256 elapsedVestingUnits = (elapsedVestingTimestamp.sub(start)).div(vestingInterval);
    uint256 totalVestingUnits = (end.sub(start)).div(vestingInterval);
    return Math.min(granted.mul(elapsedVestingUnits).div(totalVestingUnits), granted);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/MerkleDistributor.sol.
pragma solidity 0.6.12;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import "../interfaces/ICommunityRewards.sol";
import "../interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
  address public immutable override communityRewards;
  bytes32 public immutable override merkleRoot;

  // @dev This is a packed array of booleans.
  mapping(uint256 => uint256) private acceptedBitMap;

  constructor(address communityRewards_, bytes32 merkleRoot_) public {
    require(communityRewards_ != address(0), "Cannot use the null address");
    require(merkleRoot_ != 0, "Invalid merkle root provided");
    communityRewards = communityRewards_;
    merkleRoot = merkleRoot_;
  }

  function isGrantAccepted(uint256 index) public view override returns (bool) {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    uint256 acceptedWord = acceptedBitMap[acceptedWordIndex];
    uint256 mask = (1 << acceptedBitIndex);
    return acceptedWord & mask == mask;
  }

  function _setGrantAccepted(uint256 index) private {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    acceptedBitMap[acceptedWordIndex] = acceptedBitMap[acceptedWordIndex] | (1 << acceptedBitIndex);
  }

  function acceptGrant(
    uint256 index,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isGrantAccepted(index), "Grant already accepted");

    // Verify the merkle proof.
    //
    /// @dev Per the Warning in
    /// https://github.com/ethereum/solidity/blob/v0.6.12/docs/abi-spec.rst#non-standard-packed-mode,
    /// it is important that no more than one of the arguments to `abi.encodePacked()` here be a
    /// dynamic type (see definition in
    /// https://github.com/ethereum/solidity/blob/v0.6.12/docs/abi-spec.rst#formal-specification-of-the-encoding).
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount, vestingLength, cliffLength, vestingInterval));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it accepted and perform the granting.
    _setGrantAccepted(index);
    uint256 tokenId = ICommunityRewards(communityRewards).grant(
      msg.sender,
      amount,
      vestingLength,
      cliffLength,
      vestingInterval
    );

    emit GrantAccepted(tokenId, index, msg.sender, amount, vestingLength, cliffLength, vestingInterval);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/interfaces/IMerkleDistributor.sol.
pragma solidity 0.6.12;

/// @notice Enables the granting of a CommunityRewards grant, if the grant details exist in this
/// contract's Merkle root.
interface IMerkleDistributor {
  /// @notice Returns the address of the CommunityRewards contract whose grants are distributed by this contract.
  function communityRewards() external view returns (address);

  /// @notice Returns the merkle root of the merkle tree containing grant details available to accept.
  function merkleRoot() external view returns (bytes32);

  /// @notice Returns true if the index has been marked accepted.
  function isGrantAccepted(uint256 index) external view returns (bool);

  /// @notice Causes the sender to accept the grant consisting of the given details. Reverts if
  /// the inputs (which includes who the sender is) are invalid.
  function acceptGrant(
    uint256 index,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval,
    bytes32[] calldata merkleProof
  ) external;

  /// @notice This event is triggered whenever a call to #acceptGrant succeeds.
  event GrantAccepted(
    uint256 indexed tokenId,
    uint256 indexed index,
    address indexed account,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../core/BaseUpgradeablePausable.sol";
import "../core/ConfigHelper.sol";
import "../core/CreditLine.sol";
import "../core/GoldfinchConfig.sol";
import "../../interfaces/IERC20withDec.sol";
import "../../interfaces/ITranchedPool.sol";
import "../../interfaces/IBorrower.sol";
import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title Goldfinch's Borrower contract
 * @notice These contracts represent the a convenient way for a borrower to interact with Goldfinch
 *  They are 100% optional. However, they let us add many sophisticated and convient features for borrowers
 *  while still keeping our core protocol small and secure. We therefore expect most borrowers will use them.
 *  This contract is the "official" borrower contract that will be maintained by Goldfinch governance. However,
 *  in theory, anyone can fork or create their own version, or not use any contract at all. The core functionality
 *  is completely agnostic to whether it is interacting with a contract or an externally owned account (EOA).
 * @author Goldfinch
 */

contract Borrower is BaseUpgradeablePausable, BaseRelayRecipient, IBorrower {
  using SafeMath for uint256;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  address private constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address private constant BUSD_ADDRESS = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
  address private constant GUSD_ADDRESS = address(0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
  address private constant DAI_ADDRESS = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  function initialize(address owner, address _config) external override initializer {
    require(owner != address(0) && _config != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = GoldfinchConfig(_config);

    trustedForwarder = config.trustedForwarderAddress();

    // Handle default approvals. Pool, and OneInch for maximum amounts
    address oneInch = config.oneInchAddress();
    IERC20withDec usdc = config.getUSDC();
    usdc.approve(oneInch, uint256(-1));
    bytes memory data = abi.encodeWithSignature("approve(address,uint256)", oneInch, uint256(-1));
    invoke(USDT_ADDRESS, data);
    invoke(BUSD_ADDRESS, data);
    invoke(GUSD_ADDRESS, data);
    invoke(DAI_ADDRESS, data);
  }

  function lockJuniorCapital(address poolAddress) external onlyAdmin {
    ITranchedPool(poolAddress).lockJuniorCapital();
  }

  function lockPool(address poolAddress) external onlyAdmin {
    ITranchedPool(poolAddress).lockPool();
  }

  /**
   * @notice Allows a borrower to drawdown on their creditline through the CreditDesk.
   * @param poolAddress The creditline from which they would like to drawdown
   * @param amount The amount, in USDC atomic units, that a borrower wishes to drawdown
   * @param addressToSendTo The address where they would like the funds sent. If the zero address is passed,
   *  it will be defaulted to the contracts address (msg.sender). This is a convenience feature for when they would
   *  like the funds sent to an exchange or alternate wallet, different from the authentication address
   */
  function drawdown(
    address poolAddress,
    uint256 amount,
    address addressToSendTo
  ) external onlyAdmin {
    ITranchedPool(poolAddress).drawdown(amount);

    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    transferERC20(config.usdcAddress(), addressToSendTo, amount);
  }

  function drawdownWithSwapOnOneInch(
    address poolAddress,
    uint256 amount,
    address addressToSendTo,
    address toToken,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) public onlyAdmin {
    // Drawdown to the Borrower contract
    ITranchedPool(poolAddress).drawdown(amount);

    // Do the swap
    swapOnOneInch(config.usdcAddress(), toToken, amount, minTargetAmount, exchangeDistribution);

    // Default to sending to the owner, and don't let funds stay in this contract
    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    // Fulfill the send to
    bytes memory _data = abi.encodeWithSignature("balanceOf(address)", address(this));
    uint256 receivedAmount = toUint256(invoke(toToken, _data));
    transferERC20(toToken, addressToSendTo, receivedAmount);
  }

  function transferERC20(
    address token,
    address to,
    uint256 amount
  ) public onlyAdmin {
    bytes memory _data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
    invoke(token, _data);
  }

  /**
   * @notice Allows a borrower to payback loans by calling the `pay` function directly on the CreditDesk
   * @param poolAddress The credit line to be paid back
   * @param amount The amount, in USDC atomic units, that the borrower wishes to pay
   */
  function pay(address poolAddress, uint256 amount) external onlyAdmin {
    IERC20withDec usdc = config.getUSDC();
    bool success = usdc.transferFrom(_msgSender(), address(this), amount);
    require(success, "Failed to transfer USDC");
    _transferAndPay(usdc, poolAddress, amount);
  }

  function payMultiple(address[] calldata pools, uint256[] calldata amounts) external onlyAdmin {
    require(pools.length == amounts.length, "Pools and amounts must be the same length");

    uint256 totalAmount;
    for (uint256 i = 0; i < amounts.length; i++) {
      totalAmount = totalAmount.add(amounts[i]);
    }

    IERC20withDec usdc = config.getUSDC();
    // Do a single transfer, which is cheaper
    bool success = usdc.transferFrom(_msgSender(), address(this), totalAmount);
    require(success, "Failed to transfer USDC");

    for (uint256 i = 0; i < amounts.length; i++) {
      _transferAndPay(usdc, pools[i], amounts[i]);
    }
  }

  function payInFull(address poolAddress, uint256 amount) external onlyAdmin {
    IERC20withDec usdc = config.getUSDC();
    bool success = usdc.transferFrom(_msgSender(), address(this), amount);
    require(success, "Failed to transfer USDC");

    _transferAndPay(usdc, poolAddress, amount);
    require(ITranchedPool(poolAddress).creditLine().balance() == 0, "Failed to fully pay off creditline");
  }

  function payWithSwapOnOneInch(
    address poolAddress,
    uint256 originAmount,
    address fromToken,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) external onlyAdmin {
    transferFrom(fromToken, _msgSender(), address(this), originAmount);
    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, minTargetAmount, exchangeDistribution);
    uint256 usdcBalance = usdc.balanceOf(address(this));
    _transferAndPay(usdc, poolAddress, usdcBalance);
  }

  function payMultipleWithSwapOnOneInch(
    address[] calldata pools,
    uint256[] calldata minAmounts,
    uint256 originAmount,
    address fromToken,
    uint256[] calldata exchangeDistribution
  ) external onlyAdmin {
    require(pools.length == minAmounts.length, "Pools and amounts must be the same length");

    uint256 totalMinAmount = 0;
    for (uint256 i = 0; i < minAmounts.length; i++) {
      totalMinAmount = totalMinAmount.add(minAmounts[i]);
    }

    transferFrom(fromToken, _msgSender(), address(this), originAmount);

    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, totalMinAmount, exchangeDistribution);

    for (uint256 i = 0; i < minAmounts.length; i++) {
      _transferAndPay(usdc, pools[i], minAmounts[i]);
    }

    uint256 remainingUSDC = usdc.balanceOf(address(this));
    if (remainingUSDC > 0) {
      _transferAndPay(usdc, pools[0], remainingUSDC);
    }
  }

  function _transferAndPay(
    IERC20withDec usdc,
    address poolAddress,
    uint256 amount
  ) internal {
    ITranchedPool pool = ITranchedPool(poolAddress);
    // We don't use transferFrom since it would require a separate approval per creditline
    bool success = usdc.transfer(address(pool.creditLine()), amount);
    require(success, "USDC Transfer to creditline failed");
    pool.assess();
  }

  function transferFrom(
    address erc20,
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    bytes memory _data;
    // Do a low-level invoke on this transfer, since Tether fails if we use the normal IERC20 interface
    _data = abi.encodeWithSignature("transferFrom(address,address,uint256)", sender, recipient, amount);
    invoke(address(erc20), _data);
  }

  function swapOnOneInch(
    address fromToken,
    address toToken,
    uint256 originAmount,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) internal {
    bytes memory _data = abi.encodeWithSignature(
      "swap(address,address,uint256,uint256,uint256[],uint256)",
      fromToken,
      toToken,
      originAmount,
      minTargetAmount,
      exchangeDistribution,
      0
    );
    invoke(config.oneInchAddress(), _data);
  }

  /**
   * @notice Performs a generic transaction.
   * @param _target The address for the transaction.
   * @param _data The data of the transaction.
   * Mostly copied from Argent:
   * https://github.com/argentlabs/argent-contracts/blob/develop/contracts/wallet/BaseWallet.sol#L111
   */
  function invoke(address _target, bytes memory _data) internal returns (bytes memory) {
    // External contracts can be compiled with different Solidity versions
    // which can cause "revert without reason" when called through,
    // for example, a standard IERC20 ABI compiled on the latest version.
    // This low-level call avoids that issue.

    bool success;
    bytes memory _res;
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = _target.call(_data);
    if (!success && _res.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    } else if (!success) {
      revert("VM: wallet invoke reverted");
    }
    return _res;
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }

  // OpenZeppelin contracts come with support for GSN _msgSender() (which just defaults to msg.sender)
  // Since there are two different versions of the function in the hierarchy, we need to instruct solidity to
  // use the relay recipient version which can actually pull the real sender from the parameters.
  // https://www.notion.so/My-contract-is-using-OpenZeppelin-How-do-I-add-GSN-support-2bee7e9d5f774a0cbb60d3a8de03e9fb
  function _msgSender() internal view override(ContextUpgradeSafe, BaseRelayRecipient) returns (address payable) {
    return BaseRelayRecipient._msgSender();
  }

  function _msgData() internal view override(ContextUpgradeSafe, BaseRelayRecipient) returns (bytes memory ret) {
    return BaseRelayRecipient._msgData();
  }

  function versionRecipient() external view override returns (string memory) {
    return "2.0.0";
  }
}

// SPDX-Licence-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBorrower {
  function initialize(address owner, address _config) external;
}

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity ^0.6.2;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./GoldfinchConfig.sol";
import "./BaseUpgradeablePausable.sol";
import "../../interfaces/IBorrower.sol";
import "../../interfaces/ITranchedPool.sol";
import "./ConfigHelper.sol";

/**
 * @title GoldfinchFactory
 * @notice Contract that allows us to create other contracts, such as CreditLines and BorrowerContracts
 *  Note GoldfinchFactory is a legacy name. More properly this can be considered simply the GoldfinchFactory
 * @author Goldfinch
 */

contract GoldfinchFactory is BaseUpgradeablePausable {
  GoldfinchConfig public config;

  /// Role to allow for pool creation
  bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");

  using ConfigHelper for GoldfinchConfig;

  event BorrowerCreated(address indexed borrower, address indexed owner);
  event PoolCreated(address indexed pool, address indexed borrower);
  event GoldfinchConfigUpdated(address indexed who, address configAddress);
  event CreditLineCreated(address indexed creditLine);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;
    _performUpgrade();
  }

  function performUpgrade() external onlyAdmin {
    _performUpgrade();
  }

  function _performUpgrade() internal {
    if (getRoleAdmin(BORROWER_ROLE) != OWNER_ROLE) {
      _setRoleAdmin(BORROWER_ROLE, OWNER_ROLE);
    }
  }

  /**
   * @notice Allows anyone to create a CreditLine contract instance
   * @dev There is no value to calling this function directly. It is only meant to be called
   *  by a TranchedPool during it's creation process.
   */
  function createCreditLine() external returns (address) {
    address creditLine = deployMinimal(config.creditLineImplementationAddress());
    emit CreditLineCreated(creditLine);
    return creditLine;
  }

  /**
   * @notice Allows anyone to create a Borrower contract instance
   * @param owner The address that will own the new Borrower instance
   */
  function createBorrower(address owner) external returns (address) {
    address _borrower = deployMinimal(config.borrowerImplementationAddress());
    IBorrower borrower = IBorrower(_borrower);
    borrower.initialize(owner, address(config));
    emit BorrowerCreated(address(borrower), owner);
    return address(borrower);
  }

  /**
   * @notice Allows anyone to create a new TranchedPool for a single borrower
   * @param _borrower The borrower for whom the CreditLine will be created
   * @param _juniorFeePercent The percent of senior interest allocated to junior investors, expressed as
   *  integer percents. eg. 20% is simply 20
   * @param _limit The maximum amount a borrower can drawdown from this CreditLine
   * @param _interestApr The interest amount, on an annualized basis (APR, so non-compounding), expressed as an integer.
   *  We assume 18 digits of precision. For example, to submit 15.34%, you would pass up 153400000000000000,
   *  and 5.34% would be 53400000000000000
   * @param _paymentPeriodInDays How many days in each payment period.
   *  ie. the frequency with which they need to make payments.
   * @param _termInDays Number of days in the credit term. It is used to set the `termEndTime` upon first drawdown.
   *  ie. The credit line should be fully paid off {_termIndays} days after the first drawdown.
   * @param _lateFeeApr The additional interest you will pay if you are late. For example, if this is 3%, and your
   *  normal rate is 15%, then you will pay 18% while you are late. Also expressed as an 18 decimal precision integer
   *
   * Requirements:
   *  You are the admin
   */
  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) external onlyAdminOrBorrower returns (address pool) {
    address tranchedPoolImplAddress = config.tranchedPoolAddress();
    pool = deployMinimal(tranchedPoolImplAddress);
    ITranchedPool(pool).initialize(
      address(config),
      _borrower,
      _juniorFeePercent,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays,
      _fundableAt,
      _allowedUIDTypes
    );
    emit PoolCreated(pool, _borrower);
    config.getPoolTokens().onPoolCreated(pool);
    return pool;
  }

  function createMigratedPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) external onlyCreditDesk returns (address pool) {
    address tranchedPoolImplAddress = config.migratedTranchedPoolAddress();
    pool = deployMinimal(tranchedPoolImplAddress);
    ITranchedPool(pool).initialize(
      address(config),
      _borrower,
      _juniorFeePercent,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays,
      _fundableAt,
      _allowedUIDTypes
    );
    emit PoolCreated(pool, _borrower);
    config.getPoolTokens().onPoolCreated(pool);
    return pool;
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  // Stolen from:
  // https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/ProxyFactory.sol
  function deployMinimal(address _logic) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(_logic);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }
    return proxy;
  }

  function isBorrower() public view returns (bool) {
    return hasRole(BORROWER_ROLE, _msgSender());
  }

  modifier onlyAdminOrBorrower() {
    require(isAdmin() || isBorrower(), "Must have admin or borrower role to perform this action");
    _;
  }

  modifier onlyCreditDesk() {
    require(msg.sender == config.creditDeskAddress(), "Only the CreditDesk can call this");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";

import "../library/SafeERC20Transfer.sol";
import "../protocol/core/ConfigHelper.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";
import "../interfaces/IPoolTokens.sol";
import "../interfaces/ITranchedPool.sol";
import "../interfaces/IBackerRewards.sol";

// Basically, Every time a interest payment comes back
// we keep a running total of dollars (totalInterestReceived) until it reaches the maxInterestDollarsEligible limit
// Every dollar of interest received from 0->maxInterestDollarsEligible
// has a allocated amount of rewards based on a sqrt function.

// When a interest payment comes in for a given Pool or the pool balance increases
// we recalculate the pool's accRewardsPerPrincipalDollar

// equation ref `_calculateNewGrossGFIRewardsForInterestAmount()`:
// (sqrtNewTotalInterest - sqrtOrigTotalInterest) / sqrtMaxInterestDollarsEligible * (totalRewards / totalGFISupply)

// When a PoolToken is minted, we set the mint price to the pool's current accRewardsPerPrincipalDollar
// Every time a PoolToken withdraws rewards, we determine the allocated rewards,
// increase that PoolToken's rewardsClaimed, and transfer the owner the gfi

contract BackerRewards is IBackerRewards, BaseUpgradeablePausable, SafeERC20Transfer {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using SafeMath for uint256;

  struct BackerRewardsInfo {
    uint256 accRewardsPerPrincipalDollar; // accumulator gfi per interest dollar
  }

  struct BackerRewardsTokenInfo {
    uint256 rewardsClaimed; // gfi claimed
    uint256 accRewardsPerPrincipalDollarAtMint; // Pool's accRewardsPerPrincipalDollar at PoolToken mint()
  }

  uint256 public totalRewards; // total amount of GFI rewards available, times 1e18
  uint256 public maxInterestDollarsEligible; // interest $ eligible for gfi rewards, times 1e18
  uint256 public totalInterestReceived; // counter of total interest repayments, times 1e6
  uint256 public totalRewardPercentOfTotalGFI; // totalRewards/totalGFISupply, times 1e18

  mapping(uint256 => BackerRewardsTokenInfo) public tokens; // poolTokenId -> BackerRewardsTokenInfo

  mapping(address => BackerRewardsInfo) public pools; // pool.address -> BackerRewardsInfo

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  /**
   * @notice Calculates the accRewardsPerPrincipalDollar for a given pool,
   when a interest payment is received by the protocol
   * @param _interestPaymentAmount The amount of total dollars the interest payment, expects 10^6 value
   */
  function allocateRewards(uint256 _interestPaymentAmount) external override onlyPool {
    // note: do not use a require statment because that will TranchedPool kill execution
    if (_interestPaymentAmount > 0) {
      _allocateRewards(_interestPaymentAmount);
    }
  }

  /**
   * @notice Set the total gfi rewards and the % of total GFI
   * @param _totalRewards The amount of GFI rewards available, expects 10^18 value
   */
  function setTotalRewards(uint256 _totalRewards) public onlyAdmin {
    totalRewards = _totalRewards;
    uint256 totalGFISupply = config.getGFI().totalSupply();
    totalRewardPercentOfTotalGFI = _totalRewards.mul(mantissa()).div(totalGFISupply).mul(100);
    emit BackerRewardsSetTotalRewards(_msgSender(), _totalRewards, totalRewardPercentOfTotalGFI);
  }

  /**
   * @notice Set the total interest received to date.
   This should only be called once on contract deploy.
   * @param _totalInterestReceived The amount of interest the protocol has received to date, expects 10^6 value
   */
  function setTotalInterestReceived(uint256 _totalInterestReceived) public onlyAdmin {
    totalInterestReceived = _totalInterestReceived;
    emit BackerRewardsSetTotalInterestReceived(_msgSender(), _totalInterestReceived);
  }

  /**
   * @notice Set the max dollars across the entire protocol that are eligible for GFI rewards
   * @param _maxInterestDollarsEligible The amount of interest dollars eligible for GFI rewards, expects 10^18 value
   */
  function setMaxInterestDollarsEligible(uint256 _maxInterestDollarsEligible) public onlyAdmin {
    maxInterestDollarsEligible = _maxInterestDollarsEligible;
    emit BackerRewardsSetMaxInterestDollarsEligible(_msgSender(), _maxInterestDollarsEligible);
  }

  /**
   * @notice When a pool token is minted for multiple drawdowns,
   set accRewardsPerPrincipalDollarAtMint to the current accRewardsPerPrincipalDollar price
   * @param tokenId Pool token id
   */
  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external override {
    require(_msgSender() == config.poolTokensAddress(), "Invalid sender!");
    require(config.getPoolTokens().validPool(poolAddress), "Invalid pool!");
    if (tokens[tokenId].accRewardsPerPrincipalDollarAtMint != 0) {
      return;
    }
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    require(poolAddress == tokenInfo.pool, "PoolAddress must equal PoolToken pool address");

    tokens[tokenId].accRewardsPerPrincipalDollarAtMint = pools[tokenInfo.pool].accRewardsPerPrincipalDollar;
  }

  /**
   * @notice Calculate the gross available gfi rewards for a PoolToken
   * @param tokenId Pool token id
   * @return The amount of GFI claimable
   */
  function poolTokenClaimableRewards(uint256 tokenId) public view returns (uint256) {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    // Note: If a TranchedPool is oversubscribed, reward allocation's scale down proportionately.

    uint256 diffOfAccRewardsPerPrincipalDollar = pools[tokenInfo.pool].accRewardsPerPrincipalDollar.sub(
      tokens[tokenId].accRewardsPerPrincipalDollarAtMint
    );
    uint256 rewardsClaimed = tokens[tokenId].rewardsClaimed.mul(mantissa());

    /*
      equation for token claimable rewards:
        token.principalAmount
        * (pool.accRewardsPerPrincipalDollar - token.accRewardsPerPrincipalDollarAtMint)
        - token.rewardsClaimed
    */

    return
      usdcToAtomic(tokenInfo.principalAmount).mul(diffOfAccRewardsPerPrincipalDollar).sub(rewardsClaimed).div(
        mantissa()
      );
  }

  /**
   * @notice PoolToken request to withdraw multiple PoolTokens allocated rewards
   * @param tokenIds Array of pool token id
   */
  function withdrawMultiple(uint256[] calldata tokenIds) public {
    require(tokenIds.length > 0, "TokensIds length must not be 0");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      withdraw(tokenIds[i]);
    }
  }

  /**
   * @notice PoolToken request to withdraw all allocated rewards
   * @param tokenId Pool token id
   */
  function withdraw(uint256 tokenId) public {
    uint256 totalClaimableRewards = poolTokenClaimableRewards(tokenId);
    uint256 poolTokenRewardsClaimed = tokens[tokenId].rewardsClaimed;
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    address poolAddr = tokenInfo.pool;
    require(config.getPoolTokens().validPool(poolAddr), "Invalid pool!");
    require(msg.sender == poolTokens.ownerOf(tokenId), "Must be owner of PoolToken");

    BaseUpgradeablePausable pool = BaseUpgradeablePausable(poolAddr);
    require(!pool.paused(), "Pool withdraw paused");

    ITranchedPool tranchedPool = ITranchedPool(poolAddr);
    require(!tranchedPool.creditLine().isLate(), "Pool is late on payments");

    tokens[tokenId].rewardsClaimed = poolTokenRewardsClaimed.add(totalClaimableRewards);
    safeERC20Transfer(config.getGFI(), poolTokens.ownerOf(tokenId), totalClaimableRewards);
    emit BackerRewardsClaimed(_msgSender(), tokenId, totalClaimableRewards);
  }

  /* Internal functions  */
  function _allocateRewards(uint256 _interestPaymentAmount) internal {
    uint256 _totalInterestReceived = totalInterestReceived;
    if (usdcToAtomic(_totalInterestReceived) >= maxInterestDollarsEligible) {
      return;
    }

    address _poolAddress = _msgSender();

    // Gross GFI Rewards earned for incoming interest dollars
    uint256 newGrossRewards = _calculateNewGrossGFIRewardsForInterestAmount(_interestPaymentAmount);

    ITranchedPool pool = ITranchedPool(_poolAddress);
    BackerRewardsInfo storage _poolInfo = pools[_poolAddress];

    uint256 totalJuniorDeposits = pool.totalJuniorDeposits();
    if (totalJuniorDeposits == 0) {
      return;
    }

    // example: (6708203932437400000000 * 10^18) / (100000*10^18)
    _poolInfo.accRewardsPerPrincipalDollar = _poolInfo.accRewardsPerPrincipalDollar.add(
      newGrossRewards.mul(mantissa()).div(usdcToAtomic(totalJuniorDeposits))
    );

    totalInterestReceived = _totalInterestReceived.add(_interestPaymentAmount);
  }

  /**
   * @notice Calculate the rewards earned for a given interest payment
   * @param _interestPaymentAmount interest payment amount times 1e6
   */
  function _calculateNewGrossGFIRewardsForInterestAmount(uint256 _interestPaymentAmount)
    internal
    view
    returns (uint256)
  {
    uint256 totalGFISupply = config.getGFI().totalSupply();

    // incoming interest payment, times * 1e18 divided by 1e6
    uint256 interestPaymentAmount = usdcToAtomic(_interestPaymentAmount);

    // all-time interest payments prior to the incoming amount, times 1e18
    uint256 _previousTotalInterestReceived = usdcToAtomic(totalInterestReceived);
    uint256 sqrtOrigTotalInterest = Babylonian.sqrt(_previousTotalInterestReceived);

    // sum of new interest payment + previous total interest payments, times 1e18
    uint256 newTotalInterest = usdcToAtomic(
      atomicToUSDC(_previousTotalInterestReceived).add(atomicToUSDC(interestPaymentAmount))
    );

    // interest payment passed the maxInterestDollarsEligible cap, should only partially be rewarded
    if (newTotalInterest > maxInterestDollarsEligible) {
      newTotalInterest = maxInterestDollarsEligible;
    }

    /*
      equation:
        (sqrtNewTotalInterest-sqrtOrigTotalInterest)
        * totalRewardPercentOfTotalGFI
        / sqrtMaxInterestDollarsEligible
        / 100
        * totalGFISupply
        / 10^18

      example scenario:
      - new payment = 5000*10^18
      - original interest received = 0*10^18
      - total reward percent = 3 * 10^18
      - max interest dollars = 1 * 10^27 ($1 billion)
      - totalGfiSupply = 100_000_000 * 10^18

      example math:
        (70710678118 - 0)
        * 3000000000000000000
        / 31622776601683
        / 100
        * 100000000000000000000000000
        / 10^18
        = 6708203932437400000000 (6,708.2039 GFI)
    */
    uint256 sqrtDiff = Babylonian.sqrt(newTotalInterest).sub(sqrtOrigTotalInterest);
    uint256 sqrtMaxInterestDollarsEligible = Babylonian.sqrt(maxInterestDollarsEligible);

    require(sqrtMaxInterestDollarsEligible > 0, "maxInterestDollarsEligible must not be zero");

    uint256 newGrossRewards = sqrtDiff
      .mul(totalRewardPercentOfTotalGFI)
      .div(sqrtMaxInterestDollarsEligible)
      .div(100)
      .mul(totalGFISupply)
      .div(mantissa());

    // Extra safety check to make sure the logic is capped at a ceiling of potential rewards
    // Calculating the gfi/$ for first dollar of interest to the protocol, and multiplying by new interest amount
    uint256 absoluteMaxGfiCheckPerDollar = Babylonian
      .sqrt((uint256)(1).mul(mantissa()))
      .mul(totalRewardPercentOfTotalGFI)
      .div(sqrtMaxInterestDollarsEligible)
      .div(100)
      .mul(totalGFISupply)
      .div(mantissa());
    require(
      newGrossRewards < absoluteMaxGfiCheckPerDollar.mul(newTotalInterest),
      "newGrossRewards cannot be greater then the max gfi per dollar"
    );

    return newGrossRewards;
  }

  function mantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }

  function usdcToAtomic(uint256 amount) internal pure returns (uint256) {
    return amount.mul(mantissa()).div(usdcMantissa());
  }

  function atomicToUSDC(uint256 amount) internal pure returns (uint256) {
    return amount.div(mantissa().div(usdcMantissa()));
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(_msgSender(), address(config));
  }

  /* ======== MODIFIERS  ======== */

  modifier onlyPool() {
    require(config.getPoolTokens().validPool(_msgSender()), "Invalid pool!");
    _;
  }

  /* ======== EVENTS ======== */
  event GoldfinchConfigUpdated(address indexed who, address configAddress);
  event BackerRewardsClaimed(address indexed owner, uint256 indexed tokenId, uint256 amount);
  event BackerRewardsSetTotalRewards(address indexed owner, uint256 totalRewards, uint256 totalRewardPercentOfTotalGFI);
  event BackerRewardsSetTotalInterestReceived(address indexed owner, uint256 totalInterestReceived);
  event BackerRewardsSetMaxInterestDollarsEligible(address indexed owner, uint256 maxInterestDollarsEligible);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../rewards/BackerRewards.sol";

contract TestBackerRewards is BackerRewards {
  address payable public sender;

  // solhint-disable-next-line modifiers/ensure-modifiers
  function _setSender(address payable _sender) public {
    sender = _sender;
  }

  function _msgSender() internal view override returns (address payable) {
    if (sender != address(0)) {
      return sender;
    } else {
      return super._msgSender();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

import "../../external/ERC721PresetMinterPauserAutoId.sol";
import "../../interfaces/IPoolTokens.sol";
import "../../interfaces/ITranchedPool.sol";
import "../../interfaces/IPoolTokens.sol";
import "../../interfaces/ISeniorPool.sol";
import "../../interfaces/IFidu.sol";
import "../core/BaseUpgradeablePausable.sol";
import "../core/GoldfinchConfig.sol";
import "../core/ConfigHelper.sol";
import "../../library/SafeERC20Transfer.sol";

contract TransferRestrictedVault is
  ERC721PresetMinterPauserAutoIdUpgradeSafe,
  ReentrancyGuardUpgradeSafe,
  SafeERC20Transfer
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using SafeMath for uint256;

  struct PoolTokenPosition {
    uint256 tokenId;
    uint256 lockedUntil;
  }

  struct FiduPosition {
    uint256 amount;
    uint256 lockedUntil;
  }

  // tokenId => poolTokenPosition
  mapping(uint256 => PoolTokenPosition) public poolTokenPositions;
  // tokenId => fiduPosition
  mapping(uint256 => FiduPosition) public fiduPositions;

  /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ReentrancyGuard_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained("Goldfinch V2 Accredited Investor Tokens", "GFI-V2-AI");
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();

    config = _config;

    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function depositJunior(ITranchedPool tranchedPool, uint256 amount) public nonReentrant {
    require(config.getGo().go(msg.sender), "This address has not been go-listed");
    safeERC20TransferFrom(config.getUSDC(), msg.sender, address(this), amount);

    approveSpender(address(tranchedPool), amount);
    uint256 poolTokenId = tranchedPool.deposit(uint256(ITranchedPool.Tranches.Junior), amount);

    uint256 transferRestrictionPeriodInSeconds = SECONDS_PER_DAY.mul(config.getTransferRestrictionPeriodInDays());

    _tokenIdTracker.increment();
    uint256 tokenId = _tokenIdTracker.current();
    poolTokenPositions[tokenId] = PoolTokenPosition({
      tokenId: poolTokenId,
      lockedUntil: block.timestamp.add(transferRestrictionPeriodInSeconds)
    });
    _mint(msg.sender, tokenId);
  }

  function depositJuniorWithPermit(
    ITranchedPool tranchedPool,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    depositJunior(tranchedPool, amount);
  }

  function depositSenior(uint256 amount) public nonReentrant {
    safeERC20TransferFrom(config.getUSDC(), msg.sender, address(this), amount);

    ISeniorPool seniorPool = config.getSeniorPool();
    approveSpender(address(seniorPool), amount);
    uint256 depositShares = seniorPool.deposit(amount);

    uint256 transferRestrictionPeriodInSeconds = SECONDS_PER_DAY.mul(config.getTransferRestrictionPeriodInDays());

    _tokenIdTracker.increment();
    uint256 tokenId = _tokenIdTracker.current();
    fiduPositions[tokenId] = FiduPosition({
      amount: depositShares,
      lockedUntil: block.timestamp.add(transferRestrictionPeriodInSeconds)
    });
    _mint(msg.sender, tokenId);
  }

  function depositSeniorWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    depositSenior(amount);
  }

  function withdrawSenior(uint256 tokenId, uint256 usdcAmount) public nonReentrant onlyTokenOwner(tokenId) {
    IFidu fidu = config.getFidu();
    ISeniorPool seniorPool = config.getSeniorPool();

    uint256 fiduBalanceBefore = fidu.balanceOf(address(this));

    uint256 receivedAmount = seniorPool.withdraw(usdcAmount);

    uint256 fiduUsed = fiduBalanceBefore.sub(fidu.balanceOf(address(this)));

    FiduPosition storage fiduPosition = fiduPositions[tokenId];

    uint256 fiduPositionAmount = fiduPosition.amount;
    require(fiduPositionAmount >= fiduUsed, "Not enough Fidu for withdrawal");
    fiduPosition.amount = fiduPositionAmount.sub(fiduUsed);

    safeERC20Transfer(config.getUSDC(), msg.sender, receivedAmount);
  }

  function withdrawSeniorInFidu(uint256 tokenId, uint256 shares) public nonReentrant onlyTokenOwner(tokenId) {
    FiduPosition storage fiduPosition = fiduPositions[tokenId];
    uint256 fiduPositionAmount = fiduPosition.amount;
    require(fiduPositionAmount >= shares, "Not enough Fidu for withdrawal");

    fiduPosition.amount = fiduPositionAmount.sub(shares);
    uint256 usdcAmount = config.getSeniorPool().withdrawInFidu(shares);
    safeERC20Transfer(config.getUSDC(), msg.sender, usdcAmount);
  }

  function withdrawJunior(uint256 tokenId, uint256 amount)
    public
    nonReentrant
    onlyTokenOwner(tokenId)
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  {
    PoolTokenPosition storage position = poolTokenPositions[tokenId];
    require(position.lockedUntil > 0, "Position is empty");

    IPoolTokens poolTokens = config.getPoolTokens();
    uint256 poolTokenId = position.tokenId;
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(poolTokenId);
    ITranchedPool pool = ITranchedPool(tokenInfo.pool);

    (interestWithdrawn, principalWithdrawn) = pool.withdraw(poolTokenId, amount);
    uint256 totalWithdrawn = interestWithdrawn.add(principalWithdrawn);
    safeERC20Transfer(config.getUSDC(), msg.sender, totalWithdrawn);
    return (interestWithdrawn, principalWithdrawn);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId // solhint-disable-line no-unused-vars
  ) internal virtual override(ERC721PresetMinterPauserAutoIdUpgradeSafe) {
    // AccreditedInvestor tokens can never be transferred. The underlying positions,
    // however, can be transferred after the timelock expires.
    require(from == address(0) || to == address(0), "TransferRestrictedVault tokens cannot be transferred");
  }

  /**
   * @dev This method assumes that positions are mutually exclusive i.e. that the token
   *  represents a position in either PoolTokens or Fidu, but not both.
   */
  function transferPosition(uint256 tokenId, address to) public nonReentrant {
    require(ownerOf(tokenId) == msg.sender, "Cannot transfer position of token you don't own");

    FiduPosition storage fiduPosition = fiduPositions[tokenId];
    if (fiduPosition.lockedUntil > 0) {
      require(
        block.timestamp >= fiduPosition.lockedUntil,
        "Underlying position cannot be transferred until lockedUntil"
      );

      transferFiduPosition(fiduPosition, to);
      delete fiduPositions[tokenId];
    }

    PoolTokenPosition storage poolTokenPosition = poolTokenPositions[tokenId];
    if (poolTokenPosition.lockedUntil > 0) {
      require(
        block.timestamp >= poolTokenPosition.lockedUntil,
        "Underlying position cannot be transferred until lockedUntil"
      );

      transferPoolTokenPosition(poolTokenPosition, to);
      delete poolTokenPositions[tokenId];
    }

    _burn(tokenId);
  }

  function transferPoolTokenPosition(PoolTokenPosition storage position, address to) internal {
    IPoolTokens poolTokens = config.getPoolTokens();
    poolTokens.safeTransferFrom(address(this), to, position.tokenId);
  }

  function transferFiduPosition(FiduPosition storage position, address to) internal {
    IFidu fidu = config.getFidu();
    safeERC20Transfer(fidu, to, position.amount);
  }

  function approveSpender(address spender, uint256 allowance) internal {
    IERC20withDec usdc = config.getUSDC();
    safeERC20Approve(usdc, spender, allowance);
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    require(ownerOf(tokenId) == msg.sender, "Only the token owner is allowed to call this function");
    _;
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

// contract IOneSplitConsts {
//     // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
//     uint256 internal constant FLAG_DISABLE_UNISWAP = 0x01;
//     uint256 internal constant DEPRECATED_FLAG_DISABLE_KYBER = 0x02; // Deprecated
//     uint256 internal constant FLAG_DISABLE_BANCOR = 0x04;
//     uint256 internal constant FLAG_DISABLE_OASIS = 0x08;
//     uint256 internal constant FLAG_DISABLE_COMPOUND = 0x10;
//     uint256 internal constant FLAG_DISABLE_FULCRUM = 0x20;
//     uint256 internal constant FLAG_DISABLE_CHAI = 0x40;
//     uint256 internal constant FLAG_DISABLE_AAVE = 0x80;
//     uint256 internal constant FLAG_DISABLE_SMART_TOKEN = 0x100;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_BDAI = 0x400;
//     uint256 internal constant FLAG_DISABLE_IEARN = 0x800;
//     uint256 internal constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
//     uint256 internal constant FLAG_DISABLE_CURVE_USDT = 0x2000;
//     uint256 internal constant FLAG_DISABLE_CURVE_Y = 0x4000;
//     uint256 internal constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
//     uint256 internal constant FLAG_DISABLE_WETH = 0x80000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_IDLE = 0x800000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
//     uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
//     uint256 internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDT = 0x400000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_WBTC = 0x800000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_TBTC = 0x1000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_RENBTC = 0x2000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
//     uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
//     uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
//     uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_SBTC = 0x40000000000;
//     uint256 internal constant FLAG_DISABLE_DMM = 0x80000000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_ALL = 0x100000000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400000000000;
//     uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_1 = 0x2000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_2 = 0x4000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_3 = 0x8000000000000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x10000000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x20000000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x40000000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP = 0x80000000000000; // Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_COMP = 0x100000000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_1 = 0x400000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_2 = 0x800000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_3 = 0x1000000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_4 = 0x2000000000000000;
//     uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN = 0x4000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_ALL = 0x8000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_ETH = 0x10000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_DAI = 0x20000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_USDC = 0x40000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_POOL_TOKEN = 0x80000000000000000;
// }

interface IOneSplit {
  function getExpectedReturn(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags // See constants in IOneSplit.sol
  ) external view returns (uint256 returnAmount, uint256[] memory distribution);

  function getExpectedReturnWithGas(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags, // See constants in IOneSplit.sol
    uint256 destTokenEthPriceTimesGasPrice
  )
    external
    view
    returns (
      uint256 returnAmount,
      uint256 estimateGasAmount,
      uint256[] memory distribution
    );

  function swap(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory distribution,
    uint256 flags
  ) external payable returns (uint256 returnAmount);
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";
import "../../Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeSafe is Initializable, ERC20UpgradeSafe, PausableUpgradeSafe {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {


    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";
import "../../Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeSafe is Initializable, ContextUpgradeSafe, ERC20UpgradeSafe {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {


    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

import "../access/AccessControl.sol";
import "../GSN/Context.sol";
import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Pausable.sol";
import "../Initializable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC20PresetMinterPauserUpgradeSafe is Initializable, ContextUpgradeSafe, AccessControlUpgradeSafe, ERC20BurnableUpgradeSafe, ERC20PausableUpgradeSafe {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */

    function initialize(string memory name, string memory symbol) public {
        __ERC20PresetMinterPauser_init(name, symbol);
    }

    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
    }

    function __ERC20PresetMinterPauser_init_unchained(string memory name, string memory symbol) internal initializer {


        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

    }


    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20UpgradeSafe, ERC20PausableUpgradeSafe) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/presets/ERC20PresetMinterPauser.sol";
import "./ConfigHelper.sol";

/**
 * @title Fidu
 * @notice Fidu (symbol: FIDU) is Goldfinch's liquidity token, representing shares
 *  in the Pool. When you deposit, we mint a corresponding amount of Fidu, and when you withdraw, we
 *  burn Fidu. The share price of the Pool implicitly represents the "exchange rate" between Fidu
 *  and USDC (or whatever currencies the Pool may allow withdraws in during the future)
 * @author Goldfinch
 */

contract Fidu is ERC20PresetMinterPauserUpgradeSafe {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  // $1 threshold to handle potential rounding errors, from differing decimals on Fidu and USDC;
  uint256 public constant ASSET_LIABILITY_MATCH_THRESHOLD = 1e6;
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  /*
    We are using our own initializer function so we can set the owner by passing it in.
    I would override the regular "initializer" function, but I can't because it's not marked
    as "virtual" in the parent contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(
    address owner,
    string calldata name,
    string calldata symbol,
    GoldfinchConfig _config
  ) external initializer {
    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC20_init_unchained(name, symbol);

    __ERC20Burnable_init_unchained();
    __Pausable_init_unchained();
    __ERC20Pausable_init_unchained();

    config = _config;

    _setupRole(MINTER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mintTo(address to, uint256 amount) public {
    require(canMint(amount), "Cannot mint: it would create an asset/liability mismatch");
    // This super call restricts to only the minter in its implementation, so we don't need to do it here.
    super.mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have the MINTER_ROLE
   */
  function burnFrom(address from, uint256 amount) public override {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: Must have minter role to burn");
    require(canBurn(amount), "Cannot burn: it would create an asset/liability mismatch");
    _burn(from, amount);
  }

  // Internal functions

  // canMint assumes that the USDC that backs the new shares has already been sent to the Pool
  function canMint(uint256 newAmount) internal view returns (bool) {
    ISeniorPool seniorPool = config.getSeniorPool();
    uint256 liabilities = totalSupply().add(newAmount).mul(seniorPool.sharePrice()).div(fiduMantissa());
    uint256 liabilitiesInDollars = fiduToUSDC(liabilities);
    uint256 _assets = seniorPool.assets();
    if (_assets >= liabilitiesInDollars) {
      return true;
    } else {
      return liabilitiesInDollars.sub(_assets) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    }
  }

  // canBurn assumes that the USDC that backed these shares has already been moved out the Pool
  function canBurn(uint256 amountToBurn) internal view returns (bool) {
    ISeniorPool seniorPool = config.getSeniorPool();
    uint256 liabilities = totalSupply().sub(amountToBurn).mul(seniorPool.sharePrice()).div(fiduMantissa());
    uint256 liabilitiesInDollars = fiduToUSDC(liabilities);
    uint256 _assets = seniorPool.assets();
    if (_assets >= liabilitiesInDollars) {
      return true;
    } else {
      return liabilitiesInDollars.sub(_assets) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    }
  }

  function fiduToUSDC(uint256 amount) internal pure returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  function fiduMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }

  function updateGoldfinchConfig() external {
    require(hasRole(OWNER_ROLE, _msgSender()), "ERC20PresetMinterPauser: Must have minter role to change config");
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "./LeverageRatioStrategy.sol";
import "../../interfaces/ISeniorPoolStrategy.sol";
import "../../interfaces/ISeniorPool.sol";
import "../../interfaces/ITranchedPool.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract FixedLeverageRatioStrategy is LeverageRatioStrategy {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  function getLeverageRatio(ITranchedPool pool) public view override returns (uint256) {
    return config.getLeverageRatio();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "../../interfaces/ISeniorPoolStrategy.sol";
import "../../interfaces/ISeniorPool.sol";
import "../../interfaces/ITranchedPool.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

abstract contract LeverageRatioStrategy is BaseUpgradeablePausable, ISeniorPoolStrategy {
  using SafeMath for uint256;

  uint256 internal constant LEVERAGE_RATIO_DECIMALS = 1e18;

  /**
   * @notice Determines how much money to invest in the senior tranche based on what is committed to the junior
   * tranche, what is committed to the senior tranche, and a leverage ratio to the junior tranche. Because
   * it takes into account what is already committed to the senior tranche, the value returned by this
   * function can be used "idempotently" to achieve the investment target amount without exceeding that target.
   * @param seniorPool The senior pool to invest from
   * @param pool The tranched pool to invest into (as the senior)
   * @return The amount of money to invest into the tranched pool's senior tranche, from the senior pool
   */
  function invest(ISeniorPool seniorPool, ITranchedPool pool) public view override returns (uint256) {
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Junior));
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Senior));

    // If junior capital is not yet invested, or pool already locked, then don't invest anything.
    if (juniorTranche.lockedUntil == 0 || seniorTranche.lockedUntil > 0) {
      return 0;
    }

    return _invest(pool, juniorTranche, seniorTranche);
  }

  /**
   * @notice A companion of `invest()`: determines how much would be returned by `invest()`, as the
   * value to invest into the senior tranche, if the junior tranche were locked and the senior tranche
   * were not locked.
   * @param seniorPool The senior pool to invest from
   * @param pool The tranched pool to invest into (as the senior)
   * @return The amount of money to invest into the tranched pool's senior tranche, from the senior pool
   */
  function estimateInvestment(ISeniorPool seniorPool, ITranchedPool pool) public view override returns (uint256) {
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Junior));
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Senior));

    return _invest(pool, juniorTranche, seniorTranche);
  }

  function _invest(
    ITranchedPool pool,
    ITranchedPool.TrancheInfo memory juniorTranche,
    ITranchedPool.TrancheInfo memory seniorTranche
  ) internal view returns (uint256) {
    uint256 juniorCapital = juniorTranche.principalDeposited;
    uint256 existingSeniorCapital = seniorTranche.principalDeposited;
    uint256 seniorTarget = juniorCapital.mul(getLeverageRatio(pool)).div(LEVERAGE_RATIO_DECIMALS);

    if (existingSeniorCapital >= seniorTarget) {
      return 0;
    }

    return seniorTarget.sub(existingSeniorCapital);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "./LeverageRatioStrategy.sol";
import "../../interfaces/ISeniorPoolStrategy.sol";
import "../../interfaces/ISeniorPool.sol";
import "../../interfaces/ITranchedPool.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract DynamicLeverageRatioStrategy is LeverageRatioStrategy {
  bytes32 public constant LEVERAGE_RATIO_SETTER_ROLE = keccak256("LEVERAGE_RATIO_SETTER_ROLE");

  struct LeverageRatioInfo {
    uint256 leverageRatio;
    uint256 juniorTrancheLockedUntil;
  }

  // tranchedPoolAddress => leverageRatioInfo
  mapping(address => LeverageRatioInfo) public ratios;

  event LeverageRatioUpdated(
    address indexed pool,
    uint256 leverageRatio,
    uint256 juniorTrancheLockedUntil,
    bytes32 version
  );

  function initialize(address owner) public initializer {
    require(owner != address(0), "Owner address cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    _setupRole(LEVERAGE_RATIO_SETTER_ROLE, owner);

    _setRoleAdmin(LEVERAGE_RATIO_SETTER_ROLE, OWNER_ROLE);
  }

  function getLeverageRatio(ITranchedPool pool) public view override returns (uint256) {
    LeverageRatioInfo memory ratioInfo = ratios[address(pool)];
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Junior));
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Senior));

    require(ratioInfo.juniorTrancheLockedUntil > 0, "Leverage ratio has not been set yet.");
    if (seniorTranche.lockedUntil > 0) {
      // The senior tranche is locked. Coherence check: we expect locking the senior tranche to have
      // updated `juniorTranche.lockedUntil` (compared to its value when `setLeverageRatio()` was last
      // called successfully).
      require(
        ratioInfo.juniorTrancheLockedUntil < juniorTranche.lockedUntil,
        "Expected junior tranche `lockedUntil` to have been updated."
      );
    } else {
      require(
        ratioInfo.juniorTrancheLockedUntil == juniorTranche.lockedUntil,
        "Leverage ratio is obsolete. Wait for its recalculation."
      );
    }

    return ratioInfo.leverageRatio;
  }

  /**
   * @notice Updates the leverage ratio for the specified tranched pool. The combination of the
   * `juniorTranchedLockedUntil` param and the `version` param in the event emitted by this
   * function are intended to enable an outside observer to verify the computation of the leverage
   * ratio set by calls of this function.
   * @param pool The tranched pool whose leverage ratio to update.
   * @param leverageRatio The leverage ratio value to set for the tranched pool.
   * @param juniorTrancheLockedUntil The `lockedUntil` timestamp, of the tranched pool's
   * junior tranche, to which this calculation of `leverageRatio` corresponds, i.e. the
   * value of the `lockedUntil` timestamp of the JuniorCapitalLocked event which the caller
   * is calling this function in response to having observed. By providing this timestamp
   * (plus an assumption that we can trust the caller to report this value accurately),
   * the caller enables this function to enforce that a leverage ratio that is obsolete in
   * the sense of having been calculated for an obsolete `lockedUntil` timestamp cannot be set.
   * @param version An arbitrary identifier included in the LeverageRatioUpdated event emitted
   * by this function, enabling the caller to describe how it calculated `leverageRatio`. Using
   * the bytes32 type accommodates using git commit hashes (both the current SHA1 hashes, which
   * require 20 bytes; and the future SHA256 hashes, which require 32 bytes) for this value.
   */
  function setLeverageRatio(
    ITranchedPool pool,
    uint256 leverageRatio,
    uint256 juniorTrancheLockedUntil,
    bytes32 version
  ) public onlySetterRole {
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Junior));
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Senior));

    // NOTE: We allow a `leverageRatio` of 0.
    require(
      leverageRatio <= 10 * LEVERAGE_RATIO_DECIMALS,
      "Leverage ratio must not exceed 10 (adjusted for decimals)."
    );

    require(juniorTranche.lockedUntil > 0, "Cannot set leverage ratio if junior tranche is not locked.");
    require(seniorTranche.lockedUntil == 0, "Cannot set leverage ratio if senior tranche is locked.");
    require(juniorTrancheLockedUntil == juniorTranche.lockedUntil, "Invalid `juniorTrancheLockedUntil` timestamp.");

    ratios[address(pool)] = LeverageRatioInfo({
      leverageRatio: leverageRatio,
      juniorTrancheLockedUntil: juniorTrancheLockedUntil
    });

    emit LeverageRatioUpdated(address(pool), leverageRatio, juniorTrancheLockedUntil, version);
  }

  modifier onlySetterRole() {
    require(
      hasRole(LEVERAGE_RATIO_SETTER_ROLE, _msgSender()),
      "Must have leverage-ratio setter role to perform this action"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "../token/ERC20/ERC20.sol";
import "./IERC20Permit.sol";
import "../cryptography/ECDSA.sol";
import "../utils/Counters.sol";
import "./EIP712.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) internal EIP712(name, "1") {
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

/**
 * @title GFI
 * @notice GFI is Goldfinch's governance token.
 * @author Goldfinch
 */
contract GFI is Context, AccessControl, ERC20Burnable, ERC20Pausable {
  using SafeMath for uint256;

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// The maximum number of tokens that can be minted
  uint256 public cap;

  event CapUpdated(address indexed who, uint256 cap);

  constructor(
    address owner,
    string memory name,
    string memory symbol,
    uint256 initialCap
  ) public ERC20(name, symbol) {
    cap = initialCap;

    _setupRole(MINTER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice create and send tokens to a specified address
   * @dev this function will fail if the caller attempts to mint over the current cap
   */
  function mint(address account, uint256 amount) public onlyMinter whenNotPaused {
    require(mintingAmountIsWithinCap(amount), "Cannot mint more than cap");
    _mint(account, amount);
  }

  /**
   * @notice sets the maximum number of tokens that can be minted
   * @dev the cap must be greater than the current total supply
   */
  function setCap(uint256 _cap) external onlyOwner {
    require(_cap >= totalSupply(), "Cannot decrease the cap below existing supply");
    cap = _cap;
    emit CapUpdated(_msgSender(), cap);
  }

  function mintingAmountIsWithinCap(uint256 amount) internal returns (bool) {
    return totalSupply().add(amount) <= cap;
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external onlyPauser {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external onlyPauser {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  modifier onlyOwner() {
    require(hasRole(OWNER_ROLE, _msgSender()), "Must be owner");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "Must be minter");
    _;
  }

  modifier onlyPauser() {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Must be pauser");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

// Taken from  https://github.com/opengsn/forwarder/blob/master/contracts/Forwarder.sol and adapted to work locally
// Main change is removing interface inheritance and adding a some debugging niceities
contract TestForwarder {
  using ECDSA for bytes32;

  struct ForwardRequest {
    address from;
    address to;
    uint256 value;
    uint256 gas;
    uint256 nonce;
    bytes data;
  }

  string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data";

  string public constant EIP712_DOMAIN_TYPE =
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"; // solhint-disable-line max-line-length

  mapping(bytes32 => bool) public typeHashes;
  mapping(bytes32 => bool) public domains;

  // Nonces of senders, used to prevent replay attacks
  mapping(address => uint256) private nonces;

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  function getNonce(address from) public view returns (uint256) {
    return nonces[from];
  }

  constructor() public {
    string memory requestType = string(abi.encodePacked("ForwardRequest(", GENERIC_PARAMS, ")"));
    registerRequestTypeInternal(requestType);
  }

  function verify(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes calldata suffixData,
    bytes calldata sig
  ) external view {
    _verifyNonce(req);
    _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
  }

  function execute(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes calldata suffixData,
    bytes calldata sig
  ) external payable returns (bool success, bytes memory ret) {
    _verifyNonce(req);
    _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
    _updateNonce(req);

    // solhint-disable-next-line avoid-low-level-calls
    (success, ret) = req.to.call{gas: req.gas, value: req.value}(abi.encodePacked(req.data, req.from));
    // Added by Goldfinch for debugging
    if (!success) {
      require(success, string(ret));
    }
    if (address(this).balance > 0) {
      //can't fail: req.from signed (off-chain) the request, so it must be an EOA...
      payable(req.from).transfer(address(this).balance);
    }
    return (success, ret);
  }

  function _verifyNonce(ForwardRequest memory req) internal view {
    require(nonces[req.from] == req.nonce, "nonce mismatch");
  }

  function _updateNonce(ForwardRequest memory req) internal {
    nonces[req.from]++;
  }

  function registerRequestType(string calldata typeName, string calldata typeSuffix) external {
    for (uint256 i = 0; i < bytes(typeName).length; i++) {
      bytes1 c = bytes(typeName)[i];
      require(c != "(" && c != ")", "invalid typename");
    }

    string memory requestType = string(abi.encodePacked(typeName, "(", GENERIC_PARAMS, ",", typeSuffix));
    registerRequestTypeInternal(requestType);
  }

  function registerDomainSeparator(string calldata name, string calldata version) external {
    uint256 chainId;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
      chainId := chainid()
    }

    bytes memory domainValue = abi.encode(
      keccak256(bytes(EIP712_DOMAIN_TYPE)),
      keccak256(bytes(name)),
      keccak256(bytes(version)),
      chainId,
      address(this)
    );

    bytes32 domainHash = keccak256(domainValue);

    domains[domainHash] = true;
    emit DomainRegistered(domainHash, domainValue);
  }

  function registerRequestTypeInternal(string memory requestType) internal {
    bytes32 requestTypehash = keccak256(bytes(requestType));
    typeHashes[requestTypehash] = true;
    emit RequestTypeRegistered(requestTypehash, requestType);
  }

  event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

  event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

  function _verifySig(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes memory suffixData,
    bytes memory sig
  ) internal view {
    require(domains[domainSeparator], "unregistered domain separator");
    require(typeHashes[requestTypeHash], "unregistered request typehash");
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, keccak256(_getEncoded(req, requestTypeHash, suffixData)))
    );
    require(digest.recover(sig) == req.from, "signature mismatch");
  }

  function _getEncoded(
    ForwardRequest memory req,
    bytes32 requestTypeHash,
    bytes memory suffixData
  ) public pure returns (bytes memory) {
    return
      abi.encodePacked(
        requestTypeHash,
        abi.encode(req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)),
        suffixData
      );
  }
}

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/drafts/ERC20Permit.sol";

contract TestERC20 is ERC20("USD Coin", "USDC"), ERC20Permit("USD Coin") {
  constructor(uint256 initialSupply, uint8 decimals) public {
    _setupDecimals(decimals);
    _mint(msg.sender, initialSupply);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../external/ERC721PresetMinterPauserAutoId.sol";
import "./GoldfinchConfig.sol";
import "./ConfigHelper.sol";
import "../../interfaces/ITranchedPool.sol";
import "../../interfaces/IPoolTokens.sol";

/**
 * @title PoolTokens
 * @notice PoolTokens is an ERC721 compliant contract, which can represent
 *  junior tranche or senior tranche shares of any of the borrower pools.
 * @author Goldfinch
 */

contract PoolTokens is IPoolTokens, ERC721PresetMinterPauserAutoIdUpgradeSafe {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  struct PoolInfo {
    uint256 totalMinted;
    uint256 totalPrincipalRedeemed;
    bool created;
  }

  // tokenId => tokenInfo
  mapping(uint256 => TokenInfo) public tokens;
  // poolAddress => poolInfo
  mapping(address => PoolInfo) public pools;

  event TokenMinted(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 tranche
  );

  event TokenRedeemed(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    uint256 tranche
  );

  event TokenBurned(address indexed owner, address indexed pool, uint256 indexed tokenId);

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC165_init_unchained();
    // This is setting name and symbol of the NFT's
    __ERC721_init_unchained("Goldfinch V2 Pool Tokens", "GFI-V2-PT");
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();

    config = _config;

    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice Called by pool to create a debt position in a particular tranche and amount
   * @param params Struct containing the tranche and the amount
   * @param to The address that should own the position
   * @return tokenId The token ID (auto-incrementing integer across all pools)
   */
  function mint(MintParams calldata params, address to)
    external
    virtual
    override
    onlyPool
    whenNotPaused
    returns (uint256 tokenId)
  {
    address poolAddress = _msgSender();
    tokenId = createToken(params, poolAddress);
    _mint(to, tokenId);
    config.getBackerRewards().setPoolTokenAccRewardsPerPrincipalDollarAtMint(_msgSender(), tokenId);
    emit TokenMinted(to, poolAddress, tokenId, params.principalAmount, params.tranche);
    return tokenId;
  }

  /**
   * @notice Updates a token to reflect the principal and interest amounts that have been redeemed.
   * @param tokenId The token id to update (must be owned by the pool calling this function)
   * @param principalRedeemed The incremental amount of principal redeemed (cannot be more than principal deposited)
   * @param interestRedeemed The incremental amount of interest redeemed
   */
  function redeem(
    uint256 tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed
  ) external virtual override onlyPool whenNotPaused {
    TokenInfo storage token = tokens[tokenId];
    address poolAddr = token.pool;
    require(token.pool != address(0), "Invalid tokenId");
    require(_msgSender() == poolAddr, "Only the token's pool can redeem");

    PoolInfo storage pool = pools[poolAddr];
    pool.totalPrincipalRedeemed = pool.totalPrincipalRedeemed.add(principalRedeemed);
    require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot redeem more than we minted");

    token.principalRedeemed = token.principalRedeemed.add(principalRedeemed);
    require(
      token.principalRedeemed <= token.principalAmount,
      "Cannot redeem more than principal-deposited amount for token"
    );
    token.interestRedeemed = token.interestRedeemed.add(interestRedeemed);

    emit TokenRedeemed(ownerOf(tokenId), poolAddr, tokenId, principalRedeemed, interestRedeemed, token.tranche);
  }

  /**
   * @dev Burns a specific ERC721 token, and removes the data from our mappings
   * @param tokenId uint256 id of the ERC721 token to be burned.
   */
  function burn(uint256 tokenId) external virtual override whenNotPaused {
    TokenInfo memory token = _getTokenInfo(tokenId);
    bool canBurn = _isApprovedOrOwner(_msgSender(), tokenId);
    bool fromTokenPool = _validPool(_msgSender()) && token.pool == _msgSender();
    address owner = ownerOf(tokenId);
    require(canBurn || fromTokenPool, "ERC721Burnable: caller cannot burn this token");
    require(token.principalRedeemed == token.principalAmount, "Can only burn fully redeemed tokens");
    destroyAndBurn(tokenId);
    emit TokenBurned(owner, token.pool, tokenId);
  }

  function getTokenInfo(uint256 tokenId) external view virtual override returns (TokenInfo memory) {
    return _getTokenInfo(tokenId);
  }

  /**
   * @notice Called by the GoldfinchFactory to register the pool as a valid pool. Only valid pools can mint/redeem
   * tokens
   * @param newPool The address of the newly created pool
   */
  function onPoolCreated(address newPool) external override onlyGoldfinchFactory {
    pools[newPool].created = true;
  }

  /**
   * @notice Returns a boolean representing whether the spender is the owner or the approved spender of the token
   * @param spender The address to check
   * @param tokenId The token id to check for
   * @return True if approved to redeem/transfer/burn the token, false if not
   */
  function isApprovedOrOwner(address spender, uint256 tokenId) external view override returns (bool) {
    return _isApprovedOrOwner(spender, tokenId);
  }

  function validPool(address sender) public view virtual override returns (bool) {
    return _validPool(sender);
  }

  function createToken(MintParams calldata params, address poolAddress) internal returns (uint256 tokenId) {
    PoolInfo storage pool = pools[poolAddress];

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();
    tokens[tokenId] = TokenInfo({
      pool: poolAddress,
      tranche: params.tranche,
      principalAmount: params.principalAmount,
      principalRedeemed: 0,
      interestRedeemed: 0
    });
    pool.totalMinted = pool.totalMinted.add(params.principalAmount);
    return tokenId;
  }

  function destroyAndBurn(uint256 tokenId) internal {
    delete tokens[tokenId];
    _burn(tokenId);
  }

  function _validPool(address poolAddress) internal view virtual returns (bool) {
    return pools[poolAddress].created;
  }

  function _getTokenInfo(uint256 tokenId) internal view returns (TokenInfo memory) {
    return tokens[tokenId];
  }

  /**
   * @notice Migrates to a new goldfinch config address
   */
  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyGoldfinchFactory() {
    require(_msgSender() == config.goldfinchFactoryAddress(), "Only Goldfinch factory is allowed");
    _;
  }

  modifier onlyPool() {
    require(_validPool(_msgSender()), "Invalid pool!");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/PoolTokens.sol";

contract TestPoolTokens is PoolTokens {
  bool public disablePoolValidation;
  address payable public sender;

  // solhint-disable-next-line modifiers/ensure-modifiers
  function _disablePoolValidation(bool shouldDisable) public {
    disablePoolValidation = shouldDisable;
  }

  // solhint-disable-next-line modifiers/ensure-modifiers
  function _setSender(address payable _sender) public {
    sender = _sender;
  }

  function _validPool(address _sender) internal view override returns (bool) {
    if (disablePoolValidation) {
      return true;
    } else {
      return super._validPool(_sender);
    }
  }

  function _msgSender() internal view override returns (address payable) {
    if (sender != address(0)) {
      return sender;
    } else {
      return super._msgSender();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IV2CreditLine.sol";
import "./IV1CreditLine.sol";
import "./ITranchedPool.sol";

abstract contract IMigratedTranchedPool is ITranchedPool {
  function migrateCreditLineToV2(
    IV1CreditLine clToMigrate,
    uint256 termEndTime,
    uint256 nextDueTime,
    uint256 interestAccruedAsOf,
    uint256 lastFullPaymentTime,
    uint256 totalInterestPaid
  ) external virtual returns (IV2CreditLine);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract IV1CreditLine {
  address public borrower;
  address public underwriter;
  uint256 public limit;
  uint256 public interestApr;
  uint256 public paymentPeriodInDays;
  uint256 public termInDays;
  uint256 public lateFeeApr;

  uint256 public balance;
  uint256 public interestOwed;
  uint256 public principalOwed;
  uint256 public termEndBlock;
  uint256 public nextDueBlock;
  uint256 public interestAccruedAsOfBlock;
  uint256 public writedownAmount;
  uint256 public lastFullPaymentBlock;

  function setLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./TranchedPool.sol";
import "../../interfaces/IV1CreditLine.sol";
import "../../interfaces/IMigratedTranchedPool.sol";

contract MigratedTranchedPool is TranchedPool, IMigratedTranchedPool {
  bool public migrated;

  function migrateCreditLineToV2(
    IV1CreditLine clToMigrate,
    uint256 termEndTime,
    uint256 nextDueTime,
    uint256 interestAccruedAsOf,
    uint256 lastFullPaymentTime,
    uint256 totalInterestPaid
  ) external override returns (IV2CreditLine) {
    require(msg.sender == config.creditDeskAddress(), "Only credit desk can call this");
    require(!migrated, "Already migrated");

    // Set accounting state vars.
    IV2CreditLine newCl = creditLine;
    newCl.setBalance(clToMigrate.balance());
    newCl.setInterestOwed(clToMigrate.interestOwed());
    newCl.setPrincipalOwed(clToMigrate.principalOwed());
    newCl.setTermEndTime(termEndTime);
    newCl.setNextDueTime(nextDueTime);
    newCl.setInterestAccruedAsOf(interestAccruedAsOf);
    newCl.setLastFullPaymentTime(lastFullPaymentTime);
    newCl.setTotalInterestAccrued(totalInterestPaid.add(clToMigrate.interestOwed()));

    migrateDeposits(clToMigrate, totalInterestPaid);

    migrated = true;

    return newCl;
  }

  function migrateDeposits(IV1CreditLine clToMigrate, uint256 totalInterestPaid) internal {
    // Mint junior tokens to the SeniorPool, equal to current cl balance;
    require(!locked(), "Pool has been locked");
    // Hardcode to always get the JuniorTranche, since the migration case is when
    // the senior pool took the entire investment. Which we're expressing as the junior tranche
    uint256 tranche = uint256(ITranchedPool.Tranches.Junior);
    TrancheInfo storage trancheInfo = getTrancheInfo(tranche);
    require(trancheInfo.lockedUntil == 0, "Tranche has been locked");
    trancheInfo.principalDeposited = clToMigrate.limit();
    IPoolTokens.MintParams memory params = IPoolTokens.MintParams({
      tranche: tranche,
      principalAmount: trancheInfo.principalDeposited
    });
    IPoolTokens poolTokens = config.getPoolTokens();

    uint256 tokenId = poolTokens.mint(params, config.seniorPoolAddress());
    uint256 balancePaid = creditLine.limit().sub(creditLine.balance());

    // Account for the implicit redemptions already made by the Legacy Pool
    _lockJuniorCapital(poolSlices.length - 1);
    _lockPool();
    PoolSlice storage currentSlice = poolSlices[poolSlices.length - 1];
    currentSlice.juniorTranche.lockedUntil = block.timestamp - 1;
    poolTokens.redeem(tokenId, balancePaid, totalInterestPaid);

    // Simulate the drawdown
    currentSlice.juniorTranche.principalSharePrice = 0;
    currentSlice.seniorTranche.principalSharePrice = 0;

    // Set junior's sharePrice correctly
    currentSlice.juniorTranche.applyByAmount(totalInterestPaid, balancePaid, totalInterestPaid, balancePaid);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "./Accountant.sol";
import "./CreditLine.sol";
import "./GoldfinchFactory.sol";
import "../../interfaces/IV1CreditLine.sol";
import "../../interfaces/IMigratedTranchedPool.sol";

/**
 * @title Goldfinch's CreditDesk contract
 * @notice Main entry point for borrowers and underwriters.
 *  Handles key logic for creating CreditLine's, borrowing money, repayment, etc.
 * @author Goldfinch
 */

contract CreditDesk is BaseUpgradeablePausable, ICreditDesk {
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  struct Underwriter {
    uint256 governanceLimit;
    address[] creditLines;
  }

  struct Borrower {
    address[] creditLines;
  }

  event PaymentApplied(
    address indexed payer,
    address indexed creditLine,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount
  );
  event PaymentCollected(address indexed payer, address indexed creditLine, uint256 paymentAmount);
  event DrawdownMade(address indexed borrower, address indexed creditLine, uint256 drawdownAmount);
  event CreditLineCreated(address indexed borrower, address indexed creditLine);
  event GovernanceUpdatedUnderwriterLimit(address indexed underwriter, uint256 newLimit);

  mapping(address => Underwriter) public underwriters;
  mapping(address => Borrower) private borrowers;
  mapping(address => address) private creditLines;

  /**
   * @notice Run only once, on initialization
   * @param owner The address of who should have the "OWNER_ROLE" of this contract
   * @param _config The address of the GoldfinchConfig contract
   */
  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  /**
   * @notice Sets a particular underwriter's limit of how much credit the DAO will allow them to "create"
   * @param underwriterAddress The address of the underwriter for whom the limit shall change
   * @param limit What the new limit will be set to
   * Requirements:
   *
   * - the caller must have the `OWNER_ROLE`.
   */
  function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit)
    external
    override
    onlyAdmin
    whenNotPaused
  {
    require(withinMaxUnderwriterLimit(limit), "This limit is greater than the max allowed by the protocol");
    underwriters[underwriterAddress].governanceLimit = limit;
    emit GovernanceUpdatedUnderwriterLimit(underwriterAddress, limit);
  }

  /**
   * @notice Allows a borrower to drawdown on their creditline.
   *  `amount` USDC is sent to the borrower, and the credit line accounting is updated.
   * @param creditLineAddress The creditline from which they would like to drawdown
   * @param amount The amount, in USDC atomic units, that a borrower wishes to drawdown
   *
   * Requirements:
   *
   * - the caller must be the borrower on the creditLine
   */
  function drawdown(address creditLineAddress, uint256 amount)
    external
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    CreditLine cl = CreditLine(creditLineAddress);
    Borrower storage borrower = borrowers[msg.sender];
    require(borrower.creditLines.length > 0, "No credit lines exist for this borrower");
    require(amount > 0, "Must drawdown more than zero");
    require(cl.borrower() == msg.sender, "You are not the borrower of this credit line");
    require(withinTransactionLimit(amount), "Amount is over the per-transaction limit");
    uint256 unappliedBalance = getUSDCBalance(creditLineAddress);
    require(
      withinCreditLimit(amount, unappliedBalance, cl),
      "The borrower does not have enough credit limit for this drawdown"
    );

    uint256 balance = cl.balance();

    if (balance == 0) {
      cl.setInterestAccruedAsOf(currentTime());
      cl.setLastFullPaymentTime(currentTime());
    }

    IPool pool = config.getPool();

    // If there is any balance on the creditline that has not been applied yet, then use that first before
    // drawing down from the pool. This is to support cases where the borrower partially pays back the
    // principal before the due date, but then decides to drawdown again
    uint256 amountToTransferFromCL;
    if (unappliedBalance > 0) {
      if (amount > unappliedBalance) {
        amountToTransferFromCL = unappliedBalance;
        amount = amount.sub(unappliedBalance);
      } else {
        amountToTransferFromCL = amount;
        amount = 0;
      }
      bool success = pool.transferFrom(creditLineAddress, msg.sender, amountToTransferFromCL);
      require(success, "Failed to drawdown");
    }

    (uint256 interestOwed, uint256 principalOwed) = updateAndGetInterestAndPrincipalOwedAsOf(cl, currentTime());
    balance = balance.add(amount);

    updateCreditLineAccounting(cl, balance, interestOwed, principalOwed);

    // Must put this after we update the credit line accounting, so we're using the latest
    // interestOwed
    require(!isLate(cl, currentTime()), "Cannot drawdown when payments are past due");
    emit DrawdownMade(msg.sender, address(cl), amount.add(amountToTransferFromCL));

    if (amount > 0) {
      bool success = pool.drawdown(msg.sender, amount);
      require(success, "Failed to drawdown");
    }
  }

  /**
   * @notice Allows a borrower to repay their loan. Payment is *collected* immediately (by sending it to
   *  the individual CreditLine), but it is not *applied* unless it is after the nextDueTime, or until we assess
   *  the credit line (ie. payment period end).
   *  Any amounts over the minimum payment will be applied to outstanding principal (reducing the effective
   *  interest rate). If there is still any left over, it will remain in the USDC Balance
   *  of the CreditLine, which is held distinct from the Pool amounts, and can not be withdrawn by LP's.
   * @param creditLineAddress The credit line to be paid back
   * @param amount The amount, in USDC atomic units, that a borrower wishes to pay
   */
  function pay(address creditLineAddress, uint256 amount)
    external
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    require(amount > 0, "Must pay more than zero");
    CreditLine cl = CreditLine(creditLineAddress);

    collectPayment(cl, amount);
    assessCreditLine(creditLineAddress);
  }

  /**
   * @notice Assesses a particular creditLine. This will apply payments, which will update accounting and
   *  distribute gains or losses back to the pool accordingly. This function is idempotent, and anyone
   *  is allowed to call it.
   * @param creditLineAddress The creditline that should be assessed.
   */
  function assessCreditLine(address creditLineAddress)
    public
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    CreditLine cl = CreditLine(creditLineAddress);
    // Do not assess until a full period has elapsed or past due
    require(cl.balance() > 0, "Must have balance to assess credit line");

    // Don't assess credit lines early!
    if (currentTime() < cl.nextDueTime() && !isLate(cl, currentTime())) {
      return;
    }

    uint256 timeToAssess = calculateNextDueTime(cl);
    cl.setNextDueTime(timeToAssess);

    // We always want to assess for the most recently *past* nextDueTime.
    // So if the recalculation above sets the nextDueTime into the future,
    // then ensure we pass in the one just before this.
    if (timeToAssess > currentTime()) {
      uint256 secondsPerPeriod = cl.paymentPeriodInDays().mul(SECONDS_PER_DAY);
      timeToAssess = timeToAssess.sub(secondsPerPeriod);
    }
    _applyPayment(cl, getUSDCBalance(address(cl)), timeToAssess);
  }

  function applyPayment(address creditLineAddress, uint256 amount)
    external
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    CreditLine cl = CreditLine(creditLineAddress);
    require(cl.borrower() == msg.sender, "You do not belong to this credit line");
    _applyPayment(cl, amount, currentTime());
  }

  function migrateV1CreditLine(
    address _clToMigrate,
    address borrower,
    uint256 termEndTime,
    uint256 nextDueTime,
    uint256 interestAccruedAsOf,
    uint256 lastFullPaymentTime,
    uint256 totalInterestPaid
  ) public onlyAdmin returns (address, address) {
    IV1CreditLine clToMigrate = IV1CreditLine(_clToMigrate);
    uint256 originalBalance = clToMigrate.balance();
    require(clToMigrate.limit() > 0, "Can't migrate empty credit line");
    require(originalBalance > 0, "Can't migrate credit line that's currently paid off");
    // Ensure it is a v1 creditline by calling a function that only exists on v1
    require(clToMigrate.nextDueBlock() > 0, "Invalid creditline");
    if (borrower == address(0)) {
      borrower = clToMigrate.borrower();
    }
    // We're migrating from 1e8 decimal precision of interest rates to 1e18
    // So multiply the legacy rates by 1e10 to normalize them.
    uint256 interestMigrationFactor = 1e10;
    uint256[] memory allowedUIDTypes;
    address pool = getGoldfinchFactory().createMigratedPool(
      borrower,
      20, // junior fee percent
      clToMigrate.limit(),
      clToMigrate.interestApr().mul(interestMigrationFactor),
      clToMigrate.paymentPeriodInDays(),
      clToMigrate.termInDays(),
      clToMigrate.lateFeeApr(),
      0,
      0,
      allowedUIDTypes
    );

    IV2CreditLine newCl = IMigratedTranchedPool(pool).migrateCreditLineToV2(
      clToMigrate,
      termEndTime,
      nextDueTime,
      interestAccruedAsOf,
      lastFullPaymentTime,
      totalInterestPaid
    );

    // Close out the original credit line
    clToMigrate.setLimit(0);
    clToMigrate.setBalance(0);

    // Some sanity checks on the migration
    require(newCl.balance() == originalBalance, "Balance did not migrate properly");
    require(newCl.interestAccruedAsOf() == interestAccruedAsOf, "Interest accrued as of did not migrate properly");
    return (address(newCl), pool);
  }

  /**
   * @notice Simple getter for the creditlines of a given underwriter
   * @param underwriterAddress The underwriter address you would like to see the credit lines of.
   */
  function getUnderwriterCreditLines(address underwriterAddress) public view returns (address[] memory) {
    return underwriters[underwriterAddress].creditLines;
  }

  /**
   * @notice Simple getter for the creditlines of a given borrower
   * @param borrowerAddress The borrower address you would like to see the credit lines of.
   */
  function getBorrowerCreditLines(address borrowerAddress) public view returns (address[] memory) {
    return borrowers[borrowerAddress].creditLines;
  }

  /**
   * @notice This function is only meant to be used by frontends. It returns the total
   * payment due for a given creditLine as of the provided timestamp. Returns 0 if no
   * payment is due (e.g. asOf is before the nextDueTime)
   * @param creditLineAddress The creditLine to calculate the payment for
   * @param asOf The timestamp to use for the payment calculation, if it is set to 0, uses the current time
   */
  function getNextPaymentAmount(address creditLineAddress, uint256 asOf)
    external
    view
    override
    onlyValidCreditLine(creditLineAddress)
    returns (uint256)
  {
    if (asOf == 0) {
      asOf = currentTime();
    }
    CreditLine cl = CreditLine(creditLineAddress);

    if (asOf < cl.nextDueTime() && !isLate(cl, currentTime())) {
      return 0;
    }

    (uint256 interestAccrued, uint256 principalAccrued) = Accountant.calculateInterestAndPrincipalAccrued(
      cl,
      asOf,
      config.getLatenessGracePeriodInDays()
    );
    return cl.interestOwed().add(interestAccrued).add(cl.principalOwed().add(principalAccrued));
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
  }

  /*
   * Internal Functions
   */

  /**
   * @notice Collects `amount` of payment for a given credit line. This sends money from the payer to the credit line.
   *  Note that payment is not *applied* when calling this function. Only collected (ie. held) for later application.
   * @param cl The CreditLine the payment will be collected for.
   * @param amount The amount, in USDC atomic units, to be collected
   */
  function collectPayment(CreditLine cl, uint256 amount) internal {
    require(withinTransactionLimit(amount), "Amount is over the per-transaction limit");

    emit PaymentCollected(msg.sender, address(cl), amount);

    bool success = config.getPool().transferFrom(msg.sender, address(cl), amount);
    require(success, "Failed to collect payment");
  }

  /**
   * @notice Applies `amount` of payment for a given credit line. This moves already collected money into the Pool.
   *  It also updates all the accounting variables. Note that interest is always paid back first, then principal.
   *  Any extra after paying the minimum will go towards existing principal (reducing the
   *  effective interest rate). Any extra after the full loan has been paid off will remain in the
   *  USDC Balance of the creditLine, where it will be automatically used for the next drawdown.
   * @param cl The CreditLine the payment will be collected for.
   * @param amount The amount, in USDC atomic units, to be applied
   * @param timestamp The timestamp on which accrual calculations should be based. This allows us
   *  to be precise when we assess a Credit Line
   */
  function _applyPayment(
    CreditLine cl,
    uint256 amount,
    uint256 timestamp
  ) internal {
    (uint256 paymentRemaining, uint256 interestPayment, uint256 principalPayment) = handlePayment(
      cl,
      amount,
      timestamp
    );

    IPool pool = config.getPool();

    if (interestPayment > 0 || principalPayment > 0) {
      emit PaymentApplied(cl.borrower(), address(cl), interestPayment, principalPayment, paymentRemaining);
      pool.collectInterestAndPrincipal(address(cl), interestPayment, principalPayment);
    }
  }

  function handlePayment(
    CreditLine cl,
    uint256 paymentAmount,
    uint256 timestamp
  )
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 interestOwed, uint256 principalOwed) = updateAndGetInterestAndPrincipalOwedAsOf(cl, timestamp);
    Accountant.PaymentAllocation memory pa = Accountant.allocatePayment(
      paymentAmount,
      cl.balance(),
      interestOwed,
      principalOwed
    );

    uint256 newBalance = cl.balance().sub(pa.principalPayment);
    // Apply any additional payment towards the balance
    newBalance = newBalance.sub(pa.additionalBalancePayment);
    uint256 totalPrincipalPayment = cl.balance().sub(newBalance);
    uint256 paymentRemaining = paymentAmount.sub(pa.interestPayment).sub(totalPrincipalPayment);

    updateCreditLineAccounting(
      cl,
      newBalance,
      interestOwed.sub(pa.interestPayment),
      principalOwed.sub(pa.principalPayment)
    );

    assert(paymentRemaining.add(pa.interestPayment).add(totalPrincipalPayment) == paymentAmount);

    return (paymentRemaining, pa.interestPayment, totalPrincipalPayment);
  }

  function isLate(CreditLine cl, uint256 timestamp) internal view returns (bool) {
    uint256 secondsElapsedSinceFullPayment = timestamp.sub(cl.lastFullPaymentTime());
    return secondsElapsedSinceFullPayment > cl.paymentPeriodInDays().mul(SECONDS_PER_DAY);
  }

  function getGoldfinchFactory() internal view returns (GoldfinchFactory) {
    return GoldfinchFactory(config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchFactory)));
  }

  function updateAndGetInterestAndPrincipalOwedAsOf(CreditLine cl, uint256 timestamp)
    internal
    returns (uint256, uint256)
  {
    (uint256 interestAccrued, uint256 principalAccrued) = Accountant.calculateInterestAndPrincipalAccrued(
      cl,
      timestamp,
      config.getLatenessGracePeriodInDays()
    );
    if (interestAccrued > 0) {
      // If we've accrued any interest, update interestAccruedAsOf to the time that we've
      // calculated interest for. If we've not accrued any interest, then we keep the old value so the next
      // time the entire period is taken into account.
      cl.setInterestAccruedAsOf(timestamp);
    }
    return (cl.interestOwed().add(interestAccrued), cl.principalOwed().add(principalAccrued));
  }

  function withinCreditLimit(
    uint256 amount,
    uint256 unappliedBalance,
    CreditLine cl
  ) internal view returns (bool) {
    return cl.balance().add(amount).sub(unappliedBalance) <= cl.limit();
  }

  function withinTransactionLimit(uint256 amount) internal view returns (bool) {
    return amount <= config.getNumber(uint256(ConfigOptions.Numbers.TransactionLimit));
  }

  function calculateNewTermEndTime(CreditLine cl, uint256 balance) internal view returns (uint256) {
    // If there's no balance, there's no loan, so there's no term end time
    if (balance == 0) {
      return 0;
    }
    // Don't allow any weird bugs where we add to your current end time. This
    // function should only be used on new credit lines, when we are setting them up
    if (cl.termEndTime() != 0) {
      return cl.termEndTime();
    }
    return currentTime().add(SECONDS_PER_DAY.mul(cl.termInDays()));
  }

  function calculateNextDueTime(CreditLine cl) internal view returns (uint256) {
    uint256 secondsPerPeriod = cl.paymentPeriodInDays().mul(SECONDS_PER_DAY);
    uint256 balance = cl.balance();
    uint256 nextDueTime = cl.nextDueTime();
    uint256 curTimestamp = currentTime();
    // You must have just done your first drawdown
    if (nextDueTime == 0 && balance > 0) {
      return curTimestamp.add(secondsPerPeriod);
    }

    // Active loan that has entered a new period, so return the *next* nextDueTime.
    // But never return something after the termEndTime
    if (balance > 0 && curTimestamp >= nextDueTime) {
      uint256 secondsToAdvance = (curTimestamp.sub(nextDueTime).div(secondsPerPeriod)).add(1).mul(secondsPerPeriod);
      nextDueTime = nextDueTime.add(secondsToAdvance);
      return Math.min(nextDueTime, cl.termEndTime());
    }

    // Your paid off, or have not taken out a loan yet, so no next due time.
    if (balance == 0 && nextDueTime != 0) {
      return 0;
    }
    // Active loan in current period, where we've already set the nextDueTime correctly, so should not change.
    if (balance > 0 && curTimestamp < nextDueTime) {
      return nextDueTime;
    }
    revert("Error: could not calculate next due time.");
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function underwriterCanCreateThisCreditLine(uint256 newAmount, Underwriter storage underwriter)
    internal
    view
    returns (bool)
  {
    uint256 underwriterLimit = underwriter.governanceLimit;
    require(underwriterLimit != 0, "underwriter does not have governance limit");
    uint256 creditCurrentlyExtended = getCreditCurrentlyExtended(underwriter);
    uint256 totalToBeExtended = creditCurrentlyExtended.add(newAmount);
    return totalToBeExtended <= underwriterLimit;
  }

  function withinMaxUnderwriterLimit(uint256 amount) internal view returns (bool) {
    return amount <= config.getNumber(uint256(ConfigOptions.Numbers.MaxUnderwriterLimit));
  }

  function getCreditCurrentlyExtended(Underwriter storage underwriter) internal view returns (uint256) {
    uint256 creditExtended;
    uint256 length = underwriter.creditLines.length;
    for (uint256 i = 0; i < length; i++) {
      CreditLine cl = CreditLine(underwriter.creditLines[i]);
      creditExtended = creditExtended.add(cl.limit());
    }
    return creditExtended;
  }

  function updateCreditLineAccounting(
    CreditLine cl,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) internal nonReentrant {
    // subtract cl from total loans outstanding
    totalLoansOutstanding = totalLoansOutstanding.sub(cl.balance());

    cl.setBalance(balance);
    cl.setInterestOwed(interestOwed);
    cl.setPrincipalOwed(principalOwed);

    // This resets lastFullPaymentTime. These conditions assure that they have
    // indeed paid off all their interest and they have a real nextDueTime. (ie. creditline isn't pre-drawdown)
    uint256 nextDueTime = cl.nextDueTime();
    if (interestOwed == 0 && nextDueTime != 0) {
      // If interest was fully paid off, then set the last full payment as the previous due time
      uint256 mostRecentLastDueTime;
      if (currentTime() < nextDueTime) {
        uint256 secondsPerPeriod = cl.paymentPeriodInDays().mul(SECONDS_PER_DAY);
        mostRecentLastDueTime = nextDueTime.sub(secondsPerPeriod);
      } else {
        mostRecentLastDueTime = nextDueTime;
      }
      cl.setLastFullPaymentTime(mostRecentLastDueTime);
    }

    // Add new amount back to total loans outstanding
    totalLoansOutstanding = totalLoansOutstanding.add(balance);

    cl.setTermEndTime(calculateNewTermEndTime(cl, balance)); // pass in balance as a gas optimization
    cl.setNextDueTime(calculateNextDueTime(cl));
  }

  function getUSDCBalance(address _address) internal view returns (uint256) {
    return config.getUSDC().balanceOf(_address);
  }

  modifier onlyValidCreditLine(address clAddress) {
    require(creditLines[clAddress] != address(0), "Unknown credit line");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/CreditDesk.sol";

contract TestCreditDesk is CreditDesk {
  // solhint-disable-next-line modifiers/ensure-modifiers
  function _setTotalLoansOutstanding(uint256 amount) public {
    totalLoansOutstanding = amount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../core/BaseUpgradeablePausable.sol";
import "../core/ConfigHelper.sol";
import "../core/CreditLine.sol";
import "../core/GoldfinchConfig.sol";
import "../../interfaces/IMigrate.sol";

/**
 * @title V2 Migrator Contract
 * @notice This is a one-time use contract solely for the purpose of migrating from our V1
 *  to our V2 architecture. It will be temporarily granted authority from the Goldfinch governance,
 *  and then revokes it's own authority and transfers it back to governance.
 * @author Goldfinch
 */

contract V2Migrator is BaseUpgradeablePausable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant GO_LISTER_ROLE = keccak256("GO_LISTER_ROLE");
  using SafeMath for uint256;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  mapping(address => address) public borrowerContracts;
  event CreditLineMigrated(address indexed owner, address indexed clToMigrate, address newCl, address tranchedPool);

  function initialize(address owner, address _config) external initializer {
    require(owner != address(0) && _config != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = GoldfinchConfig(_config);
  }

  function migratePhase1(GoldfinchConfig newConfig) external onlyAdmin {
    pauseEverything();
    migrateToNewConfig(newConfig);
    migrateToSeniorPool(newConfig);
  }

  function migrateCreditLines(
    GoldfinchConfig newConfig,
    address[][] calldata creditLinesToMigrate,
    uint256[][] calldata migrationData
  ) external onlyAdmin {
    IMigrate creditDesk = IMigrate(newConfig.creditDeskAddress());
    IGoldfinchFactory factory = newConfig.getGoldfinchFactory();
    for (uint256 i = 0; i < creditLinesToMigrate.length; i++) {
      address[] calldata clData = creditLinesToMigrate[i];
      uint256[] calldata data = migrationData[i];
      address clAddress = clData[0];
      address owner = clData[1];
      address borrowerContract = borrowerContracts[owner];
      if (borrowerContract == address(0)) {
        borrowerContract = factory.createBorrower(owner);
        borrowerContracts[owner] = borrowerContract;
      }
      (address newCl, address pool) = creditDesk.migrateV1CreditLine(
        clAddress,
        borrowerContract,
        data[0],
        data[1],
        data[2],
        data[3],
        data[4]
      );
      emit CreditLineMigrated(owner, clAddress, newCl, pool);
    }
  }

  function bulkAddToGoList(GoldfinchConfig newConfig, address[] calldata members) external onlyAdmin {
    newConfig.bulkAddToGoList(members);
  }

  function pauseEverything() internal {
    IMigrate(config.creditDeskAddress()).pause();
    IMigrate(config.poolAddress()).pause();
    IMigrate(config.fiduAddress()).pause();
  }

  function migrateToNewConfig(GoldfinchConfig newConfig) internal {
    uint256 key = uint256(ConfigOptions.Addresses.GoldfinchConfig);
    config.setAddress(key, address(newConfig));

    IMigrate(config.creditDeskAddress()).updateGoldfinchConfig();
    IMigrate(config.poolAddress()).updateGoldfinchConfig();
    IMigrate(config.fiduAddress()).updateGoldfinchConfig();
    IMigrate(config.goldfinchFactoryAddress()).updateGoldfinchConfig();

    key = uint256(ConfigOptions.Numbers.DrawdownPeriodInSeconds);
    newConfig.setNumber(key, 24 * 60 * 60);

    key = uint256(ConfigOptions.Numbers.TransferRestrictionPeriodInDays);
    newConfig.setNumber(key, 365);

    key = uint256(ConfigOptions.Numbers.LeverageRatio);
    // 1e18 is the LEVERAGE_RATIO_DECIMALS
    newConfig.setNumber(key, 3 * 1e18);
  }

  function upgradeImplementations(GoldfinchConfig _config, address[] calldata newDeployments) public {
    address newPoolAddress = newDeployments[0];
    address newCreditDeskAddress = newDeployments[1];
    address newFiduAddress = newDeployments[2];
    address newGoldfinchFactoryAddress = newDeployments[3];

    bytes memory data;
    IMigrate pool = IMigrate(_config.poolAddress());
    IMigrate creditDesk = IMigrate(_config.creditDeskAddress());
    IMigrate fidu = IMigrate(_config.fiduAddress());
    IMigrate goldfinchFactory = IMigrate(_config.goldfinchFactoryAddress());

    // Upgrade implementations
    pool.changeImplementation(newPoolAddress, data);
    creditDesk.changeImplementation(newCreditDeskAddress, data);
    fidu.changeImplementation(newFiduAddress, data);
    goldfinchFactory.changeImplementation(newGoldfinchFactoryAddress, data);
  }

  function migrateToSeniorPool(GoldfinchConfig newConfig) internal {
    IMigrate(config.fiduAddress()).grantRole(MINTER_ROLE, newConfig.seniorPoolAddress());
    IMigrate(config.poolAddress()).unpause();
    IMigrate(newConfig.poolAddress()).migrateToSeniorPool();
  }

  function closeOutMigration(GoldfinchConfig newConfig) external onlyAdmin {
    IMigrate fidu = IMigrate(newConfig.fiduAddress());
    IMigrate creditDesk = IMigrate(newConfig.creditDeskAddress());
    IMigrate oldPool = IMigrate(newConfig.poolAddress());
    IMigrate goldfinchFactory = IMigrate(newConfig.goldfinchFactoryAddress());

    fidu.unpause();
    fidu.renounceRole(MINTER_ROLE, address(this));
    fidu.renounceRole(OWNER_ROLE, address(this));
    fidu.renounceRole(PAUSER_ROLE, address(this));

    creditDesk.renounceRole(OWNER_ROLE, address(this));
    creditDesk.renounceRole(PAUSER_ROLE, address(this));

    oldPool.renounceRole(OWNER_ROLE, address(this));
    oldPool.renounceRole(PAUSER_ROLE, address(this));

    goldfinchFactory.renounceRole(OWNER_ROLE, address(this));
    goldfinchFactory.renounceRole(PAUSER_ROLE, address(this));

    config.renounceRole(PAUSER_ROLE, address(this));
    config.renounceRole(OWNER_ROLE, address(this));

    newConfig.renounceRole(OWNER_ROLE, address(this));
    newConfig.renounceRole(PAUSER_ROLE, address(this));
    newConfig.renounceRole(GO_LISTER_ROLE, address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract IMigrate {
  function pause() public virtual;

  function unpause() public virtual;

  function updateGoldfinchConfig() external virtual;

  function grantRole(bytes32 role, address assignee) external virtual;

  function renounceRole(bytes32 role, address self) external virtual;

  // Proxy methods
  function transferOwnership(address newOwner) external virtual;

  function changeImplementation(address newImplementation, bytes calldata data) external virtual;

  function owner() external view virtual returns (address);

  // CreditDesk
  function migrateV1CreditLine(
    address _clToMigrate,
    address borrower,
    uint256 termEndTime,
    uint256 nextDueTime,
    uint256 interestAccruedAsOf,
    uint256 lastFullPaymentTime,
    uint256 totalInterestPaid
  ) public virtual returns (address, address);

  // Pool
  function migrateToSeniorPool() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/Pool.sol";

contract TestPool is Pool {
  function _getNumShares(uint256 amount) public view returns (uint256) {
    return getNumShares(amount);
  }

  function _usdcMantissa() public pure returns (uint256) {
    return usdcMantissa();
  }

  function _fiduMantissa() public pure returns (uint256) {
    return fiduMantissa();
  }

  function _usdcToFidu(uint256 amount) public pure returns (uint256) {
    return usdcToFidu(amount);
  }

  function _setSharePrice(uint256 newSharePrice) public returns (uint256) {
    sharePrice = newSharePrice;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/Pool.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";

contract FakeV2CreditLine is BaseUpgradeablePausable {
  // Credit line terms
  address public borrower;
  address public underwriter;
  uint256 public limit;
  uint256 public interestApr;
  uint256 public paymentPeriodInDays;
  uint256 public termInDays;
  uint256 public lateFeeApr;

  // Accounting variables
  uint256 public balance;
  uint256 public interestOwed;
  uint256 public principalOwed;
  uint256 public termEndTime;
  uint256 public nextDueTime;
  uint256 public interestAccruedAsOf;
  uint256 public writedownAmount;
  uint256 public lastFullPaymentTime;

  function initialize(
    address owner,
    address _borrower,
    address _underwriter,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr
  ) public initializer {
    __BaseUpgradeablePausable__init(owner);
    borrower = _borrower;
    underwriter = _underwriter;
    limit = _limit;
    interestApr = _interestApr;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lateFeeApr = _lateFeeApr;
    interestAccruedAsOf = block.timestamp;
  }

  function anotherNewFunction() external pure returns (uint256) {
    return 42;
  }

  function authorizePool(address) external view onlyAdmin {
    // no-op
    return;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "../../interfaces/IGo.sol";
import "../../interfaces/IUniqueIdentity0612.sol";

contract Go is IGo, BaseUpgradeablePausable {
  address public override uniqueIdentity;

  using SafeMath for uint256;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  GoldfinchConfig public legacyGoList;
  uint256[11] public allIdTypes;
  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  function initialize(
    address owner,
    GoldfinchConfig _config,
    address _uniqueIdentity
  ) public initializer {
    require(
      owner != address(0) && address(_config) != address(0) && _uniqueIdentity != address(0),
      "Owner and config and UniqueIdentity addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    _performUpgrade();
    config = _config;
    uniqueIdentity = _uniqueIdentity;
  }

  function updateGoldfinchConfig() external override onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
    emit GoldfinchConfigUpdated(msg.sender, address(config));
  }

  function performUpgrade() external onlyAdmin {
    return _performUpgrade();
  }

  function _performUpgrade() internal {
    allIdTypes[0] = ID_TYPE_0;
    allIdTypes[1] = ID_TYPE_1;
    allIdTypes[2] = ID_TYPE_2;
    allIdTypes[3] = ID_TYPE_3;
    allIdTypes[4] = ID_TYPE_4;
    allIdTypes[5] = ID_TYPE_5;
    allIdTypes[6] = ID_TYPE_6;
    allIdTypes[7] = ID_TYPE_7;
    allIdTypes[8] = ID_TYPE_8;
    allIdTypes[9] = ID_TYPE_9;
    allIdTypes[10] = ID_TYPE_10;
  }

  /**
   * @notice sets the config that will be used as the source of truth for the go
   * list instead of the config currently associated. To use the associated config for to list, set the override
   * to the null address.
   */
  function setLegacyGoList(GoldfinchConfig _legacyGoList) external onlyAdmin {
    legacyGoList = _legacyGoList;
  }

  /**
   * @notice Returns whether the provided account is go-listed for use of the Goldfinch protocol
   * for any of the UID token types.
   * This status is defined as: whether `balanceOf(account, id)` on the UniqueIdentity
   * contract is non-zero (where `id` is a supported token id on UniqueIdentity), falling back to the
   * account's status on the legacy go-list maintained on GoldfinchConfig.
   * @param account The account whose go status to obtain
   * @return The account's go status
   */
  function go(address account) public view override returns (bool) {
    require(account != address(0), "Zero address is not go-listed");

    if (_getLegacyGoList().goList(account) || IUniqueIdentity0612(uniqueIdentity).balanceOf(account, ID_TYPE_0) > 0) {
      return true;
    }

    // start loop at index 1 because we checked index 0 above
    for (uint256 i = 1; i < allIdTypes.length; ++i) {
      uint256 idTypeBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(account, allIdTypes[i]);
      if (idTypeBalance > 0) {
        return true;
      }
    }
    return false;
  }

  /**
   * @notice Returns whether the provided account is go-listed for use of the Goldfinch protocol
   * for defined UID token types
   * @param account The account whose go status to obtain
   * @param onlyIdTypes Array of id types to check balances
   * @return The account's go status
   */
  function goOnlyIdTypes(address account, uint256[] memory onlyIdTypes) public view override returns (bool) {
    require(account != address(0), "Zero address is not go-listed");
    GoldfinchConfig goListSource = _getLegacyGoList();
    for (uint256 i = 0; i < onlyIdTypes.length; ++i) {
      if (onlyIdTypes[i] == ID_TYPE_0 && goListSource.goList(account)) {
        return true;
      }
      uint256 idTypeBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(account, onlyIdTypes[i]);
      if (idTypeBalance > 0) {
        return true;
      }
    }
    return false;
  }

  /**
   * @notice Returns whether the provided account is go-listed for use of the SeniorPool on the Goldfinch protocol.
   * @param account The account whose go status to obtain
   * @return The account's go status
   */
  function goSeniorPool(address account) public view override returns (bool) {
    require(account != address(0), "Zero address is not go-listed");
    if (account == config.stakingRewardsAddress() || _getLegacyGoList().goList(account)) {
      return true;
    }
    uint256[2] memory seniorPoolIdTypes = [ID_TYPE_0, ID_TYPE_1];
    for (uint256 i = 0; i < seniorPoolIdTypes.length; ++i) {
      uint256 idTypeBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(account, seniorPoolIdTypes[i]);
      if (idTypeBalance > 0) {
        return true;
      }
    }
    return false;
  }

  function _getLegacyGoList() internal view returns (GoldfinchConfig) {
    return address(legacyGoList) == address(0) ? config : legacyGoList;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/// @dev This interface provides a subset of the functionality of the IUniqueIdentity
/// interface -- namely, the subset of functionality needed by Goldfinch protocol contracts
/// compiled with Solidity version 0.6.12.
interface IUniqueIdentity0612 {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/GoldfinchConfig.sol";

contract TestTheConfig {
  address public poolAddress = 0xBAc2781706D0aA32Fb5928c9a5191A13959Dc4AE;
  address public clImplAddress = 0xc783df8a850f42e7F7e57013759C285caa701eB6;
  address public goldfinchFactoryAddress = 0x0afFE1972479c386A2Ab21a27a7f835361B6C0e9;
  address public fiduAddress = 0xf3c9B38c155410456b5A98fD8bBf5E35B87F6d96;
  address public creditDeskAddress = 0xeAD9C93b79Ae7C1591b1FB5323BD777E86e150d4;
  address public treasuryReserveAddress = 0xECd9C93B79AE7C1591b1fB5323BD777e86E150d5;
  address public trustedForwarderAddress = 0x956868751Cc565507B3B58E53a6f9f41B56bed74;
  address public cUSDCAddress = 0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1;
  address public goldfinchConfigAddress = address(8);

  function testTheEnums(address configAddress) public {
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TransactionLimit), 1);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TotalFundsLimit), 2);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.MaxUnderwriterLimit), 3);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.ReserveDenominator), 4);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator), 5);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays), 6);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LatenessMaxDays), 7);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.DrawdownPeriodInSeconds), 8);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TransferRestrictionPeriodInDays), 9);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LeverageRatio), 10);

    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.Fidu), fiduAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.Pool), poolAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.CreditDesk), creditDeskAddress);
    GoldfinchConfig(configAddress).setAddress(
      uint256(ConfigOptions.Addresses.GoldfinchFactory),
      goldfinchFactoryAddress
    );
    GoldfinchConfig(configAddress).setAddress(
      uint256(ConfigOptions.Addresses.TrustedForwarder),
      trustedForwarderAddress
    );
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.CUSDCContract), cUSDCAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.GoldfinchConfig), goldfinchConfigAddress);

    GoldfinchConfig(configAddress).setTreasuryReserve(treasuryReserveAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/GoldfinchConfig.sol";

contract TestGoldfinchConfig is GoldfinchConfig {
  function setAddressForTest(uint256 addressKey, address newAddress) public {
    addresses[addressKey] = newAddress;
  }
}