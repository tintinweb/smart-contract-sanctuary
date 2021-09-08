// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.7;

import "./SafeMath.sol";

contract Timelock {
    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
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

    uint256 public immutable GRACE_PERIOD;
    uint256 public immutable MINIMUM_DELAY;
    uint256 public immutable MAXIMUM_DELAY;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;
    bool public _admininitialized;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(
        address _admin,
        // uint256[] [GRACE_PERIOD, MINIMUM_DELAY, MAXIMUM_DELAY, delay]
        uint256[4] memory TimelockValues
    ) {
        require(
            TimelockValues[3] >= TimelockValues[1],
            "Timelock::constructor: Delay must exceed minimum delay."
        );
        require(
            TimelockValues[3] <= TimelockValues[2],
            "Timelock::constructor: Delay must not exceed maximum delay."
        );

        admin = _admin;

        GRACE_PERIOD = TimelockValues[0];
        MINIMUM_DELAY = TimelockValues[1];
        MAXIMUM_DELAY = TimelockValues[2];
        delay = TimelockValues[3];

        _admininitialized = false;
    }

    receive() external payable {}

    function setDelay(uint256 _delay) public {
        require(
            msg.sender == address(this),
            "Timelock::setDelay: Call must come from Timelock."
        );
        require(
            _delay >= MINIMUM_DELAY,
            "Timelock::setDelay: Delay must exceed minimum delay."
        );
        require(
            _delay <= MAXIMUM_DELAY,
            "Timelock::setDelay: Delay must not exceed maximum delay."
        );
        delay = _delay;

        emit NewDelay(delay);
    }

    function acceptAdmin() external {
        require(
            msg.sender == pendingAdmin,
            "Timelock::acceptAdmin: Call must come from pendingAdmin."
        );
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pending_admin) public {
        if (_admininitialized) {
            require(
                msg.sender == address(this),
                "Timelock::setPendingAdmin: Call must come from Timelock."
            );
        } else {
            require(
                msg.sender == admin,
                "Timelock::setPendingAdmin: First call must come from admin."
            );
            _admininitialized = true;
        }
        pendingAdmin = pending_admin;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external returns (bytes32) {
        require(
            msg.sender == admin,
            "Timelock::queueTransaction: Call must come from admin."
        );
        require(
            eta >= getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external {
        require(
            msg.sender == admin,
            "Timelock::cancelTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external payable returns (bytes memory) {
        require(
            msg.sender == admin,
            "Timelock::executeTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        require(
            queuedTransactions[txHash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            getBlockTimestamp() >= eta,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta.add(GRACE_PERIOD),
            "Timelock::executeTransaction: Transaction is stale."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}