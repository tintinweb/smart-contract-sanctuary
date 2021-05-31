/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Creator {
    address public creator;
    constructor() public {
        creator = msg.sender;
    }

    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }
}


contract WithdrawETH is Creator {
    
    receive() external payable {}
    
    function safeTransferETH() public  creatorOnly {
        payable(msg.sender).transfer(address(this).balance);
    }  
    
}