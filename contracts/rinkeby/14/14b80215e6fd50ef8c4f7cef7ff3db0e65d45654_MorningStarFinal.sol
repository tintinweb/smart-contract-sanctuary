// SPDX-License-Identifier:  minutes

pragma solidity ^0.8.0;
// consider limit burn to owner, otherwise token can be devauled by burn of circulating supply 
// artodoeah:  limit flash functions to onlyowner

import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./ERC20Snapshot.sol";
import "./ERC20FlashMint.sol";

// 72000000000000000000000000 = 72*10**6 * 10**18 - CONFIRMED 2021.06.13 , 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,  16000000000000000000000000, 10000000000000000000000000, 6000000000000000000000000
contract MorningStarFinal is ERC20Pausable, Ownable, ERC20Burnable, ERC20Capped, ERC20Snapshot, ERC20FlashMint {
    constructor (uint256 initialSupply) ERC20("MorningStarFinal", "MSF") ERC20Capped(40000000000000000000000000) {
        ERC20._mint(msg.sender, initialSupply);
    }
    // override beforetokentransfer to pausable definition
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
    // override _mint for capped MorningStarFinal
    function _mint(address from, uint256 amount) internal override (ERC20, ERC20Capped) {
        super._mint(from, amount);
    }
    // override burn to require owner
    function burn(uint256 amount) public override (ERC20Burnable) onlyOwner {
        _burn(_msgSender(), amount);
    }
    // add pause modifiers 
    function salePause() public onlyOwner {
        _pause();
    }
    function unPause() public onlyOwner {
        _unpause();
    }
}