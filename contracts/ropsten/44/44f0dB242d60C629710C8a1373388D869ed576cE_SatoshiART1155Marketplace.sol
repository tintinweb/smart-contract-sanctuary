/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

interface ISatoshiART1155 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function tokenCreator(uint256 _id) external view returns (address);

    function tokenRoyalty(uint256 _id) external view returns (uint256);
}

contract SatoshiART1155Marketplace is AccessControl {
    struct Listing {
        bytes1 status; // 0x00 onHold 0x01 onSale 0x02 isAuction
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 commission;
        bool isDropOfTheDay;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => mapping(address => Listing)) private _listings;
    ISatoshiART1155 public satoshiART1155;
    mapping(address => uint256) private _outstandingPayments;
    uint256 private _defaultCommission;
    uint256 private _defaultAuctionCommission;
    bytes32 public constant DROP_OF_THE_DAY_CREATOR_ROLE =
        keccak256("DROP_OF_THE_DAY_CREATOR_ROLE");
    address private _commissionReceiver;

    event PurchaseConfirmed(uint256 tokenId, address itemOwner, address buyer);
    event PaymentWithdrawed(uint256 amount);
    event HighestBidIncreased(
        uint256 tokenId,
        address itemOwner,
        address bidder,
        uint256 amount
    );
    event AuctionEnded(
        uint256 tokenId,
        address itemOwner,
        address winner,
        uint256 amount
    );

    constructor(address satoshiART1155Address) {
        satoshiART1155 = ISatoshiART1155(satoshiART1155Address);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _defaultCommission = 250;
        _defaultAuctionCommission = 250;
        _commissionReceiver = msg.sender;
    }

    function commissionReceiver() external view returns (address) {
        return _commissionReceiver;
    }

    function setCommissionReceiver(address user) external returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _commissionReceiver = user;

        return true;
    }

    function defaultCommission() external view returns (uint256) {
        return _defaultCommission;
    }

    function defaultAuctionCommission() external view returns (uint256) {
        return _defaultAuctionCommission;
    }

    function setDefaultCommission(uint256 commission) external returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        require(commission <= 3000, "commission is too high");
        _defaultCommission = commission;

        return true;
    }

    function setDefaultAuctionCommission(uint256 commission)
        external
        returns (bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        require(commission <= 3000, "commission is too high");
        _defaultAuctionCommission = commission;

        return true;
    }

    function setListing(
        uint256 tokenId,
        bytes1 status,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 dropOfTheDayCommission,
        bool isDropOfTheDay
    ) external {
        require(
            satoshiART1155.balanceOf(msg.sender, tokenId) >= 1,
            "Set listing: you are trying to sell more than you have"
        );

        if (status == 0x00) {
            require(
                _listings[tokenId][msg.sender].highestBidder == address(0),
                "Set listing: bid already exists"
            );

            _listings[tokenId][msg.sender] = Listing({
                status: status,
                price: 0,
                startTime: 0,
                endTime: 0,
                commission: 0,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (isDropOfTheDay) {
            require(
                hasRole(DROP_OF_THE_DAY_CREATOR_ROLE, msg.sender),
                "Set listing: Caller is not a drop of the day creator"
            );
            require(
                _listings[tokenId][msg.sender].status == 0x00,
                "Set listing: token not on hold"
            );
            require(
                dropOfTheDayCommission <= 3000,
                "Set drop of the day listing: commission is too high"
            );
            require(
                block.timestamp < startTime && startTime < endTime,
                "endTime should be greater than startTime. startTime should be greater than current time"
            );

            _listings[tokenId][msg.sender] = Listing({
                status: status,
                price: price,
                startTime: startTime,
                endTime: endTime,
                commission: dropOfTheDayCommission,
                isDropOfTheDay: isDropOfTheDay,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (status == 0x01) {
            require(
                _listings[tokenId][msg.sender].status == 0x00,
                "Set listing: token not on hold"
            );

            _listings[tokenId][msg.sender] = Listing({
                status: status,
                price: price,
                startTime: 0,
                endTime: 0,
                commission: _defaultCommission,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (status == 0x02) {
            require(
                _listings[tokenId][msg.sender].status == 0x00,
                "Set listing: token not on hold"
            );
            require(
                block.timestamp < startTime && startTime < endTime,
                "endTime should be greater than startTime. startTime should be greater than current time"
            );

            _listings[tokenId][msg.sender] = Listing({
                status: status,
                price: price,
                startTime: startTime,
                endTime: endTime,
                commission: _defaultAuctionCommission,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        }
    }

    function listingOf(address account, uint256 tokenId)
        external
        view
        returns (
            bytes1,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            address,
            uint256
        )
    {
        require(
            account != address(0),
            "ERC1155: listing query for the zero address"
        );

        Listing memory l = _listings[tokenId][account];
        return (
            l.status,
            l.price,
            l.startTime,
            l.endTime,
            l.commission,
            l.isDropOfTheDay,
            l.highestBidder,
            l.highestBid
        );
    }

    function buy(uint256 tokenId, address itemOwner)
        external
        payable
        returns (bool)
    {
        require(
            _listings[tokenId][itemOwner].status == 0x01,
            "buy: token not listed for sale"
        );
        require(
            satoshiART1155.balanceOf(itemOwner, tokenId) >= 1,
            "buy: trying to buy more than owned"
        );
        require(
            msg.value >= _listings[tokenId][itemOwner].price,
            "buy: not enough fund"
        );

        if (_listings[tokenId][itemOwner].isDropOfTheDay) {
            require(
                block.timestamp >= _listings[tokenId][itemOwner].startTime &&
                    block.timestamp <= _listings[tokenId][itemOwner].endTime,
                "buy (Drop of the day): drop of the day has ended/not started"
            );
        }

        uint256 commision =
            (msg.value * _listings[tokenId][itemOwner].commission) / 10000;
        uint256 royalty =
            (msg.value * satoshiART1155.tokenRoyalty(tokenId)) / 10000;

        _listings[tokenId][itemOwner] = Listing({
            status: 0x00,
            price: 0,
            startTime: 0,
            endTime: 0,
            commission: 0,
            isDropOfTheDay: false,
            highestBidder: address(0),
            highestBid: 0
        });
        emit PurchaseConfirmed(tokenId, itemOwner, msg.sender);

        satoshiART1155.safeTransferFrom(
            itemOwner,
            msg.sender,
            tokenId,
            satoshiART1155.balanceOf(itemOwner, tokenId),
            ""
        );

        _outstandingPayments[satoshiART1155.tokenCreator(tokenId)] =
            _outstandingPayments[satoshiART1155.tokenCreator(tokenId)] +
            royalty;
        _outstandingPayments[_commissionReceiver] =
            _outstandingPayments[_commissionReceiver] +
            commision;
        _outstandingPayments[itemOwner] =
            _outstandingPayments[itemOwner] +
            (msg.value - commision - royalty);

        return true;
    }

    function withdrawPayment() external returns (bool) {
        uint256 amount = _outstandingPayments[msg.sender];
        if (amount > 0) {
            _outstandingPayments[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                _outstandingPayments[msg.sender] = amount;
                return false;
            }
        }
        emit PaymentWithdrawed(amount);
        return true;
    }

    function outstandingPayment(address user) external view returns (uint256) {
        return _outstandingPayments[user];
    }

    //Auction
    function bid(uint256 tokenId, address itemOwner) external payable {
        require(
            _listings[tokenId][itemOwner].status == 0x02,
            "Item not listed for auction."
        );
        require(
            block.timestamp <= _listings[tokenId][itemOwner].endTime &&
                block.timestamp >= _listings[tokenId][itemOwner].startTime,
            "Auction not started/already ended."
        );
        require(
            msg.value > _listings[tokenId][itemOwner].highestBid,
            "There already is a higher bid."
        );

        if (_listings[tokenId][itemOwner].highestBid != 0) {
            _outstandingPayments[
                _listings[tokenId][itemOwner].highestBidder
            ] += _listings[tokenId][itemOwner].highestBid;
        }
        _listings[tokenId][itemOwner].highestBidder = msg.sender;
        _listings[tokenId][itemOwner].highestBid = msg.value;
        emit HighestBidIncreased(tokenId, itemOwner, msg.sender, msg.value);
    }

    // Withdraw a bid that was overbid.
    // use withdrawPayment()

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd(uint256 tokenId, address itemOwner) external {
        require(
            _listings[tokenId][itemOwner].status == 0x02,
            "Auction end: item is not for auction"
        );
        require(
            block.timestamp > _listings[tokenId][itemOwner].endTime,
            "Auction end: auction not yet ended."
        );

        uint256 commision =
            (_listings[tokenId][itemOwner].highestBid *
                _listings[tokenId][itemOwner].commission) / 10000;

        uint256 royalty =
            (_listings[tokenId][itemOwner].highestBid *
                satoshiART1155.tokenRoyalty(tokenId)) / 10000;

        _listings[tokenId][itemOwner] = Listing({
            status: 0x00,
            price: 0,
            startTime: 0,
            endTime: 0,
            commission: 0,
            isDropOfTheDay: false,
            highestBidder: _listings[tokenId][itemOwner].highestBidder,
            highestBid: _listings[tokenId][itemOwner].highestBid
        });
        emit AuctionEnded(
            tokenId,
            itemOwner,
            _listings[tokenId][itemOwner].highestBidder,
            _listings[tokenId][itemOwner].highestBid
        );

        satoshiART1155.safeTransferFrom(
            itemOwner,
            _listings[tokenId][itemOwner].highestBidder,
            tokenId,
            1,
            ""
        );

        _outstandingPayments[satoshiART1155.tokenCreator(tokenId)] =
            _outstandingPayments[satoshiART1155.tokenCreator(tokenId)] +
            royalty;
        _outstandingPayments[_commissionReceiver] =
            _outstandingPayments[_commissionReceiver] +
            commision;
        _outstandingPayments[itemOwner] =
            _outstandingPayments[itemOwner] +
            (_listings[tokenId][itemOwner].highestBid - commision - royalty);
    }

    function setDropOfTheDayAuctionEndTime(uint256 tokenId, uint256 newEndTime)
        external
    {
        require(
            hasRole(DROP_OF_THE_DAY_CREATOR_ROLE, msg.sender),
            "Set drop of the day auction end time: caller is not drop of the day creator."
        );
        require(
            _listings[tokenId][msg.sender].status == 0x02,
            "Item is not in auction"
        );
        require(
            _listings[tokenId][msg.sender].isDropOfTheDay,
            "Set drop of the day auction end time: item is not for drop of the day."
        );
        require(
            _listings[tokenId][msg.sender].endTime < newEndTime,
            "newEndTime not greater than current endTime."
        );
        _listings[tokenId][msg.sender].endTime = newEndTime;
    }

    function transfer(uint256 tokenId, address receiver) external {
        require(
            satoshiART1155.balanceOf(msg.sender, tokenId) >= 1,
            "Do not have enough token to transfer."
        );
        require(
            _listings[tokenId][msg.sender].status == 0x00,
            "Token not on hold"
        );

        satoshiART1155.safeTransferFrom(
            msg.sender,
            receiver,
            tokenId,
            satoshiART1155.balanceOf(msg.sender, tokenId),
            ""
        );
    }
}