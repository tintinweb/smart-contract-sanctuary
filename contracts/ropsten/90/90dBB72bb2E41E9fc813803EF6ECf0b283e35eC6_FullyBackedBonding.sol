/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "../AbstractBonding.sol";

import "@keep-network/keep-core/contracts/Authorizations.sol";
import "@keep-network/keep-core/contracts/StakeDelegatable.sol";
import "@keep-network/keep-core/contracts/KeepRegistry.sol";

import "@keep-network/sortition-pools/contracts/api/IFullyBackedBonding.sol";

/// @title Fully Backed Bonding
/// @notice Contract holding deposits and delegations for ETH-only keeps'
/// operators. An owner of the ETH can delegate ETH to an operator by depositing
/// it in this contract.
contract FullyBackedBonding is
    IFullyBackedBonding,
    AbstractBonding,
    Authorizations,
    StakeDelegatable
{
    event Delegated(address indexed owner, address indexed operator);

    event OperatorDelegated(
        address indexed operator,
        address indexed beneficiary,
        address indexed authorizer,
        uint256 value
    );

    event OperatorToppedUp(address indexed operator, uint256 value);

    // The ether value (in wei) that should be passed along with the delegation
    // and deposited for bonding.
    uint256 public constant MINIMUM_DELEGATION_DEPOSIT = 40 ether;

    // Once a delegation to an operator is received the delegator has to wait for
    // specific time period before being able to pull out the funds.
    uint256 public constant DELEGATION_LOCK_PERIOD = 12 hours;

    uint256 public initializationPeriod; // varies between mainnet and testnet

    /// @notice Initializes Fully Backed Bonding contract.
    /// @param _keepRegistry Keep Registry contract address.
    /// @param _initializationPeriod To avoid certain attacks on group selection,
    /// recently delegated operators must wait for a specific period of time
    /// before being eligible for group selection.
    constructor(KeepRegistry _keepRegistry, uint256 _initializationPeriod)
        public
        AbstractBonding(address(_keepRegistry))
        Authorizations(_keepRegistry)
    {
        initializationPeriod = _initializationPeriod;
    }

    /// @notice Registers delegation details. The function is used to register
    /// addresses of operator, beneficiary and authorizer for a delegation from
    /// the caller.
    /// The function requires ETH to be submitted in the call as a protection
    /// against attacks blocking operators. The value should be at least equal
    /// to the minimum delegation deposit. Whole amount is deposited as operator's
    /// unbonded value for the future bonding.
    /// @param operator Address of the operator.
    /// @param beneficiary Address of the beneficiary.
    /// @param authorizer Address of the authorizer.
    function delegate(
        address operator,
        address payable beneficiary,
        address authorizer
    ) external payable {
        address owner = msg.sender;

        require(operator != address(0), "Invalid operator address");
        require(authorizer != address(0), "Invalid authorizer address");

        require(
            operators[operator].owner == address(0),
            "Operator already in use"
        );

        require(
            msg.value >= MINIMUM_DELEGATION_DEPOSIT,
            "Insufficient delegation value"
        );

        operators[operator] = Operator(
            OperatorParams.pack(0, block.timestamp, 0),
            owner,
            beneficiary,
            authorizer
        );

        deposit(operator);

        emit Delegated(owner, operator);
        emit OperatorDelegated(operator, beneficiary, authorizer, msg.value);
    }

    /// @notice Top-ups operator's unbonded value.
    /// @dev This function should be used to add new unbonded value to the system
    /// for an operator. The `deposit` function defined in parent abstract contract
    /// should be called only by applications returning value that has been already
    /// initially deposited and seized later. As an application may seize bonds
    /// and return them to the bonding contract with `deposit` function it makes
    /// tracking the totally deposited value much more complicated. Functions
    /// `delegate` and `topUps` should be used to add fresh value to the contract
    /// and events emitted by these functions should be enough to determine total
    /// value deposited ever for an operator.
    /// @param operator Address of the operator.
    function topUp(address operator) public payable {
        deposit(operator);

        emit OperatorToppedUp(operator, msg.value);
    }

    /// @notice Checks if the operator for the given bond creator contract
    /// has passed the initialization period.
    /// @param operator The operator address.
    /// @param bondCreator The bond creator contract address.
    /// @return True if operator has passed initialization period for given
    /// bond creator contract, false otherwise.
    function isInitialized(address operator, address bondCreator)
        public
        view
        returns (bool)
    {
        uint256 operatorParams = operators[operator].packedParams;

        return
            isAuthorizedForOperator(operator, bondCreator) &&
            _isInitialized(operatorParams);
    }

    /// @notice Withdraws amount from operator's value available for bonding.
    /// This function can be called only by:
    /// - operator,
    /// - owner of the stake.
    /// Withdraw cannot be performed immediately after delegation to protect
    /// from a griefing. It is required that delegator waits specific period
    /// of time before they can pull out the funds deposited on delegation.
    /// @param amount Value to withdraw in wei.
    /// @param operator Address of the operator.
    function withdraw(uint256 amount, address operator) public {
        require(
            msg.sender == operator || msg.sender == ownerOf(operator),
            "Only operator or the owner is allowed to withdraw bond"
        );

        require(
            hasDelegationLockPassed(operator),
            "Delegation lock period has not passed yet"
        );

        withdrawBond(amount, operator);
    }

    /// @notice Gets delegation info for the given operator.
    /// @param operator Address of the operator.
    /// @return createdAt The time when the delegation was created.
    /// @return undelegatedAt The time when undelegation has been requested.
    /// If undelegation has not been requested, 0 is returned.
    function getDelegationInfo(address operator)
        public
        view
        returns (uint256 createdAt, uint256 undelegatedAt)
    {
        uint256 operatorParams = operators[operator].packedParams;

        return (
            operatorParams.getCreationTimestamp(),
            operatorParams.getUndelegationTimestamp()
        );
    }

    /// @notice Is the operator with the given params initialized
    function _isInitialized(uint256 operatorParams)
        internal
        view
        returns (bool)
    {
        return
            block.timestamp >
            operatorParams.getCreationTimestamp().add(initializationPeriod);
    }

    /// @notice Has lock period passed for a delegation.
    /// @param operator Address of the operator.
    /// @return True if delegation lock period passed, false otherwise.
    function hasDelegationLockPassed(address operator)
        internal
        view
        returns (bool)
    {
        return
            block.timestamp >
            operators[operator].packedParams.getCreationTimestamp().add(
                DELEGATION_LOCK_PERIOD
            );
    }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity 0.5.17;

import "./IBonding.sol";

/// @title Fully Backed Bonding contract interface.
/// @notice The interface should be implemented by a bonding contract used for
/// Fully Backed Sortition Pool.
contract IFullyBackedBonding is IBonding {
  /// @notice Checks if the operator for the given bond creator contract
  /// has passed the initialization period.
  /// @param operator The operator address.
  /// @param bondCreator The bond creator contract address.
  /// @return True if operator has passed initialization period for given
  /// bond creator contract, false otherwise.
  function isInitialized(address operator, address bondCreator)
    public
    view
    returns (bool);
}

pragma solidity 0.5.17;

interface IBonding {
    // Gives the amount of ETH
    // the `operator` has made available for bonding by the `bondCreator`.
    // If the operator doesn't exist,
    // or the bond creator isn't authorized,
    // returns 0.
    function availableUnbondedValue(
        address operator,
        address bondCreator,
        address authorizedSortitionPool
    ) external view returns (uint256);
}

pragma solidity 0.5.17;

library OperatorParams {
    // OperatorParams packs values that are commonly used together
    // into a single uint256 to reduce the cost functions
    // like querying eligibility.
    //
    // An OperatorParams uint256 contains:
    // - the operator's staked token amount (uint128)
    // - the operator's creation timestamp (uint64)
    // - the operator's undelegation timestamp (uint64)
    //
    // These are packed as [amount | createdAt | undelegatedAt]
    //
    // Staked KEEP is stored in an uint128,
    // which is sufficient because KEEP tokens have 18 decimals (2^60)
    // and there will be at most 10^9 KEEP in existence (2^30).
    //
    // Creation and undelegation times are stored in an uint64 each.
    // Thus uint64s would be sufficient for around 3*10^11 years.
    uint256 constant TIMESTAMP_WIDTH = 64;
    uint256 constant AMOUNT_WIDTH = 128;

    uint256 constant TIMESTAMP_MAX = (2**TIMESTAMP_WIDTH) - 1;
    uint256 constant AMOUNT_MAX = (2**AMOUNT_WIDTH) - 1;

    uint256 constant CREATION_SHIFT = TIMESTAMP_WIDTH;
    uint256 constant AMOUNT_SHIFT = 2 * TIMESTAMP_WIDTH;

    function pack(
        uint256 amount,
        uint256 createdAt,
        uint256 undelegatedAt
    ) internal pure returns (uint256) {
        // Check for staked amount overflow.
        // We shouldn't actually ever need this.
        require(amount <= AMOUNT_MAX, "uint128 overflow");
        // Bitwise OR the timestamps together.
        // The resulting number is equal or greater than either,
        // and tells if we have a bit set outside the 64 available bits.
        require(
            (createdAt | undelegatedAt) <= TIMESTAMP_MAX,
            "uint64 overflow"
        );

        return ((amount << AMOUNT_SHIFT) |
            (createdAt << CREATION_SHIFT) |
            undelegatedAt);
    }

    function unpack(uint256 packedParams)
        internal
        pure
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        amount = getAmount(packedParams);
        createdAt = getCreationTimestamp(packedParams);
        undelegatedAt = getUndelegationTimestamp(packedParams);
    }

    function getAmount(uint256 packedParams) internal pure returns (uint256) {
        return (packedParams >> AMOUNT_SHIFT) & AMOUNT_MAX;
    }

    function setAmount(uint256 packedParams, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return
            pack(
                amount,
                getCreationTimestamp(packedParams),
                getUndelegationTimestamp(packedParams)
            );
    }

    function getCreationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return (packedParams >> CREATION_SHIFT) & TIMESTAMP_MAX;
    }

    function setCreationTimestamp(
        uint256 packedParams,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }

    function getUndelegationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return packedParams & TIMESTAMP_MAX;
    }

    function setUndelegationTimestamp(
        uint256 packedParams,
        uint256 undelegationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                getCreationTimestamp(packedParams),
                undelegationTimestamp
            );
    }

    function setAmountAndCreationTimestamp(
        uint256 packedParams,
        uint256 amount,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                amount,
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./utils/OperatorParams.sol";

/// @title Stake Delegatable
/// @notice A base contract to allow stake delegation for staking contracts.
contract StakeDelegatable {
    using OperatorParams for uint256;

    mapping(address => Operator) internal operators;

    struct Operator {
        uint256 packedParams;
        address owner;
        address payable beneficiary;
        address authorizer;
    }

    /// @notice Gets the stake balance of the specified address.
    /// @param _address The address to query the balance of.
    /// @return An uint256 representing the amount staked by the passed address.
    function balanceOf(address _address) public view returns (uint256 balance) {
        return operators[_address].packedParams.getAmount();
    }

    /// @notice Gets the stake owner for the specified operator address.
    /// @return Stake owner address.
    function ownerOf(address _operator) public view returns (address) {
        return operators[_operator].owner;
    }

    /// @notice Gets the beneficiary for the specified operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _operator)
        public
        view
        returns (address payable)
    {
        return operators[_operator].beneficiary;
    }

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address) {
        return operators[_operator].authorizer;
    }
}

pragma solidity 0.5.17;

/// @title KeepRegistry
/// @notice Governance owned registry of approved contracts and roles.
contract KeepRegistry {
    enum ContractStatus {New, Approved, Disabled}

    // Governance role is to enable recovery from key compromise by rekeying
    // other roles. Also, it can disable operator contract panic buttons
    // permanently.
    address public governance;

    // Registry Keeper maintains approved operator contracts. Each operator
    // contract must be approved before it can be authorized by a staker or
    // used by a service contract.
    address public registryKeeper;

    // Each operator contract has a Panic Button which can disable malicious
    // or malfunctioning contract that have been previously approved by the
    // Registry Keeper.
    //
    // New operator contract added to the registry has a default panic button
    // value assigned (defaultPanicButton). Panic button for each operator
    // contract can be later updated by Governance to individual value.
    //
    // It is possible to disable panic button for individual contract by
    // setting the panic button to zero address. In such case, operator contract
    // can not be disabled and is permanently approved in the registry.
    mapping(address => address) public panicButtons;

    // Default panic button for each new operator contract added to the
    // registry. Can be later updated for each contract.
    address public defaultPanicButton;

    // Each service contract has a Operator Contract Upgrader whose purpose
    // is to manage operator contracts for that specific service contract.
    // The Operator Contract Upgrader can add new operator contracts to the
    // service contract’s operator contract list, and deprecate old ones.
    mapping(address => address) public operatorContractUpgraders;

    // Operator contract may have a Service Contract Upgrader whose purpose is
    // to manage service contracts for that specific operator contract.
    // Service Contract Upgrader can add and remove service contracts
    // from the list of service contracts approved to work with the operator
    // contract. List of service contracts is maintained in the operator
    // contract and is optional - not every operator contract needs to have
    // a list of service contracts it wants to cooperate with.
    mapping(address => address) public serviceContractUpgraders;

    // The registry of operator contracts
    mapping(address => ContractStatus) public operatorContracts;

    event OperatorContractApproved(address operatorContract);
    event OperatorContractDisabled(address operatorContract);

    event GovernanceUpdated(address governance);
    event RegistryKeeperUpdated(address registryKeeper);
    event DefaultPanicButtonUpdated(address defaultPanicButton);
    event OperatorContractPanicButtonDisabled(address operatorContract);
    event OperatorContractPanicButtonUpdated(
        address operatorContract,
        address panicButton
    );
    event OperatorContractUpgraderUpdated(
        address serviceContract,
        address upgrader
    );
    event ServiceContractUpgraderUpdated(
        address operatorContract,
        address keeper
    );

    modifier onlyGovernance() {
        require(governance == msg.sender, "Not authorized");
        _;
    }

    modifier onlyRegistryKeeper() {
        require(registryKeeper == msg.sender, "Not authorized");
        _;
    }

    modifier onlyPanicButton(address _operatorContract) {
        address panicButton = panicButtons[_operatorContract];
        require(panicButton != address(0), "Panic button disabled");
        require(panicButton == msg.sender, "Not authorized");
        _;
    }

    modifier onlyForNewContract(address _operatorContract) {
        require(
            isNewOperatorContract(_operatorContract),
            "Not a new operator contract"
        );
        _;
    }

    modifier onlyForApprovedContract(address _operatorContract) {
        require(
            isApprovedOperatorContract(_operatorContract),
            "Not an approved operator contract"
        );
        _;
    }

    constructor() public {
        governance = msg.sender;
        registryKeeper = msg.sender;
        defaultPanicButton = msg.sender;
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
        emit GovernanceUpdated(governance);
    }

    function setRegistryKeeper(address _registryKeeper) public onlyGovernance {
        registryKeeper = _registryKeeper;
        emit RegistryKeeperUpdated(registryKeeper);
    }

    function setDefaultPanicButton(address _panicButton) public onlyGovernance {
        defaultPanicButton = _panicButton;
        emit DefaultPanicButtonUpdated(defaultPanicButton);
    }

    function setOperatorContractPanicButton(
        address _operatorContract,
        address _panicButton
    ) public onlyForApprovedContract(_operatorContract) onlyGovernance {
        require(
            panicButtons[_operatorContract] != address(0),
            "Disabled panic button cannot be updated"
        );
        require(
            _panicButton != address(0),
            "Panic button must be non-zero address"
        );

        panicButtons[_operatorContract] = _panicButton;

        emit OperatorContractPanicButtonUpdated(
            _operatorContract,
            _panicButton
        );
    }

    function disableOperatorContractPanicButton(address _operatorContract)
        public
        onlyForApprovedContract(_operatorContract)
        onlyGovernance
    {
        require(
            panicButtons[_operatorContract] != address(0),
            "Panic button already disabled"
        );

        panicButtons[_operatorContract] = address(0);

        emit OperatorContractPanicButtonDisabled(_operatorContract);
    }

    function setOperatorContractUpgrader(
        address _serviceContract,
        address _operatorContractUpgrader
    ) public onlyGovernance {
        operatorContractUpgraders[_serviceContract] = _operatorContractUpgrader;
        emit OperatorContractUpgraderUpdated(
            _serviceContract,
            _operatorContractUpgrader
        );
    }

    function setServiceContractUpgrader(
        address _operatorContract,
        address _serviceContractUpgrader
    ) public onlyGovernance {
        serviceContractUpgraders[_operatorContract] = _serviceContractUpgrader;
        emit ServiceContractUpgraderUpdated(
            _operatorContract,
            _serviceContractUpgrader
        );
    }

    function approveOperatorContract(address operatorContract)
        public
        onlyForNewContract(operatorContract)
        onlyRegistryKeeper
    {
        operatorContracts[operatorContract] = ContractStatus.Approved;
        panicButtons[operatorContract] = defaultPanicButton;
        emit OperatorContractApproved(operatorContract);
    }

    function disableOperatorContract(address operatorContract)
        public
        onlyForApprovedContract(operatorContract)
        onlyPanicButton(operatorContract)
    {
        operatorContracts[operatorContract] = ContractStatus.Disabled;
        emit OperatorContractDisabled(operatorContract);
    }

    function isNewOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.New;
    }

    function isApprovedOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.Approved;
    }

    function operatorContractUpgraderFor(address _serviceContract)
        public
        view
        returns (address)
    {
        return operatorContractUpgraders[_serviceContract];
    }

    function serviceContractUpgraderFor(address _operatorContract)
        public
        view
        returns (address)
    {
        return serviceContractUpgraders[_operatorContract];
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./KeepRegistry.sol";

/// @title AuthorityDelegator
/// @notice An operator contract can delegate authority to other operator
/// contracts by implementing the AuthorityDelegator interface.
///
/// To delegate authority,
/// the recipient of delegated authority must call `claimDelegatedAuthority`,
/// specifying the contract it wants delegated authority from.
/// The staking contract calls `delegator.__isRecognized(recipient)`
/// and if the call returns `true`,
/// the named delegator contract is set as the recipient's authority delegator.
/// Any future checks of registry approval or per-operator authorization
/// will transparently mirror the delegator's status.
///
/// Authority can be delegated recursively;
/// an operator contract receiving delegated authority
/// can recognize other operator contracts as recipients of its authority.
interface AuthorityDelegator {
    function __isRecognized(address delegatedAuthorityRecipient)
        external
        returns (bool);
}

/// @title AuthorityVerifier
/// @notice An operator contract can delegate authority to other operator
/// contracts. Entry in the registry is not updated and source contract remains
/// listed there as authorized. This interface is a verifier that support verification
/// of contract authorization in case of authority delegation from the source contract.
interface AuthorityVerifier {
    /// @notice Returns true if the given operator contract has been approved
    /// for use. The function never reverts.
    function isApprovedOperatorContract(address _operatorContract)
        external
        view
        returns (bool);
}

contract Authorizations is AuthorityVerifier {
    // Authorized operator contracts.
    mapping(address => mapping(address => bool)) internal authorizations;

    // Granters of delegated authority to operator contracts.
    // E.g. keep factories granting delegated authority to keeps.
    // `delegatedAuthority[keep] = factory`
    mapping(address => address) internal delegatedAuthority;

    // Registry contract with a list of approved operator contracts and upgraders.
    KeepRegistry internal registry;

    modifier onlyApprovedOperatorContract(address operatorContract) {
        require(
            isApprovedOperatorContract(operatorContract),
            "Operator contract unapproved"
        );
        _;
    }

    constructor(KeepRegistry _registry) public {
        registry = _registry;
    }

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address);

    /// @notice Authorizes operator contract to access staked token balance of
    /// the provided operator. Can only be executed by stake operator authorizer.
    /// Contracts using delegated authority
    /// cannot be authorized with `authorizeOperatorContract`.
    /// Instead, authorize `getAuthoritySource(_operatorContract)`.
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    function authorizeOperatorContract(
        address _operator,
        address _operatorContract
    ) public onlyApprovedOperatorContract(_operatorContract) {
        require(
            authorizerOf(_operator) == msg.sender,
            "Not operator authorizer"
        );
        require(
            getAuthoritySource(_operatorContract) == _operatorContract,
            "Delegated authority used"
        );
        authorizations[_operatorContract][_operator] = true;
    }

    /// @notice Checks if operator contract has access to the staked token balance of
    /// the provided operator.
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    function isAuthorizedForOperator(
        address _operator,
        address _operatorContract
    ) public view returns (bool) {
        return authorizations[getAuthoritySource(_operatorContract)][_operator];
    }

    /// @notice Grant the sender the same authority as `delegatedAuthoritySource`
    /// @dev If `delegatedAuthoritySource` is an approved operator contract
    /// and recognizes the claimant, this relationship will be recorded in
    /// `delegatedAuthority`. Later, the claimant can slash, seize, place locks etc.
    /// on operators that have authorized the `delegatedAuthoritySource`.
    /// If the `delegatedAuthoritySource` is disabled with the panic button,
    /// any recipients of delegated authority from it will also be disabled.
    function claimDelegatedAuthority(address delegatedAuthoritySource)
        public
        onlyApprovedOperatorContract(delegatedAuthoritySource)
    {
        require(
            AuthorityDelegator(delegatedAuthoritySource).__isRecognized(
                msg.sender
            ),
            "Unrecognized claimant"
        );
        delegatedAuthority[msg.sender] = delegatedAuthoritySource;
    }

    /// @notice Checks if the operator contract is authorized in the registry.
    /// If the contract uses delegated authority it checks authorization of the
    /// source contract.
    /// @param _operatorContract address of operator contract.
    /// @return True if operator contract is approved, false if operator contract
    /// has not been approved or if it was disabled by the panic button.
    function isApprovedOperatorContract(address _operatorContract)
        public
        view
        returns (bool)
    {
        return
            registry.isApprovedOperatorContract(
                getAuthoritySource(_operatorContract)
            );
    }

    /// @notice Get the source of the operator contract's authority.
    /// If the contract uses delegated authority,
    /// returns the original source of the delegated authority.
    /// If the contract doesn't use delegated authority,
    /// returns the contract itself.
    /// Authorize `getAuthoritySource(operatorContract)`
    /// to grant `operatorContract` the authority to penalize an operator.
    function getAuthoritySource(address operatorContract)
        public
        view
        returns (address)
    {
        address delegatedAuthoritySource = delegatedAuthority[operatorContract];
        if (delegatedAuthoritySource == address(0)) {
            return operatorContract;
        }
        return getAuthoritySource(delegatedAuthoritySource);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "@keep-network/sortition-pools/contracts/api/IBonding.sol";

contract IBondingManagement is IBonding {
    /// @notice Add the provided value to operator's pool available for bonding.
    /// @param operator Address of the operator.
    function deposit(address operator) public payable;

    /// @notice Withdraws amount from operator's value available for bonding.
    /// @param amount Value to withdraw in wei.
    /// @param operator Address of the operator.
    function withdraw(uint256 amount, address operator) public;

    /// @notice Create bond for the given operator, holder, reference and amount.
    /// @param operator Address of the operator to bond.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID used to track the bond by holder.
    /// @param amount Value to bond in wei.
    /// @param authorizedSortitionPool Address of authorized sortition pool.
    function createBond(
        address operator,
        address holder,
        uint256 referenceID,
        uint256 amount,
        address authorizedSortitionPool
    ) public;

    /// @notice Returns value of wei bonded for the operator.
    /// @param operator Address of the operator.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID of the bond.
    /// @return Amount of wei in the selected bond.
    function bondAmount(
        address operator,
        address holder,
        uint256 referenceID
    ) public view returns (uint256);

    /// @notice Reassigns a bond to a new holder under a new reference.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param newHolder Address of the new holder of the bond.
    /// @param newReferenceID New reference ID to register the bond.
    function reassignBond(
        address operator,
        uint256 referenceID,
        address newHolder,
        uint256 newReferenceID
    ) public;

    /// @notice Releases the bond and moves the bond value to the operator's
    /// unbounded value pool.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    function freeBond(address operator, uint256 referenceID) public;

    /// @notice Seizes the bond by moving some or all of the locked bond to the
    /// provided destination address.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param amount Amount to be seized.
    /// @param destination Address to send the amount to.
    function seizeBond(
        address operator,
        uint256 referenceID,
        uint256 amount,
        address payable destination
    ) public;
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./api/IBondingManagement.sol";

import "@keep-network/keep-core/contracts/KeepRegistry.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @title Abstract Bonding
/// @notice Contract holding deposits from keeps' operators.
contract AbstractBonding is IBondingManagement {
    using SafeMath for uint256;

    // Registry contract with a list of approved factories (operator contracts).
    KeepRegistry internal registry;

    // Unassigned value in wei deposited by operators.
    mapping(address => uint256) public unbondedValue;

    // References to created bonds. Bond identifier is built from operator's
    // address, holder's address and reference ID assigned on bond creation.
    mapping(bytes32 => uint256) internal lockedBonds;

    // Sortition pools authorized by operator's authorizer.
    // operator -> pool -> boolean
    mapping(address => mapping(address => bool)) internal authorizedPools;

    event UnbondedValueDeposited(
        address indexed operator,
        address indexed beneficiary,
        uint256 amount
    );
    event UnbondedValueWithdrawn(
        address indexed operator,
        address indexed beneficiary,
        uint256 amount
    );
    event BondCreated(
        address indexed operator,
        address indexed holder,
        address indexed sortitionPool,
        uint256 referenceID,
        uint256 amount
    );
    event BondReassigned(
        address indexed operator,
        uint256 indexed referenceID,
        address newHolder,
        uint256 newReferenceID
    );
    event BondReleased(address indexed operator, uint256 indexed referenceID);
    event BondSeized(
        address indexed operator,
        uint256 indexed referenceID,
        address destination,
        uint256 amount
    );

    /// @notice Initializes Keep Bonding contract.
    /// @param registryAddress Keep registry contract address.
    constructor(address registryAddress) public {
        registry = KeepRegistry(registryAddress);
    }

    /// @notice Add the provided value to operator's pool available for bonding.
    /// @param operator Address of the operator.
    function deposit(address operator) public payable {
        address beneficiary = beneficiaryOf(operator);
        // Beneficiary has to be set (delegation exist) before an operator can
        // deposit wei. It protects from a situation when an operator wants
        // to withdraw funds which are transfered to beneficiary with zero
        // address.
        require(
            beneficiary != address(0),
            "Beneficiary not defined for the operator"
        );
        unbondedValue[operator] = unbondedValue[operator].add(msg.value);
        emit UnbondedValueDeposited(operator, beneficiary, msg.value);
    }

    /// @notice Withdraws amount from operator's value available for bonding.
    /// @param amount Value to withdraw in wei.
    /// @param operator Address of the operator.
    function withdraw(uint256 amount, address operator) public;

    /// @notice Returns the amount of wei the operator has made available for
    /// bonding and that is still unbounded. If the operator doesn't exist or
    /// bond creator is not authorized as an operator contract or it is not
    /// authorized by the operator or there is no secondary authorization for
    /// the provided sortition pool, function returns 0.
    /// @dev Implements function expected by sortition pools' IBonding interface.
    /// @param operator Address of the operator.
    /// @param bondCreator Address authorized to create a bond.
    /// @param authorizedSortitionPool Address of authorized sortition pool.
    /// @return Amount of authorized wei deposit available for bonding.
    function availableUnbondedValue(
        address operator,
        address bondCreator,
        address authorizedSortitionPool
    ) public view returns (uint256) {
        // Sortition pools check this condition and skips operators that
        // are no longer eligible. We cannot revert here.
        if (
            registry.isApprovedOperatorContract(bondCreator) &&
            isAuthorizedForOperator(operator, bondCreator) &&
            hasSecondaryAuthorization(operator, authorizedSortitionPool)
        ) {
            return unbondedValue[operator];
        }

        return 0;
    }

    /// @notice Create bond for the given operator, holder, reference and amount.
    /// @dev Function can be executed only by authorized contract. Reference ID
    /// should be unique for holder and operator.
    /// @param operator Address of the operator to bond.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID used to track the bond by holder.
    /// @param amount Value to bond in wei.
    /// @param authorizedSortitionPool Address of authorized sortition pool.
    function createBond(
        address operator,
        address holder,
        uint256 referenceID,
        uint256 amount,
        address authorizedSortitionPool
    ) public {
        require(
            availableUnbondedValue(
                operator,
                msg.sender,
                authorizedSortitionPool
            ) >= amount,
            "Insufficient unbonded value"
        );

        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(
            lockedBonds[bondID] == 0,
            "Reference ID not unique for holder and operator"
        );

        unbondedValue[operator] = unbondedValue[operator].sub(amount);
        lockedBonds[bondID] = lockedBonds[bondID].add(amount);

        emit BondCreated(
            operator,
            holder,
            authorizedSortitionPool,
            referenceID,
            amount
        );
    }

    /// @notice Returns value of wei bonded for the operator.
    /// @param operator Address of the operator.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID of the bond.
    /// @return Amount of wei in the selected bond.
    function bondAmount(
        address operator,
        address holder,
        uint256 referenceID
    ) public view returns (uint256) {
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        return lockedBonds[bondID];
    }

    /// @notice Reassigns a bond to a new holder under a new reference.
    /// @dev Function requires that a caller is the current holder of the bond
    /// which is being reassigned.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param newHolder Address of the new holder of the bond.
    /// @param newReferenceID New reference ID to register the bond.
    function reassignBond(
        address operator,
        uint256 referenceID,
        address newHolder,
        uint256 newReferenceID
    ) public {
        address holder = msg.sender;
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(lockedBonds[bondID] > 0, "Bond not found");

        bytes32 newBondID =
            keccak256(abi.encodePacked(operator, newHolder, newReferenceID));

        require(
            lockedBonds[newBondID] == 0,
            "Reference ID not unique for holder and operator"
        );

        lockedBonds[newBondID] = lockedBonds[bondID];
        lockedBonds[bondID] = 0;

        emit BondReassigned(operator, referenceID, newHolder, newReferenceID);
    }

    /// @notice Releases the bond and moves the bond value to the operator's
    /// unbounded value pool.
    /// @dev Function requires that caller is the holder of the bond which is
    /// being released.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    function freeBond(address operator, uint256 referenceID) public {
        address holder = msg.sender;
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(lockedBonds[bondID] > 0, "Bond not found");

        uint256 amount = lockedBonds[bondID];
        lockedBonds[bondID] = 0;
        unbondedValue[operator] = unbondedValue[operator].add(amount);

        emit BondReleased(operator, referenceID);
    }

    /// @notice Seizes the bond by moving some or all of the locked bond to the
    /// provided destination address.
    /// @dev Function requires that a caller is the holder of the bond which is
    /// being seized.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param amount Amount to be seized.
    /// @param destination Address to send the amount to.
    function seizeBond(
        address operator,
        uint256 referenceID,
        uint256 amount,
        address payable destination
    ) public {
        require(amount > 0, "Requested amount should be greater than zero");

        address payable holder = msg.sender;
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(
            lockedBonds[bondID] >= amount,
            "Requested amount is greater than the bond"
        );

        lockedBonds[bondID] = lockedBonds[bondID].sub(amount);

        (bool success, ) = destination.call.value(amount)("");
        require(success, "Transfer failed");

        emit BondSeized(operator, referenceID, destination, amount);
    }

    /// @notice Authorizes sortition pool for the provided operator.
    /// Operator's authorizers need to authorize individual sortition pools
    /// per application since they may be interested in participating only in
    /// a subset of keep types used by the given application.
    /// @dev Only operator's authorizer can call this function.
    function authorizeSortitionPoolContract(
        address _operator,
        address _poolAddress
    ) public {
        require(authorizerOf(_operator) == msg.sender, "Not authorized");
        authorizedPools[_operator][_poolAddress] = true;
    }

    /// @notice Deauthorizes sortition pool for the provided operator.
    /// Authorizer may deauthorize individual sortition pool in case the
    /// operator should no longer be eligible for work selection and the
    /// application represented by the sortition pool should no longer be
    /// eligible to create bonds for the operator.
    /// @dev Only operator's authorizer can call this function.
    function deauthorizeSortitionPoolContract(
        address _operator,
        address _poolAddress
    ) public {
        require(authorizerOf(_operator) == msg.sender, "Not authorized");
        authorizedPools[_operator][_poolAddress] = false;
    }

    /// @notice Checks if the sortition pool has been authorized for the
    /// provided operator by its authorizer.
    /// @dev See authorizeSortitionPoolContract.
    function hasSecondaryAuthorization(address _operator, address _poolAddress)
        public
        view
        returns (bool)
    {
        return authorizedPools[_operator][_poolAddress];
    }

    /// @notice Checks if operator contract has been authorized for the provided
    /// operator.
    /// @param _operator Operator address.
    /// @param _operatorContract Address of the operator contract.
    function isAuthorizedForOperator(
        address _operator,
        address _operatorContract
    ) public view returns (bool);

    /// @notice Gets the authorizer for the specified operator address.
    /// @param _operator Operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address);

    /// @notice Gets the beneficiary for the specified operator address.
    /// @param _operator Operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _operator)
        public
        view
        returns (address payable);

    /// @notice Withdraws the provided amount from unbonded value of the
    /// provided operator to operator's beneficiary. If there is no enough
    /// unbonded value or the transfer failed, function fails.
    function withdrawBond(uint256 amount, address operator) internal {
        require(
            unbondedValue[operator] >= amount,
            "Insufficient unbonded value"
        );

        unbondedValue[operator] = unbondedValue[operator].sub(amount);

        address beneficiary = beneficiaryOf(operator);

        (bool success, ) = beneficiary.call.value(amount)("");
        require(success, "Transfer failed");

        emit UnbondedValueWithdrawn(operator, beneficiary, amount);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}