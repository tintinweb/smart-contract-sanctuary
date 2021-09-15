/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;


/// @author dom
interface Wagmipet {
    function feed() external;
    function clean() external;
    function play() external;
    function sleep() external;
    
    function getHunger() external view returns (uint256);
    function getUncleanliness() external view returns (uint256);
    function getBoredom() external view returns (uint256);
    function getSleepiness() external view returns (uint256);
}


/// @author 0age
contract NagmiPet {
    Wagmipet public constant wagmipet = Wagmipet(
        0xeCB504D39723b0be0e3a9Aa33D646642D1051EE1
    );

    constructor() {
        toughLove();
    }
    
    function toughLove() public returns (
        uint256 boredom,
        uint256 sleepiness,
        uint256 hunger,
        uint256 uncleanliness
    ) {
        hunger = wagmipet.getHunger();
        uncleanliness = wagmipet.getUncleanliness();
        boredom = wagmipet.getBoredom();
        sleepiness = wagmipet.getSleepiness();

        if (uncleanliness > 0) {
            wagmipet.clean();
            uncleanliness = 0;
        }
        
        if (sleepiness > 0) {
            wagmipet.sleep();
            sleepiness = 0;
            uncleanliness += 5;
        }
        
        
        if (hunger > 80) {
            wagmipet.feed();
            hunger = 0;
            boredom += 10;
            uncleanliness += 3;
        }
        
        wagmipet.play();
        boredom = 0;
        hunger += 10;
        sleepiness += 10;
        uncleanliness += 5;
        
        while (uncleanliness < 35) {
            wagmipet.feed();
            hunger = 0;
            boredom += 10;
            uncleanliness += 3;
            
            wagmipet.play();
            boredom = 0;
            hunger += 10;
            sleepiness += 10;
            uncleanliness += 5;
        }

        while (sleepiness < 80) {
            wagmipet.play();
            boredom = 0;
            hunger += 10;
            sleepiness += 10;
            uncleanliness += 5;
        }
        
        while (boredom < 80) {
            wagmipet.feed();
            hunger = 0;
            boredom += 10;
            uncleanliness += 3;
        }
    }
}