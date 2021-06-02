/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-20
*/

pragma solidity 0.6.6;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
}

interface ISorareData {
    function createPlayer(
        string calldata name,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    ) external returns (uint256);

    function getPlayer(uint256 playerId)
    external
    view
    returns (
        string memory name,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    );

    function createClub(
        string calldata name,
        string calldata country,
        string calldata city,
        uint16 yearFounded
    ) external returns (uint16);

    function getClub(uint16 clubId)
    external
    view
    returns (
        string memory name,
        string memory country,
        string memory city,
        uint16 yearFounded
    );

    function playerExists(uint256 playerId) external view returns (bool);

    function clubExists(uint16 clubId) external view returns (bool);
}

interface ISorareCards {
    function createCard(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    ) external returns (uint256);

    function getCard(uint256 _cardId)
    external
    view
    returns (
        uint256 playerId,
        uint16 season,
        uint256 scarcity,
        uint16 serialNumber,
        bytes memory metadata,
        uint16 clubId
    );

    function getPlayer(uint256 playerId)
    external
    view
    returns (
        string memory name,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    );

    function getClub(uint16 clubId)
    external
    view
    returns (
        string memory name,
        string memory country,
        string memory city,
        uint16 yearFounded
    );

    function cardExists(uint256 cardId) external view returns (bool);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MinterAccess is Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, _msgSender()), "Sender is not a minter");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function addMinter(address account) external {
        grantRole(MINTER_ROLE, account);
    }

    function renounceMinter(address account) external {
        renounceRole(MINTER_ROLE, account);
    }

    function revokeMinter(address account) external {
        revokeRole(MINTER_ROLE, account);
    }
}

contract CapperAccess is Ownable, AccessControl {
    bytes32 public constant CAPPER_ROLE = keccak256("CAPPER_ROLE");

    modifier onlyCapper {
        require(hasRole(CAPPER_ROLE, _msgSender()), "Sender is not a capper");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CAPPER_ROLE, msg.sender);
    }

    function addCapper(address account) external {
        grantRole(CAPPER_ROLE, account);
    }

    function renounceCapper(address account) external {
        renounceRole(CAPPER_ROLE, account);
    }
}

contract SorareCards is MinterAccess, CapperAccess, ISorareCards {
    struct Card {
        // The id of the football Player
        uint256 playerId;
        /// @dev Contains the immutable metadata hash for each card.The IPFS address can be computed
        /// like so base58('1220' + hex(value))
        bytes32 metadata;
        // The football season represented by the first year of the season: Season 2018/2019 is 2018.
        uint16 season;
        // Card serial number
        uint16 serialNumber;
        // Card scarcity
        uint8 scarcity;
        // Id of the football club
        uint16 clubId;
    }

    /// @dev The CardAdded is fired whenever a new Card is minted.
    event CardAdded(
        uint256 indexed cardId,
        uint256 indexed playerId,
        uint16 indexed season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    );

    ISorareData private sorareData;

    /// @dev The limit number of cards that can be minted depending on their Scarcity Level.
    uint256[] public scarcityLimitByLevel;

    /// @dev Specifies if production of cards of a given season and scarcity has been stopped
    mapping(uint16 => mapping(uint256 => bool)) internal stoppedProductionBySeasonAndScarcityLevel;

    /// @dev A mapping containing the Card struct for all Cards in existence.
    mapping(uint256 => Card) public cards;

    constructor(address sorareDataAddress) public {
        require(
            sorareDataAddress != address(0),
            "SorareData address is required"
        );
        sorareData = ISorareData(sorareDataAddress);

        scarcityLimitByLevel.push(1);
        scarcityLimitByLevel.push(10);
        scarcityLimitByLevel.push(100);
    }

    /// @dev Init the maximum number of cards that can be created for a scarcity level.
    function setScarcityLimit(uint256 limit) public onlyCapper {
        uint256 editedScarcities = scarcityLimitByLevel.length - 1;
        require(
            limit >= scarcityLimitByLevel[editedScarcities] * 2,
            "Limit not large enough"
        );

        scarcityLimitByLevel.push(limit);
    }

    /// @dev Stop the production of cards for a given season and scarcity level
    function stopProductionForSeasonAndScarcityLevel(uint16 season, uint8 level)
    public
    onlyMinter
    {
        stoppedProductionBySeasonAndScarcityLevel[season][level] = true;
    }

    /// @dev Returns true if the production has been stopped for a given season and scarcity level
    function productionStoppedForSeasonAndScarcityLevel(
        uint16 season,
        uint8 level
    ) public view returns (bool) {
        return stoppedProductionBySeasonAndScarcityLevel[season][level];
    }

    // prettier-ignore
    function createCard(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    )
    public
    onlyMinter
    override
    returns (
        uint256
    )
    {
        require(sorareData.playerExists(playerId), "Player does not exist");
        require(sorareData.clubExists(clubId), "Club does not exist");

        require(
            serialNumber >= 1 && serialNumber <= scarcityLimitByLevel[scarcity],
            "Invalid serial number"
        );
        require(
            stoppedProductionBySeasonAndScarcityLevel[season][scarcity] ==
            false,
            "Production has been stopped"
        );

        Card memory card;
        card.playerId = playerId;
        card.season = season;
        card.scarcity = scarcity;
        card.serialNumber = serialNumber;
        card.metadata = metadata;
        card.clubId = clubId;
        uint256 cardId = uint256(
            keccak256(
                abi.encodePacked(
                    playerId,
                    season,
                    uint256(scarcity),
                    serialNumber
                )
            )
        );

        require(cards[cardId].playerId == 0, "Card already exists");

        cards[cardId] = card;

        emit CardAdded(
            cardId,
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        );

        return cardId;
    }

    // prettier-ignore
    function getCard(
        uint256 cardId // prettier-ignore
    )
    external
    override
    view
    returns (
        uint256 playerId,
        uint16 season,
        uint256 scarcity,
        uint16 serialNumber,
        bytes memory metadata,
        uint16 clubId
    )
    {
        Card storage c = cards[cardId];
        playerId = c.playerId;
        season = c.season;
        scarcity = c.scarcity;
        serialNumber = c.serialNumber;
        // Our IPFS hash will always be encoded using SHA256
        metadata = sha256Bytes32ToBytes(c.metadata);
        clubId = c.clubId;
    }

    // prettier-ignore
    function getPlayer(uint256 playerId)
    external
    override
    view
    returns (
        string memory name,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    )
    {
        (name, yearOfBirth, monthOfBirth, dayOfBirth) = sorareData.getPlayer(playerId);
    }

    // prettier-ignore
    function getClub(uint16 clubId)
    external
    override
    view
    returns (
        string memory name,
        string memory country,
        string memory city,
        uint16 yearFounded
    )
    {
        (name, country, city, yearFounded) = sorareData.getClub(clubId);
    }

    // prettier-ignore
    function cardExists(uint256 cardId) external override view returns(bool) {
        Card storage card = cards[cardId];
        return card.season > 0;
    }

    function sha256Bytes32ToBytes(bytes32 _bytes32)
    internal
    pure
    returns (bytes memory)
    {
        bytes memory bytesArray = new bytes(34);
        bytesArray[0] = 0x12;
        bytesArray[1] = 0x20;
        // We add 0x1220 to specify the encryption algorithm
        for (uint256 i = 2; i < 34; i++) {
            bytesArray[i] = _bytes32[i - 2];
        }
        return bytesArray;
    }
}