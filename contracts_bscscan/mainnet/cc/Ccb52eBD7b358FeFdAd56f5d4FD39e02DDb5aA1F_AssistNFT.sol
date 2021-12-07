/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IERC721 {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function getPrice(uint tokenId) external view returns (uint price);
    function ownerOf(uint256 _tokenId) external view returns (address);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenCounter() external view returns (uint256);
}

contract AssistNFT {
    function getERC721HolderTokens(address erc721Address, address holder)
        public
        view
        returns (string[] memory tokenURIs, uint256[] memory tokenIds, uint256[] memory prices)
    {
        IERC721 token = IERC721(erc721Address);

        uint256 tokenCounter = token.tokenCounter();
        uint256 balance = token.balanceOf(holder);

        string[] memory tokenURIs_ = new string[](balance);
        uint256[] memory tokenIds_ = new uint256[](balance);
        uint256[] memory prices_ = new uint[](balance);

        uint256 index = 0;

        for (uint256 tokenId = 0; tokenId < tokenCounter; tokenId++) {
            if (holder == token.ownerOf(tokenId)) {
                tokenURIs_[index] = token.tokenURI(tokenId);
                tokenIds_[index] = tokenId;
                prices_[index] = token.getPrice(tokenId);
                index++;
            }
        }
        return (tokenURIs_, tokenIds_, prices_);
    }

    function getLastNFT(address erc721Address, address holder) public view  returns (string memory tokenURI) {
 
        IERC721 token = IERC721(erc721Address);
        uint256 tokenCounter = token.tokenCounter();

        string memory tokenURI_;

        for (uint256 tokenId = 0; tokenId < tokenCounter; tokenId++) {
            if (holder == token.ownerOf(tokenId)) {
                tokenURI_ = token.tokenURI(tokenId);
            }
        }
        return tokenURI_;
    }
}