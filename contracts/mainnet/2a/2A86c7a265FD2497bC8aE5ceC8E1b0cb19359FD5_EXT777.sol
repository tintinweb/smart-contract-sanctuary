//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./ERC777.sol";

contract EXT777 is ERC777 { 
    
    uint256 initialSupply = 5000000000 * 10 ** 18;


    constructor() public
        ERC777("Enjoy X Travel", "EXT", new address[](0))
    {
        _mint(msg.sender, initialSupply, "","");
    }

}
