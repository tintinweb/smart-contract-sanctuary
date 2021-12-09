// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// Summary status derived from a `State` by comparing the `xSince` times
/// against a specific block number.
enum Status {
    // Either no Status has ever been held or it was removed.
    Nil,
    // The account and associated ID has been added, pending verification.
    Added,
    // The associated ID has been reviewed and verified.
    Approved,
    // The associated ID has been reviewed and banned.
    // (even if previously approved)
    Banned
}

/// Records the block a verify session reaches each status.
/// If a status is not reached it is left as UNINITIALIZED, i.e. 0xFFFFFFFF.
/// Most accounts will never be banned so most accounts will never reach every
/// status, which is a good thing.
struct State {
    uint32 addedSince;
    uint32 approvedSince;
    uint32 bannedSince;
}

/// @title Verify
/// Trust-minimised contract to record the state of some verification process.
/// When some off-chain identity is to be reified on chain there is inherently
/// some multi-party, multi-faceted trust relationship. For example, the DID
/// (Decentralized Identifiers) specification from W3C outlines that the
/// controller and the subject of an identity are two different entities.
///
/// This is because self-identification is always problematic to the point of
/// being uselessly unbelievable.
///
/// For example, I can simply say "I am the queen of England" and what
/// onchain mechanism could possibly check, let alone stop me?
/// The same problem exists in any situation where some priviledge or right is
/// associated with identity. Consider passports, driver's licenses,
/// celebrity status, age, health, accredited investor, social media account,
/// etc. etc.
///
/// Typically crypto can't and doesn't want to deal with this issue. The usual
/// scenario is that some system demands personal information, which leads to:
///
/// - Data breaches that put individual's safety at risk. Consider the December
///   2020 leak from Ledger that dumped 270 000 home addresses and phone
///   numbers, and another million emails, of hardware wallet owners on a
///   public forum.
/// - Discriminatory access, undermining an individual's self-sovereign right
///   to run a full node, self-host a GUI and broadcast transactions onchain.
///   Consider the dydx airdrop of 2021 where metadata about a user's access
///   patterns logged on a server were used to deny access to presumed
///   Americans over regulatory fears.
/// - An entrenched supply chain of centralized actors from regulators, to
///   government databases, through KYC corporations, platforms, etc. each of
///   which holds an effective monopoly over, and ability to manipulate user's
///   "own" identity.
///
/// These examples and others are completely antithetical to and undermine the
/// safety of an opt-in, permissionless system based on pseudonomous actors
/// self-signing actions into a shared space.
///
/// That said, one can hardly expect a permissionless pseudonomous system
/// founded on asynchronous value transfers to succeed without at least some
/// concept of curation and reputation.
///
/// Anon, will you invest YOUR money in anon's project?
///
/// Clearly for every defi blue chip there are 10 000 scams and nothing onchain
/// can stop a scam, this MUST happen at the social layer.
///
/// Rain protocol is agnostic to how this verification happens. A government
/// regulator is going to want a government issued ID cross-referenced against
/// international sanctions. A fan of some social media influencer wants to
/// see a verified account on that platform. An open source software project
/// should show a github profile. A security token may need evidence from an
/// accountant showing accredited investor status. There are so many ways in
/// which BOTH sides of a fundraise may need to verify something about
/// themselves to each other via a THIRD PARTY that Rain cannot assume much.
///
/// The trust model and process for Rain verification is:
///
/// - There are many `Verify` contracts, each represents a specific
///   verification method with a (hopefully large) set of possible reviewers.
/// - The verifyee compiles some evidence that can be referenced in some
///   relevant system. It could be a session ID in a KYC provider's database or
///   a tweet from a verified account, etc. The evidence is passed to the
///   `Verify` contract as raw bytes so it is opaque onchain, but visible as an
///   event to verifiers.
/// - The verifyee calls `add` _for themselves_ to initialize their state and
///   emit the evidence for their account, after which they _cannot change_
///   their submission without appealing to someone who can remove. This costs
///   gas, so why don't we simply ask the user to sign something and have an
///   approver verify the signed data? Because we want to leverage both the
///   censorship resistance and asynchronous nature of the underlying
///   blockchain. Assuming there are N possible approvers, we want ANY 1 of
///   those N approvers to be able to review and approve an application. If the
///   user is forced to submit their application directly to one SPECIFIC
///   approver we lose this property. In the gasless model the user must then
///   rely on their specific approver both being online and not to censor the
///   request. It's also possible that many accounts add the same evidence,
///   after all it will be public in the event logs, so it is important for
///   approvers to verify the PAIRING between account and evidence.
/// - ANY account with the `APPROVER` role can review the evidence by
///   inspecting the event logs. IF the evidence is valid then the `approve`
///   function should be called by the approver.
/// - ANY account with the `BANNER` role can veto either an add OR a prior
///   approval. In the case of a false positive, i.e. where an account was
///   mistakenly approved, an appeal can be made to a banner to update the
///   status. Bad accounts SHOULD BE BANNED NOT REMOVED. When an account is
///   removed, its onchain state is once again open for the attacker to
///   resubmit new fraudulent evidence and potentially be reapproved.
///   Once an account is banned, any attempt by the account holder to change
///   their status, or an approver to approve will be rejected. Downstream
///   consumers of a `State` MUST check for an existing ban.
///   - ANY account with the `REMOVER` role can scrub the `State` from an
///   account. Of course, this is a blockchain so the state changes are all
///   still visible to full nodes and indexers in historical data, in both the
///   onchain history and the event logs for each state change. This allows an
///   account to appeal to a remover in the case of a MISTAKEN BAN or also in
///   the case of a MISTAKEN ADD (e.g. mistake in evidence), effecting a
///   "hard reset" at the contract storage level.
///
/// Banning some account with an invalid session is NOT required. It is
/// harmless for an added session to remain as `Status.Added` indefinitely.
/// For as long as no approver decides to approve some invalid added session it
/// MUST be treated as equivalent to a ban by downstream contracts. This is
/// important so that admins are only required to spend gas on useful actions.
///
/// In addition to `Approve`, `Ban`, `Remove` there are corresponding events
/// `RequestApprove`, `RequestBan`, `RequestRemove` that allow for admins to be
/// notified that some new evidence must be considered that may lead to each
/// action. `RequestApprove` is automatically submitted as part of the `add`
/// call, but `RequestBan` and `RequestRemove` must be manually called
///
/// Rain uses standard Open Zeppelin `AccessControl` and is agnostic to how the
/// approver/remover/banner roles and associated admin roles are managed.
/// Ideally the more credibly neutral qualified parties assigend to each role
/// for each `Verify` contract the better. This improves the censorship
/// resistance of the verification process and the responsiveness of the
/// end-user experience.
///
/// Ideally the admin account assigned at deployment would renounce their admin
/// rights after establishing a more granular and appropriate set of accounts
/// with each specific role.
contract Verify is AccessControl {

    /// Any state never held is UNINITIALIZED.
    /// Note that as per default evm an unset state is 0 so always check the
    /// `addedSince` block on a `State` before trusting an equality check on
    /// any other block number.
    /// (i.e. removed or never added)
    uint32 constant public UNINITIALIZED = 0xFFFFFFFF;

    /// Emitted when evidence is first submitted to approve an account.
    /// The requestor is always the `msg.sender` of the user calling `add`.
    /// @param account The address that submitted its own evidence.
    /// @param data The evidence to support an approval.
    /// NOT written to contract storage.
    event RequestApprove(
        address indexed account,
        bytes data
    );
    /// Emitted when a previously added account is approved.
    /// @param approver The address that approved `account`.
    /// @param account The address that was approved.
    /// @param data Any additional data the `approver` deems relevant.
    /// NOT written to contract storage.
    event Approve(
        address indexed approver,
        address indexed account,
        bytes data
    );

    /// Currently approved accounts can request that any account be banned.
    /// The requestor is expected to provide supporting data for the ban.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param requestor The address requesting a ban of `account`.
    /// @param account The address that `requestor` wants to ban.
    /// @param data Any additional data the `requestor` feels will strengthen
    /// its case for the ban. NOT written to contract storage.
    event RequestBan(
        address indexed requestor,
        address indexed account,
        bytes data
    );
    /// Emitted when an added or approved account is banned.
    /// @param banner The address that banned `account`.
    /// @param account The address that `banner` has banned.
    /// @param data The evidence to support a ban.
    /// NOT written to contract storage.
    event Ban(
        address indexed banner,
        address indexed account,
        bytes data
    );

    /// Currently approved accounts can request that any account be removed.
    /// The requestor is expected to provide supporting data for the removal.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param requestor The address requesting a removal of `account`.
    /// @param account The address that `requestor` wants to ban.
    /// @param data Any additional data the `requestor` feels will strengthen
    /// its case for the ban. NOT written to contract storage.
    event RequestRemove(
        address indexed requestor,
        address indexed account,
        bytes data
    );
    /// Emitted when an account is scrubbed from blockchain state.
    /// @param remover The address that removed `account`.
    /// @param account The address that `remover` has removed.
    /// @param data The evidence to support a remove.
    /// NOT written to contract storage.
    event Remove(
        address indexed remover,
        address indexed account,
        bytes data
    );

    /// Admin role for `APPROVER`.
    bytes32 public constant APPROVER_ADMIN = keccak256("APPROVER_ADMIN");
    /// Role for `APPROVER`.
    bytes32 public constant APPROVER = keccak256("APPROVER");

    /// Admin role for `REMOVER`.
    bytes32 public constant REMOVER_ADMIN = keccak256("REMOVER_ADMIN");
    /// Role for `REMOVER`.
    bytes32 public constant REMOVER = keccak256("REMOVER");

    /// Admin role for `BANNER`.
    bytes32 public constant BANNER_ADMIN = keccak256("BANNER_ADMIN");
    /// Role for `BANNER`.
    bytes32 public constant BANNER = keccak256("BANNER");

    // Account => State
    mapping (address => State) public states;

    /// Defines RBAC logic for each role under Open Zeppelin.
    /// @param admin_ The address to ASSIGN ALL ADMIN ROLES to initially. This
    /// address is free and encouraged to delegate fine grained permissions to
    /// many other sub-admin addresses, then revoke it's own "root" access.
    constructor (address admin_) {
        // `APPROVER_ADMIN` can admin each other in addition to
        // `APPROVER` addresses underneath.
        _setRoleAdmin(APPROVER_ADMIN, APPROVER_ADMIN);
        _setRoleAdmin(APPROVER, APPROVER_ADMIN);

        // `REMOVER_ADMIN` can admin each other in addition to
        // `REMOVER` addresses underneath.
        _setRoleAdmin(REMOVER_ADMIN, REMOVER_ADMIN);
        _setRoleAdmin(REMOVER, REMOVER_ADMIN);

        // `BANNER_ADMIN` can admin each other in addition to
        // `BANNER` addresses underneath.
        _setRoleAdmin(BANNER_ADMIN, BANNER_ADMIN);
        _setRoleAdmin(BANNER, BANNER_ADMIN);

        // It is STRONGLY RECOMMENDED that the `admin_` delegates specific
        // admin roles then revokes the `DEFAULT_ADMIN_ROLE` and the `X_ADMIN`
        // roles.
        _setupRole(APPROVER_ADMIN, admin_);
        _setupRole(REMOVER_ADMIN, admin_);
        _setupRole(BANNER_ADMIN, admin_);

        // This is at the end of the constructor because putting it at the
        // start seems to break the source map from the compiler 
        require(admin_ != address(0), "0_ACCOUNT");
    }

    /// Typed accessor into states.
    /// @param account_ The account to return the current `State` for.
    function state(address account_) external view returns (State memory) {
        return states[account_];
    }

    /// Derives a single `Status` from a `State` and a reference block number.
    /// @param state_ The raw `State` to reduce into a `Status`.
    /// @param blockNumber_ The block number to compare `State` against.
    function statusAtBlock(State memory state_, uint32 blockNumber_)
        public
        pure
        returns (Status)
    {
        // The state hasn't even been added so is picking up block zero as the
        // evm fallback value. In this case if we checked other blocks using
        // a `<=` equality they would incorrectly return `true` always due to
        // also having a `0` fallback value.
        // Using `< 1` here to silence slither.
        if (state_.addedSince < 1) {
            return Status.Nil;
        }
        // Banned takes priority over everything.
        else if (state_.bannedSince <= blockNumber_) {
            return Status.Banned;
        }
        // Approved takes priority over added.
        else if (state_.approvedSince <= blockNumber_) {
            return Status.Approved;
        }
        // Added is lowest priority.
        else if (state_.addedSince <= blockNumber_) {
            return Status.Added;
        }
        // The `addedSince` block is after `blockNumber_` so `Status` is nil
        // relative to `blockNumber_`.
        else {
            return Status.Nil;
        }
    }

    /// Requires that `msg.sender` is approved as at the current block.
    modifier onlyApproved {
        require(
            statusAtBlock(states[msg.sender], uint32(block.number))
                == Status.Approved,
            "ONLY_APPROVED"
        );
        _;
    }

    /// An account adds their own verification evidence.
    /// Internally `msg.sender` is used; delegated `add` is not supported.
    /// @param data_ The evidence to support approving the `msg.sender`.
    function add(bytes calldata data_) external {
        // Accounts may NOT change their application to be approved.
        // This restriction is the main reason delegated add is not supported
        // as it would lead to griefing.
        // A mistaken add requires an appeal to a REMOVER to restart the
        // process OR a new `msg.sender` (i.e. different wallet address).
        // The awkward < 1 here is to silence slither complaining about
        // equality checks against `0`. The intent is to ensure that
        // `addedSince` is not already set before we set it.
        require(states[msg.sender].addedSince < 1, "PRIOR_ADD");
        states[msg.sender] = State(
            uint32(block.number),
            UNINITIALIZED,
            UNINITIALIZED
        );
        emit RequestApprove(msg.sender, data_);
    }

    /// An `APPROVER` can review added evidence and approve the account.
    /// @param account_ The account to be approved.
    /// @param data_ Additional evidence provided by the approver.
    function approve(address account_, bytes calldata data_) external {
        require(account_ != address(0), "0_ADDRESS");
        require(hasRole(APPROVER, msg.sender), "ONLY_APPROVER");
        // In theory we should also check the `addedSince` is lte the current
        // `block.number` but in practise no code path produces a future
        // `addedSince`.
        require(states[account_].addedSince > 0, "NOT_ADDED");
        require(
            states[account_].approvedSince == UNINITIALIZED,
            "PRIOR_APPROVE"
        );
        require(
            states[account_].bannedSince == UNINITIALIZED,
            "PRIOR_BAN"
        );
        states[account_].approvedSince = uint32(block.number);
        emit Approve(
            msg.sender,
            account_,
            data_
        );
    }

    /// Any approved account can request some account be banned, along with
    /// supporting evidence. Banners are free to ban the originator of
    /// vexatious ban requests.
    /// @param account_ The account to be banned.
    /// @param data_ The supporting evidence.
    function requestBan(address account_, bytes calldata data_)
        external
        onlyApproved
    {
        emit RequestBan(msg.sender, account_, data_);
    }

    /// A `BANNER` can ban an added OR approved account.
    /// @param account_ The account to be banned.
    /// @param data_ Additional evidence provided by the banner.
    function ban(address account_, bytes calldata data_) external {
        require(account_ != address(0), "0_ADDRESS");
        require(hasRole(BANNER, msg.sender), "ONLY_BANNER");
        // In theory we should also check the `addedSince` is lte the current
        // `block.number` but in practise no code path produces a future
        // `addedSince`.
        require(states[account_].addedSince > 0, "NOT_ADDED");
        require(
            states[account_].bannedSince == UNINITIALIZED,
            "PRIOR_BAN"
        );
        states[account_].bannedSince = uint32(block.number);
        emit Ban(
            msg.sender,
            account_,
            data_
        );
    }

    /// Any approved account can request some account be removed, along with
    /// supporting evidence.
    /// @param account_ The account to be removed.
    /// @param data_ The supporting evidence.
    function requestRemove(address account_, bytes calldata data_)
        external
        onlyApproved
    {
        emit RequestRemove(msg.sender, account_, data_);
    }

    /// A `REMOVER` can scrub state mapping from an account.
    /// A malicious account MUST be banned rather than removed.
    /// Removal is useful to reset the whole process in case of some mistake.
    /// @param account_ The account to be removed.
    /// @param data_ Additional evidence provided by the remover.
    function remove(address account_, bytes calldata data_) external {
        require(account_ != address(0), "0_ADDRESS");
        require(hasRole(REMOVER, msg.sender), "ONLY_REMOVER");
        delete(states[account_]);
        emit Remove(
            msg.sender,
            account_,
            data_
        );
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