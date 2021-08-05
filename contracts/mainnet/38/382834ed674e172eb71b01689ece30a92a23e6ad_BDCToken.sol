pragma solidity ^0.6.0;

import "./ERC20.sol";

contract BDCToken is ERC20 {
    
    uint8 private DECIMALS = 18;
    uint256 private MAX_TOKEN_COUNT = 5000000000;
    uint256 private MAX_SUPPLY = MAX_TOKEN_COUNT * (10 ** uint256(DECIMALS));
    
    constructor() public ERC20("BUYDREAM", "BDC"){
        _mint(msg.sender, MAX_SUPPLY);
    }
}