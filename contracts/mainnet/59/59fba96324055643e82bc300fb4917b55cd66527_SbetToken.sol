// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract SbetToken is ERC20("Sport Bet Token", "SBET") {
    using SafeMath for uint256;

    constructor(
        address team,
        address marketing,
        address airdrop,
        address dev, 
        address bounty, 
        address crowdsale
    ) {
        // Fixed supply of 3 billion tokens;
        uint256 fixedSupply = 3000000000000000000000000000;
        // Mint the full supply
        _mint(msg.sender, fixedSupply);

        approve(msg.sender, totalSupply());

        transferFrom(msg.sender, crowdsale, fixedSupply.div(100).mul(20));
        transferFrom(msg.sender, crowdsale, fixedSupply.div(100).mul(30));

        transferFrom(msg.sender, crowdsale, fixedSupply.div(100).mul(35));

        transferFrom(msg.sender, team, fixedSupply.div(100).mul(10));
        transferFrom(msg.sender, marketing, fixedSupply.div(100).mul(2));
        transferFrom(msg.sender, airdrop, fixedSupply.div(100).mul(1));
        transferFrom(msg.sender, dev, fixedSupply.div(100).mul(1));
        transferFrom(msg.sender, bounty, fixedSupply.div(100).mul(1));
    }
    

}