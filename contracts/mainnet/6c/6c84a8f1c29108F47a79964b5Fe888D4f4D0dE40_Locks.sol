{{
  "language": "Solidity",
  "sources": {
    "solidity/contracts/libraries/staking/Locks.sol": {
      "content": "pragma solidity 0.5.17;\n\nimport \"openzeppelin-solidity/contracts/math/SafeMath.sol\";\nimport { AuthorityVerifier } from \"../../Authorizations.sol\";\nimport \"./LockUtils.sol\";\n\nlibrary Locks {\n    using SafeMath for uint256;\n    using LockUtils for LockUtils.LockSet;\n\n    event StakeLocked(address indexed operator, address lockCreator, uint256 until);\n    event LockReleased(address indexed operator, address lockCreator);\n    event ExpiredLockReleased(address indexed operator, address lockCreator);\n\n    uint256 public constant maximumLockDuration = 86400 * 200; // 200 days in seconds\n\n    struct Storage {\n        // Locks placed on the operator.\n        // `operatorLocks[operator]` returns all locks placed on the operator.\n        // Each authorized operator contract can place one lock on an operator.\n        mapping(address => LockUtils.LockSet) operatorLocks;\n    }\n\n    function lockStake(\n        Storage storage self,\n        address operator,\n        uint256 duration\n    ) public {\n        require(duration <= maximumLockDuration, \"Lock duration too long\");\n        self.operatorLocks[operator].setLock(\n            msg.sender,\n            uint96(block.timestamp.add(duration))\n        );\n        emit StakeLocked(operator, msg.sender, block.timestamp.add(duration));\n    }\n\n    function releaseLock(\n        Storage storage self,\n        address operator\n    ) public {\n        self.operatorLocks[operator].releaseLock(msg.sender);\n        emit LockReleased(operator, msg.sender);\n    }\n\n    function releaseExpiredLock(\n        Storage storage self,\n        address operator,\n        address operatorContract,\n        address authorityVerifier\n    ) public {\n        LockUtils.LockSet storage locks = self.operatorLocks[operator];\n\n        require(\n            locks.contains(operatorContract),\n            \"No matching lock present\"\n        );\n\n        bool expired = block.timestamp >= locks.getLockTime(operatorContract);\n        bool disabled = !AuthorityVerifier(authorityVerifier)\n            .isApprovedOperatorContract(operatorContract);\n\n        require(\n            expired || disabled,\n            \"Lock still active and valid\"\n        );\n\n        locks.releaseLock(operatorContract);\n\n        emit ExpiredLockReleased(operator, operatorContract);\n    }\n\n    /// @dev AuthorityVerifier is a trusted implementation and not a third-party,\n    /// external contract. AuthorityVerifier never reverts on the check and\n    /// has a reasonable gas consumption.\n    function isStakeLocked(\n        Storage storage self,\n        address operator,\n        address authorityVerifier\n    ) public view returns (bool) {\n        LockUtils.Lock[] storage _locks = self.operatorLocks[operator].locks;\n        LockUtils.Lock memory lock;\n        for (uint i = 0; i < _locks.length; i++) {\n            lock = _locks[i];\n            if (block.timestamp < lock.expiresAt) {\n                if (\n                    AuthorityVerifier(authorityVerifier)\n                        .isApprovedOperatorContract(lock.creator)\n                ) {\n                    return true;\n                }\n            }\n        }\n        return false;\n    }\n\n    function isStakeReleased(\n        Storage storage self,\n        address operator,\n        address operatorContract\n    ) public view returns (bool) {\n        LockUtils.LockSet storage locks = self.operatorLocks[operator];\n        // `getLockTime` returns 0 if the lock doesn't exist,\n        // thus we don't need to check for its presence separately.\n        return block.timestamp >= locks.getLockTime(operatorContract);\n    }\n\n    function getLocks(\n        Storage storage self,\n        address operator\n    ) public view returns (address[] memory creators, uint256[] memory expirations) {\n        uint256 lockCount = self.operatorLocks[operator].locks.length;\n        creators = new address[](lockCount);\n        expirations = new uint256[](lockCount);\n        LockUtils.Lock memory lock;\n        for (uint i = 0; i < lockCount; i++) {\n            lock = self.operatorLocks[operator].locks[i];\n            creators[i] = lock.creator;\n            expirations[i] = lock.expiresAt;\n        }\n    }\n} \n"
    },
    "solidity/contracts/Authorizations.sol": {
      "content": "/**\n▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄\n▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓\n  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓\n  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀\n  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌\n▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓\n▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓\n\n                           Trust math, not hardware.\n*/\n\npragma solidity 0.5.17;\n\nimport \"./KeepRegistry.sol\";\n\n/// @title AuthorityDelegator\n/// @notice An operator contract can delegate authority to other operator\n/// contracts by implementing the AuthorityDelegator interface.\n///\n/// To delegate authority,\n/// the recipient of delegated authority must call `claimDelegatedAuthority`,\n/// specifying the contract it wants delegated authority from.\n/// The staking contract calls `delegator.__isRecognized(recipient)`\n/// and if the call returns `true`,\n/// the named delegator contract is set as the recipient's authority delegator.\n/// Any future checks of registry approval or per-operator authorization\n/// will transparently mirror the delegator's status.\n///\n/// Authority can be delegated recursively;\n/// an operator contract receiving delegated authority\n/// can recognize other operator contracts as recipients of its authority.\ninterface AuthorityDelegator {\n    function __isRecognized(address delegatedAuthorityRecipient) external returns (bool);\n}\n\n/// @title AuthorityVerifier\n/// @notice An operator contract can delegate authority to other operator\n/// contracts. Entry in the registry is not updated and source contract remains\n/// listed there as authorized. This interface is a verifier that support verification\n/// of contract authorization in case of authority delegation from the source contract.\ninterface AuthorityVerifier {\n    /// @notice Returns true if the given operator contract has been approved\n    /// for use. The function never reverts.\n    function isApprovedOperatorContract(address _operatorContract)\n        external\n        view\n        returns (bool);\n}\n\ncontract Authorizations is AuthorityVerifier {\n    // Authorized operator contracts.\n    mapping(address => mapping (address => bool)) internal authorizations;\n\n    // Granters of delegated authority to operator contracts.\n    // E.g. keep factories granting delegated authority to keeps.\n    // `delegatedAuthority[keep] = factory`\n    mapping(address => address) internal delegatedAuthority;\n\n    // Registry contract with a list of approved operator contracts and upgraders.\n    KeepRegistry internal registry;\n\n    modifier onlyApprovedOperatorContract(address operatorContract) {\n        require(\n            isApprovedOperatorContract(operatorContract),\n            \"Operator contract unapproved\"\n        );\n        _;\n    }\n\n    constructor(KeepRegistry _registry) public {\n        registry = _registry;\n    }\n\n    /// @notice Gets the authorizer for the specified operator address.\n    /// @return Authorizer address.\n    function authorizerOf(address _operator) public view returns (address);\n\n    /// @notice Authorizes operator contract to access staked token balance of\n    /// the provided operator. Can only be executed by stake operator authorizer.\n    /// Contracts using delegated authority\n    /// cannot be authorized with `authorizeOperatorContract`.\n    /// Instead, authorize `getAuthoritySource(_operatorContract)`.\n    /// @param _operator address of stake operator.\n    /// @param _operatorContract address of operator contract.\n    function authorizeOperatorContract(address _operator, address _operatorContract)\n        public\n        onlyApprovedOperatorContract(_operatorContract) {\n        require(\n            authorizerOf(_operator) == msg.sender,\n            \"Not operator authorizer\"\n        );\n        require(\n            getAuthoritySource(_operatorContract) == _operatorContract,\n            \"Delegated authority used\"\n        );\n        authorizations[_operatorContract][_operator] = true;\n    }\n\n    /// @notice Checks if operator contract has access to the staked token balance of\n    /// the provided operator.\n    /// @param _operator address of stake operator.\n    /// @param _operatorContract address of operator contract.\n    function isAuthorizedForOperator(\n        address _operator,\n        address _operatorContract\n    ) public view returns (bool) {\n        return authorizations[getAuthoritySource(_operatorContract)][_operator];\n    }\n\n    /// @notice Grant the sender the same authority as `delegatedAuthoritySource`\n    /// @dev If `delegatedAuthoritySource` is an approved operator contract\n    /// and recognizes the claimant, this relationship will be recorded in\n    /// `delegatedAuthority`. Later, the claimant can slash, seize, place locks etc.\n    /// on operators that have authorized the `delegatedAuthoritySource`.\n    /// If the `delegatedAuthoritySource` is disabled with the panic button,\n    /// any recipients of delegated authority from it will also be disabled.\n    function claimDelegatedAuthority(\n        address delegatedAuthoritySource\n    ) public onlyApprovedOperatorContract(delegatedAuthoritySource) {\n        require(\n            AuthorityDelegator(delegatedAuthoritySource).__isRecognized(msg.sender),\n            \"Unrecognized claimant\"\n        );\n        delegatedAuthority[msg.sender] = delegatedAuthoritySource;\n    }\n\n    /// @notice Checks if the operator contract is authorized in the registry.\n    /// If the contract uses delegated authority it checks authorization of the\n    /// source contract.\n    /// @param _operatorContract address of operator contract.\n    /// @return True if operator contract is approved, false if operator contract\n    /// has not been approved or if it was disabled by the panic button.\n    function isApprovedOperatorContract(address _operatorContract)\n        public\n        view\n        returns (bool)\n    {\n        return\n            registry.isApprovedOperatorContract(\n                getAuthoritySource(_operatorContract)\n            );\n    }\n\n    /// @notice Get the source of the operator contract's authority.\n    /// If the contract uses delegated authority,\n    /// returns the original source of the delegated authority.\n    /// If the contract doesn't use delegated authority,\n    /// returns the contract itself.\n    /// Authorize `getAuthoritySource(operatorContract)`\n    /// to grant `operatorContract` the authority to penalize an operator.\n    function getAuthoritySource(\n        address operatorContract\n    ) public view returns (address) {\n        address delegatedAuthoritySource = delegatedAuthority[operatorContract];\n        if (delegatedAuthoritySource == address(0)) {\n            return operatorContract;\n        }\n        return getAuthoritySource(delegatedAuthoritySource);\n    }\n}\n"
    },
    "solidity/contracts/KeepRegistry.sol": {
      "content": "pragma solidity 0.5.17;\n\n\n/// @title KeepRegistry\n/// @notice Governance owned registry of approved contracts and roles.\ncontract KeepRegistry {\n    enum ContractStatus {New, Approved, Disabled}\n\n    // Governance role is to enable recovery from key compromise by rekeying\n    // other roles. Also, it can disable operator contract panic buttons\n    // permanently.\n    address public governance;\n\n    // Registry Keeper maintains approved operator contracts. Each operator\n    // contract must be approved before it can be authorized by a staker or\n    // used by a service contract.\n    address public registryKeeper;\n\n    // Each operator contract has a Panic Button which can disable malicious\n    // or malfunctioning contract that have been previously approved by the\n    // Registry Keeper.\n    //\n    // New operator contract added to the registry has a default panic button\n    // value assigned (defaultPanicButton). Panic button for each operator\n    // contract can be later updated by Governance to individual value.\n    //\n    // It is possible to disable panic button for individual contract by\n    // setting the panic button to zero address. In such case, operator contract\n    // can not be disabled and is permanently approved in the registry.\n    mapping(address => address) public panicButtons;\n\n    // Default panic button for each new operator contract added to the\n    // registry. Can be later updated for each contract.\n    address public defaultPanicButton;\n\n    // Each service contract has a Operator Contract Upgrader whose purpose\n    // is to manage operator contracts for that specific service contract.\n    // The Operator Contract Upgrader can add new operator contracts to the\n    // service contract’s operator contract list, and deprecate old ones.\n    mapping(address => address) public operatorContractUpgraders;\n\n    // Operator contract may have a Service Contract Upgrader whose purpose is\n    // to manage service contracts for that specific operator contract.\n    // Service Contract Upgrader can add and remove service contracts\n    // from the list of service contracts approved to work with the operator\n    // contract. List of service contracts is maintained in the operator\n    // contract and is optional - not every operator contract needs to have\n    // a list of service contracts it wants to cooperate with.\n    mapping(address => address) public serviceContractUpgraders;\n\n    // The registry of operator contracts\n    mapping(address => ContractStatus) public operatorContracts;\n\n    event OperatorContractApproved(address operatorContract);\n    event OperatorContractDisabled(address operatorContract);\n\n    event GovernanceUpdated(address governance);\n    event RegistryKeeperUpdated(address registryKeeper);\n    event DefaultPanicButtonUpdated(address defaultPanicButton);\n    event OperatorContractPanicButtonDisabled(address operatorContract);\n    event OperatorContractPanicButtonUpdated(\n        address operatorContract,\n        address panicButton\n    );\n    event OperatorContractUpgraderUpdated(\n        address serviceContract,\n        address upgrader\n    );\n    event ServiceContractUpgraderUpdated(\n        address operatorContract,\n        address keeper\n    );\n\n    modifier onlyGovernance() {\n        require(governance == msg.sender, \"Not authorized\");\n        _;\n    }\n\n    modifier onlyRegistryKeeper() {\n        require(registryKeeper == msg.sender, \"Not authorized\");\n        _;\n    }\n\n    modifier onlyPanicButton(address _operatorContract) {\n        address panicButton = panicButtons[_operatorContract];\n        require(panicButton != address(0), \"Panic button disabled\");\n        require(panicButton == msg.sender, \"Not authorized\");\n        _;\n    }\n\n    modifier onlyForNewContract(address _operatorContract) {\n        require(\n            isNewOperatorContract(_operatorContract),\n            \"Not a new operator contract\"\n        );\n        _;\n    }\n\n    modifier onlyForApprovedContract(address _operatorContract) {\n        require(\n            isApprovedOperatorContract(_operatorContract),\n            \"Not an approved operator contract\"\n        );\n        _;\n    }\n\n    constructor() public {\n        governance = msg.sender;\n        registryKeeper = msg.sender;\n        defaultPanicButton = msg.sender;\n    }\n\n    function setGovernance(address _governance) public onlyGovernance {\n        governance = _governance;\n        emit GovernanceUpdated(governance);\n    }\n\n    function setRegistryKeeper(address _registryKeeper) public onlyGovernance {\n        registryKeeper = _registryKeeper;\n        emit RegistryKeeperUpdated(registryKeeper);\n    }\n\n    function setDefaultPanicButton(address _panicButton) public onlyGovernance {\n        defaultPanicButton = _panicButton;\n        emit DefaultPanicButtonUpdated(defaultPanicButton);\n    }\n\n    function setOperatorContractPanicButton(\n        address _operatorContract,\n        address _panicButton\n    ) public onlyForApprovedContract(_operatorContract) onlyGovernance {\n        require(\n            panicButtons[_operatorContract] != address(0),\n            \"Disabled panic button cannot be updated\"\n        );\n        require(\n            _panicButton != address(0),\n            \"Panic button must be non-zero address\"\n        );\n\n        panicButtons[_operatorContract] = _panicButton;\n\n        emit OperatorContractPanicButtonUpdated(\n            _operatorContract,\n            _panicButton\n        );\n    }\n\n    function disableOperatorContractPanicButton(address _operatorContract)\n        public\n        onlyForApprovedContract(_operatorContract)\n        onlyGovernance\n    {\n        require(\n            panicButtons[_operatorContract] != address(0),\n            \"Panic button already disabled\"\n        );\n\n        panicButtons[_operatorContract] = address(0);\n\n        emit OperatorContractPanicButtonDisabled(_operatorContract);\n    }\n\n    function setOperatorContractUpgrader(\n        address _serviceContract,\n        address _operatorContractUpgrader\n    ) public onlyGovernance {\n        operatorContractUpgraders[_serviceContract] = _operatorContractUpgrader;\n        emit OperatorContractUpgraderUpdated(\n            _serviceContract,\n            _operatorContractUpgrader\n        );\n    }\n\n    function setServiceContractUpgrader(\n        address _operatorContract,\n        address _serviceContractUpgrader\n    ) public onlyGovernance {\n        serviceContractUpgraders[_operatorContract] = _serviceContractUpgrader;\n        emit ServiceContractUpgraderUpdated(\n            _operatorContract,\n            _serviceContractUpgrader\n        );\n    }\n\n    function approveOperatorContract(address operatorContract)\n        public\n        onlyForNewContract(operatorContract)\n        onlyRegistryKeeper\n    {\n        operatorContracts[operatorContract] = ContractStatus.Approved;\n        panicButtons[operatorContract] = defaultPanicButton;\n        emit OperatorContractApproved(operatorContract);\n    }\n\n    function disableOperatorContract(address operatorContract)\n        public\n        onlyForApprovedContract(operatorContract)\n        onlyPanicButton(operatorContract)\n    {\n        operatorContracts[operatorContract] = ContractStatus.Disabled;\n        emit OperatorContractDisabled(operatorContract);\n    }\n\n    function isNewOperatorContract(address operatorContract)\n        public\n        view\n        returns (bool)\n    {\n        return operatorContracts[operatorContract] == ContractStatus.New;\n    }\n\n    function isApprovedOperatorContract(address operatorContract)\n        public\n        view\n        returns (bool)\n    {\n        return operatorContracts[operatorContract] == ContractStatus.Approved;\n    }\n\n    function operatorContractUpgraderFor(address _serviceContract)\n        public\n        view\n        returns (address)\n    {\n        return operatorContractUpgraders[_serviceContract];\n    }\n\n    function serviceContractUpgraderFor(address _operatorContract)\n        public\n        view\n        returns (address)\n    {\n        return serviceContractUpgraders[_operatorContract];\n    }\n}\n"
    },
    "solidity/contracts/libraries/staking/LockUtils.sol": {
      "content": "pragma solidity 0.5.17;\n\nlibrary LockUtils {\n    struct Lock {\n        address creator;\n        uint96 expiresAt;\n    }\n\n    /// @notice The LockSet is like an array of unique `uint256`s,\n    /// but additionally supports O(1) membership tests and removals.\n    /// @dev Because the LockSet relies on a mapping,\n    /// it can only be used in storage, not in memory.\n    struct LockSet {\n        // locks[positions[lock.creator] - 1] = lock\n        Lock[] locks;\n        mapping(address => uint256) positions;\n    }\n\n    /// @notice Check whether the LockSet `self` contains a lock by `creator`\n    function contains(LockSet storage self, address creator)\n        internal view returns (bool) {\n        return (self.positions[creator] != 0);\n    }\n\n    function getLockTime(LockSet storage self, address creator)\n        internal view returns (uint96) {\n        uint256 positionPlusOne = self.positions[creator];\n        if (positionPlusOne == 0) { return 0; }\n        return self.locks[positionPlusOne - 1].expiresAt;\n    }\n\n    /// @notice Set the lock of `creator` to `expiresAt`,\n    /// overriding the current value if any.\n    function setLock(\n        LockSet storage self,\n        address _creator,\n        uint96 _expiresAt\n    ) internal {\n        uint256 positionPlusOne = self.positions[_creator];\n        Lock memory lock = Lock(_creator, _expiresAt);\n        // No existing lock\n        if (positionPlusOne == 0) {\n            self.locks.push(lock);\n            self.positions[_creator] = self.locks.length;\n        // Existing lock present\n        } else {\n            self.locks[positionPlusOne - 1].expiresAt = _expiresAt;\n        }\n    }\n\n    /// @notice Remove the lock of `creator`.\n    /// If no lock present, do nothing.\n    function releaseLock(\n        LockSet storage self,\n        address _creator\n    ) internal {\n        uint256 positionPlusOne = self.positions[_creator];\n        if (positionPlusOne != 0) {\n            uint256 lockCount = self.locks.length;\n            if (positionPlusOne != lockCount) {\n                // Not the last lock,\n                // so we need to move the last lock into the emptied position.\n                Lock memory lastLock = self.locks[lockCount - 1];\n                self.locks[positionPlusOne - 1] = lastLock;\n                self.positions[lastLock.creator] = positionPlusOne;\n            }\n            self.locks.length--;\n            self.positions[_creator] = 0;\n        }\n    }\n\n    /// @notice Return the locks of the LockSet `self`.\n    function enumerate(LockSet storage self)\n        internal view returns (Lock[] memory) {\n        return self.locks;\n    }\n}\n"
    },
    "openzeppelin-solidity/contracts/math/SafeMath.sol": {
      "content": "pragma solidity ^0.5.0;\n\n/**\n * @dev Wrappers over Solidity's arithmetic operations with added overflow\n * checks.\n *\n * Arithmetic operations in Solidity wrap on overflow. This can easily result\n * in bugs, because programmers usually assume that an overflow raises an\n * error, which is the standard behavior in high level programming languages.\n * `SafeMath` restores this intuition by reverting the transaction when an\n * operation overflows.\n *\n * Using this library instead of the unchecked operations eliminates an entire\n * class of bugs, so it's recommended to use it always.\n */\nlibrary SafeMath {\n    /**\n     * @dev Returns the addition of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `+` operator.\n     *\n     * Requirements:\n     * - Addition cannot overflow.\n     */\n    function add(uint256 a, uint256 b) internal pure returns (uint256) {\n        uint256 c = a + b;\n        require(c >= a, \"SafeMath: addition overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity's `-` operator.\n     *\n     * Requirements:\n     * - Subtraction cannot overflow.\n     */\n    function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n        return sub(a, b, \"SafeMath: subtraction overflow\");\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity's `-` operator.\n     *\n     * Requirements:\n     * - Subtraction cannot overflow.\n     *\n     * _Available since v2.4.0._\n     */\n    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b <= a, errorMessage);\n        uint256 c = a - b;\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the multiplication of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `*` operator.\n     *\n     * Requirements:\n     * - Multiplication cannot overflow.\n     */\n    function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the\n        // benefit is lost if 'b' is also tested.\n        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522\n        if (a == 0) {\n            return 0;\n        }\n\n        uint256 c = a * b;\n        require(c / a == b, \"SafeMath: multiplication overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity's `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     */\n    function div(uint256 a, uint256 b) internal pure returns (uint256) {\n        return div(a, b, \"SafeMath: division by zero\");\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity's `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     *\n     * _Available since v2.4.0._\n     */\n    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        // Solidity only automatically asserts when dividing by 0\n        require(b > 0, errorMessage);\n        uint256 c = a / b;\n        // assert(a == b * c + a % b); // There is no case in which this doesn't hold\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts when dividing by zero.\n     *\n     * Counterpart to Solidity's `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     */\n    function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n        return mod(a, b, \"SafeMath: modulo by zero\");\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts with custom message when dividing by zero.\n     *\n     * Counterpart to Solidity's `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     *\n     * _Available since v2.4.0._\n     */\n    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b != 0, errorMessage);\n        return a % b;\n    }\n}\n"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}}