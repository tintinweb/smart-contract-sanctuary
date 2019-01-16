pragma solidity ^0.4.24;
/**
 * The TicketsEventos contract does this and that...
 */
contract TicketsEventos {
	struct ClassEventos {
		address EventOwner;
		uint Max_Tickets;
		mapping(uint => address)  TicketOwner;
		uint ticketsVendidos;
		bool finDelEvento;
	}
	 ClassEventos[] public eventos;
struct Funder {
	address addr;
	uint amount;
	
}

Funder asd;

	function createEvent( uint _maxTicket) public returns(uint _id) {
	    asd.addr = msg.sender;
		ClassEventos memory  TempEvento;
		TempEvento.EventOwner = msg.sender;
		TempEvento.Max_Tickets = _maxTicket;
		eventos.push(TempEvento);
		_id = eventos.length;
	}
	function comprarTicket(uint _IdEvent, uint _ticketNum) public  payable {
		require(msg.value == 1 ether);
		require(!eventos[_IdEvent].finDelEvento);
		require(eventos[_IdEvent].Max_Tickets>=_ticketNum );
		require(eventos[_IdEvent].TicketOwner[_ticketNum]== 0x0 );
		eventos[_IdEvent].TicketOwner[_ticketNum] = msg.sender;
		eventos[_IdEvent].ticketsVendidos ++;
	}
	function reembolsar(uint _IdEvent, uint _ticketNum) public{
		require(eventos[_IdEvent].Max_Tickets>=_ticketNum );
		require(!eventos[_IdEvent].finDelEvento);
		require(eventos[_IdEvent].TicketOwner[_ticketNum]== msg.sender );
		eventos[_IdEvent].TicketOwner[_ticketNum]= 0x0;
		msg.sender.transfer(1 ether);
		eventos[_IdEvent].ticketsVendidos --;

	}
	function retirarDinero(uint _IdEvent) public{
		require(eventos[_IdEvent].EventOwner== msg.sender);
		msg.sender.transfer(eventos[_IdEvent].ticketsVendidos * 1 ether);
		eventos[_IdEvent].finDelEvento = true;
	}
	function TicketOwner(uint _IdEvent, uint _Ticket) public view returns (address) {
		return (eventos[_IdEvent].TicketOwner[_Ticket]);
	}
	function getMaxTickets(uint _IdEvent) public view returns (uint256){
		return(eventos[_IdEvent].Max_Tickets);
	}
}