//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IndexERC721.sol";

contract IndexERC721Factory {
    
    address[] public baskets;
    
    event NewBasket(address indexed _address, address indexed _creator);
    
    function createBasket() public {
        IndexERC721 basket = new IndexERC721();
        basket.transferFrom(address(this), msg.sender, 0);
        
        baskets.push(address(basket));
        
        emit NewBasket(address(basket), msg.sender);
    }
    
}