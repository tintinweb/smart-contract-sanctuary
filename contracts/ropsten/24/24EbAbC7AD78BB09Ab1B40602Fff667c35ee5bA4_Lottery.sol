pragma solidity ^0.4.24;

contract Lottery{
    
    address public manager;
    address[] public players;
    address public lastWinner;
    
    constructor(){
        manager = msg.sender;
    }
    
    function enter() public payable {
        //y/c moi nguoi 1eth
        require(msg.value == 0.1 ether);
        
        players.push(msg.sender);//address cua nguoi goi ham
    }
    
    //view chi doc, ko thay doi data
    function random() private view returns (uint){
        return uint(keccak256(block.difficulty, now, players));    
        
    }
    
    function pickWinner() public onlyManagerCanCall returns (address) {
        
        uint index = random() % players.length;
        lastWinner = players[index];
        players[index].transfer(address(this).balance);
        
        //reset tro choi
        players = new address[](0);
        return lastWinner;
    }
    
    modifier onlyManagerCanCall() {
        //phai la nguoi tao smart contract
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]){
        return players;
    }
    
}