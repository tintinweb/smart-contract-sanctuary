pragma solidity ^0.4.24;

contract Lottery {
    address public owner;
    address[] public players;

    constructor() public {
        owner = msg.sender;
    }
    
    modifier ownerOnly() {
      require(msg.sender == owner);
      _;
    }
    
    function enter() public payable {
        require(msg.value > .0001 ether);
        players.push(msg.sender);
    }
    // 1 - 隨機挑選(helper function)
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }
    
    function pickWinner() public ownerOnly{
        // 2 - 挑選贏家
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        // 3 - Reset
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
      return players;
    }
}