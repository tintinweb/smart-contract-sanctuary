/**
 *Submitted for verification at arbiscan.io on 2021-12-08
*/

// Sources flattened with hardhat v2.6.3 https://hardhat.org

// File contracts/lib/Structs.sol

pragma solidity ^0.8.0;

library Structs {
    struct Vote {
        uint32 epoch;
        uint48[] values;
    }

    struct Commitment {
        uint32 epoch;
        bytes32 commitmentHash;
    }
    struct Staker {
        bool acceptDelegation;
        uint8 commission;
        address _address;
        address tokenAddress;
        uint32 id;
        uint32 age;
        uint32 epochFirstStakedOrLastPenalized;
        uint256 stake;
    }

    struct Lock {
        uint256 amount; //amount in RZR
        uint256 commission;
        uint256 withdrawAfter;
    }

    struct BountyLock {
        address bountyHunter;
        uint256 amount; //amount in RZR
        uint256 redeemAfter;
    }

    struct Block {
        uint32 proposerId;
        uint32[] medians;
        uint256 iteration;
        uint256 biggestInfluence;
        bool valid;
    }

    struct Dispute {
        uint8 assetId;
        uint32 lastVisitedStaker;
        uint256 accWeight;
        uint256 accProd;
        // uint32 median;
    }

    struct Job {
        uint8 id;
        uint8 selectorType; // 0-1
        uint8 weight; // 1-100
        int8 power;
        string name;
        string selector;
        string url;
    }

    struct Collection {
        bool active;
        uint8 id;
        uint8 assetIndex;
        int8 power;
        uint32 aggregationMethod;
        uint8[] jobIDs;
        string name;
    }
}


// File contracts/Core/storage/Constants.sol

pragma solidity ^0.8.0;

contract Constants {
    enum State {
        Commit,
        Reveal,
        Propose,
        Dispute,
        Confirm
    }

    enum StakeChanged {
        BlockReward,
        InactivityPenalty,
        Slashed
    }

    uint8 public constant NUM_STATES = 5;

    // keccak256("BLOCK_CONFIRMER_ROLE")
    bytes32 public constant BLOCK_CONFIRMER_ROLE = 0x18797bc7973e1dadee1895be2f1003818e30eae3b0e7a01eb9b2e66f3ea2771f;

    // keccak256("ASSET_CONFIRMER_ROLE")
    bytes32 public constant ASSET_CONFIRMER_ROLE = 0xed202a1bc048f9b31cb3937bc52e7c8fe76413f0674b9146ff4bcc15612ccbc2;

    // keccak256("STAKER_ACTIVITY_UPDATER_ROLE")
    bytes32 public constant STAKER_ACTIVITY_UPDATER_ROLE = 0x4cd3070aaa07d03ab33731cbabd0cb27eb9e074a9430ad006c96941d71b77ece;

    // keccak256("STAKE_MODIFIER_ROLE")
    bytes32 public constant STAKE_MODIFIER_ROLE = 0xdbaaaff2c3744aa215ebd99971829e1c1b728703a0bf252f96685d29011fc804;

    // keccak256("REWARD_MODIFIER_ROLE")
    bytes32 public constant REWARD_MODIFIER_ROLE = 0xcabcaf259dd9a27f23bd8a92bacd65983c2ebf027c853f89f941715905271a8d;

    // keccak256("ASSET_MODIFIER_ROLE")
    bytes32 public constant ASSET_MODIFIER_ROLE = 0xca0fffcc0404933256f3ec63d47233fbb05be25fc0eacc2cfb1a2853993fbbe4;

    // keccak256("VOTE_MODIFIER_ROLE")
    bytes32 public constant VOTE_MODIFIER_ROLE = 0xca0fffcc0404933256f3ec63d47233fbb05be25fc0eacc2cfb1a2853993fbbe5;

    // keccak256("DELEGATOR_MODIFIER_ROLE")
    bytes32 public constant DELEGATOR_MODIFIER_ROLE = 0x6b7da7a33355c6e035439beb2ac6a052f1558db73f08690b1c9ef5a4e8389597;
    // keccak256("SECRETS_MODIFIER_ROLE")
    bytes32 public constant SECRETS_MODIFIER_ROLE = 0x46aaf8a125792dfff6db03d74f94fe1acaf55c8cab22f65297c15809c364465c;

    address public constant BURN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}


// File contracts/Core/interface/IStakeManager.sol

pragma solidity ^0.8.0;


interface IStakeManager {
    function setStakerStake(
        uint32 _epoch,
        uint32 _id,
        Constants.StakeChanged reason,
        uint256 _stake
    ) external;

    function slash(
        uint32 epoch,
        uint32 stakerId,
        address bountyHunter
    ) external returns (uint32);

    function setStakerAge(
        uint32 _epoch,
        uint32 _id,
        uint32 _age
    ) external;

    function setStakerEpochFirstStakedOrLastPenalized(uint32 _epoch, uint32 _id) external;

    function escape(address _address) external;

    function getStakerId(address _address) external view returns (uint32);

    function getStaker(uint32 _id) external view returns (Structs.Staker memory staker);

    function getNumStakers() external view returns (uint32);

    function getInfluence(uint32 stakerId) external view returns (uint256);

    function getStake(uint32 stakerId) external view returns (uint256);

    function getEpochFirstStakedOrLastPenalized(uint32 stakerId) external view returns (uint32);
}


// File contracts/Core/interface/IRewardManager.sol

pragma solidity ^0.8.0;

interface IRewardManager {
    function givePenalties(uint32 epoch, uint32 stakerId) external;

    function giveBlockReward(uint32 epoch, uint32 stakerId) external;

    function giveInactivityPenalties(uint32 epoch, uint32 stakerId) external;
}


// File contracts/Core/interface/IVoteManager.sol

pragma solidity ^0.8.0;

interface IVoteManager {
    function getVoteValue(uint8 assetId, uint32 stakerId) external view returns (uint48);

    function getVote(uint32 stakerId) external view returns (Structs.Vote memory vote);

    function getInfluenceSnapshot(uint32 epoch, uint32 stakerId) external view returns (uint256);

    function getTotalInfluenceRevealed(uint32 epoch) external view returns (uint256);

    function getEpochLastRevealed(uint32 stakerId) external view returns (uint32);

    function getEpochLastCommitted(uint32 stakerId) external view returns (uint32);

    function getRandaoHash() external view returns (bytes32);
}


// File contracts/tokenization/IStakedTokenFactory.sol

pragma solidity ^0.8.0;

interface IStakedTokenFactory {
    function createStakedToken(address stakeManagerAddress, uint32 stakedID) external returns (address);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/tokenization/IStakedToken.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IStakedToken is IERC20 {
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(
        address account,
        uint256 amount,
        uint256 razorDeposited
    ) external returns (bool);

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
    function burn(address account, uint256 amount) external returns (bool);

    function getRZRDeposited(address delegator, uint256 sAmount) external view returns (uint256);
}


// File contracts/Core/storage/StakeStorage.sol

pragma solidity ^0.8.0;

contract StakeStorage {
    // slither-disable-next-line constable-states
    uint32 public numStakers;
    // slither-disable-next-line constable-states
    uint32 public bountyCounter;

    mapping(address => uint32) public stakerIds;
    mapping(uint32 => Structs.Staker) public stakers;
    mapping(address => mapping(address => Structs.Lock)) public locks;
    mapping(uint32 => Structs.BountyLock) public bountyLocks;
    //[math.floor(math.sqrt(i*10000)/2) for i in range(1,100)]
    uint16[] public maturities = [
        50,
        70,
        86,
        100,
        111,
        122,
        132,
        141,
        150,
        158,
        165,
        173,
        180,
        187,
        193,
        200,
        206,
        212,
        217,
        223,
        229,
        234,
        239,
        244,
        250,
        254,
        259,
        264,
        269,
        273,
        278,
        282,
        287,
        291,
        295,
        300,
        304,
        308,
        312,
        316,
        320,
        324,
        327,
        331,
        335,
        339,
        342,
        346,
        350,
        353,
        357,
        360,
        364,
        367,
        370,
        374,
        377,
        380,
        384,
        387,
        390,
        393,
        396,
        400,
        403,
        406,
        409,
        412,
        415,
        418,
        421,
        424,
        427,
        430,
        433,
        435,
        438,
        441,
        444,
        447,
        450,
        452,
        455,
        458,
        460,
        463,
        466,
        469,
        471,
        474,
        476,
        479,
        482,
        484,
        487,
        489,
        492,
        494,
        497,
        500,
        502
    ];
}


// File contracts/Core/parameters/interfaces/IStakeManagerParams.sol

pragma solidity ^0.8.0;

interface IStakeManagerParams {
    function setEpochLength(uint16 _epochLength) external;

    function setSlashParams(
        uint16 _bounty,
        uint16 _burn,
        uint16 _keep
    ) external;

    function setBaseDenominator(uint16 _baseDenominator) external;

    function setWithdrawLockPeriod(uint8 _withdrawLockPeriod) external;

    function setWithdrawReleasePeriod(uint8 _withdrawReleasePeriod) external;

    function setExtendLockPenalty(uint8 _extendLockPenalty) external;

    function setMinStake(uint256 _minStake) external;

    function setGracePeriod(uint16 _gracePeriod) external;

    function setMaxCommission(uint8 _maxCommission) external;

    function disableEscapeHatch() external;

    function baseDenominator() external view returns (uint16);
}


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;




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


// File contracts/Core/parameters/ACL.sol

pragma solidity ^0.8.0;

contract ACL is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}


// File contracts/Core/parameters/child/StakeManagerParams.sol

pragma solidity ^0.8.0;


abstract contract StakeManagerParams is ACL, IStakeManagerParams {
    struct SlashNums {
        uint16 bounty;
        uint16 burn;
        uint16 keep;
    }
    uint8 public withdrawLockPeriod = 1;
    uint8 public withdrawReleasePeriod = 5;
    uint8 public extendLockPenalty = 1;
    uint8 public maxCommission = 20;
    SlashNums public slashNums = SlashNums(500, 9500, 0);
    // Slash Penalty = bounty + burned + kept
    uint16 public override baseDenominator = 10000;
    uint16 public gracePeriod = 8;
    uint16 public epochLength = 300;
    bool public escapeHatchEnabled = true;
    uint256 public minStake = 1000 * (10**18);
    bytes32 public constant GOVERNANCE_ROLE = 0x71840dc4906352362b0cdaf79870196c8e42acafade72d5d5a6d59291253ceb1;

    function setEpochLength(uint16 _epochLength) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        epochLength = _epochLength;
    }

    function setSlashParams(
        uint16 _bounty,
        uint16 _burn,
        uint16 _keep
    ) external override onlyRole(GOVERNANCE_ROLE) {
        require(_bounty + _burn + _keep <= baseDenominator, "Slash nums addtion exceeds 10000");
        // slither-disable-next-line events-maths
        slashNums = SlashNums(_bounty, _burn, _keep);
    }

    function setBaseDenominator(uint16 _baseDenominator) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        baseDenominator = _baseDenominator;
    }

    function setWithdrawLockPeriod(uint8 _withdrawLockPeriod) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        withdrawLockPeriod = _withdrawLockPeriod;
    }

    function setWithdrawReleasePeriod(uint8 _withdrawReleasePeriod) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        withdrawReleasePeriod = _withdrawReleasePeriod;
    }

    function setExtendLockPenalty(uint8 _extendLockPenalty) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        extendLockPenalty = _extendLockPenalty;
    }

    function setMinStake(uint256 _minStake) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        minStake = _minStake;
    }

    function setGracePeriod(uint16 _gracePeriod) external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        gracePeriod = _gracePeriod;
    }

    function setMaxCommission(uint8 _maxCommission) external override onlyRole(GOVERNANCE_ROLE) {
        require(_maxCommission <= 100, "Invalid Max Commission Update");
        // slither-disable-next-line events-maths
        maxCommission = _maxCommission;
    }

    function disableEscapeHatch() external override onlyRole(GOVERNANCE_ROLE) {
        // slither-disable-next-line events-maths
        escapeHatchEnabled = false;
    }
}


// File contracts/Initializable.sol


// solhint-disable-next-line compiler-version
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
 *
 * Forked from OZ's (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b9125001f0a1c44d596ca3a47536f1a467e3a29d/contracts/proxy/utils/Initializable.sol)
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

    modifier initialized() {
        require(_initialized, "Contract should be initialized");
        _;
    }
}


// File contracts/Core/StateManager.sol

pragma solidity ^0.8.0;

contract StateManager is Constants {
    modifier checkEpoch(uint32 epoch, uint32 epochLength) {
        // slither-disable-next-line incorrect-equality
        require(epoch == getEpoch(epochLength), "incorrect epoch");
        _;
    }

    modifier checkState(State state, uint32 epochLength) {
        // slither-disable-next-line incorrect-equality
        require(state == getState(epochLength), "incorrect state");
        _;
    }

    modifier notState(State state, uint32 epochLength) {
        // slither-disable-next-line incorrect-equality
        require(state != getState(epochLength), "incorrect state");
        _;
    }

    modifier checkEpochAndState(
        State state,
        uint32 epoch,
        uint32 epochLength
    ) {
        // slither-disable-next-line incorrect-equality
        require(epoch == getEpoch(epochLength), "incorrect epoch");
        // slither-disable-next-line incorrect-equality
        require(state == getState(epochLength), "incorrect state");
        _;
    }

    function getEpoch(uint32 epochLength) public view returns (uint32) {
        return (uint32(block.number) / (epochLength));
    }

    function getState(uint32 epochLength) public view returns (State) {
        uint8 state = uint8(((block.number) / (epochLength / NUM_STATES)) % (NUM_STATES));
        return State(state);
    }
}


// File @openzeppelin/contracts/security/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/Pause.sol

pragma solidity ^0.8.0;


contract Pause is Pausable, ACL {
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Pausable._pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Pausable._unpause();
    }
}


// File contracts/Core/StakeManager.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;











/// @title StakeManager
/// @notice StakeManager handles stake, unstake, withdraw, reward, functions
/// for stakers

contract StakeManager is Initializable, StakeStorage, StateManager, Pause, StakeManagerParams, IStakeManager {
    IRewardManager public rewardManager;
    IVoteManager public voteManager;
    IERC20 public razor;
    IStakedTokenFactory public stakedTokenFactory;

    event StakeChange(uint32 epoch, uint32 indexed stakerId, Constants.StakeChanged reason, uint256 newStake, uint256 timestamp);

    event AgeChange(uint32 epoch, uint32 indexed stakerId, uint32 newAge, uint256 timestamp);

    event Staked(
        address staker,
        address sToken,
        uint32 epoch,
        uint32 indexed stakerId,
        uint256 newStake,
        uint256 totalSupply,
        uint256 timestamp
    );

    event Unstaked(
        address staker,
        uint32 epoch,
        uint32 indexed stakerId,
        uint256 amount,
        uint256 newStake,
        uint256 totalSupply,
        uint256 timestamp
    );

    event Withdrew(address staker, uint32 epoch, uint32 indexed stakerId, uint256 amount, uint256 newStake, uint256 timestamp);

    event Delegated(
        address delegator,
        uint32 epoch,
        uint32 indexed stakerId,
        uint256 amount,
        uint256 newStake,
        uint256 totalSupply,
        uint256 timestamp
    );

    event DelegationAcceptanceChanged(bool delegationEnabled, address staker, uint32 indexed stakerId);

    event ResetLock(address staker, uint32 epoch);

    /// @param razorAddress The address of the Razor token ERC20 contract
    /// @param rewardManagerAddress The address of the RewardManager contract
    /// @param voteManagersAddress The address of the VoteManager contract
    function initialize(
        address razorAddress,
        address rewardManagerAddress,
        address voteManagersAddress,
        address stakedTokenFactoryAddress
    ) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        razor = IERC20(razorAddress);
        rewardManager = IRewardManager(rewardManagerAddress);
        voteManager = IVoteManager(voteManagersAddress);
        stakedTokenFactory = IStakedTokenFactory(stakedTokenFactoryAddress);
    }

    /// @notice stake during commit state only
    /// we check epoch during every transaction to avoid withholding and rebroadcasting attacks
    /// @param epoch The Epoch value for which staker is requesting to stake
    /// @param amount The amount in RZR
    function stake(uint32 epoch, uint256 amount) external initialized checkEpoch(epoch, epochLength) whenNotPaused {
        uint32 stakerId = stakerIds[msg.sender];
        uint256 totalSupply = 0;

        if (stakerId == 0) {
            require(amount >= minStake, "staked amount is less than minimum stake required");
            numStakers = numStakers + (1);
            stakerId = numStakers;
            stakerIds[msg.sender] = stakerId;
            // slither-disable-next-line reentrancy-benign
            IStakedToken sToken = IStakedToken(stakedTokenFactory.createStakedToken(address(this), numStakers));
            stakers[numStakers] = Structs.Staker(false, 0, msg.sender, address(sToken), numStakers, 10000, epoch, amount);

            // Minting
            require(sToken.mint(msg.sender, amount, amount)); // as 1RZR = 1 sRZR
            totalSupply = amount;
        } else {
            require(amount + stakers[stakerId].stake >= minStake, "staked amount is less than minimum stake required");
            IStakedToken sToken = IStakedToken(stakers[stakerId].tokenAddress);
            totalSupply = sToken.totalSupply();
            uint256 toMint = _convertRZRtoSRZR(amount, stakers[stakerId].stake, totalSupply); // RZRs to sRZRs
            // WARNING: ALLOWING STAKE TO BE ADDED AFTER WITHDRAW/SLASH, consequences need an analysis
            // For more info, See issue -: https://github.com/razor-network/contracts/issues/112
            stakers[stakerId].stake = stakers[stakerId].stake + (amount);

            // Mint sToken as Amount * (totalSupplyOfToken/previousStake)
            require(sToken.mint(msg.sender, toMint, amount));
            totalSupply = totalSupply + toMint;
        }
        // slither-disable-next-line reentrancy-events
        emit Staked(msg.sender, stakers[stakerId].tokenAddress, epoch, stakerId, stakers[stakerId].stake, totalSupply, block.timestamp);
        require(razor.transferFrom(msg.sender, address(this), amount), "razor transfer failed");
    }

    /// @notice Delegation
    /// @param epoch The Epoch value for which staker is requesting to stake
    /// @param amount The amount in RZR
    /// @param stakerId The Id of staker whom you want to delegate
    function delegate(
        uint32 epoch,
        uint32 stakerId,
        uint256 amount
    ) external initialized checkEpoch(epoch, epochLength) whenNotPaused {
        require(stakers[stakerId].acceptDelegation, "Delegetion not accpected");
        require(isStakerActive(stakerId, epoch), "Staker is inactive");

        // Step 1 : Calculate Mintable amount
        IStakedToken sToken = IStakedToken(stakers[stakerId].tokenAddress);
        uint256 totalSupply = sToken.totalSupply();
        uint256 toMint = _convertRZRtoSRZR(amount, stakers[stakerId].stake, totalSupply);

        // Step 2: Increase given stakers stake by : Amount
        stakers[stakerId].stake = stakers[stakerId].stake + (amount);

        // Step 3:  Mint sToken as Amount * (totalSupplyOfToken/previousStake)
        require(sToken.mint(msg.sender, toMint, amount));
        totalSupply = totalSupply + toMint;

        // slither-disable-next-line reentrancy-events
        emit Delegated(msg.sender, epoch, stakerId, amount, stakers[stakerId].stake, totalSupply, block.timestamp);

        // Step 4:  Razor Token Transfer : Amount
        require(razor.transferFrom(msg.sender, address(this), amount), "RZR token transfer failed");
    }

    /// @notice staker/delegator must call unstake() to lock their sRZRs
    // and should wait for params.withdraw_after period
    // after which she can call withdraw() in withdrawReleasePeriod.
    // If this period pass, lock expires and she will have to extendLock() to able to withdraw again
    /// @param epoch The Epoch value for which staker is requesting to unstake
    /// @param stakerId The Id of staker associated with sRZR which user want to unstake
    /// @param sAmount The Amount in sRZR
    function unstake(
        uint32 epoch,
        uint32 stakerId,
        uint256 sAmount
    ) external initialized checkEpoch(epoch, epochLength) whenNotPaused {
        State currentState = getState(epochLength);
        require(currentState != State.Propose, "Unstake: NA Propose");
        require(currentState != State.Dispute, "Unstake: NA Dispute");

        Structs.Staker storage staker = stakers[stakerId];
        require(staker.id != 0, "staker.id = 0");
        require(staker.stake > 0, "Nonpositive stake");
        require(locks[msg.sender][staker.tokenAddress].amount == 0, "Existing Lock");
        require(sAmount > 0, "Non-Positive Amount");

        // slither-disable-next-line reentrancy-events,reentrancy-no-eth
        rewardManager.giveInactivityPenalties(epoch, stakerId);

        IStakedToken sToken = IStakedToken(staker.tokenAddress);
        require(sToken.balanceOf(msg.sender) >= sAmount, "Invalid Amount");

        uint256 rAmount = _convertSRZRToRZR(sAmount, staker.stake, sToken.totalSupply());
        staker.stake = staker.stake - rAmount;

        // Transfer commission in case of delegators
        // Check commission rate >0
        uint256 commission = 0;
        if (stakerIds[msg.sender] != stakerId && staker.commission > 0) {
            // Calculate Gain
            uint256 initial = sToken.getRZRDeposited(msg.sender, sAmount);
            if (rAmount > initial) {
                uint256 gain = rAmount - initial;
                uint8 commissionApplicable = staker.commission < maxCommission ? staker.commission : maxCommission;
                commission = (gain * commissionApplicable) / 100;
            }
        }

        locks[msg.sender][staker.tokenAddress] = Structs.Lock(rAmount, commission, epoch + withdrawLockPeriod);

        require(sToken.burn(msg.sender, sAmount), "Token burn Failed");
        //emit event here
        emit Unstaked(msg.sender, epoch, stakerId, rAmount, staker.stake, sToken.totalSupply(), block.timestamp);
    }

    /// @notice staker/delegator can withdraw their funds after calling unstake and withdrawAfter period.
    // To be eligible for withdraw it must be called with in withDrawReleasePeriod(),
    //this is added to avoid front-run unstake/withdraw.
    // For Staker, To be eligible for withdraw she must not participate in lock duration,
    //this is added to avoid hit and run dispute attack.
    // For Delegator, there is no such restriction
    // Both Staker and Delegator should have their locked funds(sRZR) present in
    //their wallet at time of if not withdraw reverts
    // And they have to use extendLock()
    /// @param epoch The Epoch value for which staker is requesting to unstake
    /// @param stakerId The Id of staker associated with sRZR which user want to withdraw
    function withdraw(uint32 epoch, uint32 stakerId) external initialized checkEpoch(epoch, epochLength) whenNotPaused {
        Structs.Staker storage staker = stakers[stakerId];
        Structs.Lock storage lock = locks[msg.sender][staker.tokenAddress];

        require(staker.id != 0, "staker doesnt exist");
        require(lock.withdrawAfter != 0, "Did not unstake");
        require(lock.withdrawAfter <= epoch, "Withdraw epoch not reached");
        require(lock.withdrawAfter + withdrawReleasePeriod >= epoch, "Release Period Passed"); // Can Use ExtendLock
        uint256 commission = lock.commission;
        uint256 withdrawAmount = lock.amount - commission;
        // Reset lock
        _resetLock(stakerId);
        emit Withdrew(msg.sender, epoch, stakerId, withdrawAmount, staker.stake, block.timestamp);
        require(razor.transfer(staker._address, commission), "couldnt transfer");
        //Transfer Razor Back
        require(razor.transfer(msg.sender, withdrawAmount), "couldnt transfer");
    }

    /// @notice remove all funds in case of emergency
    function escape(address _address) external override initialized onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        if (escapeHatchEnabled) {
            require(razor.transfer(_address, razor.balanceOf(address(this))), "razor transfer failed");
        } else {
            revert("escape hatch is disabled");
        }
    }

    /// @notice Used by staker to set delegation acceptance, its set as False by default
    function setDelegationAcceptance(bool status) external {
        uint32 stakerId = stakerIds[msg.sender];
        require(stakerId != 0, "staker id = 0");
        require(stakers[stakerId].commission != 0, "comission not set");
        stakers[stakerId].acceptDelegation = status;
        emit DelegationAcceptanceChanged(status, msg.sender, stakerId);
    }

    /// @notice Used by staker to set commision for delegation
    function setCommission(uint8 commission) external {
        uint32 stakerId = stakerIds[msg.sender];
        require(stakerId != 0, "staker id = 0");
        require(stakers[stakerId].commission == 0, "Commission already intilised");
        require(commission <= maxCommission, "Commission exceeds maxlimit");
        stakers[stakerId].commission = commission;
    }

    /// @notice As of now we only allow decresing commision, as with increase staker would have unfair adv
    function decreaseCommission(uint8 commission) external {
        uint32 stakerId = stakerIds[msg.sender];
        require(stakerId != 0, "staker id = 0");
        require(commission != 0, "Invalid Commission Update");
        require(stakers[stakerId].commission > commission, "Invalid Commission Update");
        stakers[stakerId].commission = commission;
    }

    /// @notice Used by anyone whose lock expired or who lost funds, and want to request withdraw
    // Here we have added penalty to avoid repeating front-run unstake/witndraw attack
    function extendLock(uint32 stakerId) external initialized whenNotPaused {
        // Lock should be expired if you want to extend
        uint32 epoch = getEpoch(epochLength);
        require(locks[msg.sender][stakers[stakerId].tokenAddress].amount != 0, "Existing Lock doesnt exist");
        require(
            locks[msg.sender][stakers[stakerId].tokenAddress].withdrawAfter + withdrawReleasePeriod < epoch,
            "Release Period Not yet passed"
        );

        Structs.Lock storage lock = locks[msg.sender][stakers[stakerId].tokenAddress];

        //Giving out the extendLock penalty
        uint256 penalty = (lock.amount * extendLockPenalty) / 100;
        lock.amount = lock.amount - penalty;
        lock.withdrawAfter = epoch;
    }

    /// @notice External function for setting stake of the staker
    /// Used by RewardManager
    /// @param _id of the staker
    /// @param _stake the amount of Razor tokens staked
    function setStakerStake(
        uint32 _epoch,
        uint32 _id,
        Constants.StakeChanged reason,
        uint256 _stake
    ) external override onlyRole(STAKE_MODIFIER_ROLE) {
        _setStakerStake(_epoch, _id, reason, _stake);
    }

    /// @notice The function is used by the Votemanager reveal function and BlockManager FinalizeDispute
    /// to penalise the staker who lost his secret and make his stake less by "slashPenaltyAmount" and
    /// transfer to bounty hunter half the "slashPenaltyAmount" of the staker
    /// @param stakerId The ID of the staker who is penalised
    /// @param bountyHunter The address of the bounty hunter
    function slash(
        uint32 epoch,
        uint32 stakerId,
        address bountyHunter
    ) external override onlyRole(STAKE_MODIFIER_ROLE) returns (uint32) {
        uint256 _stake = stakers[stakerId].stake;

        uint256 bounty;
        uint256 amountToBeBurned;
        uint256 amountToBeKept;

        // Block Scoping
        // Done for stack too deep issue
        // https://soliditydeveloper.com/stacktoodeep
        {
            (uint16 bountyNum, uint16 burnSlashNum, uint16 keepSlashNum) = (slashNums.bounty, slashNums.burn, slashNums.keep);
            bounty = (_stake * bountyNum) / baseDenominator;
            amountToBeBurned = (_stake * burnSlashNum) / baseDenominator;
            amountToBeKept = (_stake * keepSlashNum) / baseDenominator;
        }

        uint256 slashPenaltyAmount = bounty + amountToBeBurned + amountToBeKept;
        _stake = _stake - slashPenaltyAmount;
        _setStakerStake(epoch, stakerId, StakeChanged.Slashed, _stake);

        if (bounty == 0) return 0;
        bountyCounter = bountyCounter + 1;
        bountyLocks[bountyCounter] = Structs.BountyLock(bountyHunter, bounty, epoch + withdrawLockPeriod);

        //please note that since slashing is a critical part of consensus algorithm,
        //the following transfers are not `reuquire`d. even if the transfers fail, the slashing
        //tx should complete.
        // slither-disable-next-line unchecked-transfer
        razor.transfer(BURN_ADDRESS, amountToBeBurned);

        return bountyCounter;
    }

    /// @notice Allows bountyHunter to redeem their bounty once its locking period is over
    /// @param bountyId The ID of the bounty
    function redeemBounty(uint32 bountyId) external {
        uint32 epoch = getEpoch(epochLength);
        uint256 bounty = bountyLocks[bountyId].amount;

        require(msg.sender == bountyLocks[bountyId].bountyHunter, "Incorrect Caller");
        require(bountyLocks[bountyId].redeemAfter <= epoch, "Redeem epoch not reached");
        delete bountyLocks[bountyId];
        require(razor.transfer(msg.sender, bounty), "couldnt transfer");
    }

    /// @notice External function for setting epochLastPenalized of the staker
    /// Used by RewardManager
    /// @param _id of the staker
    function setStakerEpochFirstStakedOrLastPenalized(uint32 _epoch, uint32 _id) external override onlyRole(STAKE_MODIFIER_ROLE) {
        stakers[_id].epochFirstStakedOrLastPenalized = _epoch;
    }

    function setStakerAge(
        uint32 _epoch,
        uint32 _id,
        uint32 _age
    ) external override onlyRole(STAKE_MODIFIER_ROLE) {
        stakers[_id].age = _age;
        emit AgeChange(_epoch, _id, _age, block.timestamp);
    }

    /// @param _address Address of the staker
    /// @return The staker ID
    function getStakerId(address _address) external view override returns (uint32) {
        return (stakerIds[_address]);
    }

    /// @param _id The staker ID
    /// @return staker The Struct of staker information
    function getStaker(uint32 _id) external view override returns (Structs.Staker memory staker) {
        return (stakers[_id]);
    }

    /// @return The number of stakers in the razor network
    function getNumStakers() external view override returns (uint32) {
        return (numStakers);
    }

    /// @return age of staker
    function getAge(uint32 stakerId) external view returns (uint32) {
        return stakers[stakerId].age;
    }

    /// @return influence of staker
    function getInfluence(uint32 stakerId) external view override returns (uint256) {
        return _getMaturity(stakerId) * stakers[stakerId].stake;
    }

    /// @return stake of staker
    function getStake(uint32 stakerId) external view override returns (uint256) {
        return stakers[stakerId].stake;
    }

    function getEpochFirstStakedOrLastPenalized(uint32 stakerId) external view override returns (uint32) {
        return stakers[stakerId].epochFirstStakedOrLastPenalized;
    }

    /// @return isStakerActive : Activity < Grace
    function isStakerActive(uint32 stakerId, uint32 epoch) public view returns (bool) {
        uint32 epochLastRevealed = voteManager.getEpochLastRevealed(stakerId);
        return ((epoch - epochLastRevealed) <= gracePeriod);
    }

    /// @notice Internal function for setting stake of the staker
    /// @param _id of the staker
    /// @param _stake the amount of Razor tokens staked
    function _setStakerStake(
        uint32 _epoch,
        uint32 _id,
        Constants.StakeChanged reason,
        uint256 _stake
    ) internal {
        stakers[_id].stake = _stake;
        emit StakeChange(_epoch, _id, reason, _stake, block.timestamp);
    }

    /// @return maturity of staker
    function _getMaturity(uint32 stakerId) internal view returns (uint256) {
        uint256 index = stakers[stakerId].age / 10000;

        return maturities[index];
    }

    /// @notice 1 sRZR = ? RZR
    // Used to calcualte sRZR into RZR value
    /// @param _sAmount The Amount in sRZR
    /// @param _currentStake The cuurent stake of associated staker
    function _convertSRZRToRZR(
        uint256 _sAmount,
        uint256 _currentStake,
        uint256 _totalSupply
    ) internal pure returns (uint256) {
        return ((_sAmount * _currentStake) / _totalSupply);
    }

    /// @notice 1 RZR = ? sRZR
    // Used to calcualte RZR into sRZR value
    /// @param _amount The Amount in RZR
    /// @param _currentStake The cuurent stake of associated staker
    /// @param _totalSupply The totalSupply of sRZR
    function _convertRZRtoSRZR(
        uint256 _amount,
        uint256 _currentStake,
        uint256 _totalSupply
    ) internal pure returns (uint256) {
        // Follwoing require is included to cover case where
        // CurrentStake Becomes zero beacues of penalties,
        //this is likely scenario when staker stakes is slashed to 0 for invalid block.
        require(_currentStake != 0, "Stakers Stake is 0");
        return ((_amount * _totalSupply) / _currentStake);
    }

    function _resetLock(uint32 stakerId) private {
        locks[msg.sender][stakers[stakerId].tokenAddress] = Structs.Lock({amount: 0, commission: 0, withdrawAfter: 0});
        emit ResetLock(msg.sender, getEpoch(epochLength));
    }
}