/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract GetRandom{

    struct Card {
        bool selected;
        address owner;
    }

    mapping(uint256 => Card) cards;

    uint256 cardsRemaining;
    uint256 x;
    uint256 y;
    
    //test
    uint256 public getRandomCard;
    uint256 public getRandomSide;
    
    constructor (uint256 _x, uint256 _y) {
        x = _x;
        y = _y;
        cardsRemaining = x * y;
    }


    function randomCard() public returns(uint256) {
        //request for a random index from existing cards
        uint256 randIndex = (randomHash() % cardsRemaining);

        //select from remaining cards
        uint256 counter = 0;
        uint256 selector = 0;
        do {
            if (! cards[selector].selected){
                counter ++;
            } 
            selector ++;
        } while(counter <= randIndex);
        selector --;

        //make sure the card would not be selected again
        cardsRemaining --;
        cards[selector].selected = true;
        
        //test
        getRandomCard = selector;

        return selector;
    }

    function randomSide(uint256 cardNum) public returns(uint256) {

        uint256[4] memory sidesAvailable;

        uint256 selectedSide;

        //available sides
        uint256 index = 0;
        //right side
        if (cardNum % x != x-1 && !cards[cardNum + 1].selected) {
            sidesAvailable[index] = cardNum + 1;
            index++;
        }
        //top side
        if (cardNum >= x && !cards[cardNum - x].selected) {
            sidesAvailable[index] = cardNum - x;
            index++;
        }
        //left side
        if (cardNum % x != 0 && !cards[cardNum - 1].selected) {
            sidesAvailable[index] = cardNum - 1;
            index++;
        }
        //bottom side
        if (cardNum < x*y - x && !cards[cardNum + x].selected) {
            sidesAvailable[index] = cardNum + x;
            index++;
        }


        if (index == 0){
            selectedSide = randomCard();
        } else if (index == 1) {
            selectedSide = sidesAvailable[0];
        } else {
            //request for a random index from available sides
            uint256 randIndex = (randomHash() % index);

            selectedSide = sidesAvailable[randIndex];
        }
        
        
        //test
        getRandomSide = selectedSide;
        
        return selectedSide;
    }


    function randomHash() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
}