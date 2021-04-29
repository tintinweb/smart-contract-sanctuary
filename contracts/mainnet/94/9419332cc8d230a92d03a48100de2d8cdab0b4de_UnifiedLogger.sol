/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity 0.5.10;

contract UnifiedLogger {
    bytes32 private constant GUARD_VALUE = keccak256("guard.bytes32");
    address private constant GATED_LOG_BATCHER_LIB = 0x8D29bE29923b68abfDD21e541b9374737B49cdAD;

    bytes32 guard;
    
    struct UnlockSchedule {
        address beneficiary;
        address token;
        uint256 totalAmount;
        uint256 start;
        uint256 end;
        uint256 duration;
    }

    event UnlockScheduleSet(
        address indexed beneficiary,
        address token,
        uint256 totalAmount,
        uint256 start,
        uint256 end,
        uint256 duration,
        uint256 indexed timestamp,
        uint256 indexed blockNumber
    );
    event DiggPegRewards(address indexed beneficiary, uint256 response, uint256 rate, uint256 indexed timestamp, uint256 indexed blockNumber);

    event BatchLogs(bytes32 contentHash);

    constructor() public {
        guard = GUARD_VALUE;
    }

    function batchLogs(bytes memory logs) public {
        require(guard != GUARD_VALUE, "BatchLogs should only be called via delegatecall");
        (bool success, bytes memory data) = GATED_LOG_BATCHER_LIB.delegatecall(abi.encodeWithSignature("multiSend(bytes)", logs));
        emit BatchLogs(keccak256(logs));
    }
}