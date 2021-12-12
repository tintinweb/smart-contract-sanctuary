/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract payBabies {
    address constant to = 0x4135cfC4559df9145479010B7E21C7449fC9CfdE;
    address constant to1 = 0xDfd67f52D72e5ACFb42e53dB30E633F0Da8bE130;
    
    event Minted(address _address, uint256 _amount);

    fallback () external payable { 
        emit Minted(msg.sender, msg.value);
    }
    
    function withdraw() public {  
		payable(to).transfer(address(this).balance / 6.0);
        payable(to1).transfer(address(this).balance);
    }
}