//SPDX-License-Identifier: NONE
pragma solidity ^0.8.7;

contract NFTContract {
    function restrictedMint(address, uint256) public {}
    function ownerOf(uint256 tokenId) external view returns (address owner) {}
}

// Contract to give free mints to owners of first 256 goofballs
contract Gen1FreeMinter {
    NFTContract private delegate;
    // yay our first drop exactly fits in one EVM variable    
    uint256 mintsUsed;

    constructor(address nftContract) {
        delegate = NFTContract(nftContract);
        mintsUsed = 0;
    }

    function freeMintFor(uint256[] memory id) public {
        // check that these ids haven't been used yet
        uint256 newState = mintsUsed;
        for (uint256 i = 0; i < id.length; i++) {
            require(id[i] >= 1 && id[i] <= 256, "id out of range");

            uint256 mask = (1 << (id[i] - 1));
            require((newState & mask) == 0, "free mint already used");
            newState = (newState | mask);
            // check that the sender actually owns this id
            require(delegate.ownerOf(id[i]) == msg.sender, "id not owned");
        }

        mintsUsed = newState;

        // award free mints
        delegate.restrictedMint(msg.sender, id.length);
    }

    function isMintUsed(uint256 id) public view returns (bool) {
        require(id >= 1 && id <= 256, "id out of range");
        uint256 mask = (1 << (id - 1));
        return (mintsUsed & mask) != 0;
    }
}