pragma solidity ^0.8.0;

import "./Controlled.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract ShuflasCoin is Ownable, Controlled, ERC20 {
    
    uint256 private _maxSupply;
    uint256 private _initialSupply;
    
    constructor() ERC20("ShuflasCoin","SFC",18) {
        _maxSupply = 10000000000000000000000000;
        _initialSupply = 1000000000000000000000;
        ERC20._mint(msg.sender, _initialSupply);
    }
    
    function mint(address recipient, uint256 amount) public onlyController returns (bool) {
        ERC20._mint(recipient, amount);
        return true;
    }
}