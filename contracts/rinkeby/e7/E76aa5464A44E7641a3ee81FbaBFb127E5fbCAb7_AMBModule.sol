// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract Enum {
    enum Operation {Call, DelegateCall}
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

interface IAMB {
    function messageSender() external view returns (address);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function requireToPassMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas
    ) external returns (bytes32);
}

contract AMBModule {
    event AmbModuleSetup(address indexed initiator, address indexed safe);

    IAMB public amb;
    Executor public executor;
    address public owner;
    bytes32 public chainId;

    constructor(
        Executor _executor,
        IAMB _amb,
        address _owner,
        bytes32 _chainId
    ) {
        setUp(_executor, _amb, _owner, _chainId);
    }

    /// @param _executor Address of the executor (e.g. a Safe)
    /// @param _amb Address of the AMB contract
    /// @param _owner Address of the authorized owner contract on the other side of the bridge
    /// @param _chainId Address of the authorized chainId from which owner can initiate transactions
    function setUp(
        Executor _executor,
        IAMB _amb,
        address _owner,
        bytes32 _chainId
    ) public {
        require(address(executor) == address(0), "Module is already initialized");
        executor = _executor;
        amb = _amb;
        owner = _owner;
        chainId = _chainId;

        emit AmbModuleSetup(msg.sender, address(_executor));
    }

    modifier executorOnly() {
        require(msg.sender == address(executor), "Not authorized");
        _;
    }

    /// @dev Check that the amb, chainId, and owner are valid
    modifier onlyValid() {
        require(msg.sender == address(amb), "Unauthorized amb");
        require(amb.messageSourceChainId() == chainId, "Unauthorized chainId");
        require(amb.messageSender() == owner, "Unauthorized owner");
        _;
    }

    /// @dev Set the AMB contract address
    /// @param _amb Address of the AMB contract
    /// @notice This can only be called by the executor
    function setAmb(address _amb) public executorOnly() {
        require(address(amb) != _amb, "AMB address already set to this");
        amb = IAMB(_amb);
    }

    /// @dev Set the approved chainId
    /// @param _chainId ID of the approved network
    /// @notice This can only be called by the executor
    function setChainId(bytes32 _chainId) public executorOnly() {
        require(chainId != _chainId, "chainId already set to this");
        chainId = _chainId;
    }

    /// @dev Set the owner address
    /// @param _owner Set the address of owner on the other side of the bridge
    /// @notice This can only be called by the executor
    function setOwner(address _owner) public executorOnly() {
        require(owner != _owner, "owner already set to this");
        owner = _owner;
    }

    /// @dev Executes a transaction initated by the AMB
    /// @param to Target of the transaction that should be executed
    /// @param value Wei value of the transaction that should be executed
    /// @param data Data of the transaction that should be executed
    /// @param operation Operation (Call or Delegatecall) of the transaction that should be executed
    function executeTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public onlyValid() {
        require(
            executor.execTransactionFromModule(to, value, data, operation),
            "Module transaction failed"
        );
    }
}

