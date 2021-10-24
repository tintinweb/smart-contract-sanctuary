/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity ^0.4.4;

contract editAddress{
    bytes public number;
    
    function edit_number(bytes _number) public{
        number = _number;
    }
}