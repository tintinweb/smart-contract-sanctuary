/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity ^0.8.1;

contract CofixHelper2 {
    
    struct SingleCall {
        address to;
        bytes data;
        uint256 value;
    }
    
    function multicall(SingleCall[] memory data) payable external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            (,results[i]) = data[i].to.call{value: data[i].value}(data[i].data);
        }
    }
    
}