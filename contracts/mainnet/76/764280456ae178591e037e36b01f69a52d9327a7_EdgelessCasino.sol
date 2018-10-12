/**
 * The test edgeless casino contract v2 holds the players&#39;s funds and provides state channel functionality.
 * The casino has at no time control over the players&#39;s funds.
 * State channels can be updated and closed from both parties: the player and the casino.
 * author: Rytis Grincevicius
 **/

pragma solidity ^0.4.21;

contract SafeMath {

	function safeSub(uint a, uint b) pure internal returns(uint) {
		assert(b <= a);
		return a - b;
	}
	
	function safeSub(int a, int b) pure internal returns(int) {
		if(b < 0) assert(a - b > a);
		else assert(a - b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) pure internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeMul(uint a, uint b) pure internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
}


contract Token {
	function transferFrom(address sender, address receiver, uint amount) public returns(bool success);

	function transfer(address receiver, uint amount) public returns(bool success);

	function balanceOf(address holder) public view returns(uint);
}

contract Owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function Owned() public{
    owner = msg.sender;
  }

}

/** owner should be able to close the contract is nobody has been using it for at least 30 days */
contract Mortal is Owned {
	/** contract can be closed by the owner anytime after this timestamp if non-zero */
	uint public closeAt;
	/** the edgeless token contract */
	Token edg;
	
	function Mortal(address tokenContract) internal{
		edg = Token(tokenContract);
	}
	/**
	* lets the owner close the contract if there are no player funds on it or if nobody has been using it for at least 30 days
	*/
  function closeContract(uint playerBalance) internal{
		if(closeAt == 0) closeAt = now + 30 days;
		if(closeAt < now || playerBalance == 0){
			edg.transfer(owner, edg.balanceOf(address(this)));
			selfdestruct(owner);
		} 
  }

	/**
	* in case close has been called accidentally.
	**/
	function open() onlyOwner public{
		closeAt = 0;
	}

	/**
	* make sure the contract is not in process of being closed.
	**/
	modifier isAlive {
		require(closeAt == 0);
		_;
	}

	/**
	* delays the time of closing.
	**/
	modifier keepAlive {
		if(closeAt > 0) closeAt = now + 30 days;
		_;
	}
}

contract RequiringAuthorization is Mortal {
	/** indicates if an address is authorized to act in the casino&#39;s name  */
	mapping(address => bool) public authorized;
	/** tells if an address is allowed to receive funds from the bankroll **/
	mapping(address => bool) public allowedReceiver;

	modifier onlyAuthorized {
		require(authorized[msg.sender]);
		_;
	}

	/**
	 * Constructor. Authorize the owner.
	 * */
	function RequiringAuthorization() internal {
		authorized[msg.sender] = true;
		allowedReceiver[msg.sender] = true;
	}

	/**
	 * authorize a address to call game functions and set configs.
	 * @param addr the address to be authorized
	 **/
	function authorize(address addr) public onlyOwner {
		authorized[addr] = true;
	}

	/**
	 * deauthorize a address to call game functions and set configs.
	 * @param addr the address to be deauthorized
	 **/
	function deauthorize(address addr) public onlyOwner {
		authorized[addr] = false;
	}

	/**
	 * allow authorized wallets to withdraw funds from the bonkroll to this address
	 * @param receiver the receiver&#39;s address
	 * */
	function allowReceiver(address receiver) public onlyOwner {
		allowedReceiver[receiver] = true;
	}

	/**
	 * disallow authorized wallets to withdraw funds from the bonkroll to this address
	 * @param receiver the receiver&#39;s address
	 * */
	function disallowReceiver(address receiver) public onlyOwner {
		allowedReceiver[receiver] = false;
	}

	/**
	 * changes the owner of the contract. revokes authorization of the old owner and authorizes the new one.
	 * @param newOwner the address of the new owner
	 * */
	function changeOwner(address newOwner) public onlyOwner {
		deauthorize(owner);
		authorize(newOwner);
		disallowReceiver(owner);
		allowReceiver(newOwner);
		owner = newOwner;
	}
}

contract ChargingGas is RequiringAuthorization, SafeMath {
	/** 1 EDG has 5 decimals **/
	uint public constant oneEDG = 100000;
	/** the price per kgas and GWei in tokens (with decimals) */
	uint public gasPrice;
	/** the amount of gas used per transaction in kGas */
	mapping(bytes4 => uint) public gasPerTx;
	/** the number of tokens (5 decimals) payed by the users to cover the gas cost */
	uint public gasPayback;
	
	function ChargingGas(uint kGasPrice) internal{
		//deposit, withdrawFor, updateChannel, updateBatch, transferToNewContract
	    bytes4[5] memory signatures = [bytes4(0x3edd1128),0x9607610a, 0xde48ff52, 0xc97b6d1f, 0x6bf06fde];
	    //amount of gas consumed by the above methods in GWei
	    uint[5] memory gasUsage = [uint(146), 100, 65, 50, 85];
	    setGasUsage(signatures, gasUsage);
	    setGasPrice(kGasPrice);
	}
	/**
	 * sets the amount of gas consumed by methods with the given sigantures.
	 * only called from the edgeless casino constructor.
	 * @param signatures an array of method-signatures
	 *        gasNeeded  the amount of gas consumed by these methods
	 * */
	function setGasUsage(bytes4[5] signatures, uint[5] gasNeeded) public onlyOwner {
		require(signatures.length == gasNeeded.length);
		for (uint8 i = 0; i < signatures.length; i++)
			gasPerTx[signatures[i]] = gasNeeded[i];
	}

	/**
	 * updates the price per 1000 gas in EDG.
	 * @param price the new gas price (with decimals, max 0.1 EDG)
	 **/
	function setGasPrice(uint price) public onlyAuthorized {
		require(price < oneEDG/10);
		gasPrice = price;
	}

	/**
	 * returns the gas cost of the called function.
	 * */
	function getGasCost() internal view returns(uint) {
		return safeMul(safeMul(gasPerTx[msg.sig], gasPrice), tx.gasprice) / 1000000000;
	}

}


contract CasinoBank is ChargingGas {
	/** the total balance of all players with virtual decimals **/
	uint public playerBalance;
	/** the balance per player in edgeless tokens with virtual decimals */
	mapping(address => uint) public balanceOf;
	/** in case the user wants/needs to call the withdraw function from his own wallet, he first needs to request a withdrawal */
	mapping(address => uint) public withdrawAfter;
	/** a number to count withdrawal signatures to ensure each signature is different even if withdrawing the same amount to the same address */
	mapping(address => uint) public withdrawCount;
	/** the maximum amount of tokens the user is allowed to deposit (with decimals) */
	uint public maxDeposit;
	/** the maximum withdrawal of tokens the user is allowed to withdraw on one day (only enforced when the tx is not sent from an authorized wallet) **/
	uint public maxWithdrawal;
	/** waiting time for withdrawal if not requested via the server **/
	uint public waitingTime;
	/** the address of the predecessor **/
	address public predecessor;

	/** informs listeners how many tokens were deposited for a player */
	event Deposit(address _player, uint _numTokens, uint _gasCost);
	/** informs listeners how many tokens were withdrawn from the player to the receiver address */
	event Withdrawal(address _player, address _receiver, uint _numTokens, uint _gasCost);
	
	
	/**
	 * Constructor.
	 * @param depositLimit    the maximum deposit allowed
	 *		  predecessorAddr the address of the predecessing contract
	 * */
	function CasinoBank(uint depositLimit, address predecessorAddr) internal {
		maxDeposit = depositLimit * oneEDG;
		maxWithdrawal = maxDeposit;
		waitingTime = 24 hours;
		predecessor = predecessorAddr;
	}

	/**
	 * accepts deposits for an arbitrary address.
	 * retrieves tokens from the message sender and adds them to the balance of the specified address.
	 * edgeless tokens do not have any decimals, but are represented on this contract with decimals.
	 * @param receiver  address of the receiver
	 *        numTokens number of tokens to deposit (0 decimals)
	 *				 chargeGas indicates if the gas cost is subtracted from the user&#39;s edgeless token balance
	 **/
	function deposit(address receiver, uint numTokens, bool chargeGas) public isAlive {
		require(numTokens > 0);
		uint value = safeMul(numTokens, oneEDG);
		uint gasCost;
		if (chargeGas) {
			gasCost = getGasCost();
			value = safeSub(value, gasCost);
			gasPayback = safeAdd(gasPayback, gasCost);
		}
		uint newBalance = safeAdd(balanceOf[receiver], value);
		require(newBalance <= maxDeposit);
		assert(edg.transferFrom(msg.sender, address(this), numTokens));
		balanceOf[receiver] = newBalance;
		playerBalance = safeAdd(playerBalance, value);
		emit Deposit(receiver, numTokens, gasCost);
	}

	/**
	 * If the user wants/needs to withdraw his funds himself, he needs to request the withdrawal first.
	 * This method sets the earliest possible withdrawal date to &#39;waitingTime from now (default 90m, but up to 24h).
	 * Reason: The user should not be able to withdraw his funds, while the the last game methods have not yet been mined.
	 **/
	function requestWithdrawal() public {
		withdrawAfter[msg.sender] = now + waitingTime;
	}

	/**
	 * In case the user requested a withdrawal and changes his mind.
	 * Necessary to be able to continue playing.
	 **/
	function cancelWithdrawalRequest() public {
		withdrawAfter[msg.sender] = 0;
	}

	/**
	 * withdraws an amount from the user balance if the waiting time passed since the request.
	 * @param amount the amount of tokens to withdraw
	 **/
	function withdraw(uint amount) public keepAlive {
		require(amount <= maxWithdrawal);
		require(withdrawAfter[msg.sender] > 0 && now > withdrawAfter[msg.sender]);
		withdrawAfter[msg.sender] = 0;
		uint value = safeMul(amount, oneEDG);
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
		playerBalance = safeSub(playerBalance, value);
		assert(edg.transfer(msg.sender, amount));
		emit Withdrawal(msg.sender, msg.sender, amount, 0);
	}

	/**
	 * lets the owner withdraw from the bankroll
	 * @param receiver the receiver&#39;s address
	 *				numTokens the number of tokens to withdraw (0 decimals)
	 **/
	function withdrawBankroll(address receiver, uint numTokens) public onlyAuthorized {
		require(numTokens <= bankroll());
		require(allowedReceiver[receiver]);
		assert(edg.transfer(receiver, numTokens));
	}

	/**
	 * withdraw the gas payback to the owner
	 **/
	function withdrawGasPayback() public onlyAuthorized {
		uint payback = gasPayback / oneEDG;
		assert(payback > 0);
		gasPayback = safeSub(gasPayback, payback * oneEDG);
		assert(edg.transfer(owner, payback));
	}

	/**
	 * returns the current bankroll in tokens with 0 decimals
	 **/
	function bankroll() view public returns(uint) {
		return safeSub(edg.balanceOf(address(this)), safeAdd(playerBalance, gasPayback) / oneEDG);
	}


	/**
	 * updates the maximum deposit.
	 * @param newMax the new maximum deposit (0 decimals)
	 **/
	function setMaxDeposit(uint newMax) public onlyAuthorized {
		maxDeposit = newMax * oneEDG;
	}
	
	/**
	 * updates the maximum withdrawal.
	 * @param newMax the new maximum withdrawal (0 decimals)
	 **/
	function setMaxWithdrawal(uint newMax) public onlyAuthorized {
		maxWithdrawal = newMax * oneEDG;
	}

	/**
	 * sets the time the player has to wait for his funds to be unlocked before withdrawal (if not withdrawing with help of the casino server).
	 * the time may not be longer than 24 hours.
	 * @param newWaitingTime the new waiting time in seconds
	 * */
	function setWaitingTime(uint newWaitingTime) public onlyAuthorized  {
		require(newWaitingTime <= 24 hours);
		waitingTime = newWaitingTime;
	}

	/**
	 * transfers an amount from the contract balance to the owner&#39;s wallet.
	 * @param receiver the receiver address
	 *				 amount   the amount of tokens to withdraw (0 decimals)
	 *				 v,r,s 		the signature of the player
	 **/
	function withdrawFor(address receiver, uint amount, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized keepAlive {
		address player = ecrecover(keccak256(receiver, amount, withdrawCount[receiver]), v, r, s);
		withdrawCount[receiver]++;
		uint gasCost = getGasCost();
		uint value = safeAdd(safeMul(amount, oneEDG), gasCost);
		gasPayback = safeAdd(gasPayback, gasCost);
		balanceOf[player] = safeSub(balanceOf[player], value);
		playerBalance = safeSub(playerBalance, value);
		assert(edg.transfer(receiver, amount));
		emit Withdrawal(player, receiver, amount, gasCost);
	}
	
	/**
	 * transfers the player&#39;s tokens directly to the new casino contract after an update.
	 * @param newCasino the address of the new casino contract
	 *		  v, r, s   the signature of the player
	 *		  chargeGas indicates if the gas cost is payed by the player.
	 * */
	function transferToNewContract(address newCasino, uint8 v, bytes32 r, bytes32 s, bool chargeGas) public onlyAuthorized keepAlive {
		address player = ecrecover(keccak256(address(this), newCasino), v, r, s);
		uint gasCost = 0;
		if(chargeGas) gasCost = getGasCost();
		uint value = safeSub(balanceOf[player], gasCost);
		require(value > oneEDG);
		//fractions of one EDG cannot be withdrawn 
		value /= oneEDG;
		playerBalance = safeSub(playerBalance, balanceOf[player]);
		balanceOf[player] = 0;
		assert(edg.transfer(newCasino, value));
		emit Withdrawal(player, newCasino, value, gasCost);
		CasinoBank cb = CasinoBank(newCasino);
		assert(cb.credit(player, value));
	}
	
	/**
	 * receive a player balance from the predecessor contract.
	 * @param player the address of the player to credit the value for
	 *				value  the number of tokens to credit (0 decimals)
	 * */
	function credit(address player, uint value) public returns(bool) {
		require(msg.sender == predecessor);
		uint valueWithDecimals = safeMul(value, oneEDG);
		balanceOf[player] = safeAdd(balanceOf[player], valueWithDecimals);
		playerBalance = safeAdd(playerBalance, valueWithDecimals);
		emit Deposit(player, value, 0);
		return true;
	}

	/**
	 * lets the owner close the contract if there are no player funds on it or if nobody has been using it for at least 30 days
	 * */
	function close() public onlyOwner {
		closeContract(playerBalance);
	}
}


contract EdgelessCasino is CasinoBank{
	/** the most recent known state of a state channel */
	mapping(address => State) public lastState;
	/** fired when the state is updated */
	event StateUpdate(address player, uint128 count, int128 winBalance, int difference, uint gasCost);
  /** fired if one of the parties chooses to log the seeds and results */
  event GameData(address player, bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint gasCost);
  
	struct State{
		uint128 count;
		int128 winBalance;
	}


  /**
  * creates a new edgeless casino contract.
  * @param predecessorAddress the address of the predecessing contract
	*				 tokenContract      the address of the Edgeless token contract
	* 			 depositLimit       the maximum deposit allowed
	* 			 kGasPrice				  the price per kGas in WEI
  **/
  function EdgelessCasino(address predecessorAddress, address tokenContract, uint depositLimit, uint kGasPrice) CasinoBank(depositLimit, predecessorAddress) Mortal(tokenContract) ChargingGas(kGasPrice) public{

  }
  
  /**
   * updates several state channels at once. can be called by authorized wallets only.
   * 1. determines the player address from the signature.
   * 2. verifies if the signed game-count is higher than the last known game-count of this channel.
   * 3. updates the balances accordingly. This means: It checks the already performed updates for this channel and computes
   *    the new balance difference to add or subtract from the player‘s balance.
   * @param winBalances array of the current wins or losses
   *				gameCounts  array of the numbers of signed game moves
   *				v,r,s       array of the players&#39;s signatures
   *        chargeGas   indicates if the gas costs should be subtracted from the players&#39;s balances
   * */
  function updateBatch(int128[] winBalances,  uint128[] gameCounts, uint8[] v, bytes32[] r, bytes32[] s, bool chargeGas) public onlyAuthorized{
    require(winBalances.length == gameCounts.length);
    require(winBalances.length == v.length);
    require(winBalances.length == r.length);
    require(winBalances.length == s.length);
    require(winBalances.length <= 50);
    address player;
    uint gasCost = 0;
    if(chargeGas) 
      gasCost = getGasCost();
    gasPayback = safeAdd(gasPayback, safeMul(gasCost, winBalances.length));
    for(uint8 i = 0; i < winBalances.length; i++){
      player = ecrecover(keccak256(winBalances[i], gameCounts[i]), v[i], r[i], s[i]);
      _updateState(player, winBalances[i], gameCounts[i], gasCost);
    }
  }

  /**
   * updates a state channel. can be called by both parties.
   * 1. verifies the signature.
   * 2. verifies if the signed game-count is higher than the last known game-count of this channel.
   * 3. updates the balances accordingly. This means: It checks the already performed updates for this channel and computes
   *    the new balance difference to add or subtract from the player‘s balance.
   * @param winBalance the current win or loss
   *				gameCount  the number of signed game moves
   *				v,r,s      the signature of either the casino or the player
   *        chargeGas  indicates if the gas costs should be subtracted from the player&#39;s balance
   * */
  function updateState(int128 winBalance,  uint128 gameCount, uint8 v, bytes32 r, bytes32 s, bool chargeGas) public{
  	address player = determinePlayer(winBalance, gameCount, v, r, s);
  	uint gasCost = 0;
  	if(player == msg.sender)//if the player closes the state channel himself, make sure the signer is a casino wallet
  		require(authorized[ecrecover(keccak256(player, winBalance, gameCount), v, r, s)]);
  	else if (chargeGas){//subtract the gas costs from the player balance only if the casino wallet is the sender
  		gasCost = getGasCost();
  		gasPayback = safeAdd(gasPayback, gasCost);
  	}
  	_updateState(player, winBalance, gameCount, gasCost);
  }
  
  /**
   * internal method to perform the actual state update.
   * @param player the player address
   *        winBalance the player&#39;s win balance
   *        gameCount  the player&#39;s game count
   * */
  function _updateState(address player, int128 winBalance,  uint128 gameCount, uint gasCost) internal {
    State storage last = lastState[player];
  	require(gameCount > last.count);
  	int difference = updatePlayerBalance(player, winBalance, last.winBalance, gasCost);
  	lastState[player] = State(gameCount, winBalance);
  	emit StateUpdate(player, gameCount, winBalance, difference, gasCost);
  }

  /**
   * determines if the msg.sender or the signer of the passed signature is the player. returns the player&#39;s address
   * @param winBalance the current winBalance, used to calculate the msg hash
   *				gameCount  the current gameCount, used to calculate the msg.hash
   *				v, r, s    the signature of the non-sending party
   * */
  function determinePlayer(int128 winBalance, uint128 gameCount, uint8 v, bytes32 r, bytes32 s) view internal returns(address){
  	if (authorized[msg.sender])//casino is the sender -> player is the signer
  		return ecrecover(keccak256(winBalance, gameCount), v, r, s);
  	else
  		return msg.sender;
  }

	/**
	 * computes the difference of the win balance relative to the last known state and adds it to the player&#39;s balance.
	 * in case the casino is the sender, the gas cost in EDG gets subtracted from the player&#39;s balance.
	 * @param player the address of the player
	 *				winBalance the current win-balance
	 *				lastWinBalance the win-balance of the last known state
	 *				gasCost the gas cost of the tx
	 * */
  function updatePlayerBalance(address player, int128 winBalance, int128 lastWinBalance, uint gasCost) internal returns(int difference){
  	difference = safeSub(winBalance, lastWinBalance);
  	int outstanding = safeSub(difference, int(gasCost));
  	uint outs;
  	if(outstanding < 0){
  		outs = uint256(outstanding * (-1));
  		playerBalance = safeSub(playerBalance, outs);
  		balanceOf[player] = safeSub(balanceOf[player], outs);
  	}
  	else{
  		outs = uint256(outstanding);
  		assert(bankroll() * oneEDG > outs);
  	  playerBalance = safeAdd(playerBalance, outs);
  	  balanceOf[player] = safeAdd(balanceOf[player], outs);
  	}
  }
  
  /**
   * logs some seeds and game results for players wishing to have their game history logged by the contract
   * @param serverSeeds array containing the server seeds
   *        clientSeeds array containing the client seeds
   *        results     array containing the results
   *        v, r, s     the signature of the non-sending party (to make sure the correct results are logged)
   * */
  function logGameData(bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint8 v, bytes32 r, bytes32 s) public{
    address player = determinePlayer(serverSeeds, clientSeeds, results, v, r, s);
    uint gasCost;
    //charge gas in case the server is logging the results for the player
    if(player != msg.sender){
      gasCost = (57 + 768 * serverSeeds.length / 1000)*gasPrice;
      balanceOf[player] = safeSub(balanceOf[player], gasCost);
      playerBalance = safeSub(playerBalance, gasCost);
      gasPayback = safeAdd(gasPayback, gasCost);
    }
    emit GameData(player, serverSeeds, clientSeeds, results, gasCost);
  }
  
  /**
   * determines if the msg.sender or the signer of the passed signature is the player. returns the player&#39;s address
   * @param serverSeeds array containing the server seeds
   *        clientSeeds array containing the client seeds
   *        results     array containing the results
   *				v, r, s    the signature of the non-sending party
   * */
  function determinePlayer(bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint8 v, bytes32 r, bytes32 s) view internal returns(address){
  	address signer = ecrecover(keccak256(serverSeeds, clientSeeds, results), v, r, s);
  	if (authorized[msg.sender])//casino is the sender -> player is the signer
  		return signer;
  	else if (authorized[signer])
  		return msg.sender;
  	else 
  	  revert();
  }

}