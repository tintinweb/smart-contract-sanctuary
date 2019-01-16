pragma solidity ^0.4.24;

contract Roll{
    address public manager;
    address[] public players;

    constructor() public{
        manager = msg.sender;
    }

    function random() private view returns (uint8) {
    return uint8(uint256(keccak256(block.timestamp, block.difficulty))%100); // random 0-99
    }

    function enter() public payable{
        require(msg.value > .01 ether);

        players.push(msg.sender);


        uint8 _random = random();

        if (_random + 50 >= 100) {
          uint256 balance = .05 ether;
          uint256 luck = .01 ether;
          if (balance > 0){
            msg.sender.transfer(balance);
          }
        } else if (_random + 10 >= 100) {
          msg.sender.transfer(luck);
        }
    }


    modifier restricted() {
        // Ensure the participant awarding the ether is the manager
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address[]) {
        // Return list of players
        return players;
    }
}