// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "ERC20.sol";

import "ERC20Burnable.sol";
import "Ownable.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "draft-ERC20Permit.sol";

contract Token is ERC20, ERC20Burnable, Pausable, ReentrancyGuard, Ownable, ERC20Permit {
    constructor() ERC20("Playex", "PLYX") ERC20Permit("Playex") ReentrancyGuard(){
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}