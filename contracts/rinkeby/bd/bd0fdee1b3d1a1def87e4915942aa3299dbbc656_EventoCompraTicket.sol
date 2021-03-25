/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EventoCompraTicket{
    address payable owner;
    uint public tickets;
    string public descripcion;
    uint constant price = 0.001 ether;
    string public website;
    
    mapping(address => uint) public purcharsers;
    
    constructor(uint _cantiTickets, string memory _descripcion, string memory _website){
        owner = msg.sender;
        descripcion = _descripcion;
        website = _website;
        tickets = _cantiTickets;
    }
    
    
    function GeneraNuevaVentaTicket(uint _cantiTickets, string memory _descripcion, string memory _website)  public{
        
        string memory sMsjRet;
        
        if (msg.sender == address(owner)){
            descripcion = _descripcion;
            website = _website;
            tickets = _cantiTickets;
            abi.encodePacked(sMsjRet,_descripcion);
        }
    }
    
    
    
    function buyTickets(uint _amount) payable external returns(string memory){
        string memory sMsjRet;
        if(tickets==0){
            sMsjRet = 'Se acabaron los tickets';
            return sMsjRet;
        }
        
        if(msg.value != (_amount * price) || _amount >tickets){
            revert();
        }else{
            purcharsers[msg.sender] += _amount;
            tickets -= _amount;
            sMsjRet = 'Compra de Ticket Realizada';
            
            if(tickets==0){
                owner.transfer(address(this).balance);
            }
            return sMsjRet;
        }
        
    }
    
    function refund(uint numTickets) public{
        if(purcharsers[msg.sender] < numTickets){
            revert();
        }else{
            msg.sender.transfer(numTickets * price);
            purcharsers[msg.sender] -= numTickets;
            tickets += numTickets;
        }
    }
    
}