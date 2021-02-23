/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


contract MultiCall {
    
    struct Call {
        address to;
        bytes data;
    }
    
   function multicall(Call[] memory calls) public returns (bytes[] memory results, bool[] memory success) {
        results = new bytes[](calls.length);
        success = new bool[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (success[i], results[i]) = calls[i].to.call(calls[i].data);
        }
    }
}