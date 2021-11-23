/**
 *Submitted for verification at FtmScan.com on 2021-11-23
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
}

interface Woolf {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BarnApi {
    Woolf woolf = Woolf(0xD04F2119B174c14210E74E0EBB4A63a1b36AD409);

    function getUserWoolf(
        Barn barn,
        address user,
        uint256 begin,
        uint256 end
    ) public view returns (uint256[] memory wollfs, uint256 i) {
        uint256 idx;
        uint256 tid;
        address _user;
        wollfs = new uint256[](100);
        for (i = begin; i <= end; i++) {
            (tid, , _user) = barn.barn(i);
            if (_user == user) {
                wollfs[idx++] = tid;
            } else if (tid == 0) {
                _user = barn.getWolfOwner(i);
                if (_user == user && woolf.ownerOf(i) == address(barn)) {
                    wollfs[idx++] = i;
                }
            }
            if (idx == 101) return (wollfs, i);
        }
    }
}