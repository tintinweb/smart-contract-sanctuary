// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract JackPot {

    address payable private owner;

    uint256 private maxBet;
    address private winner;
    uint256 private lastBetTimestamp;

    constructor(){
        owner = payable(msg.sender);
        newRound();
    }

    function newRound() internal {
        maxBet = 0;
        winner = address(0x0);
        lastBetTimestamp = block.timestamp;
    }

    function bet() public payable {
        if (msg.value > maxBet) {
            maxBet = msg.value;
            winner = msg.sender;
            lastBetTimestamp = block.timestamp;
        }
    }

    function getMaxBet() public view returns (uint256, address, uint256){
        return (maxBet, winner, lastBetTimestamp);
    }

    function getJackPot() public {
        require(winner == msg.sender, 'You are not winner');
        require(lastBetTimestamp + 1 weeks < block.timestamp, "It's too early to collect your winnings");
        owner.transfer(address(this).balance / 2);
        payable(msg.sender).transfer(address(this).balance);
    }

    function getOwner() public view returns(address){
        return owner;
    }

    function transferOwnership(address newOwner) public {
        require(owner==msg.sender,'Only owner can transfer ownership');
        owner = payable(newOwner);
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}