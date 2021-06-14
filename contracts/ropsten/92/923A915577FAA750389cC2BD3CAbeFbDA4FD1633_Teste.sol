/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.5.3;

contract Teste{
    address payable dono;
    uint cotas;
    uint totalCoras;
    uint valorCotas;
    uint saldo;
    bool ContratoComDInheiro = false;
    
    constructor() public {
        dono = msg.sender;
        
    }
    
    function CompraCotas(uint quant) public payable {
        require(msg.value >= quant*1 ether, "Insufitient funds, please trie again !");
        cotas = quant;
        ContratoComDInheiro = true;
        
        if (address(this).balance > 0){
            saldo = address(this).balance; 
            dono.transfer(saldo);
            } 
        
    }
   
}