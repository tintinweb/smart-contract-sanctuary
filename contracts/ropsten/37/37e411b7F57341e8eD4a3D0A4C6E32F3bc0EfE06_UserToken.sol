/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract UserToken {

    struct Token {
        address tokenAddress;
        string tokenName;
        uint256 tokenAmount;
    }
        
    mapping(address => bool) userApproved;
    mapping(address => Token[]) userTokens;

    function getUserApprovedTokens() public view returns(Token[] memory){
        if (!isUserApproved()) {
            revert('User has not approved for accessing tokens');
        }
        return userTokens[msg.sender];
    }

    function insertTokenAmount(address tokenAddress, string memory tokenName, uint256 tokenAmount) public {
        if (!isUserApproved()) {
            revert('User has not approved for accessing tokens');
        }

        bool found = false;
        Token[] storage aUserTokens = userTokens[msg.sender];
        for (uint256 i = 0; i < aUserTokens.length; i++) {
            if (address(aUserTokens[i].tokenAddress) == address(tokenAddress)) {
                aUserTokens[i].tokenAmount = tokenAmount;
                found = true;
            }
        }
        if (!found) {
            userTokens[msg.sender].push(Token(tokenAddress, tokenName, tokenAmount));
        }
    }

    function isUserApproved() private view returns(bool) {
        return userApproved[msg.sender];
    }

    function userApprovedAuthority() public {
        userApproved[msg.sender] = true;
    }

    function userRevokedAuthority() public {
        delete userApproved[msg.sender];
    }
}