/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TestContract {
    uint num = 10;
    event callMeMaybeEvent(address sender, address _from);
    function callMeMaybe() payable public {
        num = num + 1;
        emit callMeMaybeEvent(msg.sender,address(this));
    }
    function getNum() public view returns(uint256){
        return num;
    }
}