pragma solidity ^0.4.16;

//Define the pool
contract SmartPool {

    //Pool info
    uint currAmount;    //Current amount in the pool (=balance)
    uint ticketPrice;   //Price of one ticket
    uint startDate;		//The date of opening
	uint endDate;		//The date of closing (or 0 if still open)
	
	//Block infos (better to use block number than dates to trigger the end)
	uint startBlock;
	uint endBlock;
	
	//End triggers
	uint duration;		//The pool ends when the duration expire
    uint ticketCount;	//Or when the reserve of tickets has been sold
    bool ended;			//Current state (can&#39;t buy tickets when ended)
	bool terminated;	//true if a winner has been picked
	bool moneySent;		//true if the winner has picked his money
    
	//Min wait duration between ended and terminated states
	uint constant blockDuration = 15; // we use 15 sec for the block duration
	uint constant minWaitDuration = 240; // (= 3600 / blockDuration => 60 minutes waiting between &#39;ended&#39; and &#39;terminated&#39;)
	
    //Players
    address[] players;	//List of tickets owners, each ticket gives an entry in the array
	
	//Winning info
    address winner;		//The final winner (only available when terminated == true)
     
    //Pool manager address (only the manager can call modifiers of this contract, see PoolManager.sol)
    address poolManager;
    
    //Create a pool with a fixed ticket price, a ticket reserve and/or a duration)
    function SmartPool(uint _ticketPrice, uint _ticketCount, uint _duration) public
    {
		//Positive ticket price and either ticketCount or duration must be provided
        require(_ticketPrice > 0 && (_ticketCount > 0 || _duration > blockDuration));
		
		//Check for overflows
		require(now + _duration >= now);
		
		//Set ticketCount if needed (according to max balance)
		if (_ticketCount == 0)
		{
			_ticketCount = (2 ** 256 - 1) / _ticketPrice;
		}
		
		require(_ticketCount * _ticketPrice >= _ticketPrice);
		
		//Store manager
		poolManager = msg.sender;
		
        //Init
        currAmount = 0;
		startDate = now;
		endDate = 0;
		startBlock = block.number;
		endBlock = 0;
        ticketPrice = _ticketPrice;
        ticketCount = _ticketCount;
		duration = _duration / blockDuration; // compute duration in blocks
        ended = false;
		terminated = false;
		moneySent = false;
		winner = 0x0000000000000000000000000000000000000000;
    }

	
	//Accessors
	function getPlayers() public constant returns (address[])
    {
    	return players;
    }
	
	function getStartDate() public constant returns (uint)
    {
    	return startDate;
    }
	
	function getStartBlock() public constant returns (uint)
    {
    	return startBlock;
    }
	
    function getCurrAmount() public constant returns (uint)
    {
    	return currAmount;
    }
	
	function getTicketPrice() public constant returns (uint)
	{
		return ticketPrice;
	}
	
	function getTicketCount() public constant returns (uint)
	{
		return ticketCount;
	}
	
	function getBoughtTicketCount() public constant returns (uint)
	{
		return players.length;
	}
	
	function getAvailableTicketCount() public constant returns (uint)
	{
		return ticketCount - players.length;
	}
	
	function getEndDate() public constant returns (uint)
	{
		return endDate;
	}
	
	function getEndBlock() public constant returns (uint)
    {
    	return endBlock;
    }
	
	function getDuration() public constant returns (uint)
	{
		return duration; // duration in blocks
	}
	
	function getDurationS() public constant returns (uint)
	{
		return duration * blockDuration; // duration in seconds
	}
		
	function isEnded() public constant returns (bool)
	{
		return ended;
	}

	function isTerminated() public constant returns (bool)
	{
		return terminated;
	}
	
	function isMoneySent() public constant returns (bool)
	{
		return moneySent;
	}
	
	function getWinner() public constant returns (address)
	{
		return winner;
	}

	//End trigger
	function checkEnd() public
	{
		if ( (duration > 0 && block.number >= startBlock + duration) || (players.length >= ticketCount) )
        {
			ended = true;
			endDate = now;
			endBlock = block.number;
        }
	}
	
    //Add player with ticketCount to the pool (only poolManager can do this)
    function addPlayer(address player, uint ticketBoughtCount, uint amount) public  
	{
		//Only manager can call this
		require(msg.sender == poolManager);
		
        //Revert if pool ended (should not happen because the manager check this too)
        require (!ended);
		
        //Add amount to the pool
        currAmount += amount; // amount has been checked by the manager
        
        //Add player to the ticket owner array, for each bought ticket
		for (uint i = 0; i < ticketBoughtCount; i++)
			players.push(player);
        
        //Check end	
		checkEnd();
    }
	
	function canTerminate() public constant returns(bool)
	{
		return ended && !terminated && block.number - endBlock >= minWaitDuration;
	}

    //Terminate the pool by picking a winner (only poolManager can do this, after the pool is ended and some time has passed so the seed has changed many times)
    function terminate(uint randSeed) public 
	{		
		//Only manager can call this
		require(msg.sender == poolManager);
		
        //The pool need to be ended, but not terminated
        require(ended && !terminated);
		
		//Min duration between ended and terminated
		require(block.number - endBlock >= minWaitDuration);
		
		//Only one call to this function
        terminated = true;

		//Pick a winner
		if (players.length > 0)
			winner = players[randSeed % players.length];
    }
	
	//Update pool state (only poolManager can call this when the money has been sent)
	function onMoneySent() public
	{
		//Only manager can call this
		require(msg.sender == poolManager);
		
		//The pool must be terminated (winner picked)
		require(terminated);
		
		//Update money sent (only one call to this function)
		require(!moneySent);
		moneySent = true;
	}
}

       
//Wallet interface
contract WalletContract
{
	function payMe() public payable;
}
	   
	   
contract PoolManager {

	//Pool owner (address which manage the pool creation)
    address owner;
	
	//Wallet which receive the fees (1% of ticket price)
	address wallet;
	
	//Fees infos (external websites providing access to pools get 1% too)
	mapping(address => uint) fees;
		
	//Fees divider (1% for the wallet, and 1% for external website where player can buy tickets)
	uint constant feeDivider = 100; //(1/100 of the amount)

	//The ticket price for pools must be a multiple of 0.010205 ether (to avoid truncating the fees, and having a minimum to send to the winner)
    uint constant ticketPriceMultiple = 10205000000000000; //(multiple of 0.010205 ether for ticketPrice)

	//Pools infos (current active pools. When a pool is done, it goes into the poolsDone array bellow and a new pool is created to replace it at the same index)
	SmartPool[] pools;
	
	//Ended pools (cleaned automatically after winners get their prices)
	SmartPool[] poolsDone;
	
	//History (contains all the pools since the deploy)
	SmartPool[] poolsHistory;
	
	//Current rand seed (it changes a lot so it&#39;s pretty hard to know its value when the winner is picked)
	uint randSeed;

	//Constructor (only owner)
	function PoolManager(address wal) public
	{
		owner = msg.sender;
		wallet = wal;

		randSeed = 0;
	}
	
	//Called frequently by other functions to keep the seed moving
	function updateSeed() private
	{
		randSeed += (uint(block.blockhash(block.number - 1)));
	}
	
	//Create a new pool (only owner can do this)
	function addPool(uint ticketPrice, uint ticketCount, uint duration) public
	{
		require(msg.sender == owner);
		require(ticketPrice >= ticketPriceMultiple && ticketPrice % ticketPriceMultiple == 0);
		
		//Deploy a new pool
		pools.push(new SmartPool(ticketPrice, ticketCount, duration));
	}
	
	//Accessors (public)
	
	//Get Active Pools
	function getPoolCount() public constant returns(uint)
	{
		return pools.length;
	}
	function getPool(uint index) public constant returns(address)
	{
		require(index < pools.length);
		return pools[index];
	}
	
	//Get Ended Pools
	function getPoolDoneCount() public constant returns(uint)
	{
		return poolsDone.length;
	}
	function getPoolDone(uint index) public constant returns(address)
	{
		require(index < poolsDone.length);
		return poolsDone[index];
	}

	//Get History
	function getPoolHistoryCount() public constant returns(uint)
	{
		return poolsHistory.length;
	}
	function getPoolHistory(uint index) public constant returns(address)
	{
		require(index < poolsHistory.length);
		return poolsHistory[index];
	}
		
	//Buy tickets for a pool (public)
	function buyTicket(uint poolIndex, uint ticketCount, address websiteFeeAddr) public payable
	{
		require(poolIndex < pools.length);
		require(ticketCount > 0);
		
		//Get pool and check state
		SmartPool pool = pools[poolIndex];
		pool.checkEnd();
		require (!pool.isEnded());
		
		//Adjust ticketCount according to available tickets
		uint availableCount = pool.getAvailableTicketCount();
		if (ticketCount > availableCount)
			ticketCount = availableCount;
		
		//Get amount required and check msg.value
		uint amountRequired = ticketCount * pool.getTicketPrice();
		require(msg.value >= amountRequired);
		
		//If too much value sent, we send it back to player
		uint amountLeft = msg.value - amountRequired;
		
		//if no websiteFeeAddr given, the wallet get the fee
		if (websiteFeeAddr == address(0))
			websiteFeeAddr = wallet;
		
		//Compute fee
		uint feeAmount = amountRequired / feeDivider;
		
		addFee(websiteFeeAddr, feeAmount);
		addFee(wallet, feeAmount);
		
		//Add player to the pool with the amount minus the fees (1% + 1% = 2%)
		pool.addPlayer(msg.sender, ticketCount, amountRequired - 2 * feeAmount);
		
		//Send back amountLeft to player if too much value sent
		if (amountLeft > 0 && !msg.sender.send(amountLeft))
		{
			addFee(wallet, amountLeft); // if it fails, we take it as a fee..
		}
		
		updateSeed();
	}

	//Check pools end. (called by our console each 10 minutes, or can be called by anybody)
	function checkPoolsEnd() public 
	{
		for (uint i = 0; i < pools.length; i++)
		{
			//Check each pool and restart the ended ones
			checkPoolEnd(i);
		}
	}
	
	//Check end of a pool and restart it if it&#39;s ended (public)
	function checkPoolEnd(uint i) public 
	{
		require(i < pools.length);
		
		//Check end (if not triggered yet)
		SmartPool pool = pools[i];
		if (!pool.isEnded())
			pool.checkEnd();
			
		if (!pool.isEnded())
		{
			return; // not ended yet
		}
		
		updateSeed();
		
		//Store pool done and restart a pool to replace it
		poolsDone.push(pool);
		pools[i] = new SmartPool(pool.getTicketPrice(), pool.getTicketCount(), pool.getDurationS());
	}
	
	//Check pools done. (called by our console, or can be called by anybody)
	function checkPoolsDone() public 
	{
		for (uint i = 0; i < poolsDone.length; i++)
		{
			checkPoolDone(i);
		}
	}
	
	//Check end of one pool
	function checkPoolDone(uint i) public
	{
		require(i < poolsDone.length);
		
		SmartPool pool = poolsDone[i];
		if (pool.isTerminated())
			return; // already terminated
			
		if (!pool.canTerminate())
			return; // we need to wait a bit more before random occurs, so the seed has changed enough (60 minutes before ended and terminated states)
			
		updateSeed();
		
		//Terminate (pick a winner) and store pool done
		pool.terminate(randSeed);
	}

	//Send money of the pool to the winner (public)
	function sendPoolMoney(uint i) public
	{
		require(i < poolsDone.length);
		
		SmartPool pool = poolsDone[i];
		require (pool.isTerminated()); // we need a winner picked
		
		require(!pool.isMoneySent()); // money not sent
		
		uint amount = pool.getCurrAmount();
		address winner = pool.getWinner();
		pool.onMoneySent();
		if (amount > 0 && !winner.send(amount)) // the winner can&#39;t get his money (should not happen)
		{
			addFee(wallet, amount);
		}
		
		//Pool goes into history array
		poolsHistory.push(pool);
	}
		
	//Clear pools done array (called once a week by our console, or can be called by anybody)
	function clearPoolsDone() public
	{
		//Make sure all pools are terminated with no money left
		for (uint i = 0; i < poolsDone.length; i++)
		{
			if (!poolsDone[i].isMoneySent())
				return;
		}
		
		//"Clear" poolsDone array (just reset the length, instances will be override)
		poolsDone.length = 0;
	}
	
	//Get current fee value
	function getFeeValue(address a) public constant returns (uint)
	{
		if (a == address(0))
			a = msg.sender;
		return fees[a];
	}

	//Send fee to address (public, with a min amount required)
	function getMyFee(address a) public
	{
		if (a == address(0))
			a = msg.sender;
		uint amount = fees[a];
		require (amount > 0);
		
		fees[a] = 0;
		
		if (a == wallet)
		{
			WalletContract walletContract = WalletContract(a);
			walletContract.payMe.value(amount)();
		}
		else if (!a.send(amount))
			addFee(wallet, amount); // the fee can&#39;t be sent (hacking attempt?), so we take it... :-p
	}
	
	//Add fee (private)
	function addFee(address a, uint fee) private
	{
		if (fees[a] == 0)
			fees[a] = fee;
		else
			fees[a] += fee; // we don&#39;t check for overflow, if you&#39;re billionaire in fees, call getMyFee sometimes :-)
	}
}