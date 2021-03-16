/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.4.26;   

// SPDX-License-Identifier: MIT


// An ERC20 token that is mined using PoW through a SmartContract
// No pre-mine
// No ICO
 
// Difficulty target auto-adjusts with PoW hashrate
// Rewards decrease as more tokens are minted
// Compatible with all services that support ERC20 tokens


// Source:  https://en.bitcoinwiki.org/wiki/ERC20



/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/



// ----------------------------------------------------------------------------

// 'ASSANAT Token' contract

// Mineable ERC20 Token using Proof Of Work 

//

// Symbol      : ASSANAT 

// Name        : ASSANAT Token

// Total supply: 10000000000 00000000

// Decimals    : 0  

//




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


    constructor() public {

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

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

// ----------------------------------------------------------------------------


contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function totalSupply() public constant returns (uint256);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);  
    

}   




// ---------------------------------------------------------------------------


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
// -----------------------------------------------------------------------------------------------------

// SafeMath library

// -----------------------------------------------------------------------------------------------------

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag. 
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator. 
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
    
    
}



library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b; 

        return a;

    }
}



contract ASSANAT is EIP20Interface, Owned { 
    
    using SafeMath for uint256; 
    using ExtendedMath for uint;
    
    
    
    uint public epochCount;  // number of 'blocks' mined
    
    uint public latestDifficultyPeriodStarted;
    
    uint public _BLOCKS_PER_READJUSTMENT = 1024;
    
    // a little number
    uint public  _MINIMUM_TARGET = 2**16;  // 
    
    //a big number is easier; just find a solution that is smaller
    //uint public  _MAXIMUM_TARGET = 2**224;  bitcoin uses 224
    uint public _MAXIMUM_TARGET = 2**234;
    
    uint public miningTarget;
    
    bytes32 public challengeNumber;     //generate a new one when a new reward is minted
    
    

    uint public rewardEra;
    uint public maxSupplyForEra;

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber; //
    
    bool locked = false; 
    
    mapping(bytes32 => bytes32) solutionForChallenge;
    
    uint public tokensMinted;           // Total amount currently mined 
    
    // Balances for each account
    mapping (address => uint256) public balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping (address => uint256)) public allowed;
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    
    
    /*
    NOTE: 
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks  
    string public symbol;                 //An identifier: eg SBX
    uint8 public decimals;                //How many decimals to show.
    uint public _totalSupply;             


    constructor (
        
    ) public onlyOwner() {
        symbol = "ASSANAT";                                    // Set the symbol for display purposes
        name = "ASSANAT";                                    // Set the name for display purposes
        decimals = 8;                                       // Amount of decimals for display purposes
        _totalSupply =  10000000000 * 10**uint(decimals) ;     // Update total supply
        
        balances[msg.sender] = 10000000000;                // Give  the creator all initial tokens
        
        if(locked) revert();  
        locked = true;
        
        tokensMinted = 0;       
        rewardEra = 0;
        maxSupplyForEra = _totalSupply.div(2);
        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        
        _startNewMiningEpoch();
        
        //The owner gets nothing! You must mine this ERC20 token
        //balances[owner] = _totalSupply;
        //Transfer(address(0), owner, _totalSupply);
        
    }
    
    
    
    // How does it work?
    // Typically, ERC20 tokens will grant all tokens to the owner or will have an ICO 
    // and demand that large amounts of Ether be sent to the owner. 
    // Instead of granting tokens to the 'contract owner', 
    // all ASSANAT tokens are locked within the smart contract initially. 
    // These tokens are dispensed, 50 at a time, by calling the function 'mint' and using Proof of Work, 
    // just like mining bitcoin. Here is what that looks like :
    
    /* Mint new coins by sending ether, ( this function used to buy coins )  */
    function mint(uint256 nonce, bytes32 challenge_digest ) public returns ( bool success ) {
        //the PoW must contain work that includes
        // a recent ethereum block hash 
        // (challenge number) and 
        // the msg.sender's address to prevent 
        // MITM attacks
        
        bytes32 digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

        // the challenge digest must match the expected
        if( digest != challenge_digest ) revert();
        
        //the digest must be smaller than the target
        if(uint256(digest) > miningTarget ) revert();

        //only allow one reward for each challenge
        bytes32 solution = solutionForChallenge[challengeNumber];
        solutionForChallenge[challengeNumber] = digest;
        
        //prevent the same answer from awarding twice
        if( solution != 0x0 ) revert(); 

        uint reward_amount = getMiningReward();
         
        balances[msg.sender] = balances[msg.sender].add(reward_amount);
        
        tokensMinted = tokensMinted.add(reward_amount);
        
        //Cannot mint more tokens than there are
        assert( tokensMinted <= maxSupplyForEra );
        
        //set readonly diagnostics data
        lastRewardTo = msg.sender;
        lastRewardAmount = reward_amount;
        lastRewardEthBlockNumber= block.number;
        
        _startNewMiningEpoch();
        
        /* Notify anyone listening that the minting took place */
        emit Mint(msg.sender, reward_amount, epochCount, challengeNumber); 
        
        return true;

     }
     
    //  As you can see, a special number called a 'nonce' has to be passed 
    //  into this function in order for tokens to be dispensed. This number 
    //  has to fit a special 'puzzle' similar to a sudoku puzzle, 
    //  and this is called Proof of Work. To find this special number, 
    //  it is necessary to run a mining program. 
    
    
    // a new 'block' to be mined !!
    function _startNewMiningEpoch() internal {
        
    // if max supply for the era will be exceeded next
    // reward round then enter the new era before that happens
    // 40 is the final reward era, almost all tokens minted
    // once the final era is reached, more tokens will not be given out because the asset function 
     
       if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39 ){
           rewardEra += 1; 
       }
       
       // set the next minted supply at which the era will change 
       // total supply is 10000000000 00000000  because of 8 decimal places
       
        maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1) );
        
        epochCount = epochCount.add(1);
        
        // every so often, readjust difficulty. don't readjust when deploying.
        
        if( epochCount % _BLOCKS_PER_READJUSTMENT == 0 ){
            _reAdjustDifficulty();
        }
        
        //make the latest ethereum block hash
        // a part of the next challenge for PoW to prevent pre-mining future blocks
        
        //do this last since this is a protection mechanism 
        // in the mint() function
    
        challengeNumber = blockhash( block.number - 1 );
        


    }
    
    
    // -----------------------------------------------------------------------------------------------------

    // What is "difficulty"?
    
    // Difficulty is a measure of how difficult it is to find a hash below a given target.
    // The Bitcoin network has a global block difficulty. 
    // Valid blocks must have a hash below this target. 
    // Mining pools also have a pool-specific share difficulty setting a lower limit for shares.
    
    // -----------------------------------------------------------------------------------------------------
    
    //https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
    //as of 2017 the bitcoin difficulty was up to 17 zeroes, it was only 8 in the early days

    // The contract auto-adjusts difficulty
    
    //readjust the target by 5 percent
    function _reAdjustDifficulty() internal {
        
        // When the difficulty adjustment period is reached, 
        // check how many block numbers there were 
        // (usually 360 blocks per hour (3600s / 10s))
        
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour

        //we want miners to spend 10 minutes to mine each 'block', 
        // about 60 ethereum blocks = one ( ASSANAT ) epoch
        uint epochsMined = _BLOCKS_PER_READJUSTMENT; //256

        // BTC generates one block every 10 minutes,
        // Ethereum creates 60 blocks, so multiply by 60
        // (Bitcoin is 1024 blocks, but in Ethereum there
        // are as many blocks multiplied by 60)
        
        uint targetEthBlocksPerDiffPeriod = epochsMined * 60; //should be 60 times slower than ethereum

        //if there were less eth blocks passed in time than expected
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );

          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
          // If there were 5% more blocks mined than expected then this is 5.
          // If there were 100% more blocks mined than expected then this is 100.

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
    
    
    // this is a recent ethereum block hash,
    // used to prevent pre-mining future blocks
    function getChallengeNumber() public constant returns (bytes32) {
        
        return challengeNumber;
    }
    
    
    // the number of zeroes the digest
    // of the PoW solution requires.  Auto adjusts .
    function getMiningDifficulty() public constant returns (uint)  {
        return _MAXIMUM_TARGET.div(miningTarget);
    }
       
       
    function getMiningTarget() public constant returns (uint)  {
        return miningTarget;
    } 
    
    
    //21m coins total
    //reward begins at 50 and is cut in half every reward era (as tokens are mined)
    function getMiningReward() public constant returns (uint) {
         //once we get half way thru the coins, only get 25 per block

         //every reward era, the reward amount halves.

         return (50 * 10**uint(decimals) ).div( 2**rewardEra );

    }
    
    
    // help debug mining software !!
    function getMintDigest(uint256 nonce, bytes32 challenge_number) public view returns (bytes32 digesttest) {

        bytes32 digest = keccak256(abi.encodePacked(challenge_number, msg.sender, nonce));
        
        return digest;

    }
    
    
    // help debug mining software !!
    function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

        bytes32 digest = keccak256(abi.encodePacked(challenge_number, msg.sender, nonce));
            
        if( uint256(digest) > testTarget ) revert();
        
        return ( digest == challenge_digest );

    } 
    
    
    
    // ------------------------------------------------------------------------

    // Total supply

    // ------------------------------------------------------------------------

    function totalSupply() public constant returns (uint256) {

        return _totalSupply - balances[address(0)]; 

    }
    

    // Send coins to another address 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);  // (Person balance) Check if the sender has enough
         
        // require(balances[_to] + _value >= balanceOf[_to]);    // ( recive balance )  Check for overflows
        
        // balances[msg.sender] -= _value;         // Subtract from the sender
        
        balances[msg.sender] = balances[msg.sender].sub(_value);         // Subtract from the sender
        
        // balances[_to] += _value;                // Add the same to the recipient 
        
        balances[_to] = balances[_to].add(_value);                // Add the same to the recipient
        
        //  updateSupply();
         
        /* Notify anyone listening that the transfer took place */
        
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    // transfers coins from this address to another address
    
    // Send `tokens` amount of tokens from address `from` to address `to`
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        
        require(balances[_from] >= _value && allowance >= _value && _value > 0); 
        
        // balances[_from] -= _value;
        
        balances[_from] = balances[_from].sub(_value);
        
        // balances[_to] += _value;
        
        balances[_to] = balances[_to].add(_value);
        
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    
    // Get the token balance for account `tokenOwner`
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // this funtion, we approve another address to spend a certain amount of our tokens !!
     
     
    // Allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);    //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
    
    
    // -------------------------------------------------------------------------------
    
    // Token owner can approve for ` spender ` to transferFrom (....) ` tokens `
    
    // from the token owner's account. the ` spender `  contract function
    
    // `receiveApproval(...)` is then executed
    
    
    // -------------------------------------------------------------------------------
    
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns ( bool success ) {
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    
    function () public payable {
        revert();
    }
     
    
     // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------


    function transferAnyERC20Token(address tokenAddress, uint tokens ) public onlyOwner returns ( bool success ) {
        
        return EIP20Interface(tokenAddress).transfer(owner, tokens);
        
    }

    
}