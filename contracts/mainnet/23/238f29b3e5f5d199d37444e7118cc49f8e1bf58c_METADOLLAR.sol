pragma solidity ^0.4.18;

 // ERC Token Standard #20 Interface
 // https://github.com/ethereum/EIPs/issues/20

 contract ERC20Interface {
	/// @notice Get the total metadollars supply
	function totalSupply() constant returns (uint256 totalAmount);

	/// @notice  Get the account balance of another account with address _owner
	function balanceOf(address _owner) constant returns (uint256 balance);

	/// @notice  Send _value amount of metadollarss to address _to
	function transfer(address _to, uint256 _value) returns (bool success);

	/// @notice  Send _value amount of metadollars from address _from to address _to
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

	/// @notice  Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	/// @notice  If this function is called again it overwrites the current allowance with _value.
	/// @notice  this function is required for some DEX functionality
	function approve(address _spender, uint256 _value) returns (bool success);

	/// @notice  Returns the amount which _spender is still allowed to withdraw from _owner
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);

	/// @notice  Triggered when metadollars are transferred.
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	/// @notice  Triggered whenever approve(address _spender, uint256 _value) is called.
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
 
 contract owned{
	address public owner;
	address constant supervisor  = 0x2d6808bC989CbEB46cc6dd75a6C90deA50e3e504;
	
	function owned(){
		owner = msg.sender;
	}

	/// @notice Functions with this modifier can only be executed by the owner
	modifier isOwner {
		assert(msg.sender == owner || msg.sender == supervisor);
		_;
	}
	
	/// @notice Transfer the ownership of this contract
	function transferOwnership(address newOwner);
	
	event ownerChanged(address whoTransferredOwnership, address formerOwner, address newOwner);
 }

contract METADOLLAR is ERC20Interface, owned{

	string public constant name = "METADOLLAR";
	string public constant symbol = "DOL";
	uint public constant decimals = 18;
	uint256 public _totalSupply = 1000000000000000000000000000000;  // Total Supply 100,000,000,000
	uint256 public icoMin = 1000000000000000000000000000000;				 //  Min ICO 100,000,000	
	uint256 public preIcoLimit = 1000000000000000000;		 // Pre Ico Limit 1
	uint256 public countHolders = 0;				// count how many unique holders have metadollars
	uint256 public amountOfInvestments = 0;	// amount of collected wei
	
	uint256 preICOprice;									// price of 1 metadollar in weis for the preICO time
	uint256 ICOprice;										// price of 1 metadollar in weis for the ICO time
	uint256 public currentTokenPrice;				// current metadollar price in weis
	uint256 public sellPrice;								// buyback price of one metadollar in weis
	
	bool public preIcoIsRunning;
	bool public minimalGoalReached;
	bool public icoIsClosed;
	bool icoExitIsPossible;


	//Balances for each account
	mapping (address => uint256) public tokenBalanceOf;

	// Owner of account approves the transfer of an amount to another account
	mapping(address => mapping (address => uint256)) allowed;
	
	//list with information about frozen accounts
	mapping(address => bool) frozenAccount;
	
	//this generate a public event on a blockchain that will notify clients
	event FrozenFunds(address initiator, address account, string status);
	
	//this generate a public event on a blockchain that will notify clients
	event BonusChanged(uint8 bonusOld, uint8 bonusNew);
	
	//this generate a public event on a blockchain that will notify clients
	event minGoalReached(uint256 minIcoAmount, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event preIcoEnded(uint256 preIcoAmount, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event priceUpdated(uint256 oldPrice, uint256 newPrice, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event withdrawed(address _to, uint256 summe, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event deposited(address _from, uint256 summe, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event orderToTransfer(address initiator, address _from, address _to, uint256 summe, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event tokenCreated(address _creator, uint256 summe, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event tokenDestroyed(address _destroyer, uint256 summe, string notice);
	
	//this generate a public event on a blockchain that will notify clients
	event icoStatusUpdated(address _initiator, string status);

	/// @notice Constructor of the contract
	function STARTMETADOLLAR() {
		preIcoIsRunning = true;
		minimalGoalReached = false;
		icoExitIsPossible = false;
		icoIsClosed = false;
		tokenBalanceOf[this] += _totalSupply;
		allowed[this][owner] = _totalSupply;
		allowed[this][supervisor] = _totalSupply;
		currentTokenPrice = 1 * 1000 ether;	// initial price of 1 metadollar
		preICOprice = 1 * 1000 ether; 			// price of 1 metadollar in weis for the preICO time 
		ICOprice = 1 * 1000 ether;				// price of 1 metadollar in weis for the ICO time
		sellPrice = 1 * 950 ether;
		updatePrices();
	}

	function () payable {
		require(!frozenAccount[msg.sender]);
		if(msg.value > 0 && !frozenAccount[msg.sender]) {
			buyToken();
		}
	}

	/// @notice Returns a whole amount of metadollars
	function totalSupply() constant returns (uint256 totalAmount) {
		totalAmount = _totalSupply;
	}

	/// @notice What is the balance of a particular account?
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return tokenBalanceOf[_owner];
	}

	/// @notice Shows how much metadollars _spender can spend from _owner address
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	
	/// @notice Calculates amount of weis needed to buy more than one metadollar
	/// @param howManyTokenToBuy - Amount of metadollars to calculate
	function calculateTheEndPrice(uint256 howManyTokenToBuy) constant returns (uint256 summarizedPriceInWeis) {
		if(howManyTokenToBuy > 0) {
			summarizedPriceInWeis = howManyTokenToBuy * currentTokenPrice;
		}else {
			summarizedPriceInWeis = 0;
		}
	}
	
	/// @notice Shows if account is frozen
	/// @param account - Accountaddress to check
	function checkFrozenAccounts(address account) constant returns (bool accountIsFrozen) {
		accountIsFrozen = frozenAccount[account];
	}

	/// @notice Buy metadollars from contract by sending ether
	function buy() payable public {
		require(!frozenAccount[msg.sender]);
		require(msg.value > 0);
		buyToken();
	}

	/// @notice Sell metadollars and receive ether from contract
	function sell(uint256 amount) {
		require(!frozenAccount[msg.sender]);
		require(tokenBalanceOf[msg.sender] >= amount);         	// checks if the sender has enough to sell
		require(amount > 0);
		require(sellPrice > 0);
		_transfer(msg.sender, this, amount);
		uint256 revenue = amount * sellPrice;
		msg.sender.transfer(revenue);         // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
	}
	
	/// @notice Allow user to sell maximum possible amount of metadollars, depend on ether amount on contract
	function sellMaximumPossibleAmountOfTokens() {
		require(!frozenAccount[msg.sender]);
		require(tokenBalanceOf[msg.sender] > 0);
		require(this.balance > sellPrice);
		if(tokenBalanceOf[msg.sender] * sellPrice <= this.balance) {
			sell(tokenBalanceOf[msg.sender]);
		}else {
			sell(this.balance / sellPrice);
		}
	}

	/// @notice Transfer amount of metadollars from own wallet to someone else
	function transfer(address _to, uint256 _value) returns (bool success) {
		assert(msg.sender != address(0));
		assert(_to != address(0));
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_to]);
		require(tokenBalanceOf[msg.sender] >= _value);
		require(tokenBalanceOf[msg.sender] - _value < tokenBalanceOf[msg.sender]);
		require(tokenBalanceOf[_to] + _value > tokenBalanceOf[_to]);
		require(_value > 0);
		_transfer(msg.sender, _to, _value);
		return true;
	}

	/// @notice  Send _value amount of metadollars from address _from to address _to
	/// @notice  The transferFrom method is used for a withdraw workflow, allowing contracts to send
	/// @notice  tokens on your behalf, for example to "deposit" to a contract address and/or to charge
	/// @notice  fees in sub-currencies; the command should fail unless the _from account has
	/// @notice  deliberately authorized the sender of the message via some mechanism; we propose
	/// @notice  these standardized APIs for approval:
	function transferFrom(address _from,	address _to,	uint256 _value) returns (bool success) {
		assert(msg.sender != address(0));
		assert(_from != address(0));
		assert(_to != address(0));
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		require(tokenBalanceOf[_from] >= _value);
		require(allowed[_from][msg.sender] >= _value);
		require(tokenBalanceOf[_from] - _value < tokenBalanceOf[_from]);
		require(tokenBalanceOf[_to] + _value > tokenBalanceOf[_to]);
		require(_value > 0);
		orderToTransfer(msg.sender, _from, _to, _value, "Order to transfer metadollars from allowed account");
		_transfer(_from, _to, _value);
		allowed[_from][msg.sender] -= _value;
		return true;
	}

	/// @notice Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	/// @notice If this function is called again it overwrites the current allowance with _value.
	function approve(address _spender, uint256 _value) returns (bool success) {
		require(!frozenAccount[msg.sender]);
		assert(_spender != address(0));
		require(_value >= 0);
		allowed[msg.sender][_spender] = _value;
		return true;
	}

	/// @notice Check if minimal goal of ICO is reached
	function checkMinimalGoal() internal {
		if(tokenBalanceOf[this] <= _totalSupply - icoMin) {
			minimalGoalReached = true;
			minGoalReached(icoMin, "Minimal goal of ICO is reached!");
		}
	}

	/// @notice Check if preICO is ended
	function checkPreIcoStatus() internal {
		if(tokenBalanceOf[this] <= _totalSupply - preIcoLimit) {
			preIcoIsRunning = false;
			preIcoEnded(preIcoLimit, "Token amount for preICO sold!");
		}
	}

	/// @notice Processing each buying
	function buyToken() internal {
		uint256 value = msg.value;
		address sender = msg.sender;
		require(!icoIsClosed);
		require(!frozenAccount[sender]);
		require(value > 0);
		require(currentTokenPrice > 0);
		uint256 amount = value / currentTokenPrice;			// calculates amount of metadollars
		uint256 moneyBack = value - (amount * currentTokenPrice);
		require(tokenBalanceOf[this] >= amount);              		// checks if contract has enough to sell
		amountOfInvestments = amountOfInvestments + (value - moneyBack);
		updatePrices();
		_transfer(this, sender, amount);
		if(!minimalGoalReached) {
			checkMinimalGoal();
		}
		if(moneyBack > 0) {
			sender.transfer(moneyBack);
		}
	}

	/// @notice Internal transfer, can only be called by this contract
	function _transfer(address _from, address _to, uint256 _value) internal {
		assert(_from != address(0));
		assert(_to != address(0));
		require(_value > 0);
		require(tokenBalanceOf[_from] >= _value);
		require(tokenBalanceOf[_to] + _value > tokenBalanceOf[_to]);
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		if(tokenBalanceOf[_to] == 0){
			countHolders += 1;
		}
		tokenBalanceOf[_from] -= _value;
		if(tokenBalanceOf[_from] == 0){
			countHolders -= 1;
		}
		tokenBalanceOf[_to] += _value;
		allowed[this][owner] = tokenBalanceOf[this];
		allowed[this][supervisor] = tokenBalanceOf[this];
		Transfer(_from, _to, _value);
	}

	/// @notice Set current ICO prices in wei for one metadollar
	function updatePrices() internal {
		uint256 oldPrice = currentTokenPrice;
		if(preIcoIsRunning) {
			checkPreIcoStatus();
		}
		if(preIcoIsRunning) {
			currentTokenPrice = preICOprice;
		}else{
			currentTokenPrice = ICOprice;
		}
		
		if(oldPrice != currentTokenPrice) {
			priceUpdated(oldPrice, currentTokenPrice, "Metadollar price updated!");
		}
	}

	/// @notice Set current preICO price in wei for one metadollar
	/// @param priceForPreIcoInWei - is the amount in wei for one metadollar
	function setPreICOPrice(uint256 priceForPreIcoInWei) isOwner {
		require(priceForPreIcoInWei > 0);
		require(preICOprice != priceForPreIcoInWei);
		preICOprice = priceForPreIcoInWei;
		updatePrices();
	}
	

	/// @notice Set current ICO price price in wei for one metadollar
	/// @param priceForIcoInWei - is the amount in wei
	function setICOPrice(uint256 priceForIcoInWei) isOwner {
		require(priceForIcoInWei > 0);
		require(ICOprice != priceForIcoInWei);
		ICOprice = priceForIcoInWei;
		updatePrices();
	}
	
	

	/// @notice Set both prices at the same time
	/// @param priceForPreIcoInWei - Price of the metadollar in pre ICO
	/// @param priceForIcoInWei - Price of the metadollar in ICO
	function setPrices(uint256 priceForPreIcoInWei, uint256 priceForIcoInWei) isOwner {
		require(priceForPreIcoInWei > 0);
		require(priceForIcoInWei > 0);
		preICOprice = priceForPreIcoInWei;
		ICOprice = priceForIcoInWei;
		updatePrices();
	}
	
	

	/// @notice Set the current sell price in wei for one metadollar
	/// @param priceInWei - is the amount in wei for one metadollar
	function setSellPrice(uint256 priceInWei) isOwner {
		require(priceInWei >= 0);
		sellPrice = priceInWei;
	}

	/// @notice &#39;freeze? Prevent | Allow&#39; &#39;account&#39; from sending and receiving metadollars
	/// @param account - address to be frozen
	/// @param freeze - select is the account frozen or not
	function freezeAccount(address account, bool freeze) isOwner {
		require(account != owner);
		require(account != supervisor);
		frozenAccount[account] = freeze;
		if(freeze) {
			FrozenFunds(msg.sender, account, "Account set frozen!");
		}else {
			FrozenFunds(msg.sender, account, "Account set free for use!");
		}
	}

	/// @notice Create an amount of metadollars
	/// @param amount - metadollars to create
	function mintToken(uint256 amount) isOwner {
		require(amount > 0);
		require(tokenBalanceOf[this] <= icoMin);	// owner can create metadollars only if the initial amount is strongly not enough to supply and demand ICO
		require(_totalSupply + amount > _totalSupply);
		require(tokenBalanceOf[this] + amount > tokenBalanceOf[this]);
		_totalSupply += amount;
		tokenBalanceOf[this] += amount;
		allowed[this][owner] = tokenBalanceOf[this];
		allowed[this][supervisor] = tokenBalanceOf[this];
		tokenCreated(msg.sender, amount, "Additional metadollars created!");
	}

	/// @notice Destroy an amount of metadollars
	/// @param amount - token to destroy
	function destroyToken(uint256 amount) isOwner {
		require(amount > 0);
		require(tokenBalanceOf[this] >= amount);
		require(_totalSupply >= amount);
		require(tokenBalanceOf[this] - amount >= 0);
		require(_totalSupply - amount >= 0);
		tokenBalanceOf[this] -= amount;
		_totalSupply -= amount;
		allowed[this][owner] = tokenBalanceOf[this];
		allowed[this][supervisor] = tokenBalanceOf[this];
		tokenDestroyed(msg.sender, amount, "An amount of metadollars destroyed!");
	}

	/// @notice Transfer the ownership to another account
	/// @param newOwner - address who get the ownership
	function transferOwnership(address newOwner) isOwner {
		assert(newOwner != address(0));
		address oldOwner = owner;
		owner = newOwner;
		ownerChanged(msg.sender, oldOwner, newOwner);
		allowed[this][oldOwner] = 0;
		allowed[this][newOwner] = tokenBalanceOf[this];
	}

	/// @notice Transfer ether from smartcontract to owner
	function collect() isOwner {
        require(this.balance > 0);
		withdraw(this.balance);
    }

	/// @notice Withdraw an amount of ether
	/// @param summeInWei - amout to withdraw
	function withdraw(uint256 summeInWei) isOwner {
		uint256 contractbalance = this.balance;
		address sender = msg.sender;
		require(contractbalance >= summeInWei);
		withdrawed(sender, summeInWei, "wei withdrawed");
        sender.transfer(summeInWei);
	}

	/// @notice Deposit an amount of ether
	function deposit() payable isOwner {
		require(msg.value > 0);
		require(msg.sender.balance >= msg.value);
		deposited(msg.sender, msg.value, "wei deposited");
	}

	/// @notice Allow user to exit ICO
	/// @param exitAllowed - status if the exit is allowed
	function allowIcoExit(bool exitAllowed) isOwner {
		require(icoExitIsPossible != exitAllowed);
		icoExitIsPossible = exitAllowed;
	}

	/// @notice Stop running ICO
	/// @param icoIsStopped - status if this ICO is stopped
	function stopThisIco(bool icoIsStopped) isOwner {
		require(icoIsClosed != icoIsStopped);
		icoIsClosed = icoIsStopped;
		if(icoIsStopped) {
			icoStatusUpdated(msg.sender, "Coin offering was stopped!");
		}else {
			icoStatusUpdated(msg.sender, "Coin offering is running!");
		}
	}

	/// @notice Sell all metadollars for half of a price and exit this ICO
	function exitThisIcoForHalfOfTokenPrice() {
		require(icoExitIsPossible);
		require(!frozenAccount[msg.sender]);
		require(tokenBalanceOf[msg.sender] > 0);         	// checks if the sender has enough to sell
		require(currentTokenPrice > 1);
		uint256 amount = tokenBalanceOf[msg.sender] ;
		uint256 revenue = amount * currentTokenPrice / 2;
		require(this.balance >= revenue);
		_transfer(msg.sender, this, amount);
		msg.sender.transfer(revenue);                	// sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
	}

	/// @notice Sell all of metadollars for all ether of this smartcontract
	function getAllMyTokensForAllEtherOnContract() {
		require(icoExitIsPossible);
		require(!frozenAccount[msg.sender]);
		require(tokenBalanceOf[msg.sender] > 0);         	// checks if the sender has enough to sell
		require(currentTokenPrice > 1);
		uint256 amount = tokenBalanceOf[msg.sender] ;
		uint256 revenue = amount * currentTokenPrice / 2;
		require(this.balance <= revenue);
		_transfer(msg.sender, this, amount);
		msg.sender.transfer(this.balance); 
	}
}