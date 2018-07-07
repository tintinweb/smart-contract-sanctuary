pragma solidity ^0.4.24;

// Connor&#39;s first simple smart contract. Workbook at https://www.youtube.com/watch?v=ScyTVWMpXzw&t=27s (logan Brutsche)
contract Splitter {
    address test2 = 0x7AFd6060705c953c528c8aD1ef01440f3C942eDf;
    address test3 = 0x7F9f07F298004995c9cf260643291321391763c9;
    
    function splitEther() external payable {
        uint value = msg.value;
        
        test2.transfer(value/2);
        test3.transfer(value/2);
    }
}