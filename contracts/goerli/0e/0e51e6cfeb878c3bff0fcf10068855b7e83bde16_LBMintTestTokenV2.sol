// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC20Ownable.sol";
import "./Context.sol";

// ----------------------------------------------------------------------------
// Lib: Safe Math
// ----------------------------------------------------------------------------
library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function ceil(uint a, uint m) internal pure returns (uint) {
        uint c = add(a,m);
        uint d = sub(c,1);
        return mul(div(d, m),m);
    }
}

library ExtendedMath {

    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

abstract contract StandardToken is Context, IERC20, IERC20Metadata {
    
    using SafeMath for uint;
    using ExtendedMath for uint;
	
    mapping(address => uint) balances;
    uint _totalSupply;
    
    /**
     * @dev total number of tokens in existence
     **/
    function  totalSupply() override public view returns (uint) {
        return _totalSupply;
    }
    
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     **/
    function transfer(address _to, uint _value) override public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint representing the amount owned by the passed address.
     **/
    function balanceOf(address _owner) override public view returns (uint) {
        return balances[_owner];
    }
    
    //-------------------------------------------------------------------------
    // Calculate one percent of a given token value.
    //-------------------------------------------------------------------------
    function findOnePercent(uint tokenAmount) public pure returns (uint){
    	uint roundValue = tokenAmount.ceil(100);
    	uint onePercent = roundValue.mul(100).div(10000);
    	return onePercent;
    }
    
	mapping (address => mapping (address => uint)) internal allowed;
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     **/
    function transferFrom(address _from, address _to, uint _value) override public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     **/
    function approve(address _spender, uint _value) override public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     **/
    function allowance(address _owner, address _spender) override public view returns (uint) {
        return allowed[_owner][_spender];
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     **/
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     **/
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
	
}

/**
 * @title Configurable
 * @dev Configurable varriables of the contract
 **/
contract Configurable {
    using SafeMath for uint;
	
    uint public constant cap = 100000000*10**18;
    uint public constant basePrice = 10000000*10**18; // tokens per 1 ether
	
    uint public constant minableTokenSupply = 200000000*10**18;
    uint public tokenReserve = 200000000*10**18;
	
    uint public tokensSold = 0;
    uint public remainingTokens = 0;
	
	/*
	 * Minting Variables
	 */
	
    uint public tokensMinted;
	uint public latestDifficultyPeriodStarted;
	
    //Difficulty Max and Min
	uint public  _MINIMUM_TARGET = 2**16;
    uint public  _MAXIMUM_TARGET = 2**234;
    uint public _BLOCKS_PER_READJUSTMENT = 1024;
	
    uint public miningTarget = _MAXIMUM_TARGET; //Max Difficulty in the beginning
    bytes32 public challengeNumber;   //generate a new one when a new reward is minted
	
    uint public epochCount;//number of 'blocks' mined
	
    uint public rewardEra;
    uint public maxSupplyForEra;

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    mapping(bytes32 => bytes32) solutionForChallenge;
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}

/**
 * @title CrowdsaleToken 
 * @dev Contract to preform crowd sale with token
 **/
abstract contract CrowdsaleToken is StandardToken, Configurable, IERC20Ownable {
    using SafeMath for uint;
    using ExtendedMath for uint;
    
    /**
     * @dev enum of current crowd sale state
     **/
     enum Stages {
        none,
        icoStart, 
        icoEnd
    }
    
    Stages currentStage;
  
    /**
     * @dev constructor of CrowdsaleToken
     **/
    constructor() {
        currentStage = Stages.none;
        _totalSupply = _totalSupply.add(tokenReserve);
        remainingTokens = cap;
		
		rewardEra = 0;
		tokensMinted = 0;
		maxSupplyForEra = minableTokenSupply.div(2);
		latestDifficultyPeriodStarted = block.number;
		
		_startNewMiningEpoch();
    }
    
    /**
     * @dev fallback function to send ether to for Crowd sale
     **/
    receive () external payable {
        require(currentStage == Stages.icoStart);
        require(msg.value > 0);
        require(remainingTokens > 0);
        
        
        uint weiAmount = msg.value; // Calculate tokens to sell
        uint tokens = weiAmount.mul(basePrice).div(1 ether);
        uint returnWei = 0;
        
        if(tokensSold.add(tokens) > cap){
            uint newTokens = cap.sub(tokensSold);
            uint newWei = newTokens.div(basePrice).mul(1 ether);
            returnWei = weiAmount.sub(newWei);
            weiAmount = newWei;
            tokens = newTokens;
        }
        
        tokensSold = tokensSold.add(tokens); // Increment raised amount
        remainingTokens = cap.sub(tokensSold);
        if(returnWei > 0){
            payable(msg.sender).transfer(returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }
        
		//Gift 1% from Reserve
		uint tokensToAdd = findOnePercent(tokens);
		tokenReserve = tokenReserve.sub(tokensToAdd);
        uint tokensToTransfer = tokens.add(tokensToAdd);
        balances[msg.sender] = balances[msg.sender].add(tokensToTransfer);
        emit Transfer(address(this), msg.sender, tokensToTransfer);
		
		//Increase the number of supplied tokens in circulation
        _totalSupply = _totalSupply.add(tokens);
        
		payable(owner).transfer(weiAmount);// Send money to owner
		
    }
	/**
     * @dev startIco starts the public ICO
     **/
    function startIco() public onlyOwner {
        require(currentStage != Stages.icoEnd);
        currentStage = Stages.icoStart;
    }
	/**
     * @dev endIco closes down the ICO 
     **/
    function endIco() internal {
        currentStage = Stages.icoEnd;
        // Transfer any remaining tokens
        if(remainingTokens > 0)
            balances[owner] = balances[owner].add(remainingTokens);
		_totalSupply = _totalSupply.add(remainingTokens);
        // transfer any remaining ETH balance in the contract to the owner
        payable(owner).transfer(address(this).balance); 
		// transfer reserve to owner to offer liquidity
        balances[owner] = balances[owner].add(tokenReserve);
        emit Transfer(address(this), owner, tokenReserve);
    }
	/**
     * @dev finalizeIco closes down the ICO and sets needed varriables
     **/
    function finalizeIco() public onlyOwner {
        require(currentStage != Stages.icoEnd);
        endIco();
    }
    
    /*
	 *The minting section
	 */
	 
	 function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {


		//the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender's address to prevent MITM attacks
		bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce ));

		//the challenge digest must match the expected
		if (digest != challenge_digest) revert();

		//the digest must be smaller than the target
		if(uint256(digest) > miningTarget) revert();

		//only allow one reward for each challenge
		bytes32 solution = solutionForChallenge[challengeNumber];
		solutionForChallenge[challengeNumber] = digest;
		if(solution != 0x0) revert();  //prevent the same answer from awarding twice

		uint reward_amount = getMiningReward();
		balances[msg.sender] = balances[msg.sender].add(reward_amount);
		tokensMinted = tokensMinted.add(reward_amount);
		_totalSupply = _totalSupply.add(reward_amount);

		//Cannot mint more tokens than there are
		assert(tokensMinted <= maxSupplyForEra);

		//set readonly diagnostics data
		lastRewardTo = msg.sender;
		lastRewardAmount = reward_amount;
		lastRewardEthBlockNumber = block.number;

		_startNewMiningEpoch();
		Mint(msg.sender, reward_amount, epochCount, challengeNumber );

		return true;
	}


	//a new 'block' to be mined
	function _startNewMiningEpoch() internal {

	  //if max supply for the era will be exceeded next reward round then enter the new era before that happens

	  //40 is the final reward era, almost all tokens minted
	  //once the final era is reached, more tokens will not be given out because the assert function
	  if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39)
	  {
		rewardEra = rewardEra + 1;
	  }

	  //set the next minted supply at which the era will change
	  // total supply is 200000000000000000000000000  because of 8 decimal places
	  maxSupplyForEra = minableTokenSupply - minableTokenSupply.div( 2**(rewardEra + 1));

	  epochCount = epochCount.add(1);

	  //every so often, readjust difficulty. Dont readjust when deploying
	  if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
	  {
		_reAdjustDifficulty();
	  }

	  //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
	  //do this last since this is a protection mechanism in the mint() function
	  challengeNumber = blockhash(block.number - 1);
	}


	//https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
	//as of 2017 the bitcoin difficulty was up to 17 zeroes, it was only 8 in the early days

	//readjust the target by 5 percent
	function _reAdjustDifficulty() internal {

		uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
		//assume 360 ethereum blocks per hour

		//we want miners to spend 10 minutes to mine each 'block', about 60 ethereum blocks = one 0xbitcoin epoch
		uint epochsMined = _BLOCKS_PER_READJUSTMENT; //256

		uint targetEthBlocksPerDiffPeriod = epochsMined * 60; //should be 60 times slower than ethereum

		//if there were less eth blocks passed in time than expected
		if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
		{
		  uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );

		  uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
		  // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.

		  //make it harder
		  miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %
		}else{
		  uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );

		  uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

		  //make it easier
		  miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));   //by up to 50 %
		}

		latestDifficultyPeriodStarted = block.number;

		if(miningTarget < _MINIMUM_TARGET) //very difficult
		{
		  miningTarget = _MINIMUM_TARGET;
		}

		if(miningTarget > _MAXIMUM_TARGET) //very easy
		{
		  miningTarget = _MAXIMUM_TARGET;
		}
	}

	//this is a recent ethereum block hash, used to prevent pre-mining future blocks
	function getChallengeNumber() public view returns (bytes32) {
		return challengeNumber;
	}

	//the number of zeroes the digest of the PoW solution requires.  Auto adjusts
	 function getMiningDifficulty() public view returns (uint) {
		return _MAXIMUM_TARGET.div(miningTarget);
	}

	function getMiningTarget() public view returns (uint) {
	   return miningTarget;
	}

	//100m coins total
	//reward begins at 50 and is cut in half every reward era (as tokens are mined)
	function getMiningReward() public view returns (uint) {
		//once we get half way thru the coins, only get 25 per block
		 //every reward era, the reward amount halves.
		 return (50 * 10**uint(18) ).div( 2**rewardEra ) ;
	}

	//help debug mining software
	function getMintDigest(uint256 nonce, bytes32 challenge_number) public view returns (bytes32 digesttest) {

		bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));
		return digest;
	}

	//help debug mining software
	function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

	  bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));
	  if(uint256(digest) > testTarget) revert();
	  return (digest == challenge_digest);

	}
	
	//Returns the amount of Tokens that have been minted
	function getMintedTokenAmount() public view returns (uint) {
		return tokensMinted;
	}
	
	//Return the amount of Tokens that can still be minted
	function getMintableTokenAmount() public view returns (uint) {
		return minableTokenSupply.sub(tokensMinted);
	}
	
	//Return the maximal amount of Tokens that can ever exist
	function getMaxSupply() public view returns (uint) {
		return tokenReserve.add(minableTokenSupply).add(cap);
	}
}

/**
 * @title LavevelToken 
 * @dev Contract to create the Kimera Token
 **/
contract LBMintTestTokenV2 is CrowdsaleToken {
    string override public constant name = "LB Mint Test Token V2";
    string override public constant symbol = "LBMTX";
    uint override public constant decimals = 18;
}