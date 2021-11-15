// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.2;

import "./TimelockEvents.sol";

/// @title Timelock
/// @author Forked from Compound https://github.com/compound-finance/compound-protocol/blob/master/contracts/Timelock.sol
/// @notice Queue and execute transactions
/// @dev Executes the proposals voted by the governance
/// This contract is the actual governor, meaning it should be the `msg.sender` of the governance transactions
contract Timelock is TimelockEvents {
    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 0 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    // ========================= Constructor ===================

    /// @notice Initializes the timelock contract
    /// @param admin_ Admin of the contract (i.e. the governor)
    /// @param delay_ Delay between proposal submission and execution
    constructor(
        address admin_,
        address pendingAdmin_,
        uint256 delay_
    ) {
        require(delay_ >= MINIMUM_DELAY, "Delay must exceed minimum delay");
        require(delay_ <= MAXIMUM_DELAY, "Delay must not exceed maximum delay");

        admin = admin_;
        pendingAdmin = pendingAdmin_;
        delay = delay_;
    }

    /// @notice Queues a transaction
    /// @param target Address of the contract that will receive the Tx
    /// @param value Value of the ETH to send in the transaction
    /// @param signature Signature of the function to call
    /// @param data The abi encoding of the function parameters
    /// @param eta Estimated date of execution. Has to be later than current time + delay
    /// @return The hash of the Tx
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "call must come from admin");
        require(eta >= _getBlockTimestamp() + delay, "estimated execution block must satisfy delay");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    /// @notice Cancels a queued transaction
    /// @param target Address of the contract that will receive the Tx
    /// @param value Value of the ETH to send in the transaction
    /// @param signature The signature of the function to call
    /// @param data The abi encoding of the function parameters
    /// @param eta The estimated date of execution. Has to be later than current time + delay
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "call must come from admin");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    /// @notice Executes a queued transaction
    /// @param target Address of the contract that will receive the Tx
    /// @param value Value of the ETH to send in the transaction
    /// @param signature The signature of the function to call
    /// @param data The abi encoding of the function parameters
    /// @param eta The estimated date of execution.
    /// @dev All these parameters has to match exactly the ones of the queued tx
    /// @dev The Tx can only be executed after its eta, and before eta + the grace period
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "call must come from admin");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "transaction has not been queued");
        require(_getBlockTimestamp() >= eta, "transaction has not surpassed time lock");
        require(_getBlockTimestamp() <= eta + GRACE_PERIOD, "transaction is stale");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{ value: value }(callData); //solhint-disable avoid-call-value;
        require(success, "transaction execution reverted");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    /// @notice In case ETH is required for some transactions
    receive() external payable {}

    // ========================= Governance =====================

    /// @notice Admin function for setting the minimum delay
    /// @param delay_ New voting period, in blocks
    function setDelay(uint256 delay_) public {
        require(msg.sender == address(this), "call must come from Timelock");
        require(delay_ >= MINIMUM_DELAY, "delay must exceed minimum delay");
        require(delay_ <= MAXIMUM_DELAY, "delay must not exceed maximum delay");
        delay = delay_;

        emit NewDelay(delay);
    }

    /// @notice Changes the admin
    /// @param pendingAdmin_ New admin
    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "call must come from Timelock");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    /// @notice Function for changing the admin after a pendingAdmin change
    /// @dev The pending admin has to call this function to accept its role
    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "call must come from pendingAdmin");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    // ========================= Internal Functions =====================
    /// @notice Getter to the current block timestamp
    function _getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.2;

/// @title TimelockEvents
/// @author Angle Core Team
/// @notice All the events used in Timelock contract
contract TimelockEvents {
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event NewAdmin(address indexed newAdmin);

    event NewPendingAdmin(address indexed newPendingAdmin);

    event NewDelay(uint256 indexed newDelay);
}

