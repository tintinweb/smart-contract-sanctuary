// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IterationsTest {
    mapping (uint256 => address) public nft;

    function set(uint256 tokenId) public {
        nft[tokenId] = msg.sender;
    }

    function loop(address addr, uint32 from, uint32 to) public view returns (uint32[] memory) {
        uint32 count;
        for (uint32 i = from; i <= to; i++) {
            if (nft[i] == addr)
                count++;
        }

        uint32[] memory own = new uint32[](count);
        uint32 num;
        for (uint256 i = from; i <= to; i++) {
            if (nft[i] == addr)
                own[num++] = uint32(i);
        }

        return own;
    }

}

