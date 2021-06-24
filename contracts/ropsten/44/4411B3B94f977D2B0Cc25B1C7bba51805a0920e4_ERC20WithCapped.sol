pragma solidity >=0.4.21 <0.7.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Capped.sol";


//0.5.0
contract ERC20WithCapped is ERC20, ERC20Detailed, ERC20Capped {
    constructor(
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        uint256 initalSupply, 
        uint256 cap, 
        address adminAddress
    ) public ERC20Detailed(name, symbol, decimals) ERC20Capped(cap * (10**uint256(decimals))){
        _mint(adminAddress, initalSupply * (10**uint256(decimals)));
    }
}