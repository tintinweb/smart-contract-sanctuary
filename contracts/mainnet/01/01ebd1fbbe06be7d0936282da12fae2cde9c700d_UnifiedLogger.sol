/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity 0.5.10;

contract UnifiedLogger {
    bytes32 private constant GUARD_VALUE = keccak256("guard.bytes32");
    address private constant MULTISEND_LIBRARY = 0x8D29bE29923b68abfDD21e541b9374737B49cdAD;

    bytes32 guard;

    event BatchLogs(bytes32 contentHash);

    constructor() public {
        guard = GUARD_VALUE;
    }

    function batchLogs(bytes memory entries) public {
        require(guard != GUARD_VALUE, "BatchLogs should only be called via delegatecall");
        (bool success, bytes memory data) = MULTISEND_LIBRARY.delegatecall(abi.encodeWithSignature("multiSend(bytes)", entries));
        emit BatchLogs(keccak256(entries));
    }
}