// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./GovernanceToken.sol";
import "./assetFactory.sol";



contract VoteMachine is Ownable{
	using SafeMath for uint256;
	AssetFactory public assetFactory;
	address public assetFactoryAddress;
	address public rewardsMachineAddress;
	address public DAOAddress;
	GovernanceToken public governanceToken;
	uint256 DAOVolume = 100000000 * (10 ** 18) * 10 / 100;
	
	//NEW PART
	uint256 public lastVoteID = 0;
	mapping (string => uint256) public lastFreezeVoteIDBySymbol;
	mapping (uint256 => mapping (address => bool)) public freezeVotesByID;
	mapping (uint256 => freezeVoteDetails) public allFreezeVotesByID;
	mapping (uint256 => mapping (address => bool)) public hasVoted;

	struct individualFreezeVote {
		uint256 voteID;
		bool vote;
		uint256 votingPoints;
	}
	struct freezeVoteDetails{
		bool voteResult;
		bool open;
		uint256 endingTime;
	}
	mapping (uint256 => mapping (address => individualFreezeVote[])) public freezeVotesToCheck;
	mapping (uint256 => bool) public freezeVoteResults;
	
	mapping (string => uint256) public lastExpiryVoteIDBySymbol;
	mapping (uint256 => mapping (address => uint256)) public expiryVotesByID;
	mapping (uint256 => expiryVoteDetails) public allExpiryVotesByID;
	struct individualExpiryVote {
		uint256 voteID;
		uint256 vote;
		uint256 votingPoints;

	}
	struct expiryVoteDetails{
		uint256 voteResult;
		bool open;
		uint256 endingTime;
	}
	mapping (uint256 => mapping (address => individualExpiryVote[])) public expiryVotesToCheck;
	mapping (uint256 => uint256) public expiryVoteResults;

	
	//END OF NEW PART
	

	struct Votes{
		address votingAddress;
		bool voted;
		uint256 yesVotes;
		uint256 noVotes;
	}

	

    struct FreezeVotes {
        uint256 voteID;
        uint256 startingTime;
        uint256 endingTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool open;
        bool exists;
        mapping (address => bool) hasvoted;
        uint256 voteNumber;
        //Votes[] individualVotes;
    }


    struct endOfLifeVote{
		address votingAddress;
		bool voted;
		uint256 numberOfVotingShares;
		uint256 voteValue;
	}

	struct endOfLifeVotes {
    	uint256 voteID;
    	uint256 startingTime;
    	uint256 endingTime;
    	uint256 numberOfVotingShares;
    	uint256 totalVoteValue;
    	bool open;
    	bool exists;
    	mapping (address => bool) hasvoted;
    	uint256 voteNumber;
    	//endOfLifeVote[] individualVotes;
    }

    struct rewardPointsSnapshot {
    	mapping (address => uint256) votingRewardpoints;
    	address[] votingRewardAddresses;
    	uint256 totalVotingRewardPoints;
    }

    

    mapping (uint256 => rewardPointsSnapshot) public rewardPointsSnapshots;
    uint256 public currentRewardsRound = 0;

    mapping(string => FreezeVotes) public getFreezeVotes;
    mapping(string => endOfLifeVotes) public getEndOfLifeVotes;
    mapping (address => uint256) public rewardPoints;

    
    /**
    struct grantFundingVote{
		address votingAddress;
		bool voted;
		uint256 yesVotes;
		uint256 noVotes;
	}

	
	struct grantFundingVotes {
    	uint256 startingTime;
        uint256 endingTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 amount;
        string description;
    	bool open;
    	bool exists;
    	mapping (address => bool) hasvoted;
    	uint256 voteNumber;
    	grantFundingVote[] individualVotes;
    }

	mapping(address => grantFundingVotes) public getGrantVotes;
	*/
	constructor(GovernanceToken _governanceToken, AssetFactory _assetFactory) Ownable() {
		governanceToken = _governanceToken;
		assetFactory = _assetFactory;
	}
	
	event freezeVoteInitiated(
		string _symbol
	);

	event freezeVoteClosed (
		string  _symbol,
		bool success
	);


	/**
    * @notice A method that sets the AssetFactory contract address
    * @param _address Address of the AssetFactory contract
    */
    /**
    function setAssetFactoryAddress (
		address _address
		)
		external 
		onlyOwner
		{
		assetFactoryAddress = _address;
	}
	/**
	

	/**
    * @notice A method that sets the RewardsMachine contract address
    * @param _address Address of the RewardsMachine contract
    */
    function setRewardsMachineAddress (
		address _address
		)
		external
		onlyOwner
		{
		rewardsMachineAddress = _address;
	}
	
	/**
    * @notice A method that sets the DAO contract address
    * @param _address Address of the DAO contract
    */
    function setDAOAddress (
		address _address
		)
		external 
		onlyOwner
		{
		DAOAddress = _address;
	}

	/**
    * @notice A method initiates a new voting process that determines if an asset is frozen.
    * @param _symbol Symbol of the asset that is voted on
    */
    function initiateFreezeVote(
		string calldata _symbol
		)
		external 
		{
		require (governanceToken.stakeOf(msg.sender) > 100000*(10**18),'INSUFFICIENT_IPT_STAKED');
		require (assetFactory.assetExists(_symbol),'ASSET_UNKNOWN'); //check if the symbol already exists
		require (getFreezeVotes[_symbol].open == false,'VOTE_IS_OPEN');   //check if the voting process is open
		require (assetFactory.assetFrozen(_symbol) == false,'ASSET_IS_FROZEN');   //check if the asset is frozen
		require(assetFactory.getExpiryTime(_symbol) > block.timestamp, 'ASSET_EXPIRED');
		getFreezeVotes[_symbol].startingTime = (block.timestamp);
    	getFreezeVotes[_symbol].endingTime = block.timestamp.add(7 days);
    	getFreezeVotes[_symbol].yesVotes = 0;
    	getFreezeVotes[_symbol].noVotes = 0;
    	getFreezeVotes[_symbol].open = true;
    	getFreezeVotes[_symbol].exists = true;
    	emit freezeVoteInitiated(_symbol);
    	//NEW
    	getFreezeVotes[_symbol].voteID = lastVoteID +1;
    	lastFreezeVoteIDBySymbol[_symbol] = lastVoteID + 1;
    	allFreezeVotesByID[lastVoteID +1].open = true;
    	lastVoteID = lastVoteID + 1;

    }


    

	/**
    * @notice A method that votes if an asset should be frozen or not
    * @param _symbol Symbol of the asset that is voted on
    *        _vote Should be set to true when it should be frozen or false if not
    */
    function voteFreezeVote (
		string  calldata _symbol, 
		bool _vote
		)
		external
		{
		uint256 voteID = lastFreezeVoteIDBySymbol[_symbol];
		require(hasVoted[voteID][msg.sender] == false, 'VOTED_AlREADY');  // check if the address has voted already
		hasVoted[voteID][msg.sender] = true;

		require(getFreezeVotes[_symbol].exists,'UNKNOWN'); //checks if the vote id exists)
		require(getFreezeVotes[_symbol].open,'NOT_OPEN'); //checks is the vote is open)
		require(getFreezeVotes[_symbol].endingTime >= block.timestamp, 'VOTE_OPEN'); //checks if the voting period is still open
		
		uint256 voteNumber = governanceToken.stakeOf(msg.sender);
		

		governanceToken.lockStakeForVote(msg.sender,getFreezeVotes[_symbol].endingTime);
		//Votes memory individualVote;
		//individualVote.voted = true;
		//individualVote.votingAddress = msg.sender;
		if (_vote == true) {
			getFreezeVotes[_symbol].yesVotes = getFreezeVotes[_symbol].yesVotes.add(voteNumber);
			//individualVote.yesVotes = voteNumber;

		}
		else {
			getFreezeVotes[_symbol].noVotes = getFreezeVotes[_symbol].noVotes.add(voteNumber);
			//individualVote.noVotes = voteNumber;
		}
		//getFreezeVotes[_symbol].hasvoted[msg.sender] = true;
		//getFreezeVotes[_symbol].individualVotes.push(individualVote);
		getFreezeVotes[_symbol].voteNumber = getFreezeVotes[_symbol].voteNumber.add(1);
		addRewardPoints(msg.sender,voteNumber);
		rewardPointsSnapshots[currentRewardsRound].totalVotingRewardPoints = rewardPointsSnapshots[currentRewardsRound].totalVotingRewardPoints.add(voteNumber);
		//NEW
		freezeVotesByID[lastFreezeVoteIDBySymbol[_symbol]][msg.sender] = _vote;
		individualFreezeVote memory voteToCheck;
		voteToCheck.voteID = lastFreezeVoteIDBySymbol[_symbol];
		voteToCheck.vote = _vote;
		voteToCheck.votingPoints = voteNumber;
		freezeVotesToCheck[currentRewardsRound][msg.sender].push(voteToCheck);					
	}

	/**
    * @notice A method that checks if an address has already voted in a specific freeze vote.
    * @param _address Address that is checked
    *        _symbol Symbol for which the voting process should be checked
    */
    function checkIfVoted(
		address _address, 
		string calldata _symbol
		) 
		external
		view
		returns(bool)
		{
		uint256 voteID = lastFreezeVoteIDBySymbol[_symbol];
		return (hasVoted[voteID][_address]);
	}

	/**
    * @notice A method that checks if an address has already voted in a specific expiry vote.
    * @param _address Address that is checked
    *        _symbol Symbol for which the voting process should be checked
    */
    function checkIfVotedOnExpiry(
		address _address,
		string calldata _symbol
		) 
		external
		view
		returns(bool)
		{
		uint256 voteID = lastExpiryVoteIDBySymbol[_symbol];
		return (hasVoted[voteID][_address]);
		
	}
	
	/**
    * @notice A method that closes a specific freeze voting process.
    * @param _symbol Symbol for which the voting process should be closed
    */
    function closeFreezeVote (
		string calldata _symbol
		)
		external 
		{
		require(getFreezeVotes[_symbol].exists,'VOTEID_UNKNOWN'); //checks if the vote id exists)
		require(getFreezeVotes[_symbol].open,'VOTE_NOT_OPEN'); //checks is the vote is open)
		require(getFreezeVotes[_symbol].endingTime < block.timestamp);

		
		
		if (getFreezeVotes[_symbol].yesVotes > getFreezeVotes[_symbol].noVotes){
			emit freezeVoteClosed(_symbol,true);
			assetFactory.freezeAsset(_symbol);
			freezeVoteResults[getFreezeVotes[_symbol].voteID] = true;

			allFreezeVotesByID[getFreezeVotes[_symbol].voteID].open = false;
			allFreezeVotesByID[getFreezeVotes[_symbol].voteID].voteResult = true;
		}
		else {
			emit freezeVoteClosed(_symbol,false);
			freezeVoteResults[getFreezeVotes[_symbol].voteID] = false;
			allFreezeVotesByID[getFreezeVotes[_symbol].voteID].open = false;
			allFreezeVotesByID[getFreezeVotes[_symbol].voteID].voteResult = false;
		}
		delete(getFreezeVotes[_symbol]);
		
	}

	

	/**
    * @notice A method to checks for a specific address and voteID if the freeze vote is qualifiying for rewards.
    * @param _rewardsRound The rewards round to get the data from
    *        _address Address to check
    */
    function checkFreezeVotes (
		uint256 _rewardsRound,
		address _address
		)
		external
		view
		returns (bool)
		{
		bool result = true; 
		for (uint256 s = 0; s < freezeVotesToCheck[_rewardsRound][_address].length; s += 1){
	    	uint256 voteID = freezeVotesToCheck[_rewardsRound][_address][s].voteID;
	    	//uint256 votingPoints = freezeVotesToCheck[_rewardsRound][_address][s].votingPoints;
	    	bool vote = freezeVotesToCheck[_rewardsRound][_address][s].vote;
	    	bool voteConsensusresult = freezeVoteResults[voteID]; 
	    	if (vote != voteConsensusresult && allFreezeVotesByID[voteID].open == false){
	    		result = false;
	    	}
	    	
       	}
		return (result);
		}

	/**
    * @notice A method to checks if votes are closes and if not moves the votes and rewards to the next period.
    * @param _rewardsRound The rewards round to get the data from
    *        _address Address to check
    */
    function checkVotesIfClosed (
		uint256 _rewardsRound,
		address _address
		)
		external
		{
		require (msg.sender == rewardsMachineAddress,'NOT_ALLOWED');
		uint256 numberOfVotesToCheck = freezeVotesToCheck[_rewardsRound][_address].length;
		for (uint256 s = 0; s < numberOfVotesToCheck; s += 1){
	    	uint256 voteID = freezeVotesToCheck[_rewardsRound][_address][s].voteID;
	    	
	    	if (allFreezeVotesByID[voteID].open) {
	    		uint256 votingPoints = freezeVotesToCheck[_rewardsRound][_address][s].votingPoints;
	    		// Move the votingPoints into the next rewards Round
	    		rewardPointsSnapshots[_rewardsRound].votingRewardpoints[_address] = rewardPointsSnapshots[_rewardsRound].votingRewardpoints[_address] - votingPoints;
	    		rewardPointsSnapshots[_rewardsRound+1].votingRewardpoints[_address] = rewardPointsSnapshots[_rewardsRound+1].votingRewardpoints[_address] + votingPoints;
	    		rewardPointsSnapshots[_rewardsRound+1].totalVotingRewardPoints = rewardPointsSnapshots[_rewardsRound+1].totalVotingRewardPoints + votingPoints;
	    		// Add the Votes to check into the next rewards round
	    		freezeVotesToCheck[_rewardsRound+1][_address].push(freezeVotesToCheck[_rewardsRound][_address][s]);
	    	}
	    }

	    numberOfVotesToCheck = expiryVotesToCheck[_rewardsRound][_address].length;
		for (uint256 s = 0; s < numberOfVotesToCheck; s += 1){
	    	uint256 voteID = expiryVotesToCheck[_rewardsRound][_address][s].voteID;
	    	
	    	if (allExpiryVotesByID[voteID].open) {
	    		uint256 votingPoints = expiryVotesToCheck[_rewardsRound][_address][s].votingPoints;
	    		// Move the votingPoints into the next rewards Round
	    		rewardPointsSnapshots[_rewardsRound].votingRewardpoints[_address] -= votingPoints;
	    		rewardPointsSnapshots[_rewardsRound+1].votingRewardpoints[_address] += votingPoints;
	    		rewardPointsSnapshots[_rewardsRound+1].totalVotingRewardPoints += votingPoints;
	    		// Add the Votes to check into the next rewards round
	    		expiryVotesToCheck[_rewardsRound+1][_address].push(expiryVotesToCheck[_rewardsRound][_address][s]);
	    	}

		}
		}		

	/**
    * @notice A method initiates a new voting process that determines the price of an asset at expiry.
    * @param _symbol Symbol of the asset that is voted on
    */
    function initiateEndOfLifeVote(
		string calldata _symbol
		)
		external
		{
		require (assetFactory.assetExists(_symbol),'ASSET_UNKNOWN'); //check if the symbol already exists
		require (getEndOfLifeVotes[_symbol].open == false,'VOTE_OPEN');
		require(assetFactory.getExpiryTime(_symbol) < block.timestamp, 'EXPIRY_TIME_NOT_REACHED');
		require(assetFactory.assetExpired(_symbol) == false, 'ASSET_ALREADY_EXPIRED');
		require (assetFactory.assetFrozen(_symbol) == false,'ASSET_IS_FROZEN');   //check if the asset is frozen
		require (getFreezeVotes[_symbol].open == false,'FV__OPEN');   //check if the freeze voting process is open
		
		getEndOfLifeVotes[_symbol].startingTime = (block.timestamp);
    	getEndOfLifeVotes[_symbol].endingTime = block.timestamp.add(7 days);
    	getEndOfLifeVotes[_symbol].numberOfVotingShares = 0;
    	getEndOfLifeVotes[_symbol].totalVoteValue = 0;
    	getEndOfLifeVotes[_symbol].open = true;
    	getEndOfLifeVotes[_symbol].exists = true;
    	//NEW
    	getEndOfLifeVotes[_symbol].voteID = lastVoteID +1;
    	lastExpiryVoteIDBySymbol[_symbol] = lastVoteID + 1;
    	allExpiryVotesByID[lastVoteID +1].open = true;
    	lastVoteID = lastVoteID + 1;
    	}

	/**
    * @notice A method that votes on the expiry price
    * @param _symbol Symbol of the asset that is voted on
    *        _value Value of the price at expiry
    */
    function voteOnEndOfLifeValue (
		string  calldata _symbol,
		uint256 _value
		) 
		external
		{
		uint256 voteID = lastExpiryVoteIDBySymbol[_symbol];
		require(hasVoted[voteID][msg.sender] == false, 'VOTED_AlREADY');  // check if the address has voted already
		hasVoted[voteID][msg.sender] = true;

		require(getEndOfLifeVotes[_symbol].exists,'VOTEID_UNKNOWN'); //checks if the vote id exists)
		require(getEndOfLifeVotes[_symbol].open,'VOTE_NOT_OPEN'); //checks is the vote is open)
		require(getEndOfLifeVotes[_symbol].endingTime >= block.timestamp, 'VOTE_OVER'); //checks if the voting period is still open
		
		require(_value < assetFactory.getUpperLimit(_symbol), 'EXCEEDS_UPPERLIMIT');
		uint256 voteNumber = governanceToken.stakeOf(msg.sender);
		governanceToken.lockStakeForVote(msg.sender,getEndOfLifeVotes[_symbol].endingTime);
		
		getEndOfLifeVotes[_symbol].numberOfVotingShares = getEndOfLifeVotes[_symbol].numberOfVotingShares.add(voteNumber);
		getEndOfLifeVotes[_symbol].totalVoteValue = getEndOfLifeVotes[_symbol].totalVoteValue.add(voteNumber.mul(_value));

		getEndOfLifeVotes[_symbol].voteNumber = getFreezeVotes[_symbol].voteNumber.add(1);
		addRewardPoints(msg.sender,voteNumber);
		rewardPointsSnapshots[currentRewardsRound].totalVotingRewardPoints = rewardPointsSnapshots[currentRewardsRound].totalVotingRewardPoints.add(voteNumber);
		//NEW
		expiryVotesByID[lastExpiryVoteIDBySymbol[_symbol]][msg.sender] = _value;
		individualExpiryVote memory voteToCheck;
		voteToCheck.voteID = lastExpiryVoteIDBySymbol[_symbol];
		voteToCheck.vote = _value;
		voteToCheck.votingPoints = voteNumber;
		expiryVotesToCheck[currentRewardsRound][msg.sender].push(voteToCheck);			
	}

	/**
    * @notice A method that closes a specific expiry voting process.
    * @param _symbol Symbol for which the voting process should be closed
    */
    function closeEndOfLifeVote (
		string calldata _symbol
		)
		external
		{
		require(getEndOfLifeVotes[_symbol].exists,'VOTEID_UNKNOWN'); //checks if the vote id exists)
		require(getEndOfLifeVotes[_symbol].open,'VOTE_NOT_OPEN'); //checks if the vote is open)
		require(getEndOfLifeVotes[_symbol].endingTime < block.timestamp);  //checks if the voting period is over
		uint256 endOfLiveValue;
		getEndOfLifeVotes[_symbol].open = false;
		if (getEndOfLifeVotes[_symbol].numberOfVotingShares != 0) {
			 endOfLiveValue = getEndOfLifeVotes[_symbol].totalVoteValue.div(getEndOfLifeVotes[_symbol].numberOfVotingShares);
			 expiryVoteResults[getFreezeVotes[_symbol].voteID]  = endOfLiveValue;
			 allExpiryVotesByID[getFreezeVotes[_symbol].voteID].open = false;
			 allExpiryVotesByID[getFreezeVotes[_symbol].voteID].voteResult = endOfLiveValue;
		}
		else {
			endOfLiveValue =  0;
			expiryVoteResults[getFreezeVotes[_symbol].voteID]  = endOfLiveValue;
		}
		assetFactory.setEndOfLifeValue(_symbol,endOfLiveValue);
		delete(getEndOfLifeVotes[_symbol]);
	}

	/**
    * @notice A method to checks for a specific address and voteID if the freeze vote is qualifiying for rewards.
    * @param _rewardsRound The rewards round to get the data from
    *        _address Address to check
    */
    function checkExpiryVotes (
		uint256 _rewardsRound,
		address _address
		)
		external
		view
		returns (bool)
		{
		bool result = true;
		for (uint256 s = 0; s < expiryVotesToCheck[_rewardsRound][_address].length; s += 1){
	    	uint256 voteID = expiryVotesToCheck[_rewardsRound][_address][s].voteID;
	    	uint256 vote = expiryVotesToCheck[_rewardsRound][_address][s].vote;
	    	uint256 voteConsensusresult = expiryVoteResults[voteID];
	    	if ((vote > (voteConsensusresult * 102 / 100) || vote < (voteConsensusresult * 98 / 100)) && allExpiryVotesByID[voteID].open == false){
	    		result = false;
	    	}
	    	
       	}
		return (result);
		}

		


   	
   	/**
    * @notice A method to retrieve the reward points for an address.
    * @param _address The address to retrieve the stake for.
    * @return uint256 The amount of earned rewards points.
    */
   	function rewardPointsOf(
   		address _address
   		)
    	external
       	view
       	returns(uint256)
   		{
       	return rewardPointsSnapshots[currentRewardsRound.sub(1)].votingRewardpoints[_address];
   	}

   	/**
    * @notice A method to retrieve the reward points for an address adjusted for votes not yet closed.
    * @param _address The address to retrieve the stake for.
    * @return uint256 The amount of earned rewards points.
    */
   	function adjustedRewardPointsOf(
   		address _address
   		)
    	external
       	view
       	returns(uint256)
   		{
   		uint256 points = rewardPointsSnapshots[currentRewardsRound -1].votingRewardpoints[_address];
   		uint256 numberOfVotesToCheck = freezeVotesToCheck[currentRewardsRound -1][_address].length;
		for (uint256 s = 0; s < numberOfVotesToCheck; s += 1){
	    	uint256 voteID = freezeVotesToCheck[currentRewardsRound -1][_address][s].voteID;
	    	
	    	if (allFreezeVotesByID[voteID].open) {
	    		uint256 votingPoints = freezeVotesToCheck[currentRewardsRound -1][_address][s].votingPoints;
	    		points -= votingPoints;
	    	}
	    }

	    numberOfVotesToCheck = expiryVotesToCheck[currentRewardsRound -1][_address].length;
		for (uint256 s = 0; s < numberOfVotesToCheck; s += 1){
	    	uint256 voteID = expiryVotesToCheck[currentRewardsRound -1][_address][s].voteID;
	    	
	    	if (allExpiryVotesByID[voteID].open) {
	    		uint256 votingPoints = expiryVotesToCheck[currentRewardsRound -1][_address][s].votingPoints;
	    		points -= votingPoints;
	    	}

		}

       	return (points);
   	}

   	function addRewardPoints(
   		address _address, 
   		uint256 _amount
   		)
    	internal
   		{
	       	rewardPointsSnapshots[currentRewardsRound].votingRewardpoints[_address] = rewardPointsSnapshots[currentRewardsRound].votingRewardpoints[_address].add(_amount);
   	}

   	/**
    * @notice A method to add  reward points for an address. Can only be called by the DAO contract.
    * @param _address The address to retrieve the stake for.
    + @param _amount The amount of reward points to be added
    */	
   	function addRewardPointsDAO(
   		address _address, 
   		uint256 _amount
   		)
    	external
   		{
	       	require (msg.sender == DAOAddress);
	       	rewardPointsSnapshots[currentRewardsRound].votingRewardpoints[_address] = rewardPointsSnapshots[currentRewardsRound].votingRewardpoints[_address].add(_amount);
   	}

   	/**
    * @notice A method to add  total reward points. Can only be called by the DAO contract.
    + @param _amount The amount of total reward points to be added
    */	
   	function addTotalRewardPointsDAO(
   		uint256 _amount
   		)
    	external
   		{
	       	require (msg.sender == DAOAddress);
	       	rewardPointsSnapshots[currentRewardsRound].totalVotingRewardPoints = rewardPointsSnapshots[currentRewardsRound].totalVotingRewardPoints.add(_amount);
   	}




   	function getTotalRewardPoints()
	   	external
	   	view
	   	returns(uint256)
	   	{
	   		return (rewardPointsSnapshots[currentRewardsRound.sub(1)].totalVotingRewardPoints);
   	}

   	/**
    * @notice A method to reset all reward points to zero.
    */
   	function resetRewardPoints () 
    	external
   		{
	       	require (msg.sender == rewardsMachineAddress,'NOT_ALLOWED');
	       	currentRewardsRound = currentRewardsRound +1;
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math2 {

    
    /**
    * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
    * number.
    *
    * @param x unsigned 256-bit integer number
    * @return unsigned 128-bit integer number
    */
    function sqrtu (uint256 x) internal pure returns (uint128) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128 (r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "./Arrays.sol";
//import "./Counters.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Math2.sol";



/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter internal _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    // this fuctions allows to question the most recent snapshot id
    function snapshotID(
        )
        public
        view
        returns(uint256)
        {
            uint256 currentId = _currentSnapshotId.current();
            return (currentId);
        }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
//import "./IERC20.sol";
//import "./IERC20Metadata.sol";
//import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AssetToken.sol";

library issuaaLibrary {
	struct Asset {
    	address Token1; 
    	address Token2; 
    	string name;
    	string description;
    	uint256 upperLimit;
    	uint256 endOfLifeValue;
    	uint256 expiryTime;
    	bool frozen;
        bool expired;
    	bool exists;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMarketRouter01 {
    function factory() external view returns (address);
    

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    

    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint256[] memory);
    

    
    //function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    //function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    //function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    //function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts);
    //function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function numberOfHolders() external pure returns (uint256);
    function holders(uint256 _position) external pure returns (address);

    
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to) external;
    
    function initialize(address, address,address) external;
    function createSnapShot() external;
    function snapshotID() external view returns (uint256);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
    function totalSupplyAt(uint256 snapshotId) external view returns(uint256); 
        
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AssetToken.sol";
import "./TokenFactory.sol";
import "./RewardsMachine.sol";
import "./issuaaLibrary.sol";
import "./MarketFactory.sol";
import "./interfaces/IMarketPair.sol";
import "./interfaces/IMarketRouter01.sol";

//import "../interfaces/RewardsMachineInterface.sol";



contract AssetFactory is Ownable{
	using SafeMath for uint256;
	bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

	uint256 public feePool;
    uint256 public assetNumber;
	address private constant USDCaddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public tokenFactoryAddress;
    address public voteMachineAddress;
    address public rewardsMachineAddress;
    address public marketFactoryAddress;
    address public marketRouterAddress;
    address public IPTAddress;
    string[] public assets;
    mapping(string => issuaaLibrary.Asset) public getAsset;
    mapping (address => uint256) public harvestCooldown;

	constructor(
		address governanceTokenAddress, 
		address _tokenFactoryAddress
		) 
		Ownable() 
		{
		IPTAddress = governanceTokenAddress;
		tokenFactoryAddress = _tokenFactoryAddress;
	}
	
	event Freeze(
        string _symbol
    );

    event EndOfLiveValueSet (
    	string _symbol, 
    	uint256 _value
    );

    event Mint (
		string _symbol, 
		uint256 _amount
	) ;

    event Burn (
		string _symbol, 
		uint256 _amount
	); 

    event BurnExpired (
		string _symbol, 
		uint256 _amount1,
		uint256 _amount2
	); 

	event NewAsset (
		string _name, 
		string _symbol, 
		string _description, 
		uint256 _upperLimit
	);

	event BurnIPT (
		uint256 _amount, 
		address _address
	);

	/**
	* @notice A method to safely transfer ERV20 tokens.
	* @param _token Address of the token.
		_from Address from which the token will be transfered.
		_to Address to which the tokens will be transfered
		_value Amount of tokens to be sent.	
	*/
	function _transferFrom(
		address _token, 
		address _from, 
		address _to, 
		uint256 _value
		) 
		private 
		{
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, _from, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FAILED');
    }

	/**
	* @notice A method to set the address of the voting machine contract. Ownly executable for the owner.
	* @param _address Address of the voting machine contract.
	*/
	function setVoteMachineAddress (
		address _address
		) 
		external 
		onlyOwner
		{
		voteMachineAddress = _address;
	}

	/**
	* @notice A method to set the address of the voting machine contract. Ownly executable for the owner.
	* @param _address Address of the rewards machine contract.
	*/
	function setRewardsMachineAddress (
		address _address
		) 
		external 
		onlyOwner
		{
		rewardsMachineAddress = _address;
	}

	/**
	* @notice A method to set the address of the market factory contract. Ownly executable for the owner.
	* @param _address Address of the market factory contract.
	*/
	function setMarketFactoryAddress (
		address _address
		) 
		external 
		onlyOwner
		{
		marketFactoryAddress = _address;
	}

	/**
	* @notice A method to set the address of the market router contract. Ownly executable for the owner.
	* @param _address Address of the market router contract.
	*/
	function setMarketRouterAddress (
		address _address
		) 
		external
		onlyOwner
		{
		marketRouterAddress = _address;
	}

	/**
	* @notice A method to define ad create a new Asset.
	* @param _name Name of the new Asset.
		_symbol Symbol of the new Asset.
		_description Short description of the asset
		_upperLimit Upper limit of the assets, that defines when the asset is frozen.	
	*/
	function createAssets (
		string calldata _name, 
		string calldata _symbol, 
		string calldata _description, 
		uint256 _upperLimit
		) 
		external 
		onlyOwner
		{
		require (getAsset[_symbol].exists == false,'EXISTS'); assets.push(_symbol);
		assetNumber = assetNumber.add(1);
		getAsset[_symbol].name = _name;
		getAsset[_symbol].description = _description;
		getAsset[_symbol].Token1 = TokenFactory(tokenFactoryAddress).deployToken(_name,_symbol);
		getAsset[_symbol].Token2 = TokenFactory(tokenFactoryAddress).deployToken(_name,string(abi.encodePacked("i",_symbol)));
		getAsset[_symbol].upperLimit = _upperLimit;
		getAsset[_symbol].expiryTime = block.timestamp.add(365 days);
		getAsset[_symbol].exists = true;
		emit NewAsset ( _name, _symbol, _description, _upperLimit);
		//MarketFactory(marketFactoryAddress).createPair(getAsset[_symbol].Token1,USDCaddress);
		//MarketFactory(marketFactoryAddress).createPair(getAsset[_symbol].Token2,USDCaddress);
	}


	/**
	* @notice A method that checks if a specific asset does already exist.
	* @param _symbol Symbol of the asset to check.
	* @return bool Returns true if the asset exists and false if not.
	*/
	function assetExists (
		string calldata _symbol
		)
		external 
		view 
		returns(bool)
		{
		return(getAsset[_symbol].exists);
	}

	/**
	* @notice A method that checks if a specific asset is frozen.
	* @param _symbol Symbol of the asset to check.
	* @return bool Returns true if the asset is frozen or not.
	*/
	function assetFrozen (
		string calldata _symbol
		)
		external 
		view 
		returns(bool)
		{
		return(getAsset[_symbol].frozen);
	}
	
	/**
	* @notice A method that checks if a specific asset is marked as expired.
	* @param _symbol Symbol of the asset to check.
	* @return bool Returns true if the asset is expired or not.
	*/
	function assetExpired (
		string calldata _symbol
		)
		external 
		view 
		returns(bool)
		{
		return(getAsset[_symbol].expired);
	}

	/**
	* @notice A message that checks the expiry time of an asset.
	* @param _symbol Symbol of the asset to check.
	* @return uint256 Returns the expiry time as a timestamp.
	*/
	function getExpiryTime(
		string calldata _symbol
		)
		external 
		view 
		returns(uint256)
		{
		return (getAsset[_symbol].expiryTime);
	}


	/**
	* @notice A message that checks the upper limit an asset.
	* @param _symbol Symbol of the asset to check.
	* @return uint256 Returns the upper limit.
	*/
	function getUpperLimit(
		string calldata _symbol
		)
		external 
		view 
		returns(uint256)
		{
		return (getAsset[_symbol].upperLimit);
	}

	/**
	* @notice A message that checks the expiry price of an asset.
	* @param _symbol Symbol of the asset to check.
	* @return uint256 Returns the expiry price.
	*/
	function getExpiryPrice(
		string calldata _symbol
		) 
		external 
		view 
		returns(uint256)
		{
		return (getAsset[_symbol].endOfLifeValue);
	}

	/**
	* @notice A message that checks the token addresses for an asset symbol.
	* @param _symbol Symbol of the asset to check.
	* @return address, address Returns the long und short token addresses.
	*/
	function getTokenAddresses(
		string calldata _symbol
		) 
		external 
		view 
		returns(address,address)
		{
		return (getAsset[_symbol].Token1, getAsset[_symbol].Token2);
	}

	/**
	* @notice A message that mints a specific asset. The caller will get both long and short
	*         assets and will pay the upper limit in USD stable coins as a price.
	* @param _symbol Symbol of the asset to mint.
	*/
	function mintAssets (
		string calldata _symbol, 
		uint256 _amount
		) 
		external 
		{
		require (getAsset[_symbol].frozen == false && getAsset[_symbol].expiryTime > block.timestamp,'INVALID'); 
		IERC20(USDCaddress).transferFrom(msg.sender,address(this),_amount);
		uint256 USDDecimals = ERC20(USDCaddress).decimals();
		uint256 tokenAmount = _amount.mul(10**(18-USDDecimals)).mul(1000).div(getAsset[_symbol].upperLimit);
		TokenFactory(tokenFactoryAddress).mint(getAsset[_symbol].Token1, msg.sender, tokenAmount);
		TokenFactory(tokenFactoryAddress).mint(getAsset[_symbol].Token2, msg.sender, tokenAmount);
		emit Mint(_symbol, _amount);
	}

	/**
	* @notice A message that burns a specific asset to get USD stable coins in return.
	* @param _symbol Symbol of the asset to burn.
	*        _amount Amount of long and short tokens to be burned.
	*/
	function burnAssets (
		string calldata _symbol,
		uint256 _amount
		) 
		external 
		{
		require(getAsset[_symbol].expired == false,'EXPIRED');
		uint256 USDDecimals = ERC20(USDCaddress).decimals();
		uint256 amountOut = _amount.mul(getAsset[_symbol].upperLimit).div(10**(18-USDDecimals)).div(1000);
		
		if (getAsset[_symbol].frozen) {
			IERC20(USDCaddress).transfer(msg.sender,amountOut);
			AssetToken(getAsset[_symbol].Token1).transferFrom(msg.sender, address(this), _amount);
			AssetToken(getAsset[_symbol].Token2).transferFrom(msg.sender, address(this), AssetToken(getAsset[_symbol].Token2).balanceOf(msg.sender));
		}
		else {
			IERC20(USDCaddress).transfer(msg.sender,amountOut*99/100);
			feePool += amountOut*1/100;
			AssetToken(getAsset[_symbol].Token1).transferFrom(msg.sender, address(this), _amount);
			AssetToken(getAsset[_symbol].Token2).transferFrom(msg.sender, address(this), _amount);
		}
		emit Burn (_symbol, _amount);	
	}

	/**
	* @notice A method that burns a specific expired asset to get USD stable coins in return.
	* @param _symbol Symbol of the asset to burn.
	*        _amount1 Amount of the long token to be burned.
	*        _amount2 Amount of the short token to be burned.
	*/
	function burnExpiredAssets (
		string calldata _symbol, 
		uint256 _amount1, 
		uint256 _amount2
		) 
		external 
		{
		require(getAsset[_symbol].expired == true,'NOT_EXPIRED');
		require(getAsset[_symbol].frozen == false,'FROZEN');
		require(getAsset[_symbol].endOfLifeValue > 0,'VOTE_NOT_CLOSED');
		
		uint256 USDDecimals = ERC20(USDCaddress).decimals();
		uint256 valueShort = getAsset[_symbol].upperLimit.sub(getAsset[_symbol].endOfLifeValue);
		uint256 amountOut1 = _amount1.mul(getAsset[_symbol].endOfLifeValue).div(10**(18-USDDecimals)).div(1000);
		uint256 amountOut2 = _amount2.mul(valueShort).div(10**(18-USDDecimals)).div(1000);
        IERC20(USDCaddress).transfer(msg.sender,amountOut1.add(amountOut2));
        AssetToken(getAsset[_symbol].Token1).transferFrom(msg.sender, address(this), _amount1);
        AssetToken(getAsset[_symbol].Token2).transferFrom(msg.sender, address(this), _amount2);
        emit BurnExpired (_symbol, _amount1, _amount2);
	}

	/**
	* @notice A method that burns governance tokens to get USD stable coins in return.
	* @param _amount Amount of tokens to be burned
	*/
	function burnGovernanceToken (
		uint256 _amount
		) 
		external 
		{
		
		uint256 USDCAmount = (feePool.mul(_amount)).div(RewardsMachine(rewardsMachineAddress).maxIPTSupply());
		feePool = feePool.sub(USDCAmount);
		_transferFrom(IPTAddress,msg.sender, address(this), _amount);
		RewardsMachine(rewardsMachineAddress).burnAssetFactoryIPT(_amount);
		RewardsMachine(rewardsMachineAddress).reduceCurrentIPTSupply(_amount);
		IERC20(USDCaddress).transfer(msg.sender,USDCAmount);
		emit BurnIPT (_amount, msg.sender);
	}

    /**
	* @notice A method that freezes a specific asset. Can only be called by the votemachine contract.
	* @param _symbol Symbol of the asset to freeze.
	*/
    function freezeAsset(
    	string calldata _symbol
    	) 
    	external 
    	{
    	require(msg.sender == voteMachineAddress);
    	getAsset[_symbol].frozen = true;
    	emit Freeze (_symbol);
    }

    /**
	* @notice A method that sets the expiry value of a specific asset. Can only be called by the votemachine contract.
	* @param _symbol Symbol of the asset to freeze.
	*        _value Value of the asset at the expiry time
	*/
	function setEndOfLifeValue(
    	string calldata _symbol, 
    	uint256 _value
    	) 
    	external 
    	{
    	require(msg.sender == voteMachineAddress);
    	getAsset[_symbol].endOfLifeValue = _value;
    	getAsset[_symbol].expired = true;
    	emit EndOfLiveValueSet (_symbol,_value);
    }

    /**
	* @notice A method that unstakes liquidiy provider tokens, which have been earned as fees for the governance token.
	*         Asset tokens are then sold for USD stable coins.
	* @param _pairAddress Address of the market pair.
	*/
	function harvestFees(
    	address _pairAddress
    	)
    	external 
    	{
    	require (harvestCooldown[_pairAddress] < block.timestamp,'COOLDOWN');
    	harvestCooldown[_pairAddress] = (block.timestamp + 60 minutes);
    	address token0 = IMarketPair(_pairAddress).token0();
        address token1 = IMarketPair(_pairAddress).token1();

        // get balance
    	uint256 liquidity = IMarketPair(_pairAddress).balanceOf(address(this));
    	// burn balance
    	IMarketPair(_pairAddress).approve(marketRouterAddress,liquidity);
    	(uint256 amount0, uint256 amount1) = IMarketRouter01(marketRouterAddress).removeLiquidity(token0,token1,liquidity,0,0,address(this),block.timestamp.add(1 hours));
        //uint256 tokenAmt = token0 == USDCaddress ? amount1 : amount0;
        uint256 usdAmt = token0 == USDCaddress ? amount0 : amount1;
        address tokenAddress = token0 == USDCaddress ? token1 : token0;
        uint256 tokenAmt = AssetToken(tokenAddress).balanceOf(address(this));
    	
    	// trade asset against USD
    	IERC20(tokenAddress).approve(marketRouterAddress,tokenAmt);
    	address[] memory path = new address[](2);
    	path[0] = tokenAddress;
   		path[1] = USDCaddress;
   		
   		(uint256 _reserve0, uint256 _reserve1) = IMarketPair(_pairAddress).getReserves();
   		(uint256 tokenReserves, uint256 USDCReserves) = tokenAddress < USDCaddress ? (_reserve0,_reserve1) : (_reserve1,_reserve0);
   		if (tokenAmt > tokenReserves * 6 / 1000) {tokenAmt = tokenReserves * 6 / 1000;}
   		uint256 expectedUSDCAmt = USDCReserves - ((tokenReserves * USDCReserves)/(tokenAmt + tokenReserves));
   		
   		uint256 minUSDCAmt = expectedUSDCAmt.mul(99).div(100);
    	uint256[] memory amounts = IMarketRouter01(marketRouterAddress).swapExactTokensForTokens(tokenAmt,minUSDCAmt,path,address(this),block.timestamp.add(1 hours));
    	usdAmt = usdAmt.add(amounts[1]);
    	feePool += usdAmt;
    	
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "./openzeppelin/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AssetToken.sol";



	contract TokenFactory is Ownable{
	//using SafeMath for uint256;

	/**
    * @notice A method that deploys a new token contract.
    * @param  _name Name of the asset
    *         _symbol Symbol of the new asset token
    *         _description Description of the new asset
    *         _upperLimit Upper limit set for this asset
    */
    function deployToken (
		string calldata _name, 
		string calldata _symbol
		)
		external 
		onlyOwner 
		returns (address)
		{
		address token = address(new AssetToken(_name,_symbol));
		return (token);
	}


	/**
    * @notice A method that adds mints new tokens. Can only be issued by the owner, which is the Asset Factory contract.
    * @param  _token Address of the token to mint
    *         _to Address that shall receive the newly minted tokens
    *         _amount Amount of new tokens to be minted (in WEI)
    */
    function mint (
		address _token,
		address _to,
		uint256 _amount
		)
		external
		onlyOwner
		{
		AssetToken(_token).mint(_to, _amount);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarketFactory.sol";
import "./GovernanceToken.sol";
import "./VoteMachine.sol";
//import "./issuaaLibrary.sol";
import "./interfaces/IMarketPair.sol";
import "./assetFactory.sol";

contract RewardsMachine is Ownable{
	using SafeMath for uint256;
    uint256 public nextRewardsPayment = 1633273200;
    uint256 public currentIPTSupply;
    uint256 constant public maxIPTSupply = 100000000 * (10 ** 18);
    uint256 constant public maxBonusPools = 250;
    
    uint256 public rewardsRound;
    mapping (address => uint256) public lastRewardsRound;

    GovernanceToken public governanceToken;
    VoteMachine public voteMachine;
    
    
	
	address constant private USDCaddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address public voteMachineAddress;
    address public assetFactoryAddress;
    address public marketFactoryAddress;
    uint256 constant public vestingPeriod = 180 days;
    uint256 public LPRewardTokenNumber;
    uint256 public votingRewardTokenNumber;
    bool public IPTBonusPoolAdded = false;

    address[] public pools;
    mapping(string =>bool) public poolExists;
    uint256 public numberOfPools; 

	constructor(GovernanceToken _governanceToken) Ownable() {
		governanceToken = _governanceToken;
		currentIPTSupply = 40000000 * (10 ** 18);
		
  	}
	event currentIPTSupplyReduced(
        uint256 _amount
    );
    event rewardPoolAdded(
        string _symbol
    );
    event IPTPoolAdded(
        address _poolAddress
    );

	/**
    * @notice A method that set the address of the VoteMachine contract.
    * @param  _address Address of the VoteMachine contract
    */
    function setVoteMachineAddress (
		address _address
		)
		public
		onlyOwner
		{
		voteMachineAddress = _address;
	}

    /**
    * @notice A method that set the address of the VoteMachine contract.
    * @param  _address Address of the VoteMachine contract
    */
    function setMarketFactoryAddress (
        address _address
        )
        public
        onlyOwner
        {
        marketFactoryAddress = _address;
    }

	/**
    * @notice A method that set the address of the AssetFactory contract.
    * @param  _address Address of the AssetFactory contract
    */
    function setAssetFactoryAddress (
		address _address
		) 
		public
		onlyOwner
		{
		assetFactoryAddress = _address;
	}

	
	/**
    * @notice A method that reduced the variable currentIPTSupply.
    *         currentIPTsupple keeps track of the amount of governace token, which is important
    *         to keep reducing the rewards to ot let the issued amount exceed the max value.
    *         this function is used when givernance tokens are burned.
    * @param  _amount Amount by which the currentIPTsupply is reduced.
    */
    function reduceCurrentIPTSupply(
		uint256 _amount
		) 
		external 
		{
		require (msg.sender == assetFactoryAddress,'Not authorized');
		currentIPTSupply = currentIPTSupply.sub(_amount);
        emit currentIPTSupplyReduced(_amount);
	}

    /**
    * @notice A method that burns IPT owned by the assetFactory contract.
    * @param  _amount Amount ofIPT which is burned.
    */
    function burnAssetFactoryIPT(
        uint256 _amount
        ) 
        external 
        {
        require (msg.sender == assetFactoryAddress,'Not authorized');
        governanceToken.burn(assetFactoryAddress, _amount);
    }

	/**
    * @notice A method that lets an external contract fetch the current supply of the governance token.
    */
    function getCurrentSupply() 
		external
		view 
		returns (uint256) 
		{
		return (currentIPTSupply);
	}

	/**
    * @notice A method that adds a market pair to the list of pools, which will get rewarded.
    * @param  _symbol Address of the asset, for which the new pool is generated
    */
    function addPools(
		string calldata _symbol
		) 
		external
        onlyOwner
		{
		require (pools.length+2 <= maxBonusPools,'TOO_MANY_POOLS');
        require(poolExists[_symbol] == false,'POOL_EXISTS_ALREADY');
        require(AssetFactory(assetFactoryAddress).assetExists(_symbol),'UNKNOWN_SYMBOL');
        (address token1,address token2) = AssetFactory(assetFactoryAddress).getTokenAddresses(_symbol);
        address pair1 = MarketFactory(marketFactoryAddress).getPair(token1,USDCaddress);
        address pair2 = MarketFactory(marketFactoryAddress).getPair(token2,USDCaddress);
        require (pair1 != address(0) && pair2 != address(0),"PAIR_DOES_NOT_EXIST");
        poolExists[_symbol] = true;
        pools.push(pair1);
        pools.push(pair2);
		numberOfPools +=2;
        emit rewardPoolAdded(_symbol);
	}

    /**
    * @notice A method that adds the IPT MarketPool.
    * @param  _poolAddress Address of the pool, for which the new pool is generated
    */
    function addIPTBonusPool(
        address _poolAddress
        ) 
        external
        
        {
        require(IPTBonusPoolAdded == false,'POOL_EXISTS_ALREADY');
        
        pools.push(_poolAddress);
        numberOfPools +=1;
        IPTBonusPoolAdded = true;
        emit IPTPoolAdded(_poolAddress);
    }
    

    /**
    * @notice A method that creates the weekly reward tokens. Can only be called once per week.
    */
    function createRewards() 
    	external 
    	{
    	require(nextRewardsPayment<block.timestamp,'TIME_NOT_UP');
    	votingRewardTokenNumber = maxIPTSupply.sub(currentIPTSupply).mul(20).mul(3).div(100).div(100);
    	LPRewardTokenNumber = maxIPTSupply.sub(currentIPTSupply).mul(3).div(100) - votingRewardTokenNumber;

    	//SNAPSHOT FOR THE LP TOKEN HOLDERS
	    for (uint256 s = 0; s < numberOfPools; s += 1){
	    	address poolAddress = pools[s];
	    	IMarketPair(poolAddress).createSnapShot();
	    }

	    nextRewardsPayment = block.timestamp.add(7 days);
	    VoteMachine(voteMachineAddress).resetRewardPoints();
	    rewardsRound = rewardsRound.add(1);
    }


    /**
    * @notice A method that claims the rewards for the calling address.
    */
    function claimRewards()
    	external
        returns (uint256)
    	{
    		require (lastRewardsRound[msg.sender]<rewardsRound-1,'CLAIMED_ALREADY');
            VoteMachine(voteMachineAddress).checkVotesIfClosed(rewardsRound - 1,msg.sender); 
            require(VoteMachine(voteMachineAddress).checkFreezeVotes(rewardsRound - 1,msg.sender),'VOTE_NOT_CONSENSUS');
            
            require(VoteMachine(voteMachineAddress).checkExpiryVotes(rewardsRound - 1,msg.sender),'VOTE_NOT_CONSENSUS');
    		lastRewardsRound[msg.sender] = rewardsRound - 1;
    		
            //Voting rewards
    		uint256 votingRewardPoints = VoteMachine(voteMachineAddress).rewardPointsOf(msg.sender);
    		uint256 totalVotingRewardPoints = VoteMachine(voteMachineAddress).getTotalRewardPoints();
    		uint256 votingRewards;
    		if (totalVotingRewardPoints > 0) {
    			votingRewards = votingRewardTokenNumber.mul(votingRewardPoints).div(totalVotingRewardPoints);	
    		}
    		else {
    			votingRewards = 0;
    		}
    		
    		
    		
    		//LP Rewards
    		uint256 LPRewards;

    		for (uint256 s = 0; s < numberOfPools; s += 1){
	    		address poolAddress = pools[s];
	    		uint256 rewards;
	    		uint256 snapshotID = IMarketPair(poolAddress).snapshotID();
	    		
	    		uint256 LPTokenBalance = IMarketPair(poolAddress).balanceOfAt(msg.sender, snapshotID);
	    		uint256 LPTokenTotalSupply = IMarketPair(poolAddress).totalSupplyAt(snapshotID);

	    		
                if (LPTokenTotalSupply >0){
	    			rewards = LPRewardTokenNumber.mul(LPTokenBalance).div(LPTokenTotalSupply).div(numberOfPools);
	    			}
	    		else{
	    			rewards = 0;	
	    		}
	    		
	    		LPRewards = LPRewards.add(rewards);
            }
    		
    		

    		uint256 totalRewards = votingRewards.add(LPRewards);
    		currentIPTSupply = currentIPTSupply.add(totalRewards);
    		governanceToken.mintAndVest(msg.sender, totalRewards.mul(80).div(100),vestingPeriod);
		    governanceToken.mint(msg.sender, totalRewards.mul(20).div(100));
			return (totalRewards);

    	}

    /**
    * @notice A method that gets the pending rewards for a specific address.
    * @param  _address Address for the pending rewards are checked
    */
    function getRewards(address _address)
    	external
    	view
        returns (uint256)
    	{
    		if (lastRewardsRound[_address]>=rewardsRound-1){return 0;}

    		//Voting rewards
    		uint256 votingRewardPoints = VoteMachine(voteMachineAddress).adjustedRewardPointsOf(_address);
    		uint256 totalVotingRewardPoints = VoteMachine(voteMachineAddress).getTotalRewardPoints();
    		uint256 votingRewards;
    		if (totalVotingRewardPoints > 0) {
    			votingRewards = votingRewardTokenNumber.mul(votingRewardPoints).div(totalVotingRewardPoints);	
    		}
    		else {
    			votingRewards = 0;
    		}
    		
    		
    		
    		//LP Rewards
    		uint256 LPRewards;

    		for (uint256 s = 0; s < numberOfPools; s += 1){
	    		address poolAddress = pools[s];
	    		uint256 rewards;
	    		uint256 snapshotID = IMarketPair(poolAddress).snapshotID();
	    		
	    		uint256 LPTokenBalance = IMarketPair(poolAddress).balanceOfAt(_address, snapshotID);
	    		uint256 LPTokenTotalSupply = IMarketPair(poolAddress).totalSupplyAt(snapshotID);

	    		if (LPTokenTotalSupply >0){
	    			rewards = LPRewardTokenNumber.mul(LPTokenBalance).div(LPTokenTotalSupply).div(numberOfPools);
	    			}
	    		else{
	    			rewards = 0;	
	    		}
	    		
	    		LPRewards = LPRewards.add(rewards);
            }
    		
    		

    		uint256 totalRewards = votingRewards.add(LPRewards);
    		return (totalRewards);

    	}
}

// SPDX-License-Identifier: MIT

// The market functionality has been largely forked from uiswap.
// Adaptions to the code have been made, to remove functionality that is not needed,
// or to adapt to the remaining code of this project.
// For the original uniswap contracts plese see:
// https://github.com/uniswap
//

pragma solidity ^0.8.0;
//import "./interfaces/IERC20I.sol";
import "./interfaces/IMarketFactory.sol";
//import "./openzeppelin/Math.sol";
import './MarketERC20.sol';


contract MarketPair is MarketERC20{
	
	using SafeMath for uint256;


	bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
	bytes4 private constant SELECTOR1 = bytes4(keccak256(bytes('transfer(address,uint256)')));
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast;
    address public token0;
    address public token1;
    address public factory;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
   
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    address rewardsMachineAddress;
    address[] public holdersSnapShot;
    




	constructor()   {
		factory = msg.sender;
        }
	
  	// called once by the factory at time of deployment
    function initialize(
        address _token0, 
        address _token1,
        address _rewardsMachineAddress)
        external 
        {
        require(msg.sender == factory, 'FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        rewardsMachineAddress = _rewardsMachineAddress;
    }

  	event Mint(
        address indexed sender, 
        uint256 amount0, 
        uint256 amount1
    );

    event Burn(
        address indexed sender, 
        uint256 amount0, 
        uint256 amount1, 
        address indexed to
    );

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    event Sync(
        uint112 reserve0, 
        uint112 reserve1
    );


	function _safeTransferFrom(
        address token, 
        address from, 
        address to, 
        uint256 value
        ) 
        private 
        {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

	function _safeTransfer(
        address token, 
        address to, 
        uint256 value
        ) 
        private 
        {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR1, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function getReserves()
        public 
        view 
        returns (uint112 _reserve0, uint112 _reserve1) 
        {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        
        return (_reserve0, _reserve1);
    }

    // update reserves
    function _update(
        uint balance0, 
        uint balance1
        ) 
        private
        {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrtu(k)
    function _mintFee(
        uint112 _reserve0, 
        uint112 _reserve1
        ) 
        private 
        returns (bool feeOn) 
        {
        address feeTo = IMarketFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math2.sqrtu(uint(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math2.sqrtu(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply().mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = (numerator) / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
        return feeOn;
    }




    // this low-level function should be called from a contract which performs important safety checks
    function mint(
        address to
        ) 
        external 
        returns (uint256 liquidity) 
        {
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = (Math2.sqrtu(amount0.mul(amount1)))-(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'INSUFFICIENT_LIQ');
        _mint(to, liquidity);

        _update(balance0, balance1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
        return (liquidity);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(
        address to
        ) 
        external 
        returns (uint256 amount0, uint256 amount1) 
        {
        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'INSUFF_LIQ_BURN');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
        return (amount0, amount1);
    }


    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out, 
        uint256 amount1Out, 
        address to
        ) 
        external 
        {
        require(amount0Out > 0 || amount1Out > 0, 'INSUF_OUTPUT');
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'INSUF_LIQ');

        uint256 balance0;
        uint256 balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'INSUF_INPUT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), ': K-FACTOR');
        }

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }



    // this function creates a snapshot, which is used for calculating rewards
    function createSnapShot(
        ) 
        external 
        {
            require (msg.sender == rewardsMachineAddress, 'NOT_ALLOWED1');
            holdersSnapShot = holders;
            _snapshot();

    }

}

// SPDX-License-Identifier: MIT

// The market functionality has been largely forked from uiswap.
// Adaptions to the code have been made, to remove functionality that is not needed,
// or to adapt to the remaining code of this project.
// For the original uniswap contracts plese see:
// https://github.com/uniswap
//

pragma solidity ^0.8.0;

import './interfaces/IMarketFactory.sol';
import './MarketPair.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketFactory is IMarketFactory, Ownable{
    address public override feeTo;
    address public override feeToSetter;
    address public rewardsMachineAddress;

    address private constant USDCAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

   

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;
    }


    /**
    * @notice A method that sets the RewardsMachine contract address
    * @param _address Address of the RewardsMachine contract
    */
    function setRewardsMachineAddress (
        address _address
        )
        external
        onlyOwner
        {
        rewardsMachineAddress = _address;
    }


    /**
    * @notice A method that returns the number of market pairs.
    */
    function allPairsLength() 
        external 
        view 
        override 
        returns (uint256) 
        {
        return allPairs.length;
    }

    
    

    /**
    * @notice A method that creates a new market pair for to tokens.
    * @param tokenA The first token in the pair
    *        tokenB The second token in the pair
    */
    function createPair(
        address tokenA, 
        address tokenB
        ) 
        external 
        override 
        returns (address pairAddress) 
        {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        require(tokenA == USDCAddress || tokenB == USDCAddress,'PAIR_NEEDS_TO_INCLUDE_USDC');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'PAIR_EXISTS'); // single check is sufficient
        
        bytes memory bytecode = type(MarketPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pairAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        MarketPair(pairAddress).initialize(token0, token1, rewardsMachineAddress);
        getPair[token0][token1] = pairAddress;
        getPair[token1][token0] = pairAddress; // populate mapping in the reverse direction
        allPairs.push(pairAddress);
        emit PairCreated(token0, token1, pairAddress, allPairs.length);
        return pairAddress;
    }


    /**
    * @notice A method that sets the receiver of a trading fee.
    * @param _feeTo The address that will receive the trading fee
    */
    function setFeeTo(
        address _feeTo
        ) 
        external 
        override 
        {
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        feeTo = _feeTo;
    }

    /**
    * @notice A method that sets the address that that can set the receiver of the fees..
    * @param _feeToSetter Address that will be the new address that is allowed to set the fee.
    */
    function setFeeToSetter(
        address _feeToSetter
        )
        external 
        override 
        {
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: MIT

// The market functionality has been largely forked from uiswap.
// Adaptions to the code have been made, to remove functionality that is not needed,
// or to adapt to the remaining code of this project.
// For the original uniswap contracts plese see:
// https://github.com/uniswap
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./openzeppelin/ERC20Snapshot.sol";
import "./openzeppelin/Math2.sol";


contract MarketERC20 is ERC20Snapshot{
    using SafeMath for uint256;

    string public override constant name = 'ISSUAA LP Token';
    string public override constant symbol = 'ILPT';
    uint8 public override constant decimals = 18;
    //mapping (address => uint256) private _balances;
    //uint256 internal _totalSupply;
    
    uint256 public numberOfHolders;
    address[] public holders;
    
    //bytes32 public DOMAIN_SEPARATOR;
    //bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    //mapping(address => uint256) public nonces;

    constructor() ERC20(name, symbol) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        //DOMAIN_SEPARATOR = keccak256(
        //    abi.encode(
        //        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        //        keccak256(bytes(name)),
        //        keccak256(bytes('1')),
        //        chainId,
        //        address(this)
        //    )
        //);
    }






    // allows transfer to zero instead of the normal ERC20 _mint function
    function _mint(address account, uint256 amount) internal override {
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovernanceToken is Ownable, ERC20 {
  using SafeMath for uint256;

  address public voteMachineAddress;
  address public DAOAddress;

  address[] internal stakeholders;

  mapping(address => uint256) internal stakes;

  mapping(address => uint256[2][]) public vestingSchedules;

  
  mapping (address =>bool) public isStakeholder;
  uint256 public numberOfStakeholders;
  uint256 public totalStakes;
  uint256 public constant maxVestingEntries = 52*3;



  constructor () ERC20("Issuaa Protocol Token", "IPT") {    
    
  }

  /**
  * @notice A method that sets the address of the vote machine contract.
  * @param _address Address of the vote machine contract.
  */
  function setVoteMachineAddress(
    address _address
    ) 
    external 
    onlyOwner 
    {
    voteMachineAddress = _address;
    }

  /**
  * @notice A method that sets the address of the DAO contract.
  * @param _address Address of the DAO contract.
  */
  function setDAOAddress(
    address _address
    ) 
    external 
    onlyOwner 
    {
    DAOAddress = _address;
    }


  /**
  * @notice A method that mints new governance tokens. Can only be called by the owner.
  * @param _address Address that receives the governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  */
  function mint(
    address _address, 
    uint256 _amount
    ) 
    external 
    onlyOwner 
    {
  	_mint(_address, _amount);
  }

  /**
  * @notice A method that mints and automatically vests new governance tokens. Can only be called by the owner.
  * @param _address Address that receives the governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  *        _time Time for which the stake is locked
  */
  function mintAndVest(
    address _address,
    uint256 _amount, 
    uint256 _time
    ) 
    external 
    onlyOwner 
    {
    require (_time < 731 days,"VESTING_PERIOD_TOO_LONG");
    require (vestingSchedules[_address].length<maxVestingEntries,"TOO_MANY_VESTING_ENTRIES");

    if (stakes[_address] == 0) {
      isStakeholder[_address] = true;
      numberOfStakeholders = numberOfStakeholders + 1;
    }
    stakes[_address] = stakes[_address].add(_amount);
  	vestingSchedules[_address].push([block.timestamp.add(_time),_amount]);
  }

  /**
  * @notice A method that transfers and vests governance tokens.
  * @param _address Address that receives the staked and vesting governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  *        _time Time for which the stake is locked
  */
  function transferAndVest(
    address _address, 
    uint256 _amount,
    uint256 _time
    )
    external
    {
      require (_time < 731 days,"VESTING_PERIOD_TOO_LONG");
      require (vestingSchedules[_address].length<10,"TOO_MANY_VESTING_ENTRIES");
      require (_amount > 999 * (10**18),'AMOUNT_TOO_LOW');
      _burn(msg.sender, _amount);
      if (stakes[_address] == 0) {
        isStakeholder[_address] = true;
        numberOfStakeholders = numberOfStakeholders + 1;
      }
      stakes[_address] = stakes[_address].add(_amount);
      vestingSchedules[_address].push([block.timestamp.add(_time),_amount]);

    }
  



  /**
  * @notice A method that burns governance tokens. Can only be called by the owner.
  * @param _address Address that receives the governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  */
  function burn(
    address _address,
    uint256 _amount
    ) 
    external 
    onlyOwner {
    _burn(_address, _amount);
  }

  

  

  /**
  * @notice A method to retrieve the stake for a stakeholder.
  * @param _stakeholder The stakeholder to retrieve the stake for.
  * @return uint256 The amount of wei staked.
  */
  function stakeOf(
    address _stakeholder
    )
  	public
    view
    returns(uint256)
  	{
     	return stakes[_stakeholder];
  }

  /**
  * @notice A method to the aggregated stakes from all stakeholders.
  * @return uint256 The aggregated stakes from all stakeholders.
  */
  /*function totalStakes()
   	public
   	view
   	returns(uint256)
  	{
   	uint256 _totalStakes = 0;
   	for (uint256 s = 0; s < stakeholders.length; s += 1){
    	_totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
   	}
   	return _totalStakes;
  }
  */

  /**
  * @notice A method for a stakeholder to create a stake.
  * @param _stake The size of the stake to be created.
  */
  function createStake(
    uint256 _stake
    )
  	public
  	{
       	_burn(msg.sender, _stake);
       	if(stakes[msg.sender] == 0) {
          isStakeholder[msg.sender] = true;
          numberOfStakeholders = numberOfStakeholders + 1;
        }
       	stakes[msg.sender] = stakes[msg.sender].add(_stake);
        totalStakes = totalStakes + _stake;
  }


  /**
  * @notice A method for a stakeholder to remove a stake.
  * @param _stake The size of the stake to be removed.
  */
  function removeStake(
    uint256 _stake
    )
  	public
  	{
   	uint256 freeStake = stakes[msg.sender] - getVestingStake(msg.sender);
   	
   	require (freeStake >= _stake,'Not enough free stake');

   	stakes[msg.sender] = stakes[msg.sender].sub(_stake);
   	if(stakes[msg.sender] == 0) {
      isStakeholder[msg.sender] = false;
      numberOfStakeholders = numberOfStakeholders - 1;
    }
   	_mint(msg.sender, _stake);

   	for (uint256 i = 0; i < vestingSchedules[msg.sender].length; i += 1){
  		if(vestingSchedules[msg.sender][i][0] < block.timestamp) {
        vestingSchedules[msg.sender][i] = vestingSchedules[msg.sender][vestingSchedules[msg.sender].length-1];
        vestingSchedules[msg.sender].pop();
        
      }
  	}

    totalStakes = totalStakes - _stake;
  }

  /**
  * @notice A method to get the vesting schedule of a stakeholder
  * @param _stakeholder The address of the the stakeholder
  */
  function vestingSchedule(
    address _stakeholder
    )
  	public
  	view
  	returns(uint256[2][] memory)
  	{
   	uint256[2][] memory schedule = vestingSchedules[_stakeholder];
   	return schedule;
  }
   		
  /**
  * @notice A method to get the currently vesting stake of a stakeholder
  * @param _address The address of the the stakeholder
  */
 	function getVestingStake(
    address _address
    )
 		public
 		view
 		returns (uint256)
 		{
		uint256[2][] memory schedule = vestingSchedule(_address);
 		uint256 vestedStake = 0;
 		for (uint256 i=0; i < schedule.length;i++){
 		  if (schedule[i][0] > block.timestamp) {vestedStake = vestedStake.add(schedule[i][1]);}
 		  }
 		return vestedStake;
 	}


  /**
  * @notice A method to increase the minimum vesting period to a given timestamp.
  * @param _address The address of the the stakeholder
  *        _timestamp The time until when the vesting is prolonged
  */
  function setMinimumVestingPeriod(
    address _address,
    uint256 _timestamp
    )
    internal
    {
    require (_timestamp < block.timestamp + 731 days,"VESTING_PERIOD_TOO_LONG");
    uint256[2][] memory schedule = vestingSchedule(_address);
    for (uint256 i=0; i < schedule.length;i++){
      if (schedule[i][0] < _timestamp && schedule[i][0] > block.timestamp) {vestingSchedules[_address][i][0] = _timestamp;}
      }
    }


  /**
  * @notice A method to get the locked stake of a stakeholder at a given time
  * @param _address The address of the the stakeholder
  * @param _time The time in the future
  */
  function getFutureLockedStake(
    address _address, 
    uint256 _time
    )
    public
    view
    returns (uint256)
    {
    uint256[2][] memory schedule = vestingSchedule(_address);
    uint256 lockedStake = 0;
    for (uint256 i=0; i < schedule.length;i++){
      if (schedule[i][0] > _time) {lockedStake = lockedStake.add(schedule[i][1]);}
      }
    return lockedStake;
  }

 	/**
  * @notice A method for a stakeholder to lock a stake.
  * @param _stake The size of the stake to be vested.
  		 _time The time until the stake becomes free again in seconds
  */
  /**
 	function lockStake(
    uint256 _stake, 
    uint256 _time
    )
  	public
 		{
    require (_time < 731 days,"VESTING_PERIOD_TOO_LONG");
    uint256[2][] memory schedule = vestingSchedule(msg.sender);
    uint256 lockedStake = 0;
    for (uint256 i=0; i>schedule.length;i++){
   	  if (schedule[i][0] > block.timestamp) {lockedStake = lockedStake.add(schedule[i][1]);}
   	  
    }
    uint256  currentStake = stakeOf(msg.sender);
    uint256  unlockedStake = currentStake.sub(lockedStake);
    require (unlockedStake >= _stake,'Not enough free stake available');
    vestingSchedules[msg.sender].push([block.timestamp.add(_time),_stake]);
  }
  **/

  /**
  * @notice A method for that locks a stake during a voting process.
  * @param
    _address Address that will locks its stake 
    _stake The size of the stake to be locked.
    _timestamp The timestamp of the time until the stake is locked
  */
  function lockStakeForVote(
    address _address, 
    uint256 _timestamp
    )
    external
    {
    require (msg.sender == voteMachineAddress || msg.sender == DAOAddress,"NOT_VM_ADRESS");
    uint256[2][] memory schedule = vestingSchedule(_address);
    uint256 lockedStake = 0;
    for (uint256 i=0; i < schedule.length;i++){
      if (schedule[i][0] > block.timestamp) {lockedStake = lockedStake.add(schedule[i][1]);}
      
    }
    uint256  currentStake = stakeOf(_address);
    uint256  unlockedStake = currentStake.sub(lockedStake);
    vestingSchedules[_address].push([_timestamp,unlockedStake]);
    setMinimumVestingPeriod(_address,_timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin/ERC20.sol";

contract AssetToken is Ownable, ERC20 {
//	string public _name;
//	string public _symbol;


    constructor (
    	string memory _name, 
    	string memory _symbol
    	)
    	 
    	ERC20(_name,_symbol)
    	{}

    /**
	* @notice A method that mints new tokens. Can only be called by the owner, which is the token factory contract.
	* @param _account Address of the account that receives the tokens.
	*        _amount Amount of tokens to be minted (in WEI).
	*/
	function mint(
    	address _account, 
    	uint256 _amount
    	) 
    	external 
    	onlyOwner 
    	{
        _mint(_account, _amount);
    }

    /**
	* @notice A method that burns tokens. Can only be called by the owner, which is the token factory contract.
	* @param _account Address of the account that burns the tokens.
	*        _amount Amount of tokens to be burned (in WEI).
	*/
	function burn(
    	address _account, 
    	uint256 _amount
    	) 
    	external 
    	onlyOwner 
    	{
        _burn(_account, _amount);
    }

    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}