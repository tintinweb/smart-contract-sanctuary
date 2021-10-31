// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./MultiManager.sol";


contract Facebook is ERC20, Multimanager{
    
    constructor() ERC20("Meta Facebook", "META") {
        _mint(deployer, 700000000 * 10 ** decimals());
    } 
    
    function burn(uint256 amountBurned) public {
        _burn(msg.sender, amountBurned);
    }
    
    function burnContract(uint256 amountBurned)public onlyManager{
        _burn(address(this), amountBurned);
    }
    
}