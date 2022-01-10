// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract pointsData {

    struct layerData {
        bytes data;
    }

    mapping(uint256 => layerData) public CellLayerData;

    function addDataToLayer(string memory data, uint256 tokenId) external {
        CellLayerData[tokenId].data = abi.encodePacked(data);
    }

    function multiAdd(string[] memory data, uint256[] memory tokenId) external {
        require(data.length == tokenId.length);
        
        for (uint256 i=0; i<tokenId.length; i++) {
            CellLayerData[tokenId[i]].data = abi.encodePacked(data[i]);
        }
    }

    function readId(uint256 tokenId) external view returns (string memory) {
        return string(CellLayerData[tokenId].data);
    }


}