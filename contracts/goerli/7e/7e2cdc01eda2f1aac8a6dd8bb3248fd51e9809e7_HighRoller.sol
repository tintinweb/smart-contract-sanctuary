/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity >=0.7.0 <0.9.0;

contract HighRoller {

    uint roll;

    function rollTheDice(uint guess) public returns (string memory) {
        roll = getRandomNumber(6);
        if ( roll == guess ){
            // send some eth to the players account
            return "Winner";
        }else{
            // steal some eth from the players account :)
            return "Looser";
        }
    }

    // This is only psudorandom - used for testing purposes only.
    function getRandomNumber(uint max) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % max +1;
    }

    function viewLastRoll() public view returns (uint){
        return roll;
    }
}