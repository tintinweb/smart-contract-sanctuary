pragma solidity ^0.4.24;

contract Test {    
    function test(uint256 num) public view returns(bytes32) {
        return blockhash(block.number - num);
    }
    
    function test2() public view returns(uint256) {
        return block.number;
    }
}