// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";


contract payBabies is Ownable {
    mapping(address => uint256) whitelisted;
    
    uint256 constant PRESALE_PRICE = 0.064 ether;
    uint256 constant SALE_PRICE = 0.069 ether; 
    uint256 constant MAX_TOKEN = 9696;
    
    bool public presale;
    bool public sale;
    
    uint256 public totalSupply = 0;
    
    event Minted(address indexed _address, uint256 _amount);
    
    
    function buy(uint256 amount) public payable {
        require(sale, "Sale has not started yet.");
        require(totalSupply < MAX_TOKEN, "All Babies have been minted.");
        require(amount > 0, "Please mint atleast 1 Baby.");
        require(amount < 5, "Please mint less Babies.");
        require(msg.value >= amount * PRESALE_PRICE, "Please send enough ether.");
        
        totalSupply += amount;
        
        emit Minted(msg.sender, amount);
    }
    
    function buy_presale(uint256 amount) public payable {
        require(presale, "Presale has not started yet.");
        require(amount > 0, "Please mint atleast 1 Baby.");
        require(msg.value >= amount * PRESALE_PRICE, "Please send enough ether.");
        require(whitelisted[msg.sender] >= amount, "Please try to mint less Babies.");  // also secures only whitlisted address may mint 
        
        whitelisted[msg.sender] -= amount;
        totalSupply += amount;
        
        emit Minted(msg.sender, amount);
    }
    
    function toggle_presale() public onlyOwner {
        presale = !presale;
    }
    
    function toggle_sale() public onlyOwner {
        sale = !sale;
    }
    
    function add_to_whitelist(address[] memory adr, uint256[] memory amount) public onlyOwner {
        require(adr.length == amount.length, "Length missmatch.");
        
        for(uint256 i = 0; i < adr.length; i++) {
            whitelisted[adr[i]] = amount[i];
        }
    }
    
    function remove_from_whitelist(address adr) public onlyOwner {
        whitelisted[adr] = 0;
    }
    
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
		  
		payable(msg.sender).transfer(amount);
    }
}