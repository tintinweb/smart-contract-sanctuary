// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract SbetToken is ERC20("Sports Bet Token", "SBET") {
    using SafeMath for uint256;

    constructor (
        address team,
        address marketing,
        address dev, 
        address bounty, 
        address ico,
        address presale
    ) {
        // Fixed supply of 3.5 billion tokens;
        uint256 fixedSupply = 3500000000000000000000000000;
        // Mint the full supply
        _mint(msg.sender, fixedSupply);

        approve(msg.sender, totalSupply());

        transferFrom(msg.sender, presale, fixedSupply.div(100).mul(3));
        transferFrom(msg.sender, ico, fixedSupply.div(100).mul(8));

        transferFrom(msg.sender, team, fixedSupply.div(100).mul(10));
        transferFrom(msg.sender, marketing, fixedSupply.div(100).mul(1));
        transferFrom(msg.sender, dev, fixedSupply.div(100).mul(1));
        transferFrom(msg.sender, bounty, fixedSupply.div(100).mul(1));
    }

}