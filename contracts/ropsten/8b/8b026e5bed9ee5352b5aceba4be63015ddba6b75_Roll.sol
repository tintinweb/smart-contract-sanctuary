pragma solidity ^0.4.24;

contract Roll{
    address public manager;
    address[] public players;
    uint256 size;
    uint256 multiplier;
    uint256 win;
    
    constructor() public{
        manager = msg.sender;
    }

    function random() private view returns (uint8) {
    return uint8(uint256(keccak256(block.timestamp, block.difficulty))%100); // random 0-99
    }

    function bet(uint8 number) public payable{
        require(msg.value > .01 ether);
        players.push(msg.sender);
        size = msg.value;

        uint8 _random = random();

        if (_random + number >= 100) {
          multiplier = 1/number;
          win = size * multiplier;
          uint256 luck = .001 ether;
          if (address(this).balance > 0){
            msg.sender.transfer(multiplier);
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