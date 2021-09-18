/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Test {
    
    function send (address  _owner,uint _amount) external payable{
        payable(_owner).transfer(_amount);
    }
    

}