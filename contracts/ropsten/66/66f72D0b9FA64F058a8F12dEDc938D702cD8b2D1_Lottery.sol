pragma solidity 0.4.25;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }
    
    function pickWinner() public onlyManager returns (address) {
        uint index = random() % players.length;
        lastWinner = players[index];
        
        lastWinner.transfer(address(this).balance);
        
        players = new address[](0);
        
        return lastWinner;
    }
    
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}