/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
// import "./SafeMath.sol";

contract Test {
    
    function transferETH(address _to) payable public returns (bool){
           require(_to != address(0));
           payable(_to).transfer(msg.value);
           return true;
    }
    

}