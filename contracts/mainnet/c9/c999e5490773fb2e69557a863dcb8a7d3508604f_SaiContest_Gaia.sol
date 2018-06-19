// https://github.com/librasai/SaiContest_Gaia
pragma solidity ^0.4.21;

contract SaiContest_Gaia {
	address public owner;
	uint public start;      // starting date
	uint public last_roll;  // starting date for week round (7 days)
	uint public last_jack;   // starting date for jackpot round (30 days)
	address public week_winner; // current winner-of-week (wins the one has sent a biggest value in one transaction)
	address public jack_winner; // current winner-of-jackpot (the one with most transactions wins)
	uint public week_max;   // biggest value has been sent in a current week round
	uint public jack_max;   // most number of transactions was made by one sender in a current jackpot round
	uint public jack_pot;   // size of current jackpot
	uint public jack_nonce; // current nonce (number of jackpot round)
	struct JVal {
        	uint nonce;
        	uint64 count;
	}
	mapping (address => JVal) public jacks; // storing current jackpot participants (in this jackpot round) and their transactions count

	uint public constant min_payment= 1 finney; // size of minimal payment can be accepted
	
	function SaiContest_Gaia() public {
		owner = msg.sender;		
		start = now;
		last_roll = now;
		last_jack = now;
		jack_nonce = 1;
	}

	function kill(address addr) public { 
	    if (msg.sender == owner && now > start + 1 years){
	        selfdestruct(addr);
	    }
	}
	
	function getBalance() public view returns (uint bal) {
	    bal = address(this).balance;
	}

	function () public payable{
	    Paid(msg.value);
	}
	
	function Paid(uint value) private {
	    uint WeekPay;
	    uint JackPay;
	    uint oPay;
	    uint CurBal;
	    uint JackPot;
	    uint CurNonce;
	    address WeekWinner;
	    address JackWinner;
	    uint64 JackValCount;
	    uint JackValNonce;
	    
	    require(value >= min_payment);
	    oPay = value * 5 / 100; // 5% to owner
	    CurBal = address(this).balance - oPay;
	    JackPot = jack_pot;

	    if (now > last_roll + 7 days) {
	        WeekPay = CurBal - JackPot;
	        WeekWinner = week_winner;
	        last_roll = now;
	        week_max = value;
	        week_winner = msg.sender;
	    } else {
	        if (value > week_max) {
    	        week_winner = msg.sender;
	            week_max = value;
	        }
	    }
	    if (now > last_jack + 30 days) {
	        JackWinner = jack_winner;
	        if (JackPot > CurBal) {
	            JackPay = CurBal;
	        } else {
	            JackPay = JackPot;
	        }
    	    jack_pot = value * 10 / 100; // 10% to jackpot
	        jack_winner = msg.sender;
	        jack_max = 1;
	        CurNonce = jack_nonce + 1; 
	        jacks[msg.sender].nonce = CurNonce;
	        jacks[msg.sender].count = 1;
	        jack_nonce = CurNonce;
	    } else {
    	    jack_pot = JackPot + value * 10 / 100; // 10% to jackpot
	        CurNonce = jack_nonce; 
	        JackValNonce = jacks[msg.sender].nonce;
	        JackValCount = jacks[msg.sender].count;
	        if (JackValNonce < CurNonce) {
	            jacks[msg.sender].nonce = CurNonce;
	            jacks[msg.sender].count = 1;
    	        if (jack_max == 0) {
        	        jack_winner = msg.sender;
    	            jack_max = 1;
    	        }
	        } else {
	            JackValCount = JackValCount + 1;
	            jacks[msg.sender].count = JackValCount;
    	        if (JackValCount > jack_max) {
        	        jack_winner = msg.sender;
    	            jack_max = JackValCount;
    	        }
	        }
	        
	    }

	    owner.transfer(oPay);
	    if (WeekPay > 0) {
	        WeekWinner.transfer(WeekPay);
	    }
	    if (JackPay > 0) {
	        JackWinner.transfer(JackPay);
	    }
	}
}