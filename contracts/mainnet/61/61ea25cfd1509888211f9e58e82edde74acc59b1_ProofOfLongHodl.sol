/*
* Team Proof of Long Hodl presents... v2
*/

pragma solidity ^0.4.21;

contract ProofOfLongHodl {
    using SafeMath for uint256;

    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claim(address user, uint dividends);
    event Reinvest(address user, uint dividends);

    address owner;
    mapping(address => bool) preauthorized;
    bool gameStarted;

    uint constant depositTaxDivisor = 5;		// 20% of  deposits goes to  divs
    uint constant withdrawalTaxDivisor = 5;	// 20% of  withdrawals goes to  divs
    uint constant lotteryFee = 20; 				// 5% of deposits and withdrawals goes to dailyPool

    mapping(address => uint) public investment;

    mapping(address => uint) public stake;
    uint public totalStake;
    uint stakeValue;

    mapping(address => uint) dividendCredit;
    mapping(address => uint) dividendDebit;

    function ProofOfLongHodl() public {
        owner = msg.sender;
        preauthorized[owner] = true;
    }

    function preauthorize(address _user) public {
        require(msg.sender == owner);
        preauthorized[_user] = true;
    }

    function startGame() public {
        require(msg.sender == owner);
        gameStarted = true;
    }

    function depositHelper(uint _amount) private {
    	require(_amount > 0);
        uint _tax = _amount.div(depositTaxDivisor);
        uint _lotteryPool = _amount.div(lotteryFee);
        uint _amountAfterTax = _amount.sub(_tax).sub(_lotteryPool);

        // weekly and daily pool
        uint weeklyPoolFee = _lotteryPool.div(5);
        uint dailyPoolFee = _lotteryPool.sub(weeklyPoolFee);

        uint tickets = _amount.div(TICKET_PRICE);

        weeklyPool = weeklyPool.add(weeklyPoolFee);
        dailyPool = dailyPool.add(dailyPoolFee);

        //********** ADD DAILY TICKETS
        dailyTicketPurchases storage dailyPurchases = dailyTicketsBoughtByPlayer[msg.sender];

        // If we need to reset tickets from a previous lotteryRound
        if (dailyPurchases.lotteryId != dailyLotteryRound) {
            dailyPurchases.numPurchases = 0;
            dailyPurchases.ticketsPurchased = 0;
            dailyPurchases.lotteryId = dailyLotteryRound;
            dailyLotteryPlayers[dailyLotteryRound].push(msg.sender); // Add user to lottery round
        }

        // Store new ticket purchase
        if (dailyPurchases.numPurchases == dailyPurchases.ticketsBought.length) {
            dailyPurchases.ticketsBought.length += 1;
        }
        dailyPurchases.ticketsBought[dailyPurchases.numPurchases++] = dailyTicketPurchase(dailyTicketsBought, dailyTicketsBought + (tickets - 1)); // (eg: buy 10, get id&#39;s 0-9)
        
        // Finally update ticket total
        dailyPurchases.ticketsPurchased += tickets;
        dailyTicketsBought += tickets;

        //********** ADD WEEKLY TICKETS
		weeklyTicketPurchases storage weeklyPurchases = weeklyTicketsBoughtByPlayer[msg.sender];

		// If we need to reset tickets from a previous lotteryRound
		if (weeklyPurchases.lotteryId != weeklyLotteryRound) {
		    weeklyPurchases.numPurchases = 0;
		    weeklyPurchases.ticketsPurchased = 0;
		    weeklyPurchases.lotteryId = weeklyLotteryRound;
		    weeklyLotteryPlayers[weeklyLotteryRound].push(msg.sender); // Add user to lottery round
		}

		// Store new ticket purchase
		if (weeklyPurchases.numPurchases == weeklyPurchases.ticketsBought.length) {
		    weeklyPurchases.ticketsBought.length += 1;
		}
		weeklyPurchases.ticketsBought[weeklyPurchases.numPurchases++] = weeklyTicketPurchase(weeklyTicketsBought, weeklyTicketsBought + (tickets - 1)); // (eg: buy 10, get id&#39;s 0-9)

		// Finally update ticket total
		weeklyPurchases.ticketsPurchased += tickets;
		weeklyTicketsBought += tickets;

        if (totalStake > 0)
            stakeValue = stakeValue.add(_tax.div(totalStake));
        uint _stakeIncrement = sqrt(totalStake.mul(totalStake).add(_amountAfterTax)).sub(totalStake);
        investment[msg.sender] = investment[msg.sender].add(_amountAfterTax);
        stake[msg.sender] = stake[msg.sender].add(_stakeIncrement);
        totalStake = totalStake.add(_stakeIncrement);
        dividendDebit[msg.sender] = dividendDebit[msg.sender].add(_stakeIncrement.mul(stakeValue));
    }

    function deposit() public payable {
        require(preauthorized[msg.sender] || gameStarted);
        depositHelper(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public {
        require(_amount > 0);
        require(_amount <= investment[msg.sender]);
        uint _tax = _amount.div(withdrawalTaxDivisor);
        uint _lotteryPool = _amount.div(lotteryFee);
        uint _amountAfterTax = _amount.sub(_tax).sub(_lotteryPool);

        // weekly and daily pool
        uint weeklyPoolFee = _lotteryPool.div(20);
        uint dailyPoolFee = _lotteryPool.sub(weeklyPoolFee);

        weeklyPool = weeklyPool.add(weeklyPoolFee);
        dailyPool = dailyPool.add(dailyPoolFee);

        uint _stakeDecrement = stake[msg.sender].mul(_amount).div(investment[msg.sender]);
        uint _dividendCredit = _stakeDecrement.mul(stakeValue);
        investment[msg.sender] = investment[msg.sender].sub(_amount);
        stake[msg.sender] = stake[msg.sender].sub(_stakeDecrement);
        totalStake = totalStake.sub(_stakeDecrement);
        if (totalStake > 0)
            stakeValue = stakeValue.add(_tax.div(totalStake));
        dividendCredit[msg.sender] = dividendCredit[msg.sender].add(_dividendCredit);
        uint _creditDebitCancellation = min(dividendCredit[msg.sender], dividendDebit[msg.sender]);
        dividendCredit[msg.sender] = dividendCredit[msg.sender].sub(_creditDebitCancellation);
        dividendDebit[msg.sender] = dividendDebit[msg.sender].sub(_creditDebitCancellation);

        msg.sender.transfer(_amountAfterTax);
        emit Withdraw(msg.sender, _amount);
    }

    function claimHelper() private returns(uint) {
        uint _dividendsForStake = stake[msg.sender].mul(stakeValue);
        uint _dividends = _dividendsForStake.add(dividendCredit[msg.sender]).sub(dividendDebit[msg.sender]);
        dividendCredit[msg.sender] = 0;
        dividendDebit[msg.sender] = _dividendsForStake;

        return _dividends;
    }

    function claim() public {
        uint _dividends = claimHelper();
        msg.sender.transfer(_dividends);

        emit Claim(msg.sender, _dividends);
    }

    function reinvest() public {
        uint _dividends = claimHelper();
        depositHelper(_dividends);

        emit Reinvest(msg.sender, _dividends);
    }

    function dividendsForUser(address _user) public view returns (uint) {
        return stake[_user].mul(stakeValue).add(dividendCredit[_user]).sub(dividendDebit[_user]);
    }

    function min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // LOTTERY MODULE 
    // DAILY
    uint private dailyPool = 0;
    uint private dailyLotteryRound = 1;
    uint private dailyTicketsBought = 0;
    uint private dailyTicketThatWon;
    address[] public dailyWinners;
    uint256[] public dailyPots;

    // WEEKLY
    uint private weeklyPool = 0;
    uint private weeklyLotteryRound = 1;
    uint private weeklyTicketsBought = 0;
    uint private weeklyTicketThatWon;
    address[] public weeklyWinners;
    uint256[] public weeklyPots;

    uint public TICKET_PRICE = 0.01 ether;
    uint public DAILY_LIMIT = 0.15 ether;
    bool private dailyTicketSelected;
    bool private weeklyTicketSelected;

    // STRUCTS for LOTTERY
    // DAILY
    struct dailyTicketPurchases {
        dailyTicketPurchase[] ticketsBought;
        uint256 numPurchases; // Allows us to reset without clearing dailyTicketPurchase[] (avoids potential for gas limit)
        uint256 lotteryId;
        uint256 ticketsPurchased;
    }

    // Allows us to query winner without looping (avoiding potential for gas limit)
    struct dailyTicketPurchase {
        uint256 startId;
        uint256 endId;
    }

    mapping(address => dailyTicketPurchases) private dailyTicketsBoughtByPlayer;
    mapping(uint256 => address[]) private dailyLotteryPlayers;

    // WEEKLY
    struct weeklyTicketPurchases {
        weeklyTicketPurchase[] ticketsBought;
        uint256 numPurchases; // Allows us to reset without clearing weeklyTicketPurchase[] (avoids potential for gas limit)
        uint256 lotteryId;
        uint256 ticketsPurchased;
    }

    // Allows us to query winner without looping (avoiding potential for gas limit)
    struct weeklyTicketPurchase {
        uint256 startId;
        uint256 endId;
    }

    mapping(address => weeklyTicketPurchases) private weeklyTicketsBoughtByPlayer;
    mapping(uint256 => address[]) private weeklyLotteryPlayers;

    // DRAWS
    function drawDailyWinner() public {
        require(msg.sender == owner);
        require(!dailyTicketSelected);
       
        uint256 seed = dailyTicketsBought + block.timestamp;
        dailyTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, dailyTicketsBought);
        dailyTicketSelected = true;
    }

    function drawWeeklyWinner() public {
        require(msg.sender == owner);
        require(!weeklyTicketSelected);
       
        uint256 seed = weeklyTicketsBought + block.timestamp;
        weeklyTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, weeklyTicketsBought);
        weeklyTicketSelected = true;
    }

    function awardDailyLottery(address checkWinner, uint256 checkIndex) external {
		require(msg.sender == owner);
	    
	    if (!dailyTicketSelected) {
	    	drawDailyWinner(); // Ideally do it in one call (gas limit cautious)
	    }
	        
	    // Reduce gas by (optionally) offering an address to _check_ for winner
	    if (checkWinner != 0) {
	        dailyTicketPurchases storage tickets = dailyTicketsBoughtByPlayer[checkWinner];
	        if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.lotteryId == dailyLotteryRound) {
	            dailyTicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
	            if (dailyTicketThatWon >= checkTicket.startId && dailyTicketThatWon <= checkTicket.endId) {
	                if ( dailyPool >= DAILY_LIMIT) {
	            		checkWinner.transfer(DAILY_LIMIT);
	            		dailyPots.push(DAILY_LIMIT);
	            		dailyPool = dailyPool.sub(DAILY_LIMIT);		
	        		} else {
	        			checkWinner.transfer(dailyPool);
	        			dailyPots.push(dailyPool);
	        			dailyPool = 0;
	        		}

	        		dailyWinners.push(checkWinner);
            		dailyLotteryRound = dailyLotteryRound.add(1);
            		dailyTicketsBought = 0;
            		dailyTicketSelected = false;
	                return;
	            }
	        }
	    }
	    
	    // Otherwise just naively try to find the winner (will work until mass amounts of players)
	    for (uint256 i = 0; i < dailyLotteryPlayers[dailyLotteryRound].length; i++) {
	        address player = dailyLotteryPlayers[dailyLotteryRound][i];
	        dailyTicketPurchases storage playersTickets = dailyTicketsBoughtByPlayer[player];
	        
	        uint256 endIndex = playersTickets.numPurchases - 1;
	        // Minor optimization to avoid checking every single player
	        if (dailyTicketThatWon >= playersTickets.ticketsBought[0].startId && dailyTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
	            for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
	                dailyTicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
	                if (dailyTicketThatWon >= playerTicket.startId && dailyTicketThatWon <= playerTicket.endId) {
	                	if ( dailyPool >= DAILY_LIMIT) {
	                		player.transfer(DAILY_LIMIT);
	                		dailyPots.push(DAILY_LIMIT);
	                		dailyPool = dailyPool.sub(DAILY_LIMIT);
	            		} else {
	            			player.transfer(dailyPool);
	            			dailyPots.push(dailyPool);
	            			dailyPool = 0;
	            		}

	            		dailyWinners.push(player);
	            		dailyLotteryRound = dailyLotteryRound.add(1);
	            		dailyTicketsBought = 0;
	            		dailyTicketSelected = false;

	                    return;
	                }
	            }
	        }
	    }
	}

	function awardWeeklyLottery(address checkWinner, uint256 checkIndex) external {
		require(msg.sender == owner);
	    
	    if (!weeklyTicketSelected) {
	    	drawWeeklyWinner(); // Ideally do it in one call (gas limit cautious)
	    }
	       
	    // Reduce gas by (optionally) offering an address to _check_ for winner
	    if (checkWinner != 0) {
	        weeklyTicketPurchases storage tickets = weeklyTicketsBoughtByPlayer[checkWinner];
	        if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.lotteryId == weeklyLotteryRound) {
	            weeklyTicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
	            if (weeklyTicketThatWon >= checkTicket.startId && weeklyTicketThatWon <= checkTicket.endId) {
	        		checkWinner.transfer(weeklyPool);

	        		weeklyPots.push(weeklyPool);
	        		weeklyPool = 0;
	            	weeklyWinners.push(player);
	            	weeklyLotteryRound = weeklyLotteryRound.add(1);
	            	weeklyTicketsBought = 0;
	            	weeklyTicketSelected = false;
	                return;
	            }
	        }
	    }
	    
	    // Otherwise just naively try to find the winner (will work until mass amounts of players)
	    for (uint256 i = 0; i < weeklyLotteryPlayers[weeklyLotteryRound].length; i++) {
	        address player = weeklyLotteryPlayers[weeklyLotteryRound][i];
	        weeklyTicketPurchases storage playersTickets = weeklyTicketsBoughtByPlayer[player];
	        
	        uint256 endIndex = playersTickets.numPurchases - 1;
	        // Minor optimization to avoid checking every single player
	        if (weeklyTicketThatWon >= playersTickets.ticketsBought[0].startId && weeklyTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
	            for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
	                weeklyTicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
	                if (weeklyTicketThatWon >= playerTicket.startId && weeklyTicketThatWon <= playerTicket.endId) {
	            		player.transfer(weeklyPool);  

	            		weeklyPots.push(weeklyPool);
	            		weeklyPool = 0;
	            		weeklyWinners.push(player);
	            		weeklyLotteryRound = weeklyLotteryRound.add(1);
	            		weeklyTicketsBought = 0;  
	            		weeklyTicketSelected = false;            
	                    return;
	                }
	            }
	        }
	    }
	}

    function getLotteryData() public view returns( uint256, uint256, uint256, uint256, uint256, uint256) {
    	return (dailyPool, weeklyPool, dailyLotteryRound, weeklyLotteryRound, dailyTicketsBought, weeklyTicketsBought);
    }

    function getDailyLotteryParticipants(uint256 _round) public view returns(address[]) {
    	return dailyLotteryPlayers[_round];
    }

    function getWeeklyLotteryParticipants(uint256 _round) public view returns(address[]) {
    	return weeklyLotteryPlayers[_round];
    }

    function getLotteryWinners() public view returns(uint256, uint256) {
    	return (dailyWinners.length, weeklyWinners.length);
    }

    function editDailyLimit(uint _price) public payable {
    	require(msg.sender == owner);
    	DAILY_LIMIT = _price;
    }

    function editTicketPrice(uint _price) public payable {
    	require(msg.sender == owner);
    	TICKET_PRICE = _price;
    }

    function getDailyTickets(address _player) public view returns(uint256) {
    	dailyTicketPurchases storage dailyPurchases = dailyTicketsBoughtByPlayer[_player];

    	if (dailyPurchases.lotteryId != dailyLotteryRound) {
    		return 0;
    	}

    	return dailyPurchases.ticketsPurchased;
    }

    function getWeeklyTickets(address _player) public view returns(uint256) {
    	weeklyTicketPurchases storage weeklyPurchases = weeklyTicketsBoughtByPlayer[_player];

    	if (weeklyPurchases.lotteryId != weeklyLotteryRound) {
    		return 0;
    	}

    	return weeklyPurchases.ticketsPurchased;	
    }

    // If someone is generous and wants to add to pool
    function addToPool() public payable {
    	require(msg.value > 0);
    	uint _lotteryPool = msg.value;

    	// weekly and daily pool
        uint weeklyPoolFee = _lotteryPool.div(5);
        uint dailyPoolFee = _lotteryPool.sub(weeklyPoolFee);

        weeklyPool = weeklyPool.add(weeklyPoolFee);
        dailyPool = dailyPool.add(dailyPoolFee);
    }

    function winningTickets() public view returns(uint256, uint256) {
    	return (dailyTicketThatWon, weeklyTicketThatWon);
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;                                                                                                                                                                                       
        }
        uint256 c = a * b;                                                                                                                                                                                  
        assert(c / a == b);                                                                                                                                                                                 
        return c;                                                                                                                                                                                           
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0                                                                                                                               
        // uint256 c = a / b;                                                                                                                                                                               
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold                                                                                                                       
        return a / b;                                                                                                                                                                                       
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);                                                                                                                                                                                     
        return a - b;                                                                                                                                                                                       
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;                                                                                                                                                                                  
        assert(c >= a);                                                                                                                                                                                     
        return c;                                                                                                                                                                                           
    }
}