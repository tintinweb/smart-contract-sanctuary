pragma solidity ^0.4.10;

/**
 * @title Interface to communicate with ICO token contract
 */
contract IToken {
  function balanceOf(address _address) constant returns (uint balance);
  function transferFromOwner(address _to, uint256 _value) returns (bool success);
}

/**
 * @title Presale token contract
 */
contract TokenEscrow {
	// Token-related properties/description to display in Wallet client / UI
	string public standard = &#39;PBKXToken 0.3&#39;;
	string public name = &#39;PBKXToken&#39;;
	string public symbol = &#39;PBKX&#39;;
	uint public decimals = 2;
    	uint public totalSupply = 300000000;
	
	IToken icoToken;
	
	event Converted(address indexed from, uint256 value); // Event to inform about the fact of token burning/destroying
    	event Transfer(address indexed from, address indexed to, uint256 value);
	event Error(bytes32 error);
	
	mapping (address => uint) balanceFor; // Presale token balance for each of holders
	
	address owner;  // Contract owner
	
	uint public exchangeRate; // preICO -> ICO token exchange rate

	// Token supply and discount policy structure
	struct TokenSupply {
		uint limit;                 // Total amount of tokens
		uint totalSupply;           // Current amount of sold tokens
		uint tokenPriceInWei;  // Number of token per 1 Eth
	}
	
	TokenSupply[3] public tokenSupplies;

	// Modifiers
	modifier owneronly { if (msg.sender == owner) _; }

	/**
	 * @dev Set/change contract owner
	 * @param _owner owner address
	 */
	function setOwner(address _owner) owneronly {
		owner = _owner;
	}
	
	function setRate(uint _exchangeRate) owneronly {
		exchangeRate = _exchangeRate;
	}
	
	function setToken(address _icoToken) owneronly {
		icoToken = IToken(_icoToken);
	}
	
	/**
	 * @dev Returns balance/token quanity owned by address
	 * @param _address Account address to get balance for
	 * @return balance value / token quantity
	 */
	function balanceOf(address _address) constant returns (uint balance) {
		return balanceFor[_address];
	}
	
	/**
	 * @dev Transfers tokens from caller/method invoker/message sender to specified recipient
	 * @param _to Recipient address
	 * @param _value Token quantity to transfer
	 * @return success/failure of transfer
	 */	
	function transfer(address _to, uint _value) returns (bool success) {
		if(_to != owner) {
			if (balanceFor[msg.sender] < _value) return false;           // Check if the sender has enough
			if (balanceFor[_to] + _value < balanceFor[_to]) return false; // Check for overflows
			if (msg.sender == owner) {
				transferByOwner(_value);
			}
			balanceFor[msg.sender] -= _value;                     // Subtract from the sender
			balanceFor[_to] += _value;                            // Add the same to the recipient
			Transfer(owner,_to,_value);
			return true;
		}
		return false;
	}
	
	function transferByOwner(uint _value) private {
		for (uint discountIndex = 0; discountIndex < tokenSupplies.length; discountIndex++) {
			TokenSupply storage tokenSupply = tokenSupplies[discountIndex];
			if(tokenSupply.totalSupply < tokenSupply.limit) {
				if (tokenSupply.totalSupply + _value > tokenSupply.limit) {
					_value -= tokenSupply.limit - tokenSupply.totalSupply;
					tokenSupply.totalSupply = tokenSupply.limit;
				} else {
					tokenSupply.totalSupply += _value;
					break;
				}
			}
		}
	}
	
	/**
	 * @dev Burns/destroys specified amount of Presale tokens for caller/method invoker/message sender
	 * @return success/failure of transfer
	 */	
	function convert() returns (bool success) {
		if (balanceFor[msg.sender] == 0) return false;            // Check if the sender has enough
		if (!exchangeToIco(msg.sender)) return false; // Try to exchange preICO tokens to ICO tokens
		Converted(msg.sender, balanceFor[msg.sender]);
		balanceFor[msg.sender] = 0;                      // Subtract from the sender
		return true;
	} 
	
	/**
	 * @dev Converts/exchanges sold Presale tokens to ICO ones according to provided exchange rate
	 * @param owner address
		 */
	function exchangeToIco(address owner) private returns (bool) {
	    if(icoToken != address(0)) {
		    return icoToken.transferFromOwner(owner, balanceFor[owner] * exchangeRate);
	    }
	    return false;
	}

	/**
	 * @dev Presale contract constructor
	 */
	function TokenEscrow() {
		owner = msg.sender;
		
		balanceFor[msg.sender] = 300000000; // Give the creator all initial tokens
		
		// Discount policy
		tokenSupplies[0] = TokenSupply(100000000, 0, 11428571428571); // First million of tokens will go 11210762331838 wei for 1 token
		tokenSupplies[1] = TokenSupply(100000000, 0, 11848341232227); // Second million of tokens will go 12106537530266 wei for 1 token
		tokenSupplies[2] = TokenSupply(100000000, 0, 12500000000000); // Third million of tokens will go 13245033112582 wei for 1 token
	
		//Balances recovery
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,875);
		transferByOwner(875);
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,2150);
		transferByOwner(2150);
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,975);
		transferByOwner(975);
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,875000);
		transferByOwner(875000);
		transferFromOwner(0xa4a90f8d12ae235812a4770e0da76f5bc2fdb229,3500000);
		transferByOwner(3500000);
		transferFromOwner(0xbd08c225306f6b341ce5a896392e0f428b31799c,43750);
		transferByOwner(43750);
		transferFromOwner(0xf948fc5be2d2fd8a7ee20154a18fae145afd6905,3316981);
		transferByOwner(3316981);
		transferFromOwner(0x23f15982c111362125319fd4f35ac9e1ed2de9d6,2625);
		transferByOwner(2625);
		transferFromOwner(0x23f15982c111362125319fd4f35ac9e1ed2de9d6,5250);
		transferByOwner(5250);
		transferFromOwner(0x6ebff66a68655d88733df61b8e35fbcbd670018e,58625);
		transferByOwner(58625);
		transferFromOwner(0x1aaa29dffffc8ce0f0eb42031f466dbc3c5155ce,1043875);
		transferByOwner(1043875);
		transferFromOwner(0x5d47871df00083000811a4214c38d7609e8b1121,3300000);
		transferByOwner(3300000);
		transferFromOwner(0x30ced0c61ccecdd17246840e0d0acb342b9bd2e6,261070);
		transferByOwner(261070);
		transferFromOwner(0x1079827daefe609dc7721023f811b7bb86e365a8,2051875);
		transferByOwner(2051875);
		transferFromOwner(0x6c0b6a5ac81e07f89238da658a9f0e61be6a0076,10500000);
		transferByOwner(10500000);
		transferFromOwner(0xd16e29637a29d20d9e21b146fcfc40aca47656e5,1750);
		transferByOwner(1750);
		transferFromOwner(0x4c9ba33dcbb5876e1a83d60114f42c949da4ee22,7787500);
		transferByOwner(7787500);
		transferFromOwner(0x0d8cc80efe5b136865b9788393d828fd7ffb5887,100000000);
		transferByOwner(100000000);
	
	}
  
	// Incoming transfer from the Presale token buyer
	function() payable {
		
		uint tokenAmount; // Amount of tokens which is possible to buy for incoming transfer/payment
		uint amountToBePaid; // Amount to be paid
		uint amountTransfered = msg.value; // Cost/price in WEI of incoming transfer/payment
		
		if (amountTransfered <= 0) {
		      	Error(&#39;no eth was transfered&#39;);
              		msg.sender.transfer(msg.value);
		  	return;
		}

		if(balanceFor[owner] <= 0) {
		      	Error(&#39;all tokens sold&#39;);
              		msg.sender.transfer(msg.value);
		      	return;
		}
		
		// Determine amount of tokens can be bought according to available supply and discount policy
		for (uint discountIndex = 0; discountIndex < tokenSupplies.length; discountIndex++) {
			// If it&#39;s not possible to buy any tokens at all skip the rest of discount policy
			
			TokenSupply storage tokenSupply = tokenSupplies[discountIndex];
			
			if(tokenSupply.totalSupply < tokenSupply.limit) {
			
				uint tokensPossibleToBuy = amountTransfered / tokenSupply.tokenPriceInWei;

                if (tokensPossibleToBuy > balanceFor[owner]) 
                    tokensPossibleToBuy = balanceFor[owner];

				if (tokenSupply.totalSupply + tokensPossibleToBuy > tokenSupply.limit) {
					tokensPossibleToBuy = tokenSupply.limit - tokenSupply.totalSupply;
				}

				tokenSupply.totalSupply += tokensPossibleToBuy;
				tokenAmount += tokensPossibleToBuy;

				uint delta = tokensPossibleToBuy * tokenSupply.tokenPriceInWei;

				amountToBePaid += delta;
                		amountTransfered -= delta;
			
			}
		}
		
		// Do not waste gas if there is no tokens to buy
		if (tokenAmount == 0) {
		    	Error(&#39;no token to buy&#39;);
            		msg.sender.transfer(msg.value);
			return;
        	}
		
		// Transfer tokens to buyer
		transferFromOwner(msg.sender, tokenAmount);

		// Transfer money to seller
		owner.transfer(amountToBePaid);
		
		// Refund buyer if overpaid / no tokens to sell
		msg.sender.transfer(msg.value - amountToBePaid);
	}
  
	/**
	 * @dev Removes/deletes contract
	 */
	function kill() owneronly {
		suicide(msg.sender);
	}
  
	/**
	 * @dev Transfers tokens from owner to specified recipient
	 * @param _to Recipient address
	 * @param _value Token quantity to transfer
	 * @return success/failure of transfer
	 */
	function transferFromOwner(address _to, uint256 _value) private returns (bool success) {
		if (balanceFor[owner] < _value) return false;                 // Check if the owner has enough
		if (balanceFor[_to] + _value < balanceFor[_to]) return false;  // Check for overflows
		balanceFor[owner] -= _value;                          // Subtract from the owner
		balanceFor[_to] += _value;                            // Add the same to the recipient
        	Transfer(owner,_to,_value);
		return true;
	}
  
}