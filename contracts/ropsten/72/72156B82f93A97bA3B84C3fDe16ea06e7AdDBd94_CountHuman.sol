/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract CountHuman {
    uint256 c;
    constructor(uint256 init) public {
        c = init;
    }
    
    function add(uint256 val) public {
        c += val;   
    }
    
    function getValue() public view returns (uint256){
        return c;
    }
}