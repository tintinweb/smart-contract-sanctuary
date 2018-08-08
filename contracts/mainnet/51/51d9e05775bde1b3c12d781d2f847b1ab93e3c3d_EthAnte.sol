/*
*
* ███████╗████████╗██╗  ██╗     █████╗ ███╗   ██╗████████╗███████╗
* ██╔════╝╚══██╔══╝██║  ██║    ██╔══██╗████╗  ██║╚══██╔══╝██╔════╝
* █████╗     ██║   ███████║    ███████║██╔██╗ ██║   ██║   █████╗  
* ██╔══╝     ██║   ██╔══██║    ██╔══██║██║╚██╗██║   ██║   ██╔══╝  
* ███████╗   ██║   ██║  ██║    ██║  ██║██║ ╚████║   ██║   ███████╗
* ╚══════╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
*                 
* //*** This Game Pays The Last One To Bid Before The Time Runs Out
*
* "Now I am become Death, the destroyer of worlds"
*  
* //*** Developed By:
*   _____       _         _         _ ___ _         
*  |_   _|__ __| |_  _ _ (_)__ __ _| | _ (_)___ ___ 
*    | |/ -_) _| &#39; \| &#39; \| / _/ _` | |   / (_-</ -_)
*    |_|\___\__|_||_|_||_|_\__\__,_|_|_|_\_/__/\___|
*   
*   &#169; 2018 TechnicalRise.  Written in March 2018.  
*   All rights reserved.  Do not copy, adapt, or otherwise use without permission.
*   https://www.reddit.com/user/TechnicalRise/
*  
*/

pragma solidity ^0.4.20;

contract EthAnte {
    
    uint public timeOut;
    uint public feeRate;
    address public TechnicalRise = 0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538;
    address public lastBidder;
    
    function EthAnte() public payable { 
        lastBidder = msg.sender;
	    timeOut = now + 1 hours;
	    feeRate = 10; // i.e. 10%
	} 
	
	function fund() public payable {
	    require(msg.value >= 1 finney);
	    
	    // If the transaction is after the timer 
	    // runs out pay the winner
	    if (timeOut <= now) {
	        TechnicalRise.transfer((address(this).balance - msg.value) / feeRate);
	        lastBidder.transfer((address(this).balance - msg.value) - address(this).balance / feeRate);
	    }
	    
	    timeOut = now + 1 hours;
	    lastBidder = msg.sender;
	}

	function () public payable {
		fund();
	}
}