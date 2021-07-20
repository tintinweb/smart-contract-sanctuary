/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity 0.5.1;

contract MyContract {
    string public state = "Hello";
    
    function set(string memory _value) public {
        state = _value;
    }
}