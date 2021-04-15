// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

// BaskBar is the coolest bar in town. You come in with some Bask, and leave with more! The longer you stay, the more Bask you get.
//
// This contract handles swapping to and from xBask, BaskSwap's staking token.
contract XBASK is ERC20("xBASK", "xBASK") {
    using SafeMath for uint256;
    IERC20 public bask = IERC20(0x44564d0bd94343f72E3C8a0D22308B7Fa71DB0Bb);

    // Define the Bask token contract
    constructor() {}

    // xBASK/BASK ratio
    function getRatio(uint256 _share) public view returns (uint256) {
        // Gets the amount of xBask in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Bask the xBask is worth
        uint256 what = _share.mul(bask.balanceOf(address(this))).div(totalShares);

        return what;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Bask and mints xBask
    function enter(uint256 _amount) public {
        // Gets the amount of Bask locked in the contract
        uint256 totalBask = bask.balanceOf(address(this));
        // Gets the amount of xBask in existence
        uint256 totalShares = totalSupply();
        // If no xBask exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalBask == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xBask the Bask is worth. The ratio will change overtime, as xBask is burned/minted and Bask deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalBask);
            _mint(msg.sender, what);
        }
        // Lock the Bask in the contract
        bask.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Bask and burns xBask
    function leave(uint256 _share) public {
        // Gets the amount of xBask in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Bask the xBask is worth
        uint256 what = _share.mul(bask.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        bask.transfer(msg.sender, what);
    }
}