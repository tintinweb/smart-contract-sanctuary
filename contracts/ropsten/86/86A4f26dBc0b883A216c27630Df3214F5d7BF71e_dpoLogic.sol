//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract dpoLogic {
    using SafeMath for uint256;
    using SafeMath for uint;
    using SafeMath for uint8;
    //The maximum number of poems
    uint constant public MAXPOEMS = 1000;
    //Generation rounds counter (there will be 3, because 1 round is too big for Ethereum to handle)
    uint public roundCounter = 0;
    //Limit the number of poem generation rounds
    uint constant public MAXROUNDS = 3;
    //Batch sizes for generating poems
    uint constant public BATCHSIZE = 333;
    //The array of all poems
    bytes32[MAXPOEMS] public poems;
    //A mask for selecting half of the poems
    bytes32 mask = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    //A mask to be used when selecting the other half
    bytes32 mask2 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    //A mapping to keep count of each person's vote
    mapping (address => uint256) public voteBalance;
    //An event to log all newly made poems
    event LogNewPoem(uint rejectedPoemId, bytes32 newPoem);
    //A tracker of total votes to pause the contract when at max
    uint256 public totalVotes;
    //A hard limit to the total number of votes castable
    uint256 constant public MAXVOTES = 100000;

     /*
     * A function that will delete a poem from the array of poems and
     * in its place will go a new poem created by evolvePoem function
     * @param _selectedPoemId is the index of the poem in the array poems that will be spliced   
     * @param _rejectedPoemId is the index of the poem in the array poems that will be deleted
     * @emits _rejectedPoemId, msg.sender and new poem
     * @returns nothing
    */

    function generatePoems() public {
        //Prevent regeneration
        require(roundCounter < 3, "Max poems have been reached");
        //Create the remaining poems
        for(uint i= (0 + 333 * roundCounter); i < 333 * (roundCounter + 1) ; i++) {
            poems[i] = keccak256(abi.encodePacked(i));
            emit LogNewPoem(i, poems[i]);
        }
        roundCounter++;
    }

    function selectPoem(uint _selectedPoemId, uint _rejectedPoemId) public {
        require(_selectedPoemId >= 0 && _selectedPoemId < MAXPOEMS && _rejectedPoemId >= 0 && _rejectedPoemId < MAXPOEMS && _selectedPoemId != _rejectedPoemId);
        require(totalVotes < MAXVOTES, "Max votes have been cast");
        bytes32 newPoem = evolvePoem(_selectedPoemId);
        poems[_rejectedPoemId] = newPoem;
        voteBalance[msg.sender] = voteBalance[msg.sender] + 1;
        totalVotes++;
        emit LogNewPoem(_rejectedPoemId, newPoem);
    }
    /*
     * A function to get all poems
     * @returns the array of all poems
    */
    function getPoems() view public returns (bytes32[MAXPOEMS] memory) {
        return poems;
    }

    function getVoteBalance(address _address) public view returns (uint256) {
      return voteBalance[_address];
    }

    function getTotalVotes() public view returns (uint256) {
      return totalVotes;
    }
    /*
     * A function to get a poem at a given index
     * @param id is the index of the poem in the array poems
     * @returns the poem at the index specified
    */
    function getPoem(uint id) view public returns (bytes32) {
        return poems[id];
    }
    /*
     * A function to get two different arbitrary poems
     * @returns two poems and their indices
    */
    function getTwoPoems() view public returns (uint IDofFirstPoem, bytes32 poemA, uint IDofSecondPoem, bytes32 poemB) {
        //Get one arbitrary poem ID using timestamp
        uint arbitraryPoem1 = uint(block.timestamp.mod(MAXPOEMS));
        uint arbitraryPoem2 = uint(block.number.mod(MAXPOEMS));
        //Make sure second arbitrary poem ID using block height is difference from arbitraryPoem1
        if(arbitraryPoem1 == arbitraryPoem2) {
        arbitraryPoem2++;
        }
        return (arbitraryPoem1, poems[arbitraryPoem1], arbitraryPoem2, poems[arbitraryPoem2]);
    }
     /*
     * An internal function to get the splice of two poems
     * @returns one new poem
    */   
    function evolvePoem(uint _selectedPoemId) internal view returns (bytes32) {
        //Get an arbitrary number
        uint arbitraryMate = uint(block.timestamp.mod(MAXPOEMS));
        //Move the mask to pick a random 128 contiguous bits
        uint arbitraryGeneShare = uint(block.timestamp.mod(128));
        //Move the mask
        bytes32 tempMask1 = mask << arbitraryGeneShare;
        //Create the opposite mask
        bytes32 tempMask2 = mask2 ^ tempMask1;
        //Mask selected poem to keep half
        bytes32 keep1 = poems[_selectedPoemId] & tempMask1;
        //Mask arbitrary poem to keep opposite half
        bytes32 keep2 = poems[arbitraryMate] & tempMask2;
        //Merge poems by masking one with the other
        bytes32 evolvedPoem = keep1 | keep2;

        return evolvedPoem;
    }
}