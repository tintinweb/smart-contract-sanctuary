/**
 *Submitted for verification at Etherscan.io on 2020-12-03
*/

/*
███╗   ██╗███████╗████████╗     ██████╗ ██████╗  ██████╗ ██████╗     
████╗  ██║██╔════╝╚══██╔══╝     ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗    
██╔██╗ ██║█████╗     ██║        ██║  ██║██████╔╝██║   ██║██████╔╝    
██║╚██╗██║██╔══╝     ██║        ██║  ██║██╔══██╗██║   ██║██╔═══╝     
██║ ╚████║██║        ██║███████╗██████╔╝██║  ██║╚██████╔╝██║         
╚═╝  ╚═══╝╚═╝        ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝
presented by LexDAO LLC
// SPDX-License-Identifier: GPL-3.0-or-later
*/
pragma solidity 0.7.5;

interface IERC20TransferFrom { // interface for erc20 token `transferFrom()`
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC721ListingTransferFrom { // interface for erc721 token listing and `transferFrom()`
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFT_DROP { // drop tokens on enumerable NFT owners
    function dropERC721ParallelSeries(address erc721, address erc721ToDrop) external { // drop parallel erc721 series on erc721 owners
        IERC721ListingTransferFrom nft = IERC721ListingTransferFrom(erc721);
        uint256 count;
        uint256 length = nft.totalSupply();
        
        for (uint256 i = 0; i < length; i++) {
            IERC721ListingTransferFrom(erc721ToDrop).transferFrom(msg.sender, nft.ownerOf(nft.tokenByIndex(count)), IERC721ListingTransferFrom(erc721ToDrop).tokenByIndex(count));
            count++;
        }
    }
    
    /*******************
    ERC20 DROP FUNCTIONS
    *******************/
    function dropDetailedSumERC20(address erc20, address erc721, uint256[] calldata amount) external { // drop detailed erc20 amount on erc721 owners ("I want to give 10 DAI to 1st, 20 DAI to 2nd...")
        IERC721ListingTransferFrom nft = IERC721ListingTransferFrom(erc721);
        uint256 count;
        uint256 length = nft.totalSupply();
        require(amount.length == length, "!amount/length");
        
        for (uint256 i = 0; i < length; i++) {
            IERC20TransferFrom(erc20).transferFrom(msg.sender, nft.ownerOf(nft.tokenByIndex(count)), amount[i]);
            count++;
        }
    }
    
    function dropFixedSumERC20(address erc20, address erc721, uint256 amount) external { // drop erc20 amount on erc721 owners ("I want to give 20 DAI to each")
        IERC721ListingTransferFrom nft = IERC721ListingTransferFrom(erc721);
        uint256 count;
        
        for (uint256 i = 0; i < nft.totalSupply(); i++) {
            IERC20TransferFrom(erc20).transferFrom(msg.sender, nft.ownerOf(nft.tokenByIndex(count)), amount);
            count++;
        }
    }
    
    function dropLumpSumERC20(address erc20, address erc721, uint256 amount) external { // drop erc20 amount evenly on erc721 owners ("I want to spread 100 DAI across all")
        IERC721ListingTransferFrom nft = IERC721ListingTransferFrom(erc721);
        uint256 count;
        uint256 length = nft.totalSupply();
        
        for (uint256 i = 0; i < length; i++) {
            IERC20TransferFrom(erc20).transferFrom(msg.sender, nft.ownerOf(nft.tokenByIndex(count)), amount / length);
            count++;
        }
    }
}