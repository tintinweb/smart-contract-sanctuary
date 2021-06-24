pragma solidity >=0.4.21 <0.7.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./ERC20Pausable.sol";
 
//Multifunctional ERC20 tokens, can be issued, destroyed, suspended, capped,mint
contract ERC20MultiFunction is
    ERC20,
    ERC20Detailed,
    ERC20Burnable,
    ERC20Capped,
    ERC20Pausable
{
    constructor(
        string memory name, //token name
        string memory symbol, //symbol
        uint8 decimals, 
        uint256 totalSupply, 
        uint256 cap, //Capped number
        address adminAddress
    ) public ERC20Detailed(name, symbol, decimals) ERC20Capped(cap * (10**uint256(decimals))){
        _mint(adminAddress, totalSupply * (10**uint256(decimals)));
    }
}