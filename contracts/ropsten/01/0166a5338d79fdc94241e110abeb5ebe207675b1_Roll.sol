pragma solidity ^0.4.24;

contract Roll{
    address public manager;
    address[] public players;
    uint256 size;
    uint256 multiplier;
    uint256 win;
    uint256 luck;
    
    constructor() public{
        manager = msg.sender;
    }

    function random() private view returns (uint8) {
    return uint8(uint256(keccak256(block.timestamp, block.difficulty))%100); // random 0-99
    }

    function bet(uint8 under) public payable{
        require(msg.value > .01 ether);
        players.push(msg.sender);
        size = msg.value;

        uint8 _random = random();

        if (_random + under >= 100) {
          multiplier = 100/under;
          win = size * multiplier;
          luck = .001 ether;
          if (address(this).balance > 0){
            msg.sender.transfer(win);
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