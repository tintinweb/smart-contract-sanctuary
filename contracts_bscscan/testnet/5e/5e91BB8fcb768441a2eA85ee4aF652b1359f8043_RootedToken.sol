// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT: upToken

An upToken is a token that gains in value
against whatever token it is paired with.

- Raise any token using the Market Generation
and Market Distribution contracts
- An equal amount of upToken will be minted
- combine with an ERC-31337 version of the 
raised token.
- Send LP tokens to the Liquidity Controller
for efficent access to market features

*/

import "./LiquidityLockedERC20.sol";

contract RootedToken is LiquidityLockedERC20("Hobbs Network Token", "HNW")
{
    address public minter;

    function setMinter(address _minter) public ownerOnly()
    {
        minter = _minter;
    }

    function mint(uint256 amount) public
    {
        require(msg.sender == minter, "Not a minter");
        require(this.totalSupply() == 0, "Already minted");
        _mint(msg.sender, amount);
    }
}