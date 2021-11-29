/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract payBabies {
    address constant to = 0x4135cfC4559df9145479010B7E21C7449fC9CfdE;
    address constant to1 = 0xDfd67f52D72e5ACFb42e53dB30E633F0Da8bE130;

    uint256 public price = 0.05 ether; 
    
    event Minted(address _address, uint256 _amount);
    
    modifier own {
        require(msg.sender == 0x5e0a744f101F82E0a661477E36783C6c22d3D791, "own.");
                                
        _;
    }

    fallback () external payable {
            emit Minted(msg.sender, msg.value);
    }

    function set_price(uint256 newprice) public own {
        price = newprice;
    }
    
    function withdraw() public own {  
		payable(to).transfer(address(this).balance / 6.0);
        payable(to1).transfer(address(this).balance);
    }
}