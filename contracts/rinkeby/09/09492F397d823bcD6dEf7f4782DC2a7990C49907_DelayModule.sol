// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface Executor {
    /// @dev Allows a Module to execute a transaction.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);
}

contract DelayModule {
    event DelayModuleSetup(address indexed initiator, address indexed safe);
    event TransactionAdded(
        uint256 indexed queueNonce,
        bytes32 indexed txHash,
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation
    );

    event EnabledModule(address module);
    event DisabledModule(address module);

    address internal constant SENTINEL_MODULES = address(0x1);

    Executor public executor;
    uint256 public txCooldown;
    uint256 public txExpiration;
    uint256 public txNonce;
    uint256 public queueNonce;
    // Mapping of queue nonce to transaction hash.
    mapping(uint256 => bytes32) public txHash;
    // Mapping of queue nonce to creation timestamp.
    mapping(uint256 => uint256) public txCreatedAt;
    // Mapping of modules
    mapping(address => address) internal modules;

    constructor(
        Executor _executor,
        uint256 cooldown,
        uint256 expiration
    ) {
        setUp(_executor, cooldown, expiration);
    }

    /// @param _executor Address of the executor (e.g. a Safe)
    /// @param cooldown Cooldown in seconds that should be required after a transaction is proposed
    /// @param expiration Duration that a proposed transaction is valid for after the cooldown, in seconds (or 0 if valid forever)
    /// @notice There need to be at least 60 seconds between end of cooldown and expiration
    function setUp(
        Executor _executor,
        uint256 cooldown,
        uint256 expiration
    ) public {
        require(
            address(executor) == address(0),
            "Module is already initialized"
        );
        require(
            expiration == 0 || expiration >= 60,
            "Expiratition must be 0 or at least 60 seconds"
        );
        if (address(_executor) != address(0)) setupModules();

        executor = _executor;
        txExpiration = expiration;
        txCooldown = cooldown;

        emit DelayModuleSetup(msg.sender, address(_executor));
    }

    modifier executorOnly() {
        require(msg.sender == address(executor), "Not authorized");
        _;
    }

    modifier moduleOnly() {
        require(modules[msg.sender] != address(0), "Module not authorized");
        _;
    }

    function setupModules() internal {
        require(
            modules[SENTINEL_MODULES] == address(0),
            "setUpModules has already been called"
        );
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }

    /// @dev Disables a module that can add transactions to the queue
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed
    /// @notice This can only be called by the executor
    function disableModule(address prevModule, address module)
        public
        executorOnly()
    {
        require(
            module != address(0) && module != SENTINEL_MODULES,
            "Invalid module"
        );
        require(modules[prevModule] == module, "Module already disabled");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Enables a module that can add transactions to the queue
    /// @param module Address of the module to be enabled
    /// @notice This can only be called by the executor
    function enableModule(address module) public executorOnly() {
        require(
            module != address(0) && module != SENTINEL_MODULES,
            "Invalid module"
        );
        require(modules[module] == address(0), "Module already enabled");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Sets the cooldown before a transaction can be executed.
    /// @param cooldown Cooldown in seconds that should be required before the transaction can be executed
    /// @notice This can only be called by the executor
    function setTxCooldown(uint256 cooldown) public executorOnly() {
        txCooldown = cooldown;
    }

    /// @dev Sets the duration for which a transaction is valid.
    /// @param expiration Duration that a transaction is valid in seconds (or 0 if valid forever) after the cooldown
    /// @notice There need to be at least 60 seconds between end of cooldown and expiration
    /// @notice This can only be called by the executor
    function setTxExpiration(uint256 expiration) public executorOnly() {
        require(
            expiration == 0 || expiration >= 60,
            "Expiratition must be 0 or at least 60 seconds"
        );
        txExpiration = expiration;
    }

    /// @dev Sets transaction nonce. Used to invalidate or skip transactions in queue.
    /// @param _nonce New transaction nonce
    /// @notice This can only be called by the executor
    function setTxNonce(uint256 _nonce) public executorOnly() {
        require(
            _nonce > txNonce,
            "New nonce must be higher than current txNonce"
        );
        require(_nonce <= queueNonce, "Cannot be higher than queueNonce");
        txNonce = _nonce;
    }

    /// @dev Adds a transaction to the queue (same as executor interface so that this can be placed between other modules and the safe).
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice Can only be called by enabled modules
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public moduleOnly() {
        txHash[queueNonce] = getTransactionHash(to, value, data, operation);
        txCreatedAt[queueNonce] = block.timestamp;
        emit TransactionAdded(
            queueNonce,
            txHash[queueNonce],
            to,
            value,
            data,
            operation
        );
        queueNonce++;
    }

    /// @dev Executes the next transaction only if the cooldown has passed and the transaction has not expired
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice The txIndex used by this function is always 0
    function executeNextTx(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public {
        require(txNonce < queueNonce, "Transaction queue is empty");
        require(
            block.timestamp - txCreatedAt[txNonce] >= txCooldown,
            "Transaction is still in cooldown"
        );
        require(
            txCreatedAt[txNonce] + txCooldown + txExpiration > block.timestamp,
            "Transaction expired"
        );
        require(
            txHash[txNonce] == getTransactionHash(to, value, data, operation),
            "Transaction hashes do not match"
        );
        require(
            executor.execTransactionFromModule(to, value, data, operation),
            "Module transaction failed"
        );
        txNonce++;
    }

    function skipExpired() public {
        while (
            txExpiration != 0 &&
            txCreatedAt[txNonce] + txCooldown + txExpiration <
            block.timestamp &&
            txNonce <= queueNonce
        ) {
            txNonce++;
        }
    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, value, data, operation));
    }

    function getTxHash(uint256 _nonce) public view returns (bytes32) {
        return (txHash[_nonce]);
    }

    function getTxCreatedAt(uint256 _nonce) public view returns (uint256) {
        return (txCreatedAt[_nonce]);
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address _module) public view returns (bool) {
        return SENTINEL_MODULES != _module && modules[_module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next)
    {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (
            currentModule != address(0x0) &&
            currentModule != SENTINEL_MODULES &&
            moduleCount < pageSize
        ) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

{
  "optimizer": {
    "enabled": false,
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
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}