/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.4.23;

library StaticCallProxy {
    function read(address _destination, bytes memory _calldata) public returns (bytes32) {
        assembly {
            let _calldatasize := calldatasize()
            calldatacopy(0, 0, _calldatasize)
            
            // 0x9569bf28 = keccak256(readInternal(address,bytes))
            mstore8(0, 0x95)
            mstore8(add(0, 1), 0x69)
            mstore8(add(0, 2), 0xbf)
            mstore8(add(0, 3), 0x28)
            pop(call(gas(), address(), 0, 0, _calldatasize, 0, 0))
            returndatacopy(0, 0, returndatasize())
            return(0, 32)
        }
    }
}