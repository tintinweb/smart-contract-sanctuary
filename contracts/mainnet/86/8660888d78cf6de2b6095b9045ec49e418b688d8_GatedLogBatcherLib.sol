/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity >=0.5.0 <0.7.0;

contract GatedLogBatcherLib {

    bytes32 constant private GUARD_VALUE = keccak256("logs.guard.bytes32");

    bytes32 guard;

    constructor() public {
        guard = GUARD_VALUE;
    }

    function batchLogs(bytes memory logs)
        public
    {
        require(guard != GUARD_VALUE, "LogBatcher should only be called via delegatecall");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let length := mload(logs)
            let i := 0x20
            for { } lt(i, length) { } {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) it right since mload will always load 32 bytes (a word).
                // This will also zero out unused data.
                let operation := shr(0xf8, mload(add(logs, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                let to := shr(0x60, mload(add(logs, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(logs, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                let dataLength := mload(add(logs, add(i, 0x35)))
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                let data := add(logs, add(i, 0x55))
                let success := 0
                switch operation
                case 0 { success := call(gas, to, value, data, dataLength, 0, 0) }
                case 1 { success := delegatecall(gas, to, data, dataLength, 0, 0) }
                if eq(success, 0) { revert(0, 0) }
                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
        }
    }
}