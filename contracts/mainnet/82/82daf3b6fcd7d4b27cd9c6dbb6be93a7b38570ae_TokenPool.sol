/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.7;

abstract contract TokenLike {
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function mint(address, uint) virtual public;
    function burn(address, uint) virtual public;
    function approve(address, uint256) virtual external returns (bool);
    function transfer(address, uint256) virtual external returns (bool);
    function transferFrom(address,address,uint256) virtual external returns (bool);
}

contract TokenPool {
    TokenLike public token;
    address   public owner;

    constructor(address token_) public {
        token = TokenLike(token_);
        owner = msg.sender;
    }

    // @notice Transfers tokens from the pool (callable by owner only)
    function transfer(address to, uint256 wad) public {
        require(msg.sender == owner, "unauthorized");
        require(token.transfer(to, wad), "TokenPool/failed-transfer");
    }

    // @notice Returns token balance of the pool
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}