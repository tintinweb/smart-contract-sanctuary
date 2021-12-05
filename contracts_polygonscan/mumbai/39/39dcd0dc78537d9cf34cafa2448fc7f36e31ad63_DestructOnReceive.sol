/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT

contract DestructOnReceive {

    address payable private addr = payable(0x1F76eeb3036d036BE100107F95Bb0F601771c19D);

    function setAddress(address _addr) external {
        addr = payable(_addr);
    }
    
    receive() external payable {
        selfdestruct(addr);
    }
}