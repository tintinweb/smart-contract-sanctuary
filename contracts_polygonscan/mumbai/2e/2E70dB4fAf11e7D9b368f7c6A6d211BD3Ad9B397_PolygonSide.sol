// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface ISide {
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

contract PolygonSide {
    ISide sideContract;
    Cell[16] public cells;
    address nftCollection = 0x3616a7Bac3B94B9BB27885CbEF29e2571EdA55D1;

    struct Cell {
        string title; // TODO: define max length
        string description; // TODO: define max length
        string imageUrl;
        string hyperLink;
    }

    constructor() {
        sideContract = ISide(nftCollection);
    }

    function changeCellTitle(uint256 index, string calldata newTitle) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "Dude! You don't own this NFT!");
        cells[index].title = newTitle;
    }

    function changeCellDescription(uint256 index, string calldata newDescription) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "Dude! You don't own this NFT!");
        cells[index].description = newDescription;
    }

    function changeCellImageUrl(uint256 index, string calldata newImageUrl) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "Dude! You don't own this NFT!");
        cells[index].imageUrl = newImageUrl;
    }

    function changeCellHyperLink(uint256 index, string calldata newHyperLink) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "Dude! You don't own this NFT!");
        cells[index].hyperLink = newHyperLink;
    }

    function checkOwnership(uint256 nftIndex) internal view returns (bool) {
        uint256[] memory tokens = sideContract.tokensOfOwner(msg.sender);
        bool result = false;
        for (uint256 index; index < tokens.length; index++) {
            if (tokens[index] == nftIndex) {
                result = true;
                break;
            }
        }
        return result;
    }

    function getCellData(uint256 index) public view returns(Cell memory) {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        return cells[index];
    }

    function myNFTs() external view returns (uint256[] memory) {
        return sideContract.tokensOfOwner(msg.sender);
    }

    // TODO
    // Withdraw Coin
    // Withdraw ERC20
}