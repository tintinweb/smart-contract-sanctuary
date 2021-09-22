// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./erc20.sol";
contract WLUCA is ERC20{
    address public owner;
    address public minter;

    constructor() ERC20("wrap luca", "WLUCA",  18){
        owner = msg.sender;
    }
    
    function setOwner(address user) external{
        require(msg.sender == owner, "WLUCA: only owner");
        owner = user;
    }
    
    function setMinter(address user) external{
        require(msg.sender == owner, "WLUCA: only owner");
        minter = user;
    }

    function mint(address to, uint256 value) external{
        require(msg.sender == minter, "WLUCA: only minter");
        _mint(to, value);
    }
}