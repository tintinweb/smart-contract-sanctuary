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
    uint public kBalance;
    uint public feeRate;
    address public TechnicalRise = 0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538;
    address public lastBidder;
    
    function EthAnte() public payable { 
        lastBidder = msg.sender;
		kBalance = msg.value;
	    timeOut = now + 10 minutes;
	    feeRate = 100; // i.e. 1%
	} 
	
	function fund() public payable {
		uint _fee = msg.value / feeRate;
	    uint _val = msg.value - _fee;
	    kBalance += _val;
	    TechnicalRise.transfer(_fee);
	    
	    // If they sent nothing or almost nothing, 
	    // merely extend the time but don&#39;t make them
	    // eligible to win (Note that there is a trick 
	    // play available here)
	    if(_val < 9900 szabo) {
	        timeOut += 2 minutes;
	        return;
	    }
	    
	    // If the transaction is after the timer 
	    // runs out pay the winner
	    if (timeOut <= now) {
	        lastBidder.transfer(kBalance - _val);
	        kBalance = _val;
	        timeOut = now;
	    }
	    
	    // The more you put in the less time you add
	    timeOut += (10 minutes) * (9900 szabo) / _val;
	    lastBidder = msg.sender;
	}

	function () public payable {
		fund();
	}
}