// SPDX-License-Identifier: MIT

//Compiler Version
pragma solidity ^0.8.0;

//Dependencies
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC20Ownable.sol";
import "./Context.sol";

//----------------------------------------------------------------------------
// Safe Math Library
//----------------------------------------------------------------------------
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

//----------------------------------------------------------------------------
// Extended Math Library
//----------------------------------------------------------------------------
library ExtendedMath {
	using SafeMath for uint;
	
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
	
	function findOnePercent(uint _tokenAmount) internal pure returns (uint){
    	uint roundValue = _tokenAmount.ceil(100);
    	uint onePercent = roundValue.mul(100).div(10000);
    	return onePercent;
    }
}

//----------------------------------------------------------------------------
// @title Standard Contract for a token, that implement all neccessary
// definitions and variables.
//----------------------------------------------------------------------------
abstract contract StandardToken is Context, IERC20, IERC20Metadata {
    
    using SafeMath for uint;
    using ExtendedMath for uint;
	
    uint _totalSupply;
    
	mapping(address => uint) balances;
	mapping (address => mapping (address => uint)) internal allowed;
    
    /**
     * Total amount of supply in circulation.
	 * @return uint
	 * Returns the amount.
     **/
    function  totalSupply() override public view returns (uint) {
        return _totalSupply;
    }
    
    /**
     * Transfers a specified token amount to an address.
	 *
     * @param _to is Address
	 * The address to transfer to.
     * @param _value is uint
	 * The amount to be transferred.
	 * @return bool
	 * Returns true for success and false if it wasn't successfull.
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
     * Returns the balance of a specified address.
	 *
     * @param _owner is Address
	 * The address to query the the balance from.
     * @return is uint
	 * An uint representing the amount owned by the specified address.
     **/
    function balanceOf(address _owner) override public view returns (uint) {
        return balances[_owner];
    }
    
    /**
     * Calculates the one percent of a given amount.
	 *
     * @param _tokenAmount is uint
	 * The address to query the the balance from.
     * @return is uint
	 * An uint representing the amount owned by the specified address.
     **/
    // function findOnePercent(uint _tokenAmount) public pure returns (uint){
    	// uint roundValue = _tokenAmount.ceil(100);
    	// uint onePercent = roundValue.mul(100).div(10000);
    	// return onePercent;
    // }
    
    /**
     * Transfers a desired amount from one address to another.
	 * 
     * @param _from is Address
	 * Address the amount is being sent from.
     * @param _to is Address
	 * Address the amount is being transfered to.
     * @param _value is uint
	 * The amount that shall be transfered.
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
     * Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * @param _spender is Address
	 * The address which will spend the funds.
     * @param _value is uint
	 * The amount of tokens to be spent.
     **/
    function approve(address _spender, uint _value) override public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner is Address
	 * The address which owns the funds.
     * @param _spender is Address
	 * The address which will spend the funds.
     * @return is uint
	 * A uint specifying the amount of tokens still available for the spender.
     **/
    function allowance(address _owner, address _spender) override public view returns (uint) {
        return allowed[_owner][_spender];
    }
    
    /**
     * Increases the amount of tokens that an owner allowed to a spender.
     *
     * The function 'approve' should be called when allowed[_spender] == 0. To increment
     * the allowed value it's better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined).
	 * - From MonolithDAO Token.sol
	 * 
     * @param _spender is Address
	 * The address which will spend the funds.
     * @param _addedValue is Address
	 * The amount of tokens to increase the allowance by.
     **/
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * Decreases the amount of tokens that an owner allowed to a spender.
     *
     * The function 'approve' should be called when allowed[_spender] == 0. To decrement
     * the allowed value it's better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined).
	 * - From MonolithDAO Token.sol
	 * 
     * @param _spender is Address
	 * The address which will spend the funds.
     * @param _subtractedValue is Address
	 * The amount of tokens to decrease the allowance by.
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

//----------------------------------------------------------------------------
// @title Sets the configurable variables for the Contract
//----------------------------------------------------------------------------
contract Configurable {
    using SafeMath for uint;
	
    uint public constant cap = 100000000*10**18; //100m
    uint public constant basePrice = 10000000*10**18; //10m->1ETH
	
    uint public constant minableTokenSupply = 200000000*10**18; //200m
    uint public tokenReserve = 200000000*10**18; //200m
	
    uint public tokensSold = 0;
    uint public remainingSellTokens = 0;
	
	/**
	 * Minting Variables
	 **/
    uint public tokensMinted;
	uint public latestDifficultyPeriodStarted;
	
	uint public  _MINIMUM_TARGET = 2**16;
    uint public  _MAXIMUM_TARGET = 2**234;
	
    uint public _BLOCKS_BEFORE_READJUSTMENT = 50;
	
    uint public miningTarget = _MAXIMUM_TARGET;
    bytes32 public challengeNumber;
	
    uint public epochCount;
	
    uint public rewardEra;
    uint public maxSupplyForEra;

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    mapping(bytes32 => bytes32) solutionForChallenge;
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}

//----------------------------------------------------------------------------
// @title Contract for a smart Contract that implements a crowdsale implementation.
// Thanks to Stephen Hall!
//----------------------------------------------------------------------------
abstract contract CrowdsaleToken is StandardToken, Configurable, IERC20Ownable {
    using SafeMath for uint;
    using ExtendedMath for uint;
    
    //current states of the crowdsale
     enum Stages {
        none,
        icoStart, 
        icoEnd
    }
    Stages currentStage;
  
    //constructor
    constructor() {
        currentStage = Stages.none;
        _totalSupply = _totalSupply.add(tokenReserve);
        remainingSellTokens = cap;
		
		rewardEra = 0;
		tokensMinted = 99999890*10**18;
		epochCount = 45;
		maxSupplyForEra = minableTokenSupply.div(2);
		latestDifficultyPeriodStarted = block.number;
		
		_startNewMiningEpoch();
    }
    
    /**
     * @dev receive function to send ether to for Crowd sale
     **/
    receive () external payable {
        require(currentStage == Stages.icoStart);
        require(msg.value > 0);
        require(remainingSellTokens > 0);
        
        
        uint weiAmount = msg.value;
        uint tokens = weiAmount.mul(basePrice).div(1 ether);
        uint returnWei = 0;
        
        if(tokensSold.add(tokens) > cap){
            uint newTokens = cap.sub(tokensSold);
            uint newWei = newTokens.div(basePrice).mul(1 ether);
            returnWei = weiAmount.sub(newWei);
            weiAmount = newWei;
            tokens = newTokens;
        }
        
        tokensSold = tokensSold.add(tokens);
        remainingSellTokens = cap.sub(tokensSold);
        if(returnWei > 0){
            payable(msg.sender).transfer(returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }
        
		uint tokensToAdd = tokens.findOnePercent();
		tokenReserve = tokenReserve.sub(tokensToAdd);
        uint tokensToTransfer = tokens.add(tokensToAdd);
        balances[msg.sender] = balances[msg.sender].add(tokensToTransfer);
        emit Transfer(address(this), msg.sender, tokensToTransfer);
		
        _totalSupply = _totalSupply.add(tokens);
        
		payable(owner).transfer(weiAmount);
    }
	
	/**
     * Starts the crowdsale
     **/
    function startIco() public onlyOwner {
        require(currentStage != Stages.icoEnd);
        currentStage = Stages.icoStart;
    }
	
	/**
     * Ends the crowdsale
     **/
    function endIco() internal {
        currentStage = Stages.icoEnd;
        
        if(remainingSellTokens > 0)
            balances[owner] = balances[owner].add(remainingSellTokens);
		_totalSupply = _totalSupply.add(remainingSellTokens);
        
        payable(owner).transfer(address(this).balance); 
		
        balances[owner] = balances[owner].add(tokenReserve);
        emit Transfer(address(this), owner, tokenReserve);
    }
	
	/**
     * Finalizes the crowdsale and ends it.
     **/
    function finalizeIco() public onlyOwner {
        require(currentStage != Stages.icoEnd);
        endIco();
    }
    
    /*
	 * Minting function that can be called to gain a reward.
	 * 
	 * @param _nonce is uint265
	 * The number that has been found by the sender.
	 * @param _challenge_digest is bytes32
	 * The challenge the nonce is for.
	 *
	 * Thanks for 0xBitcoin!
	 */
	 function mint(uint256 _nonce, bytes32 _challenge_digest) public returns (bool success) {

		bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, _nonce ));

		if (digest != _challenge_digest) revert();
		if(uint256(digest) > miningTarget) revert();

		bytes32 solution = solutionForChallenge[challengeNumber];
		solutionForChallenge[challengeNumber] = digest;
		if(solution != 0x0) revert();

		uint reward_amount = getMiningReward();
		balances[msg.sender] = balances[msg.sender].add(reward_amount);
		tokensMinted = tokensMinted.add(reward_amount);
		_totalSupply = _totalSupply.add(reward_amount);

		assert(tokensMinted <= maxSupplyForEra);

		lastRewardTo = msg.sender;
		lastRewardAmount = reward_amount;
		lastRewardEthBlockNumber = block.number;

		_startNewMiningEpoch();
		Mint(msg.sender, reward_amount, epochCount, challengeNumber );

		return true;
	}


	/*
	 * Starts the next minting proccess by checking if a new reward era was reached or the
	 * difficuly of the minting has to be adjusted and sets the next challenge.
	 */
	function _startNewMiningEpoch() internal {

	  if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39)
	  {
		rewardEra = rewardEra + 1;
	  }

	  maxSupplyForEra = minableTokenSupply - minableTokenSupply.div( 2**(rewardEra + 1));

	  epochCount = epochCount.add(1);

	  if(epochCount % _BLOCKS_BEFORE_READJUSTMENT == 0)
	  {
		_reAdjustDifficulty();
	  }

	  challengeNumber = blockhash(block.number - 1);
	}


	//https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
	/**
	 * Function that adjust the difficulty of the mining process when called.
	 **/
	function _reAdjustDifficulty() internal {

		uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
		uint epochsMined = _BLOCKS_BEFORE_READJUSTMENT;
		uint targetEthBlocksPerDiffPeriod = epochsMined * 60;

		if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
		{
		  uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );
		  uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
		  miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));
		}
		else
		{
		  uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );
		  uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000);
		  miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));
		}

		latestDifficultyPeriodStarted = block.number;

		if(miningTarget < _MINIMUM_TARGET)
		{
		  miningTarget = _MINIMUM_TARGET;
		}

		if(miningTarget > _MAXIMUM_TARGET)
		{
		  miningTarget = _MAXIMUM_TARGET;
		}
	}

	/**
	 * Get the current challenge for minting tokens.
	 * 
	 * @return
	 * A byte32 variable that represents the current challenge
	 **/
	function getChallengeNumber() public view returns (bytes32) {
		return challengeNumber;
	}

	/**
	 * The numbers of zeroes the submitted digest to the minting function
	 * must to contain.
	 * 
	 * @return
	 * A uint variable that represents the amount of zeroes.
	 **/
	function getMiningDifficulty() public view returns (uint) {
		return _MAXIMUM_TARGET.div(miningTarget);
	}

	/**
	 * Get the current minting target that is also used to calculate
	 * the difficulty of the minting process.
	 *
	 * @return
	 * A uint variable that represents the minting target.
	 **/
	function getMiningTarget() public view returns (uint) {
	   return miningTarget;
	}

	/**
	 * Rewards token for successfully calling the minting function.
	 * The rewards start at 100 and are halved after every era.
	 *
	 * @return
	 * A uint variable that represents the minting reward.
	 **/
	function getMiningReward() public view returns (uint) {
		 return (100 * 10**uint(18) ).div( 2**rewardEra ) ;
	}

	// Function to help debugging miners
	function getMintDigest(uint256 nonce, bytes32 challenge_number) public view returns (bytes32 digesttest) {

		bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));
		return digest;
	}

	// Function to help debugging miners
	function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

	  bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));
	  if(uint256(digest) > testTarget) revert();
	  return (digest == challenge_digest);

	}
	
	/**
	 * Gets the amount of all tokens that have been minted so far.
	 *
	 * @return
	 * A uint variable that represents the amount of minted tokens.
	 **/
	function getMintedTokenAmount() public view returns (uint) {
		return tokensMinted;
	}
	
	/**
	 * Gets the amount of all tokens that can still be minted.
	 *
	 * @return
	 * A uint variable that represents the amount of mintable tokens.
	 **/
	function getMintableTokenAmount() public view returns (uint) {
		return minableTokenSupply.sub(tokensMinted);
	}
	
	/**
	 * Gets the amount of all the token that can ever exist.
	 *
	 * @return
	 * A uint variable that represents the maximal amount of tokens.
	 **/
	function getMaxSupply() public view returns (uint) {
		return tokenReserve.add(minableTokenSupply).add(cap);
	}
}

//----------------------------------------------------------------------------
// @title The actual contract for BASD Token.
//----------------------------------------------------------------------------
contract BASDToken is CrowdsaleToken {
    string override public constant name = "BASD Token";
    string override public constant symbol = "BASD";
    uint override public constant decimals = 18;
}