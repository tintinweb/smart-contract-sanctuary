pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

contract AddressList is Ownable
{

	mapping (address => bool) public inList;						// Records address to list.
	
	/// @notice Event records address added to list.
	event AddedToList(address account);

	/// @notice Event records address removed from list.
	event RemovedFromList(address account);

	/// @notice contract constructor.
	constructor() Ownable()
	{

	}

	/// @notice Function to add to list.
	/// @param account - address to add to list.
	function addToList(address account) onlyOwner() public returns (bool isAdded)
	{
		inList[account] = true;
		isAdded = true;

		emit AddedToList(account);								// Records account to event.
	}

	/// @notice Function to remove from no list.
	/// @param account - address to remove from list.
	function removeFromList(address account) onlyOwner() public returns (bool isRemoved)
	{
		inList[account] = false;
		isRemoved = true;
		
		emit RemovedFromList(account);							// Records account to event.
	} 
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./IZooFunctions.sol";
import "./NftArenaPool.sol";
import "./AddressList.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title Contract BaseZooFunctions.
/// @notice Contracts for base implementation of some ZooDao functions.
contract BaseZooFunctions is IZooFunctions
{
	using SafeMath for uint256;

	NftArenaPool public nftArenaPool;
	AddressList public noFeeList;
	AddressList public noBurnList;

	/// @notice contract constructor.
	constructor (address nftBattleArena, address _noFeeList, address _noBurnList)
	{
		nftArenaPool = NftArenaPool(nftBattleArena);
		noFeeList = AddressList(_noFeeList);
		noBurnList = AddressList(_noBurnList);
	}

	/// @notice Function for choosing winner in battle.
	/// @param votesForA - amount of votes for 1st candidate.
	/// @param votesForB - amount of votes for 2nd candidate.
	/// @param random - generated random number.
	/// @return bool - returns true if 1st candidate wins.
	function decideWins(uint votesForA, uint votesForB, uint random) override external view returns (bool)
	{
		uint mod = random % (votesForA + votesForB);
		return mod < votesForA;
	}

	/// @notice Function for calculcate transfer fee from Zoo token.
	/// @param amount - amount of transfer.
	/// @return fee amount.
	function computeFeeForTransfer(address from, address to, uint amount) override external view returns (uint)
	{
		if (noFeeList.inList(from) || noFeeList.inList(to))				// No fee list check.
		{
			return 0;
		}

		uint256 basisPointToReward = 30;                              	// Sets basis points to 0.3%.
        uint256 fee = amount.mul(basisPointToReward).div(10000);

		return fee;
	}

	/// @notice Function for calculating burn fee amount from transfer of Zoo token.
	/// @param amount - amount of transfer.
	/// @return burn fee amount.
	function computeBurnValueForTransfer(address from, address to, uint amount) override external view returns (uint)
	{
		if (noBurnList.inList(from) || noBurnList.inList(to))			// No burn list check.
		{
			return 0;
		}

		return amount.mul(15).div(10000);
	}

	/// @notice Function for calculating voting with Dai in vote battles.
	/// @param amount - amount of dai used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByDai(uint amount) override external view returns (uint votes)
	{
		if (block.timestamp < nftArenaPool.epochStartDate().add(nftArenaPool.firstStageDuration().add(2 days)))
		{
			votes = amount.mul(13).div(10);
		}
		else if (block.timestamp < nftArenaPool.epochStartDate().add(nftArenaPool.firstStageDuration().add(5 days)))
		{
			votes = amount;
		}
		else
		{
			votes = amount.mul(7).div(10);
		}
	}

	/// @notice Function for calculating voting with Zoo in vote battles.
	/// @param amount - amount of Zoo used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByZoo(uint amount) override external view returns (uint votes)
	{
		if (block.timestamp < nftArenaPool.epochStartDate().add(nftArenaPool.firstStageDuration().add(nftArenaPool.secondStageDuration().add(2 days))))
		{
			votes = amount.mul(13).div(10);
		}
		else if (block.timestamp < nftArenaPool.epochStartDate().add(nftArenaPool.firstStageDuration().add(nftArenaPool.secondStageDuration().add(4 days))))
		{
			votes = amount;
		}
		else
		{
			votes = amount.mul(7).div(10);
		}
	}
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

/// @title interface of Zoo functions contract.
interface IZooFunctions {
	
	/// @notice Function for choosing winner in battle.
	/// @param votesForA - amount of votes for 1st candidate.
	/// @param votesForB - amount of votes for 2nd candidate.
	/// @param random - generated random number.
	/// @return bool - returns true if 1st candidate wins.
	function decideWins(uint votesForA, uint votesForB, uint random) external view returns (bool);

	/// @notice Function for calculcate transfer fee from Zoo token.
	/// @param amount - amount of transfer.
	/// @return fee amount.
	function computeFeeForTransfer(address from, address to, uint amount) external view returns (uint);

	/// @notice Function for calculating burn fee amount from transfer of Zoo token.
	/// @param amount - amount of transfer.
	/// @return burn fee amount.
	function computeBurnValueForTransfer(address from, address to, uint amount) external view returns (uint);

	/// @notice Function for calculating voting with Dai in vote battles.
	/// @param amount - amount of dai used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByDai(uint amount) external view returns (uint);

	/// @notice Function for calculating voting with Zoo in vote battles.
	/// @param amount - amount of Zoo used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByZoo(uint amount) external view returns (uint);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";
import "./ZooToken.sol";
//import "../node_modules/yearn-protocol/interfaces/yearn/IVault.sol";
import "./IZooFunctions.sol";
import "./ZooGovernance.sol";

/// @title NftArenaPool contract.
/// @notice Contract for staking ZOO-Nft for participate in battle votes.
contract NftArenaPool is Ownable
{
	using SafeMath for uint256;
	
	ZooToken public zoo;
	IERC20 public dai;
	//IVault public vault;
	ZooGovernance public zooGovernance;
	IZooFunctions public zooFunctions;

	// Stages of vote battle.
	enum Stage
	{
		FirstStage,
		SecondStage,
		ThirdStage,
		FourthStage
	}

	struct VoteRecord
	{
		uint daiInvested;
		uint zooInvested;
		uint votes;
	}

	struct NftRecord
	{
		address token;
		uint id;
		uint votes;
	}

	// struct for pair of nft for battle.
	struct NftPair
	{
		address token1;
		uint id1;
		address token2;
		uint id2;
		bool win;
	}

	uint public epochStartDate;					// Start date of 1st battle.
	uint public currentEpoch = 0;				// Counter for battle epochs.

	uint public firstStageDuration = 3 days;	// Duration of first stage.
	uint public secondStageDuration = 7 days;	// Duration of second stage.	
	uint public thirdStageDuration = 5 days;	// Duration third stage.
	uint public fourthStage = 2 days; 			// Duration of fourth stage.
	uint public epochDuration = firstStageDuration + secondStageDuration + thirdStageDuration + fourthStage; // Total duration of battle epoch.

	// Epoch => address of NFT => id => VoteRecord
	mapping (uint => mapping(address => mapping(uint => VoteRecord))) public votesForNftInEpoch;

	// Epoch => address of NFT => id => investor => VoteRecord
	mapping (uint => mapping(address => mapping(uint => mapping(address => VoteRecord)))) public investedInVoting;

	mapping (address => bool) public allowedForStaking;                     // List of NFT available for staking.

	mapping (address => mapping (uint256 => address)) public tokenStakedBy;	// Records that nft staked or not.

	mapping (uint => NftRecord[]) public nftsInEpoch;						// Records amount of nft in battle epoch.

	mapping (uint => NftPair[]) public pairsInEpoch;						// Records amount of pairs in battle epoch.

	/// @notice Contract constructor.
	/// @param _zoo - address of Zoo token contract.
	/// @param _dai - address of DAI token contract.
	/// @param _zooGovernance - address of ZooDao Governance contract.
	constructor (address _zoo, address _dai, address _zooGovernance) Ownable()
	{
		zoo = ZooToken(_zoo);
		dai = IERC20(_dai);
		//vault = IVault(_vault);
		zooGovernance = ZooGovernance(_zooGovernance);

		epochStartDate = block.timestamp + 14 days;							// Start date of 1st battle.
	}

	/// @notice Function for updating functions according last governance resolutions.
	function updateZooFunctions() external
	{
		require(getCurrentStage() == Stage.FirstStage);						// Requires to be at first stage in battle epoch.

		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());
	}

	/// @notice Function to allow new NFT contract available for stacking.
	/// @param token - address of new Nft contract.
	function allowNewContractForStaking(address token) onlyOwner external
	{
		allowedForStaking[token] = true;
	}

	/// @notice Function for staking NFT in this pool.
	/// @param token - address of Nft token to stake
	/// @param id - id of nft token
	function stakeNft(address token, uint256 id) public
	{
		require(allowedForStaking[token] = true);					// Requires for nft-token to be from allowed contract.
		require(tokenStakedBy[token][id] == address(0));			// Requires for token to be non-staked before.
		require(getCurrentStage() == Stage.FirstStage);				// Requires to be at first stage in battle epoch.

		IERC721(token).transferFrom(msg.sender, address(this), id);	// Sends NFT token to this contract.

		tokenStakedBy[token][id] = msg.sender;						// Records that token now staked.

	}

	/// @notice Function for withdrawal Nft token back to owner.
	/// @param token - address of Nft token to unstake.
	/// @param id - id of nft token.
	function withdrawNft(address token, uint256 id) public
	{
		require(tokenStakedBy[token][id] == msg.sender);			// Requires for token to be staked in this contract.
		require(getCurrentStage() == Stage.FirstStage);				// Requires to be at first stage in battle epoch.

		IERC721(token).transferFrom(address(this), msg.sender, id);	// Transfers token back to owner.

		tokenStakedBy[token][id] = address(0);						// Records that token is unstaked.

	}

	/// @notice Function for voting with DAI in battle epoch.
	/// @param token - address of Nft token voting for.
	/// @param id - id of voter.
	/// @param amount - amount of votes in DAI.
	function voteWithDai(address token, uint256 id, uint256 amount) public returns (uint)
	{
		require(getCurrentStage() == Stage.SecondStage);					// Requires to be at second stage of battle epoch.

		dai.transferFrom(msg.sender, address(this), amount);				// Transfers DAI to vote.

		uint votes = zooFunctions.computeVotesByDai(amount);/*
		if (block.timestamp < epochStartDate + firstStageDuration + 2 days)
		{
			votes = amount * 13 / 10;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + 5 days)
		{
			votes = amount;
		}
		else
		{
			votes = amount * 7 / 10;
		}*/

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;
		votesForNftInEpoch[currentEpoch][token][id].daiInvested += amount;

		//vault.deposit(amount);

		investedInVoting[currentEpoch][token][id][msg.sender].daiInvested += amount;
		investedInVoting[currentEpoch][token][id][msg.sender].votes += votes;

		uint length = nftsInEpoch[currentEpoch].length;

		uint i;
		for (i = 0; i < length; i++)
		{
			if (nftsInEpoch[currentEpoch][i].token == token && nftsInEpoch[currentEpoch][i].id == id)
			{
				nftsInEpoch[currentEpoch][i].votes += votes;
				break;
			}
		}

		if (i == length)
		{
			nftsInEpoch[currentEpoch].push(NftRecord(token, id, votes));
		}

		return votes;
	}

	/// @notice Function for
	function truncateAndPair() public returns (bool success)
	{
		require(getCurrentStage() == Stage.ThirdStage);

		// Truncate.
		if (nftsInEpoch[currentEpoch].length % 2 == 1)
		{
			uint random = uint(keccak256(abi.encodePacked(blockhash(block.number - 1))));
			uint index = random % nftsInEpoch[currentEpoch].length;
			uint length = nftsInEpoch[currentEpoch].length;
			nftsInEpoch[currentEpoch][index] = nftsInEpoch[currentEpoch][length - 1];
			nftsInEpoch[currentEpoch].pop();
		}

		uint i = 1;
		// Truncate if odd
		while (nftsInEpoch[currentEpoch].length != 0)
		{
			uint length = nftsInEpoch[currentEpoch].length;

			uint random1 = uint(keccak256(abi.encodePacked(uint(blockhash(block.number - 1)) + i++))) % length;
			uint random2 = uint(keccak256(abi.encodePacked(uint(blockhash(block.number - 1)) + i++))) % length;

			address token1 = nftsInEpoch[currentEpoch][random1].token;
			uint id1 = nftsInEpoch[currentEpoch][random1].id;

			address token2 = nftsInEpoch[currentEpoch][random2].token;
			uint id2 = nftsInEpoch[currentEpoch][random2].id;

			pairsInEpoch[currentEpoch].push(NftPair(token1, id1, token2, id2, false));

			nftsInEpoch[currentEpoch][random1] = nftsInEpoch[currentEpoch][length - 1];
			nftsInEpoch[currentEpoch][random2] = nftsInEpoch[currentEpoch][length - 2];

			nftsInEpoch[currentEpoch].pop();
			nftsInEpoch[currentEpoch].pop();
		}
		
		return success;
	}

	/// @notice Function for boost\multiply votes with Zoo.
	/// @param token - address of nft.
	/// @param id - id of voter.
	/// @param amount - amount of Zoo.
	function voteWithZoo(address token, uint256 id, uint256 amount) public returns (uint)
	{
		require(getCurrentStage() == Stage.ThirdStage);

		zoo.transferFrom(msg.sender, address(this), amount);

		uint votes = zooFunctions.computeVotesByZoo(amount);/*
		if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + 2 days)
		{
			votes = amount * 13 / 10;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + 4 days)
		{
			votes = amount;
		}
		else
		{
			votes = amount * 7 / 10;
		}
*/
		require(votes <= investedInVoting[currentEpoch][token][id][msg.sender].votes);

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;
		votesForNftInEpoch[currentEpoch][token][id].zooInvested += amount;

		investedInVoting[currentEpoch][token][id][msg.sender].votes += votes;
		investedInVoting[currentEpoch][token][id][msg.sender].zooInvested += amount;

		return votes;
	}
	
	/// @notice Function for chosing winner.
	/// @dev should be changed for chainlink VRF.
	function chooseWinners() public
	{
		require(getCurrentStage() == Stage.FourthStage);

		for (uint i = 0; i < pairsInEpoch[currentEpoch].length; i++)
		{
			uint random = uint(keccak256(abi.encodePacked(uint(blockhash(block.number - 1)) + i)));

			address token1 = pairsInEpoch[currentEpoch][i].token1;
			uint id1 = pairsInEpoch[currentEpoch][i].id1;
			uint votesForA = votesForNftInEpoch[currentEpoch][token1][id1].votes;
			
			address token2 = pairsInEpoch[currentEpoch][i].token2;
			uint id2 = pairsInEpoch[currentEpoch][i].id2;
			uint votesForB = votesForNftInEpoch[currentEpoch][token2][id2].votes;

			pairsInEpoch[currentEpoch][i].win = zooFunctions.decideWins(votesForA, votesForB, random);
		}
	}

	function claimRewardForStakers() public
	{

	}

	function claimRewardForVoter() public
	{

	}
/*
	/// Get 256-bit random from chainlink
	/// Returns true if A won else returns false
	function decideWins(uint votesForA, uint votesForB, uint random) internal pure returns (bool)
	{
		uint mod = random % (votesForA + votesForB);
		return mod < votesForA;
	}
*/
	/// @notice Function to view current stage in battle epoch.
	function getCurrentStage() public view returns (Stage)
	{
		if (block.timestamp < epochStartDate + firstStageDuration)
		{
			return Stage.FirstStage;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration)
		{
			return Stage.SecondStage;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + thirdStageDuration)
		{
			return Stage.ThirdStage;
		}
		else
		{
			return Stage.FourthStage;
		}
	}
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./IZooFunctions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract ZooGovernance.
/// @notice Contract for Zoo Dao vote proposals.
contract ZooGovernance is Ownable {

	using SafeMath for uint;
	
	struct Voting
	{
		uint startDate;
		uint votesFor;
		uint votesAgainst;
		bool isUsed;
	}

	address public zooFunctions;                    // Address of contract with Zoo functions.
	IERC20 public zooToken;

	uint public quorum = 10 ** 6 * 18;              // 1 m of zoo as quorum.
	uint public votingDuration = 14 days;           // Duration of vote proposal.
	mapping (address => Voting) public votings;
	mapping (address => mapping (address => uint)) public locked;

	/// @notice Contract constructor.
	constructor (address _zoo)
	{
		zooToken = IERC20(_zoo);
	}

	/// @notice Function to set default zoo functions contract.
	/// @param baseZooFunctions - address of deployed BaseZooFunctions contract.
	function init(address baseZooFunctions) external onlyOwner {

		zooFunctions = baseZooFunctions;

		renounceOwnership();            // Sets owner to zero address.
	}

    /// @notice Function for vote for changing Zoo fuctions.
    /// @param newZooFunctions - address of new Zoo functions contract.
    /// @param value - amount of votes.
    /// @param isFor - bool for voting for or against.
	function changeZooFunctionsContract(address newZooFunctions, uint value, bool isFor) external
	{
		require(votings[newZooFunctions].startDate + votingDuration < block.timestamp);

		zooToken.transferFrom(msg.sender, address(this), value);

		if (isFor)
		{
			votings[newZooFunctions].votesFor += value;
		}
		else
		{
			votings[newZooFunctions].votesAgainst += value;
		}

		locked[msg.sender][newZooFunctions] += value;
	}
    
    /// @notice Function - for unlocking Zoo tokens used in votes.
    /// @param zooFunctionsContract - address of Zoo functions contract.
	function unlock(address zooFunctionsContract) external
	{
		require(votings[zooFunctionsContract].startDate + votingDuration > block.timestamp);

		zooToken.transfer(msg.sender, locked[msg.sender][zooFunctionsContract]);
		locked[msg.sender][zooFunctionsContract] = 0;
	}

    /// @notice Function for calculating result of vote.
    /// @param zooFunctionsContract - address of Zoo functions contract.
	function tryToWin(address zooFunctionsContract) external
	{
		require(!votings[zooFunctionsContract].isUsed);
		uint votesFor = votings[zooFunctionsContract].votesFor;
		uint votesAgainst = votings[zooFunctionsContract].votesAgainst;

		uint totalVoted = votesFor + votesAgainst;
		require(totalVoted > quorum);

		require(3 * votesFor > totalVoted * 2);

		votings[zooFunctionsContract].isUsed = true;
		zooFunctions = zooFunctionsContract;
	}
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IZooFunctions.sol";
import "./ZooGovernance.sol";

/// @title Zoo token contract
/// @notice Based on the ERC-20 token standard as defined at https://eips.ethereum.org/EIPS/eip-20
/// @notice Added burn and redistribution from transfers to YieldFarm.
contract ZooToken is Ownable {

    using SafeMath for uint256;

    string public name;                                         // Contract name.
    string public symbol;                                       // Contract symbol.
    uint256 public decimals;                                    // Token decimals.
    uint256 public totalSupply;                                 // Token total supply.
    address public yieldFarm;                                   // Address of yield farm contract.

    ZooGovernance public zooGovernance;                         // Governance contract.

    mapping(address => uint256) balances;                       // Records balances.
    mapping(address => mapping(address => uint256)) allowed;    // Records allowances for tokens.

    /// @notice Event records info about transfers.
    /// @param from - address sender.
    /// @param to - address recipient.
    /// @param value - amount of tokens transfered.
    event Transfer(address from, address to, uint256 value);

    /// @notice Event records info about approved tokens.
    /// @param owner - address owner of tokens.
    /// @param spender - address spender of tokens.
    /// @param value - amount of tokens allowed to spend.
    event Approval(address owner, address spender, uint256 value);

    /// @notice Event records address of initiated governance contract.
    /// @param ZooGovernance - address of governance contract.
    event Inited(address ZooGovernance);

    /// @notice Contract constructor.
    /// @param _name - name of token.
    /// @param _symbol - symbol of token.
    /// @param _decimals - token decimals.
    /// @param _totalSupply - total supply amount.
    /// @param _yieldFarm - address of contract for yield farming with Zoo.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _totalSupply,
        address _yieldFarm
    )
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        yieldFarm = _yieldFarm;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// @notice Function to initiate address of governance contract.
    /// @param _zooGovernance - address of zoo governance contract.
    function init(address _zooGovernance) external onlyOwner
    {
        zooGovernance = ZooGovernance(_zooGovernance);

        renounceOwnership();            // Sets owner to zero address.

        emit Inited(_zooGovernance);                // Records governance address to event.
    }
    
    /// @notice Function to check the current balance of an address.
    /// @param _owner Address of owner.
    /// @return Balances of owner.
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /// @notice Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    /// @return The amount of tokens available for the spender.
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /// @notice Function to approve an address to spend the specified amount of msg.sender's tokens.
    /// @param _spender The address which will spend the tokens.
    /// @param _value The amount of tokens allowed to be spent.
    /// @return Success boolean.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);        // Records in Approval event.

        return true;
    }

    /// @param _from - sender of tokens.
    /// @param _to - recipient of tokens.
    /// @param _value - amount of transfer.
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance"); // Requires balance to be sufficient enough for transfer.
        balances[_from] = balances[_from].sub(_value);              // Decreases balances of sender.
        balances[_to] = balances[_to].add(_value);                  // Increases balances of recipient.
        
        IZooFunctions zooFunctions = IZooFunctions(zooGovernance.zooFunctions());      // Calls ZooFunctions contracts.
        uint burnValue = zooFunctions.computeBurnValueForTransfer(_from, _to, _value); // Sets burn value.
        burnFrom(_to, burnValue);                                   // Burns % of tokens from transfered amount, currently burns 0.15%.
        
        uint fee = zooFunctions.computeFeeForTransfer(_from, _to, _value);             // Sets amount of fee.
        balances[_to] = balances[_to].sub(fee);                                        // Decreases amount of token sended for fee amount.
        balances[yieldFarm] = balances[yieldFarm].add(fee);                            // Increases balances of YieldFarm for fee amount.

        // old fee:
        //burnFrom(_to, _value.mul(15).div(10000));                 // Decreases amount of token sended for burn amount, currently burns 0.15%.
        //uint256 basisPointToReward = 30;                          // Sets basis points amount.
        //uint256 fee = _value.mul(basisPointToReward).div(10000);  // Calculates fee amount.
        //balances[_to] = balances[_to].sub(fee);                   // Decreases amount of token sended for fee amount.
        //balances[yieldFarm] = balances[yieldFarm].add(fee);       // Increases balances of YieldFarm for fee amount.

        emit Transfer(_from, _to, _value);                          // Records transfer to Transfer event.
        emit Transfer(_from, yieldFarm, fee);                       // Records fee to Transfer event.
    }

    /// @notice Function for burning tokens.
    /// @param amount - amount of tokens to burn.
     function burn(uint256 amount) public {        
        burnFrom(msg.sender, amount);
    }

    /// @param from - Address of token owner.
    /// @param amount - Amount of tokens to burn.
    function burnFrom(address from, uint256 amount) internal {
        require(balances[from] >= amount, "ERC20: burn amount exceeds balance"); // Requires balance to be sufficient enough for burn.

        balances[from] = balances[from].sub(amount);                             // Decreases balances of owner for burn amount.
        totalSupply = totalSupply.sub(amount);                                   // Decreases total supply of tokens for amount.

        emit Transfer(from, address(0), amount);                                 // Records to Transfer event.
    }

    /// @notice Function for transfering tokens to a specified address.
    /// @param _to The address of recipient.
    /// @param _value The amount of tokens to be transfered.
    /// @return Success boolean.
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Function for transfering tokens from one specified address to another.
    /// @param _from The address which you want to send tokens from.
    /// @param _to The address recipient.
    /// @param _value The amount of tokens to be transfered.
    /// @return Success boolean.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance"); // Requires allowance for sufficient amount of tokens to send.
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);     // Decreases amount of allowed tokens for sended value.

        _transfer(_from, _to, _value);                                           // Calls _transfer function.
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
    * - Subtraction cannot overflow.
    */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

