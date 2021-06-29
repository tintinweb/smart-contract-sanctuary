pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

 contract  KEY is ERC20 {
    constructor() public  ERC20("KEY", "KEY") {
        _mint(msg.sender, 21* 10**24);
    }
}