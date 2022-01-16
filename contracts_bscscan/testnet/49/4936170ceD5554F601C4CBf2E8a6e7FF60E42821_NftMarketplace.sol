// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./pancake-swap/interfaces/IPancakeRouter02.sol";

import "./ExilonNftLootboxLibrary.sol";
import "./FeesCalculator.sol";

import "./interfaces/INftMarketplace.sol";

contract NftMarketplace is FeesCalculator, INftMarketplace {
    using EnumerableSet for EnumerableSet.UintSet;

    struct SellingInfo {
        ExilonNftLootboxLibrary.TokenInfo tokenInfo;
        uint256 price;
        address seller;
    }

    struct ModerationInfo {
        ExilonNftLootboxLibrary.TokenInfo tokenInfo;
        address requestingAddress;
    }

    struct TokenStateInfo {
        uint256 price;
        uint256 duration;
        uint256 changeTime;
        bool zeroPrevious;
    }

    // public

    uint256 public moderationPrice;
    uint256 public feePercentage = 1_000; // 10%

    mapping(uint256 => SellingInfo) public idToSellingInfo;

    mapping(address => mapping(uint256 => bool)) public override isTokenModerated;
    mapping(address => mapping(uint256 => bool)) public isOnModeration;

    uint256 public constant NUMBER_OF_STATES = 20;
    TokenStateInfo[NUMBER_OF_STATES] public tokenStateInfo;

    // private

    uint256 private _lastIdForSellingInfo;

    EnumerableSet.UintSet private _activeIds;
    mapping(address => EnumerableSet.UintSet) private _userToActiveIds;

    ModerationInfo[] private _moderationRequests;
    mapping(address => mapping(uint256 => uint256)) private _moderationRequestId;

    mapping(address => mapping(uint256 => uint256)) private _moderatedTokenId;
    ExilonNftLootboxLibrary.TokenInfo[] private _moderatedTokens;

    mapping(address => mapping(uint256 => uint256[NUMBER_OF_STATES])) private _tokenStates;

    event SellCreated(
        address indexed user,
        uint256 sellPrice,
        uint256 id,
        ExilonNftLootboxLibrary.TokenInfo tokenInfo
    );
    event SellCanceled(
        address indexed user,
        uint256 id,
        ExilonNftLootboxLibrary.TokenInfo tokenInfo
    );
    event SellMaded(
        address indexed seller,
        address indexed buyer,
        uint256 id,
        uint256 usdPrice,
        uint256 bnbPrice,
        uint256 timestamp,
        ExilonNftLootboxLibrary.TokenInfo tokenInfo
    );

    event ModerationRequest(address indexed user, ExilonNftLootboxLibrary.TokenInfo tokenInfo);
    event ModerationPass(ExilonNftLootboxLibrary.TokenInfo tokenInfo);
    event ModerationFail(ExilonNftLootboxLibrary.TokenInfo tokenInfo);
    event ModerationCanceled(ExilonNftLootboxLibrary.TokenInfo tokenInfo);

    event StateInfoChange(
        uint256 stateNum,
        uint256 price,
        uint256 duration,
        uint256 timestamp,
        bool zeroPrevious
    );
    event BuyTokenState(ExilonNftLootboxLibrary.TokenInfo tokenInfo, uint256 stateNum);

    event FeePercentageChange(uint256 newValue);
    event ModerationPriceChange(uint256 newValue);

    constructor(
        address _usdToken,
        IPancakeRouter02 _pancakeRouter,
        address _feeReceiver,
        IAccess _accessControl
    ) FeesCalculator(_usdToken, _pancakeRouter, _feeReceiver, _accessControl) {
        moderationPrice = _oneUsd;

        emit FeePercentageChange(feePercentage);
        emit ModerationPriceChange(_oneUsd);
    }

    function sellToken(ExilonNftLootboxLibrary.TokenInfo calldata tokenInfo, uint256 sellPrice)
        external
        nonReentrant
        onlyEOA
    {
        _checkInputData(tokenInfo);
        require(sellPrice > 0, "NftMarketplace: Wrong price");

        ExilonNftLootboxLibrary.withdrawToken(tokenInfo, msg.sender, address(this), true);

        uint256 __lastId = _lastIdForSellingInfo++;

        SellingInfo memory sellingInfo;
        sellingInfo.tokenInfo = tokenInfo;
        sellingInfo.price = sellPrice;
        sellingInfo.seller = msg.sender;

        idToSellingInfo[__lastId] = sellingInfo;
        _userToActiveIds[msg.sender].add(__lastId);

        _activeIds.add(__lastId);

        emit SellCreated(msg.sender, sellPrice, __lastId, tokenInfo);
    }

    function buy(uint256 id) external payable nonReentrant onlyEOA {
        require(_activeIds.contains(id), "NftMarketplace: Not active id");

        SellingInfo memory sellingInfo = idToSellingInfo[id];

        uint256 bnbValue = _checkFees(sellingInfo.price);
        _processFeeTransfer(bnbValue, sellingInfo.seller);

        ExilonNftLootboxLibrary.withdrawToken(
            sellingInfo.tokenInfo,
            address(this),
            msg.sender,
            true
        );

        _activeIds.remove(id);
        _userToActiveIds[sellingInfo.seller].remove(id);
        delete idToSellingInfo[id];

        emit SellMaded(
            sellingInfo.seller,
            msg.sender,
            id,
            sellingInfo.price,
            bnbValue,
            block.timestamp,
            sellingInfo.tokenInfo
        );
    }

    function cancelSell(uint256 id) external nonReentrant {
        require(_activeIds.contains(id), "NftMarketplace: Not active id");

        SellingInfo memory sellingInfo = idToSellingInfo[id];

        require(msg.sender == sellingInfo.seller, "NftMarketplace: Not seller");

        _activeIds.remove(id);
        _userToActiveIds[msg.sender].remove(id);
        delete idToSellingInfo[id];

        ExilonNftLootboxLibrary.withdrawToken(
            sellingInfo.tokenInfo,
            address(this),
            msg.sender,
            true
        );

        emit SellCanceled(msg.sender, id, sellingInfo.tokenInfo);
    }

    function sendAddressOnModeration(ExilonNftLootboxLibrary.TokenInfo calldata tokenInfo)
        external
        payable
        nonReentrant
        onlyEOA
    {
        _checkInputData(tokenInfo);
        require(
            isTokenModerated[tokenInfo.tokenAddress][tokenInfo.id] == false,
            "NftMarketplace: Moderated"
        );
        require(
            isOnModeration[tokenInfo.tokenAddress][tokenInfo.id] == false,
            "NftMarketplace: Moderating"
        );

        _checkFees(moderationPrice);
        _processFeeTransferOnFeeReceiver();

        _moderationRequests.push(
            ModerationInfo({tokenInfo: tokenInfo, requestingAddress: msg.sender})
        );
        _moderationRequestId[tokenInfo.tokenAddress][tokenInfo.id] = _moderationRequests.length - 1;
        isOnModeration[tokenInfo.tokenAddress][tokenInfo.id] = true;

        emit ModerationRequest(msg.sender, tokenInfo);
    }

    function buyTokenState(ExilonNftLootboxLibrary.TokenInfo calldata tokenInfo, uint256 stateNum)
        external
        payable
        nonReentrant
        onlyEOA
    {
        require(stateNum < NUMBER_OF_STATES, "NftMarketplace: State number");
        _checkInputData(tokenInfo);

        uint256 price = tokenStateInfo[stateNum].price;
        require(price > 0, "NftMarketplace: Not opened state");
        _checkFees(price);
        _processFeeTransferOnFeeReceiver();

        _tokenStates[tokenInfo.tokenAddress][tokenInfo.id][stateNum] = block.timestamp;

        emit BuyTokenState(tokenInfo, stateNum);
    }

    function processModeration(
        address tokenAddress,
        uint256 tokenId,
        bool decision
    ) external onlyManagerOrAdmin {
        require(isOnModeration[tokenAddress][tokenId], "NftMarketplace: Not on moderation");

        uint256 moderationRequestsIndex = _moderationRequestId[tokenAddress][tokenId];
        delete _moderationRequestId[tokenAddress][tokenId];

        ModerationInfo memory moderationInfo = _moderationRequests[moderationRequestsIndex];

        uint256 moderationRequestsLength = _moderationRequests.length;
        if (moderationRequestsIndex < moderationRequestsLength - 1) {
            ModerationInfo memory replacement = _moderationRequests[moderationRequestsLength - 1];
            _moderationRequests[moderationRequestsIndex] = replacement;

            _moderationRequestId[replacement.tokenInfo.tokenAddress][
                replacement.tokenInfo.id
            ] = moderationRequestsIndex;
        }
        _moderationRequests.pop();
        delete isOnModeration[moderationInfo.tokenInfo.tokenAddress][moderationInfo.tokenInfo.id];

        if (decision) {
            isTokenModerated[moderationInfo.tokenInfo.tokenAddress][
                moderationInfo.tokenInfo.id
            ] = true;

            _moderatedTokens.push(moderationInfo.tokenInfo);
            _moderatedTokenId[moderationInfo.tokenInfo.tokenAddress][moderationInfo.tokenInfo.id] =
                _moderatedTokens.length -
                1;

            emit ModerationPass(moderationInfo.tokenInfo);
        } else {
            emit ModerationFail(moderationInfo.tokenInfo);
        }
    }

    function cancelModeration(ExilonNftLootboxLibrary.TokenInfo calldata tokenInfo)
        external
        onlyManagerOrAdmin
    {
        bool isModerated = isTokenModerated[tokenInfo.tokenAddress][tokenInfo.id];
        if (isModerated) {
            delete isTokenModerated[tokenInfo.tokenAddress][tokenInfo.id];

            uint256 indexDeleting = _moderatedTokenId[tokenInfo.tokenAddress][tokenInfo.id];
            delete _moderatedTokenId[tokenInfo.tokenAddress][tokenInfo.id];

            uint256 length = _moderatedTokens.length;
            if (indexDeleting < length - 1) {
                ExilonNftLootboxLibrary.TokenInfo memory replacement = _moderatedTokens[length - 1];
                _moderatedTokens[indexDeleting] = replacement;

                _moderatedTokenId[replacement.tokenAddress][replacement.id] = indexDeleting;
            }
            _moderatedTokens.pop();

            for (uint256 i = 0; i < NUMBER_OF_STATES; ++i) {
                delete _tokenStates[tokenInfo.tokenAddress][tokenInfo.id][i];
            }

            emit ModerationCanceled(tokenInfo);
        }
    }

    function setStateInfo(
        uint256 stateNum,
        uint256 price,
        uint256 duration,
        bool zeroPrevious
    ) external onlyAdmin {
        require(stateNum < NUMBER_OF_STATES, "NftMarketplace: State number");
        require(price > 0, "NftMarketplace: Wrong price");

        tokenStateInfo[stateNum] = TokenStateInfo({
            price: price,
            duration: duration,
            changeTime: block.timestamp,
            zeroPrevious: zeroPrevious
        });

        emit StateInfoChange(stateNum, price, duration, block.timestamp, zeroPrevious);
    }

    function setFeePercentage(uint256 newValue) external onlyAdmin {
        require(newValue <= 5_000, "NftMarketplace: Too big percentage");
        feePercentage = newValue;

        emit FeePercentageChange(newValue);
    }

    function setModerationPrice(uint256 newValue) external onlyAdmin {
        moderationPrice = newValue;

        emit ModerationPriceChange(newValue);
    }

    function getBnbPriceToBuy(uint256 id) external view returns (uint256) {
        return _getBnbAmountToFront(idToSellingInfo[id].price);
    }

    function getBnbPriceForModeration() external view returns (uint256) {
        return _getBnbAmountToFront(moderationPrice);
    }

    function getBnbPriceForState(uint256 state) external view returns(uint256) {
        if (state >= NUMBER_OF_STATES) {
            return 0;
        }
        return _getBnbAmountToFront(tokenStateInfo[state].price);
    }

    function activeIdsLength() external view returns (uint256) {
        return _activeIds.length();
    }

    function activeIds(uint256 indexFrom, uint256 indexTo) external view returns (uint256[] memory result) {
        uint256 fullLength = _activeIds.length();
        if (indexFrom >= indexTo || indexTo > fullLength) {
            return result;
        }

        result = new uint256[](indexTo - indexFrom);
        for (uint256 i = indexFrom; i < indexTo; ++i) {
            result[i - indexFrom] = _activeIds.at(i);
        }
    }

    function userToActiveIdsLength(address user) external view returns (uint256) {
        return _userToActiveIds[user].length();
    }

    function userToActiveIdsAt(address user, uint256 indexFrom, uint256 indexTo) external view returns (uint256[] memory result) {
        uint256 fullLength = _userToActiveIds[user].length();
        if (indexFrom >= indexTo || indexTo > fullLength) {
            return result;
        }

        result = new uint256[](indexTo - indexFrom);
        for (uint256 i = indexFrom; i < indexTo; ++i) {
            result[i - indexFrom] = _userToActiveIds[user].at(i);
        }
    }

    function moderationRequestsLen() external view returns (uint256) {
        return _moderationRequests.length;
    }

    function moderationRequests(uint256 indexFrom, uint256 indexTo)
        external
        view
        returns (ModerationInfo[] memory result)
    {
        uint256 fullLength = _moderationRequests.length;
        if (indexFrom >= indexTo || indexTo > fullLength) {
            return result;
        }

        result = new ModerationInfo[](indexTo - indexFrom);
        for (uint256 i = indexFrom; i < indexTo; ++i) {
            result[i - indexFrom] = _moderationRequests[i];
        }
    }

    function moderatedTokensLen() external view returns (uint256) {
        return _moderatedTokens.length;
    }

    function moderatedTokens(uint256 indexFrom, uint256 indexTo)
        external
        view
        returns (ExilonNftLootboxLibrary.TokenInfo[] memory result)
    {
        uint256 fullLength = _moderatedTokens.length;
        if (indexFrom >= indexTo || indexTo > fullLength) {
            return result;
        }

        result = new ExilonNftLootboxLibrary.TokenInfo[](indexTo - indexFrom);
        for (uint256 i = indexFrom; i < indexTo; ++i) {
            result[i - indexFrom] = _moderatedTokens[i];
        }
    }

    function getTokenStates(ExilonNftLootboxLibrary.TokenInfo[] calldata tokenInfo)
        external
        view
        returns (bool[NUMBER_OF_STATES][] memory result)
    {
        result = new bool[NUMBER_OF_STATES][](tokenInfo.length);
        for (uint256 i = 0; i < tokenInfo.length; ++i) {
            for (uint256 state = 0; state < NUMBER_OF_STATES; ++state) {
                TokenStateInfo memory _tokenStateInfo = tokenStateInfo[state];

                uint256 tokenState = _tokenStates[tokenInfo[i].tokenAddress][tokenInfo[i].id][
                    state
                ];

                if (
                    (_tokenStateInfo.zeroPrevious && tokenState < _tokenStateInfo.changeTime) ||
                    tokenState == 0
                ) {
                    result[i][state] = false;
                } else {
                    result[i][state] = tokenState + _tokenStateInfo.duration >= block.timestamp;
                }
            }
        }
    }

    function _processFeeTransfer(uint256 bnbAmount, address to) private {
        uint256 amountToSeller = (bnbAmount * (10_000 - feePercentage)) / 10_000;

        // seller is not a contract and shouldn't fail
        (bool success, ) = to.call{value: amountToSeller}("");
        require(success, "NftMarketplace: Transfer to seller");

        _processFeeTransferOnFeeReceiver();
    }

    function _checkInputData(ExilonNftLootboxLibrary.TokenInfo calldata tokenInfo) private view {
        require(
            tokenInfo.tokenType == ExilonNftLootboxLibrary.TokenType.ERC721 ||
                tokenInfo.tokenType == ExilonNftLootboxLibrary.TokenType.ERC1155,
            "NftMarketplace: Wrong token type"
        );
        require(tokenInfo.amount == 0, "NftMarketplace: Wrong amount");
        if (tokenInfo.tokenType == ExilonNftLootboxLibrary.TokenType.ERC721) {
            require(
                IERC165(tokenInfo.tokenAddress).supportsInterface(bytes4(0x80ac58cd)),
                "NftMarketplace: ERC721 type"
            );
        } else {
            require(
                IERC165(tokenInfo.tokenAddress).supportsInterface(bytes4(0xd9b67a26)),
                "NftMarketplace: ERC1155 type"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./pancake-swap/interfaces/IPancakeRouter02.sol";

import "./interfaces/IExilon.sol";

library ExilonNftLootboxLibrary {
    using SafeERC20 for IERC20;

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum LootBoxType {
        DEFAULT,
        MEGA_LOOTBOX_RESERVE,
        MEGA_LOOTBOX_NO_RESERVE
    }

    struct TokenInfo {
        address tokenAddress;
        TokenType tokenType;
        uint256 id; // for ERC721 and ERC1155. For ERC20 must be 0
        uint256 amount; // for ERC20 and ERC1155. For ERC721 must be 0
    }

    struct WinningPlace {
        uint256 placeAmounts;
        TokenInfo[] prizesInfo;
    }

    uint256 public constant MAX_TOKENS_IN_LOOTBOX = 200;
    uint256 public constant MAX_GAS_FOR_TOKEN_TRANSFER = 1_500_000;
    uint256 public constant MAX_GAS_FOR_ETH_TRANSFER = 500_000;

    event BadERC20TokenWithdraw(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        string errorMessage
    );
    event BadERC721TokenWithdraw(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 id,
        string errorMessage
    );
    event BadERC1155TokenWithdraw(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount,
        string errorMessage
    );

    function withdrawToken(
        TokenInfo memory tokenInfo,
        address from,
        address to,
        bool requireSuccess
    ) public returns (bool) {
        if (tokenInfo.tokenType == TokenType.ERC20) {
            if (from == address(this)) {
                if (requireSuccess) {
                    IERC20(tokenInfo.tokenAddress).safeTransfer(to, tokenInfo.amount);
                    return true;
                } else {
                    require(
                        gasleft() >= MAX_GAS_FOR_TOKEN_TRANSFER,
                        "ExilonNftLootboxLibrary: Not enough gas"
                    );
                    (bool success, bytes memory result) = tokenInfo.tokenAddress.call{
                        gas: MAX_GAS_FOR_TOKEN_TRANSFER
                    }(abi.encodeWithSelector(IERC20.transfer.selector, to, tokenInfo.amount));
                    if (!success) {
                        emit BadERC20TokenWithdraw(
                            tokenInfo.tokenAddress,
                            from,
                            to,
                            tokenInfo.amount,
                            _getRevertMsg(result)
                        );
                    }
                    return success;
                }
            } else {
                if (requireSuccess) {
                    IERC20(tokenInfo.tokenAddress).safeTransferFrom(from, to, tokenInfo.amount);
                    return true;
                } else {
                    require(
                        gasleft() >= MAX_GAS_FOR_TOKEN_TRANSFER,
                        "ExilonNftLootboxLibrary: Not enough gas"
                    );
                    (bool success, bytes memory result) = tokenInfo.tokenAddress.call{
                        gas: MAX_GAS_FOR_TOKEN_TRANSFER
                    }(
                        abi.encodeWithSelector(
                            IERC20.transferFrom.selector,
                            from,
                            to,
                            tokenInfo.amount
                        )
                    );
                    if (!success) {
                        emit BadERC20TokenWithdraw(
                            tokenInfo.tokenAddress,
                            from,
                            to,
                            tokenInfo.amount,
                            _getRevertMsg(result)
                        );
                    }
                    return success;
                }
            }
        } else if (tokenInfo.tokenType == TokenType.ERC721) {
            if (requireSuccess) {
                IERC721(tokenInfo.tokenAddress).safeTransferFrom(from, to, tokenInfo.id);
                return true;
            } else {
                require(
                    gasleft() >= MAX_GAS_FOR_TOKEN_TRANSFER,
                    "ExilonNftLootboxLibrary: Not enough gas"
                );
                (bool success, bytes memory result) = tokenInfo.tokenAddress.call{
                    gas: MAX_GAS_FOR_TOKEN_TRANSFER
                }(
                    abi.encodeWithSignature(
                        "safeTransferFrom(address,address,uint256)",
                        from,
                        to,
                        tokenInfo.id
                    )
                );
                if (!success) {
                    emit BadERC721TokenWithdraw(
                        tokenInfo.tokenAddress,
                        from,
                        to,
                        tokenInfo.id,
                        _getRevertMsg(result)
                    );
                }
                return success;
            }
        } else if (tokenInfo.tokenType == TokenType.ERC1155) {
            if (requireSuccess) {
                IERC1155(tokenInfo.tokenAddress).safeTransferFrom(
                    from,
                    to,
                    tokenInfo.id,
                    tokenInfo.amount,
                    ""
                );
                return true;
            } else {
                require(
                    gasleft() >= MAX_GAS_FOR_TOKEN_TRANSFER,
                    "ExilonNftLootboxLibrary: Not enough gas"
                );
                (bool success, bytes memory result) = tokenInfo.tokenAddress.call{
                    gas: MAX_GAS_FOR_TOKEN_TRANSFER
                }(
                    abi.encodeWithSelector(
                        IERC1155.safeTransferFrom.selector,
                        from,
                        to,
                        tokenInfo.id,
                        tokenInfo.amount,
                        ""
                    )
                );
                if (!success) {
                    emit BadERC1155TokenWithdraw(
                        tokenInfo.tokenAddress,
                        from,
                        to,
                        tokenInfo.id,
                        tokenInfo.amount,
                        _getRevertMsg(result)
                    );
                }
                return success;
            }
        } else {
            revert("ExilonNftLootboxLibrary: Wrong type of token");
        }
    }

    struct processMergeInfoInputStruct {
        uint256 idFrom;
        uint256 idTo;
        address tokenAddress;
        TokenType tokenType;
        uint256 balanceBefore;
        address fundsHolderTo;
        address processingTokenAddress;
        ExilonNftLootboxLibrary.WinningPlace[] winningPlacesFrom;
    }

    function processMergeInfo(
        processMergeInfoInputStruct memory input,
        mapping(uint256 => mapping(address => uint256)) storage totalSharesOfERC20,
        mapping(uint256 => WinningPlace[]) storage _prizes
    ) external {
        if (input.tokenType == TokenType.ERC20) {
            uint256 totalSharesTo = totalSharesOfERC20[input.idTo][input.tokenAddress];
            uint256 totalSharesFrom = totalSharesOfERC20[input.idFrom][input.tokenAddress];
            if (totalSharesTo == 0) {
                totalSharesOfERC20[input.idTo][input.tokenAddress] = totalSharesFrom;
            } else {
                uint256 balanceAfter = IERC20(input.tokenAddress).balanceOf(input.fundsHolderTo);

                require(
                    balanceAfter > input.balanceBefore,
                    "ExilonNftLootboxMaster: Merge balance error"
                );
                uint256 newSharesAmount = (balanceAfter * totalSharesTo) /
                    input.balanceBefore -
                    totalSharesTo;
                totalSharesOfERC20[input.idTo][input.tokenAddress] =
                    totalSharesTo +
                    newSharesAmount;

                for (uint256 i = 0; i < input.winningPlacesFrom.length; ++i) {
                    for (uint256 j = 0; j < input.winningPlacesFrom[j].prizesInfo.length; ++j) {
                        if (
                            input.winningPlacesFrom[i].prizesInfo[j].tokenAddress ==
                            input.processingTokenAddress
                        ) {
                            _prizes[input.idFrom][i].prizesInfo[j].amount =
                                (input.winningPlacesFrom[i].prizesInfo[j].amount *
                                    newSharesAmount) /
                                totalSharesFrom;
                        }
                    }
                }
            }
        }
    }

    function mergeWinningPrizeInfo(
        uint256 idFrom,
        uint256 idTo,
        uint256 lengthTo,
        uint256 lengthFrom,
        address creatorFrom,
        mapping(uint256 => WinningPlace[]) storage _prizes,
        mapping(uint256 => mapping(uint256 => address)) storage _winningPlaceCreator
    ) external {
        for (uint256 i = lengthFrom; i > 0; --i) {
            _prizes[idTo].push(_prizes[idFrom][i - 1]);
            _prizes[idFrom].pop();
            _winningPlaceCreator[idTo][lengthTo] = creatorFrom;
            ++lengthTo;
        }
    }

    function transferFundsToFundsHolder(
        TokenInfo[] memory allTokensInfo,
        address fundsHolder,
        uint256 id,
        address exilon,
        mapping(uint256 => mapping(address => uint256)) storage totalSharesOfERC20
    ) external {
        for (uint256 i = 0; i < allTokensInfo.length; ++i) {
            if (
                allTokensInfo[i].tokenAddress == exilon &&
                AccessControl(exilon).hasRole(bytes32(0), address(this)) &&
                !IExilon(exilon).isExcludedFromPayingFees(fundsHolder)
            ) {
                IExilon(exilon).excludeFromPayingFees(fundsHolder);
            }

            withdrawToken(allTokensInfo[i], msg.sender, fundsHolder, true);

            if (allTokensInfo[i].tokenType == TokenType.ERC20) {
                totalSharesOfERC20[id][allTokensInfo[i].tokenAddress] = allTokensInfo[i].amount;
            }
        }
    }

    function getRandomNumber(uint256 nonce, uint256 upperLimit) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.number,
                        msg.sender,
                        nonce,
                        blockhash(block.number - 1),
                        blockhash(block.number - 2),
                        block.coinbase,
                        block.difficulty
                    )
                )
            ) % upperLimit;
    }

    function processTokensInfo(WinningPlace[] calldata winningPlaces)
        external
        view
        returns (TokenInfo[] memory allTokensInfo, uint256 amountOfLootBoxes)
    {
        allTokensInfo = new TokenInfo[](MAX_TOKENS_IN_LOOTBOX);
        uint256 lastIndex = 0;

        for (uint256 i = 0; i < winningPlaces.length; ++i) {
            require(winningPlaces[i].placeAmounts > 0, "ExilonNftLootboxLibrary: Winning amount");
            amountOfLootBoxes += winningPlaces[i].placeAmounts;

            for (uint256 j = 0; j < winningPlaces[i].prizesInfo.length; ++j) {
                ExilonNftLootboxLibrary.TokenInfo memory currentToken = winningPlaces[i].prizesInfo[
                    j
                ];

                if (currentToken.tokenType == ExilonNftLootboxLibrary.TokenType.ERC20) {
                    require(currentToken.id == 0, "ExilonNftLootboxLibrary: ERC20 no id");
                    require(currentToken.amount > 0, "ExilonNftLootboxLibrary: ERC20 amount");
                } else if (currentToken.tokenType == ExilonNftLootboxLibrary.TokenType.ERC721) {
                    require(currentToken.amount == 0, "ExilonNftLootboxLibrary: ERC721 amount");
                    require(
                        winningPlaces[i].placeAmounts == 1,
                        "ExilonNftLootboxLibrary: No multiple winners for ERC721"
                    );

                    require(
                        IERC165(currentToken.tokenAddress).supportsInterface(bytes4(0x80ac58cd)),
                        "ExilonNftLootboxLibrary: ERC721 type"
                    );
                } else if (currentToken.tokenType == ExilonNftLootboxLibrary.TokenType.ERC1155) {
                    require(currentToken.amount > 0, "ExilonNftLootboxLibrary: ERC1155 amount");

                    require(
                        IERC165(currentToken.tokenAddress).supportsInterface(bytes4(0xd9b67a26)),
                        "ExilonNftLootboxLibrary: ERC1155 type"
                    );
                }
                currentToken.amount = currentToken.amount * winningPlaces[i].placeAmounts;

                uint256 index = _findTokenInTokenInfoArray(
                    allTokensInfo,
                    lastIndex,
                    currentToken.tokenAddress,
                    currentToken.id
                );
                if (index != type(uint256).max) {
                    require(
                        currentToken.tokenType != ExilonNftLootboxLibrary.TokenType.ERC721,
                        "ExilonNftLootboxLibrary: Multiple ERC721"
                    );
                    allTokensInfo[index].amount += currentToken.amount;
                } else {
                    require(
                        lastIndex < MAX_TOKENS_IN_LOOTBOX,
                        "ExilonNftLootboxLibrary: Too many different tokens"
                    );
                    allTokensInfo[lastIndex] = currentToken;

                    ++lastIndex;
                }
            }
        }

        uint256 numberToDecrease = MAX_TOKENS_IN_LOOTBOX - lastIndex;
        assembly {
            mstore(allTokensInfo, sub(mload(allTokensInfo), numberToDecrease))
        }
    }

    function _findTokenInTokenInfoArray(
        ExilonNftLootboxLibrary.TokenInfo[] memory tokensInfo,
        uint256 len,
        address token,
        uint256 id
    ) private pure returns (uint256) {
        for (uint256 i = 0; i < len; ++i) {
            if (tokensInfo[i].tokenAddress == token && tokensInfo[i].id == id) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function getWinningIndex(WinningPlace[] memory restPrizes, uint256 randomNumber)
        external
        pure
        returns (uint256 winningIndex)
    {
        winningIndex = type(uint256).max;
        uint256 amountPassed;
        for (uint256 j = 0; j < restPrizes.length && winningIndex == type(uint256).max; ++j) {
            if (restPrizes[j].placeAmounts >= randomNumber + 1 - amountPassed) {
                winningIndex = j;
            }
            amountPassed += restPrizes[j].placeAmounts;
        }
        require(winningIndex != type(uint256).max, "ExilonNftLootboxLibrary: Random generator");
    }

    function removeWinningPlace(
        WinningPlace[] memory restPrizes,
        uint256 winningIndex,
        WinningPlace[] storage winningPlaces,
        bool needToPeplaceCreators,
        mapping(uint256 => address) storage winningPlaceCreator
    ) external returns (WinningPlace[] memory) {
        restPrizes[winningIndex].placeAmounts -= 1;
        winningPlaces[winningIndex].placeAmounts -= 1;
        if (restPrizes[winningIndex].placeAmounts == 0) {
            uint256 len = restPrizes.length;
            if (winningIndex < len - 1) {
                winningPlaces[winningIndex] = winningPlaces[len - 1];
                restPrizes[winningIndex] = restPrizes[len - 1];

                if (needToPeplaceCreators) {
                    winningPlaceCreator[winningIndex] = winningPlaceCreator[len - 1];
                }
            }

            delete winningPlaceCreator[len];
            winningPlaces.pop();

            assembly {
                mstore(restPrizes, sub(mload(restPrizes), 1))
            }
        }

        return restPrizes;
    }

    function getUsdPriceOfAToken(
        IPancakeRouter02 pancakeRouter,
        address usdToken,
        address weth,
        address token,
        uint256 amount
    ) external view returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        if (token == usdToken) {
            return amount;
        } else if (token == weth) {
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = usdToken;
            return (pancakeRouter.getAmountsOut(amount, path))[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = token;
            path[1] = weth;
            path[2] = usdToken;
            return (pancakeRouter.getAmountsOut(amount, path))[2];
        }
    }

    function sendTokenCarefully(
        IERC20 token,
        uint256 amount,
        bool reequireSuccess
    ) external returns (bool, uint256) {
        uint256 balance;
        if (address(token) == address(0)) {
            balance = address(this).balance;
        } else {
            balance = token.balanceOf(address(this));
        }

        if (amount > balance) {
            amount = balance;
        }

        if (amount > 0) {
            bool success;
            if (address(token) == address(0)) {
                require(
                    gasleft() >= MAX_GAS_FOR_ETH_TRANSFER,
                    "ExilonNftLootboxLibrary: Not enough gas"
                );
                (success, ) = msg.sender.call{gas: MAX_GAS_FOR_ETH_TRANSFER, value: amount}("");
            } else {
                require(
                    gasleft() >= MAX_GAS_FOR_TOKEN_TRANSFER,
                    "ExilonNftLootboxLibrary: Not enough gas"
                );
                (success, ) = address(token).call{gas: MAX_GAS_FOR_TOKEN_TRANSFER}(
                    abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, amount)
                );
            }

            if (reequireSuccess) {
                require(success, "ExilonNftLootboxLibrary: Carefull token transfer failed");
                return (true, amount);
            } else {
                return (success, amount);
            }
        } else {
            return (true, 0);
        }
    }

    struct getWinningAmountInputStruct {
        uint256 totalShares;
        uint256 prizeInfoAmount;
        address tokenAddress;
        address fundsHolder;
        uint256 winningPlaceAmounts;
        uint256 nonce;
        uint256 minRandomPercentage;
        uint256 maxRandomPercentage;
        uint256 powParameter;
    }

    struct getWinningAmountOutputStruct {
        uint256 rawAmount;
        uint256 sharesAmount;
        uint256 newPrizeInfoAmount;
    }

    function getWinningAmount(getWinningAmountInputStruct memory input)
        external
        view
        returns (getWinningAmountOutputStruct memory output)
    {
        uint256 totalAmountOnFundsHolder = IERC20(input.tokenAddress).balanceOf(input.fundsHolder);

        uint256 totalAmountOfSharesForWinnginPlace = input.prizeInfoAmount *
            input.winningPlaceAmounts;
        uint256 totalAmountOfFundsForWinningPlace = (totalAmountOnFundsHolder *
            totalAmountOfSharesForWinnginPlace) / input.totalShares;

        if (input.winningPlaceAmounts == 1) {
            return
                getWinningAmountOutputStruct({
                    rawAmount: totalAmountOfFundsForWinningPlace,
                    sharesAmount: totalAmountOfSharesForWinnginPlace,
                    newPrizeInfoAmount: input.prizeInfoAmount
                });
        }

        uint256 randomNumber = getRandomNumber(input.nonce, 1000);

        (uint256 minWinningAmount, uint256 maxWinningAmount) = _getMinAndMaxAmount(
            totalAmountOfFundsForWinningPlace,
            input.winningPlaceAmounts,
            input.minRandomPercentage,
            input.maxRandomPercentage
        );
        output.rawAmount =
            minWinningAmount +
            (((maxWinningAmount - minWinningAmount) * randomNumber**input.powParameter) /
                1000**input.powParameter);

        (uint256 minSharesAmount, uint256 maxSharesAmount) = _getMinAndMaxAmount(
            totalAmountOfSharesForWinnginPlace,
            input.winningPlaceAmounts,
            input.minRandomPercentage,
            input.maxRandomPercentage
        );
        output.sharesAmount =
            minSharesAmount +
            (((maxSharesAmount - minSharesAmount) * randomNumber**input.powParameter) /
                1000**input.powParameter);

        output.newPrizeInfoAmount =
            (totalAmountOfSharesForWinnginPlace - output.sharesAmount) /
            (input.winningPlaceAmounts - 1);
    }

    function _getMinAndMaxAmount(
        uint256 total,
        uint256 winningPlaceAmounts,
        uint256 minRandomPercentage,
        uint256 maxRandomPercentage
    ) private pure returns (uint256 min, uint256 max) {
        min = (total * minRandomPercentage) / (winningPlaceAmounts * 10_000);
        max = (total * maxRandomPercentage) / (winningPlaceAmounts * 10_000);

        uint256 minimalReservationsForOtherUsers = (total * 5_000 * (winningPlaceAmounts - 1)) /
            (winningPlaceAmounts * 10_000);

        if (max > total - minimalReservationsForOtherUsers) {
            max = total - minimalReservationsForOtherUsers;
        }
    }

    struct addTokenInfoToAllTokensArrayInputStruct {
        TokenInfo prizeInfo;
        uint256 balanceBefore;
        uint256 lastIndex;
        TokenInfo[] successWithdrawTokens;
    }

    function addTokenInfoToAllTokensArray(addTokenInfoToAllTokensArrayInputStruct memory input)
        external
        view
        returns (
            TokenInfo[] memory,
            uint256,
            uint256
        )
    {
        if (input.prizeInfo.tokenType == TokenType.ERC20) {
            uint256 balanceAfter = IERC20(input.prizeInfo.tokenAddress).balanceOf(msg.sender);
            input.prizeInfo.amount = balanceAfter - input.balanceBefore;
        }

        uint256 index = _findTokenInTokenInfoArray(
            input.successWithdrawTokens,
            input.lastIndex,
            input.prizeInfo.tokenAddress,
            input.prizeInfo.id
        );
        if (index != type(uint256).max) {
            input.successWithdrawTokens[index].amount += input.prizeInfo.amount;
        } else {
            input.successWithdrawTokens[input.lastIndex] = input.prizeInfo;

            ++input.lastIndex;
        }

        return (input.successWithdrawTokens, input.lastIndex, input.prizeInfo.amount);
    }

    function _getRevertMsg(bytes memory revertData)
        private
        pure
        returns (string memory errorMessage)
    {
        // revert data format:
        // 4 bytes - Function selector for Error(string)
        // 32 bytes - Data offset
        // 32 bytes - String length
        // other - String data

        // If the revertData length is less than 68, then the transaction failed silently (without a revert message)
        if (revertData.length <= 68) return "";

        uint256 index = revertData.length - 1;
        while (index > 68 && revertData[index] == bytes1(0)) {
            index--;
        }
        uint256 numberOfZeroElements = revertData.length - 1 - index;

        bytes memory rawErrorMessage = new bytes(revertData.length - 68 - numberOfZeroElements);

        for (uint256 i = 0; i < revertData.length - 68 - numberOfZeroElements; ++i) {
            rawErrorMessage[i] = revertData[i + 68];
        }
        errorMessage = string(rawErrorMessage);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./pancake-swap/interfaces/IPancakeRouter02.sol";

import "./ExilonNftLootboxLibrary.sol";
import "./interfaces/IAccess.sol";

contract FeesCalculator is ReentrancyGuard {
    // public

    address public feeReceiver;

    IAccess public immutable accessControl;
    address public immutable usdToken;
    IPancakeRouter02 public immutable pancakeRouter;

    uint256 public extraPriceForFront = 1_000; // 10%

    // private

    address internal immutable _weth;
    bytes32 private immutable _MANAGER_ROLE;

    // internal

    uint256 internal immutable _oneUsd;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "FeesCalculator: Only EOA");
        _;
    }

    modifier onlyAdmin() {
        require(accessControl.hasRole(bytes32(0), msg.sender), "ExilonNftLootbox: No access");
        _;
    }

    modifier onlyManagerOrAdmin() {
        require(
            accessControl.hasRole(_MANAGER_ROLE, msg.sender) ||
                accessControl.hasRole(bytes32(0), msg.sender),
            "ExilonNftLootbox: No access"
        );
        _;
    }

    event FeeReceiverChange(address newValue);
    event ExtraPriceForFrontChange(uint256 newValue);

    event FeesCollected(address indexed user, uint256 bnbAmount, uint256 usdAmount);
    event CommissionTransfer(address indexed to, uint256 amount);

    event BadCommissionTransfer(address indexed to, uint256 amount);

    constructor(
        address _usdToken,
        IPancakeRouter02 _pancakeRouter,
        address _feeReceiver,
        IAccess _accessControl
    ) {
        usdToken = _usdToken;
        _oneUsd = 10**IERC20Metadata(_usdToken).decimals();

        pancakeRouter = _pancakeRouter;
        _weth = _pancakeRouter.WETH();

        feeReceiver = _feeReceiver;

        accessControl = _accessControl;
        _MANAGER_ROLE = _accessControl.MANAGER_ROLE();

        emit FeeReceiverChange(_feeReceiver);
        emit ExtraPriceForFrontChange(extraPriceForFront);
    }

    function processFeeTransferOnFeeReceiver() external onlyAdmin {
        _processFeeTransferOnFeeReceiverPrivate(true);
    }

    function setFeeReceiver(address newValue) external onlyAdmin {
        feeReceiver = newValue;

        emit FeeReceiverChange(newValue);
    }

    function setExtraPriceForFront(uint256 newValue) external onlyAdmin {
        require(newValue <= 5_000, "FeesCalculator: Too big percentage"); // 50%
        extraPriceForFront = newValue;

        emit ExtraPriceForFrontChange(newValue);
    }

    function _getBnbAmountToFront(uint256 usdAmount) internal view returns (uint256) {
        return _getBnbAmount((usdAmount * (extraPriceForFront + 10_000)) / 10_000);
    }

    function _processFeeTransferOnFeeReceiver() internal {
        _processFeeTransferOnFeeReceiverPrivate(false);
    }

    function _processFeeTransferOnFeeReceiverPrivate(bool force) private {
        address _feeReceiver = feeReceiver;
        uint256 amount = address(this).balance;
        if (amount == 0) {
            return;
        }
        bool success;
        if (force) {
            (success, ) = _feeReceiver.call{value: amount}("");
            require(success, "FeesCalculator: Transfer failed");
        } else {
            require(
                gasleft() >= ExilonNftLootboxLibrary.MAX_GAS_FOR_ETH_TRANSFER,
                "FeesCalculator: Not enough gas"
            );
            (success, ) = _feeReceiver.call{
                value: amount,
                gas: ExilonNftLootboxLibrary.MAX_GAS_FOR_ETH_TRANSFER
            }("");
        }
        if (!success) {
            emit BadCommissionTransfer(_feeReceiver, amount);
        } else {
            emit CommissionTransfer(_feeReceiver, amount);
        }
    }

    function _checkFees(uint256 amount) internal returns (uint256 bnbAmount) {
        bnbAmount = _getBnbAmount(amount);

        require(msg.value >= bnbAmount, "FeesCalculator: Not enough bnb");

        uint256 amountBack = msg.value - bnbAmount;
        if (amountBack > 0) {
            (bool success, ) = msg.sender.call{value: amountBack}("");
            require(success, "FeesCalculator: Failed transfer back");
        }

        emit FeesCollected(msg.sender, bnbAmount, amount);
    }

    function _getBnbAmount(uint256 usdAmount) private view onlyEOA returns (uint256) {
        if (usdAmount == 0) {
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = _weth;
        path[1] = usdToken;
        return (pancakeRouter.getAmountsIn(usdAmount, path))[0];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

interface INftMarketplace {
    function isTokenModerated(address token, uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

interface IPancakeRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

interface IExilon {
    function isExcludedFromPayingFees(address user) external view returns (bool);

    function addLiquidity() external payable;

    function forceLpFeesDistribute() external;

    function excludeFromFeesDistribution(address user) external;

    function includeToFeesDistribution(address user) external;

    function excludeFromPayingFees(address user) external;

    function includeToPayingFees(address user) external;

    function enableLowerCommissions(address user) external;

    function disableLowerCommissions(address user) external;

    function setWethLimitForLpFee(uint256 newValue) external;

    function setDefaultLpMintAddress(address newValue) external;

    function setMarketingAddress(address newValue) external;
}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccess is IAccessControl {
    function MANAGER_ROLE() external view returns (bytes32);
}