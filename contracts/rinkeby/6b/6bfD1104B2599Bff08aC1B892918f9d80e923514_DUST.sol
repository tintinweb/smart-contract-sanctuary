pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract DUST is ERC20, Ownable {
    address private _minter = address(0);
    address private _extraMinter = address(0);
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function setMinter(address minter) public onlyOwner {
        require(_minter == address(0), "ERROR: minter is set already, cannot be changed");
        _minter = minter;
    }

    // future functions like staking
    function setExtraMinter(address minter) public onlyOwner {  
        require(_minter == address(0), "ERROR: minter is set already, cannot be changed");
        _minter = minter;
    }

    function mint(address to, uint256 amount) public virtual returns (bool) {
        require((_msgSender() == _minter) || (_msgSender() == _extraMinter), "ERROR: not minter");
        _mint(to, amount);
	return true;
    }
}