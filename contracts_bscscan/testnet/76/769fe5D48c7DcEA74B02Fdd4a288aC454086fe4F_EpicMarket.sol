// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function mint(address to, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address account) external returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external returns(uint256);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external returns(uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function isApprovedForAll(address account, address operator) external returns(bool);
    function supportsInterface(bytes4 interfaceId) external returns(bool);
}
interface IERC721 {
    function balanceOf(address owner) external returns(uint256);
    function ownerOf(uint256 tokenId) external returns(address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address account, address operator) external returns(bool);
    function supportsInterface(bytes4 interfaceId) external returns(bool);
}

contract EpicMarket is AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _marketIdCounter;
    IERC20 ERC20;
    address public _wallet;

    enum TokenType {
        CLOSED,
        ERC1155,
        ERC721
    }

    bytes4 public constant ERC1155InterfaceId = 0xd9b67a26;
    bytes4 public constant ERC721InterfaceId = 0x80ac58cd;
    uint256 public fee;
    struct Item {
        address _item;
        TokenType _itemType;
        address _owner;
        uint256 _tokenId;
        uint256 _amount;
        uint256 _price;
        uint256 _expiration;
        address _buyer;
        bool _available;
        uint256 _marketId;
    }
    struct Offer {
        address _buyer;
        uint256 _price;
        uint256 _amount;
        uint256 _marketId;
        uint256 _expiration;
        uint256 _offerId;
        bool _isAccept;
        bool _active;
    }

    Item[] items;

    // mapping owner -> offer[]
    mapping(address => Offer[]) offers;

    // event 
    event PlaceItem(address item, uint256 price, uint256 marketId, uint256 tokenId, uint256 amount);
    event BuyItem(uint256 marketId, uint256 tokenId, uint256 amount, uint256 price, address seller, address buyer);
    event CancelItem(uint256 marketId, address owner, uint256 price);
    event CloseOffer(uint256 marketId, uint256 offerId);
    event ExistItem(address item, address owner, bool status);
    event MakeOffer(uint256 marketId, uint256 amount, uint256 price, bool status);
    // placeItem
    // buyItem
    // cancelItem
    // getMarketId
    // makeOffer
    // closeOffer
    // acceptOffer
    // getOfferLists
    // getItems
    // setFee
    // getMarketId

    modifier onlyExistItem(uint256 marketId) {
        (bool found, Item memory itemData) = _getItemInfo(marketId);
        require(found, "Item is not exist");
        require(itemData._available, "Item is not available");
        require(itemData._expiration >= block.timestamp, "This item has expired");
        _;
    }
    modifier uniqueItem(address item, uint256 tokenId, uint256 amount) {
        for(uint256 i = 0; i < items.length; i++){
            if(
                items[i]._amount == amount &&
                items[i]._item == item &&
                items[i]._tokenId == tokenId &&
                items[i]._available &&
                items[i]._owner == msg.sender
            ) revert("This item is already created");
                
        }
        _;
    }
    modifier onlyItemOwner(uint256 marketId) {
        (bool found, Item memory itemData) = _getItemInfo(marketId);
        require(found, "Not found token");
        bool isERC721 = IERC721(itemData._item).supportsInterface(ERC721InterfaceId);
        bool isERC1155 = IERC1155(itemData._item).supportsInterface(ERC1155InterfaceId);
        require(
            (isERC721 && IERC721(itemData._item).ownerOf(itemData._tokenId) == msg.sender) || 
            (isERC1155 && IERC1155(itemData._item).balanceOf(itemData._owner, itemData._tokenId) >= itemData._amount)
            , "You are not owned this token."
        );
        _;
    }
    function _getItemInfo(uint256 marketId) public view returns(bool, Item memory) {
        for(uint256 i = 0; i < items.length; i++)
            if(i == marketId) return (true,items[i]);
        return (false, Item(address(0), TokenType.CLOSED, address(0), 0, 0, 0, 0, address(0), false, 0));
    }
    constructor(address tokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        fee = 10000 wei;
        _wallet = msg.sender;
        // Token Address
        ERC20 = IERC20(tokenAddress);
    }
    function placeItem(
        address item,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 expiration
    ) public uniqueItem(item, tokenId, amount){
        TokenType itemType = TokenType.CLOSED;
        require(price > 0, "Price must more than zero");
        if(IERC1155(item).supportsInterface(ERC1155InterfaceId))
            itemType = TokenType.ERC1155;
        if(IERC721(item).supportsInterface(ERC721InterfaceId))
            itemType = TokenType.ERC721;
        if(itemType == TokenType.ERC1155){
            require(IERC1155(item).balanceOf(msg.sender, tokenId) >= amount, "You do not own this item (ERC1155)");
            require(IERC1155(item).isApprovedForAll(msg.sender, address(this)), "Item is not approve");
        }
        if(itemType == TokenType.ERC721) {
            require(IERC721(item).ownerOf(tokenId) == msg.sender, "You do not own this item (ERC721)");
            require(IERC721(item).isApprovedForAll(msg.sender, address(this)), "Item is not approve");
            amount = 1;
        }
        require(expiration > block.timestamp, "Incorrect expiration");

        uint256 marketId = _marketIdCounter.current();
        _marketIdCounter.increment();
        items.push(
            Item(
                item,
                itemType,
                msg.sender,
                tokenId,
                amount,
                price,
                expiration,
                address(0),
                true,
                marketId
            )
        );

        emit PlaceItem(item, price, marketId, tokenId, amount);
    }
    function buyItem(uint256 marketId, uint256 amount) public onlyExistItem(marketId) {
        (, Item memory itemData) = _getItemInfo(marketId);

        require(ERC20.balanceOf(msg.sender) >= itemData._price * amount, "Balance is not enough");
        require(itemData._buyer == address(0), "Item is already sold");
        require(amount <= itemData._amount, "Item is not enough");
        require(msg.sender != itemData._owner, "You already owned this item");
        if(itemData._itemType == TokenType.ERC1155)
            require(
                IERC1155(itemData._item).balanceOf(itemData._owner, itemData._tokenId) >= itemData._amount,
                "Seller does not own this item (ERC1155)"
            );
        if(itemData._itemType == TokenType.ERC721)
            require(
                IERC721(itemData._item).ownerOf(itemData._tokenId) == itemData._owner,
                "Seller does not own this item (ERC721)"
            );
        ERC20.transferFrom(msg.sender, itemData._owner, amount * itemData._price * 1 ether - fee);
        ERC20.transferFrom(msg.sender, _wallet, fee);
        if(itemData._itemType == TokenType.ERC1155) 
            IERC1155(itemData._item).safeTransferFrom(
                itemData._owner, 
                msg.sender, 
                itemData._tokenId, 
                amount, 
                ""
            );
        
        // transfer ERC721 to buyer
        if(itemData._itemType == TokenType.ERC721)
            IERC721(itemData._item).safeTransferFrom(
                itemData._owner, 
                msg.sender, 
                itemData._tokenId
            );
        if(itemData._amount == amount){
            items[marketId]._available = false;
            items[marketId]._buyer = msg.sender;
        }
        items[marketId]._amount -= amount;
        emit BuyItem(marketId, itemData._tokenId, amount, itemData._price * amount, itemData._owner, msg.sender);
    }
    function makeOffer(uint256 marketId, uint256 price, uint256 expiration, uint256 amount) public onlyExistItem(marketId){
        require(block.timestamp < expiration, "Offer is expired");
        (, Item memory itemData) = _getItemInfo(marketId);
        require(itemData._price * amount <= ERC20.balanceOf(msg.sender), "Balance is not enough");
        require(itemData._amount >= amount, "Amount item is not enough");
        require(itemData._buyer == address(0), "Item is already sold");
        offers[itemData._owner].push(
            Offer(
                msg.sender,
                price,
                amount,
                marketId,
                expiration,
                offers[itemData._owner].length,
                false,
                true
            )
        );
        emit MakeOffer(marketId, amount, price * amount, true);
    }
    function getItems() public view returns(Item[] memory){
        return items;
    }
    function getOfferLists(address owner) public view returns (Offer[] memory){
        return offers[owner];
    }
    function getOfferById(address owner, uint256 offerId) public view returns(bool status, Offer memory){
        for(uint256 i = 0; i < offers[owner].length; i++){
            if(i == offerId) return  (true, offers[owner][i]);
        }
        return (false, Offer(address(0), 0, 0, 0, 0, 0, false, false));
    }
    function acceptOffer(uint256 marketId, uint256 offerId) public onlyExistItem(marketId){
        (, Item memory itemData) = _getItemInfo(marketId);
        require(itemData._buyer == address(0), "Item is already sold");
        
        (bool status, Offer memory offerData) = getOfferById(itemData._owner, offerId);
        require(status, "Offer not found");
        require(offerData._active, "Offer is not active");
        require(offerData._isAccept == false, "Item is already accept");
        require(offerData._expiration >= block.timestamp, "Offer is expired");

        require(itemData._amount >= offerData._amount, "Item in market is not enough");
        require(ERC20.balanceOf(offerData._buyer) >= offerData._price * offerData._amount, "Balance buyer is not enough");
        ERC20.transferFrom(offerData._buyer, itemData._owner, offerData._price * offerData._amount * 1 ether  - fee);
        ERC20.transferFrom(offerData._buyer, _wallet, fee);

        if(itemData._itemType == TokenType.ERC1155){
            IERC1155(itemData._item).safeTransferFrom(itemData._owner, offerData._buyer, itemData._tokenId, offerData._amount, "");
        } else if(itemData._itemType == TokenType.ERC721){
            IERC721(itemData._item).safeTransferFrom(itemData._owner, offerData._buyer, itemData._tokenId);
        } else {
            revert("Item type is incorrect");
        }
        if(offerData._amount == itemData._amount){
            items[marketId]._available = false;
            items[marketId]._buyer = offerData._buyer;
        }
        items[marketId]._amount -= offerData._amount;
        offers[itemData._owner][offerId]._isAccept = true;
        offers[itemData._owner][offerId]._active = false;
    }
    function closeOffer(address owner, uint256 offerId, uint256 marketId) public onlyExistItem(marketId){
        require(offerId < offers[owner].length, "Invalid offerId");

        // collect fee to wallet owner
        require(ERC20.balanceOf(owner) >= fee, "Balance is not enough to pay fee");
        ERC20.transferFrom(owner, _wallet, fee);

        offers[owner][offerId]._active = false;
        emit CloseOffer(marketId, offerId);
    }
    function cancelItem(uint256 marketId) public onlyItemOwner(marketId)  {
        (, Item memory itemData) = _getItemInfo(marketId);
        require(items[marketId]._available, "Items is already not available");
        require(ERC20.balanceOf(msg.sender) >= fee, "Balance is not enough to cancel");

        ERC20.transferFrom(msg.sender, _wallet, fee);
        emit CancelItem(itemData._marketId, itemData._owner, itemData._price);
        items[marketId]._available = false;

        // transfer fee to admin wallet
    }
    function setFee(uint256 _fee) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        fee = _fee;
        return true;
    }
    function setAdminWallet(address wallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _wallet = wallet;
    }
    function getMarketId(address item, address owner, uint256 tokenId, uint256 amount) public view returns(bool, uint256){
        for(uint i = 0; i < items.length; i++){
            if(items[i]._owner == owner && items[i]._tokenId == tokenId && items[i]._amount == amount && items[i]._item == item){
                return (true, items[i]._marketId);
            }
        }
        return (false, 0);
    }
    function setAvailable(uint256 marketId) public onlyExistItem(marketId) onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        items[marketId]._available = false;
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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