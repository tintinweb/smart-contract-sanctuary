/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity 0.8.0;

contract factory {
    
   address [] public childs;
    
    function createChild(uint number) public {
        children child = new children(number);
        childs.push(address(child));
    }
}

contract children {
    // uint public number;
    uint public Number;
    constructor (uint number) {
        Number = number;
    }
}