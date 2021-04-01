/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.6.0;

contract Telephone {
    function changeOwner(address _owner) public {}
}

contract TelephoneCall {
    Telephone t;
    constructor(Telephone addr) public {
        t = addr;
    }
    
    function teehee(address _owner) public {
        t.changeOwner(_owner);
    }
}