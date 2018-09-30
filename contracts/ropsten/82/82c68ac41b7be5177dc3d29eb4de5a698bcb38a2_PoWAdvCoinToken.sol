pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;PoWAdv Token&#39; contract
// Mineable ERC20 Token using Proof Of Work
//
// Symbol      : POWA
// Name        : PoWAdv Token
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

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

library ExtendedMath {
    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract PoWAdvCoinToken is ERC20Interface, Owned {
    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    uint public latestDifficultyPeriodStarted;
    uint public firstValidBlockNumber;

    uint public epochCount; //number of &#39;blocks&#39; mined

    uint public _BLOCKS_PER_READJUSTMENT = 16;
    // avg ETH block period is ~10sec this is 60 roughly block per 10min
    uint public _TARGET_EPOCH_PER_PEDIOD = _BLOCKS_PER_READJUSTMENT * 60; 
    uint public _BLOCK_REWARD = (250 * 10**uint(8));
    //a little number
    uint public  _MINIMUM_TARGET = 2**16;
    //a big number is easier ; just find a solution that is smaller
    uint public  _MAXIMUM_TARGET = 2**234;

    uint public miningTarget;
    bytes32 public challengeNumber;   //generate a new one when a new reward is minted

    bool locked = false;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function PoWAdvCoinToken() public onlyOwner {

        symbol = "POWA";
        name = "PoWAdv Token";
        decimals = 8;
        _totalSupply = 100000000 * 10**uint(decimals);

        if(locked) 
			revert();
			
        locked = true;
        tokensMinted = 0;
        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        firstValidBlockNumber =  5349511;
        _startNewMiningEpoch();

        // Sum of tokens mined before hard fork, will be distributed manually
        epochCount = 3071;
        balances[owner] = epochCount * _BLOCK_REWARD;
        tokensMinted = epochCount * _BLOCK_REWARD;
    }
 
	function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {

        require(block.number > firstValidBlockNumber);
            
		//the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender&#39;s address to prevent MITM attacks
		bytes32 digest = keccak256(challengeNumber, msg.sender, nonce);

		//the challenge digest must match the expected
		if (digest != challenge_digest) 
			revert();

		//the digest must be smaller than the target
		if(uint256(digest) > discountedMiningTarget(msg.sender)) 
			revert();

		//only allow one reward for each challenge
		bytes32 solution = solutionForChallenge[challengeNumber];
		solutionForChallenge[challengeNumber] = digest;
		if(solution != 0x0) 
			revert();  //prevent the same answer from awarding twice

		uint reward_amount = _BLOCK_REWARD;

		balances[msg.sender] = balances[msg.sender].add(reward_amount);

        tokensMinted = tokensMinted.add(reward_amount);
        
		assert(tokensMinted <= _totalSupply);
	
		_startNewMiningEpoch();

		emit Mint(msg.sender, reward_amount, epochCount, challengeNumber);

		return true;
	}

    //a new &#39;block&#39; to be mined
    function _startNewMiningEpoch() internal {
		epochCount = epochCount.add(1);

		//every so often, readjust difficulty. Dont readjust when deploying
		if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
			_reAdjustDifficulty();
		
		//make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
		//do this last since this is a protection mechanism in the mint() function
		challengeNumber = block.blockhash(block.number - 1);
    }

    function _reAdjustDifficulty() internal {

        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;

        //we want miners to spend 10 minutes to mine each &#39;block&#39;, about 60 ethereum blocks = one POWA epoch
        uint targetEthBlocksPerDiffPeriod = _TARGET_EPOCH_PER_PEDIOD; //should be X times slower than ethereum

        //if there were less eth blocks passed in time than expected
        if(ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod)
        {
			uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div(ethBlocksSinceLastDifficultyPeriod);
			uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
		
			//make it harder
			miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %
        }else{
			uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div(targetEthBlocksPerDiffPeriod);
			uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

			//make it easier
			miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));  //by up to 50 %
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
        return _MAXIMUM_TARGET.div(miningTarget);
    }

	function getMiningTarget() public constant returns (uint) {
		return miningTarget;
	}
	
    function discountedMiningTarget(address solver) public constant returns (uint256 discountedDiff) {
        // the number of coins owned
        uint256 minerBalance = uint256(balanceOf(solver));
         
        if(minerBalance <= 2 * _BLOCK_REWARD)
            return getMiningTarget();
            
        // the number of full block rewards owned
        uint256 minerDiscount = uint256(minerBalance.div(_BLOCK_REWARD));
            
        discountedDiff = miningTarget.mul(minerDiscount.mul(minerDiscount));
        
        if(discountedDiff > _MAXIMUM_TARGET) //very easy
            discountedDiff = _MAXIMUM_TARGET;
      
        return discountedDiff;
    }
    
    function discountedMiningDifficulty(address solver) public constant returns (uint256 discountedDiff) {
        return _MAXIMUM_TARGET.div(discountedMiningTarget(solver));
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
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
    // - 0 value transfers are not allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != 0);
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
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}