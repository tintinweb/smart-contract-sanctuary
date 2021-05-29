pragma solidity ^0.8.4;

import "./erc20.sol";
//ERC 20 optimization
contract SODA is ERC20, Ownable{

    constructor(string memory name, string memory symbol) ERC20(name, symbol) public {
    }
    
    function mint(uint256 amount ) public onlyOwner(){
        _mint(owner(), amount);
    }

}