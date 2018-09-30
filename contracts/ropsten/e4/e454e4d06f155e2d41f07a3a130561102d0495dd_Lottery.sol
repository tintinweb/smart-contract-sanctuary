pragma solidity ^0.4.23;
 
 contract Lottery {
     address public manager;
     address[] public players;
     
     constructor() public {
         manager = msg.sender;
     }
     
     //入场
     function enter() public payable {
         require(msg.value > .01 ether);
         players.push(msg.sender);
     }
     
     //产生一个随机数
     function random() private view returns(uint) {
         return uint(keccak256(block.difficulty, now, players));
     }
     
     //庄家开牌，判断赢家
     function pickWinner() public restricted {
         uint index = random() % players.length;
         players[index].transfer(address(this).balance);
         players = new address[](0);
     }
     
     //
     modifier restricted() {
         require(msg.sender == manager);
         _;
     }
     
     
     function getPlayers() public view returns (address[]) {
         
         return players;
     }
 }