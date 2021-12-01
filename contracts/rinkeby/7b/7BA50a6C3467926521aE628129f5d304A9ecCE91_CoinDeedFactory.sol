//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/ICoinDeedFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ILendingPool.sol";
import "./interface/ICoinDeedDeployer.sol";
import "./interface/ICoinDeed.sol";

contract CoinDeedFactory is ICoinDeedFactory, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private deedIdCounter;

    IERC20 public deedToken;
    address public coinDeedAdmin;
    uint8 public override maxLeverage = 20;
    address public override wholesaleFactoryAddress;
    address public override lendingPoolAddress;
    address public override coinDeedDeployerAddress;
    uint256 public override platformFee;
    uint256 public override stakingMultiplier;

    uint256[] public pendingDeedIds;
    uint256[] public openDeedIds;
    uint256[] public completedDeedIds;

    mapping(uint256 => address) public pendingDeedMapping;
    mapping(uint256 => address) public openDeedMapping;
    mapping(uint256 => address) public completedDeedMapping;
    mapping(address => bool) public tokenPermissions;

    mapping(address => address[]) public managerDeedList;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    constructor(address deedTokenAddress,
                address _wholesaleFactoryAddress,
                address _lendingPoolAddress,
                address _coinDeedDeployerAddress,
                uint256 _platformFee,
                uint256 _stakingMultiplier) {
        deedToken = IERC20(deedTokenAddress);
        wholesaleFactoryAddress = _wholesaleFactoryAddress;
        lendingPoolAddress = _lendingPoolAddress;
        coinDeedAdmin = msg.sender;
        coinDeedDeployerAddress = _coinDeedDeployerAddress;
        platformFee = _platformFee;
        stakingMultiplier = _stakingMultiplier;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    //TODO use exchange swap stakingToken to deedToken
    //TODO Check if any rules on leverage size?
    function createDeed(
        ICoinDeed.Pair calldata pair,
        uint256 stakingAmount,
        uint256 wholesaleId,
        ICoinDeed.DeedParameters calldata deedParameters,
        ICoinDeed.ExecutionTime calldata executionTime,
        ICoinDeed.RiskMitigation calldata riskMitigation,
        ICoinDeed.BrokerConfig calldata brokerConfig
    ) external override {
        require(
            deedToken.allowance(msg.sender, address(this)) >= stakingAmount,
            "Allowance from ERC20 is not enough for staking."
        );
        require(
            pair.tokenA != pair.tokenB,
            "Trading pairs can not be the same token"
        );
        require(
            deedParameters.leverage <= maxLeverage,
            "Leverage can not be bigger than MaxLeverage."
        );
        require(
            tokenPermissions[pair.tokenA] && tokenPermissions[pair.tokenB],
            "Not on permissioned token list"
        );

        ILendingPool.PoolInfo memory poolInfo = ILendingPool(lendingPoolAddress).getPoolInfo(pair.tokenA);

        require(poolInfo.borrowIndex != 0, "LendingPool does not exist.");

        address[3] memory addressArgs = [coinDeedAdmin, address(deedToken), msg.sender];

        address coinDeedAddress = ICoinDeedDeployer(coinDeedDeployerAddress).deploy(
            addressArgs,
            stakingAmount,
            pair,
            deedParameters,
            executionTime,
            riskMitigation,
            brokerConfig
        );

        deedToken.transferFrom(msg.sender, coinDeedAddress, stakingAmount);
        deedIdCounter.increment();
        uint256 deedId = deedIdCounter.current();
        pendingDeedIds.push(deedId);
        pendingDeedMapping[deedId] = coinDeedAddress;
        managerDeedList[msg.sender].push(coinDeedAddress);

        emit DeedCreated(deedId, coinDeedAddress, msg.sender);

        if (wholesaleId > 0) {
            ICoinDeed(coinDeedAddress).reserveWholesale(wholesaleId);
        }

    }

    function openDeedCount() external view override returns (uint256) {
        return openDeedIds.length;
    }

    function completedDeedCount() external view override returns (uint256) {
        return completedDeedIds.length;
    }

    function pendingDeedCount() external view override returns (uint256) {
        return pendingDeedIds.length;
    }

    function setMaxLeverage(uint8 maxLeverage_)
    public
    override
    onlyRole(ADMIN_ROLE)
    {
        maxLeverage = maxLeverage_;
    }

    function setStakingMultiplier(uint256 _stakingMultiplier) public override onlyRole(ADMIN_ROLE) {
        stakingMultiplier = _stakingMultiplier;
    }

    function setPlatformFee(uint256 platformFee_) public override  onlyRole(ADMIN_ROLE) {
        platformFee = platformFee_;
    }

    function permitToken(address token)
    public
    override
    onlyRole(ADMIN_ROLE)
    {
        tokenPermissions[token] = true;
    }

    function unpermitToken(address token)
    public
    override
    onlyRole(ADMIN_ROLE)
    {
        tokenPermissions[token] = false;
    }

    function emitStakeAdded(
        address broker,
        uint256 amount
    ) external override {
        emit StakeAdded(
            msg.sender,
            broker,
            amount
        );
    }

    function emitStateChanged(
        ICoinDeed.DeedState state
    ) external override {
        emit StateChanged(
            msg.sender,
            state
        );
    }

    function emitDeedCanceled(
        address deedAddress
    ) external override {
        emit DeedCanceled(
            msg.sender,
            deedAddress
        );
    }

    function emitSwapExecuted(
        uint256 tokenBought
    ) external override {
        emit SwapExecuted(
            msg.sender,
            tokenBought
        );
    }

    function emitBuyIn(
        address buyer,
        uint256 amount
    ) external override {
        emit BuyIn(
            msg.sender,
            buyer,
            amount
        );
    }

    function emitExitDeed(
        address buyer,
        uint256 amount
    ) external override {
        emit ExitDeed(
            msg.sender,
            buyer,
            amount
        );
    }

    function emitPayOff(
        address buyer,
        uint256 amount
    ) external override {
        emit PayOff(
            msg.sender,
            buyer,
            amount
        );
    }

    function emitLeverageChanged(
        address salePercentage
    ) external override {
        emit LeverageChanged(
            msg.sender,
            salePercentage
        );
    }

    function emitBrokersEnabled() external override {
        emit BrokersEnabled(
            msg.sender
        );
    }

    function managerDeedCount(address manager) external view override returns (uint256) {
        return managerDeedList[manager].length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeed.sol";

interface ICoinDeedFactory {


    event DeedCreated(
        uint256 indexed id,
        address indexed deedAddress,
        address indexed manager
    );

    event StakeAdded(
        address indexed coinDeed,
        address indexed broker,
        uint256 indexed amount
    );

    event StateChanged(
        address indexed coinDeed,
        ICoinDeed.DeedState state
    );

    event DeedCanceled(
        address indexed coinDeed,
        address indexed deedAddress
    );

    event SwapExecuted(
        address indexed coinDeed,
        uint256 indexed tokenBought
    );

    event BuyIn(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event ExitDeed(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event PayOff(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event LeverageChanged(
        address indexed coinDeed,
        address indexed salePercentage
    );

    event BrokersEnabled(
        address indexed coinDeed
    );

    /**
    * DeedManager calls to create deed contract
    */
    function createDeed(ICoinDeed.Pair calldata pair,
        uint256 stakingAmount,
        uint256 wholesaleId,
        ICoinDeed.DeedParameters calldata deedParameters,
        ICoinDeed.ExecutionTime calldata executionTime,
        ICoinDeed.RiskMitigation calldata riskMitigation,
        ICoinDeed.BrokerConfig calldata brokerConfig) external;

    /**
    * Returns number of Open deeds to able to browse them
    */
    function openDeedCount() external view returns (uint256);

    /**
    * Returns number of completed deeds to able to browse them
    */
    function completedDeedCount() external view returns (uint256);

    /**
    * Returns number of pending deeds to able to browse them
    */
    function pendingDeedCount() external view returns (uint256);

    function setMaxLeverage(uint8 maxLeverage_) external;

    function setStakingMultiplier(uint256 _stakingMultiplier) external;

    function permitToken(address token) external;

    function unpermitToken(address token) external;

    function wholesaleFactoryAddress() external view returns (address);

    function lendingPoolAddress() external view returns (address);

    function coinDeedDeployerAddress() external view returns (address);

    function maxLeverage() external view returns (uint8);

    function platformFee() external view returns (uint256);

    function stakingMultiplier() external view returns (uint256);

    function setPlatformFee(uint256 platformFee_) external;

    function managerDeedCount(address manager) external view returns (uint256);

    function emitStakeAdded(
        address broker,
        uint256 amount
    ) external;

    function emitStateChanged(
        ICoinDeed.DeedState state
    ) external;

    function emitDeedCanceled(
        address deedAddress
    ) external;

    function emitSwapExecuted(
        uint256 tokenBought
    ) external;

    function emitBuyIn(
        address buyer,
        uint256 amount
    ) external;

    function emitExitDeed(
        address buyer,
        uint256 amount
    ) external;

    function emitPayOff(
        address buyer,
        uint256 amount
    ) external;

    function emitLeverageChanged(
        address salePercentage
    ) external;

    function emitBrokersEnabled() external;
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

//SPDX-License-Identifier: MIT

import "../interface/IOracle.sol";

pragma solidity >=0.7.0;

interface ILendingPool {
    struct AccrueInterestVars {
        uint256 blockDelta;
        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 simpleInterestSupplyFactor;
        uint256 borrowIndexNew;
        uint256 totalBorrowNew;
        uint256 totalReservesNew;
        uint256 supplyIndexNew;
    }

    // Info of each pool.
    struct PoolInfo {
        IOracle oracle;
        uint256 oracleDecimals;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 borrowIndex;
        uint256 supplyIndex;
        uint256 accrualBlockNumber;
        bool isCreated;
        uint256 decimals;
        uint256 accDTokenPerShare; // Accumulated DTokens per share, time 1e18. See below
    }

    // Info of each deed.
    struct DeedInfo {
        uint256 borrow;
        uint256 totalBorrow;
        uint256 borrowIndex;
        bool isValid;
    }

    event PoolAdded(address indexed token, uint256 decimals);
    event PoolUpdated(
        address indexed token,
        uint256 decimals,
        address oracle,
        uint256 oracleDecimals
    );
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Collateral(address indexed user, uint256 amount);


    /**
  * @notice Event emitted when interest is accrued
  */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves,
        uint256 supplyIndex
    );

    function initialize(address _ethOracle) external;

    function POOL_DECIMALS() external returns (uint256);

    function getPoolInfo(address) external returns (PoolInfo memory);


    // Stake tokens to Pool
    function deposit(address _tokenAddress, uint256 _amount) external payable;

    // Borrow
    function borrow(address _tokenAddress, uint256 _amount) external;

    function addNewDeed(address _address) external;

    function removeExpireDeed(address _address) external;
/*
    function getDtokenExchange(address _token, uint256 reward)
    external
    view
    returns (uint256);
*/
    // Withdraw tokens from STAKING.
    function withdraw(address _tokenAddress, uint256 _amount) external;

    function pendingBorrowBalance(address _token, address _deed)
    external
    view
    returns (uint256);

    function repay(address _tokenAddress, uint256 _amount)
    external
    payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeedFactory.sol";

interface ICoinDeedDeployer {

    function deploy(
        address[3] memory addressArgs,
        uint256 stakingAmount,
        ICoinDeed.Pair memory pair,
        ICoinDeed.DeedParameters memory deedParameters,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.RiskMitigation memory riskMitigation,
        ICoinDeed.BrokerConfig memory brokerConfig
    ) external returns (address);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeedFactory.sol";

interface ICoinDeed {


    struct DeedParameters {
        uint256 deedSize;
        uint8 leverage;
        uint256 managementFee;
        uint256 minimumBuy;
    }

    enum DeedState {SETUP, READY, OPEN, CLOSED, CANCELED}

    struct Pair {address tokenA; address tokenB;}

    struct ExecutionTime {
        uint256 recruitingEndTimestamp;
        uint256 buyTimestamp;
        uint256 sellTimestamp;
    }

    struct RiskMitigation {
        uint256 trigger;
        uint8 leverage;
    }

    struct BrokerConfig {
        bool allowed;
        uint256 minimumStaking;
    }

    /**
    *  Reserve a wholesale to swap on execution time
    */
    function reserveWholesale(uint256 wholesaleId) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    */
    function stake(uint256 amount) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    function stakeEth() external payable;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    function stakeDifferentToken(address token, uint256 amount) external;

    /**
    *  Brokers can withdraw their stake
    */
    function withDrawStake() external;

    /**
    *  Edit Broker Config
    */
    function editBrokerConfig(BrokerConfig memory brokerConfig) external;

    /**
    *  Edit RiskMitigation
    */
    function editRiskMitigation(RiskMitigation memory riskMitigation) external;

    /**
    *  Edit ExecutionTime
    */
    function editExecutionTime(ExecutionTime memory executionTime) external;

    /**
    *  Edit DeedInfo
    */
    function editBasicInfo(uint256 deedSize, uint8 leverage, uint256 managementFee, uint256 minimumBuy) external;

    /**
    *  Edit
    */
    function edit(DeedParameters memory deedParameters,
        ExecutionTime memory executionTime,
        RiskMitigation memory riskMitigation,
        BrokerConfig memory brokerConfig) external;

    /**
     * Initial swap to buy the tokens
     */
    function buy() external;

    /**
     * Final swap to buy the tokens
     */
    function sell() external;

    /**
    *  Cancels deed if it is not started yet.
    */
    function cancel() external;

    /**
    *  Buyers buys in from the deed
    */
    function buyIn(uint256 amount) external;

    /**
    *  Buyers buys in from the deed with native coin
    */
    function buyInEth() external payable;

    /**
     *  Buyers buys in from the deed with another ERC20
     */
    function buyInDifferentToken(address tokenAddress, uint256 amount) external;

    /**
    *  Buyers pays of their loan
    */
    function payOff(uint256 amount) external;

    /**
    *  Buyers pays of their loan with native coin
    */
    function payOffEth() external payable;

    /**
     *  Buyers pays of their loan with with another ERC20
     */
    function payOffDifferentToken(address tokenAddress, uint256 amount) external;

    /**
    *  Buyers claims their balance if the deed is completed.
    */
    function claimBalance() external;

    /**
    *  Brokers and DeedManager claims their rewards.
    */
    function claimManagementFee() external;

    /**
    *  System changes leverage to be sure that the loan can be paid.
    */
    function executeRiskMitigation() external;

    /**
    *  Buyers can leave deed before escrow closes.
    */
    function exitDeed() external;
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

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}