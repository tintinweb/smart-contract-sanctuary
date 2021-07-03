// SPDX-License-Identifier:  minutes

pragma solidity ^0.8.0;
// consider limit burn to owner, otherwise token can be devauled by burn of circulating supply 
// artodoeah:  limit flash functions to onlyowner

import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";

// 72000000000000000000000000 = 72*10**6 * 10**18 - CONFIRMED 2021.06.13 , 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,  16000000000000000000000000, 10000000000000000000000000, 6000000000000000000000000
contract OurNewCoin is ERC20Pausable, Ownable, ERC20Burnable, ERC20Capped {
    constructor (uint256 initialSupply, uint256 capAmount) ERC20("OurNewCoin", "ONC") ERC20Capped(capAmount) {
        ERC20._mint(msg.sender, initialSupply);
    }
    //REMOVENTHIS
    function mintTest(address from, uint256 amount) public virtual {
        _mint(from, amount);
    }
    function approve(address spender, uint256 amount) public virtual override (ERC20) onlyOwner returns (bool) {
        require(!paused(), "Not allowed: token approve while paused");
        ERC20.approve(spender, amount);
        return true; // 
    }
    function burn(uint256 amount) public virtual override (ERC20Burnable) onlyOwner {
        require(!paused(), "Not allowed: token burn while paused");
        super._burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual override (ERC20Burnable) onlyOwner {
        require(!paused(), "Not allowed: token transfer while paused");
        super._burn(account, amount);
    } 
    function decreaseAllowance(address spender, uint256 amount) public virtual override (ERC20) onlyOwner returns (bool) {
        require(!paused(), "Not allowed:  allowance while paused");
        require(super.decreaseAllowance(spender, amount));
        return true;
    }
    function increaseAllowance(address spender, uint256 amount) public virtual override (ERC20) onlyOwner returns (bool) {
        require(!paused(), "Not allowed:  allowance while paused");
        require(super.increaseAllowance(spender, amount));
        return true;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override (ERC20, ERC20Pausable) {
        // ERC20Pausable requires not paused
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override (ERC20) onlyOwner returns (bool) {
        // require(!paused(), "Not allowed: token transfer while paused");
        // ERC20Pausable requires not paused
        require(super.transferFrom(sender, recipient, amount));
        return true;
    }
    function _mint(address from, uint256 amount) internal virtual override (ERC20, ERC20Capped) onlyOwner {
        // working, testing below...super._mint(from, amount);
        // ERC20 emits beforeTokenTransfer for not paused
        ERC20Capped._mint(from, amount);
    }
    // add pause modifiers 
    function salePause() public virtual onlyOwner {
        _pause();
    }
    function saleUnPause() public virtual onlyOwner {
        _unpause();
    }
}