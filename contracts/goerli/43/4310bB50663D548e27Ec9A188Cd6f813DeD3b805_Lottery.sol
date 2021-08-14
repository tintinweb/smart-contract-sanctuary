// contracts/Lottery.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public players;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether, "Minimum bet is 0.1 ether");
        players.push(payable(msg.sender));
    }
    
    function random() private view returns (uint256) {
         return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.number, players)
                )
            );
    }
    
    function pickWinner() public onlyOwner {
        uint256 index = random() % players.length;
        address contractAddress = address(this);
        players[index].transfer(contractAddress.balance);
        players = new address payable[](0);
    }
    
    modifier onlyOwner() {
        require(msg.sender == manager, "Not authorized");
        _;
    }
    
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}

{
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