// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITokenLocker.sol";

/// @title PrivateSaleClaimer for private sale claim token in vesting model
/// @author [email protected]
/// @notice this contract use for private sale token, please check which token that this contract selling
/// @dev this contract use proxy upgradeable, multi role access control and 10**6 based denominator
/// this contract already optimize gas used by storage layout, be safe for add or change order of state variable
/// Enjoy reading. Hopefully it's bug-free. I bless, You bless, God bless. Thank you.
contract TokenLocker is
    ITokenLocker,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// === PERCENTAGE VARIABLE ===
    /// @notice initial release percent when buy token, safe use with DENOMINATOR
    uint48 public INITIAL_RELEASE_PERCENT;
    /// @notice release percent for each chunk, safe use with DENOMINATOR
    uint48 public CHUNK_RELEASE_PERCENT;
    /// NOTE for example 100% is 1 * DENOMINATOR, so 5% is 5/100 * DENOMINATOR

    /// @notice denominator for shift decimal in math divide
    uint48 public DENOMINATOR;

    /// === TIME VARIABLE ===
    /// @notice timestamp for release of first chunk
    uint48 public FIRST_RELEASE_TIMESTAMP;
    /// @notice timestamp for release of second chunk
    uint48 public SECOND_RELEASE_TIMESTAMP;
    /// @notice duration of each chunk
    uint48 public CHUNK_TIMEFRAME;
    /// @notice max chunk of this vesting plan, will calculate in initialize method
    uint16 public MAX_CHUNK;

    /// === TOKEN ===
    /// @notice private sale token for this contract
    IERC20 public token;

    /// === TOTAL COLLECTOR VARIABLE ===
    /// @notice total token for sale, can change only by deposit/withdraw method
    uint256 public totalToken;
    /// @notice total token already sale, include unclaimed token
    uint256 public totalSale;
    /// @notice total token already claim, include initial token
    /// @dev when all use claim all token, totalSale will equal to totalClaim
    uint256 public totalClaimed;

    /// === ROLE HASH VARIABLE ===
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant FUND_OWNER_ROLE = keccak256("FUND_OWNER_ROLE");

    /// === USER INFO VARIABLE ===
    /// @notice mapping for user address to user information
    mapping(address => UserInfo) public userInfo;
    /// @notice array of unique buyer address
    address[] public buyers;

    modifier beforeFirstRelease() {
        require(
            block.timestamp < FIRST_RELEASE_TIMESTAMP,
            "CLAIMER: OUT_OF_DATE"
        );
        _;
    }

    modifier afterFirstRelease() {
        require(
            block.timestamp >= FIRST_RELEASE_TIMESTAMP,
            "CLAIMER: OUT_OF_DATE"
        );
        _;
    }

    /// @notice Initialize contract after deploy
    /// @param _initialReleasePercent initial release percent when buy on private sale
    /// @param _chunkReleasePercent release percent of each chunk
    /// @param _firstReleaseTimestamp timestamp of first chuck to be claim`
    /// @param _chunkTimeframe time range of each chuck
    /// @param _token address of ICO token
    function initialize(
        uint48 _initialReleasePercent,
        uint48 _chunkReleasePercent,
        uint48 _firstReleaseTimestamp,
        uint48 _secondReleaseTimestamp,
        uint48 _chunkTimeframe,
        IERC20 _token
    ) public initializer {
        require(
            address(_token) != address(0) && _chunkTimeframe > 0,
            "CLAIMER: INVALID_PARAMETER"
        );
        // initial parent
        __AccessControl_init();
        __ReentrancyGuard_init();

        // setup state variable
        INITIAL_RELEASE_PERCENT = _initialReleasePercent;
        CHUNK_RELEASE_PERCENT = _chunkReleasePercent;
        FIRST_RELEASE_TIMESTAMP = _firstReleaseTimestamp;
        SECOND_RELEASE_TIMESTAMP = _secondReleaseTimestamp;
        CHUNK_TIMEFRAME = _chunkTimeframe;
        token = _token;
        DENOMINATOR = 10**6;

        // calculate max chunk
        // @formula max_chunk = ceil[(100% - init%) / chunk%] + 1
        MAX_CHUNK = uint16(
            Math.ceilDiv(
                ((1 * DENOMINATOR) - _initialReleasePercent),
                _chunkReleasePercent
            ) + 1 // +1 for initial chunk
        );

        // setup access role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FUND_OWNER_ROLE, msg.sender);
    }

    /// @dev call transferFram token and check it success
    /// @param _token token to be called
    /// @param sender sender
    /// @param receiver receiver
    /// @param amount amount
    function _safeTransferFrom(
        IERC20 _token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        require(
            _token.transferFrom(sender, receiver, amount),
            "CLAIMER: TRANSFER_FAIL"
        );
    }

    /// @dev call transfer token and check it success
    /// @param _token token to be called
    /// @param receiver receiver
    /// @param amount amount
    function _safeTransfer(
        IERC20 _token,
        address receiver,
        uint256 amount
    ) internal {
        require(_token.transfer(receiver, amount), "CLAIMER: TRANSFER_FAIL");
    }

    /// @notice buy private sale token by distributor
    /// @param _receiver token receiver of this purchasing
    /// @param _totalReceive amount of token in this purchasing
    function lock(address _receiver, uint256 _totalReceive)
        external
        override
        nonReentrant
        onlyRole(DISTRIBUTOR_ROLE)
    {
        // 1. CHECK
        uint256 _totalSale = totalSale; // for gas reduce
        require(_totalReceive > 0, "CLAIMER: INVALID_AMOUNT");
        require(
            _totalSale + _totalReceive <= totalToken,
            "CLAIMER: INSUFFICIENT_TOKEN"
        );

        // 2. EFFECT
        //  2.1 calculate inital release token
        //  initToken = token_receive * initPercent
        uint256 initToken = (_totalReceive * INITIAL_RELEASE_PERCENT) /
            DENOMINATOR;
        //  2.2 update userInfo
        //   2.2.1 query userInfo, if new all value is zero
        UserInfo storage _userInfo = userInfo[_receiver]; // try to use memory cannot reduce gas in this case

        //   2.2.2 if new user, add to list
        if (_userInfo.totalReceiveToken == 0) {
            buyers.push(_receiver);
        }

        uint256 pending = 0;
        if (_userInfo.lastClaimChunk != 0) {
            // transfer unclaimed token
            pending = Math.min(
                (initToken +
                    ((_userInfo.lastClaimChunk - 1) *
                        CHUNK_RELEASE_PERCENT *
                        _totalReceive) /
                    DENOMINATOR),
                _totalReceive
            );
        }
        //   2.2.3 udpdate info
        _userInfo.totalReceiveToken += _totalReceive;
        _userInfo.initialChunkToken += initToken;
        _userInfo.totalClaimedToken += pending;

        //  2.3 update total variables

        totalSale = _totalSale + _totalReceive;
        // if (pending != 0) {
        //     uint256 _totalClaimed = totalClaimed;
        //     totalClaimed = _totalClaimed + pending;
        // }

        // 3. INTERACT
        //  3.1 tranfer initial token
        if (pending != 0) {
            uint256 _totalClaimed = totalClaimed;
            totalClaimed = _totalClaimed + pending;

            _safeTransfer(token, _receiver, pending);
        }

        // 4. EMIT
        emit Lock(_receiver, _totalReceive);
    }

    /// @notice calculate pending token to claim for given receiver address
    /// @param _receiver receiver address
    /// @return pending token to claim in Wei
    function pendingToken(address _receiver)
        external
        view
        override
        returns (uint256 pending)
    {
        uint256 _firstReleaseTimestamp = FIRST_RELEASE_TIMESTAMP;
        uint256 _secondReleaseTimestamp = SECOND_RELEASE_TIMESTAMP;
        if (block.timestamp < _firstReleaseTimestamp) {
            return 0;
        }
        UserInfo memory _userInfo = userInfo[_receiver];
        uint256 chunkNo = 0;
        if (block.timestamp >= _firstReleaseTimestamp) {
            chunkNo = 1;
        }
        if (block.timestamp >= _secondReleaseTimestamp) {
            // chunkNo = min( ceil((ts - FIRST_TS + 1) / TF), MAX_CHUNK)
            // add 1 for shift in case ts == FIRST_TS
            chunkNo += uint256(
                Math.min(
                    Math.ceilDiv(
                        block.timestamp - _secondReleaseTimestamp + 1,
                        CHUNK_TIMEFRAME
                    ),
                    MAX_CHUNK
                )
            );
        }
        // calculate unclaim chunk

        // formula = min[ (totalReceive * initialPercent + (chunk - 1) * totalReceive) - totalClaimed, totalReceive - totalClaimed ]
        pending = Math.min(
            (_userInfo.initialChunkToken +
                ((chunkNo - 1) *
                    CHUNK_RELEASE_PERCENT *
                    _userInfo.totalReceiveToken) /
                DENOMINATOR) - _userInfo.totalClaimedToken,
            _userInfo.totalReceiveToken - _userInfo.totalClaimedToken
        );

        // ** legacy
        // uint256 chunk = chunkNo - _userInfo.lastClaimChunk;
        // calculate pending token
        // pending = min[ totalReceive * chunk * chunkPercent, totalReceive - totalClaim ]
        // use min for prevent over spending
        // pending = Math.min(
        //     (_userInfo.totalReceiveToken * chunk * CHUNK_RELEASE_PERCENT) /
        //         DENOMINATOR,
        //     _userInfo.totalReceiveToken - _userInfo.totalClaimedToken
        // );
    }

    /// @notice get number of buyer in private sale
    /// @dev use with buyers for get all buyer address
    /// @return number of buyer in private sale
    function buyersLength() external view override returns (uint256) {
        return buyers.length;
    }

    /// @dev internal function for perform claim
    /// @param _receiver given receiver
    function _claim(address _receiver) internal {
        // 1. CHECK
        UserInfo memory _userInfo = userInfo[_receiver]; // memory local for gas reduce
        //  1.1 check user is in private sale
        require(_userInfo.totalReceiveToken > 0, "CLAIMER: NO_TOKEN_TO_CLAIM");

        //  1.2 token to claim
        //   1.2.1 calculate current chunk no.
        //    chunkNo = min( ceil((ts - FIRST_TS + 1) / TF), MAX_CHUNK)
        //    +1 for shift in case ts=FIRST_TS or ts=FIRST_TS + n*TF
        uint256 chunkNo = 0;
        if (block.timestamp >= FIRST_RELEASE_TIMESTAMP) {
            chunkNo = 1;
        }
        uint256 _secondReleaseTimestamp = SECOND_RELEASE_TIMESTAMP; // gas reduce
        if (block.timestamp >= _secondReleaseTimestamp) {
            // chunkNo = min( ceil((ts - FIRST_TS + 1) / TF), MAX_CHUNK)
            // add 1 for shift in case ts == FIRST_TS
            chunkNo += uint256(
                Math.min(
                    Math.ceilDiv(
                        block.timestamp - _secondReleaseTimestamp + 1,
                        CHUNK_TIMEFRAME
                    ),
                    MAX_CHUNK
                )
            );
        }
        require(
            _userInfo.lastClaimChunk < chunkNo,
            "CLAIMER: NO_TOKEN_TO_CLAIM"
        );
        //    1.2.2 calculate unclaim chunk
        // uint256 chunk = chunkNo - _userInfo.lastClaimChunk;
        //    1.2.3 calculate pending token
        //     pending = min[ totalReceive * chunk * chunkPercent, totalReceive - totalClaim ]
        //     use min for prevent over spending

        // formula = min[ (totalReceive * initialPercent + (chunk - 1) * totalReceive) - totalClaimed, totalReceive - totalClaimed ]
        uint256 pending = Math.min(
            (_userInfo.initialChunkToken +
                ((chunkNo - 1) *
                    CHUNK_RELEASE_PERCENT *
                    _userInfo.totalReceiveToken) /
                DENOMINATOR) - _userInfo.totalClaimedToken,
            _userInfo.totalReceiveToken - _userInfo.totalClaimedToken
        );

        // uint256 tokenToClaim = Math.min(
        //     (_userInfo.totalReceiveToken * chunk * CHUNK_RELEASE_PERCENT) /
        //         DENOMINATOR,
        //     _userInfo.totalReceiveToken - _userInfo.totalClaimedToken
        // );

        require(pending > 0, "CLAIMER: NO_TOKEN_TO_CLAIM");

        // 2. EFFECT
        //  2.1 update user info
        UserInfo storage __userInfo = userInfo[_receiver];
        __userInfo.totalClaimedToken = _userInfo.totalClaimedToken + pending;
        __userInfo.lastClaimChunk = chunkNo;
        //   2.2 update total variable
        uint256 _totalClaimed = totalClaimed;
        totalClaimed = _totalClaimed + pending;

        // 3. INTERACT
        //  3.1 transfer pending token to receiver
        _safeTransfer(token, _receiver, pending);

        // 4. EMIT
        emit Claim(_receiver, pending);
    }

    /// @notice claim pending token for given receiver address, this method freely to everyone can call
    /// @param _receiver target receiver address
    function claim(address _receiver)
        external
        override
        nonReentrant
        afterFirstRelease
    {
        _claim(_receiver);
    }

    /// @notice claim pending token for multiple given receiver address, this method freely to everyone can call
    /// @param _receivers target receivers address
    function claimMultiple(address[] calldata _receivers)
        external
        override
        nonReentrant
        afterFirstRelease
    {
        require(_receivers.length > 0, "CLAIMER: EMPTY_ARRAY");
        for (uint256 index = 0; index < _receivers.length; index++) {
            _claim(_receivers[index]);
        }
    }

    /// @notice use by fund owner to deposit token for privatesale
    /// @dev this function use transferFrom, not balanceOf, because give owner to easy control totalToken for privatesale
    /// @param amount amount of token (in Wei)
    function deposit(uint256 amount)
        external
        override
        nonReentrant
        onlyRole(FUND_OWNER_ROLE)
    {
        require(amount > 0, "CLAIMER: INVALID_AMOUNT");
        totalToken += amount;

        _safeTransferFrom(token, msg.sender, address(this), amount);

        emit Deposit(amount, totalToken);
    }

    /// @notice use by fund owner to withdraw ICO token only and decrease totalToken for sale
    /// @param amount amount to withdraw
    /// @param to target address to withdrawal
    function withdraw(uint256 amount, address to)
        external
        override
        nonReentrant
        onlyRole(FUND_OWNER_ROLE)
    {
        require(amount > 0, "CLAIMER: INVALID_AMOUNT");
        require(
            amount <= totalToken - totalSale,
            "CLAIMER: INSUFFICIENT_TOKEN"
        );

        totalToken -= amount;

        _safeTransfer(token, to, amount);

        emit Withdraw(amount, totalToken, to);
    }

    /// @notice use by fund owner for extract token from unexpected transfer
    /// @param _token target token address
    /// @param amount extraction amount
    /// @param to target address to withdrawal
    function extractToken(
        IERC20 _token,
        uint256 amount,
        address to
    ) external override nonReentrant onlyRole(FUND_OWNER_ROLE) {
        require(amount > 0, "CLAIMER: INVALID_AMOUNT");
        uint256 balance = _token.balanceOf(address(this));

        if (_token == token) {
            // sale token must reduce with reserve token for prevent extract over reserve token
            balance = balance - (totalToken - totalClaimed);
        }
        require(amount <= balance, "CLAIMER: INSUFFICIENT_TOKEN");

        _safeTransfer(_token, to, amount);

        emit ExtractToken(address(_token), amount, to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenLocker {
    struct UserInfo {
        uint256 totalReceiveToken;
        uint256 totalClaimedToken;
        uint256 initialChunkToken;
        uint256 lastClaimChunk;
    }

    event Lock(address indexed receiver, uint256 amount);
    event Deposit(uint256 amount, uint256 totalToken);
    event Withdraw(uint256 amount, uint256 totalToken, address to);
    event Claim(address indexed receiver, uint256 totenToClaim);
    event ExtractToken(address indexed token, uint256 amount, address to);

    function lock(address _receiver, uint256 _totalReceive) external;

    function pendingToken(address _receiver)
        external
        view
        returns (uint256 pending);

    function buyersLength() external view returns (uint256);

    function claim(address _receiver) external;

    function claimMultiple(address[] calldata _receivers) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount, address to) external;

    function extractToken(
        IERC20 _token,
        uint256 amount,
        address to
    ) external;
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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