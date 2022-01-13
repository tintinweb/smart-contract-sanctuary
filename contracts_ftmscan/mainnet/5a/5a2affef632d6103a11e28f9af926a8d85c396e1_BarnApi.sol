/**
 *Submitted for verification at FtmScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface Barn {
    function barn(uint256 tokenId)
        external
        view
        returns (
            uint16,
            uint80,
            address
        );

    function getWolfOwner(uint256 tokenId) external view returns (address);
    function isSheep(uint256 tokenId) external view returns (bool sheep);
}

interface Woolf {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BarnApi {
    Woolf woolf = Woolf(0xD04F2119B174c14210E74E0EBB4A63a1b36AD409);

    function getUserWoolf(
        Barn barn,
        address user,
        uint256 begin, // 1
        uint256 end // WGAME.totalSupply()
    ) public view returns (uint256[] memory wollfs, uint256 i) {
        uint256 idx;
        uint256 tid;
        address _user;
        // we assume that one man won't mint more than 10k animals
        wollfs = new uint256[](10000);
        // i -> token id
        for (i = begin; i <= end; i++) {
            // Get NFTs staked in the barn
            // tid: Token ID
            // _user: the owner of NFT
            (tid, , _user) = barn.barn(i);
            if (_user == user) {
                // This NFT is staked
                wollfs[idx++] = tid;
            } else if (tid == 0) {
                // ID starts from 1
                // tid == 0 means NFT is not staked or not the Sheep
                // Warn here! getWolfOwner can only get the owner for wolf NFTs
                // It may cause error when input a Sheep NFT's ID
                // Skip all Sheep NFTs
                if (barn.isSheep(i)) {
                    continue;
                }
                _user = barn.getWolfOwner(i);
                // Wolf NFT is staked in the barn
                if (_user == user && woolf.ownerOf(i) == address(barn)) {
                    wollfs[idx++] = i;
                }
            }
            if (idx == 10000) return (wollfs, i);
        }
    }
}