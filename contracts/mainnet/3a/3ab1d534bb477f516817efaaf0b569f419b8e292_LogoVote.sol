pragma solidity ^0.4.10;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
/*
 * Safe Math Smart Contract.  Copyright &#169; 2016 by ABDK Consulting.
 */

/**
 * Provides methods to safely add, subtract and multiply uint256 numbers.
 */
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Add two uint256 values, throw in case of overflow.
   *
   * @param x first value to add
   * @param y second value to add
   * @return x + y
   */
  function safeAdd (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x > MAX_UINT256 - y) throw;
    return x + y;
  }

  /**
   * Subtract one uint256 value from another, throw in case of underflow.
   *
   * @param x value to subtract from
   * @param y value to subtract
   * @return x - y
   */
  function safeSub (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x < y) throw;
    return x - y;
  }

  /**
   * Multiply two uint256 values, throw in case of overflow.
   *
   * @param x first value to multiply
   * @param y second value to multiply
   * @return x * y
   */
  function safeMul (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    if (x > MAX_UINT256 / y) throw;
    return x * y;
  }
}

contract Vote is ERC20, SafeMath{

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint)) allowed;

	uint public totalSupply;
	uint public initialSupply;
	string public name;
	string public symbol;
	uint8 public decimals;

	function Vote(){
		initialSupply = 100000;
		totalSupply = initialSupply;
		balances[msg.sender] = initialSupply;
		name = "EthTaipei Logo Vote";
		symbol = "EthTaipei Logo";
		decimals = 0;
	}

	function transfer(address _to, uint _value) returns (bool) {
	    balances[msg.sender] = safeSub(balances[msg.sender], _value);
	    balances[_to] = safeAdd(balances[_to], _value);
	    Transfer(msg.sender, _to, _value);
	    return true;
  	}

  	function transferFrom(address _from, address _to, uint _value) returns (bool) {
	    var _allowance = allowed[_from][msg.sender];	    
	    balances[_to] = safeAdd(balances[_to], _value);
	    balances[_from] = safeSub(balances[_from], _value);
	    allowed[_from][msg.sender] = safeSub(_allowance, _value);
	    Transfer(_from, _to, _value);
	    return true;
  	}

  	function approve(address _spender, uint _value) returns (bool) {
    	allowed[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);
    	return true;
  	}

  	function balanceOf(address _address) constant returns (uint balance) {
  		return balances[_address];
  	}

  	function allowance(address _owner, address _spender) constant returns (uint remaining) {
    	return allowed[_owner][_spender];
  	}

}
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

contract wLogoVote {
	function claimReward(address _receiver);
}

contract Logo is Ownable{

	wLogoVote public logoVote;

	address public author;
	string public metadataUrl;

	event ReceiveTips(address _from, uint _value);

	function Logo(address _owner, address _author, string _metadatUrl){
		owner = _owner;
		author = _author;
		metadataUrl = _metadatUrl;
		logoVote = wLogoVote(msg.sender);
	}

	function tips() payable {
		ReceiveTips(msg.sender, msg.value);
		if(!author.send(msg.value)) throw;
	}

	function claimReward() onlyOwner {
		logoVote.claimReward(author);
	}

	function setMetadata(string _metadataUrl) onlyOwner {
		metadataUrl = _metadataUrl;
	}

	function () payable {
		tips();
	}
}
/*
 * Pausable
 * Abstract contract that allows children to implement an
 * emergency stop mechanism.
 */

contract Pausable is Ownable {
  bool public stopped;

  modifier stopInEmergency {
    if (stopped) {
      throw;
    }
    _;
  }
  
  modifier onlyInEmergency {
    if (!stopped) {
      throw;
    }
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }

}
contract Token{
	function transfer(address to, uint value) returns (bool ok);
}

contract Faucet {

	address public tokenAddress;
	Token token;

	function Faucet(address _tokenAddress) {
		tokenAddress = _tokenAddress;
		token = Token(tokenAddress);
	}
  
	function getToken() {
		if(!token.transfer(msg.sender, 1)) throw;
	}

	function () {
		getToken();
	}

}

contract LogoVote is Pausable, SafeMath{

	Vote public vote;
	Faucet public faucet;
	Logo[] public logos;

	mapping (address => uint) backers;
	mapping (address => bool) rewards;
	uint rewardClaimed;

	uint public votePerETH;
	uint public totalReward;
	uint public startBlock;
	uint public endBlock;
	address public winner;

	event ReceiveDonate(address addr, uint value);

	modifier respectTimeFrame() {
		if (!isRespectTimeFrame()) throw;
		_;
	}

	modifier afterEnd() {
		if (!isAfterEnd()) throw;
		_;
	}

	function LogoVote() {
		vote = new Vote();
		faucet = new Faucet(vote);
		votePerETH = 1000; // donate 0.001 ether to get 1 vote 
		totalReward = 0;
		startBlock = getBlockNumber();
		endBlock = startBlock + ( 30 * 24 * 60 * 60 / 15 ); //end in 30 days
		rewardClaimed = 0;
	}

	// functions only for owner 
	function sendToFaucet(uint _amount) onlyOwner {
		if(!vote.transfer(faucet, _amount)) throw;
	}

	function registLogo(address _owner, address _author, string _metadatUrl) 
						onlyOwner respectTimeFrame returns (address) {
		Logo logoAddress = new Logo(_owner, _author, _metadatUrl);
		logos.push(logoAddress);
		return logoAddress;
	}

	function claimWinner () onlyOwner afterEnd {
		if (isLogo(winner)) throw;
		winner = logos[0];
		for (uint8 i = 1; i < logos.length; i++) {
			if (vote.balanceOf(logos[i]) > vote.balanceOf(winner))
				winner = logos[i];
		} 
	}

	function cleanBalance () onlyOwner afterEnd {
		if (rewardClaimed >= logos.length || getBlockNumber() < endBlock + 43200) throw;
		if(!vote.transfer(owner, vote.balanceOf(this))) throw;
		if (!owner.send(this.balance)) throw;
	}

	// normal user can donate to get votes
	function donate(address beneficiary) internal stopInEmergency respectTimeFrame {
		uint voteToSend = safeMul(msg.value, votePerETH)/(1 ether);
		if (!vote.transfer(beneficiary, voteToSend)) throw; 
		backers[beneficiary] = safeAdd(backers[beneficiary], msg.value);
		totalReward = safeAdd(totalReward, msg.value);

		ReceiveDonate(beneficiary, msg.value);
	}

	// normal user can get back their funds if in emergency 
	function getFunds() onlyInEmergency {
		if (backers[msg.sender] == 0) throw;
		uint amount = backers[msg.sender];
		backers[msg.sender] = 0;

		if(!msg.sender.send(amount)) throw;
	}

	// logo&#39;s owner can claim their rewards after end 
	function claimReward (address _receiver) stopInEmergency afterEnd {
		if (!isLogo(msg.sender)) throw;
		if (rewards[msg.sender]) throw;
		if (rewardClaimed == logos.length) throw;
		uint amount = totalReward / safeMul(2, logos.length); // all logos share the 50% of rewards
		if (msg.sender == winner) {
			amount = safeAdd(amount, totalReward/2);
		}
		rewards[msg.sender] = true;
		rewardClaimed = safeAdd(rewardClaimed, 1);
		if (!_receiver.send(amount)) throw;
	}


	// helper functions 
	function isLogo (address _logoAddress) constant returns (bool) {
		for (uint8 i = 0; i < logos.length; i++) {
			if (logos[i] == _logoAddress) return true;
		}
	}

	function getLogos() constant returns (Logo[]) {
		return logos;
	}

	function getBlockNumber() constant returns (uint) {
      return block.number;
    }

	function isAfterEnd() constant returns (bool) {
      return getBlockNumber() > endBlock;
    }

	function isRespectTimeFrame() constant returns (bool) {
		return getBlockNumber() < endBlock;
	}

	function () payable {
		if (isAfterEnd()) throw;
		donate(msg.sender);
	}
}