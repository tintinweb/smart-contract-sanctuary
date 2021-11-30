// BZC DAO Token

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20TransferFee.sol";


contract BZCToken is ERC20, ERC20Capped, ERC20Burnable, Pausable, Ownable, ERC20Permit, ERC20TransferFee {
    constructor(string memory name_, string memory symbol_, uint256 transferFee_, address payable feeRecipient_)
        ERC20(name_, symbol_)
        ERC20Capped(10_000_000_000 * 1e7)
        ERC20Permit(name_)
        ERC20TransferFee(transferFee_, feeRecipient_)
    {
        pause();
    }

    function decimals() public view virtual override returns (uint8) {
        return 7;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        require(accounts.length == amounts.length, "invalid data");

        for (uint256 i; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override
    {
        require(from == address(0) || !paused() , "transfer while paused");  // allow mint
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        ERC20Capped._mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal
    override(ERC20TransferFee, ERC20) virtual {
        ERC20TransferFee._transfer(sender, recipient, amount);
    }
}

// and breath entered them; they came to life and stood up on their feet—a vast army.