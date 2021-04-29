/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity 0.5.10;

contract UnifiedLogger {
    bytes32 private constant GUARD_VALUE = keccak256("guard.bytes32");
    address gatedLogBatcherLib;
    bytes32 guard;

    struct UnlockSchedule {
        address beneficiary;
        address token;
        uint256 totalAmount;
        uint256 start;
        uint256 end;
        uint256 duration;
    }

    mapping(address => UnlockSchedule[]) public unlockSchedules;

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

    constructor(address _gatedLogBatcherLib) public {
        gatedLogBatcherLib = _gatedLogBatcherLib;
        guard = GUARD_VALUE;
    }

    function batchLogs(bytes memory logs, bytes32 contentHash) public {
        require(guard != GUARD_VALUE);
        (bool success, bytes memory data) = gatedLogBatcherLib.delegatecall(abi.encodeWithSignature("multiSend(bytes)", logs));
        emit BatchLogs(contentHash);
    }
}