// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "StorageStateCommittee.sol";
//import "Ownable.sol";
import "AccessControl.sol";
import { ERC165 } from "ERC165.sol";

contract DAOCommitteeProxy is StorageStateCommittee, AccessControl, ERC165 {
    address internal _implementation;
    bool public pauseProxy;

    event Upgraded(address indexed implementation);

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DAOCommitteeProxy: msg.sender is not an admin");
        _;
    }
     
    constructor(
        address _ton,
        address _impl,
        address _seigManager,
        address _layer2Registry,
        address _agendaManager,
        address _candidateFactory,
        //address _activityRewardManager,
        address _daoVault
    )
    {
        require(
            _ton != address(0)
            || _impl != address(0)
            || _seigManager != address(0)
            || _layer2Registry != address(0)
            || _agendaManager != address(0)
            || _candidateFactory != address(0),
            "DAOCommitteeProxy: input is zero"
        );
        ton = _ton;
        _implementation = _impl;
        seigManager = ISeigManager(_seigManager);
        layer2Registry = ILayer2Registry(_layer2Registry);
        agendaManager = IDAOAgendaManager(_agendaManager);
        candidateFactory = ICandidateFactory(_candidateFactory);
        daoVault = IDAOVault(_daoVault);
        quorum = 2;
        activityRewardPerSecond = 3170979198376458;

        _registerInterface(bytes4(keccak256("onApprove(address,address,uint256,bytes)")));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    /// @notice Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external onlyOwner {
        pauseProxy = _pause;
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external onlyOwner {
        require(_implementation != address(0), "DAOCommitteeProxy: input is zero");
        require(_implementation != impl, "DAOCommitteeProxy: The input address is same as the state");
        _implementation = impl;
        emit Upgraded(impl);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    fallback() external {
        _fallback();
    }

    function _fallback() internal {
        address _impl = implementation();
        require(_impl != address(0) && !pauseProxy, "DAOCommitteeProxy: impl is zero OR proxy is false");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "EnumerableSet.sol";
import "Address.sol";
import "Context.sol";

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
pragma solidity ^0.7.6;
pragma abicoder v2;

import { IStorageStateCommittee } from "IStorageStateCommittee.sol";
import { ICandidateFactory } from "ICandidateFactory.sol";
import { ILayer2Registry } from "ILayer2Registry.sol";
import { ISeigManager } from "ISeigManager.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { IDAOVault } from "IDAOVault.sol";
import { ICandidate } from "ICandidate.sol";

contract StorageStateCommittee is IStorageStateCommittee {
    enum AgendaStatus { NONE, NOTICE, VOTING, EXEC, ENDED, PENDING, RISK }
    enum AgendaResult { UNDEFINED, ACCEPT, REJECT, DISMISS }

    address public override ton;
    IDAOVault public override daoVault;
    IDAOAgendaManager public override agendaManager;
    ICandidateFactory public override candidateFactory;
    ILayer2Registry public override layer2Registry;
    ISeigManager public override seigManager;

    address[] public override candidates;
    address[] public override members;
    uint256 public override maxMember;

    // candidate EOA => candidate information
    mapping(address => CandidateInfo) internal _candidateInfos;
    uint256 public override quorum;

    uint256 public override activityRewardPerSecond;

    modifier validAgendaManager() {
        require(address(agendaManager) != address(0), "StorageStateCommittee: AgendaManager is zero");
        _;
    }
    
    modifier validCommitteeL2Factory() {
        require(address(candidateFactory) != address(0), "StorageStateCommittee: invalid CommitteeL2Factory");
        _;
    }

    modifier validLayer2Registry() {
        require(address(layer2Registry) != address(0), "StorageStateCommittee: invalid Layer2Registry");
        _;
    }

    modifier validSeigManager() {
        require(address(seigManager) != address(0), "StorageStateCommittee: invalid SeigManagere");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "StorageStateCommittee: not a member");
        _;
    }

    modifier onlyMemberContract() {
        address candidate = ICandidate(msg.sender).candidate();
        require(isMember(candidate), "StorageStateCommittee: not a member");
        _;
    }
    
    function isMember(address _candidate) public view override returns (bool) {
        return _candidateInfos[_candidate].memberJoinedTime > 0;
    }

    function candidateContract(address _candidate) public view override returns (address) {
        return _candidateInfos[_candidate].candidateContract;
    }

    function candidateInfos(address _candidate) external override returns (CandidateInfo memory) {
        return _candidateInfos[_candidate];
    }

    /*function getCandidate() public view returns (address) {
        ILayer2(_candidateContract).
    }*/
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
pragma solidity ^0.7.6;

import { IDAOCommittee } from "IDAOCommittee.sol";
import { ISeigManager } from "ISeigManager.sol";

interface ICandidate {
    function setSeigManager(address _seigMan) external;
    function setCommittee(address _committee) external;
    function updateSeigniorage() external returns (bool);
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function castVote(uint256 _agendaID, uint256 _vote, string calldata _comment) external;
    function isCandidateContract() external view returns (bool);
    function totalStaked() external view returns (uint256 totalsupply);
    function stakedOf(address _account) external view returns (uint256 amount);
    function setMemo(string calldata _memo) external;
    function claimActivityReward() external;

    // getter
    function candidate() external view returns (address);
    function isLayer2Candidate() external view returns (bool);
    function memo() external view returns (string memory);
    function committee() external view returns (IDAOCommittee);
    function seigManager() external view returns (ISeigManager);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { LibAgenda } from "LibAgenda.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";

interface IDAOAgendaManager  {
    struct Ratio {
        uint256 numerator;
        uint256 denominator;
    }

    function setCommittee(address _committee) external;
    function setCreateAgendaFees(uint256 _createAgendaFees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriodSeconds) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriodSeconds) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function newAgenda(
        address[] memory _targets,
        uint256 _noticePeriodSeconds,
        uint256 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] calldata _functionBytecodes
    )
        external
        returns (uint256 agendaID);
    function castVote(uint256 _agendaID, address voter, uint256 _vote) external returns (bool);
    function setExecutedAgenda(uint256 _agendaID) external;
    function setResult(uint256 _agendaID, LibAgenda.AgendaResult _result) external;
    function setStatus(uint256 _agendaID, LibAgenda.AgendaStatus _status) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function setExecutedCount(uint256 _agendaID, uint256 _count) external;
     
    // -- view functions
    function isVoter(uint256 _agendaID, address _user) external view returns (bool);
    function hasVoted(uint256 _agendaID, address _user) external view returns (bool);
    function getVoteStatus(uint256 _agendaID, address _user) external view returns (bool, uint256);
    function getAgendaNoticeEndTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingStartTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingEndTimeSeconds(uint256 _agendaID) external view returns (uint256) ;

    function canExecuteAgenda(uint256 _agendaID) external view returns (bool);
    function getAgendaStatus(uint256 _agendaID) external view returns (uint256 status);
    function totalAgendas() external view returns (uint256);
    function getAgendaResult(uint256 _agendaID) external view returns (uint256 result, bool executed);
    function getExecutionInfo(uint256 _agendaID)
        external
        view
        returns(
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,
            uint256 executeStartFrom
        );
    function isVotableStatus(uint256 _agendaID) external view returns (bool);
    function getVotingCount(uint256 _agendaID)
        external
        view
        returns (
            uint256 countingYes,
            uint256 countingNo,
            uint256 countingAbstain
        );
    function getAgendaTimestamps(uint256 _agendaID)
        external
        view
        returns (
            uint256 createdTimestamp,
            uint256 noticeEndTimestamp,
            uint256 votingStartedTimestamp,
            uint256 votingEndTimestamp,
            uint256 executedTimestamp
        );
    function numAgendas() external view returns (uint256);
    function getVoters(uint256 _agendaID) external view returns (address[] memory);

    function getStatus(uint256 _createAgendaFees) external pure returns (LibAgenda.AgendaStatus);

    // getter
    function committee() external view returns (IDAOCommittee);
    function createAgendaFees() external view returns (uint256);
    function minimumNoticePeriodSeconds() external view returns (uint256);
    function minimumVotingPeriodSeconds() external view returns (uint256);
    function executingPeriodSeconds() external view returns (uint256);
    function agendas(uint256 _index) external view returns (LibAgenda.Agenda memory);
    function voterInfos(uint256 _index1, address _index2) external view returns (LibAgenda.Voter memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

library LibAgenda {
    //using LibAgenda for Agenda;

    enum AgendaStatus { NONE, NOTICE, VOTING, WAITING_EXEC, EXECUTED, ENDED }
    enum AgendaResult { PENDING, ACCEPT, REJECT, DISMISS }

    //votor : based operator 
    struct Voter {
        bool isVoter;
        bool hasVoted;
        uint256 vote;
    }

    // counting abstainVotes yesVotes noVotes
    struct Agenda {
        uint256 createdTimestamp;
        uint256 noticeEndTimestamp;
        uint256 votingPeriodInSeconds;
        uint256 votingStartedTimestamp;
        uint256 votingEndTimestamp;
        uint256 executableLimitTimestamp;
        uint256 executedTimestamp;
        uint256 countingYes;
        uint256 countingNo;
        uint256 countingAbstain;
        AgendaStatus status;
        AgendaResult result;
        address[] voters;
        bool executed;
    }

    struct AgendaExecutionInfo {
        address[] targets;
        bytes[] functionBytecodes;
        bool atomicExecute;
        uint256 executeStartFrom;
    }

    /*function getAgenda(Agenda[] storage agendas, uint256 index) public view returns (Agenda storage agenda) {
        return agendas[index];
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
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
pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMath } from "SafeMath.sol";
import { IERC20 } from  "IERC20.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";
import { ICandidate } from "ICandidate.sol";
import { LibAgenda } from "LibAgenda.sol";
import "Ownable.sol";

contract DAOAgendaManager is Ownable, IDAOAgendaManager {
    using SafeMath for uint256;
    using LibAgenda for *;

    enum VoteChoice { ABSTAIN, YES, NO, MAX }

    IDAOCommittee public override committee;
    
    uint256 public override createAgendaFees; // 아젠다생성비용(TON)
    
    uint256 public override minimumNoticePeriodSeconds;
    uint256 public override minimumVotingPeriodSeconds;
    uint256 public override executingPeriodSeconds;
    
    LibAgenda.Agenda[] internal _agendas;
    mapping(uint256 => mapping(address => LibAgenda.Voter)) internal _voterInfos;
    mapping(uint256 => LibAgenda.AgendaExecutionInfo) internal _executionInfos;
    
    event AgendaStatusChanged(
        uint256 indexed agendaID,
        uint256 prevStatus,
        uint256 newStatus
    );

    event AgendaResultChanged(
        uint256 indexed agendaID,
        uint256 result
    );

    event CreatingAgendaFeeChanged(
        uint256 newFee
    );

    event MinimumNoticePeriodChanged(
        uint256 newPeriod
    );

    event MinimumVotingPeriodChanged(
        uint256 newPeriod
    );

    event ExecutingPeriodChanged(
        uint256 newPeriod
    );

    modifier validAgenda(uint256 _agendaID) {
        require(_agendaID < _agendas.length, "DAOAgendaManager: invalid agenda id");
        _;
    }
    
    constructor() {
        /*minimumNoticePeriodSeconds = 16 days;
        minimumVotingPeriodSeconds = 2 days;
        executingPeriodSeconds = 7 days;*/
        minimumNoticePeriodSeconds = 300;
        minimumVotingPeriodSeconds = 300;
        executingPeriodSeconds = 300;
        
        createAgendaFees = 100000000000000000000; // 100 TON
    }

    function getStatus(uint256 _status) public pure override returns (LibAgenda.AgendaStatus emnustatus) {
        require(_status < 6, "DAOAgendaManager: invalid status value");
        if (_status == uint256(LibAgenda.AgendaStatus.NOTICE))
            return LibAgenda.AgendaStatus.NOTICE;
        else if (_status == uint256(LibAgenda.AgendaStatus.VOTING))
            return LibAgenda.AgendaStatus.VOTING;
        else if (_status == uint256(LibAgenda.AgendaStatus.EXECUTED))
            return LibAgenda.AgendaStatus.EXECUTED;
        else if (_status == uint256(LibAgenda.AgendaStatus.ENDED))
            return LibAgenda.AgendaStatus.ENDED;
        else
            return LibAgenda.AgendaStatus.NONE;
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @param _committee New DAOCommitteeProxy contract address
    function setCommittee(address _committee) external override onlyOwner {
        require(_committee != address(0), "DAOAgendaManager: address is zero");
        committee = IDAOCommittee(_committee);
    }

    /// @notice Set status of the agenda
    /// @param _agendaID agenda ID
    /// @param _status New status of the agenda
    /*function setStatus(uint256 _agendaID, uint256 _status) public override onlyOwner {
        require(_agendaID < _agendas.length, "DAOAgendaManager: Not a valid Proposal Id");

        emit AgendaStatusChanged(_agendaID, uint256(_agendas[_agendaID].status), _status);
        _agendas[_agendaID].status = getStatus(_status);
    }*/

    /// @notice Set the fee(TON) of creating an agenda
    /// @param _createAgendaFees New fee(TON)
    function setCreateAgendaFees(uint256 _createAgendaFees) external override onlyOwner {
        createAgendaFees = _createAgendaFees;
        emit CreatingAgendaFeeChanged(_createAgendaFees);
    }

    /// @notice Set the minimum notice period in seconds
    /// @param _minimumNoticePeriodSeconds New minimum notice period in seconds
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriodSeconds) external override onlyOwner {
        minimumNoticePeriodSeconds = _minimumNoticePeriodSeconds;
        emit MinimumNoticePeriodChanged(_minimumNoticePeriodSeconds);
    }

    /// @notice Set the executing period in seconds
    /// @param _executingPeriodSeconds New executing period in seconds
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external override onlyOwner {
        executingPeriodSeconds = _executingPeriodSeconds;
        emit ExecutingPeriodChanged(_executingPeriodSeconds);
    }

    /// @notice Set the minimum voting period in seconds
    /// @param _minimumVotingPeriodSeconds New minimum voting period in seconds
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriodSeconds) external override onlyOwner {
        minimumVotingPeriodSeconds = _minimumVotingPeriodSeconds;
        emit MinimumVotingPeriodChanged(_minimumVotingPeriodSeconds);
    }
      
    /// @notice Creates an agenda
    /// @param _targets Target addresses for executions of the agenda
    /// @param _noticePeriodSeconds Notice period in seconds
    /// @param _votingPeriodSeconds Voting period in seconds
    /// @param _functionBytecodes RLP-Encoded parameters for executions of the agenda
    /// @return agendaID Created agenda ID
    function newAgenda(
        address[] calldata _targets,
        uint256 _noticePeriodSeconds,
        uint256 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] calldata _functionBytecodes
    )
        external
        override
        onlyOwner
        returns (uint256 agendaID)
    {
        require(
            _noticePeriodSeconds >= minimumNoticePeriodSeconds,
            "DAOAgendaManager: minimumNoticePeriod is short"
        );

        agendaID = _agendas.length;
         
        address[] memory emptyArray;
        _agendas.push(LibAgenda.Agenda({
            status: LibAgenda.AgendaStatus.NOTICE,
            result: LibAgenda.AgendaResult.PENDING,
            executed: false,
            createdTimestamp: block.timestamp,
            noticeEndTimestamp: block.timestamp + _noticePeriodSeconds,
            votingPeriodInSeconds: _votingPeriodSeconds,
            votingStartedTimestamp: 0,
            votingEndTimestamp: 0,
            executableLimitTimestamp: 0,
            executedTimestamp: 0,
            countingYes: 0,
            countingNo: 0,
            countingAbstain: 0,
            voters: emptyArray
        }));

        LibAgenda.AgendaExecutionInfo storage executionInfo = _executionInfos[agendaID];
        executionInfo.atomicExecute = _atomicExecute;
        executionInfo.executeStartFrom = 0;
        for (uint256 i = 0; i < _targets.length; i++) {
            executionInfo.targets.push(_targets[i]);
            executionInfo.functionBytecodes.push(_functionBytecodes[i]);
        }
    }

    /// @notice Casts vote for an agenda
    /// @param _agendaID Agenda ID
    /// @param _voter Voter
    /// @param _vote Voting type
    /// @return Whether or not the execution succeeded
    function castVote(
        uint256 _agendaID,
        address _voter,
        uint256 _vote
    )
        external
        override
        onlyOwner
        validAgenda(_agendaID)
        returns (bool)
    {
        require(_vote < uint256(VoteChoice.MAX), "DAOAgendaManager: invalid vote");

        require(
            isVotableStatus(_agendaID),
            "DAOAgendaManager: invalid status"
        );

        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        if (agenda.status == LibAgenda.AgendaStatus.NOTICE) {
            _startVoting(_agendaID);
        }

        require(isVoter(_agendaID, _voter), "DAOAgendaManager: not a voter");
        require(!hasVoted(_agendaID, _voter), "DAOAgendaManager: already voted");

        require(
            block.timestamp <= agenda.votingEndTimestamp,
            "DAOAgendaManager: for this agenda, the voting time expired"
        );
        
        LibAgenda.Voter storage voter = _voterInfos[_agendaID][_voter];
        voter.hasVoted = true;
        voter.vote = _vote;
             
        // counting 0:abstainVotes 1:yesVotes 2:noVotes
        if (_vote == uint256(VoteChoice.ABSTAIN))
            agenda.countingAbstain = agenda.countingAbstain.add(1);
        else if (_vote == uint256(VoteChoice.YES))
            agenda.countingYes = agenda.countingYes.add(1);
        else if (_vote == uint256(VoteChoice.NO))
            agenda.countingNo = agenda.countingNo.add(1);
        else
            revert("DAOAgendaManager: invalid voting");
        
        return true;
    }
    
    /// @notice Set the agenda status as executed
    /// @param _agendaID Agenda ID
    function setExecutedAgenda(uint256 _agendaID)
        external
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        agenda.executed = true;
        agenda.executedTimestamp = block.timestamp;

        uint256 prevStatus = uint256(agenda.status);
        agenda.status = LibAgenda.AgendaStatus.EXECUTED;
        emit AgendaStatusChanged(_agendaID, prevStatus, uint256(LibAgenda.AgendaStatus.EXECUTED));
    }

    /// @notice Set the agenda result
    /// @param _agendaID Agenda ID
    /// @param _result New result
    function setResult(uint256 _agendaID, LibAgenda.AgendaResult _result)
        public
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        agenda.result = _result;

        emit AgendaResultChanged(_agendaID, uint256(_result));
    }
     
    /// @notice Set the agenda status
    /// @param _agendaID Agenda ID
    /// @param _status New status
    function setStatus(uint256 _agendaID, LibAgenda.AgendaStatus _status)
        public
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        uint256 prevStatus = uint256(agenda.status);
        agenda.status = _status;
        emit AgendaStatusChanged(_agendaID, prevStatus, uint256(_status));
    }

    /// @notice Set the agenda status as ended(denied or dismissed)
    /// @param _agendaID Agenda ID
    function endAgendaVoting(uint256 _agendaID)
        external
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        require(
            agenda.status == LibAgenda.AgendaStatus.VOTING,
            "DAOAgendaManager: agenda status is not changable"
        );

        require(
            agenda.votingEndTimestamp <= block.timestamp,
            "DAOAgendaManager: voting is not ended yet"
        );

        setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
        setResult(_agendaID, LibAgenda.AgendaResult.DISMISS);
    }
     
    function _startVoting(uint256 _agendaID) internal validAgenda(_agendaID) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        agenda.votingStartedTimestamp = block.timestamp;
        agenda.votingEndTimestamp = block.timestamp.add(agenda.votingPeriodInSeconds);
        agenda.executableLimitTimestamp = agenda.votingEndTimestamp.add(executingPeriodSeconds);
        agenda.status = LibAgenda.AgendaStatus.VOTING;

        uint256 memberCount = committee.maxMember();
        for (uint256 i = 0; i < memberCount; i++) {
            address voter = committee.members(i);
            agenda.voters.push(voter);
            _voterInfos[_agendaID][voter].isVoter = true;
        }

        emit AgendaStatusChanged(_agendaID, uint256(LibAgenda.AgendaStatus.NOTICE), uint256(LibAgenda.AgendaStatus.VOTING));
    }
    
    function isVoter(uint256 _agendaID, address _candidate) public view override validAgenda(_agendaID) returns (bool) {
        require(_candidate != address(0), "DAOAgendaManager: user address is zero");
        return _voterInfos[_agendaID][_candidate].isVoter;
    }
    
    function hasVoted(uint256 _agendaID, address _user) public view override validAgenda(_agendaID) returns (bool) {
        return _voterInfos[_agendaID][_user].hasVoted;
    }

    function getVoteStatus(uint256 _agendaID, address _user) external view override validAgenda(_agendaID) returns (bool, uint256) {
        LibAgenda.Voter storage voter = _voterInfos[_agendaID][_user];

        return (
            voter.hasVoted,
            voter.vote
        );
    }
    
    function getAgendaNoticeEndTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].noticeEndTimestamp;
    }
    
    function getAgendaVotingStartTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].votingStartedTimestamp;
    }

    function getAgendaVotingEndTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].votingEndTimestamp;
    }

    function canExecuteAgenda(uint256 _agendaID) external view override validAgenda(_agendaID) returns (bool) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        return agenda.status == LibAgenda.AgendaStatus.WAITING_EXEC &&
            block.timestamp <= agenda.executableLimitTimestamp &&
            agenda.result == LibAgenda.AgendaResult.ACCEPT &&
            agenda.votingEndTimestamp <= block.timestamp &&
            agenda.executed == false;
    }
    
    function getAgendaStatus(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256 status) {
        return uint256(_agendas[_agendaID].status);
    }

    function totalAgendas() external view override returns (uint256) {
        return _agendas.length;
    }

    function getAgendaResult(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256 result, bool executed) {
        return (uint256(_agendas[_agendaID].result), _agendas[_agendaID].executed);
    }
   
    function getExecutionInfo(uint256 _agendaID)
        external
        view
        override
        validAgenda(_agendaID)
        returns(
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,
            uint256 executeStartFrom
        )
    {
        LibAgenda.AgendaExecutionInfo storage agenda = _executionInfos[_agendaID];
        return (
            agenda.targets,
            agenda.functionBytecodes,
            agenda.atomicExecute,
            agenda.executeStartFrom
        );
    }

    function setExecutedCount(uint256 _agendaID, uint256 _count) external override {
        LibAgenda.AgendaExecutionInfo storage agenda = _executionInfos[_agendaID];
        agenda.executeStartFrom = agenda.executeStartFrom.add(_count);
    }

    function isVotableStatus(uint256 _agendaID) public view override validAgenda(_agendaID) returns (bool) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        return block.timestamp <= agenda.votingEndTimestamp ||
            (agenda.status == LibAgenda.AgendaStatus.NOTICE &&
                agenda.noticeEndTimestamp <= block.timestamp);
    }

    function getVotingCount(uint256 _agendaID)
        external
        view
        override
        returns (
            uint256 countingYes,
            uint256 countingNo,
            uint256 countingAbstain
        )
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        return (
            agenda.countingYes,
            agenda.countingNo,
            agenda.countingAbstain
        );
    }

    function getAgendaTimestamps(uint256 _agendaID)
        external
        view
        override
        validAgenda(_agendaID)
        returns (
            uint256 createdTimestamp,
            uint256 noticeEndTimestamp,
            uint256 votingStartedTimestamp,
            uint256 votingEndTimestamp,
            uint256 executedTimestamp
        )
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        return (
            agenda.createdTimestamp,
            agenda.noticeEndTimestamp,
            agenda.votingStartedTimestamp,
            agenda.votingEndTimestamp,
            agenda.executedTimestamp
        );
    }

    function numAgendas() external view override returns (uint256) {
        return _agendas.length;
    }

    function getVoters(uint256 _agendaID) external view override validAgenda(_agendaID) returns (address[] memory) {
        return _agendas[_agendaID].voters;
    }

    function agendas(uint256 _index) external view override validAgenda(_index) returns (LibAgenda.Agenda memory) {
        return _agendas[_index];
    }

    function voterInfos(uint256 _agendaID, address _voter) external view override validAgenda(_agendaID) returns (LibAgenda.Voter memory) {
        return _voterInfos[_agendaID][_voter];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ICandidateFactory {
    function deploy(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _name,
        address _committee,
        address _seigManager
    )
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2Registry {
    function layer2s(address layer2) external view returns (bool);

    function register(address layer2) external returns (bool);
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);

    function deployCoinage(address layer2, address seigManager) external returns (bool);
    function registerAndDeployCoinage(address layer2, address seigManager) external returns (bool);
    function unregister(address layer2) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ISeigManager {
    function registry() external view returns (address);
    function depositManager() external view returns (address);
    function ton() external view returns (address);
    function wton() external view returns (address);
    function powerton() external view returns (address);
    function tot() external view returns (address);
    function coinages(address layer2) external view returns (address);
    function commissionRates(address layer2) external view returns (uint256);

    function lastCommitBlock(address layer2) external view returns (uint256);
    function seigPerBlock() external view returns (uint256);
    function lastSeigBlock() external view returns (uint256);
    function pausedBlock() external view returns (uint256);
    function unpausedBlock() external view returns (uint256);
    function DEFAULT_FACTOR() external view returns (uint256);

    function deployCoinage(address layer2) external returns (bool);
    function setCommissionRate(address layer2, uint256 commission, bool isCommissionRateNegative) external returns (bool);

    function uncomittedStakeOf(address layer2, address account) external view returns (uint256);
    function stakeOf(address layer2, address account) external view returns (uint256);
    function additionalTotBurnAmount(address layer2, address account, uint256 amount) external view returns (uint256 totAmount);

    function onTransfer(address sender, address recipient, uint256 amount) external returns (bool);
    function updateSeigniorage() external returns (bool);
    function onDeposit(address layer2, address account, uint256 amount) external returns (bool);
    function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IDAOVault {
    function setTON(address _ton) external;
    function setWTON(address _wton) external;
    function approveTON(address _to, uint256 _amount) external;
    function approveWTON(address _to, uint256 _amount) external;
    function approveERC20(address _token, address _to, uint256 _amount) external;
    function claimTON(address _to, uint256 _amount) external;
    function claimWTON(address _to, uint256 _amount) external;
    function claimERC20(address _token, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { IStorageStateCommittee } from "IStorageStateCommittee.sol";

interface IDAOCommittee is IStorageStateCommittee {
    //--owner
    function setSeigManager(address _seigManager) external;
    function setCandidatesSeigManager(address[] calldata _candidateContracts, address _seigManager) external;
    function setCandidatesCommittee(address[] calldata _candidateContracts, address _committee) external;
    function setLayer2Registry(address _layer2Registry) external;
    function setAgendaManager(address _agendaManager) external;
    function setCandidateFactory(address _candidateFactory) external;
    function setTon(address _ton) external;
    function setActivityRewardPerSecond(uint256 _value) external;
    function setDaoVault(address _daoVault) external;

    function increaseMaxMember(uint256 _newMaxMember, uint256 _quorum) external;
    function decreaseMaxMember(uint256 _reducingMemberIndex, uint256 _quorum) external;
    function createCandidate(string calldata _memo) external;
    function registerLayer2Candidate(address _layer2, string memory _memo) external;
    function registerLayer2CandidateByOwner(address _operator, address _layer2, string memory _memo) external;
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function setMemoOnCandidate(address _candidate, string calldata _memo) external;
    function setMemoOnCandidateContract(address _candidate, string calldata _memo) external;

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    )
        external
        returns (bool);

    function setQuorum(uint256 _quorum) external;
    function setCreateAgendaFees(uint256 _fees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriod) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriod) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function castVote(uint256 _AgendaID, uint256 _vote, string calldata _comment) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function executeAgenda(uint256 _AgendaID) external;
    function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) external;

    function updateSeigniorage(address _candidate) external returns (bool);
    function updateSeigniorages(address[] calldata _candidates) external returns (bool);
    function claimActivityReward(address _receiver) external;

    function isCandidate(address _candidate) external view returns (bool);
    function totalSupplyOnCandidate(address _candidate) external view returns (uint256);
    function balanceOfOnCandidate(address _candidate, address _account) external view returns (uint256);
    function totalSupplyOnCandidateContract(address _candidateContract) external view returns (uint256);
    function balanceOfOnCandidateContract(address _candidateContract, address _account) external view returns (uint256);
    function candidatesLength() external view returns (uint256);
    function isExistCandidate(address _candidate) external view returns (bool);
    function getClaimableActivityReward(address _candidate) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2 {
  function operator() external view returns (address);
  function isLayer2() external view returns (bool);
  function currentFork() external view returns (uint);
  function lastEpoch(uint forkNumber) external view returns (uint);
  function changeOperator(address _operator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { ICandidateFactory } from "ICandidateFactory.sol";
import { ILayer2Registry } from "ILayer2Registry.sol";
import { ISeigManager } from "ISeigManager.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { IDAOVault } from "IDAOVault.sol";

interface IStorageStateCommittee {
    struct CandidateInfo {
        address candidateContract;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    function ton() external returns (address);
    function daoVault() external returns (IDAOVault);
    function agendaManager() external returns (IDAOAgendaManager);
    function candidateFactory() external returns (ICandidateFactory);
    function layer2Registry() external returns (ILayer2Registry);
    function seigManager() external returns (ISeigManager);
    function candidates(uint256 _index) external returns (address);
    function members(uint256 _index) external returns (address);
    function maxMember() external returns (uint256);
    function candidateInfos(address _candidate) external returns (CandidateInfo memory);
    function quorum() external returns (uint256);
    function activityRewardPerSecond() external returns (uint256);

    function isMember(address _candidate) external returns (bool);
    function candidateContract(address _candidate) external returns (address);
}