/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity >=0.7.0 <0.8.0;

contract Canary {
    
    event Ping(string name);
    
    function ping(string memory name) public {
        emit Ping(name);
    }
    
}