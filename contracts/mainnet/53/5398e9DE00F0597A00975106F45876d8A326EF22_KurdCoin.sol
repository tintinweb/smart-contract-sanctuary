// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './ERC20.sol';


contract KurdCoin is ERC20 {
    
    address public Reman;
    
    constructor() ERC20('Kurd Coin', 'KRD') {
        
         _mint(msg.sender, 10000 * 10 ** 18 );
         
        Reman = msg.sender;
    }
    
    function mint(address to, uint amount) external {
        
        require(msg.sender == Reman, 'Only Reman');
        
        _mint(to, amount);
    }
    
    function burn(uint amount) external {
        
        _burn(msg.sender, amount);
    }
    
}