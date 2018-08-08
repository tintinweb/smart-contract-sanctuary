pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// &#39;PoWEth Token&#39; contract
// Mineable ERC20 Token using Proof Of Work
//
// Symbol      : PoWEth
// Name        : PoWEth Token
// Total supply: 100,000,000.00
// Decimals    : 8
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
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
}

library ExtendedMath {
    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract _0xEtherToken is ERC20Interface {
    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol = "PoWEth";
    string public name = "PoWEth Token";
    uint8 public decimals = 8;
    uint public _totalSupply = 10000000000000000;
	uint public maxSupplyForEra = 5000000000000000;
	
    uint public latestDifficultyPeriodStarted;
	uint public tokensMinted;
	
    uint public epochCount; //number of &#39;blocks&#39; mined
    uint public _BLOCKS_PER_READJUSTMENT = 1024;

    uint public  _MINIMUM_TARGET = 2**16;
    uint public  _MAXIMUM_TARGET = 2**234;

    uint public miningTarget = _MAXIMUM_TARGET;

    bytes32 public challengeNumber;   //generate a new one when a new reward is minted

    uint public rewardEra;
    
    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    mapping(bytes32 => bytes32) solutionForChallenge;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    address private owner;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    function _0xEtherToken() public {
        
        owner = msg.sender;
        
        latestDifficultyPeriodStarted = block.number;

        _startNewMiningEpoch();

        //The owner gets nothing! You must mine this ERC20 token
        //balances[owner] = _totalSupply;
        //Transfer(address(0), owner, _totalSupply);
    }

	function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {

		//the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender&#39;s address to prevent MITM attacks
		bytes32 digest = keccak256(challengeNumber, msg.sender, nonce );

		//the challenge digest must match the expected
		if (digest != challenge_digest) revert();

		//the digest must be smaller than the target
		if(uint256(digest) > miningTarget) revert();

		//only allow one reward for each challenge
		bytes32 solution = solutionForChallenge[challengeNumber];
		solutionForChallenge[challengeNumber] = digest;
		if(solution != 0x0) 
			revert();  //prevent the same answer from awarding twice

		uint reward_amount = getMiningReward();

		balances[msg.sender] = balances[msg.sender].add(reward_amount);

		tokensMinted = tokensMinted.add(reward_amount);

		//Cannot mint more tokens than there are
		assert(tokensMinted <= maxSupplyForEra);

		//set readonly diagnostics data
		lastRewardTo = msg.sender;
		lastRewardAmount = reward_amount;
		lastRewardEthBlockNumber = block.number;
		
		_startNewMiningEpoch();
    	emit Mint(msg.sender, reward_amount, epochCount, challengeNumber );

	   return true;
	}

    //a new &#39;block&#39; to be mined
    function _startNewMiningEpoch() internal {
		//if max supply for the era will be exceeded next reward round then enter the new era before that happens

		//20 is the final reward era, almost all tokens minted
		//once the final era is reached, more tokens will not be given out because the assert function
		// 1 era is estimated 1,5y, 20 era is roughly 60y of mining time
		if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 19)
		{
			rewardEra = rewardEra + 1;
		}

		maxSupplyForEra = _totalSupply - _totalSupply / (2**(rewardEra + 1));

		epochCount = epochCount.add(1);

		//every so often, readjust difficulty. Dont readjust when deploying
		if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
		{
			_reAdjustDifficulty();
		}

		//make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
		//do this last since this is a protection mechanism in the mint() function
		challengeNumber = block.blockhash(block.number - 1);
    }

    //https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
    //as of 2017 the bitcoin difficulty was up to 17 zeroes, it was only 8 in the early days
    //readjust the target by 5 percent
    function _reAdjustDifficulty() internal {
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        
        //assume 240 ethereum blocks per hour
        //we want miners to spend ~7,5 minutes to mine each &#39;block&#39;, about 30 ethereum blocks = 1 PoWEth epoch
        uint targetEthBlocksPerDiffPeriod = _BLOCKS_PER_READJUSTMENT * 30; //should be 30 times slower than ethereum

        //if there were less eth blocks passed in time than expected
        if(ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod)
        {
			uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)) / ethBlocksSinceLastDifficultyPeriod;
			uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
			
			//make it harder
			miningTarget = miningTarget.sub((miningTarget/2000).mul(excess_block_pct_extra));
        }else{
			uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)) / targetEthBlocksPerDiffPeriod;
			uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000);

			//make it easier
			miningTarget = miningTarget.add((miningTarget/2000).mul(shortage_block_pct_extra));
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
    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

    //the number of zeroes the digest of the PoW solution requires.  Auto adjusts
     function getMiningDifficulty() public constant returns (uint) {
        return _MAXIMUM_TARGET / miningTarget;
    }

    function getMiningTarget() public constant returns (uint) {
       return miningTarget;
	}

    //100m coins total
    //reward begins at 250 and is cut in half every reward era (as tokens are mined)
    function getMiningReward() public constant returns (uint) {
		return 25000000000/(2**rewardEra);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        require(msg.sender == owner);
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    //help debug mining software
    function getMintDigest(uint256 nonce, bytes32 challenge_number) public view returns (bytes32 digesttest) {
        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
        return digest;
	}

	//help debug mining software
	function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {
		bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
		if(uint256(digest) > testTarget) 
			revert();
		return (digest == challenge_digest);
	}
}