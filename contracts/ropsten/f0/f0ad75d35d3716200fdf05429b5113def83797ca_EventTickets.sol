pragma solidity ^0.4.25;

contract EventTickets {
 
    struct evento {
        uint no_tkt;
        string description;
        string web;
    }
    mapping (address => uint) private COMPRADORES;
    evento myEvento = evento(10,"Coldplay","http://Coldplay.com");

   constructor () payable {
    }
    
    function verEvento () returns (uint,string,string){
        return (myEvento.no_tkt,myEvento.description,myEvento.web);
    }
    
    function buyTkt () payable returns (string,uint){
        require (myEvento.no_tkt>0,"Sold out");
        require (msg.value == 1 ether, "Pago de mas o de menos");
        myEvento.no_tkt = myEvento.no_tkt - 1;
        COMPRADORES[msg.sender] = 1;
        return ("Compraste un tkt, quedan:",myEvento.no_tkt);
    }
    function reembolso () returns(string) {
        require (COMPRADORES[msg.sender]==1,"No sos comprador");
        msg.sender.transfer(1 ether);
        COMPRADORES[msg.sender]=0;
        myEvento.no_tkt = myEvento.no_tkt + 1;
        return ("Reembolsado");
    }
    function getBalance () returns (uint) {
        return this.balance;
    }
    
}