/**
 * Edgeless Casino Proxy Contract. Serves as a proxy for game functionality.
 * Allows the players to deposit and withdraw funds.
 * Allows authorized addresses to make game transactions.
 * author: Julia Altenried
 **/

pragma solidity ^ 0.4 .17;


contract token {
	function transferFrom(address sender, address receiver, uint amount) public returns(bool success) {}

	function transfer(address receiver, uint amount) public returns(bool success) {}

	function balanceOf(address holder) public constant returns(uint) {}
}

contract owned {
	address public owner;
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function owned() public {
		owner = msg.sender;
	}

	function changeOwner(address newOwner) onlyOwner public {
		owner = newOwner;
	}
}

contract safeMath {
	//internals
	function safeSub(uint a, uint b) constant internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) constant internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeMul(uint a, uint b) constant internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
}

contract casinoBank is owned, safeMath {
	/** the total balance of all players with 4 virtual decimals **/
	uint public playerBalance;
	/** the balance per player in edgeless tokens with 4 virtual decimals */
	mapping(address => uint) public balanceOf;
	/** in case the user wants/needs to call the withdraw function from his own wallet, he first needs to request a withdrawal */
	mapping(address => uint) public withdrawAfter;
	/** the price per kgas in tokens (4 decimals) */
	uint public gasPrice = 20;
	/** the edgeless token contract */
	token edg;
	/** owner should be able to close the contract is nobody has been using it for at least 30 days */
	uint public closeAt;
	/** informs listeners how many tokens were deposited for a player */
	event Deposit(address _player, uint _numTokens, bool _chargeGas);
	/** informs listeners how many tokens were withdrawn from the player to the receiver address */
	event Withdrawal(address _player, address _receiver, uint _numTokens);

	function casinoBank(address tokenContract) public {
		edg = token(tokenContract);
	}

	/**
	 * accepts deposits for an arbitrary address.
	 * retrieves tokens from the message sender and adds them to the balance of the specified address.
	 * edgeless tokens do not have any decimals, but are represented on this contract with 4 decimals.
	 * @param receiver  address of the receiver
	 *        numTokens number of tokens to deposit (0 decimals)
	 *				 chargeGas indicates if the gas cost is subtracted from the user&#39;s edgeless token balance
	 **/
	function deposit(address receiver, uint numTokens, bool chargeGas) public isAlive {
		require(numTokens > 0);
		uint value = safeMul(numTokens, 10000);
		if (chargeGas) value = safeSub(value, msg.gas / 1000 * gasPrice);
		assert(edg.transferFrom(msg.sender, address(this), numTokens));
		balanceOf[receiver] = safeAdd(balanceOf[receiver], value);
		playerBalance = safeAdd(playerBalance, value);
		Deposit(receiver, numTokens, chargeGas);
	}

	/**
	 * If the user wants/needs to withdraw his funds himself, he needs to request the withdrawal first.
	 * This method sets the earliest possible withdrawal date to 7 minutes from now. 
	 * Reason: The user should not be able to withdraw his funds, while the the last game methods have not yet been mined.
	 **/
	function requestWithdrawal() public {
		withdrawAfter[msg.sender] = now + 7 minutes;
	}

	/**
	 * In case the user requested a withdrawal and changes his mind.
	 * Necessary to be able to continue playing.
	 **/
	function cancelWithdrawalRequest() public {
		withdrawAfter[msg.sender] = 0;
	}

	/**
	 * withdraws an amount from the user balance if 7 minutes passed since the request.
	 * @param amount the amount of tokens to withdraw
	 **/
	function withdraw(uint amount) public keepAlive {
		require(withdrawAfter[msg.sender] > 0 && now > withdrawAfter[msg.sender]);
		withdrawAfter[msg.sender] = 0;
		uint value = safeMul(amount, 10000);
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
		playerBalance = safeSub(playerBalance, value);
		assert(edg.transfer(msg.sender, amount));
		Withdrawal(msg.sender, msg.sender, amount);
	}

	/**
	 * lets the owner withdraw from the bankroll
	 * @param numTokens the number of tokens to withdraw (0 decimals)
	 **/
	function withdrawBankroll(uint numTokens) public onlyOwner {
		require(numTokens <= bankroll());
		assert(edg.transfer(owner, numTokens));
	}

	/**
	 * returns the current bankroll in tokens with 0 decimals
	 **/
	function bankroll() constant public returns(uint) {
		return safeSub(edg.balanceOf(address(this)), playerBalance / 10000);
	}

	/** 
	 * lets the owner close the contract if there are no player funds on it or if nobody has been using it for at least 30 days 
	 */
	function close() onlyOwner public {
		if (playerBalance == 0) selfdestruct(owner);
		if (closeAt == 0) closeAt = now + 30 days;
		else if (closeAt < now) selfdestruct(owner);
	}

	/**
	 * in case close has been called accidentally.
	 **/
	function open() onlyOwner public {
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
		if (closeAt > 0) closeAt = now + 30 days;
		_;
	}
}

contract casinoProxy is casinoBank {
	/** indicates if an address is authorized to call game functions  */
	mapping(address => bool) public authorized;
	/** list of casino game contract addresses */
	address[] public casinoGames;
	/** a number to count withdrawal signatures to ensure each signature is different even if withdrawing the same amount to the same address */
	mapping(address => uint) public count;

	modifier onlyAuthorized {
		require(authorized[msg.sender]);
		_;
	}

	modifier onlyCasinoGames {
		bool isCasino;
		for (uint i = 0; i < casinoGames.length; i++) {
			if (msg.sender == casinoGames[i]) {
				isCasino = true;
				break;
			}
		}
		require(isCasino);
		_;
	}

	/**
	 * creates a new casino wallet.
	 * @param authorizedAddress the address which may send transactions to the Edgeless Casino
	 *        blackjackAddress  the address of the Edgeless blackjack contract
	 *				 tokenContract     the address of the Edgeless token contract
	 **/
	function casinoProxy(address authorizedAddress, address blackjackAddress, address tokenContract) casinoBank(tokenContract) public {
		authorized[authorizedAddress] = true;
		casinoGames.push(blackjackAddress);
	}

	/**
	 * shifts tokens from the contract balance to the receiver.
	 * only callable from an edgeless casino contract.
	 * @param receiver the address of the receiver
	 *        numTokens the amount of tokens to shift with 4 decimals
	 **/
	function shift(address receiver, uint numTokens) public onlyCasinoGames {
		balanceOf[receiver] = safeAdd(balanceOf[receiver], numTokens);
		playerBalance = safeAdd(playerBalance, numTokens);
	}

	/**
	 * transfers an amount from the contract balance to the owner&#39;s wallet.
	 * @param receiver the receiver address
	 *				 amount   the amount of tokens to withdraw (0 decimals)
	 *				 v,r,s 		the signature of the player
	 **/
	function withdrawFor(address receiver, uint amount, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized keepAlive {
		uint gasCost = msg.gas / 1000 * gasPrice;
		var player = ecrecover(keccak256(receiver, amount, count[receiver]), v, r, s);
		count[receiver]++;
		uint value = safeAdd(safeMul(amount, 10000), gasCost);
		balanceOf[player] = safeSub(balanceOf[player], value);
		playerBalance = safeSub(playerBalance, value);
		assert(edg.transfer(receiver, amount));
		Withdrawal(player, receiver, amount);
	}

	/**
	 * update a casino game address in case of a new contract or a new casino game
	 * @param game       the index of the game 
	 *        newAddress the new address of the game
	 **/
	function setGameAddress(uint8 game, address newAddress) public onlyOwner {
		if (game < casinoGames.length) casinoGames[game] = newAddress;
		else casinoGames.push(newAddress);
	}

	/**
	 * authorize a address to call game functions.
	 * @param addr the address to be authorized
	 **/
	function authorize(address addr) public onlyOwner {
		authorized[addr] = true;
	}

	/**
	 * deauthorize a address to call game functions.
	 * @param addr the address to be deauthorized
	 **/
	function deauthorize(address addr) public onlyOwner {
		authorized[addr] = false;
	}

	/**
	 * updates the price per 1000 gas in EDG.
	 * @param price the new gas price (4 decimals, max 0.0256 EDG)
	 **/
	function setGasPrice(uint8 price) public onlyOwner {
		gasPrice = price;
	}

	/**
	 * Forwards a move to the corresponding game contract if the data has been signed by the client.
	 * The casino contract ensures it is no duplicate move.
	 * @param game  specifies which game contract to call
	 *        value the value to send to the contract in tokens with 4 decimals
	 *        data  the function call
	 *        v,r,s the player&#39;s signature of the data
	 **/
	function move(uint8 game, uint value, bytes data, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized isAlive {
		require(game < casinoGames.length);
		require(safeMul(bankroll(), 10000) > value * 8); //make sure, the casino can always pay out the player
		var player = ecrecover(keccak256(data), v, r, s);
		require(withdrawAfter[player] == 0 || now < withdrawAfter[player]);
		value = safeAdd(value, msg.gas / 1000 * gasPrice);
		balanceOf[player] = safeSub(balanceOf[player], value);
		playerBalance = safeSub(playerBalance, value);
		assert(casinoGames[game].call(data));
	}


}