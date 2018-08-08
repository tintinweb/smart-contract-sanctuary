pragma solidity ^0.4.18;


// ----------------------------------------------------------------------------

// &#39;0xLitecoin Token&#39; contract

// Mineable ERC20 Token using Proof Of Work



/*

the idea is that the miner uses proxyMergeMint in https://github.com/snissn/0xlitecoin-token/blob/master/contracts/MintHelper.sol#L189 
to call parent::mint() and then this::merge() in the same transaction

*/

//

// Symbol      : 0xLTC

// Name        : 0xLitecoin Token

// Total supply: 4*21,000,000.00

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


contract ERC918Interface {
  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
  address public lastRewardTo;
  uint public lastRewardAmount;
  uint public lastRewardEthBlockNumber;
  bytes32 public challengeNumber;



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

        OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}



// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and an

// initial fixed supply

// ----------------------------------------------------------------------------

contract _0xLitecoinToken is ERC20Interface, Owned {

    using SafeMath for uint;
    using ExtendedMath for uint;


    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;

    address parentAddress;


     uint public latestDifficultyPeriodStarted;



    uint public epochCount;//number of &#39;blocks&#39; mined


    // the goal is for 0xLitecoin to be mined with 0xBTC

    uint public _BLOCKS_PER_READJUSTMENT = 1024;


    //a little number
    uint public  _MINIMUM_TARGET = 2**16; // TODO increase this before deploying


      //a big number is easier ; just find a solution that is smaller
    //uint public  _MAXIMUM_TARGET = 2**224;  Litecoin uses 224
    uint public  _MAXIMUM_TARGET = 2**234;


    uint public miningTarget;

    bytes32 public challengeNumber;   //generate a new one when a new reward is minted



    uint public rewardEra;
    uint public maxSupplyForEra;


    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    bool locked = false;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;

    mapping(address => uint) balances;


    mapping(address => mapping(address => uint)) allowed;


    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    function _0xLitecoinToken() public onlyOwner{



        symbol = "0xLTC";

        name = "0xLitecoin Token";

        decimals = 8;

        _totalSupply = 4*21000000 * 10**uint(decimals);

        if(locked) revert();
        locked = true;

        tokensMinted = 0;

        rewardEra = 0;
        maxSupplyForEra = _totalSupply.div(2);

        miningTarget = 27938697607979437428382017032425071986904332731688489302005732; // from 0xBitcoin as of block 5902249

        latestDifficultyPeriodStarted = block.number;

        _startNewMiningEpoch();

        parentAddress = 0xb6ed7644c69416d67b522e20bc294a9a9b405b31;



        //The owner gets nothing! You must mine this ERC20 token
        //balances[owner] = _totalSupply;
        //Transfer(address(0), owner, _totalSupply);

    }




        function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {


            //the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender&#39;s address to prevent MITM attacks
            bytes32 digest =  keccak256(challengeNumber, msg.sender, nonce );

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




        function merge() public returns (bool success) {

            // the idea is that the miner uses https://github.com/0xbitcoin/mint-helper/blob/master/contracts/MintHelper.sol 
            // to call mint() and then mergeMint() in the same transaction



            // hard code a reference to the "Parent" ERC918 Contract ( in this case 0xBitcoin)
            // Verify that the Parent contract was minted in this block, by the same person calling this contract
            // then followthrough with the resulting mint logic
            // don&#39;t call revert, but return true or false based on success
            // this method shouldn&#39;t revert because it will be calleed in the same transaction as a "Parent" mint attempt

            //ensure that mergeMint() can only be called once per Parent::mint()
            //do this by ensuring that the "new" challenge number from Parent::challenge post mint can be called once
            //and that this block time is the same as this mint, and the caller is msg.sender


            //only allow one reward for each challenge
            // do this by calculating what the new challenge will be in _startNewMiningEpoch, and verify that it is not that value
            // this checks happen in the local contract, not in the parent

            bytes32 future_challengeNumber = block.blockhash(block.number - 1);
            if(challengeNumber == future_challengeNumber){
                return false; // ( this is likely the second time that mergeMint() has been called in a transaction, so return false (don&#39;t revert))
            }

            //verify Parent::lastRewardTo == msg.sender;
            if(ERC918Interface(parentAddress).lastRewardTo() != msg.sender){
                return false; // a different address called mint last so return false ( don&#39;t revert)
            }
            
            //verify Parent::lastRewardEthBlockNumber == block.number;

            if(ERC918Interface(parentAddress).lastRewardEthBlockNumber() != block.number){
                return false; // parent::mint() was called in a different block number so return false ( don&#39;t revert)
            }

            //we have verified that _startNewMiningEpoch has not been run more than once this block by verifying that
            // the challenge is not the challenge that will be set by _startNewMiningEpoch
            //we have verified that this is the same block as a call to Parent::mint() and that the sender
            // is the sender that has called mint

            //so now we may safely run the relevant logic to give an award to the sender, and update the contract

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

              Mint(msg.sender, reward_amount, epochCount, 0 ); // use 0 to indicate a merge mine

           return true;

        }



    //a new &#39;block&#39; to be mined
    function _startNewMiningEpoch() internal {

      //if max supply for the era will be exceeded next reward round then enter the new era before that happens

      //40 is the final reward era, almost all tokens minted
      //once the final era is reached, more tokens will not be given out because the assert function
      if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39)
      {
        rewardEra = rewardEra + 1;
      }

      //set the next minted supply at which the era will change
      // total supply is 4*2100000000000000  because of 8 decimal places
      maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));

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




    //https://en.Litecoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
    //as of 2017 the Litecoin difficulty was up to 17 zeroes, it was only 8 in the early days

    //readjust the target by 5 percent
    function _reAdjustDifficulty() internal {


        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour

        //we want miners to spend 15 minutes to mine each &#39;block&#39;, about 60 ethereum blocks = one 0xLitecoin epoch = one 0xBitcoin
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



    //4*21m coins total
    //reward begins at 4*25 and is cut in half every reward era (as tokens are mined)
    function getMiningReward() public constant returns (uint) {
        //once we get half way thru the coins, only get 25 per block

         //every reward era, the reward amount halves.

         return (4*25 * 10**uint(decimals) ).div( 2**rewardEra ) ;

    }

    //help debug mining software
    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);

        return digest;

      }

        //help debug mining software
      function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

          bytes32 digest = keccak256(challenge_number,msg.sender,nonce);

          if(uint256(digest) > testTarget) revert();

          return (digest == challenge_digest);

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

        Transfer(msg.sender, to, tokens);

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

        Approval(msg.sender, spender, tokens);

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

        Transfer(from, to, tokens);

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

        Approval(msg.sender, spender, tokens);

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