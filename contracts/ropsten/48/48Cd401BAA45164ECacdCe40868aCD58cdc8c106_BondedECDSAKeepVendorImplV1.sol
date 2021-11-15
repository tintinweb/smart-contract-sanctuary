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

import "./api/IBondedECDSAKeepVendor.sol";

import "@keep-network/keep-core/contracts/KeepRegistry.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @title Bonded ECDSA Keep Vendor
/// @notice The contract is used to obtain a new Bonded ECDSA keep factory.
contract BondedECDSAKeepVendorImplV1 is IBondedECDSAKeepVendor {
    using SafeMath for uint256;

    // Mapping to store new implementation versions that inherit from
    // this contract.
    mapping(string => bool) internal _initialized;

    // KeepRegistry contract with a list of approved factories (operator contracts)
    // and upgraders.
    KeepRegistry internal registry;

    // Upgrade time delay defines a waiting period for factory address upgrade.
    // When new factory upgrade is initialized it has to wait this period
    // before the change can take effect on the currently registered facotry
    // address.
    uint256 public factoryUpgradeTimeDelay;

    // Address of ECDSA keep factory.
    address payable keepFactory;

    // Address of a new ECDSA keep factory in update process.
    address payable newKeepFactory;

    // Timestamp of the moment when factory upgrade process has started.
    uint256 factoryUpgradeInitiatedTimestamp;

    event FactoryUpgradeStarted(address factory, uint256 timestamp);
    event FactoryUpgradeCompleted(address factory);

    constructor() public {
        // Mark as already initialized to block the direct usage of the contract
        // after deployment. The contract is intended to be called via proxy, so
        // setting this value will not affect the clones usage.
        _initialized["BondedECDSAKeepVendorImplV1"] = true;
    }

    /// @notice Initializes Keep Vendor contract implementation.
    /// @param registryAddress Keep registry contract linked to this contract.
    /// @param factory Keep factory contract registered initially in the vendor
    /// contract.
    function initialize(address registryAddress, address payable factory)
        public
    {
        require(registryAddress != address(0), "Incorrect registry address");
        require(factory != address(0), "Incorrect factory address");

        require(!initialized(), "Contract is already initialized.");
        _initialized["BondedECDSAKeepVendorImplV1"] = true;

        registry = KeepRegistry(registryAddress);
        keepFactory = factory;

        factoryUpgradeTimeDelay = 1 days;
    }

    /// @notice Checks if this contract is initialized.
    function initialized() public view returns (bool) {
        return _initialized["BondedECDSAKeepVendorImplV1"];
    }

    /// @notice Starts new ECDSA keep factory upgrade.
    /// @dev Registers a new ECDSA keep factory. Address cannot be zero
    /// and cannot be the same that is currently registered. It is a first part
    /// of the two-step factory upgrade process. The function emits an event
    /// containing the new factory address and current block timestamp.
    /// @param _factory ECDSA keep factory address.
    function upgradeFactory(address payable _factory)
        public
        onlyOperatorContractUpgrader
    {
        require(_factory != address(0), "Incorrect factory address");

        if (isUpgradeInitiated()) {
            require(
                newKeepFactory != _factory,
                "Factory upgrade already initiated"
            );
        } else {
            require(keepFactory != _factory, "Factory already registered");
        }

        require(
            registry.isApprovedOperatorContract(_factory),
            "Factory contract is not approved"
        );

        newKeepFactory = _factory;

        /* solium-disable-next-line security/no-block-members */
        uint256 timestamp = block.timestamp;

        factoryUpgradeInitiatedTimestamp = timestamp;

        emit FactoryUpgradeStarted(_factory, timestamp);
    }

    /// @notice Finalizes ECDSA keep factory upgrade.
    /// @dev It is the second part of the two-step factory upgrade process.
    /// The function can be called after factory upgrade time delay period
    /// has passed since the new factory upgrade. It emits an event
    /// containing the new factory address.
    function completeFactoryUpgrade() public {
        require(isUpgradeInitiated(), "Upgrade not initiated");

        require(
            /* solium-disable-next-line security/no-block-members */
            block.timestamp.sub(factoryUpgradeInitiatedTimestamp) >=
                factoryUpgradeTimeDelay,
            "Timer not elapsed"
        );

        keepFactory = newKeepFactory;
        newKeepFactory = address(0);
        factoryUpgradeInitiatedTimestamp = 0;

        emit FactoryUpgradeCompleted(keepFactory);
    }

    /// @notice Selects the latest ECDSA keep factory.
    /// @return ECDSA keep factory address.
    function selectFactory() public view returns (address payable) {
        require(keepFactory != address(0), "Keep factory is not registered");
        return keepFactory;
    }

    function isUpgradeInitiated() internal view returns (bool) {
        return factoryUpgradeInitiatedTimestamp > 0;
    }

    /// @dev Throws if called by any account other than the operator contract
    /// upgrader authorized for this service contract.
    modifier onlyOperatorContractUpgrader() {
        require(
            address(registry) != address(0),
            "KeepRegistry address is not registered"
        );

        address operatorContractUpgrader =
            registry.operatorContractUpgraderFor(address(this));
        require(
            operatorContractUpgrader == msg.sender,
            "Caller is not operator contract upgrader"
        );
        _;
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

/// @title ECDSA Keep Vendor
/// @notice Contract reflecting an ECDSA keep vendor.
contract IBondedECDSAKeepVendor {
    /// @notice Select a recommended ECDSA keep factory from all registered
    /// ECDSA keep factories.
    /// @return Selected ECDSA keep factory address.
    function selectFactory() public view returns (address payable);
}

