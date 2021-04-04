/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Withdrawable {

    mapping (address => uint) public pendingWithdrawals;

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        
        require(amount > 0);
        require(this.balance >= amount);

        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}

/**
 * @title EthLottery
 */
contract EthLottery is Withdrawable, Ownable {

    event onTicketPurchase(uint32 lotteryId, address buyer, uint16[] tickets);
    event onLotteryCompleted(uint32 lotteryId);
    event onLotteryFinalized(uint32 lotteryId);
    event onLotteryInsurance(address claimer);

    uint32 public lotteryId;
    
    struct Lottery {        
        uint8 ownerCut;

        uint ticketPrice;
        uint16 numTickets;
        uint16 winningTicket;
        
        mapping (uint16 => address) tickets;
        mapping (address => uint16) ticketsPerAddress;
        
        address winner;
        
        uint16[] ticketsSold;
        address[] ticketOwners;

        bytes32 serverHash;
        bytes32 serverSalt;
        uint serverRoll; 

        uint lastSaleTimestamp;
    }

    mapping (uint32 => Lottery) lotteries;
    
    // Init Lottery. 
    function initLottery(uint16 numTickets, uint ticketPrice, uint8 ownerCut, bytes32 serverHash) onlyOwner public {
        require(ownerCut < 100);
                
        lotteryId += 1;

        lotteries[lotteryId].ownerCut = ownerCut;
        lotteries[lotteryId].ticketPrice = ticketPrice;
        lotteries[lotteryId].numTickets = numTickets;
        lotteries[lotteryId].serverHash = serverHash;
    }

    function getLotteryDetails(uint16 lottId) public constant returns (
        uint8 ownerCut,
        uint ticketPrice,
        //
        uint16 numTickets, 
        uint16 winningTicket,
        //
        bytes32 serverHash,
        bytes32 serverSalt,
        uint serverRoll,
        //
        uint lastSaleTimestamp,
        //
        address winner,
        uint16[] ticketsSold, 
        address[] ticketOwners
    ) {
        ownerCut = lotteries[lottId].ownerCut;
        ticketPrice = lotteries[lottId].ticketPrice;
        //
        numTickets = lotteries[lottId].numTickets;
        winningTicket = lotteries[lottId].winningTicket;
        //
        serverHash = lotteries[lottId].serverHash;
        serverSalt = lotteries[lottId].serverSalt;
        serverRoll = lotteries[lottId].serverRoll; 
        //
        lastSaleTimestamp = lotteries[lottId].lastSaleTimestamp;
        //
        winner = lotteries[lottId].winner;
        ticketsSold = lotteries[lottId].ticketsSold;
        ticketOwners = lotteries[lottId].ticketOwners;
    }

    function purchaseTicket(uint16 lottId, uint16[] tickets) public payable {

        // Checks on Lottery
        require(lotteries[lottId].winner == address(0));
        require(lotteries[lottId].ticketsSold.length < lotteries[lottId].numTickets);

        // Checks on tickets
        require(tickets.length > 0);
        require(tickets.length <= lotteries[lottId].numTickets);
        require(tickets.length * lotteries[lottId].ticketPrice == msg.value);

        for (uint16 i = 0; i < tickets.length; i++) {
            
            uint16 ticket = tickets[i];

            // Check number is OK and not Sold
            require(lotteries[lottId].numTickets > ticket);
            require(lotteries[lottId].tickets[ticket] == 0);
            
            // Ticket checks passed OK
            lotteries[lottId].ticketsSold.push(ticket);
            lotteries[lottId].ticketOwners.push(msg.sender);

            // Save who's buying this ticket
            lotteries[lottId].tickets[ticket] = msg.sender;
        }

        // Add amount of tickets bought to this address
        lotteries[lottId].ticketsPerAddress[msg.sender] += uint16(tickets.length);

        // Save last timestamp of sale
        lotteries[lottId].lastSaleTimestamp = now;

        onTicketPurchase(lottId, msg.sender, tickets);

        // Send event on all tickets sold. 
        if (lotteries[lottId].ticketsSold.length == lotteries[lottId].numTickets) {
            onLotteryCompleted(lottId);
        }
    }

    function finalizeLottery(uint16 lottId, bytes32 serverSalt, uint serverRoll) onlyOwner public {
        
        // Check lottery not Closed and completed
        require(lotteries[lottId].winner == address(0));
        require(lotteries[lottId].ticketsSold.length == lotteries[lottId].numTickets);

        // If it's been less than two hours from the sale of the last ticket.
        require((lotteries[lottId].lastSaleTimestamp + 2 hours) >= now);

        // Check fairness of server roll here
        require(keccak256(serverSalt, serverRoll) == lotteries[lottId].serverHash);
        
        // Final Number is based on server roll and lastSaleTimestamp. 
        uint16 winningTicket = uint16(
            addmod(serverRoll, lotteries[lottId].lastSaleTimestamp, lotteries[lottId].numTickets)
        );
        address winner = lotteries[lottId].tickets[winningTicket];
        
        lotteries[lottId].winner = winner;
        lotteries[lottId].winningTicket = winningTicket;

        // Send funds to owner and winner
        uint vol = lotteries[lottId].numTickets * lotteries[lottId].ticketPrice;

        pendingWithdrawals[owner] += (vol * lotteries[lottId].ownerCut) / 100;
        pendingWithdrawals[winner] += (vol * (100 - lotteries[lottId].ownerCut)) / 100;

        onLotteryFinalized(lottId);
    }

    function lotteryCloseInsurance(uint16 lottId) public {
        
        // Check lottery is still open and all tickets were sold. 
        require(lotteries[lottId].winner == address(0));
        require(lotteries[lottId].ticketsSold.length == lotteries[lottId].numTickets);
        
        // If it's been more than two hours from the sale of the last ticket.
        require((lotteries[lottId].lastSaleTimestamp + 2 hours) < now);
            
        // Check caller hash bought tickets for this lottery
        require(lotteries[lottId].ticketsPerAddress[msg.sender] > 0);

        uint16 numTickets = lotteries[lottId].ticketsPerAddress[msg.sender];

        // Send ticket refund to caller
        lotteries[lottId].ticketsPerAddress[msg.sender] = 0;
        pendingWithdrawals[msg.sender] += (lotteries[lottId].ticketPrice * numTickets);

        onLotteryInsurance(msg.sender);
    }
}