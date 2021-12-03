// ________ ___       ___  ___  ________ ________ 
//|\  _____\\  \     |\  \|\  \|\  _____\\  _____\
//\ \  \__/\ \  \    \ \  \\\  \ \  \__/\ \  \__/ 
// \ \   __\\ \  \    \ \  \\\  \ \   __\\ \   __\
//  \ \  \_| \ \  \____\ \  \\\  \ \  \_| \ \  \_|
//   \ \__\   \ \_______\ \_______\ \__\   \ \__\ 
//    \|__|    \|_______|\|_______|\|__|    \|__|                                            
                                                
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Fluff is ERC20, Ownable {
    address public hammieAddress;
    address public galaxyAddress;
    
    mapping(address => bool) public allowedAddresses;

    constructor() ERC20("Fluff", "FLF") {}
    
    function setHammieAddress(address hammieAddr) external onlyOwner {
        hammieAddress = hammieAddr;
    }
    
    function setGalaxyAddress(address galaxyAddr) external onlyOwner {
        galaxyAddress = galaxyAddr;
    }
    
    function burn(address user, uint256 amount) external {
        require(msg.sender == galaxyAddress || msg.sender == hammieAddress, "Address not authorized");
        _burn(user, amount);
    }
    
    function mint(address to, uint256 value) external {
        require(msg.sender == galaxyAddress || msg.sender == hammieAddress, "Address not authorized");
        _mint(to, value);
    }
}