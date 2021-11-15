// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LuckyBonnieLotteryBNB is AccessControl, Ownable, ReentrancyGuard  {
    bytes32 public constant BONNIE_ROLE = keccak256("BONNIE_ROLE");
    // enums 
    enum Status { Pending, Open, Close }
    // structs
    struct RoundUserInfo {
        uint256 roundId;
        bool claimed;
        uint256[] tickets;
    }

    struct Round {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicket;
        uint256[6] rewardMatchRate;
        uint256[6] rewardsPerMatching;
        uint256[6] countWinnersPerMatching;
        uint256 totalAmount;
        uint256 houseRate;
        uint256 roundRate;
        uint256 discountRate;
        uint256 ticketInit;
        uint256 ticketInitNextRound;
        uint256 finalNumber;
        string random;
        string signature;
    }

    // maps
    mapping(uint256 => Round) private _rounds;
    mapping(address => RoundUserInfo[]) private _roundsByUser;
    mapping(address => mapping(uint256 => uint256)) private _indexRoundsUser;
    mapping(uint256 => mapping(uint256 => uint256)) private _ticketsByRound;

    // vars
    uint256 public currentRoundId = 0;
    uint256 public currentTicket = 1;
    uint256 public pricePerTicket = 0.005 ether;
    uint256[6] public rewardMatchRate = [0, 5, 10, 15, 20, 50]; // %
    
    uint256 public roundRate = 95; 
    uint256 public houseRate = 5;

    uint256 private _injectFromPreviousRound = 0;
    uint256 private _treasury = 0;
    uint256 private _discountRate = 0;

    uint256 public constant MIN_TIME_ROUND = 6 hours - 5 minutes;
    uint256 public constant MAX_TIME_ROUND = 3 days + 5 minutes;
    uint256 public constant TOTAL_RATE = 100;
    uint256 public constant MAX_TREASURY_RATE = 30;
    uint256 public constant MAX_TICKETS_PER_BUY = 100;
    uint256 public constant MAX_DISCOUNT = 30;
    
    uint256 public constant MAX_PRICE_TICKET = 1 ether;
    uint256 public constant MIN_PRICE_TICKET = 0.001 ether;

    // events
    event RatesUpdated(
        uint256 beforeRoundRate,
        uint256 beforeHouseRate,
        uint256 afterRoundRate,
        uint256 afterHouseRate
    );
    event RoundOpen(
        uint256 indexed roundId,
        uint256 ticketInit,
        uint256 priceTicket,
        uint256 initAmount,
        uint256 endTime
    );
    event RoundClose(uint256 indexed roundId, uint256 finalNumber);
    event TicketsPurchase(address indexed customer, uint256 indexed roundId, uint256 totalTicketsBuy);
    event TicketsClaim(address indexed customer, uint256 amount, uint256 indexed roundId, uint256 totalTicketsClaim);

    constructor(
        address _admin,
        address _bonnie
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BONNIE_ROLE, _bonnie);
    }

    // MODIFIERS
    modifier onlyAdminOrBonnie() {
        require(
            (hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(BONNIE_ROLE, msg.sender)),
            "only admin or bonnie"
        );
        _;
    }

    /* solhint-disable */
    modifier onlyHuman() {
        uint256 size;
        address addr = msg.sender;

        assembly {
            size := extcodesize(addr)
        }

        require(!(size > 0), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }
    /* solhint-enable */

    function startRound(uint256 _endTime) external onlyRole(BONNIE_ROLE)  {
        require(
            (currentRoundId == 0) || (_rounds[currentRoundId].status == Status.Close),
            "Not time to start round"
        );

        require(
            (pricePerTicket >= MIN_PRICE_TICKET) && (pricePerTicket <= MAX_PRICE_TICKET),
            "Outside of limits price"
        );

        require(houseRate <= MAX_TREASURY_RATE, "Treasury rate too high");

        require(
            // solhint-disable-next-line
            ((_endTime - block.timestamp) > MIN_TIME_ROUND) && ((_endTime - block.timestamp) < MAX_TIME_ROUND),
            "Round length outside of range"
        );

        currentRoundId++;

        _rounds[currentRoundId].status = Status.Open;
        // solhint-disable-next-line
        _rounds[currentRoundId].startTime = block.timestamp;
        _rounds[currentRoundId].endTime = _endTime;
        _rounds[currentRoundId].priceTicket = pricePerTicket;
        _rounds[currentRoundId].rewardMatchRate = rewardMatchRate;
        _rounds[currentRoundId].totalAmount = _injectFromPreviousRound;
        _rounds[currentRoundId].status = Status.Open;
        _rounds[currentRoundId].houseRate = houseRate;
        _rounds[currentRoundId].roundRate = roundRate;
        _rounds[currentRoundId].discountRate = _discountRate;
        _rounds[currentRoundId].ticketInit = currentTicket;

        emit RoundOpen(
            currentRoundId,
            currentTicket,
            pricePerTicket,
            _injectFromPreviousRound,
            _endTime
        );

        _injectFromPreviousRound = 0;
    }

    function closeRound(
        uint256 _finalNumber,
        string memory _random,
        string memory _signature
    ) external onlyRole(BONNIE_ROLE) {
        require(_rounds[currentRoundId].status == Status.Open, "Round not open");
        // solhint-disable-next-line
        require(block.timestamp > _rounds[currentRoundId].endTime, "Round not over");

        _rounds[currentRoundId].ticketInitNextRound = currentTicket;
        _rounds[currentRoundId].status = Status.Close;
        _rounds[currentRoundId].random = _random;
        _rounds[currentRoundId].signature = _signature;
        _rounds[currentRoundId].finalNumber = _finalNumber;

        uint256 amountToWinners = (
            _rounds[currentRoundId].totalAmount * _rounds[currentRoundId].roundRate
        ) / 100;

        uint256 previusAsserts = 0;

        for (uint256 i = 0; i < 6; i++) {
            uint256 p = 5 - i;
            uint256 numberInAssert = (_finalNumber - (_finalNumber % (uint256(10)**(i))));

            // totals wins for assertion
            uint256 ticketsMatch = _ticketsByRound[currentRoundId][numberInAssert] - previusAsserts;
            previusAsserts = _ticketsByRound[currentRoundId][numberInAssert];

            // calculate wins per match
            _rounds[currentRoundId].countWinnersPerMatching[p] = ticketsMatch;
            // calculate amount per match
            uint256 _totalRewardMatch = ( amountToWinners * _rounds[currentRoundId].rewardMatchRate[p] ) / 100;

            if (_rounds[currentRoundId].countWinnersPerMatching[p] > 0) {
                _rounds[currentRoundId].rewardsPerMatching[p] = _totalRewardMatch;
            } else {
                _injectFromPreviousRound += _totalRewardMatch;
            }
        }

        _treasury += _rounds[currentRoundId].totalAmount - amountToWinners;

        emit RoundClose(currentRoundId, _finalNumber);
    }

    function buyTickets(uint256[] calldata _ticketsBuy) external payable onlyHuman nonReentrant {
        require(_ticketsBuy.length != 0, "No ticket buy specified");
        require(_ticketsBuy.length <= MAX_TICKETS_PER_BUY, "Too many tickets");

        require(_rounds[currentRoundId].status == Status.Open, "Round is not open");
        // solhint-disable-next-line
        require(block.timestamp < _rounds[currentRoundId].endTime, "Round is over");

        // validate price tickets buy
        require(
            msg.value == _calculateTotalPriceForBuy(_rounds[currentRoundId].discountRate, _rounds[currentRoundId].priceTicket, _ticketsBuy.length),
            "invalid amount to buy"
        );

        bool insertInLoop = false;
        // varify previus buy in current round
        if (
            _roundsByUser[msg.sender].length > 0 &&
            _roundsByUser[msg.sender][_roundsByUser[msg.sender].length - 1].roundId == currentRoundId
        ) {
            insertInLoop = true;
        } else {
            _roundsByUser[msg.sender].push(RoundUserInfo(currentRoundId, false, _ticketsBuy));
        }
        
        for (uint256 i = 0; i < _ticketsBuy.length; i++) {
            require((_ticketsBuy[i] >= 111111) && (_ticketsBuy[i] <= 999999), "Outside range");

            _ticketsByRound[currentRoundId][_ticketsBuy[i] - (_ticketsBuy[i] % 100000)]++; // 1 match
            _ticketsByRound[currentRoundId][_ticketsBuy[i] - (_ticketsBuy[i] % 10000)]++; // 2 match
            _ticketsByRound[currentRoundId][_ticketsBuy[i] - (_ticketsBuy[i] % 1000)]++; // 3 match
            _ticketsByRound[currentRoundId][_ticketsBuy[i] - (_ticketsBuy[i] % 100)]++; // 4 match
            _ticketsByRound[currentRoundId][_ticketsBuy[i] - (_ticketsBuy[i] % 10)]++; // 5 match
            _ticketsByRound[currentRoundId][_ticketsBuy[i] - (_ticketsBuy[i] % 1)]++; // 6 match

            // save ticket
            if (insertInLoop) {
                _roundsByUser[msg.sender][_roundsByUser[msg.sender].length - 1].tickets.push(_ticketsBuy[i]);
            }

            currentTicket++;
        }

        _rounds[currentRoundId].totalAmount += msg.value;
        _indexRoundsUser[msg.sender][currentRoundId] = _roundsByUser[msg.sender].length - 1;

        emit TicketsPurchase(msg.sender, currentRoundId, _ticketsBuy.length);
    }

    function historyUserRounds(uint256 _cursor, uint256 _size, address user) public view returns (RoundUserInfo[] memory, uint256 total, uint256 cursor) {
        uint256 _t = _roundsByUser[user].length;

        if (_t == 0 || _cursor > _t) {
            return (new RoundUserInfo[](0), _t, _cursor);
        }

        RoundUserInfo[] memory _mt =  new RoundUserInfo[](_size);

        for (uint256 i = 0; i < _size; i++) {
           _mt[i].roundId = _roundsByUser[user][i + _cursor].roundId;
           _mt[i].claimed = _roundsByUser[user][i + _cursor].claimed;
           _mt[i].tickets = _roundsByUser[user][i + _cursor].tickets;
        }

        return (_mt, _t, _cursor);
    }

    function updateRates(uint256 newRoundRate, uint256 newHouseRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // validate values ok
        require(
            (newRoundRate + newHouseRate) == TOTAL_RATE,
            "invalid for total rate"
        );

        require(newHouseRate < MAX_TREASURY_RATE, "usury not allowed");

        uint256 oldRoundRate = roundRate;
        uint256 oldHouseRate = houseRate;

        roundRate = newRoundRate;
        houseRate = newHouseRate;

        emit RatesUpdated(
            oldRoundRate,
            oldHouseRate,
            newRoundRate,
            newHouseRate
        );
    }

    function updateTicketPrice(uint256 _newPriceTicket)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newPriceTicket <= MAX_PRICE_TICKET, "price must be <= max price");
        require(_newPriceTicket >= MIN_PRICE_TICKET, "price must be >= min price");

        pricePerTicket = _newPriceTicket;
    }
    
    function updateDiscountRate(uint256 _newDiscountRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newDiscountRate <= MAX_DISCOUNT, "discount must be <= max discount");

        _discountRate = _newDiscountRate;
    }

    function getRound(uint256 _roundId) public view returns (Round memory findRound) {
        return _rounds[_roundId];
    }

    function getPriceCurrentRound() public view returns (uint256 price) {
        return _rounds[currentRoundId].priceTicket;
    }

    function _calculateTotalPriceForBuy(
        uint256 _discount,
        uint256 _price,
        uint256 _items
    ) internal pure returns (uint256) {
        return ((_price * _items) * (100 - ((_discount * (_items - 1)) / 100)) ) / 100;
    }

    function calculateTotalPriceForBuy(
        uint256 _numberTickets
    ) external view returns (uint256) {
        require(_numberTickets != 0, "Number of tickets must be > 0");
        return _calculateTotalPriceForBuy(_rounds[currentRoundId].discountRate, _rounds[currentRoundId].priceTicket, _numberTickets);
    }
    
    function claimRound(uint256 _roundId) external onlyHuman nonReentrant {
        Round memory _r = _rounds[_roundId];
        uint256 _iu = _indexRoundsUser[msg.sender][_roundId];

        require(_roundsByUser[msg.sender].length > 0 && _roundsByUser[msg.sender].length > _iu, "Not round");

        // final number
        uint256 _f = _r.finalNumber;
        // tickets user
        RoundUserInfo memory _ui = _roundsByUser[msg.sender][_iu];
        uint256[] memory _t = _ui.tickets;
        uint256 reward = 0;
        
        require(_r.status == Status.Close, "Round not over");
        require(_ui.claimed == false, "Not claimable");
        require(_t.length > 0, "Not tickets");

        // win number
        for (uint256 i = 0; i < _t.length; i++) {
            // assert in regresion
            for (uint32 i2 = 0; i2 < 6; i2++) {
                uint32 j = 5 - i2;
                if (
                    _r.rewardsPerMatching[j] > 0 &&
                    _f - (_f % ( 10 ** i2 )) == _t[i] - (_t[i] % ( 10 ** i2 ))
                ) {
                    reward += (_r.rewardsPerMatching[j] / _r.countWinnersPerMatching[j]);
                    break;
                }
            }
        }

        if(reward > 0) {
            _roundsByUser[msg.sender][_iu].claimed = true;
            _safeTransferBNB(address(msg.sender), reward);
        }
    }

    function _safeTransferBNB(address to, uint256 value) internal {
        // solhint-disable-next-line
        (bool success, ) = to.call{value: value}("");
        require(success, "BNB_TRANSFER_FAILED");
    }
}

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

import "../utils/Context.sol";

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

