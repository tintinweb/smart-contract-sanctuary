/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity 0.6.6;
 
 contract Loteria{
     
     address public admin;
     address payable [] public  jogadores;
     
     constructor() public{
         admin = msg.sender;
     }
     
     function entrar() public payable{
         
         require(msg.value > 0.1 ether);
         jogadores.push(msg.sender);
     }
     
     function random() private view returns(uint){
         return uint(keccak256(abi.encodePacked(block.difficulty, now, jogadores)));
     }
     
     function sortear() public restricted{
         
         uint indice = random() % jogadores.length;
         jogadores[indice].transfer(address(this).balance);
         jogadores = new address payable[](0);
     }
     
     modifier restricted(){
         require(msg.sender == admin);
         _;
     }
     
     function getJogadores() public view returns(address payable[] memory){
         return jogadores;
     } 
 }