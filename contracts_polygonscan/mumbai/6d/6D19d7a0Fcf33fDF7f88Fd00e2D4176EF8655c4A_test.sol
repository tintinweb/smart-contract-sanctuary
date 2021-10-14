/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test{

    
    function cash() public view returns(uint256) {
        return address(this).balance;
    }

    function payment() public payable{}
    
    function withdraw() public {
        address payable guy = payable(msg.sender);
        guy.transfer(cash());
    }
}