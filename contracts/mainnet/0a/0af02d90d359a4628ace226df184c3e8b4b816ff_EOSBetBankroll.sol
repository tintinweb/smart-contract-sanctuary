// WELCOME TO THE EOSBET.IO BUG BOUNTY CONTRACTS!
// GOOD LUCK... YOU&#39;LL NEED IT!

pragma solidity ^0.4.21;

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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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

contract EOSBetGameInterface {
	uint256 public DEVELOPERSFUND;
	uint256 public LIABILITIES;
	function payDevelopersFund(address developer) public;
	function receivePaymentForOraclize() payable public;
	function getMaxWin() public view returns(uint256);
}

contract EOSBetBankrollInterface {
	function payEtherToWinner(uint256 amtEther, address winner) public;
	function receiveEtherFromGameAddress() payable public;
	function payOraclize(uint256 amountToPay) public;
	function getBankroll() public view returns(uint256);
}

contract ERC20 {
	function totalSupply() constant public returns (uint supply);
	function balanceOf(address _owner) constant public returns (uint balance);
	function transfer(address _to, uint _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	function approve(address _spender, uint _value) public returns (bool success);
	function allowance(address _owner, address _spender) constant public returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract EOSBetBankroll is ERC20, EOSBetBankrollInterface {

	using SafeMath for *;

	// constants for EOSBet Bankroll

	address public OWNER;
	uint256 public MAXIMUMINVESTMENTSALLOWED;
	uint256 public WAITTIMEUNTILWITHDRAWORTRANSFER;
	uint256 public DEVELOPERSFUND;

	// this will be initialized as the trusted game addresses which will forward their ether
	// to the bankroll contract, and when players win, they will request the bankroll contract 
	// to send these players their winnings.
	// Feel free to audit these contracts on etherscan...
	mapping(address => bool) public TRUSTEDADDRESSES;

	address public DICE;
	address public SLOTS;

	// mapping to log the last time a user contributed to the bankroll 
	mapping(address => uint256) contributionTime;

	// constants for ERC20 standard
	string public constant name = "EOSBet Stake Tokens";
	string public constant symbol = "EOSBETST";
	uint8 public constant decimals = 18;
	// variable total supply
	uint256 public totalSupply;

	// mapping to store tokens
	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) public allowed;

	// events
	event FundBankroll(address contributor, uint256 etherContributed, uint256 tokensReceived);
	event CashOut(address contributor, uint256 etherWithdrawn, uint256 tokensCashedIn);
	event FailedSend(address sendTo, uint256 amt);

	// checks that an address is a "trusted address of a legitimate EOSBet game"
	modifier addressInTrustedAddresses(address thisAddress){

		require(TRUSTEDADDRESSES[thisAddress]);
		_;
	}

	// initialization function 
	function EOSBetBankroll(address dice, address slots) public payable {
		// function is payable, owner of contract MUST "seed" contract with some ether, 
		// so that the ratios are correct when tokens are being minted
		require (msg.value > 0);

		OWNER = msg.sender;

		// 100 tokens/ether is the inital seed amount, so:
		uint256 initialTokens = msg.value * 100;
		balances[msg.sender] = initialTokens;
		totalSupply = initialTokens;

		// log a mint tokens event
		emit Transfer(0x0, msg.sender, initialTokens);

		// insert given game addresses into the TRUSTEDADDRESSES mapping, and save the addresses as global variables
		TRUSTEDADDRESSES[dice] = true;
		TRUSTEDADDRESSES[slots] = true;

		DICE = dice;
		SLOTS = slots;

		////////////////////////////////////////////////
		// CHANGE TO 6 HOURS ON LIVE DEPLOYMENT
		////////////////////////////////////////////////
		WAITTIMEUNTILWITHDRAWORTRANSFER = 0 seconds;
		MAXIMUMINVESTMENTSALLOWED = 500 ether;
	}

	///////////////////////////////////////////////
	// VIEW FUNCTIONS
	/////////////////////////////////////////////// 

	function checkWhenContributorCanTransferOrWithdraw(address bankrollerAddress) view public returns(uint256){
		return contributionTime[bankrollerAddress];
	}

	function getBankroll() view public returns(uint256){
		// returns the total balance minus the developers fund, as the amount of active bankroll
		return SafeMath.sub(address(this).balance, DEVELOPERSFUND);
	}

	///////////////////////////////////////////////
	// BANKROLL CONTRACT <-> GAME CONTRACTS functions
	/////////////////////////////////////////////// 

	function payEtherToWinner(uint256 amtEther, address winner) public addressInTrustedAddresses(msg.sender){
		// this function will get called by a game contract when someone wins a game
		// try to send, if it fails, then send the amount to the owner
		// note, this will only happen if someone is calling the betting functions with
		// a contract. They are clearly up to no good, so they can contact us to retreive 
		// their ether
		// if the ether cannot be sent to us, the OWNER, that means we are up to no good, 
		// and the ether will just be given to the bankrollers as if the player/owner lost 

		if (! winner.send(amtEther)){

			emit FailedSend(winner, amtEther);

			if (! OWNER.send(amtEther)){

				emit FailedSend(OWNER, amtEther);
			}
		}
	}

	function receiveEtherFromGameAddress() payable public addressInTrustedAddresses(msg.sender){
		// this function will get called from the game contracts when someone starts a game.
	}

	function payOraclize(uint256 amountToPay) public addressInTrustedAddresses(msg.sender){
		// this function will get called when a game contract must pay payOraclize
		EOSBetGameInterface(msg.sender).receivePaymentForOraclize.value(amountToPay)();
	}

	///////////////////////////////////////////////
	// BANKROLL CONTRACT MAIN FUNCTIONS
	///////////////////////////////////////////////


	// this function ADDS to the bankroll of EOSBet, and credits the bankroller a proportional
	// amount of tokens so they may withdraw their tokens later
	// also if there is only a limited amount of space left in the bankroll, a user can just send as much 
	// ether as they want, because they will be able to contribute up to the maximum, and then get refunded the rest.
	function () public payable {

		// save in memory for cheap access.
		// this represents the total bankroll balance before the function was called.
		uint256 currentTotalBankroll = SafeMath.sub(getBankroll(), msg.value);
		uint256 maxInvestmentsAllowed = MAXIMUMINVESTMENTSALLOWED;

		require(currentTotalBankroll < maxInvestmentsAllowed && msg.value != 0);

		uint256 currentSupplyOfTokens = totalSupply;
		uint256 contributedEther;

		bool contributionTakesBankrollOverLimit;
		uint256 ifContributionTakesBankrollOverLimit_Refund;

		uint256 creditedTokens;

		if (SafeMath.add(currentTotalBankroll, msg.value) > maxInvestmentsAllowed){
			// allow the bankroller to contribute up to the allowed amount of ether, and refund the rest.
			contributionTakesBankrollOverLimit = true;
			// set contributed ether as (MAXIMUMINVESTMENTSALLOWED - BANKROLL)
			contributedEther = SafeMath.sub(maxInvestmentsAllowed, currentTotalBankroll);
			// refund the rest of the ether, which is (original amount sent - (maximum amount allowed - bankroll))
			ifContributionTakesBankrollOverLimit_Refund = SafeMath.sub(msg.value, contributedEther);
		}
		else {
			contributedEther = msg.value;
		}
        
		if (currentSupplyOfTokens != 0){
			// determine the ratio of contribution versus total BANKROLL.
			creditedTokens = SafeMath.mul(contributedEther, currentSupplyOfTokens) / currentTotalBankroll;
		}
		else {
			// edge case where ALL money was cashed out from bankroll
			// so currentSupplyOfTokens == 0
			// currentTotalBankroll can == 0 or not, if someone mines/selfdestruct&#39;s to the contract
			// but either way, give all the bankroll to person who deposits ether
			creditedTokens = SafeMath.mul(contributedEther, 100);
		}
		
		// now update the total supply of tokens and bankroll amount
		totalSupply = SafeMath.add(currentSupplyOfTokens, creditedTokens);

		// now credit the user with his amount of contributed tokens 
		balances[msg.sender] = SafeMath.add(balances[msg.sender], creditedTokens);

		// update his contribution time for stake time locking
		contributionTime[msg.sender] = block.timestamp;

		// now look if the attempted contribution would have taken the BANKROLL over the limit, 
		// and if true, refund the excess ether.
		if (contributionTakesBankrollOverLimit){
			msg.sender.transfer(ifContributionTakesBankrollOverLimit_Refund);
		}

		// log an event about funding bankroll
		emit FundBankroll(msg.sender, contributedEther, creditedTokens);

		// log a mint tokens event
		emit Transfer(0x0, msg.sender, creditedTokens);
	}

	function cashoutEOSBetStakeTokens(uint256 _amountTokens) public {
		// In effect, this function is the OPPOSITE of the un-named payable function above^^^
		// this allows bankrollers to "cash out" at any time, and receive the ether that they contributed, PLUS
		// a proportion of any ether that was earned by the smart contact when their ether was "staking", However
		// this works in reverse as well. Any net losses of the smart contract will be absorbed by the player in like manner.
		// Of course, due to the constant house edge, a bankroller that leaves their ether in the contract long enough
		// is effectively guaranteed to withdraw more ether than they originally "staked"

		// save in memory for cheap access.
		uint256 tokenBalance = balances[msg.sender];
		// verify that the contributor has enough tokens to cash out this many, and has waited the required time.
		require(_amountTokens <= tokenBalance 
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
			&& _amountTokens > 0);

		// save in memory for cheap access.
		// again, represents the total balance of the contract before the function was called.
		uint256 currentTotalBankroll = getBankroll();
		uint256 currentSupplyOfTokens = totalSupply;

		// calculate the token withdraw ratio based on current supply 
		uint256 withdrawEther = SafeMath.mul(_amountTokens, currentTotalBankroll) / currentSupplyOfTokens;

		// developers take 1% of withdrawls 
		uint256 developersCut = withdrawEther / 100;
		uint256 contributorAmount = SafeMath.sub(withdrawEther, developersCut);

		// now update the total supply of tokens by subtracting the tokens that are being "cashed in"
		totalSupply = SafeMath.sub(currentSupplyOfTokens, _amountTokens);

		// and update the users supply of tokens 
		balances[msg.sender] = SafeMath.sub(tokenBalance, _amountTokens);

		// update the developers fund based on this calculated amount 
		DEVELOPERSFUND = SafeMath.add(DEVELOPERSFUND, developersCut);

		// lastly, transfer the ether back to the bankroller. Thanks for your contribution!
		msg.sender.transfer(contributorAmount);

		// log an event about cashout
		emit CashOut(msg.sender, contributorAmount, _amountTokens);

		// log a destroy tokens event
		emit Transfer(msg.sender, 0x0, _amountTokens);
	}

	// TO CALL THIS FUNCTION EASILY, SEND A 0 ETHER TRANSACTION TO THIS CONTRACT WITH EXTRA DATA: 0x7a09588b
	function cashoutEOSBetStakeTokens_ALL() public {

		// just forward to cashoutEOSBetStakeTokens with input as the senders entire balance
		cashoutEOSBetStakeTokens(balances[msg.sender]);
	}

	////////////////////
	// OWNER FUNCTIONS:
	////////////////////
	// Please, be aware that the owner ONLY can change:
		// 1. The owner can increase or decrease the target amount for a game. They can then call the updater function to give/receive the ether from the game.
		// 1. The wait time until a user can withdraw or transfer their tokens after purchase through the default function above ^^^
		// 2. The owner can change the maximum amount of investments allowed. This allows for early contributors to guarantee
		// 		a certain percentage of the bankroll so that their stake cannot be diluted immediately. However, be aware that the 
		//		maximum amount of investments allowed will be raised over time. This will allow for higher bets by gamblers, resulting
		// 		in higher dividends for the bankrollers
		// 3. The owner can freeze payouts to bettors. This will be used in case of an emergency, and the contract will reject all
		//		new bets as well. This does not mean that bettors will lose their money without recompense. They will be allowed to call the 
		// 		"refund" function in the respective game smart contract once payouts are un-frozen.
		// 4. Finally, the owner can modify and withdraw the developers reward, which will fund future development, including new games, a sexier frontend,
		// 		and TRUE DAO governance so that onlyOwner functions don&#39;t have to exist anymore ;) and in order to effectively react to changes 
		// 		in the market (lower the percentage because of increased competition in the blockchain casino space, etc.)

	function transferOwnership(address newOwner) public {
		require(msg.sender == OWNER);

		OWNER = newOwner;
	}

	function changeWaitTimeUntilWithdrawOrTransfer(uint256 waitTime) public {
		// waitTime MUST be less than or equal to 10 weeks
		require (msg.sender == OWNER && waitTime <= 6048000);

		WAITTIMEUNTILWITHDRAWORTRANSFER = waitTime;
	}

	function changeMaximumInvestmentsAllowed(uint256 maxAmount) public {
		require(msg.sender == OWNER);

		MAXIMUMINVESTMENTSALLOWED = maxAmount;
	}


	function withdrawDevelopersFund(address receiver) public {
		require(msg.sender == OWNER);

		// first get developers fund from each game 
        EOSBetGameInterface(DICE).payDevelopersFund(receiver);
		EOSBetGameInterface(SLOTS).payDevelopersFund(receiver);

		// now send the developers fund from the main contract.
		uint256 developersFund = DEVELOPERSFUND;

		// set developers fund to zero
		DEVELOPERSFUND = 0;

		// transfer this amount to the owner!
		receiver.transfer(developersFund);
	}

	// Can be removed after some testing...
	function emergencySelfDestruct() public {
		require(msg.sender == OWNER);

		selfdestruct(msg.sender);
	}

	///////////////////////////////
	// BASIC ERC20 TOKEN OPERATIONS
	///////////////////////////////

	function totalSupply() constant public returns(uint){
		return totalSupply;
	}

	function balanceOf(address _owner) constant public returns(uint){
		return balances[_owner];
	}

	// don&#39;t allow transfers before the required wait-time
	// and don&#39;t allow transfers to this contract addr, it&#39;ll just kill tokens
	function transfer(address _to, uint256 _value) public returns (bool success){
		if (balances[msg.sender] >= _value 
			&& _value > 0 
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
			&& _to != address(this)){

			// safely subtract
			balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
			balances[_to] = SafeMath.add(balances[_to], _value);

			// log event 
			emit Transfer(msg.sender, _to, _value);
			return true;
		}
		else {
			return false;
		}
	}

	// don&#39;t allow transfers before the required wait-time
	// and don&#39;t allow transfers to the contract addr, it&#39;ll just kill tokens
	function transferFrom(address _from, address _to, uint _value) public returns(bool){
		if (allowed[_from][msg.sender] >= _value 
			&& balances[_from] >= _value 
			&& _value > 0 
			&& contributionTime[_from] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
			&& _to != address(this)){

			// safely add to _to and subtract from _from, and subtract from allowed balances.
			balances[_to] = SafeMath.add(balances[_to], _value);
	   		balances[_from] = SafeMath.sub(balances[_from], _value);
	  		allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);

	  		// log event
    		emit Transfer(_from, _to, _value);
    		return true;
   		} 
    	else { 
    		return false;
    	}
	}
	
	function approve(address _spender, uint _value) public returns(bool){
		if(_value > 0){

			allowed[msg.sender][_spender] = _value;
			emit Approval(msg.sender, _spender, _value);
			// log event
			return true;
		}
		else {
			return false;
		}
	}
	
	function allowance(address _owner, address _spender) constant public returns(uint){
		return allowed[_owner][_spender];
	}
}