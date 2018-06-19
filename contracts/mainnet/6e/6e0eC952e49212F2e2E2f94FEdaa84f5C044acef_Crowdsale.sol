pragma solidity ^0.4.2;
contract owned {
	address public owner;
	function owned() {
		owner = msg.sender;
	}
	function changeOwner(address newOwner) onlyowner {
		owner = newOwner;
	}
	modifier onlyowner() {
		if (msg.sender==owner) _;
	}
}
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract CSToken is owned {
	/* Public variables of the token */
	string public standard = &#39;Token 0.1&#39;;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	/* This creates an array with all balances */
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;
	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);
	/* Initializes contract with initial supply tokens to the creator of the contract */
	function CSToken(
	uint256 initialSupply,
	string tokenName,
	uint8 decimalUnits,
	string tokenSymbol
	) {
		owner = msg.sender;
		balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
		totalSupply = initialSupply;                        // Update total supply
		name = tokenName;                                   // Set the name for display purposes
		symbol = tokenSymbol;                               // Set the symbol for display purposes
		decimals = decimalUnits;                            // Amount of decimals for display purposes
	}
	/* Send coins */
	function transfer(address _to, uint256 _value) {
		if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		balanceOf[msg.sender] -= _value;                     // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
	}
	function mintToken(address target, uint256 mintedAmount) onlyowner {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, owner, mintedAmount);
		Transfer(owner, target, mintedAmount);
	}
	/* Allow another contract to spend some tokens in your behalf */
	function approve(address _spender, uint256 _value)
	returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}
	/* Approve and then comunicate the approved contract in a single tx */
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}
	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
		if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
		balanceOf[_from] -= _value;                          // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}
	/* This unnamed function is called whenever someone tries to send ether to it */
	function () {
		throw;     // Prevents accidental sending of ether
	}
}
contract Crowdsale is owned{
        uint public start = 1498651200;
        uint public currentStage = 0;
        bool public crowdsaleStarted = false;
        uint[] public prices;
        uint[] public tresholds;
        address public bounties;
        uint public totalCollected;
        uint public deadline;
        uint public presaleDeadline;
        uint public tokensRaised;
    
        uint constant presaleDuration = 19 days;
        uint constant saleDuration = 29 days;
        uint tokenMultiplier = 10;
    
    
        CSToken public tokenReward;
        mapping(address => uint256) public balanceOf;
        event GoalReached(address beneficiary, uint totalCollected);
        event FundTransfer(address backer, uint amount, bool isContribution);
        event NewStage (uint time, uint stage);
    
    
        modifier saleFinished() { if (now < deadline && currentStage < 2) throw; _; }
        modifier beforeDeadline() { if (now >= deadline) throw; _; }

	function Crowdsale(
	address _bounties
	) {
		tokenReward = new CSToken(0, &#39;MyBit Token&#39;, 8, &#39;MyB&#39;);
		tokenMultiplier = tokenMultiplier**tokenReward.decimals();
		tokenReward.mintToken(_bounties, 1100000 * tokenMultiplier);
		presaleDeadline = start + presaleDuration;
		deadline = start + presaleDuration + saleDuration;
		tresholds.push(1250000 * tokenMultiplier);
		tresholds.push(3000000 * tokenMultiplier);
		tresholds.push(2**256 - 1);
		prices.push(7500 szabo / tokenMultiplier);
		prices.push(10 finney / tokenMultiplier);
		prices.push(2**256 - 1);


		bounties = _bounties;

	}

    
	function mint(uint amount, uint tokens, address sender) internal {
		balanceOf[sender] += amount;
		tokensRaised += tokens;
		totalCollected += amount;
		tokenReward.mintToken(sender, tokens);
		tokenReward.mintToken(owner, tokens * 1333333 / 10000000);
		tokenReward.mintToken(bounties, tokens * 1666667 / 10000000);
		FundTransfer(sender, amount, true);
	}

	function processPayment(address from, uint amount) internal beforeDeadline
	{
		FundTransfer(from, amount, false);
		uint price = prices[currentStage];
		uint256 tokenAmount = amount / price;
		if (tokensRaised + tokenAmount > tresholds[currentStage])
		{
			uint256 currentTokens = tresholds[currentStage] - tokensRaised;
			uint256 currentAmount = currentTokens * price;
			mint(currentAmount, currentTokens, from);
			currentStage++;
			NewStage(now, currentStage);
			processPayment(from, amount - currentAmount);
			return;
		}
	        mint(amount, tokenAmount, from);
		uint256 change = amount - tokenAmount * price;
		if(change > 0)
		{
			totalCollected -= change;
			balanceOf[from] -= change;
			if (!from.send(change)){
				throw;
			}
		}
	}

	function () payable beforeDeadline {
		if(now < start) throw;
		if(currentStage > 1) throw;
		if (crowdsaleStarted){
			processPayment(msg.sender, msg.value);
		} else {
			if (now > presaleDeadline)
			{
				crowdsaleStarted = true;
			} else {
				if (msg.value < 1 ether) throw;
			}
			processPayment(msg.sender, msg.value);    
        }
    }

    function safeWithdrawal() saleFinished {
        if (bounties == msg.sender) {
            if (!bounties.send(totalCollected)) {
                throw;
            }
        }
    }
}