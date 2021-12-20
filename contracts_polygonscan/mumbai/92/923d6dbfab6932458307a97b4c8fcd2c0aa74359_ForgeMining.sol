/**
 *Submitted for verification at polygonscan.com on 2021-12-19
*/

// Forge - Proof of Work Mining Contract
// Distrubtion of Forge Token is as follows:
// 25% of Forge Token is Auctioned in the ForgeAuctions Contract which distributes tokens to users who use Fantom to buy tokens in fair price. auctions that last 4 days. Using the Auctions contract
// +
// 25% of Forge Token is distributed as Liquidiy Pool rewards in the ForgeRewards Contract which distributes tokens to users who deposit the SpiritSwap Liquidity Pool tokens into the LPRewards contract.
// +
// 50% of Forge Token is distributed using ForgeMining Contract(this Contract) which distributes tokens to users by using GPUs/FPGAs to solve a complicated problem to gain tokens!
//
// = 100% Of the Token is distributed to the users! No dev fee or premine!
//
// All distributions happen fairly using Bitcoins model of distribution for over 100+ years, on-chain, decentralized, trustless, ownerless contracts!
//
// Network: Optimstic Ethereum 
// ChainID = 10
//
//
// Name: Forge
// Symbol: Frg
// Decimals: 18 
//
// Total supply: 42,000,001.000000000000000000(Of Kovan Forge)
//   =
// 21,000,000 Mined over 100+ years using Bitcoins Distrubtion halvings every 4 years. Uses Proof-oF-Work to distribute the tokens. Public Miner is available.  Uses this contract.
//   +
// 10,500,000 Auctioned over 100+ years into 4 day auctions split fairly among all buyers. ALL 0xBitcoin proceeds go into THIS contract which it fairly distributes to miners.  Uses the ForgeAuctions contract
//   +
// 10,500,000 tokens goes to Liquidity Providers of the token over 100+ year using Bitcoins distribution!  Helps prevent LP losses!  Uses the ForgeRewards Contract
//
//  =
//
// 42,000,001 Tokens is the MAX Supply EVER.  Will never be more!
//      
// 66% of the 0xBitcoin Token from this contract goes to the Miner to pay for the transaction cost and if the token grows enough earn 0xBitcoin per mint!!
// 33% of the 0xBitcoin TOken from this contract goes to the Liquidity Providers via ForgeRewards Contract.  Helps prevent Impermant Loss! Larger Liquidity!
//
// No premine, dev cut, or advantage taken at launch. Public miner available at launch.  100% of the token is given away fairly over 100+ years using Bitcoins model!
//
// Send this contract any ERC20 token and it will become instantly mineable and able to distribute using proof-of-work for 1 year!!!!
//
//Viva la Mineables!!! Send this contract any ERC20 complient token (Wrapped NFTs incoming!) and we will fairly to miners and Holders(
//  Each Mint prints (1/10000) of any ERC20.
//pThirdDifficulty allows for the difficulty to be cut in a third.  So difficulty 10,000 becomes 3,333.  Costs 333 Fantom  Makes mining 3x easier
//* 1 tokens in LP are burned to create the LP pool.
//
// Credits: 0xBitcoin, Vether, Synethix


pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) internal onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}




library IsContract {
    function isContract(address _addr) internal view returns (bool) {
        bytes32 codehash;
        /* solium-disable-next-line */
        assembly { codehash := extcodehash(_addr) }
        return codehash != bytes32(0) && codehash != bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}

// File: contracts/utils/SafeMath.sol

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}

// File: contracts/utils/Math.sol

library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}

// File: contracts/interfaces/IERC20.sol

interface IERC20 {
	function totalSupply() external view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    
}


// File: contracts/commons/AddressMinHeap.sol



abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


//Main contract

contract ForgeMining is Ownable, IERC20, ApproveAndCallFallBack {

// SUPPORTING CONTRACTS
    address public AddressAuction;
    address public AddressLPReward;
    address public AddressZeroXBTC;
//Events
    using SafeMath for uint256;
    using ExtendedMath for uint;
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
    event MegaMint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber, uint NumberOfTokensMinted);

// Managment events
    uint256 override public totalSupply = 42000001000000000000000000;
    bytes32 private constant BALANCE_KEY = keccak256("balance");

    //BITCOIN INITALIZE Start
	
    uint _totalSupply = 21000000000000000000000000;
    uint public latestDifficultyPeriodStarted2 = block.timestamp;
    uint public epochCount = 0;//number of 'blocks' mined

    uint public _BLOCKS_PER_READJUSTMENT = 512;

    //a little number
    uint public  Z_MINIMUM_TARGET = 2**2;
    
    uint public  Z_MAXIMUM_TARGET = 2**16;
    uint public miningTarget = Z_MAXIMUM_TARGET.div(200000000000*25);  //1000 million difficulty to start until i enable mining
    
    bytes32 public challengeNumber;   //generate a new one when a new reward is minted
    uint public rewardEra = 0;
    uint public maxSupplyForEra = (_totalSupply - _totalSupply.div( 2**(rewardEra + 1)));
    uint public reward_amount = (150 * 10**uint(decimals) ).div( 2**rewardEra );
    //Stuff for Functions
    uint256 oldecount = 0;
    uint256 oneEthUnit =    1000000000000000000;
    uint256 one8unit   =              100000000;
    uint256 public Token2Per=         100000000;
    uint256 Token2Min=                100000000;
    mapping(bytes32 => bytes32) solutionForChallenge;
    uint public tokensMinted;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) Token_balances;
    uint give0xBTC = 0;
    uint give = 1;
    // metadata
    string public name = "Forge";
    string public constant symbol = "Fge";
    uint8 public constant decimals = 18;

    bool inited = false;
    function zinit(address AuctionAddress2, address payable LPGuild2, address _ZeroXBTCAddress) external onlyOwner{
        uint x = 21000000000000000000000000 / 2; //half supply for LP Mine and Burn
        // Only init once
        assert(!inited);
        inited = true;

        
        _totalSupply = 21000000 * 10**uint(16);
    	//bitcoin commands short and sweet //sets to previous difficulty
    	miningTarget = Z_MAXIMUM_TARGET.div(500); //5000000 = 31gh/s @ 7 min for FPGA mining, 2000000 if GPU only
    	rewardEra = 0;
        //latestDifficultyPeriodStarted2 = block.timestamp;
    	
    	_startNewMiningEpoch();
    	tokensMinted = reward_amount * epochCount;
    	
    	
        // Init contract variables and mint
        balances[AuctionAddress2] = x;
        emit Transfer(address(0), AuctionAddress2, x);
    	AddressAuction = AuctionAddress2;
	
        AddressLPReward = payable(LPGuild2);
        AddressZeroXBTC = _ZeroXBTCAddress;
        oldecount = epochCount;
        // mint 1 token to setup LPs
        balances[msg.sender] = 100000000;
        emit Transfer(address(0), msg.sender, 100000000);
        
        
        
    }

    ///
    // Managment
    ///
    // first
    


function ARewardSender() public {
    //runs every _BLOCKS_PER_READJUSTMENT / 4
    uint256 epochsPast = epochCount - oldecount; //actually epoch
    tokensMinted.add(reward_amount * epochsPast);
    reward_amount = (150 * 10**uint(decimals)).div( 2**rewardEra );
    
    balances[AddressLPReward] = balances[AddressLPReward].add((reward_amount * epochsPast) / 2);
    if(IERC20(AddressZeroXBTC).balanceOf(address(this)) > (4 * (Token2Per * _BLOCKS_PER_READJUSTMENT)/4)) // at least enough blocks to rerun this function for both LPRewards and Users
    {
        give0xBTC = 1 * give;
        IERC20(AddressZeroXBTC).transfer(AddressLPReward, ((epochsPast) * Token2Per)/2);
    }
    else{
        give0xBTC = 0;
    }
    oldecount = epochCount; //actually epoch
}

//Mints to the payee Forge, 0xBitcoin always to the sender. Making it the heaviest currency in here.
function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
            bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

            //the challenge digest must match the expected
            require(digest == challenge_digest, "Old challenge_digest or wrong challenge_digest");

            //the digest must be smaller than the target
            require(uint256(digest) < miningTarget, "Digest must be smaller than miningTarget");
                
	        bytes32 solution = solutionForChallenge[challengeNumber];
            require(solution == 0x0,"This Challenge was alreday mined by someone else");  //prevent the same answer from awarding twice
	        solutionForChallenge[challengeNumber] = digest;

            //set readonly diagnostics data

             _startNewMiningEpoch();
            balances[msg.sender] = balances[msg.sender].add(reward_amount);
            if(give0xBTC > 0){
            IERC20(AddressZeroXBTC).transfer(msg.sender, Token2Per*give0xBTC);
            }
            emit Mint(msg.sender, reward_amount, epochCount, challengeNumber );
           return true;
}


//First address for mintSend(Forge + 0xBitcoin), Second address+ for other tokens
// REPALCE WITH LINE BELOW in production
//function mintExtrasTokenMintTo(uint256 nonce, bytes32 challenge_digest, address[] memory ExtraFunds, address[] memory MintTo) public returns (bool success) {
function mintTokensArrayTo(uint256 nonce, bytes32 challenge_digest, address[] memory ExtraFunds, address[] memory MintTo) public returns (bool success) {
        require(MintTo.length == ExtraFunds.length + 1,"So MintTo has to have same number of addressses as ExtraFunds");
       for(uint x=0; x< ExtraFunds.length; x++)
        {
        require(ExtraFunds[x] != address(this) && ExtraFunds[x] != AddressZeroXBTC, "No base printing of tokens");
        
            for(uint y=1; y< ExtraFunds.length; y++){
                require(ExtraFunds[y] != ExtraFunds[x] || x == y, "No printing The same tokens");
            }

    }
    uint savex=0;
    for(uint x=0; x<ExtraFunds.length; x++)
    {
        //exponentialy more valueable
if(epochCount % (2**(x+1)) == 0){
uint256 TotalOwned = IERC20(ExtraFunds[x]).balanceOf(address(this));
    if(TotalOwned != 0)
    {
        uint256 totalOwed = 0;
        if( x % 3 == 0 && x != 0){
            totalOwed = (TotalOwned).divRound(10000);
        }
        else{
            totalOwed = (TotalOwned).div(10000);  //10000 was chosen to give each token a ~a year per token of distribution using Proof-of-Work
        }
        //Keep the NFTs for miners hard to split with rewards, 25% to LPers
        if(TotalOwned > 210005){
            IERC20(ExtraFunds[x]).transfer(AddressLPReward, totalOwed.div(3));
            IERC20(ExtraFunds[x]).transfer(MintTo[x], totalOwed);
        }
        else{
            IERC20(ExtraFunds[x]).transfer(MintTo[x], totalOwed);
        }
    }
    savex = x;
    }
				
        
    }
    
    require(mint(nonce,challenge_digest), "mint issue");
    emit MegaMint(msg.sender, reward_amount, epochCount, challengeNumber, savex );
    return true;
}
    


function mintTokensSameAddress(uint256 nonce, bytes32 challenge_digest, address[] memory ExtraFunds, address MintTo) public returns (bool success) {
        address[] memory dd = new address[](ExtraFunds.length + 1); 
        uint y=0;
        for(uint x=0; x< (ExtraFunds.length + 1); x++)
        {
            dd[x] = MintTo;
        }
        mintTokensArrayTo(nonce, challenge_digest, ExtraFunds, dd);
        return true;
}



function _startNewMiningEpoch() internal {
        
 
      //if max supply for the era will be exceeded next reward round then enter the new era before that happens

      //40 is the final reward era, almost all tokens minted
      //once the final era is reached, more tokens will not be given out because the assert function
      if( tokensMinted.add((150 * 10**uint(decimals) ).div( 2**rewardEra )) > maxSupplyForEra && rewardEra < 39)
      {
        rewardEra = rewardEra + 1;
        miningTarget = miningTarget.div(31);
        
      }

      //set the next minted supply at which the era will change
      // total supply of MINED tokens is 21000000000000000000000000  because of 16 decimal places

      epochCount = epochCount.add(1);

      //every so often, readjust difficulty. Dont readjust when deploying
    if((epochCount) % (_BLOCKS_PER_READJUSTMENT / 4) == 0)
    {
        ARewardSender();
		maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));

    if((epochCount % _BLOCKS_PER_READJUSTMENT== 0))
    {
         if(( IERC20(AddressZeroXBTC).balanceOf(address(this)) / Token2Per) <= 10000)
         {
             if(Token2Per.div(2) > Token2Min)
             {
             Token2Per = Token2Per.div(2);
            }
         }
         else
         {
             Token2Per = Token2Per.mult(3);
         }
         
        _reAdjustDifficulty();
    }
    }

    challengeNumber = blockhash(block.number - 1);
}




    //https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
    //as of 2017 the bitcoin difficulty was up to 17 zeroes, it was only 8 in the early days

    function _reAdjustDifficulty() internal {

        uint256 blktimestamp = block.timestamp;
        uint ethBlocksSinceLastDifficultyPeriod2 = blktimestamp - latestDifficultyPeriodStarted2;

        uint epochsMined = _BLOCKS_PER_READJUSTMENT; //256

        uint targetTime = 60*36; //36 min per block 60 sec * 12
	
        if( ethBlocksSinceLastDifficultyPeriod2 > (targetTime*3).div(2) && give != 2 )
	{
		give = 2;
	}
	else if(give != 1)
	{
		give = 1;
	}
        //if there were less eth blocks passed in time than expected
        if( ethBlocksSinceLastDifficultyPeriod2 < targetTime )
        {
          uint excess_block_pct = (targetTime.mult(100)).div( ethBlocksSinceLastDifficultyPeriod2 );

          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
          // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.

          //make it harder
          miningTarget = miningTarget.sub(miningTarget.div(2000).mult(excess_block_pct_extra));   //by up to 50 %
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod2.mult(100)).div( targetTime );

          uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000
          //make it easier
          miningTarget = miningTarget.add(miningTarget.div(2000).mult(shortage_block_pct_extra));   //by up to 50 %
        }


        latestDifficultyPeriodStarted2 = blktimestamp;

        if(miningTarget < Z_MINIMUM_TARGET) //very difficult
        {
          miningTarget = Z_MINIMUM_TARGET;
        }

        if(miningTarget > Z_MAXIMUM_TARGET) //very easy
        {
          miningTarget = Z_MAXIMUM_TARGET;
        }
    }


    //42 m coins total
    // = 
    //21 million proof of work
    // + 
    //10.5 million proof of burn
    // +
    //10.5 million rewards for Liquidity Providers




        //help debug mining software
     function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

        bytes32 digest = bytes32(keccak256(abi.encodePacked(challenge_number,msg.sender,nonce)));

        if(uint256(digest) > testTarget) revert();

        return (digest == challenge_digest);
        }
		
		

    //this is a recent ethereum block hash, used to prevent pre-mining future blocks
    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    //the number of zeroes the digest of the PoW solution requires.  Auto adjusts
     function getMiningDifficulty() public view returns (uint) {
        return Z_MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public view returns (uint) {
       return miningTarget;
   }



    //21m coins total
    //reward begins at 150 and is cut in half every reward era (as tokens are mined)
    function getMiningReward() public view returns (uint) {
        //once we get half way thru the coins, only get 25 per block

         //every reward era, the reward amount halves.

         return (150 * 10**uint(decimals) ).div( 2**rewardEra ) ;

    }


    //21m coins total
    //reward begins at 150 and is cut in half every reward era (as tokens are mined)
    function getEpoch() public view returns (uint) {
        //once we get half way thru the coins, only get 25 per block

         //every reward era, the reward amount halves.

         return epochCount ;

    }





    //help debug mining software
    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

            bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

        return digest;

      }



    // ------------------------------------------------------------------------

    // Total supply

    // ------------------------------------------------------------------------





    // ------------------------------------------------------------------------

    // Get the token balance for account `tokenOwner`

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public override view returns (uint balance) {

        return balances[tokenOwner];

    }



    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to `to` account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public override returns (bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account

    //

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

    // recommends that there are no checks for the approval double-spend attack

    // as this should be implemented in user interfaces

    // ------------------------------------------------------------------------

    function approve(address spender, uint tokens) public override returns (bool success) {

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

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {

        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(from, to, tokens);

        return true;

    }


    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }



    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account. The `spender` contract function

    // `receiveApproval(...)` is then executed

    // ------------------------------------------------------------------------

    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public override{
      require(token == address(this));
      
       IERC20(address(this)).transfer(from, tokens);  
    }
    




        
}