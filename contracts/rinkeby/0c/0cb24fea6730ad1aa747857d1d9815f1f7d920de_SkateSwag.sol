/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.4;

contract SkateSwag {
    
    uint level;

    uint beerPrice = 0.001 ether;
    uint beerDrinkingTime = 20 minutes;
    uint32 beerFreeTime;

    uint normalPracticeTime = 20 minutes;
    uint practiceTimeWithBeer = 10 minutes;
    uint32 newPracticePossibility;
    
    function practice () external {
        if(block.timestamp >= newPracticePossibility) {
            if(block.timestamp >= beerFreeTime) {
                // dude is currently sober
                level = level + 2;
                newPracticePossibility = uint32(block.timestamp + normalPracticeTime);
            }
            else {
                // dude is drinking a beer currently
                level = level + 1;
                newPracticePossibility = uint32(block.timestamp + practiceTimeWithBeer);
            }
        }
    }
    
    function currentLevel () external view returns(uint) {
        return level;
    }

    function isDrinkingBeer() external view returns(bool) {
        if(block.timestamp >= beerFreeTime) {
            return false;
        }
        else {
            return true;
        }
    }

    function drinkBeer () external payable {
        require(msg.value == beerPrice, "The amount of Ether sent does not equal to the price of beer.");
        require(block.timestamp >= newPracticePossibility, "It's too early to practice again.");
        beerFreeTime = uint32(block.timestamp + beerDrinkingTime);
    }
}