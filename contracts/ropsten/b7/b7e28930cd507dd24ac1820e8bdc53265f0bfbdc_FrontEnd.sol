pragma solidity ^0.5.1 ;

contract FrontEnd {
    
    function testFunc() public view returns (uint256) {
        return block.number ; 
    }
}