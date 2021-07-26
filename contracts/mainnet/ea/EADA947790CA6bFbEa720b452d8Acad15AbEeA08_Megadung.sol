// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;

import "./ERC20.sol";
import "./MinterRole.sol";
import "./IDung.sol";

contract Megadung is ERC20, MinterRole {
    using SafeMath for uint256;

    uint256 public constant DUNG_PER_MEGADUNG = 1e15;

    IDung public dung;

    constructor(IDung _dung)
        ERC20("Degen$ Farm Giga Mega Dung", "MEGADUNG")
        MinterRole(msg.sender)
    {
        dung = _dung;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
    * @dev Owner can claim any tokens that transferred
    * to this contract address
    */
    function reclaimToken(ERC20 token) external onlyMinter {
        require(address(token) != address(0));
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev This function implement proxy for befor transfer hook form OpenZeppelin ERC20.
     *
     * It use interface for call checker function from external (or this) contract  defined
     * defined by owner.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(to != address(this), "This contract not accept tokens" );
    }

    function wrap(uint amount) external {
        dung.transferFrom(msg.sender, address(this), amount);
        dung.burn(amount);
        _mint(msg.sender, amount/DUNG_PER_MEGADUNG);
    }

    function unwrap(uint amount) external {
        _burn(msg.sender, amount);
        dung.mint(msg.sender, amount*DUNG_PER_MEGADUNG);
    }

}