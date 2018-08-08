pragma solidity ^0.4.11;

//------------------------------------------------------------------------------------------------
// LICENSE
//
// This file is part of BattleDrome.
// 
// BattleDrome is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// BattleDrome is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with BattleDrome.  If not, see <http://www.gnu.org/licenses/>.
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
// ERC20 Standard Token Implementation, based on ERC Standard:
// https://github.com/ethereum/EIPs/issues/20
// With some inspiration from ConsenSys HumanStandardToken as well
// Copyright 2017 BattleDrome
//------------------------------------------------------------------------------------------------

contract ERC20Standard {
	uint public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;

	//Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

	function balanceOf(address _owner) constant returns (uint balance) {
		return balances[_owner];
	}

	function transfer(address _recipient, uint _value) onlyPayloadSize(2*32) {
		require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] -= _value;
	    balances[_recipient] += _value;
	    Transfer(msg.sender, _recipient, _value);        
    }

	function transferFrom(address _from, address _to, uint _value) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

	function approve(address _spender, uint _value) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) constant returns (uint balance) {
		return allowed[_owner][_spender];
	}

	//Event which is triggered to log all transfers to this contract&#39;s event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);

}

//------------------------------------------------------------------------------------------------
// FAME ERC20 Token, based on ERC20Standard interface
// Copyright 2017 BattleDrome
//------------------------------------------------------------------------------------------------

contract FAMEToken is ERC20Standard {

	function FAMEToken() {
		totalSupply = 2100000 szabo;			//Total Supply (including all decimal places!)
		name = "Fame";							//Pretty Name
		decimals = 12;							//Decimal places (with 12 decimal places 1 szabo = 1 token in uint256)
		symbol = "FAM";							//Ticker Symbol (3 characters, upper case)
		version = "FAME1.0";					//Version Code
		balances[msg.sender] = totalSupply;		//Assign all balance to creator initially for distribution from there.
	}

	//Burn _value of tokens from your balance.
	//Will destroy the tokens, removing them from your balance, and reduce totalSupply accordingly.
	function burn(uint _value) {
		require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
	}

	//Event to log any time someone burns tokens to the contract&#39;s event log:
	event Burn(
		address indexed _owner,
		uint _value
		);

}

//------------------------------------------------------------------------------------------------
// ICO Crowd Sale Contract
// Works like a kickstarter. Minimum goal required, or everyone gets their money back
// Contract holds all tokens, upon success (passing goal on time) sends out all bought tokens
// It then burns the rest.
// In the event of failure, it sends tokens back to creator, and all payments back to senders.
// Each time tokens are bought, a percentage is also issued to the "Developer" account.
// Pay-out of collected Ether to creators is managed through an Escrow address.
// Copyright 2017 BattleDrome
//------------------------------------------------------------------------------------------------

contract BattleDromeICO {
	uint public constant ratio = 100 szabo;				//Ratio of how many tokens (in absolute uint256 form) are issued per ETH
	uint public constant minimumPurchase = 1 finney;	//Minimum purchase size (of incoming ETH)
	uint public constant startBlock = 3960000;			//Starting Block Number of Crowsd Sale
	uint public constant duration = 190000;				//16s block times 190k is about 35 days, from July 1st, to approx first Friday of August.
	uint public constant fundingGoal = 500 ether;		//Minimum Goal in Ether Raised
	uint public constant fundingMax = 20000 ether;		//Maximum Funds in Ether that we will accept before stopping the crowdsale
	uint public constant devRatio = 20;					//Ratio of Sold Tokens to Dev Tokens (ie 20 = 20:1 or 5%)
	address public constant tokenAddress 	= 0x190e569bE071F40c704e15825F285481CB74B6cC;	//Address of ERC20 Token Contract
	address public constant escrow 			= 0x50115D25322B638A5B8896178F7C107CFfc08144;	//Address of Escrow Provider Wallet

	FAMEToken public Token;
	address public creator;
	uint public savedBalance;
	bool public creatorPaid = false;			//Has the creator been paid? 

	mapping(address => uint) balances;			//Balances in incoming Ether
	mapping(address => uint) savedBalances;		//Saved Balances in incoming Ether (for after withdrawl validation)

	//Constructor, initiate the crowd sale
	function BattleDromeICO() {
		Token = FAMEToken(tokenAddress);				//Establish the Token Contract to handle token transfers					
		creator = msg.sender;							//Establish the Creator address for receiving payout if/when appropriate.
	}

	//Default Function, delegates to contribute function (for ease of use)
	//WARNING: Not compatible with smart contract invocation, will exceed gas stipend!
	//Only use from full wallets.
	function () payable {
		contribute();
	}

	//Contribute Function, accepts incoming payments and tracks balances
	function contribute() payable {
		require(isStarted());								//Has the crowdsale even started yet?
		require(this.balance<=fundingMax); 					//Does this payment send us over the max?
		require(msg.value >= minimumPurchase);              //Require that the incoming amount is at least the minimum purchase size.
		require(!isComplete()); 							//Has the crowdsale completed? We only want to accept payments if we&#39;re still active.
		balances[msg.sender] += msg.value;					//If all checks good, then accept contribution and record new balance.
		savedBalances[msg.sender] += msg.value;		    	//Save contributors balance for later	
		savedBalance += msg.value;							//Save the balance for later when we&#39;re doing pay-outs so we know what it was.
		Contribution(msg.sender,msg.value,now);             //Woohoo! Log the new contribution!
	}

	//Function to view current token balance of the crowdsale contract
	function tokenBalance() constant returns(uint balance) {
		return Token.balanceOf(address(this));
	}

	//Function to check if crowdsale has started yet, have we passed the start block?
	function isStarted() constant returns(bool) {
		return block.number >= startBlock;
	}

	//Function to check if crowdsale is complete (have we eigher hit our max, or passed the crowdsale completion block?)
	function isComplete() constant returns(bool) {
		return (savedBalance >= fundingMax) || (block.number > (startBlock + duration));
	}

	//Function to check if crowdsale has been successful (has incoming contribution balance met, or exceeded the minimum goal?)
	function isSuccessful() constant returns(bool) {
		return (savedBalance >= fundingGoal);
	}

	//Function to check the Ether balance of a contributor
	function checkEthBalance(address _contributor) constant returns(uint balance) {
		return balances[_contributor];
	}

	//Function to check the Saved Ether balance of a contributor
	function checkSavedEthBalance(address _contributor) constant returns(uint balance) {
		return savedBalances[_contributor];
	}

	//Function to check the Token balance of a contributor
	function checkTokBalance(address _contributor) constant returns(uint balance) {
		return (balances[_contributor] * ratio) / 1 ether;
	}

	//Function to check the current Tokens Sold in the ICO
	function checkTokSold() constant returns(uint total) {
		return (savedBalance * ratio) / 1 ether;
	}

	//Function to get Dev Tokens issued during ICO
	function checkTokDev() constant returns(uint total) {
		return checkTokSold() / devRatio;
	}

	//Function to get Total Tokens Issued during ICO (Dev + Sold)
	function checkTokTotal() constant returns(uint total) {
		return checkTokSold() + checkTokDev();
	}

	//function to check percentage of goal achieved
	function percentOfGoal() constant returns(uint16 goalPercent) {
		return uint16((savedBalance*100)/fundingGoal);
	}

	//function to initiate payout of either Tokens or Ether payback.
	function payMe() {
		require(isComplete()); //No matter what must be complete
		if(isSuccessful()) {
			payTokens();
		}else{
			payBack();
		}
	}

	//Function to pay back Ether
	function payBack() internal {
		require(balances[msg.sender]>0);						//Does the requester have a balance?
		balances[msg.sender] = 0;								//Ok, zero balance first to avoid re-entrance
		msg.sender.transfer(savedBalances[msg.sender]);			//Send them their saved balance
		PayEther(msg.sender,savedBalances[msg.sender],now); 	//Log payback of ether
	}

	//Function to pay out Tokens
	function payTokens() internal {
		require(balances[msg.sender]>0);					//Does the requester have a balance?
		uint tokenAmount = checkTokBalance(msg.sender);		//If so, then let&#39;s calculate how many Tokens we owe them
		balances[msg.sender] = 0;							//Zero their balance ahead of transfer to avoid re-entrance (even though re-entrance here should be zero risk)
		Token.transfer(msg.sender,tokenAmount);				//And transfer the tokens to them
		PayTokens(msg.sender,tokenAmount,now);          	//Log payout of tokens to contributor
	}

	//Function to pay the creator upon success
	function payCreator() {
		require(isComplete());										//Creator can only request payout once ICO is complete
		require(!creatorPaid);										//Require that the creator hasn&#39;t already been paid
		creatorPaid = true;											//Set flag to show creator has been paid.
		if(isSuccessful()){
			uint tokensToBurn = tokenBalance() - checkTokTotal();	//How many left-over tokens after sold, and dev tokens are accounted for? (calculated before we muck with balance)
			PayEther(escrow,this.balance,now);      				//Log the payout to escrow
			escrow.transfer(this.balance);							//We were successful, so transfer the balance to the escrow address
			PayTokens(creator,checkTokDev(),now);       			//Log payout of tokens to creator
			Token.transfer(creator,checkTokDev());					//And since successful, send DevRatio tokens to devs directly			
			Token.burn(tokensToBurn);								//Burn any excess tokens;
			BurnTokens(tokensToBurn,now);        					//Log the burning of the tokens.
		}else{
			PayTokens(creator,tokenBalance(),now);       			//Log payout of tokens to creator
			Token.transfer(creator,tokenBalance());					//We were not successful, so send ALL tokens back to creator.
		}
	}
	
	//Event to record new contributions
	event Contribution(
	    address indexed _contributor,
	    uint indexed _value,
	    uint indexed _timestamp
	    );
	    
	//Event to record each time tokens are paid out
	event PayTokens(
	    address indexed _receiver,
	    uint indexed _value,
	    uint indexed _timestamp
	    );

	//Event to record each time Ether is paid out
	event PayEther(
	    address indexed _receiver,
	    uint indexed _value,
	    uint indexed _timestamp
	    );
	    
	//Event to record when tokens are burned.
	event BurnTokens(
	    uint indexed _value,
	    uint indexed _timestamp
	    );

}