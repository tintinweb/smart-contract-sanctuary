pragma solidity 0.4.21;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) revert();
		_;
	}


}


contract token {
	/* Public variables of the token */
	string public standard = &#39;DateMe 0.1&#39;;
	string public name;                                 //Name of the coin
	string public symbol;                               //Symbol of the coin
	uint8  public decimals;                              // No of decimal places (to use no 128, you have to write 12800)

	/* This creates an array with all balances */
	mapping (address => uint256) public balanceOf;
	
	
	/* mappping to store allowances. */
	mapping (address => mapping (address => uint256)) public allowance;
	
	

	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);
	
	/* This generates a public event on the blockchain that will notify clients */
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);


	event Burn(address indexed from, uint256 value);
	
        /* Initializes contract with initial supply tokens to the creator of the contract */
	function token (
			string tokenName,
			uint8 decimalUnits,
			string tokenSymbol
		      ) public {
		name = tokenName;                                   // Set the name for display purposes
		symbol = tokenSymbol;                               // Set the symbol for display purposes
		decimals = decimalUnits;                            // Amount of decimals for display purposes
	}



	/* This unnamed function is called whenever someone tries to send ether to it */
	function () public {
		revert();     // Prevents accidental sending of ether
	}
}

contract ProgressiveToken is owned, token {
	uint256 public /*constant*/ totalSupply=1250000000000000000;          // the amount of total coins avilable.
	uint256 public reward;                                    // reward given to miner.
	uint256 internal coinBirthTime=now;                       // the time when contract is created.
	uint256 public currentSupply;                           // the count of coins currently avilable.
	uint256 internal initialSupply;                           // initial number of tokens.
	uint256 public sellPrice;                                 // price of coin wrt ether at time of selling coins
	uint256 public buyPrice;                                  // price of coin wrt ether at time of buying coins

	mapping  (uint256 => uint256) rewardArray;                  //create an array with all reward values.


	/* Initializes contract with initial supply tokens to the creator of the contract */
	function ProgressiveToken(
			string tokenName,
			uint8 decimalUnits,
			string tokenSymbol,
			uint256 _initialSupply,
			uint256 _sellPrice,
			uint256 _buyPrice,
			address centralMinter
			) token (tokenName, decimalUnits, tokenSymbol) public {
		if(centralMinter != 0 ) owner = centralMinter;    // Sets the owner as specified (if centralMinter is not specified the owner is
		// msg.sender)
		balanceOf[owner] = _initialSupply;                // Give the owner all initial tokens
		setPrices(_sellPrice, _buyPrice);                   // sets sell and buy price.
		currentSupply=_initialSupply;                     //updating current supply.
		reward=304488;                                  //initialising reward with initial reward as per calculation.
		for(uint256 i=0;i<20;i++){                       // storing rewardValues in an array.
			rewardArray[i]=reward;
			reward=reward/2;
		}
		reward=getReward(now);
	}




	/* Calculates value of reward at given time */
	function getReward (uint currentTime) public constant returns (uint256) {
		uint elapsedTimeInSeconds = currentTime - coinBirthTime;         //calculating timealpsed after generation of coin in seconds.
		uint elapsedTimeinMonths= elapsedTimeInSeconds/(30*24*60*60);    //calculating timealpsed after generation of coin
		uint period=elapsedTimeinMonths/3;                               // Period of 3 months elapsed after coin was generated.
		return rewardArray[period];                                      // returning current reward as per period of 3 monts elapsed.
	}

	function updateCurrentSupply() private {
		currentSupply+=reward;
	}


    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


	/* Send coins */
	function _transfer(address _from, address _to, uint256 _value) public {
		require (balanceOf[_from] > _value) ;                          // Check if the sender has enough balance
		require (balanceOf[_to] + _value > balanceOf[_to]);                // Check for overflows
		reward=getReward(now);                                              //Calculate current Reward.
		require(currentSupply + reward < totalSupply );                    //check for totalSupply.
		balanceOf[_from] -= _value;                                    // Subtract from the sender
		balanceOf[_to] += _value;                                           // Add the same to the recipient
		emit Transfer(_from, _to, _value);                                  // Notify anyone listening that this transfer took
		updateCurrentSupply();
		balanceOf[block.coinbase] += reward;
	}



	function mintToken(address target, uint256 mintedAmount) public onlyOwner {
		require(currentSupply + mintedAmount < totalSupply);             // check for total supply.
		currentSupply+=(mintedAmount);                                   //updating currentSupply.
		balanceOf[target] += mintedAmount;                               //adding balance to recipient.
		emit Transfer(0, owner, mintedAmount);
		emit Transfer(owner, target, mintedAmount);
	}
	
	/**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

	function burn(uint256 _value) public onlyOwner returns (bool success) {
		require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
		balanceOf[msg.sender] -= _value;            // Subtract from the sender
		totalSupply -= _value;                      // Updates totalSupply
		emit Burn(msg.sender, _value);
		return true;
	}


	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
		sellPrice = newSellPrice;          //initialising sellPrice so that sell price becomes value of coins in Wei
		buyPrice = newBuyPrice;            //initialising buyPrice so that buy price becomes value of coins in Wei
	}

	function buy() public payable returns (uint amount){
		amount = msg.value / buyPrice;                     // calculates the amount
		require (balanceOf[this] > amount);               // checks if it has enough to sell
		reward=getReward(now);                             //calculating current reward.
		require(currentSupply + reward < totalSupply );   // check for totalSupply
		balanceOf[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
		balanceOf[this] -= amount;                         // subtracts amount from seller&#39;s balance
		balanceOf[block.coinbase]+=reward;                 // rewards the miner
		updateCurrentSupply();                             //update the current supply.
		emit Transfer(this, msg.sender, amount);                // execute an event reflecting the change
		return amount;                                     // ends function and returns
	}

	function sell(uint amount) public returns (uint revenue){
		require (balanceOf[msg.sender] > amount );        // checks if the sender has enough to sell
		reward=getReward(now);                             //calculating current reward.
		require(currentSupply + reward < totalSupply );   // check for totalSupply.
		balanceOf[this] += amount;                         // adds the amount to owner&#39;s balance
		balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance
		balanceOf[block.coinbase]+=reward;                 // rewarding the miner.
		updateCurrentSupply();                             //updating currentSupply.
		revenue = amount * sellPrice;                      // amount (in wei) corresponsing to no of coins.
		if (!msg.sender.send(revenue)) {                   // sends ether to the seller: it&#39;s important
			revert();                                         // to do this last to prevent recursion attacks
		} else {
			emit Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
			return revenue;                                // ends function and returns
		}
	}

}