/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.6.5;

contract AlohaTest {

    uint256 value;

    constructor() public {
       value = 1;
    }

 
    function setValue(uint256 newValue) public {
        value = newValue;
    }

}