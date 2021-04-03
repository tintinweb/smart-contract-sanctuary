/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract fuck {
    uint256 public s ;
    constructor(uint256 init) public {
        s = init ;
    }
    
    function add(uint256 val) public {
        s += val ;
    }
    
    function getValue() public view returns (uint256) {
        return s ;
    }
    
    
}