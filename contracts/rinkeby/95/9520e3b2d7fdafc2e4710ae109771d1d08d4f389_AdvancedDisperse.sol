/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract AdvancedDisperse {
    
    function disperseEther(address payable[] memory recipients, uint256[] memory values) external payable {
        for(uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if(balance > 0)
            payable(msg.sender).transfer(balance);
    }

    function disperseToken(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        uint256 total = 0;
        for(uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for(uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function disperseTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        for(uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
    
    function disperseNft(IERC721 token, address[] memory recipients, uint256[] memory values) external {
        for(uint256 i = 0; i < recipients.length; i++){
            require(token.isApprovedForAll(msg.sender, address(this)) || token.getApproved(values[i]) == address(this));
            token.safeTransferFrom(msg.sender, recipients[i], values[i]);
        }
    }
    
}