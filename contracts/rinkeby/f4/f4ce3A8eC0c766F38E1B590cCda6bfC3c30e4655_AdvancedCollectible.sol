/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// File: AdvancedCollectible.sol

contract AdvancedCollectible{
    uint256 public tokenCounter;
    // enum Breed{PUG, SHIBA_INU, BRENARD}
    // // add other things
    // mapping(bytes32 => address) public requestIdToSender;
    // mapping(bytes32 => string) public requestIdToTokenURI;
    // mapping(uint256 => Breed) public tokenIdToBreed;
    // mapping(bytes32 => uint256) public requestIdToTokenId;
    // event requestedCollectible(bytes32 indexed requestId); 


    // bytes32 internal keyHash;
    // uint256 internal fee;
    // uint256 public randomResult;
    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash)
    public 
    {
        // tokenCounter = 0;
        // keyHash = _keyhash;
        // fee = 0.1 * 10 ** 18;
    }

    // function createCollectible(string memory tokenURI, uint256 userProvidedSeed) 
    //     public returns (bytes32){
    //         bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
    //         requestIdToSender[requestId] = msg.sender;
    //         requestIdToTokenURI[requestId] = tokenURI;
    //         emit requestedCollectible(requestId);
    // }

    // function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
    //     // address dogOwner = requestIdToSender[requestId];
    //     // string memory tokenURI = requestIdToTokenURI[requestId];
    //     // uint256 newItemId = tokenCounter;
    //     // _safeMint(dogOwner, newItemId);
    //     // _setTokenURI(newItemId, tokenURI);
    //     // Breed breed = Breed(randomNumber % 3); 
    //     // tokenIdToBreed[newItemId] = breed;
    //     // requestIdToTokenId[requestId] = newItemId;
    //     tokenCounter = tokenCounter + 1;
    // }
}