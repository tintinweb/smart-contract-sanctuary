/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

contract TestValue {
    
     uint256 config_value = 0.3*(10**18);
     uint256 pay_value ;
    constructor() public payable{
        pay_value = msg.value;
    }
    function look() public view returns(uint256,uint256){
        return (config_value,pay_value);
    }
    function tiqu(address payable account,uint256 amount) public{
        sendValue(account,amount);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}