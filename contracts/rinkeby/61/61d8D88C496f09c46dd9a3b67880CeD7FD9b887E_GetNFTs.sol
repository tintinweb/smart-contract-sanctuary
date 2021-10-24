// Hi. If you have any questions or comments in this smart contract please let me know at:
// Whatsapp +923014440289, Telegram @thinkmuneeb, discord: timon#1213, I'm Muneeb Zubair Khan
//
//
// Smart Contract Made by Muneeb Zubair Khan
// The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash.
//
//
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        uint256[] memory selectedTokenIdsList = new uint256[](
            _tokenIdTo - _tokenIdFrom
        );

        IERC721 nft = IERC721(_nftAddress);

        for (uint256 i = _tokenIdFrom; i <= _tokenIdTo; i++) {
            try nft.ownerOf(i) returns (address owner) {
                if (owner == _owner) {
                    selectedTokenIdsList[i] = i;
                    selectedTokenIds++;
                }
            } catch {}
        }

        // get only those ids that are not 0
        return getSelectedItems(selectedTokenIdsList, selectedTokenIds);
    }

    function getSelectedItems(uint256[] memory temp, uint256 selectedCount)
        private
        pure
        returns (uint256[] memory)
    {
        uint256 someI = 0;
        uint256[] memory selectedPresales = new uint256[](selectedCount);

        for (uint256 i = 0; i < temp.length; i++)
            if (temp[i] != 0) selectedPresales[someI++] = temp[i];

        return selectedPresales;
    }
}

/*
        address _owner,
        address _nftAddress,
        uint256 _tokenIdFrom,
        uint256 _tokenIdTo
*/