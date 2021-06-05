/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/ILevelContract.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;

interface ILevelContract {
    function name() external returns (string memory);

    function credits() external returns (uint256);
}


// File contracts/ICourseContract.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;

interface ICourseContract {
    function creditToken(address challenger) external;

    function addLevel(address levelContract) external;
}


// File contracts/levels/ImFeelingLucky.sol

// Flip a coin, 10 heads to win
// Once per block
// https://ethernaut.openzeppelin.com/level/0x4dF32584890A0026e56f7535d0f2C6486753624f
pragma solidity ^0.5.17;


// Simple smart contract, goal is simply to call the helloWorld function
contract ImFeelingLucky is ILevelContract {
    string public name = "I'm Feeling Lucky";
    uint256 public credits = 30e18;
    ICourseContract public course;

    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    struct PlayerData {
        uint256 consecutiveWins;
        uint256 lastFlip;
    }

    mapping(address => PlayerData) public player;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function flip(bool guess, address challenger) public allowedToFlip(challenger) {
        player[challenger].lastFlip = block.number;
        uint256 entropy = uint256(blockhash(block.number - 1));

        uint256 coinFlip = entropy / FACTOR;
        bool head = coinFlip % 2 == 0 ? true : false;

        if (head == guess) {
            player[challenger].consecutiveWins += 1;
            if (player[challenger].consecutiveWins == 10) {
                course.creditToken(challenger);
            }
        } else {
            player[challenger].consecutiveWins = 0;
        }
    }

    modifier allowedToFlip(address challenger) {
        require(
            player[challenger].lastFlip < block.number,
            "Challenger cannot flip again in this block"
        );
        _;
    }
}