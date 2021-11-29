/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract payBabies {
    address constant to = 0x4135cfC4559df9145479010B7E21C7449fC9CfdE;
    address constant to1 = 0xDfd67f52D72e5ACFb42e53dB30E633F0Da8bE130;

    uint256 public price = 0.05 ether; 
    uint256 public maxSupply = 2100;
    uint256 public totalSupply = 0;
    
    event Minted(address _address, uint256 _amount);
    
    modifier own {
        require(msg.sender == 0x5e0a744f101F82E0a661477E36783C6c22d3D791, "own.");
                                
        _;
    }


    fallback () external payable {
        require(msg.value >= price, "Please send enough ether.");
        require(totalSupply < maxSupply, "All minted!");
        uint256 amount = 0;


        if(msg.value == 0.05 ether)
            amount = 1;
        else if(msg.value == 0.1 ether)
            amount = 2;
        else if(msg.value == 0.15 ether)
            amount = 3;
        else if(msg.value == 0.2 ether)
            amount = 4;
        else if(msg.value == 0.25 ether)
            amount = 5;
            
        
        if(amount > 0) {
            totalSupply += amount;
            
            emit Minted(msg.sender, amount);
        }
    }

    function set_price(uint256 newprice) public own {
        price = newprice;
    }
    
    function set_total_supply(uint256 val) public own {
        totalSupply = val;
    }
    
    function withdraw() public own {  
		payable(to).transfer(address(this).balance / 6.0);
        payable(to1).transfer(address(this).balance);
    }
}