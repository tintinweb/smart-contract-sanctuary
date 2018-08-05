pragma solidity 0.4.24;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value == 1 ether, &quot;Require 1 ether&quot;);
        
        players.push(msg.sender);
    }
    
    function random() private view onlyManagerCanCall returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty)));
    }
    
    function pickWinner() public returns (address) {
        uint index = random() % players.length;
        lastWinner = players[index];
        lastWinner.transfer(address(this).balance);
        
        players = new address[](0);
        return lastWinner;
    }
    
    modifier onlyManagerCanCall() {
        require(msg.sender == manager, &quot;Only manager can call&quot;);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}