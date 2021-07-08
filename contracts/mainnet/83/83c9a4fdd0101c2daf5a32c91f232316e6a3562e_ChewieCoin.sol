pragma solidity ^0.8.5;

import './ERC20.sol';

contract ChewieCoin is ERC20 {
    constructor() ERC20('Chewie Coin', 'CHWE') {
        _mint(msg.sender, 1000000000000000 * 10 ** 18);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}