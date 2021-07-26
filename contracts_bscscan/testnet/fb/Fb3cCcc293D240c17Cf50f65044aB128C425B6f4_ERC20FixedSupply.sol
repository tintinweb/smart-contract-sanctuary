pragma solidity >=0.4.21 <0.7.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

//openzeppelin v2.5.0

//0.5.0
contract ERC20FixedSupply is ERC20, ERC20Detailed {
    constructor(
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        uint256 totalSupply, 
        address adminAddress
    ) public ERC20Detailed(name, symbol, decimals) {
        _mint(adminAddress, totalSupply * (10**uint256(decimals)));
    }
}