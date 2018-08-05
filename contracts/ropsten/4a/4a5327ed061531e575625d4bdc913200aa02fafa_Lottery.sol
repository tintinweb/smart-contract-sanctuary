pragma solidity 0.4.24;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value == 0.1 ether);
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManagerCanCall returns (address) {
        uint winnerIndex = random() % players.length;
        players[winnerIndex].transfer(address(this).balance);
        
        return players[winnerIndex];
    }
    
    modifier onlyManagerCanCall() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}