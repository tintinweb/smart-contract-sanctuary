/**
 *Submitted for verification at snowtrace.io on 2022-01-22
*/

// File: contracts/Timelock.sol


pragma solidity ^0.8.0;

contract Timelock {
    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;

    event NewAdmin(
        address indexed newAdmin
    );
    event NewPendingAdmin(
        address indexed newPendingAdmin
    );
    event NewDelay(
        uint indexed newDelay
    );
    event CancelTransaction(
        bytes32 indexed txHash,
        uint indexed proposalId,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        uint indexed proposalId,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        uint indexed proposalId,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );

    constructor(address admin_, uint delay_) {
        require(delay_ >= MINIMUM_DELAY, "ERR_DELAY_BELOW_MIN");
        require(delay_ <= MAXIMUM_DELAY, "ERR_DELAY_ABOVE_MAX");
        require(admin_ != address(0), "ERR_ZERO_ADDRESS");

        admin = admin_;
        delay = delay_;
    }

    receive() external payable {}

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "ERR_NOT_TIMELOCK");
        require(delay_ >= MINIMUM_DELAY, "ERR_DELAY_BELOW_MIN");
        require(delay_ <= MAXIMUM_DELAY, "ERR_DELAY_ABOVE_MAX");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "ERR_NOT_PENDINGADMIN");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "ERR_NOT_TIMELOCK");
        require(pendingAdmin_ != address(0), "ERR_ZERO_ADDRESS");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        uint proposalId,
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
        )
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "ERR_NOT_CONTROLLER");
        require(eta >= block.timestamp + delay, "ERR_ETA_BELOW_DELAY");

        bytes32 txHash = keccak256(abi.encode(proposalId, target, value, signature, data, eta));

        require(!queuedTransactions[txHash], "ERR_TRANSACTION_ALREADY_QUEUED");

        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, proposalId, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        uint proposalId,
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
        )
        public
    {
        require(msg.sender == admin, "ERR_NOT_CONTROLLER");

        bytes32 txHash = keccak256(abi.encode(proposalId, target, value, signature, data, eta));

        require(queuedTransactions[txHash], "ERR_TRANSACTION_NOT_QUEUED");

        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, proposalId, target, value, signature, data, eta);
    }

    function executeTransaction(
        uint proposalId,
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
        )
        public
        payable
        returns (bytes memory)
    {
        require(msg.sender == admin, "ERR_NOT_CONTROLLER");

        bytes32 txHash = keccak256(abi.encode(proposalId, target, value, signature, data, eta));

        require(queuedTransactions[txHash], "ERR_TRANSACTION_NOT_QUEUED");
        require(block.timestamp >= eta, "ERR_DELAY_NOT_PASSED");
        require(block.timestamp <= eta + GRACE_PERIOD, "ERR_TRANSACTION_IS_STALE");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "ERR_EXECUTION_REVERTED");

        emit ExecuteTransaction(txHash, proposalId, target, value, signature, data, eta);

        return returnData;
    }
}