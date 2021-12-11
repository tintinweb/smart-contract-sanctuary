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
    constructor() {
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

// SPDX-License-Identifier: GPL-3.0
// TBILL Universal Oracle
// Based on ChainBridge voting.

pragma solidity 0.8.10; 

import "openzeppelin43/access/AccessControl.sol";
import "openzeppelin43/security/Pausable.sol";

/**
 * @title TBILL Universal Oracle
 * @notice Oracles vote on proposals using keccack256 data hash. 
 * @notice After vote threshold is met, execute should be called with the full data 
 * @notice within the expiration period to fire the onExecute function
 * @notice with the data less the proposalNumber header.
 */
abstract contract TOracle is Pausable, AccessControl {
    enum Vote {No, Yes}
    enum ProposalStatus {Inactive, Active, Passed, Executed, Cancelled}
    struct Proposal {
        ProposalStatus _status;
        bytes32 _dataHash;
        address[] _yesVotes;
        uint256 _proposedBlock;
    }


    event VoteThresholdChanged(uint256 indexed newThreshold);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event ProposalEvent(
        uint32 indexed proposalNumber,
        ProposalStatus indexed status,
        bytes32 dataHash
    );
    event ProposalVote(
        uint32 indexed proposalNumber,
        ProposalStatus indexed status
    );


    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    uint256 public _voteThreshold; //number of votes required to pass a proposal
    uint256 public _expiry; //blocks after which to expire proposals
    uint256 public _totalOracles; //number of oracles
    uint256 public _executedCount;

    // proposalNumber => dataHash => Proposal, where proposalNumber is executedCount+1
    mapping(uint32 => mapping(bytes32 => Proposal)) public _proposals;
    // proposalNumber => dataHash => oracleAddress => bool, where proposalNumber is executedCount+1
    mapping(uint32 => mapping(bytes32 => mapping(address => bool))) public _hasVotedOnProposal;

    uint256[50] private ______gap; //leave space for upgrades;


    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }
    modifier onlyAdminOrOracle() {
        _onlyAdminOrOracle();
        _;
    }
    modifier onlyOracles() {
        _onlyOracles();
        _;
    }
    modifier onlySelf(){
        _onlySelf();
        _;
    }

    function _onlyAdminOrOracle() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(ORACLE_ROLE, msg.sender),
            "sender is not oracle or admin"
        );
    }
    function _onlyAdmin() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender doesn't have admin role");
    }
    function _onlyOracles() private view {
        require(hasRole(ORACLE_ROLE, msg.sender), "sender doesn't have oracle role");
    }
    function _onlySelf() private view {
        require(msg.sender == address(this), "Only self can call");
    }

    /**
        @notice Initializes oracle, creates and grants admin role, creates and grants oracle role.
        @param initialVoteThreshold Number of votes required to pass proposal.
        @param expiry Number of blocks after which an unexecuted proposal is cancelled.
        @param initialOracles Addresses that should be allowed to vote on proposals.
     */
    constructor(
        uint256 initialVoteThreshold,
        uint256 expiry,
        address[] memory initialOracles        
    ){
        _voteThreshold = initialVoteThreshold;
        _expiry = expiry;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        for (uint256 i; i < initialOracles.length; i++){
            grantRole(ORACLE_ROLE, initialOracles[i]);
        }
        _totalOracles = initialOracles.length;
    }

    /**
        @notice Returns true if {checkAddress} has the oracle role.
        @param checkAddress Address to check.
     */
    function isOracle(address checkAddress) external view returns (bool) {
        return hasRole(ORACLE_ROLE, checkAddress);
    }

    /**
        @notice Removes admin role from {msg.sender} and grants it to {newAdmin}.
        @notice Only callable by an address that currently has the admin role.
        @param newAdmin Address that admin role will be granted to.
     */
    function renounceAdmin(address newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @notice Pauses executions, proposal creation and voting.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminPause() external onlyAdmin {
        _pause();
    }

    /**
        @notice Unpauses executions, proposal creation and voting.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminUnpause() external onlyAdmin {
        _unpause();
    }

    /**
        @notice Modifies the number of votes required for a proposal to be considered passed.
        @notice Only callable by an address that currently has the admin role.
        @param newThreshold Value {_voteThreshold} will be changed to.
        @notice Emits {VoteThresholdChanged} event.
     */
    function adminChangeVoteThreshold(uint256 newThreshold) external onlyAdmin {
        _voteThreshold = newThreshold;
        emit VoteThresholdChanged(newThreshold);
    }

    /**
        @notice Grants {oracleAddress} the oracle role and increases {_totalOracles} count.
        @notice Only callable by an address that currently has the admin role.
        @param oracleAddress Address of oracle to be added.
        @notice Emits {OracleAdded} event.
     */
    function adminAddOracle(address oracleAddress) external onlyAdmin {
        require(!hasRole(ORACLE_ROLE, oracleAddress), "addr already has oracle role!");
        grantRole(ORACLE_ROLE, oracleAddress);
        emit OracleAdded(oracleAddress);
        _totalOracles++;
    }

    /**
        @notice Removes oracle role for {oracleAddress} and decreases {_totalOracles} count.
        @notice Only callable by an address that currently has the admin role.
        @param oracleAddress Address of oracle to be removed.
        @notice Emits {OracleRemoved} event.
     */
    function adminRemoveOracle(address oracleAddress) external onlyAdmin {
        require(hasRole(ORACLE_ROLE, oracleAddress), "addr doesn't have oracle role!");
        revokeRole(ORACLE_ROLE, oracleAddress);
        emit OracleRemoved(oracleAddress);
        _totalOracles--;
    }
    
    /**
        @notice Returns a proposal.
        @param proposalNumber The number of proposals that will have been completed if this proposal is executed (_executedCount+1).
        @param dataHash Hash of data that will be provided when proposal is sent for execution.
        @return Proposal which consists of:
        - _dataHash Hash of data to be provided when deposit proposal is executed.
        - _yesVotes Number of votes in favor of proposal.
        - _proposedBlock
        - _status Current status of proposal.
     */
    function getProposal(
        uint32 proposalNumber,
        bytes32 dataHash
    ) external view returns (Proposal memory) {
        return _proposals[proposalNumber][dataHash];
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by oracles when is not paused.
        @param proposalNumber The number of proposals that will have been completed if this proposal is executed (_executedCount+1).
        @param dataHash Hash of encodePacked data that will be provided when proposal is sent for execution.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(uint32 proposalNumber, bytes32 dataHash) external onlyOracles whenNotPaused {
        Proposal storage proposal = _proposals[proposalNumber][dataHash];

        //proposal already passed/executed/cancelled
        if (proposal._status > ProposalStatus.Active) return;
        
        require(!_hasVotedOnProposal[proposalNumber][dataHash][msg.sender], "oracle already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            _proposals[proposalNumber][dataHash] = Proposal({
                _dataHash: dataHash,
                _yesVotes: new address[](1),
                _status: ProposalStatus.Active,
                _proposedBlock: block.number
            });
            proposal._yesVotes[0] = msg.sender;
            emit ProposalEvent(proposalNumber, ProposalStatus.Active, dataHash);
        } else {
            if (block.number - proposal._proposedBlock > _expiry) {
                // if the number of blocks that has passed since this proposal was
                // submitted exceeds the expiry threshold set, cancel the proposal
                proposal._status = ProposalStatus.Cancelled;
                emit ProposalEvent(
                    proposalNumber,
                    ProposalStatus.Cancelled,
                    dataHash
                );
            } else {
                require(dataHash == proposal._dataHash, "datahash mismatch");
                proposal._yesVotes.push(msg.sender);
            }
        }
        if (proposal._status != ProposalStatus.Cancelled) {
            _hasVotedOnProposal[proposalNumber][dataHash][msg.sender] = true;
            emit ProposalVote(proposalNumber, proposal._status);

            // If _depositThreshold is set to 1, then auto finalize
            // or if _relayerThreshold has been exceeded
            if (_voteThreshold <= 1 || proposal._yesVotes.length >= _voteThreshold) {
                proposal._status = ProposalStatus.Passed;
                emit ProposalEvent(
                    proposalNumber,
                    ProposalStatus.Passed,
                    dataHash
                );
            }
        }
    }

    /**
        @notice Cancels an expired proposal that has not yet been marked as cancelled.
        @notice Only callable by oracles or admin.
        @param proposalNumber The number of proposal executions that would have been completed if this proposal had been executed (_executedCount+1).
        @param dataHash Hash of encodePacked data originally provided when proposal was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(
        uint32 proposalNumber,
        bytes32 dataHash
    ) public onlyAdminOrOracle {
        Proposal storage proposal = _proposals[proposalNumber][dataHash];

        require(proposal._status != ProposalStatus.Cancelled, "Proposal already cancelled");
        require(
            block.number - proposal._proposedBlock > _expiry,
            "Proposal not at expiry threshold"
        );

        proposal._status = ProposalStatus.Cancelled;
        emit ProposalEvent(
            proposalNumber,
            ProposalStatus.Cancelled,
            proposal._dataHash
        );
    }

    /**
        @notice Executes a proposal that is considered passed.
        @notice Only callable by oracles when not paused.
        @param proposalNumber The number of proposal executions that will have been completed when this proposal is executed (_executedCount+1).
        @param data abi-encode-packed resourceID, proposalNumber, and data to pass on to handler specified by resourceID lookup.
        @notice Proposal must have "Passed" status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(
        uint32 proposalNumber,
        bytes calldata data
    ) external onlyOracles whenNotPaused {
        bytes32 dataHash = keccak256(data);
        Proposal storage proposal = _proposals[proposalNumber][dataHash];

        require(proposal._status != ProposalStatus.Inactive, "proposal is not active");
        require(proposal._status == ProposalStatus.Passed, "proposal already executed, cancelled, or not yet passed");
        require(dataHash == proposal._dataHash, "data doesn't match datahash");

        require(proposalNumber == uint32(bytes4(data[:4])), "proposalNumber<>data mismatch");

        proposal._status = ProposalStatus.Executed;
        ++_executedCount;
        onExecute(data[4:]);

        emit ProposalEvent(
            proposalNumber,
            ProposalStatus.Executed,
            dataHash
        );
    }

    function onExecute(bytes calldata data) internal virtual;
    
    /**
        @notice Transfers native currency in the contract to the specified addresses. The parameters addrs and amounts are mapped 1:1.
        This means that the address at index 0 for addrs will receive the amount (in WEI/ticks) from amounts at index 0.
        @param addrs Array of addresses to transfer {amounts} to.
        @param amounts Array of amonuts to transfer to {addrs}.
     */
    function transferFunds(address payable[] calldata addrs, uint256[] calldata amounts)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addrs[i].transfer(amounts[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10; 

import "./TOracle.sol";

interface IOracle {
    function getData() external view returns (uint256, bool);
}

/**
 * @title TBILL Price Oracle
 */
contract TBillPriceOracle is TOracle, IOracle {
    event UpdatedAvgPrice(
        uint256 price,
        bool valid
    );
    
    uint256 private constant VALIDITY_MASK = 2**(256-1);
    uint256 private constant PRICE_MASK = VALIDITY_MASK-1;
    uint8 public constant decimals = 18;

    uint256 private _tbillAvgPriceAndValidity; //1 bit validity then 255 bit price; updated ONLY daily. for more up-to-date info, view PriceRecords

    constructor(
        uint256 initialTbillPrice, 
        uint256 initialVoteThreshold, uint256 expiry, address[] memory initialOracles
    )
    TOracle(initialVoteThreshold, expiry, initialOracles)
    {
        _tbillAvgPriceAndValidity = initialTbillPrice;        
    }    

    function getData() external view returns (uint256 price, bool valid) {
        price = _tbillAvgPriceAndValidity & PRICE_MASK;
        valid = _tbillAvgPriceAndValidity & VALIDITY_MASK > 0;
    }
    function getTBillLastPrice() external view returns (uint256 price) {
        price = _tbillAvgPriceAndValidity & PRICE_MASK;
    }
    function getTBillLastPriceValid() external view returns (bool valid) {
        valid = _tbillAvgPriceAndValidity & VALIDITY_MASK > 0;
    }

    /**
        @notice should only be called by executeProposal, which has already verified the dataHash.
     */
    function onExecute(bytes calldata data) internal override {
        uint256 tbillAvgPriceAndValidity = uint256(bytes32(data[:32]));
        uint256 price = tbillAvgPriceAndValidity & PRICE_MASK;
        bool valid = tbillAvgPriceAndValidity & VALIDITY_MASK > 0;
        _tbillAvgPriceAndValidity = tbillAvgPriceAndValidity;
        emit UpdatedAvgPrice(price, valid);
    }    
}