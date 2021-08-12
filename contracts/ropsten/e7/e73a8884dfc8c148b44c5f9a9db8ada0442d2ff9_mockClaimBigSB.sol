/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.4;

contract mockClaimBigSB {
    event TokensClaimed(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    mapping(address => uint256) public buggedTokens;

    mapping(address => uint256) public amlTokens;

    mapping(address => address) public morty;

    mapping(address => bool) public isClaimed;

    address constant ZERO = address(0x0);
    bool public constant claimStarted = true;

    function claim() external {
        require(morty[msg.sender] == ZERO, "Use claimFrom");
        _claim(msg.sender, msg.sender);
    }

    function canClaim(address user) external view returns (uint256) {
        return buggedTokens[user];
    }

    function claimAML() external {
        uint256 amt = amlTokens[msg.sender];
        require(amt > 0, "Not on AML list");
        amlTokens[msg.sender] = 0;
        emit TokensClaimed(msg.sender, msg.sender, amt);
    }

    function claimFrom(address from) external {
        address to = morty[from];
        require(msg.sender == to, "Wrong Morty");
        _claim(from, to);
    }

    function claimFromTo(address from, address to) external {
        require(msg.sender == morty[from], "Wrong Morty");
        _claim(from, to);
    }

    function _claim(address from, address to) internal {
        uint256 amt = buggedTokens[from];
        emit TokensClaimed(from, to, amt);
        isClaimed[from] = true;
    }

    function addMorty(address bad, address good) external {
        morty[bad] = good;
    }

    function addBugged(address user, uint256 tokens) external {
        buggedTokens[user] = tokens;
    }

    function addAml(address user, uint256 tokens) external {
        amlTokens[user] = tokens;
    }
}