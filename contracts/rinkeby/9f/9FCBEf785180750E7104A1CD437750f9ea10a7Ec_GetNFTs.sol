// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
contract GetNFTs {
    function GetNFTsForAddress(
        address _owner,
        address _nftAddress,
        uint256 _tokenIdFrom,
        uint256 _tokenIdTo
    ) external view returns (uint256[] memory) {
        uint256 selectedTokenIds = 0;
        uint256[] memory selectedTokenIdsList = new uint256[](50);

        IERC721 nft = IERC721(_nftAddress);

        for (uint256 i = _tokenIdFrom; i <= _tokenIdTo; i++) {
            try nft.ownerOf(i) returns (address owner) {
                if (owner == _owner) {
                    selectedTokenIdsList[selectedTokenIds] = i;
                    selectedTokenIds++;
                }
            } catch {}
        }

        return selectedTokenIdsList;
    }
}