pragma solidity ^0.5.0;

import "ERC20.sol";

contract PaybToken is ERC20 {

    uint256 public initialSupply = 1000000000000000000000000;
    uint8   public decimals = 18;

    constructor() public {
        _mint(msg.sender, initialSupply);
    }
}