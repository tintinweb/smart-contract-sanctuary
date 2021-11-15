// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {SafeMath} from "../utils/math/SafeMath.sol";

import "./StakeProxyStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IStakeFactory} from "../interfaces/IStakeFactory.sol";
import {IStakeRegistry} from "../interfaces/IStakeRegistry.sol";
import {IStake1Vault} from "../interfaces/IStake1Vault.sol";
import {IStakeTON} from "../interfaces/IStakeTON.sol";
import {Stake1Vault} from "./Stake1Vault.sol";

contract Stake1Logic is StakeProxyStorage, AccessControl {
    using SafeMath for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant ZERO_HASH =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    modifier onlyOwner() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            ""
        );
        _;
    }

    modifier nonZero(address _addr) {
        require(_addr != address(0), "Stake1Proxy: zero address");
        _;
    }

    modifier nonZeroHash(bytes32 _hash) {
        require(_hash != ZERO_HASH, "Stake1Proxy: zero hash");
        _;
    }

    //////////////////////////////
    // Events
    //////////////////////////////
    event CreatedVault(address indexed vault, address paytoken, uint256 cap);
    event CreatedStakeContract(address indexed vault, address indexed stakeContract, uint256 phase);
    /*
    event ClosedSale(address indexed vault, address from);
    event TokamakStaked(address indexed stakeContract, address from, address layer2);
    event TokamakRequestedUnStakingAll(address indexed stakeContract, address from, address layer2);
    event TokamakRequestedUnStakingReward(address indexed stakeContract, address from, address layer2);
    event TokamakProcessedUnStaking(address indexed stakeContract, address from, address layer2, bool receiveTON);
    */
    event SetStakeFactory(address stakeFactory);
    event SetStakeRegistry(address stakeRegistry);

    //////////////////////////////////////////////////////////////////////
    // setters
    function setStore(
        address _fld,
        address _stakeRegistry,
        address _stakeFactory,
        address _ton,
        address _wton,
        address _depositManager,
        address _seigManager
    )
        external
        onlyOwner
        nonZero(_ton)
        nonZero(_wton)
        nonZero(_depositManager)
    {
        setFLD(_fld);
        setStakeRegistry(_stakeRegistry);
        setStakeFactory(_stakeFactory);
        ton = _ton;
        wton = _wton;
        depositManager = _depositManager;
        seigManager = _seigManager;

    }

    ///
    function setFactory(address _stakeFactory) external onlyOwner {
        setStakeFactory(_stakeFactory);
    }

    //////////////////////////////////////////////////////////////////////
    // Admin Functions
    function createVault(
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlcok,
        uint256 _stakeStartBlcok,
        uint256 _phase,
        bytes32 _vaultName,
        uint256 _stakeType,
        address _defiAddr
    ) external {
        Stake1Vault vault = new Stake1Vault();
        vault.initialize(
            fld,
            _paytoken,
            _cap,
            _saleStartBlcok,
            _stakeStartBlcok,
            address(stakeFactory),
            _stakeType,
            _defiAddr
        );
        stakeRegistry.addVault(address(vault), _phase, _vaultName);

        emit CreatedVault(address(vault), _paytoken, _cap);
    }

    function createStakeContract(
        uint256 _phase,
        address _vault,
        address token,
        address paytoken,
        uint256 periodBlock,
        string memory _name
    ) external onlyOwner {
        require(
            stakeRegistry.validVault(_phase, _vault),
            "Stake1Logic: unvalidVault"
        );
        // solhint-disable-next-line max-line-length
        address _contract =
            stakeFactory.deploy(
                _phase,
                _vault,
                token,
                paytoken,
                periodBlock,
                [ton, wton, depositManager, seigManager]
            );
        require(
            _contract != address(0),
            "Stake1Logic: deploy fail"
        );

        IStake1Vault(_vault).addSubVaultOfStake(_name, _contract, periodBlock);
        stakeRegistry.addStakeContract(_vault, _contract);

        emit CreatedStakeContract(_vault, _contract, _phase);
    }

    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    function closeSale(address _vault) external {
        IStake1Vault(_vault).closeSale();

        // emit ClosedSale(_vault, msg.sender);
    }

    function addVault(
        uint256 _phase,
        bytes32 _vaultName,
        address _vault
    ) external onlyOwner {

        stakeRegistry.addVault(_vault, _phase, _vaultName);
    }

    function stakeContractsOfVault(address _vault)
        external
        view
        nonZero(_vault)
        returns (address[] memory)
    {
        return IStake1Vault(_vault).stakeAddressesAll();
    }

    function vaultsOfPhase(uint256 _phaseIndex)
        external
        view
        returns (address[] memory)
    {
        return stakeRegistry.phasesAll(_phaseIndex);
    }

    function tokamakStaking(
        address _stakeContract,
        address _layer2
    ) external {
        IStakeTON(_stakeContract).tokamakStaking(_layer2);
        //emit TokamakStaked(_stakeContract, msg.sender, _layer2);
    }

    /// @dev Requests unstaking all
    function tokamakRequestUnStakingAll(address _stakeContract, address _layer2)
        external
    {
        IStakeTON(_stakeContract).tokamakRequestUnStakingAll(_layer2);
        //emit TokamakRequestedUnStakingAll(_stakeContract, msg.sender, _layer2);
    }

    /// @dev Requests unstaking
    function tokamakRequestUnStakingReward(
        address _stakeContract,
        address _layer2
    ) external {
        IStakeTON(_stakeContract).tokamakRequestUnStakingReward(_layer2);
        //emit TokamakRequestedUnStakingReward(_stakeContract, msg.sender, _layer2);
    }

    /// @dev Processes unstaking
    function tokamakProcessUnStaking(
        address _stakeContract,
        address _layer2,
        bool receiveTON
    ) external {
        IStakeTON(_stakeContract).tokamakProcessUnStaking(_layer2, receiveTON);
        //emit TokamakProcessedUnStaking(_stakeContract, msg.sender, _layer2, receiveTON);
    }

    /// @dev Sets FLD address
    function setFLD(address _fld) public onlyOwner nonZero(_fld) {
        fld = _fld;
    }

    /// @dev Sets Stake Registry address
    function setStakeRegistry(address _stakeRegistry)
        public
        onlyOwner
        nonZero(_stakeRegistry)
    {
        stakeRegistry = IStakeRegistry(_stakeRegistry);
        emit SetStakeRegistry(_stakeRegistry);
    }

    /// @dev Sets Stake Factory address
    function setStakeFactory(address _stakeFactory)
        public
        onlyOwner
        nonZero(_stakeFactory)
    {
        stakeFactory = IStakeFactory(_stakeFactory);
        emit SetStakeFactory(_stakeFactory);
    }

    function vaultsOfPahse(uint256 _phase)
        public
        view
        nonZero(address(stakeRegistry))
        returns (address[] memory)
    {
        return stakeRegistry.phasesAll(_phase);
    }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import {IStakeFactory} from "../interfaces/IStakeFactory.sol";
import {IStakeRegistry} from "../interfaces/IStakeRegistry.sol";

contract StakeProxyStorage {
    IStakeRegistry public stakeRegistry;
    IStakeFactory public stakeFactory;
    uint256 public secondsPerBlock;
    address public fld;

    address public ton;
    address public wton;
    address public depositManager;
    address public seigManager;

    modifier validStakeRegistry() {
        require(
            address(stakeRegistry) != address(0),
            "StakeStorage: stakeRegistry is zero"
        );
        _;
    }

    modifier validStakeFactory() {
        require(
            address(stakeFactory) != address(0),
            "StakeStorage: invalid stakeFactory"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeFactory {
    function deploy(
        uint256 _pahse,
        address _vault,
        address _token,
        address _paytoken,
        uint256 _period,
        address[4] memory tokamakAddr
    ) external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeRegistry {
    function addVault(
        address _vault,
        uint256 _pahse,
        bytes32 _vaultName
    ) external;

    function addStakeContract(address _vault, address _stakeContract) external;

    function validVault(uint256 _pahse, address _vault)
        external
        view
        returns (bool valid);

    function phasesAll(uint256 _index) external view returns (address[] memory);

    function stakeContractsOfVaultAll(address _vault)
        external
        view
        returns (address[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;
import "../libraries/LibTokenStake1.sol";

interface IStake1Vault {
    function initialize(
        address _fld,
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlcok,
        uint256 _stakeStartBlcok
    ) external;

    /// @dev Sets the FLD address
    function setFLD(address _ton) external;

    /// @dev Changes the cap of vault.
    function changeCap(uint256 _cap) external;

    function changeOrderedEndBlocks(uint256[] memory _ordered) external;

    function addSubVaultOfStake(
        string memory _name,
        address stakeContract,
        uint256 periodBlocks
    ) external;

    function closeSale() external;

    function claim(address _to, uint256 _amount) external returns (bool);

    function canClaim(address _to, uint256 _amount)
        external
        view
        returns (uint256);

    function totalRewardAmount(address _account)
        external
        view
        returns (uint256);

    function stakeAddressesAll() external view returns (address[] memory);

    function orderedEndBlocksAll() external view returns (uint256[] memory);

    function fld() external view returns (address);

    function paytoken() external view returns (address);

    function cap() external view returns (uint256);

    function stakeType() external view returns (uint256);

    function defiAddr() external view returns (address);

    function saleStartBlock() external view returns (uint256);

    function stakeStartBlock() external view returns (uint256);

    function stakeEndBlock() external view returns (uint256);

    function blockTotalReward() external view returns (uint256);

    function saleClosed() external view returns (bool);

    function stakeEndBlockTotal(uint256 endblock)
        external
        view
        returns (uint256 totalStakedAmount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../libraries/LibTokenStake1.sol";

interface IStakeTON {
    function token() external view returns (address);

    function paytoken() external view returns (address);

    function vault() external view returns (address);

    function saleStartBlock() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function rewardRaised() external view returns (uint256);

    function totalStakedAmount() external view returns (uint256);

    function userStaked(address account)
        external
        returns (LibTokenStake1.StakedAmount memory);

    function initialize(
        address _token,
        address _paytoken,
        address _vault,
        uint256 _saleStartBlock,
        uint256 _startBlock,
        uint256 _period
    ) external ;

    function setTokamak(
        address _ton,
        address _wton,
        address _depositManager,
        address _seigManager,
        address _defiAddr
    ) external;


    function stake(uint256 amount) external payable;

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    ) external returns (bool);

    function stakeOnApprove(
        address _owner,
        address _spender,
        uint256 _amount
    ) external;

    function tokamakStaking(address _layer2) external;

    function tokamakRequestUnStakingAll(address _layer2) external;

    function tokamakRequestUnStakingReward(address _layer2) external;

    function tokamakProcessUnStaking(address _layer2, bool receiveTON) external;

    function tokamakPendingUnstaked(address _layer2)
        external
        view
        returns (uint256 wtonAmount);

    function tokamakAccStaked(address _layer2)
        external
        view
        returns (uint256 wtonAmount);

    function tokamakAccUnstaked(address _layer2)
        external
        view
        returns (uint256 wtonAmount);

    function tokamakStakeOf(address _layer2)
        external
        view
        returns (uint256 wtonAmount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IFLD} from "../interfaces/IFLD.sol";
import "../interfaces/IStake1Vault.sol";
import "../interfaces/IStake1.sol";

import "../libraries/LibTokenStake1.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FLD Token's Vault - stores the fld for the period of time
/// @notice A vault is associated with the set of stake contracts.
/// Stake contracts can interact with the vault to claim fld tokens
contract Stake1Vault is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant ZERO_HASH =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    //address payable public self;

    IFLD public fld;
    address public paytoken;
    uint256 public cap;
    uint256 public saleStartBlock;
    uint256 public stakeStartBlock;
    uint256 public stakeEndBlock;
    uint256 public blockTotalReward;
    bool public saleClosed;
    uint256 public stakeType; // 0 : StakeTON ( eth or ton) , 2 : StakeForStableCoin (stable coin)
    address public defiAddr; // uniswapRouter or yraenV2Vault

    address[] public stakeAddresses;
    mapping(address => LibTokenStake1.StakeInfo) public stakeInfos;

    uint256[] public orderedEndBlocks; // Ascending orders
    mapping(uint256 => uint256) public stakeEndBlockTotal;

    //mapping(bytes32 => uint) private lock;
    uint256 private _lock;

    modifier onlyOwner() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Stake1Vault: Caller is not an admin"
        );
        _;
    }

    modifier onlyManager() {
        require(
            hasRole(MANAGER_ROLE, msg.sender),
            "Stake1Vault: Caller is not a manager"
        );
        _;
    }

    modifier onlyClaimer() {
        require(
            hasRole(CLAIMER_ROLE, msg.sender),
            "Stake1Vault: Caller is not a claimer"
        );
        _;
    }

    modifier lock() {
        require(_lock == 0, "Stake1Vault: LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }

    //////////////////////////////
    // Events
    //////////////////////////////
    event ClosedSale(uint256 amount);
    event ClaimedReward(address indexed from, address to, uint256 amount);

    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CLAIMER_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(CLAIMER_ROLE, msg.sender);
    }

    receive() external payable {}

    /// @dev Initializes all variables
    /// @param _fld - FLD token address
    /// @param _paytoken - Tokens staked by users, can be used as ERC20 tokens.
    //                     (In case of ETH, input address(0))
    /// @param _cap - Maximum amount of rewards issued
    /// @param _saleStartBlock - Sales start block
    /// @param _stakeStartBlock - Staking start block
    /// @param _stakefactory - factory address to create stakeContract
    /// @param _stakeType - if paytokein is stable coin, it is true.
    function initialize(
        address _fld,
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlock,
        uint256 _stakeStartBlock,
        address _stakefactory,
        uint256 _stakeType,
        address _defiAddr
    ) external onlyOwner {
        require(
            _fld != address(0) && _stakefactory != address(0),
            "Stake1Vault: input is zero"
        );
        require(_cap > 0, "Stake1Vault: _cap is zero");
        require(
            _saleStartBlock < _stakeStartBlock && _stakeStartBlock > 0,
            "Stake1Vault: startBlock is unavailable"
        );

        fld = IFLD(_fld);
        cap = _cap;
        paytoken = _paytoken;
        saleStartBlock = _saleStartBlock;
        stakeStartBlock = _stakeStartBlock;
        stakeType = _stakeType;
        defiAddr = _defiAddr;

        grantRole(ADMIN_ROLE, _stakefactory);
    }

    /// @dev Sets FLD address
    function setFLD(address _fld) external onlyOwner {
        require(_fld != address(0), "Stake1Vault: input is zero");
        fld = IFLD(_fld);
    }

    /// @dev Change cap of the vault
    function changeCap(uint256 _cap) external onlyOwner {
        require(_cap > 0 && cap != _cap, "Stake1Vault: changeCap fails");
        cap = _cap;
    }

    /// @dev Change orders
    function changeOrderedEndBlocks(uint256[] memory _ordered)
        external
        onlyOwner
    {
        // solhint-disable-next-line max-line-length
        require(
            stakeEndBlock < block.number &&
                orderedEndBlocks.length > 0 &&
                orderedEndBlocks.length == _ordered.length,
            "Stake1Vault: changeOrderedEndBlocks fails"
        );
        orderedEndBlocks = _ordered;
    }

    /// @dev Set Defi Address
    function setDefiAddr(address _defiAddr) external onlyOwner {
        require(
            _defiAddr != address(0) && defiAddr != _defiAddr,
            "Stake1Vault: _defiAddr is zero"
        );
        defiAddr = _defiAddr;
    }

    /// @dev Add stake contract
    function addSubVaultOfStake(
        string memory _name,
        address stakeContract,
        uint256 periodBlocks
    ) external onlyOwner {
        require(
            stakeContract != address(0) && cap > 0 && periodBlocks > 0,
            "Stake1Vault: addStakerInVault init fails"
        );
        require(
            block.number < stakeStartBlock,
            "Stake1Vault: Already started stake"
        );
        require(saleClosed == false, "Stake1Vault: closed sale");
        require(
            paytoken == IStake1(stakeContract).paytoken(),
            "Different paytoken"
        );

        LibTokenStake1.StakeInfo storage info = stakeInfos[stakeContract];
        require(info.startBlcok == 0, "Stake1Vault: Already added");

        stakeAddresses.push(stakeContract);
        uint256 _endBlock = stakeStartBlock + periodBlocks;

        info.name = _name;
        info.startBlcok = stakeStartBlock;
        info.endBlock = _endBlock;

        if (stakeEndBlock < _endBlock) stakeEndBlock = _endBlock;
        orderedEndBlocks.push(stakeEndBlock);
    }

    /// @dev Close sale
    function closeSale() external {
        require(saleClosed == false, "already closed");
        require(
            cap > 0 &&
                stakeStartBlock > 0 &&
                stakeStartBlock < stakeEndBlock &&
                block.number > stakeStartBlock &&
                block.number < stakeEndBlock,
            "closeSale init fail"
        );
        require(stakeAddresses.length > 0, "no stakes");
        blockTotalReward = cap / (stakeEndBlock - stakeStartBlock);

        // update balance
        for (uint256 i = 0; i < stakeAddresses.length; i++) {
            address stake = stakeAddresses[i];
            LibTokenStake1.StakeInfo storage stakeInfo = stakeInfos[stake];
            if (paytoken == address(0)) {
                stakeInfo.balance = address(uint160(stake)).balance;
            } else {
                stakeInfo.balance = IERC20(paytoken).balanceOf(stake);
            }
        }
        uint256 sum = 0;
        // update total
        for (uint256 i = 0; i < stakeAddresses.length; i++) {
            LibTokenStake1.StakeInfo storage totalcheck =
                stakeInfos[stakeAddresses[i]];
            uint256 total = 0;
            for (uint256 j = 0; j < stakeAddresses.length; j++) {
                if (
                    stakeInfos[stakeAddresses[j]].endBlock >=
                    totalcheck.endBlock
                ) {
                    total += stakeInfos[stakeAddresses[j]].balance;
                }
            }
            stakeEndBlockTotal[totalcheck.endBlock] = total;
            sum += total;

            // reward total
            uint256 totalReward = 0;
            for (uint256 k = i; k > 0; k--) {
                totalReward +=
                    ((stakeInfos[stakeAddresses[k]].endBlock -
                        stakeInfos[stakeAddresses[k - 1]].endBlock) *
                        blockTotalReward *
                        totalcheck.balance) /
                    stakeEndBlockTotal[stakeInfos[stakeAddresses[k]].endBlock];
            }
            totalReward +=
                ((stakeInfos[stakeAddresses[0]].endBlock -
                    stakeInfos[stakeAddresses[0]].startBlcok) *
                    blockTotalReward *
                    totalcheck.balance) /
                stakeEndBlockTotal[stakeInfos[stakeAddresses[0]].endBlock];

            totalcheck.totalRewardAmount = totalReward;
        }

        saleClosed = true;
        emit ClosedSale(sum);
    }

    /// @dev
    /// sender is a staking contract.
    /// A function that pays the amount(_amount) to _to by the staking contract.
    /// A function that _to claim the amount(_amount) from the staking contract and gets the FLD in the vault.
    function claim(address _to, uint256 _amount) external returns (bool) {
        require(saleClosed && _amount > 0, "disclose sale");
        uint256 fldBalance = fld.balanceOf(address(this));
        require(
            fldBalance >= _amount,
            "not enough balance"
        );

        LibTokenStake1.StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        require(
            stakeInfo.startBlcok > 0,
            "zero"
        );
        require(
            stakeInfo.totalRewardAmount >=
                stakeInfo.claimRewardAmount + _amount,
            "claim amount exceeds"
        );
        require(
            stakeInfo.totalRewardAmount > 0 &&
                (stakeInfo.totalRewardAmount -
                    stakeInfo.claimRewardAmount -
                    _amount) >
                0,
            "amount is wrong"
        );

        stakeInfo.claimRewardAmount += _amount;

        require(fld.transfer(_to, _amount), "FLD transfer fail");

        emit ClaimedReward(msg.sender, _to, _amount);
        return true;
    }

    /// @dev How much you can claim
    function canClaim(address _to, uint256 _amount)
        external
        view
        returns (uint256)
    {
        require(saleClosed, "disclose");
        uint256 fldBalance = fld.balanceOf(address(this));
        require(
            fldBalance >= _amount,
            "not enough"
        );

        LibTokenStake1.StakeInfo storage stakeInfo = stakeInfos[_to];
        require(
            stakeInfo.startBlcok > 0,
            "startBlcok is zero"
        );

        require(
            stakeInfo.totalRewardAmount > 0,
            "amount is wrong"
        );
        require(
            stakeInfo.totalRewardAmount >=
                stakeInfo.claimRewardAmount + _amount,
            "amount exceeds"
        );
        require(
            stakeInfo.totalRewardAmount -
                stakeInfo.claimRewardAmount -
                _amount >
                0,
            "Stake1Vault: wrong"
        );
        return stakeInfo.totalRewardAmount;
    }

    /// @dev Returns the FLD balance stored in the vault
    function balanceFLDAvailableAmount()
        external
        view
        returns (
            // onlyClaimer
            uint256
        )
    {
        return fld.balanceOf(address(this));
    }

    /// @dev Returns all addresses
    function stakeAddressesAll() external view returns (address[] memory) {
        return stakeAddresses;
    }

    /// @dev Ordered end blocks
    function orderedEndBlocksAll() external view returns (uint256[] memory) {
        return orderedEndBlocks;
    }

    /// @dev Total reward amount
    function totalRewardAmount(address _account)
        external
        view
        returns (uint256)
    {
        return stakeInfos[_account].totalRewardAmount;
    }

    /// @dev Returns info
    function infos()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            paytoken,
            cap,
            saleStartBlock,
            stakeStartBlock,
            stakeEndBlock,
            blockTotalReward,
            saleClosed
        );
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibTokenStake1 {
    struct StakeInfo {
        string name;
        uint256 startBlcok;
        uint256 endBlock;
        uint256 balance;
        uint256 totalRewardAmount;
        uint256 claimRewardAmount;
    }

    struct StakedAmount {
        uint256 amount;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
        bool released;
    }

    struct StakedAmountForSFLD {
        uint256 amount;
        uint256 startBlock;
        uint256 periodBlock;
        uint256 rewardPerBlock;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IFLD {
    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * Issue a token.
     */
    function mint(address to, uint256 amount) external returns (bool);

    /**
     * burn a token.
     */
    function burn(address from, uint256 amount) external returns (bool);

    /**
     * The sender authorize spender to spend sender's tokens in the amount.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * The sender sends the value of this token to addressTO.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * The sender sends the amount of tokens from fromAddress to toAddress.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    //function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    /**
     * Authorizes the owner's token to be used by the spender as much as the value.
     * The signature must have the owner's signature.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../libraries/LibTokenStake1.sol";

interface IStake1 {
    function token() external view returns (address);

    function paytoken() external view returns (address);

    function vault() external view returns (address);

    function saleStartBlock() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function rewardRaised() external view returns (uint256);

    function totalStakedAmount() external view returns (uint256);

    function userStaked(address account)
        external
        returns (LibTokenStake1.StakedAmount memory);

    function stake(uint256 amount) external payable;
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

