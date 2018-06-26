/* 
	The following is a lucky draw contract. 
	Steps:
	1. Owner deploy the contract with a list of valid ticket (1 ticket is a address)
	2.  Owner start draw session, allow attender to attend the session.
	3.      Attender scan his ticket (a valid ticket must be in the list from step 1)
	4.  Owner stop draw session and noone will beable to scan anymore
	5.  Owner draw and get the winner
	6. Owner can draw again to get the next winner.
	7. Owner can reset for next draw session
	
	Note 1: Reset function with new list of ticket will clear winner list, reset valid tickets, and clear received tickets
	Note 2: After draw at step 6, winnning ticket will be removed and wont be able to win again at step 7
	
	Created by: Chinh Phan @Syscode
	Created in: June 2018
	
*/

pragma solidity ^0.4.4;

contract LuckyDraw {

    address[] private validTickets ;
    mapping(address =>bool) validTicketMapping;

    address[] public receivedTickets ;
    mapping(address =>bool) receivedTicketMapping;

    address private owner; 
    address[] private winners;
    uint[] private seeds;
    bool public isTimeUp;
    uint public stopBlockNumber; 
    uint public startBlockNumber; 
    uint[] public drawBlockNumbers;// other information can get from  blockNumber;

    constructor (address[] _tickets, uint firstTimeSeed) public {
        
        for (uint index = 0; index < _tickets.length; index++) {
            validTickets.push(_tickets[index]);
            validTicketMapping[_tickets[index]] = true;
            
        }
        isTimeUp = true; // not yet allow receiving ticket
        seeds.push(firstTimeSeed);
        owner = msg.sender;
    } 

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    event TicketReceive(address ticket, bool isvalidTicket, bool inExisted);
    event LogAddress(uint index, address anAddress);
    event LogNumber(uint value);
    event LogValue(string name, uint value);
    // Security Note: 
    // below value can be controled by a powerful miner.
    // or can be copy (read only) from contracts of same block
    // But: 
    // 1. The price is not big enough for powerful miner try to changes values
    // 2. The draw will be close x minute in advance. So, 2nd hack wont work!

    function generateRand() private returns (uint) { 
	    // Seeds
        uint lastSeed = seeds[seeds.length -1];
        lastSeed = ((lastSeed*3 + 1) / 2)% 10**12;
        
        uint number = block.number; // ~ 10**5 ; 60000
       
        uint diff = block.difficulty; // ~ 2 Tera = 2*10**12; 1731430114620
        uint time = block.timestamp; // ~ 2 Giga = 2*10**9; 1439147273 // can be set by miner
        uint gas = block.gaslimit; // ~ 3 Mega = 3*10**6
        uint blockhash1 = uint(block.blockhash(number -1 ))%10**12; // can be set by miner.
        uint blockhash2 = uint(block.blockhash(number -2 ))%10**12; // can be set by miner.
        
        // Rand Number in Percent
        uint total = lastSeed * number + diff + time + gas + blockhash1 + blockhash2;
        
        // for debug purpose
        emit LogValue(&quot;number&quot;,number);
        emit LogValue(&quot;diff&quot;,diff);
        emit LogValue(&quot;time&quot;,time);
        emit LogValue(&quot;gas&quot;,gas);
        emit LogValue(&quot;blockhash1&quot;,blockhash1);
        emit LogValue(&quot;blockhash2&quot;,blockhash2);
        emit LogValue(&quot;lastSeed&quot;,lastSeed);
        emit LogValue(&quot;total&quot;,total);

        return total;
    }

    function stopReceiveTicket() public onlyOwner
    {
        isTimeUp = true;
        seeds[seeds.length-1] = receivedTickets.length;
        stopBlockNumber = block.number;
    }

    function startReceiveTicket() public onlyOwner
    {
        isTimeUp = false;
        startBlockNumber = block.number;
    }

    function receiveTicket(address ticket) public 
    {
        emit TicketReceive(ticket,validTicketMapping[ticket],receivedTicketMapping[ticket]);
        if (validTicketMapping[ticket] && !receivedTicketMapping[ticket] && !isTimeUp ) {
            receivedTicketMapping[ticket] = true;
            receivedTickets.push(ticket);
        } 
    }

    function draw() onlyOwner public 
    {
        uint256 rand = 0;
        if (isTimeUp && receivedTickets.length > 0) {
            // get random number which have never picked before
            do{
                rand = generateRand()%(receivedTickets.length);
            }while(!receivedTicketMapping[receivedTickets[rand]]  );
            winners.push(receivedTickets[rand]);
            // block number where we found winner
            drawBlockNumbers.push(block.number);
            // update seed
            seeds.push(rand);
            // to prevent this ticket to be picked again!
            receivedTicketMapping[receivedTickets[rand]] = false;
            // remove the ticket to prevent error by replace it with last item
            receivedTickets[rand] = receivedTickets[receivedTickets.length-1];
           
            receivedTickets.length--;
        }  
    }

    function reset(address[] _newTickets) public onlyOwner
    {
        emit LogAddress( _newTickets.length,  _newTickets[_newTickets.length-1]);
        // remove receive ticket 
        for (uint index = 0; index < receivedTickets.length; index++) {
            receivedTicketMapping[receivedTickets[index]] = false;
        }
        delete receivedTickets;

         // remove current valid ticket
        for (uint i = 0; i < validTickets.length; i++) {
            validTicketMapping[validTickets[i]] = false;
        }
        delete validTickets;

        // remove winner
        delete winners;

        // clear seed and draw block number
        delete seeds;
        // add initial seed as always
        seeds.push(_newTickets.length);

        delete drawBlockNumbers;

        // Recreate valid ticket.
        for (uint k = 0; k < _newTickets.length; k++) {
            emit LogAddress(k,_newTickets[k]);
            validTickets.push(_newTickets[k]);
            validTicketMapping[_newTickets[k]] = true;
            
        }
        
        isTimeUp = false; // have to reopen it
    }

    function getSeedByWinner(address winner) view public returns(uint) {
        for(uint index = 0; index < winners.length; index++) {
            if (winner == winners[index] && index < drawBlockNumbers.length){
                return seeds[index];
            }
        }
    }

    function getLastSeed() view public returns(uint) {
        return seeds[seeds.length-1];
    }

    function getLastDrawBlockNumber() view public returns(uint)
    {
        return drawBlockNumbers[drawBlockNumbers.length-1];
    }
    
    function getDrawBlockNumberByWinner(address winner) view public returns(uint)
    {
        for(uint index = 0; index < winners.length; index++) {
            if (winner == winners[index] && index < drawBlockNumbers.length){
                return drawBlockNumbers[index];
            }
        }
    }

    function getAllWinner() view public returns(address[])
    {
        return winners;
    }

    function getWinnerByDrawBlockNumber(uint blockNumber) view public returns(address)
    {
        for(uint index = 0; index < drawBlockNumbers.length; index++) {
            if (blockNumber == drawBlockNumbers[index] && index < winners.length){
                return winners[index];
            }
        }
    }

    function getstartBlockNumber() view public returns(uint)
    {
        return startBlockNumber;
    }
    function getstopBlockNumber() view public returns(uint)
    {
        return stopBlockNumber;
    }
    
    function checkReceive(address ticket) view public returns(bool)
    {
        return receivedTicketMapping[ticket];
    }

    function checkWinner(address ticket) view public returns(bool)
    {
        for (uint8 index = 0; index < winners.length; index++) {
            
            if (winners[index] == ticket) {
                return true;
            } 
        }
        return false;
    }

    function gettotalReceivedTicket() view public returns(uint)
    {
        return receivedTickets.length;
    }

    function getTotalValidTk() view public returns (uint)
    {
        return validTickets.length;
    }

    function checkValidTk(address tk) view public returns (bool)
    {
        return validTicketMapping[tk];
    }
}