pragma solidity ^0.4.25;
// pragma experimental ABIEncoderV2;

contract EventTickets {
    address private owner;
    bool configured = false;
    
    struct _event_struct {
        uint256 tickets;
        string description;
        string web;
    }
    
    _event_struct _event;
    
    struct buyer {
        address wallet;
        uint256 tickets;
    }


    buyer[] buyers;
    
    mapping(address=>uint256) buyers2;

    
    constructor () public {
        owner = msg.sender;
    }
    
    function SetEventData(uint256 tickets, string description, string web) public {
        require(msg.sender == owner && configured == false);
        
        _event.tickets = tickets;
        _event.description = description;
        _event.web = web;
        
        configured = true;
    }
    
    function AddTickets(uint256 tickets) public {
        require(msg.sender == owner && configured == true);
        
        _event.tickets += tickets;
    }
    
    function RemoveTickets(uint256 tickets) public {
        require(msg.sender == owner && configured == true && _event.tickets >= tickets);
        
        _event.tickets -= tickets;
    }
    
    function GetBalance() public view returns(uint256) {
        require(msg.sender == owner);
        return address(this).balance;
    }
    
    /*
    function GetEventData() public view returns (_event_struct) {
        return(_event);
    }
    */
    
    function GetTicketOwner() public view returns(address ticket_owner, uint256 tickets){
        ticket_owner = msg.sender;
        tickets = buyers2[msg.sender];
    }
    
    function GetEventInfo() public view returns(uint256 _tickets_left, string _description, string _website) {
        _tickets_left = _event.tickets;
        _description = _event.description;
        _website = _event.web;
    }
    
    function BuyTickets(uint256 ticket_qty) public payable {
        require(ticket_qty > 0, "Ticket quantity cannot be 0.");
        require(msg.value == ticket_qty*1 ether, "Incorrect amount transferred.");
        require(_event.tickets > 0, "All tickets sold!");
        
        buyers.push(buyer(address(msg.sender), ticket_qty));
        buyers2[address(msg.sender)] = buyers2[address(msg.sender)] + ticket_qty;
        
        _event.tickets -= ticket_qty;
    }
    
    function Reimburse() public {
        /*
        
        // This is more complex.
        
        bool buyer_found = false;
        
        
        
        for(uint i=0; i < buyers.length; i++) {
            if(msg.sender == buyers[i].wallet) {
                address(msg.sender).transfer(buyers[i].tickets * 1 ether);
                _event.tickets += buyers[i].tickets;
                buyer_found = true;
                
                delete buyers[i];
                
                break;
            }    
        }
        
        
        assert(buyer_found==true);
        */
        
        // This is waay simpler.
        
        require(buyers2[msg.sender] != 0); // 
        
        address(msg.sender).transfer(buyers2[msg.sender] * 1 ether);
        _event.tickets += buyers2[msg.sender];
        
        delete buyers2[msg.sender];
        
        // Assert spends all the gas left, helps prevent attacks. The gas goes to the miner, as usual.
        // assert(buyers2[msg.sender] == 0); 
    }
    
    function GetSender() public returns (address _sender){
        return msg.sender;
    }
    
}