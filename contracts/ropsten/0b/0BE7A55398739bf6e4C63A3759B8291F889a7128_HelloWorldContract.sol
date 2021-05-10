/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity >=0.8.4;

contract HelloWorldContract {
    string public myStateVariable;
    
    constructor() {
        myStateVariable = 'Test 1';
    }
    
    function updateVar() public {
        myStateVariable = 'Test 2';
    }

}