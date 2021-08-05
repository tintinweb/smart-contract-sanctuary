pragma solidity ^0.6.6;

import "./Ownable.sol";

contract ACOVaults is Ownable {
    event AcoVault(address indexed vault, bool isValid);
    mapping(address => bool) public vaults;
    
    constructor () public {
        super.init();
    }   
    
    function setVault(address vault, bool isValid) onlyOwner external {
        require(vault != address(0));
        vaults[vault] = isValid;
        emit AcoVault(vault, isValid);
    }
}