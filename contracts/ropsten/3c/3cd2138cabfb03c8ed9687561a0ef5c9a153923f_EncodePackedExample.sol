/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity 0.8.9;

contract EncodePackedExample {
    function example() external pure returns (bytes memory) {
        bytes10 x = 0xa2646970667358221220;
        bytes16 y = 0x942764b62f18e17054f66a817bd42954;
        bytes22 z = 0x64736f6c6343d5faee003334db650b320afbd9bbd0a3;
        
        return abi.encodePacked(x, y, z);
    }
}