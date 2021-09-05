/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDice {

    /**
     * @dev Returns the weight of the side of the die
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getSideWeight(uint256 tokenId, uint256 side) external pure returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract DiceRoller { 

    IDice dice = IDice(0x36222D5969da94e05Aa953D2fe266dF139756e88);

    function rollIfOwner(uint256 tokenId, uint256 sideCount, address user) public view returns (uint256) {
        require(isOwner(tokenId, user));
        return roll(tokenId, sideCount, 1);
    }

    function roll(uint256 tokenId, uint256 sideCount) public view returns (uint256) {
        return roll(tokenId, sideCount, 1);
    }
    
    // Roll the n sided die from your set
    // Seed can be an additional sources of entropy
    function roll(uint256 tokenId, uint256 sideCount, uint256 seed) public view returns (uint256) {
        require(sideCount == 4 ||
                sideCount == 6 ||
                sideCount == 8 ||
                sideCount == 10 ||
                sideCount == 12 ||
                sideCount == 20);
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(seed, block.basefee, blockhash(block.number-1), msg.sender, address(this))));
        uint256 total = 0;
        // Add up all side weights for sides considered
        for (uint256 i = 1; i <= sideCount; i++) {
            total = total + dice.getSideWeight(tokenId, i);
        }
        pseudoRandom = pseudoRandom % total + 1;
        for (uint256 i = 1; i <= sideCount; i++) {
            uint256 sideWeight = dice.getSideWeight(tokenId, i);
            if (pseudoRandom <= sideWeight) {
                return i;
            }
            pseudoRandom = pseudoRandom - sideWeight;
        }
        revert();
    }
    
    function isOwner(uint256 tokenId, address owner) public view returns (bool) {
        return dice.ownerOf(tokenId) == owner;
    }
}