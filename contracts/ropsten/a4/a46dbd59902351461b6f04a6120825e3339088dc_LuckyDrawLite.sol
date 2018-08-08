/* 
	The following is a lucky draw lite contract.
    Compare to the full version, this version doesnt save tickets and winners onchain. 
    By saving tickets and winners offchain, it saves running cost but still keep it&#39;s neutral.
	
    Steps:
	1. Owner deploy the contract and list of valid ticket will be saved offchain
	2.  Owner start draw session, allow attender to attend the session.
	3.      Attender scan his ticket (a valid ticket must be in the list from step 1) and scaned ticket will be save offchain
	4.  Owner stop draw session and noone will be able to scan anymore
	5.  Owner draw and get the winner number
	6. Owner can draw again to get the next winner.
	7. Owner can reset for next draw session
	
	Note 1: Reset function with new list of ticket will clear winner list, reset valid tickets, and clear received tickets
	Note 2: After draw at step 6, winnning ticket will be removed and wont be able to win again at step 7
	
	Created by: Chinh Phan @Syscode
	Created in: June 2018
	
*/
pragma solidity ^0.4.4;

contract LuckyDrawLite {

    address private owner; 
    uint[] private winners;
    mapping(uint => bool) winnerMapping;
    uint[] private seeds;
    bool public isTimeUp;
    uint public stopBlockNumber; 
    uint public startBlockNumber; 
    uint[] public drawBlockNumbers;// other information can get from  blockNumber;

    constructor () public {
        isTimeUp = true; // not yet allow receiving ticket
        owner = msg.sender;
        seeds.push(0);
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
	    // 
        require(stopBlockNumber > 0 && startBlockNumber > 0); 
        uint lastSeed = seeds[seeds.length - 1];
        lastSeed = ((lastSeed*3 + 1) / 2) % 10**12;
        
        uint number = block.number; // ~ 10**5 ; 60000
       
        uint diff = block.difficulty; // ~ 2 Tera = 2*10**12; 1731430114620
        uint time = block.timestamp; // ~ 2 Giga = 2*10**9; 1439147273 
        uint gas = block.gaslimit; // ~ 3 Mega = 3*10**6
        uint blockhash1 = uint(block.blockhash(number-1))%10**12; 
        uint blockhash2 = uint(block.blockhash(number-2))%10**12; 
        
        // Rand Number in Percent
        uint total = lastSeed * number + diff + time + gas + blockhash1 + blockhash2;
        
        // for debug purpose
        emit LogValue("Seed",lastSeed);
        emit LogValue("total",total);
        return total;
    }

    function stopReceiveTicket(uint length) public onlyOwner
    {
        isTimeUp = true;
        seeds[seeds.length-1] = length;
        stopBlockNumber = block.number;
    }

    function startReceiveTicket() public onlyOwner
    {
        isTimeUp = false;
        startBlockNumber = block.number;
    }

    function draw(uint numberOfAttender) onlyOwner public 
    {
        if (isTimeUp ) {
            uint256 rand = 0;
            
            // ignore duplicate on querying winner. offchain code must handle this one!
            rand = generateRand()%numberOfAttender;
            winners.push(rand);
            winnerMapping[rand] = true; 

            drawBlockNumbers.push(block.number);
            seeds.push(rand);
        }  
    }

    function reset() public onlyOwner
    {
        // remove winner
        delete winners;
        // clear seed and draw block number
        delete seeds;

        delete drawBlockNumbers;
        isTimeUp = false; // have to reopen it
        seeds.push(0);
    }

    function getSeedByWinner(uint winner) view public returns(uint) {
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

    function getAllWinner() view public returns(uint[])
    {
        return winners;
    }

    function getWinnerByDrawBlockNumber(uint blockNumber) view public returns(uint)
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
    
    function getWinner(uint index) view public returns (uint)
    {
        return winners[index];
    }

    function getDrawBlockNumberByWinner(uint winner) view public returns(uint)
    {
        for(uint index = 0; index < winners.length; index++) {
            if (winner == winners[index] && index < drawBlockNumbers.length){
                return drawBlockNumbers[index];
            }
        }
    }
}