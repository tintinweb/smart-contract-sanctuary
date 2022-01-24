/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// Forge - Proof of Work Mining Contract
// MUST REMOVE AOPENMINT
// Distrubtion of Forge Token is as follows:
// 25% of Forge Token is Auctioned in the ForgeAuctions Contract which distributes tokens to users who use 0xBitcoin to buy tokens in fair price. Each auction lasts ~3 days. Using the Auctions contract
// +
// 25% of Forge Token is distributed as Liquidiy Pool rewards in the ForgeRewards Contract which distributes tokens to users who deposit the SpiritSwap Liquidity Pool tokens into the LPRewards contract.
// +
// 50% of Forge Token is distributed using ForgeMining Contract(this Contract) which distributes tokens to users by using GPUs/FPGAs to solve a complicated problem to gain tokens!  Uses this contract
//
// = 100% Of the Token is distributed to the users! No dev fee or premine!
//
// All distributions happen fairly using Bitcoins model of distribution for over 100+ years, on-chain, decentralized, trustless, ownerless contracts!
//   The harder it is mined the less tokens that are awarded.
// Network: Polygon Chain 
// ChainID = 89
//
//
// Name: Forge
// Symbol: Frg
// Decimals: 18 
//
// Total supply: 42,000,001.000000000000000000
//   =
// 21,000,000 Mined over 100+ years using Bitcoins Distrubtion halvings every 4 years. Uses Proof-oF-Work to distribute the tokens. Public Miner is available.  Uses this contract.
//   +
// 10,500,000 Auctioned over 100+ years into 4 day auctions split fairly among all buyers. ALL 0xBitcoin proceeds go into THIS contract which it fairly distributes to miners.  Uses the ForgeAuctions contract
//   +
// 10,500,000 tokens goes to Liquidity Providers of the token over 100+ year using Bitcoins distribution!  Helps prevent LP losses!  Uses the ForgeRewards Contract
//
//  =
//
// 42,000,001 Tokens is the max Supply
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

library SafeMath2 {
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

library ExtendedMath2 {


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
	uint constant public targetTime = 60 * 60;
	uint256 public testx;
	uint256 public  testnum;
	uint256 public testden;
    uint256 public testxx;
    uint256 public testxy;
// SUPPORTING CONTRACTS
    address public AddressAuction;
    address public AddressLPReward;
    address public AddressZeroXBTC;
//Events
    using SafeMath2 for uint256;
    using ExtendedMath2 for uint;
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
    event MegaMint(address indexed from, uint epochCount, bytes32 newChallengeNumber, uint NumberOfTokensMinted);

// Managment events
    uint256 override public totalSupply = 42000001000000000000000000;
    bytes32 private constant BALANCE_KEY = keccak256("balance");

    //BITCOIN INITALIZE Start
	
    uint _totalSupply = 21000000000000000000000000;
    uint public latestDifficultyPeriodStarted2 = block.timestamp;
    uint public epochCount = 0;//number of 'blocks' mined

    uint public _BLOCKS_PER_READJUSTMENT = 256;

    //a little number
    uint public  _MINIMUM_TARGET = 2**16;
    
    uint public  _MAXIMUM_TARGET = 2**234;
    uint public miningTarget = _MAXIMUM_TARGET.div(200000000000*25);  //1000 million difficulty to start until i enable mining
    
    bytes32 public challengeNumber;   //generate a new one when a new reward is minted
    uint public rewardEra = 0;
    uint public maxSupplyForEra = (_totalSupply - _totalSupply.div( 2**(rewardEra + 1)));
    uint public reward_amount = (150 * 10**uint(decimals) ).div( 2**rewardEra );
    //Stuff for Functions
    uint oldecount = 0;
    uint public previousBlockTime = block.timestamp;
    uint oneEthUnit =    1000000000000000000;
    uint one8unit   =              100000000;
    uint public Token2Per=           1000000;
    uint Token2Min=                  1000000;
    mapping(bytes32 => bytes32) public solutionForChallenge;
    mapping(bytes32 => uint) public EpochForChallenge;
    mapping(uint => bytes32) public ChallengeForEpoch;
    uint public tokensMinted;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    //mapping(address => uint) Token_balances;
    uint give0xBTC = 0;
    uint give = 1;
    // metadata
    string public name = "Forge";
    string public constant symbol = "Forge";
    uint8 public constant decimals = 18;
    uint public totalLifetimes = 0;

    uint256 lastrun = block.timestamp;
    uint public latestDifficultyPeriodStarted = block.number;
    bool inited = false;
    function zinit(address AuctionAddress2, address LPGuild2, address _ZeroXBTCAddress) public onlyOwner{
        uint x = 21000000000000000000000000 / (2* (2 ** totalLifetimes)); //half supply for LP Mine and Burn
        // Only init once
        assert(!inited);
        inited = true;
	
    	rewardEra = 0;
	tokensMinted = 0;
    	miningTarget = _MAXIMUM_TARGET.div(30005); //5000000 = 31gh/s @ 7 min for FPGA mining
        latestDifficultyPeriodStarted2 = block.timestamp;
    	_startNewMiningEpoch();
	
        // Init contract variables and mint
        balances[AuctionAddress2] = x;
	
        emit Transfer(address(0), AuctionAddress2, x);
	
    	AddressAuction = AuctionAddress2;
        AddressLPReward = payable(LPGuild2);
        AddressZeroXBTC = _ZeroXBTCAddress;
	
        oldecount = epochCount;
	
        // mint 1 token to setup LPs
        balances[msg.sender] = 1000000000000000000;
	
        emit Transfer(address(0), msg.sender, 1000000000000000000);
     
    }



	///
	// Managment
	///
	//MUST REMOVE MUST REMOVE


	function zinit2(address AuctionAddress2, address LPGuild2, address _ZeroXBTCAddress) public onlyOwner{

			AddressAuction = AuctionAddress2;
			AddressLPReward = payable(LPGuild2);
			AddressZeroXBTC = _ZeroXBTCAddress;

		}


	function AOpenMint(bool nonce, bool challenge_digest) public returns (uint256 success) {


		//uint diff = block.timestamp - previousBlockTime;
		uint256 x = ((block.timestamp - previousBlockTime) * 888) / targetTime;
		uint ratio = x * 100 / 888;
		uint totalOwed = 0;
		if(ratio < 314){
			totalOwed = (( 61001200 * (x ** 2 )).div(888 ** 2)+ (40861500 * x).div(888) -  291036);
		}else {
			totalOwed = (x * 100000000).div(888) + (3500000000);
		} 


		balances[msg.sender] = balances[msg.sender].add((reward_amount * totalOwed).div(100000000));
		balances[AddressLPReward] = balances[AddressLPReward].add((reward_amount * totalOwed).div(100000000 * 2));
				
		tokensMinted = tokensMinted.add((reward_amount * totalOwed * 3).div(100000000 * 2));
		previousBlockTime = block.timestamp;

		if(give0xBTC > 0){
			if(ratio < 200){
				IERC20(AddressZeroXBTC).transfer(msg.sender, (totalOwed * Token2Per * give0xBTC).div(100000000));
			}else{
				IERC20(AddressZeroXBTC).transfer(msg.sender, (23 * Token2Per * give0xBTC).div(10));
			}
		}

		emit Mint(msg.sender, (reward_amount * totalOwed).div(100000000), epochCount, challengeNumber );

		return totalOwed;

    }
	function ARewardSender() public {
		//runs every _BLOCKS_PER_READJUSTMENT / 4

		uint256 runs = block.timestamp - lastrun;

		uint256 epochsPast = epochCount - oldecount; //actually epoch
		uint256 runsperepoch = runs / epochsPast;

		reward_amount = (150 * 10**uint(decimals)).div( 2**rewardEra );
		uint256 x = (runsperepoch * 888) / targetTime;
        testxx = x;
		uint256 ratio = x * 100 / 888;
		uint256 totalOwed;
		 if(ratio < 314){
			totalOwed = (( 61001200 * (x ** 2 )).div(888**2) + (40861500 * x).div(888) -  291036) ;
		 }else {
			totalOwed = (x * 100000000).div(888) + (3500000000);
		} 
        testxy = ((epochsPast) * totalOwed * Token2Per * give0xBTC).div(2 * 100000000);
		if(IERC20(AddressZeroXBTC).balanceOf(address(this)) > (30 * 2 * (Token2Per * _BLOCKS_PER_READJUSTMENT)/4)) // at least enough blocks to rerun this function for both LPRewards and Users
		{
			give0xBTC = 1 * give;
			IERC20(AddressZeroXBTC).transfer(AddressLPReward, ((epochsPast) * totalOwed * Token2Per * give0xBTC).div(2 * 100000000));
		}
		else{
			give0xBTC = 0;
		}
		oldecount = epochCount; //actually epoch

		lastrun = block.timestamp;
	}


	//Mints to the payee Forge, 0xBitcoin always to the sender. Making it the heaviest currency in here.
	//
	//function mint(bool nonce, bool challenge_digest) public returns (bool success) {
	function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
		mintTo(nonce, challenge_digest, msg.sender);
	}


	//function mintTo(bool nonce, bool challenge_digest,  address mintTo) public returns (bool success) {
	function mintTo(uint256 nonce, bytes32 challenge_digest,  address mintTo) public returns (uint256 owed) {

		bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

		//the challenge digest must match the expected
		require(digest == challenge_digest, "Old challenge_digest or wrong challenge_digest");

		//the digest must be smaller than the target
		require(uint256(digest) < miningTarget, "Digest must be smaller than miningTarget");
		_startNewMiningEpoch();

		require(block.timestamp > previousBlockTime, "No same second solves");

		//uint diff = block.timestamp - previousBlockTime;
		uint256 x = ((block.timestamp - previousBlockTime) * 888) / targetTime;
		uint ratio = x * 100 / 888;
		uint totalOwed = 0;
		if(ratio < 314){
			totalOwed = (( 61001200 * (x ** 2 )).div(888 ** 2)+ (40861500 * x).div(888) -  291036);
		}else {
			totalOwed = (x * 100000000).div(888) + (3500000000);
		} 


		balances[mintTo] = balances[mintTo].add((reward_amount * totalOwed).div(100000000));
		balances[AddressLPReward] = balances[AddressLPReward].add((reward_amount * totalOwed).div(100000000 * 2));
				
		tokensMinted = tokensMinted.add((reward_amount * totalOwed * 3).div(100000000 * 2));
		previousBlockTime = block.timestamp;

		if(give0xBTC > 0){
			if(ratio < 200){
				IERC20(AddressZeroXBTC).transfer(mintTo, (totalOwed * Token2Per * give0xBTC).div(100000000));
			}else{
				IERC20(AddressZeroXBTC).transfer(mintTo, (23 * Token2Per * give0xBTC).div(10));
			}
		}

		emit Mint(msg.sender, (reward_amount * totalOwed).div(100000000), epochCount, challengeNumber );

		return totalOwed;

	}


	//First address for mintSend(Forge + 0xBitcoin), Second address+ for other tokens
	// REPALCE WITH LINE BELOW in production
	//function mintTokensArrayTo(bool nonce, bool challenge_digest, address[] memory ExtraFunds, address[] memory MintTo) public returns (bool success) {
	function mintTokensArrayTo(uint256 nonce, bytes32 challenge_digest, address[] memory ExtraFunds, address[] memory MintTo) public returns (bool success) {

		uint xx = ((block.timestamp - previousBlockTime) * 888) / targetTime;
		uint ratio = xx * 100 / 888;

		require(MintTo.length == ExtraFunds.length + 1,"So MintTo has to have same number of addressses as ExtraFunds");
		uint xy=0;
		for(xy = 0; xy< ExtraFunds.length; xy++)
		{
			if(epochCount % (2**(xy+1)) != 0){
				break;
			}
			require(ExtraFunds[xy] != address(this) && ExtraFunds[xy] != AddressZeroXBTC, "No base printing of tokens");
			for(uint y=xy+1; y< ExtraFunds.length; y++){
				require(ExtraFunds[y] != ExtraFunds[xy], "No printing The same tokens");
			}
		}

		uint256 totalOwed = mintTo(nonce,challenge_digest, MintTo[0]);
		require(totalOwed > 0, "mint issue");

		for(uint x=0; x<xy; x++)
		{
			//epoch count must evenly dividable by 2^n in order to get extra mints. 
			//ex. epoch 2 = 1 extramint, epoch 4 = 2 extra, epoch 8 = 3 extra mints, epoch 16 = 4 extra mints w/ a divRound for the 4th mint(allows small balance token minting aka NFTs)
			if(epochCount % (2**(x+1)) == 0){
				uint256 TotalOwned = IERC20(ExtraFunds[x]).balanceOf(address(this));
				if(TotalOwned != 0){
					uint256 ratio = 100 *xx/888;
					if( x % 3 == 0 && x != 0){
						if(ratio < 314){
							totalOwed = (( 61001200 * (x ** 2 )).div(888 ** 2)+ (40861500 * x).div(888) -  291036) ;
							totalOwed = (TotalOwned * totalOwed).divRound(100000000 * 2500 );
						}else {
							totalOwed = (totalOwed * 100000000).div(888) + (3500000000);
							totalOwed = (TotalOwned * totalOwed).divRound(100000000 * 2500);
						}
					}else{
						if(ratio < 314){
							totalOwed = (( 61001200 * (x ** 2 )).div(888 **2)+ (40861500 * x).div(888) -  291036);
							totalOwed = (TotalOwned * totalOwed).div(100000000 * 2500 );
						}else {
							totalOwed = (totalOwed * 100000000).div(888) + (3500000000);
							totalOwed = (TotalOwned * totalOwed).div(100000000 * 2500);
						} 
				    }
			    IERC20(ExtraFunds[x]).transfer(MintTo[x], totalOwed);
			    }
            }
        }

		emit MegaMint(msg.sender, epochCount, challengeNumber, xy );

		return true;

    }


	function mintTokensSameAddress(uint256 nonce, bytes32 challenge_digest, address[] memory ExtraFunds, address MintTo) public returns (bool success) {
		address[] memory dd = new address[](ExtraFunds.length + 1); 

		for(uint x=0; x< (ExtraFunds.length + 1); x++)
		{
			dd[x] = MintTo;
		}
		
		mintTokensArrayTo(nonce, challenge_digest, ExtraFunds, dd);

		return true;
	}


	function empty_mintTo(uint256 nonce, bytes32 challenge_digest) public returns (uint256 owed) {

		bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

		//the challenge digest must match the expected
		require(digest == challenge_digest, "Old challenge_digest or wrong challenge_digest");

		//the digest must be smaller than the target
		require(uint256(digest) < miningTarget, "Digest must be smaller than miningTarget");
		_startNewMiningEpoch();

		require(block.timestamp > previousBlockTime, "No same second solves");

		previousBlockTime = block.timestamp;


		emit Mint(msg.sender, 0, epochCount, challengeNumber );

		return 0;
			   
	}


	function test(	uint256 _testx,	uint256 _testthisblk, uint256 _testlastblk ) public {

		uint256 x = ((_testthisblk - _testlastblk) * 888) / targetTime;
		testden = x;
		uint ratio = x * 100 / 888;
		uint totalOwed = 0;
		
		if(ratio < 314){
			totalOwed = (( 61001200 * (x ** 2 )).div(888 ** 2)+ (40861500 * x).div(888) -  291036);
		}else {
			totalOwed = (x * 100000000).div(888) + (3500000000);
		} 
		testx = totalOwed;	
	}


	function _startNewMiningEpoch() internal {


		//if max supply for the era will be exceeded next reward round then enter the new era before that happens

		//40 is the final reward era, almost all tokens minted
		//once the final era is reached, more tokens will not be given out because the assert function
		if( tokensMinted.add((reward_amount)) > maxSupplyForEra && rewardEra < 39)
		{
			rewardEra = rewardEra + 1;
			miningTarget = miningTarget.div(2 ** rewardEra);
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
				if(( IERC20(AddressZeroXBTC).balanceOf(address(this)) / Token2Per) <= 20000) //chosen to give keep 250 days payouts in reserve at current payout
				{
					if(Token2Per.div(2) > Token2Min)
					{
						Token2Per = Token2Per.div(2);
					}
				}else{
					Token2Per = Token2Per.mult(3);
				}
				_reAdjustDifficulty();
			}
		}

		challengeNumber = blockhash(block.number - 1);
	}


	function _reAdjustDifficulty() internal {

		uint256 blktimestamp = block.timestamp;
		uint ethBlocksSinceLastDifficultyPeriod2 = blktimestamp - latestDifficultyPeriodStarted2;

		uint adjusDiffTargetTime = targetTime *  _BLOCKS_PER_READJUSTMENT; //36 min per block 60 sec * 12

		//if there were less eth blocks passed in time than expected
		if( ethBlocksSinceLastDifficultyPeriod2 < adjusDiffTargetTime )
		{
			uint excess_block_pct = (adjusDiffTargetTime.mult(100)).div( ethBlocksSinceLastDifficultyPeriod2 );
			give = 1;
			uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
			//make it harder 
			miningTarget = miningTarget.sub(miningTarget.div(2000).mult(excess_block_pct_extra));   //by up to 50 %
		}else{
			uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod2.mult(100)).div( adjusDiffTargetTime );
			give = 2;
			uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000
			//make it easier
			miningTarget = miningTarget.add(miningTarget.div(1000).mult(shortage_block_pct_extra));   //by up to 100 %
		}

		latestDifficultyPeriodStarted2 = blktimestamp;

		if(miningTarget < _MINIMUM_TARGET) //very difficult
		{
			miningTarget = _MINIMUM_TARGET;
		}
		if(miningTarget > _MAXIMUM_TARGET) //very easy
		{
			miningTarget = _MAXIMUM_TARGET;
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

		return _MAXIMUM_TARGET.div(miningTarget);
	}


	function getMiningTarget() public view returns (uint) {

		return miningTarget;

	}


	function getMiningMinted() public view returns (uint) {

		return tokensMinted;

	}


	//21m coins total
	//reward begins at 150 and is cut in half every reward era (as tokens are mined)
	function getMiningReward() public view returns (uint) {
		//once we get half way thru the coins, only get 25 per block
		//every reward era, the reward amount halves.

		return (150 * 10**uint(decimals) ).div( 2**rewardEra ) ;

		}


	function getEpoch() public view returns (uint) {

		return epochCount ;

	}


	//help debug mining software
	function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

		bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

		return digest;

	}


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


	  //Do not allow ETH to enter
	receive() external payable {

		revert();
	}


	fallback() external payable {

		revert();
	}


}