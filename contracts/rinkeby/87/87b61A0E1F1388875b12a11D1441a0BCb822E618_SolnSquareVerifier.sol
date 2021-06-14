// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ERC721Mintable.sol";
import "./ISquareVerifier.sol";

contract SolnSquareVerifier is PrivacyAssuredRealEstateOwnershipToken {

    event RealEstateOwnershipClaimed(uint256 tokenId);

    ISquareVerifier private squareVerifier;

    struct RealEstateOwnership {
        address tokenOwner;
        uint256 tokenId;
        bool hasBeenClaimed;
        bool isMinted;
    }

    mapping(bytes32 => RealEstateOwnership) private realEstateOwnerships;
    mapping(uint256 => bool) private tokenIdUsed;

    constructor(address squareVerifierAddress) PrivacyAssuredRealEstateOwnershipToken() public {
        squareVerifier = ISquareVerifier(squareVerifierAddress);
    }

    function claimRealEstateOwnership(address tokenOwner, uint256 tokenId, uint[2] memory inputs, uint[2] memory a, uint[2] memory b0, uint[2] memory b1, uint[2] memory c) public {
        require(tokenOwner != address(0), "The future token owner can not be an empty address");
        require(!tokenIdUsed[tokenId], "A token has been already used for other property - please select a different one and try again");

        bytes32 key = getRealEstateOwnershipKey(inputs);
        require(!realEstateOwnerships[key].hasBeenClaimed, "Real estate ownership could not be claimed twice");

        uint[2][2] memory b = [b0, b1];
        require(squareVerifier.verifyTx(a, b, c, inputs), "Real estate ownership verification failed");

        tokenIdUsed[tokenId] = true;
        realEstateOwnerships[key] = RealEstateOwnership(tokenOwner, tokenId, true, false);

        emit RealEstateOwnershipClaimed(tokenId);
    }

    function mintPrivacyAssuredRealEstateOwnershipToken(address tokenOwner, uint256 tokenId, uint[2] memory inputs) public {
        bytes32 key = getRealEstateOwnershipKey(inputs);

        require(tokenOwner == realEstateOwnerships[key].tokenOwner, "RealEstateOwnershipToken can be minted only after it has been claimed for the same owner");
        require(realEstateOwnerships[key].tokenId == tokenId, "RealEstateOwnershipToken can not be minted - it has been claimed for different tokenId");
        require(!realEstateOwnerships[key].isMinted, "A solution can not be minted twice");

        mint(tokenOwner, tokenId);
        realEstateOwnerships[key].isMinted = true;
    }

    function getRealEstateOwnershipKey(uint[2] memory input) private pure returns (bytes32){
        return keccak256(abi.encodePacked(input[0], input[1]));
    }
}