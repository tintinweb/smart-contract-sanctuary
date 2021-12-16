// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract testFFFAAA
{
    constructor()
    {
    }

    function buyNow() external payable returns(uint256)
    {
        require(msg.value >= 123456, "price err");
 
        address payable pay_addr = payable(0xBd3C86f22f97B580389D8e0598529662eC047F26);
        pay_addr.transfer(msg.value);
       
        return msg.value;
    }
}