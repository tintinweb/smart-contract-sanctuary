/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.26;

contract E {

    
    function execute(address _to, uint _value, bytes _data) external {
       _to.call(_data);
    }

    
    
}