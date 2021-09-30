/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


interface IERC721 {
   
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

}

interface IERC1155 {
    
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function isApprovedForAll(address account, address operator) external view returns (bool);
    
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}


interface IERC20 {
    
    function transfer(address to, uint256 value) external returns (bool);
    
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Disperse {
    function disperseEther(address[] calldata recipients, uint256[] calldata values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);
    }

    function disperseTokenERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total), "ERC20: transfer caller is not approved");
        
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    
    function disperseTokenERC721(IERC721[] calldata tokens, address[] calldata recipients, uint256[] calldata tokenIds) external {
        require(tokens.length == recipients.length, "ERC721: tokens and recipients length mismatch");
        require(tokenIds.length == recipients.length, "ERC721: recipients and tokenIds length mismatch");

        for (uint256 i = 0; i < recipients.length; i++){
            require(tokens[i].ownerOf(tokenIds[i]) == msg.sender, "ERC721: transfer caller is not owner");
            require(tokens[i].isApprovedForAll(msg.sender, address(this)), "ERC721: transfer caller is not approved");
        }
            
        for (uint256 i = 0; i < recipients.length; i++)
            tokens[i].safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
    }
    
    function disperseTokenERC1155(IERC1155[] calldata tokens, address[] calldata recipients, uint256[] calldata tokenIds, uint256[] calldata amounts, bytes[] calldata datas) external {
        require(tokens.length == recipients.length, "ERC1155: tokens and recipients length mismatch");
        require(tokenIds.length == recipients.length, "ERC1155: tokens and recipients length mismatch");

        for (uint256 i = 0; i < recipients.length; i++){
            require(tokens[i].balanceOf(msg.sender,tokenIds[i]) >= amounts[i], "ERC1155: insufficient balance for transfer");
            require(tokens[i].isApprovedForAll(msg.sender, address(this)), "ERC1155: transfer caller is not approved");
        }
            
        for (uint256 i = 0; i < recipients.length; i++)
            tokens[i].safeTransferFrom(msg.sender, recipients[i], tokenIds[i], amounts[i], datas[i]);
    }
}