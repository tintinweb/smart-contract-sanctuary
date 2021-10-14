// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract GenerationalRandomMintable {

    uint256 private _currentMappingVersion = 0;
    uint256 private _currentStartIndex;
    
    // ---- DRAW RANDOM CARD ----
    uint256 public remaining;

    // ---- DELETABLE MAPPING ----
    mapping(uint256 => uint256) public cache;

    // ---------- GENERATIONS -------------------
    struct generation {
        uint256 index;
        uint256 numItems;
        uint256 startIndex;
    }
    generation[] private _generationsArr;

    // Update price and save in price history
    function makeNewGeneration(uint256 numItems) public {
        uint256 countGenerations = _generationsArr.length;
        generation memory newGen;
        newGen.numItems = numItems;

        if (countGenerations > 0) {
            newGen.index = _generationsArr[countGenerations - 1].index + 1;
            newGen.startIndex = _generationsArr[countGenerations - 1].startIndex + numItems;
        } else {
            newGen.index = 1;
            newGen.startIndex = 1;
        }
        // uint16 currentIndex = _totalSupply();
        _generationsArr.push(newGen);
        _currentMappingVersion++;
        _currentStartIndex = newGen.startIndex;
        remaining = numItems;
    }

    function packUints(uint256 one, uint256 two) private pure returns(uint256) {
        // is this right??
        // I am not sure how this works
        uint256 packed = (one << 16) +  two;
        return packed;
    }

    function getCache(uint256 index) private view returns(uint256) {
        // uint32 = keccak256(_currentMappingVersion, index);
        uint256 key = packUints(_currentMappingVersion, index);
        return cache[key];
    }

    function setCache(uint256 index, uint256 card) private {
        uint256 key = packUints(_currentMappingVersion, index);
        cache[key] = card;
    }

    function drawIndex() internal returns(uint256 index) {
        //RNG
        //todo: I think we can only use block.number for first random, then re-randomize
        uint256 i = uint256(blockhash(block.number - 1)) % remaining;
        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        uint256 foundCard = getCache(i);
        index = foundCard == 0 ? i : foundCard;
        // grab a number from the tail
        uint256 tailCard = getCache(remaining - 1);
        setCache(i, tailCard == 0 ? remaining - 1 : tailCard);
        
        remaining = remaining - 1;
    }

    function drawNCards(uint256 number) public returns(uint256[] memory) {
        uint256[] memory cards;
        for (uint256 i = 0; i < number; i++) {
            cards[i] = drawIndex();
        }
        return cards;
    }
}