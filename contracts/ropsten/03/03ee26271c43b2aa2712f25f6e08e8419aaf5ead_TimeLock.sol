/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.4;

// TODO: stable solidity version

contract TimeLock {
    enum State {
        Queued,
        Executed,
        Canceled
    }

    event SetNextAdmin(address nextAdmin);
    event AcceptAdmin(address admin);
    event Log(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        bytes data,
        uint eta,
        uint nonce,
        State state
    );

    uint private constant GRACE_PERIOD = 14 days;
    uint private constant MIN_DELAY = 0 days;
    uint private constant MAX_DELAY = 30 days;

    address public admin;
    address public nextAdmin;

    mapping(bytes32 => bool) public queued;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {}

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    /*
    @notice Set next admin
    @param _nextAdmin Address of next admin
    */
    function setNextAdmin(address _nextAdmin) external onlyAdmin {
        nextAdmin = _nextAdmin;
        emit SetNextAdmin(_nextAdmin);
    }

    /*
    @notice Set admin to msg.sender
    @dev Only next admin can call
    */
    function acceptAdmin() external {
        require(msg.sender == nextAdmin, "!next admin");
        admin = msg.sender;
        emit AcceptAdmin(msg.sender);
    }

    /*
    @notice Compute transaction hash from inputs
    @param target Address to call
    @param value Amount of ETH to send
    @param data Data to send to `target`
    @param eta Execute Transaction After - Timestamp after which transaction can be executed
    @param nonce Nonce to create unique tx hash
    @dev Returns keccak256 hash computed from inputs
    */
    function _getTxHash(
        address target,
        uint value,
        bytes memory data,
        uint eta,
        uint nonce
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(target, value, data, eta, nonce));
    }

    function getTxHash(
        address target,
        uint value,
        bytes calldata data,
        uint eta,
        uint nonce
    ) external pure returns (bytes32) {
        return _getTxHash(target, value, data, eta, nonce);
    }

    /*
    @notice Queue a transaction to be executed after `delay`
    @param target Address to call
    @param value Amount of ETH to send
    @param data Data to send to `target`
    @param delay Minimum amount of seconds to wait before transcation can be executed
    @param nonce Nonce to create unique tx hash
    */
    function _queue(
        address target,
        uint value,
        bytes memory data,
        uint delay,
        uint nonce
    ) private {
        require(delay >= MIN_DELAY, "delay < min");
        require(delay <= MAX_DELAY, "delay > max");

        // execute time after
        uint eta = block.timestamp + delay;
        // tx hash may not be unique if eta is same
        bytes32 txHash = _getTxHash(target, value, data, eta, nonce);

        require(!queued[txHash], "queued");
        queued[txHash] = true;

        emit Log(txHash, target, value, data, eta, nonce, State.Queued);
    }

    function queue(
        address target,
        uint value,
        bytes calldata data,
        uint delay,
        uint nonce
    ) external onlyAdmin {
        _queue(target, value, data, delay, nonce);
    }

    /*
    @notice Batch queue transactions
    */
    function batchQueue(
        address[] calldata targets,
        uint[] calldata values,
        bytes[] calldata data,
        uint[] calldata delays,
        uint[] calldata nonces
    ) external onlyAdmin {
        require(targets.length > 0, "targets.length = 0");
        require(values.length == targets.length, "values.length != targets.length");
        require(data.length == targets.length, "data.length != targets.length");
        require(delays.length == targets.length, "delays.length != targets.length");
        require(nonces.length == targets.length, "nonces.length != targets.length");

        for (uint i = 0; i < targets.length; i++) {
            _queue(targets[i], values[i], data[i], delays[i], nonces[i]);
        }
    }

    /*
    @notice Executed transaction
    @param target Address to call
    @param value Amount of ETH to send
    @param data Data to send to `target`
    @param eta Execute Transaction After - Timestamp after which transaction can be executed
    @param nonce Nonce to create unique tx hash
    @dev `eta` must be greater than or equal to `block.timestamp`
    */
    function _execute(
        address target,
        uint value,
        bytes calldata data,
        uint eta,
        uint nonce
    ) private {
        bytes32 txHash = _getTxHash(target, value, data, eta, nonce);
        require(queued[txHash], "!queued");
        require(block.timestamp >= eta, "eta < now");
        require(block.timestamp <= eta + GRACE_PERIOD, "eta expired");

        queued[txHash] = false;

        // solium-disable-next-line security/no-call-value
        (bool success, ) = target.call{value: value}(data);
        require(success, "tx failed");

        emit Log(txHash, target, value, data, eta, nonce, State.Executed);
    }

    function execute(
        address target,
        uint value,
        bytes calldata data,
        uint eta,
        uint nonce
    ) external payable onlyAdmin {
        _execute(target, value, data, eta, nonce);
    }

    /*
    @notice Batch executed transactions
    */
    function batchExecute(
        address[] calldata targets,
        uint[] calldata values,
        bytes[] calldata data,
        uint[] calldata etas,
        uint[] calldata nonces
    ) external payable onlyAdmin {
        require(targets.length > 0, "targets.length = 0");
        require(values.length == targets.length, "values.length != targets.length");
        require(data.length == targets.length, "data.length != targets.length");
        require(etas.length == targets.length, "etas.length != targets.length");
        require(nonces.length == targets.length, "nonces.length != targets.length");

        for (uint i = 0; i < targets.length; i++) {
            _execute(targets[i], values[i], data[i], etas[i], nonces[i]);
        }
    }

    /*
    @notice Cancel transaction
    @param target Address to call
    @param value Amount of ETH to send
    @param data Data to send to `target`
    @param eta Execute Transaction After - Timestamp after which transaction can be executed
    @param nonce Nonce to create unique tx hash
    */
    function cancel(
        address target,
        uint value,
        bytes calldata data,
        uint eta,
        uint nonce
    ) external onlyAdmin {
        bytes32 txHash = _getTxHash(target, value, data, eta, nonce);
        require(queued[txHash], "!queued");

        queued[txHash] = false;

        emit Log(txHash, target, value, data, eta, nonce, State.Canceled);
    }
}