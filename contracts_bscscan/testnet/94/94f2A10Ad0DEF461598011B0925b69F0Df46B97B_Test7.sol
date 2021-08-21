// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Test7 is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Test7", "TST7") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    //override decimal function to set to 0 decimals
    function decimals() public view override returns (uint8) {
		return 0;
	}
    
}