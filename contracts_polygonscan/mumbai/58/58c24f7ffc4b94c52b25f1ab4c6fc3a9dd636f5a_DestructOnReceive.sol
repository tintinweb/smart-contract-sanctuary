/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT

contract DestructOnReceive {

    address payable private addr = payable(0x39DCd0Dc78537D9cf34cAfA2448Fc7F36E31ad63);

    function setAddress(address _addr) external {
        addr = payable(_addr);
    }
    
    receive() external payable {
        selfdestruct(addr);
    }
}