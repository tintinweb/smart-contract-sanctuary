// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./BEP20.sol";
import "./extensions/BEP20Capped.sol";
import "./Ownable.sol";

interface ITokenReceiver {
    function tokenTransferFallback(address _sender, uint256 _value, bytes memory _extraData) external returns (bool);
}

contract HazelToken is BEP20Capped, Ownable{

	struct AddressDetails {
		bool walletBalanceCapExempt;
		bool transactionLimitExcempt;
		bool isDerogated;
		bool isDerogatedWithPropagation;
		uint256 totalAmountInCharity;
		bool voteRightRevoked;
		uint latestVoteExpiryDate;
		string signature;
	}

	struct CharityCause {
		uint256 rate;
		uint expiryDate;
		address collectorAddress;
		uint initiatorBallotId;
	}

	struct Ballot {
		uint issueId;
		string description;
		uint expiryDate;
		MotionType motionType;
		uint256 motionTargetValue;
		address motionTargetAddress;
		uint motionTargetDate;
		uint256 currentValue;
		uint256 totalWealthInFavor;
		uint256 totalHoldersInFavor;
		uint256 totalWealthAgainst;
		uint256 totalHoldersAgainst;
		address chairperson;
		bool executed;
		bool motionPassed;
		uint256 escrowAmount;
		MotionFailReason executionResultReason;
	}

	struct Vote {
		bool voted;
		bool inFavor;
		uint timestamp;
	}

	enum TransactionDirection {
		In,
		Out
	}

	enum MotionType {
		Generic,
		WalletMaxBalance,
		TxMaxValue,
		CreatorBurnRate,
		BallotFee,
		BallotEscrow,
		BallotLifespan,
		BallotExecWindow,
		BallotTotalSupplyExecMargin,
		BallotTurnoutMargin,
		BallotInFavExecMargin,
		BallotVoterWealthExecMargin,
		ExemptAddressMaxWalletBalance,
		RevertAddressMaxWalletBalanceExemption,
		ExemptAddressMaxTxValue,
		RevertAddressMaxTxValueExemption,
		RevokeAddressRightToVote,
		GrantAddressRightToVote,
		MintTokensToAddress,
		BurnAmountFromAddress,
		LaunchCharitableEvent,
		SubmitDerogatedAddress,
		RemoveDerogatedAddress,
		SubmitDerogatedWithPropagationAddress,
		RemoveDerogatedWithPropagationAddress,
		DisableVotingSystem
	}

	enum MotionFailReason {
		None,
		VoteTurnoutNotMet,
		VoteTurnoutWealthMarginNotMet,
		VoteTurnoutMarginNotMet,
		VotesInFavorMarginNotMet,
		WealthInFavorMarginNotMet
	}

	uint public _holders;

	address private immutable _creator;
	address private immutable _voteFeeCollector;

	uint256 private _maxTxValue;
	uint256 private _maxWalletBalance;
	uint256 private _creatorBurnRate;
	uint256 private _totalAmountInDerogatedAddresses;
	uint256 private _totalAmountInAccountsWithoutVoteRight;
	uint256 private _latestCharityCause;

	uint256 private _ballotFee;
	uint256 private _ballotEscrow;
	uint private _ballotLifespan;  //expressed in minutes
	uint private _ballotExecWindow; //expressed in minutes
	uint private _ballotLastIssueId; 

	uint256 private _ballotTurnoutWealthMargin;
	uint256 private _ballotTurnoutMargin;
	uint256 private _ballotVotesInFavorPercentageMargin;
	uint256 private _ballotWealthInFavorPercentageMargin;

	bool private _votingEnabled;

	mapping(address => AddressDetails) _addressDetails;

	mapping(uint => Ballot) _ballots;
	mapping(address => mapping(MotionType => uint)) _addressVoteBulletins;
	mapping(address => mapping(uint => Vote)) _addressVotedBallots;

	mapping(uint => CharityCause) _charityCauses;

	constructor(string memory name, string memory symbol)
		BEP20 (name, symbol)
		BEP20Capped(900000000 * 1 ether)
	{	
		_maxTxValue = 900000000 * 1 ether; //initially set to totalSupply
		_maxWalletBalance = 9000000 *  1 ether;
		_creatorBurnRate = 1000;

		_creator = _msgSender();
		BEP20._mint(_msgSender(), 900000000 * 1 ether);
		_holders = 1;
		addDerogatedWithPropagation(_creator);
		revokeVoteRight(_creator);
			
		_voteFeeCollector = 0x82aD0323F61b6F4202ecb99453Ccb41C141FB9f4;
		addDerogated(_voteFeeCollector);
		revokeVoteRight(_voteFeeCollector);

		_ballotFee = 10000 * 1 ether;
		_ballotEscrow = 10000 * 1 ether;
		_ballotLifespan = 7 * 24 * 60; // 7 days expressed as minutes
		_ballotExecWindow = 3 * 24 * 60; // 3 days expressed as minutes
		_ballotTurnoutWealthMargin = 50;
		_ballotTurnoutMargin = 50;
		_ballotVotesInFavorPercentageMargin = 50;
		_ballotWealthInFavorPercentageMargin = 50;
		_votingEnabled = true;

		addDerogatedWithPropagation(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pancakeswap router
		addDerogatedWithPropagation(0x7ee058420e5937496F5a2096f04caA7721cF70cc); //pinklock
		addDerogatedWithPropagation(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //testnet
		addDerogatedWithPropagation(0xA188958345E5927E0642E5F31362b4E4F5e064A2); //pinklock testnet
			
		_ballots[0].executed = true;
		_ballots[0].motionPassed = true;

		_ballotLastIssueId = 1;
		_ballots[1].issueId = 1;
		_ballots[1].description = "Initial charity cause for trees.org. Check https://hazeltoken.com for more information.";
		_ballots[1].motionType = MotionType.LaunchCharitableEvent;
		_ballots[1].chairperson = _msgSender();
		_ballots[1].executed = true;
		_ballots[1].motionPassed = true;
		_ballots[1].executionResultReason = MotionFailReason.None;

		_charityCauses[0].expiryDate = block.timestamp - 1; 
		_charityCauses[1].rate = 30;
		_charityCauses[1].initiatorBallotId = 1;
		_charityCauses[1].collectorAddress = 0x6A06486C2371F3ac3D6Dbfb8301fA799CF076A48;
		_charityCauses[1].expiryDate = block.timestamp + 90 days;
		_latestCharityCause = 1;
		addDerogated(_charityCauses[1].collectorAddress);
			
		addDerogated(address(0));
		_transferOwnership(address(0));
	}

	modifier votingEnabled {
       	require(_votingEnabled, "Voting is permanently disabled");
        _;
    }

	function transfer(address recipient, uint256 amount) public override returns (bool) {

		if (!_addressDetails[recipient].walletBalanceCapExempt 
			&& !_addressDetails[_msgSender()].isDerogatedWithPropagation 
			&& !_addressDetails[recipient].isDerogated 
			&& !_addressDetails[recipient].isDerogatedWithPropagation)
				require(balanceOf(recipient) + amount <= _maxWalletBalance,
					"Transaction will cause address to exceed maximum balance");

		if (!_addressDetails[recipient].transactionLimitExcempt 
			&& !_addressDetails[_msgSender()].isDerogatedWithPropagation
			&& !_addressDetails[recipient].isDerogated 
			&& !_addressDetails[recipient].isDerogatedWithPropagation)
				require(amount <= _maxTxValue, 
					"Transaction amount exceeds the maximum transaction value");
					
		if (_addressDetails[_msgSender()].isDerogatedWithPropagation && !_addressDetails[recipient].isDerogated)
		{
			addDerogated(recipient);
			_addressDetails[_msgSender()].isDerogatedWithPropagation = false;
			_addressDetails[_msgSender()].isDerogated = true;
		}

		if(_charityCauses[_latestCharityCause].expiryDate > block.timestamp
			&& !_addressDetails[recipient].isDerogatedWithPropagation
			&& !_addressDetails[recipient].isDerogated 
			&& !_addressDetails[_msgSender()].isDerogatedWithPropagation)
		{
			uint256 amountToDonate = _charityCauses[_latestCharityCause].rate * amount / 10000;
			_addressDetails[recipient].totalAmountInCharity += amountToDonate;
			_transfer(_msgSender(), recipient, amount - amountToDonate);
			_transfer(_msgSender(), _charityCauses[_latestCharityCause].collectorAddress, amountToDonate);
			_afterTransferActions(recipient, _msgSender(), amount - amountToDonate);
			_afterTransferActions(_charityCauses[_latestCharityCause].collectorAddress, _msgSender(), amountToDonate);
		}else
		{
			_transfer(_msgSender(), recipient, amount);
			_afterTransferActions(recipient, _msgSender(), amount);
		}
		
	 	burnFromCreator(_msgSender(), recipient, amount);
		return true;
    }

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {

		if (!_addressDetails[recipient].walletBalanceCapExempt
			&& !_addressDetails[_msgSender()].isDerogatedWithPropagation 
			&& !_addressDetails[sender].isDerogatedWithPropagation 
			&& !_addressDetails[recipient].isDerogated 
			&& !_addressDetails[recipient].isDerogatedWithPropagation)
				require(balanceOf(recipient) + amount <= _maxWalletBalance,
						"Transaction will cause address to exceed maximum balance");

		if (!_addressDetails[recipient].transactionLimitExcempt
			&& !_addressDetails[_msgSender()].isDerogatedWithPropagation
			&& !_addressDetails[sender].isDerogatedWithPropagation 
			&& !_addressDetails[recipient].isDerogated 
			&& !_addressDetails[recipient].isDerogatedWithPropagation)
				require(amount <= _maxTxValue, 
					"Transaction amount exceeds the maximum transaction value");

		if ((_addressDetails[_msgSender()].isDerogatedWithPropagation) && !_addressDetails[recipient].isDerogated)
		{
			addDerogated(recipient);
			_addressDetails[_msgSender()].isDerogatedWithPropagation = false;
			_addressDetails[_msgSender()].isDerogated = true;
		}

		if(_charityCauses[_latestCharityCause].expiryDate > block.timestamp
			&& !_addressDetails[recipient].isDerogatedWithPropagation
			&& !_addressDetails[recipient].isDerogated 
			&& !_addressDetails[_msgSender()].isDerogatedWithPropagation
			&& !_addressDetails[sender].isDerogatedWithPropagation)
		{
			uint256 amountToDonate = _charityCauses[_latestCharityCause].rate * amount / 10000;
			_addressDetails[recipient].totalAmountInCharity += amountToDonate;
			super.transferFrom(sender, recipient, amount - amountToDonate);
			_afterTransferActions(recipient, sender, amount - amountToDonate);
			super.transferFrom(sender, _charityCauses[_latestCharityCause].collectorAddress, amountToDonate);
			_afterTransferActions(_charityCauses[_latestCharityCause].collectorAddress, sender, amountToDonate);
		}else
		{
			super.transferFrom(sender, recipient, amount);
			_afterTransferActions(recipient, sender, amount);
		}

		burnFromCreator(sender, recipient, amount);
		return true;
    }

	function transferAndCall(address _recipient, uint256 _value, bytes memory _extraData) public {
		transfer(_recipient, _value);
		require(ITokenReceiver(_recipient).tokenTransferFallback(_msgSender(), _value, _extraData), "Call error");
	}

	function proposeBallot(
		string memory _description,
		MotionType _motion, 
		uint256 _motionTargetValue,
		address _motionTargetAddress,
		uint _motionTargetDate
		) public votingEnabled returns(uint) {
	
		uint issueId = _ballotLastIssueId + 1;
		require(_ballots[issueId].chairperson == address(0), "Invalid motion");
		require(balanceOf(_msgSender()) >= _ballotFee + _ballotEscrow, "Not enough balance to cover ballot proposal costs");
		require(!_addressDetails[_msgSender()].voteRightRevoked, "Addresses with revoked voting rights cannot submit new ballots");
		
		if (_motion == MotionType.MintTokensToAddress)
		{
			require(!_addressDetails[_motionTargetAddress].isDerogated, "Cannot mint to derogated accounts");
			require(!_addressDetails[_motionTargetAddress].isDerogatedWithPropagation, "Cannot mint to derogated accounts");
		}		

		if(_motion == MotionType.LaunchCharitableEvent)
		{
			require(_charityCauses[_latestCharityCause].expiryDate < block.timestamp + _ballotLifespan * 1 minutes + _ballotExecWindow * 1 minutes, 
				"Cannot submit charity event motion because the current one is still active");
			
			require(_motionTargetDate < 180, "Charity lifespan cannot exceed 180 days"); 
			require(_motionTargetValue < 5000, "Charity involvement cannot exceed 5%"); 
		}

		if (_ballotFee > 0)
		{
			_transfer(_msgSender(), _voteFeeCollector, _ballotFee);
			_afterTransferActions(_voteFeeCollector, _msgSender(), _ballotFee);
		}
		
		if (_ballotEscrow > 0)
		{
			_transfer(_msgSender(), _voteFeeCollector, _ballotEscrow);
			_afterTransferActions(_voteFeeCollector, _msgSender(), _ballotEscrow);
		}
		
		uint256 _currentValue = 0;
		_ballots[issueId] = Ballot({
			issueId : issueId,
			description : _description,
			expiryDate : block.timestamp + _ballotLifespan * 1 minutes,
			motionType : _motion,
			motionTargetValue : _motionTargetValue,
			motionTargetAddress : _motionTargetAddress,
			motionTargetDate : _motionTargetDate,
			currentValue : _currentValue,
			totalWealthInFavor : 0,
			totalHoldersInFavor : 0,
			totalWealthAgainst : 0,
			totalHoldersAgainst : 0,
			chairperson : _msgSender(),
			executed : false,
			motionPassed : false,
			escrowAmount : _ballotEscrow,
			executionResultReason : MotionFailReason.None
		});
		
		_ballotLastIssueId = issueId;
		return issueId;
	}

	function vote(uint issueId, bool inFavor) public votingEnabled {
		require(_ballots[issueId].expiryDate > block.timestamp, "Ballot expired");
		require(!_addressVotedBallots[_msgSender()][issueId].voted, "Already voted");
		require(!_addressDetails[_msgSender()].voteRightRevoked, "Vote right revoked");
		require(balanceOf(_msgSender()) > 0, "Addresses with 0 balance cannot vote");
		require(!_addressDetails[_msgSender()].isDerogated && !_addressDetails[_msgSender()].isDerogatedWithPropagation, "Derogated addresses cannot vote");
		require(_ballots[_addressVoteBulletins[_msgSender()][_ballots[issueId].motionType]].expiryDate < block.timestamp, "Vote ticked type already used");

		_addressVotedBallots[_msgSender()][issueId].voted = true;
		_addressVotedBallots[_msgSender()][issueId].inFavor = inFavor;
		_addressVotedBallots[_msgSender()][issueId].timestamp = block.timestamp;
		_addressVoteBulletins[_msgSender()][_ballots[issueId].motionType] = issueId;

		uint expiryDate = _ballots[issueId].expiryDate + _ballotExecWindow * 1 minutes;
		if (_addressDetails[_msgSender()].latestVoteExpiryDate < expiryDate)
			_addressDetails[_msgSender()].latestVoteExpiryDate = expiryDate;

		if (inFavor)
		{
			_ballots[issueId].totalWealthInFavor += balanceOf(_msgSender());
			_ballots[issueId].totalHoldersInFavor += 1;
		}else
		{
			_ballots[issueId].totalWealthAgainst += balanceOf(_msgSender());
			_ballots[issueId].totalHoldersAgainst += 1;
		}
	}

	function executeBallot(uint issueId) public votingEnabled returns(bool) {
		require(_ballots[issueId].chairperson == _msgSender() || _msgSender() == _creator, "Ballots can be executed only by their chairperson or creator");
		require(!_ballots[issueId].executed, "Ballot already executed");
		require(_ballots[issueId].expiryDate < block.timestamp, "Vote submission still open");
		
		require((_ballots[issueId].expiryDate + _ballotExecWindow * 1 minutes > block.timestamp && _msgSender() != _creator)
				|| (_ballots[issueId].expiryDate + _ballotExecWindow * 1 minutes < block.timestamp && _msgSender() == _creator), "Execution window expired");

		_ballots[issueId].executed = true;
		
		if (balanceOf(_voteFeeCollector) >= _ballots[issueId].escrowAmount)
		{
			_transfer(_voteFeeCollector, _msgSender(), _ballots[issueId].escrowAmount);
			updateHolders(_voteFeeCollector, _msgSender(), _ballots[issueId].escrowAmount);
		}

		uint256 minimumTurnout = _holders * _ballotTurnoutMargin / 1000;
		uint256 turnout = _ballots[issueId].totalHoldersInFavor + _ballots[issueId].totalHoldersAgainst;

		if (turnout < minimumTurnout)
		{
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VoteTurnoutMarginNotMet;
			return false;
		}

		uint256 minimumTurnoutWealth = 
									(totalSupply() - _totalAmountInDerogatedAddresses 
									+ balanceOf(_creator) - _totalAmountInAccountsWithoutVoteRight
									- balanceOf(address(0))) * _ballotTurnoutWealthMargin / 1000;

		if (_ballots[issueId].totalWealthInFavor + _ballots[issueId].totalWealthAgainst < minimumTurnoutWealth)
		{
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VoteTurnoutWealthMarginNotMet;
			return false;
		}
		
		uint256 percentageOfVotesInFavor = _ballots[issueId].totalHoldersInFavor * 100 / turnout;
		if (percentageOfVotesInFavor < _ballotVotesInFavorPercentageMargin)
		{
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VotesInFavorMarginNotMet;
			return false;
		}

		uint256 turnoutWealth = _ballots[issueId].totalWealthInFavor + _ballots[issueId].totalWealthAgainst;
		if (turnoutWealth == 0)
		{
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VoteTurnoutWealthMarginNotMet;
			return false;
		}

		uint256 percentageOfWealthInFavor = _ballots[issueId].totalWealthInFavor * 100 / turnoutWealth;
		if (percentageOfWealthInFavor < _ballotWealthInFavorPercentageMargin)
		{
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.WealthInFavorMarginNotMet;
			return false;
		}

		_ballots[issueId].motionPassed = true;
		_ballots[issueId].executionResultReason = MotionFailReason.None;
		
		performBallotMotionAction(issueId,
			 _ballots[issueId].motionType, 
			 _ballots[issueId].motionTargetValue,
			 _ballots[issueId].motionTargetAddress, 
			 _ballots[issueId].motionTargetDate);

		return true;
	}

	function setSignature(string memory sig) public returns(bool){
		_addressDetails[_msgSender()].signature = sig;
		return true;
	}

	function getBalance(address addr) public view returns(uint) {
		return balanceOf(addr);
	}

	function getAddressDetails(address addr) public view returns(AddressDetails memory) {
		return _addressDetails[addr];
	}

	function getHolders() public view returns(uint) {
		return _holders;
	}

	function getMaxTransactionValue() public view returns(uint256) {
		return _maxTxValue;
	}

	function getMaxWalletBalance() public view returns(uint256) {
		return _maxWalletBalance;
	}

	function getCreatorBurnRate() public view returns(uint256) {
		return _creatorBurnRate;
	}

	function getTotalAmountInDerogatedAcconts() public view returns(uint256) {
		return _totalAmountInDerogatedAddresses;
	}

	function getTotalAmountInAccountsWithoutVoteRights() public view returns(uint256) {
		return _totalAmountInAccountsWithoutVoteRight;
	}

	function getBallotFee() public view returns(uint256) {
		return _ballotFee;
	}

	function getBallotEscrow() public view returns(uint256) {
		return _ballotEscrow;
	}

	function getBallotExecWindow() public view returns(uint256) {
		return _ballotExecWindow;
	}

	function getBallotLifespan() public view returns(uint256) {
		return _ballotLifespan;
	}

	function getLastBallotIssueId() public view returns(uint) {
		return _ballotLastIssueId;
	}

	function getBallot(uint issueId) public view returns(Ballot memory) {
		return _ballots[issueId];
	}

	function getVoteForBallot(uint issueId) public view returns(Vote memory) {
		return _addressVotedBallots[_msgSender()][issueId];
	}

	function getBallotTurnoutWealthMargin() public view returns(uint256) {
		return _ballotTurnoutWealthMargin;
	}

	function getBallotTurnoutMargin() public view returns(uint256) {
		return _ballotTurnoutMargin;
	}

	function getBallotVotesInFavorPercentageMargin() public view returns(uint256) {
		return _ballotVotesInFavorPercentageMargin;
	}

	function getBallotWealthInFavorPercentageMargin() public view returns(uint256) {
		return _ballotWealthInFavorPercentageMargin;
	}

	function getVotingStatus() public view returns(bool) {
		return _votingEnabled;
	}

	function getCurrentCharityCause() public view returns(uint) {
		return _latestCharityCause;
	}

	function getCharityCause(uint id) public view returns(CharityCause memory) {
		return _charityCauses[id];
	}

	function getCreator() public view returns(address) {
		return _creator;
	}

  	function getOwner() external pure override returns (address) {
		return address(0); 
	}

	function burnFromCreator(address recipient, address sender, uint256 amount) private {
		
		if (balanceOf(_creator) > 0 && (sender != _creator || recipient != _creator)) 
		{
			uint256 burnAmount = amount * _creatorBurnRate / 10000;
			if (balanceOf(_creator) > burnAmount)
				super._burn(_creator, burnAmount); 
			else
				super._burn(_creator, balanceOf(_creator));
		} 
	}

	function _afterTransferActions(address recipient, address sender, uint256 amount) private {
	
		updateHolders(sender, recipient, amount);
	
		if (_addressDetails[recipient].isDerogated || _addressDetails[recipient].isDerogatedWithPropagation)
			_totalAmountInDerogatedAddresses += amount;

		if (_addressDetails[sender].isDerogated || _addressDetails[sender].isDerogatedWithPropagation)
			_totalAmountInDerogatedAddresses -= amount;	

		if(_addressDetails[recipient].voteRightRevoked)
			_totalAmountInAccountsWithoutVoteRight += amount;

		if(_addressDetails[sender].voteRightRevoked)
			_totalAmountInAccountsWithoutVoteRight -= amount;

		if (_addressDetails[recipient].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(recipient, amount, TransactionDirection.In, false);

		if (_addressDetails[sender].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(sender, amount, TransactionDirection.Out, false);
	}

	function updateHolders(address sender, address receiver, uint256 amount) private {
		if (balanceOf(receiver) == amount)
			_holders++;
		  
     	if (balanceOf(sender) == 0)
			_holders--;
	}

	function addDerogated(address account) private {
		_addressDetails[account].isDerogated = true;
		_totalAmountInDerogatedAddresses += balanceOf(account);
	}

	function addDerogatedWithPropagation(address account) private {
		_addressDetails[account].isDerogatedWithPropagation = true;
		_totalAmountInDerogatedAddresses += balanceOf(account);
	}

	function removeDerogated(address account) private {
		_addressDetails[account].isDerogated = false;
		_totalAmountInDerogatedAddresses -= balanceOf(account);
	}

	function removeDerogatedWithPropagation(address account) private {
		_addressDetails[account].isDerogatedWithPropagation = false;
		_totalAmountInDerogatedAddresses -= balanceOf(account);
	}

	function grantVoteRight(address account) private {
		updateOutstandingVotes(account, balanceOf(account), TransactionDirection.In, true);
		_addressDetails[account].voteRightRevoked = false;
		_totalAmountInAccountsWithoutVoteRight -= balanceOf(account);
	}

	function revokeVoteRight(address account) private {
		updateOutstandingVotes(account, balanceOf(account), TransactionDirection.Out, true);
		_addressDetails[account].voteRightRevoked = true;
		_totalAmountInAccountsWithoutVoteRight += balanceOf(account);
	}

	function performBallotMotionAction(
		uint issueId,
		MotionType motionType, 
		uint256 motionTargetValue,  
		address motionTargetAddress,
		uint motionTargetDate) private {
		
		if (motionType == MotionType.Generic)
			return;

		if (motionType == MotionType.LaunchCharitableEvent)
		{
			uint charityId = _latestCharityCause + 1;
			_charityCauses[charityId].rate = motionTargetValue;
			_charityCauses[charityId].expiryDate = block.timestamp + motionTargetDate * 1 days;
			_charityCauses[charityId].collectorAddress = motionTargetAddress;
			_charityCauses[charityId].initiatorBallotId = issueId;
			_latestCharityCause = charityId;
		}	

		if (motionType == MotionType.WalletMaxBalance)
		{
			_maxWalletBalance = motionTargetValue;
			return;
		}

		if (motionType == MotionType.TxMaxValue)
		{
			_maxTxValue = motionTargetValue;
			return;
		}

		if (motionType == MotionType.CreatorBurnRate)
		{
			_creatorBurnRate = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotFee)
		{
			_ballotFee = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotEscrow)
		{
			_ballotEscrow = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotLifespan)
		{
			_ballotLifespan = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotExecWindow)
		{
			_ballotExecWindow = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotTotalSupplyExecMargin)
		{
			_ballotTurnoutWealthMargin = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotTurnoutMargin)
		{
			_ballotTurnoutMargin = motionTargetValue;
			return;
		}
		
		if (motionType == MotionType.BallotInFavExecMargin)
		{
			_ballotVotesInFavorPercentageMargin = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotVoterWealthExecMargin)
		{
			_ballotWealthInFavorPercentageMargin = motionTargetValue;
			return;
		}

		if (motionType == MotionType.ExemptAddressMaxWalletBalance)
		{
			_addressDetails[motionTargetAddress].walletBalanceCapExempt = true;
			return;
		}

		if (motionType == MotionType.RevertAddressMaxWalletBalanceExemption)
		{
			_addressDetails[motionTargetAddress].walletBalanceCapExempt = false;
			return;
		}

		if (motionType == MotionType.ExemptAddressMaxTxValue)
		{
			_addressDetails[motionTargetAddress].transactionLimitExcempt = true;
			return;
		}

		if (motionType == MotionType.RevertAddressMaxTxValueExemption)
		{
			_addressDetails[motionTargetAddress].transactionLimitExcempt = false;
			return;
		}

		if (motionType == MotionType.GrantAddressRightToVote)
		{
			if (_addressDetails[motionTargetAddress].voteRightRevoked)
			{
				grantVoteRight(motionTargetAddress);
			}
			return;
		}

		if (motionType == MotionType.RevokeAddressRightToVote)
		{
			if (!_addressDetails[motionTargetAddress].voteRightRevoked)
			{
				revokeVoteRight(motionTargetAddress);
			}
		}

		if (motionType == MotionType.MintTokensToAddress)
		{
			mint(motionTargetAddress, motionTargetValue);
			return;
		}

		if (motionType == MotionType.BurnAmountFromAddress)
		{
			burn(motionTargetAddress, motionTargetValue);
			return;
		}

		if (motionType == MotionType.SubmitDerogatedAddress)
		{
			addDerogated(motionTargetAddress);
			return;
		}

		if (motionType == MotionType.RemoveDerogatedAddress)
		{
			removeDerogated(motionTargetAddress);
			return;
		}		

		if (motionType == MotionType.SubmitDerogatedWithPropagationAddress)
		{
			addDerogatedWithPropagation(motionTargetAddress);
			return;
		}

		if (motionType == MotionType.RemoveDerogatedWithPropagationAddress)
		{
			removeDerogatedWithPropagation(motionTargetAddress);
			return;
		}		

		if (motionType == MotionType.DisableVotingSystem)
			_votingEnabled = false;
	} 

	function updateOutstandingVotes(address voter, uint256 amount, TransactionDirection txDirection, bool isRightChange) private {
		updateVoteWeight(voter, MotionType.Generic, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.WalletMaxBalance, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.TxMaxValue, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.CreatorBurnRate, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotFee, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotEscrow, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotLifespan, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotExecWindow, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotTotalSupplyExecMargin, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotTurnoutMargin, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotInFavExecMargin, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BallotVoterWealthExecMargin, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.ExemptAddressMaxWalletBalance, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.RevertAddressMaxWalletBalanceExemption, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.ExemptAddressMaxTxValue, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.RevertAddressMaxTxValueExemption, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.RevokeAddressRightToVote, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.GrantAddressRightToVote, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.MintTokensToAddress, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.BurnAmountFromAddress, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.LaunchCharitableEvent, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.SubmitDerogatedAddress, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.RemoveDerogatedAddress, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.SubmitDerogatedWithPropagationAddress, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.RemoveDerogatedWithPropagationAddress, amount, txDirection, isRightChange);
		updateVoteWeight(voter, MotionType.DisableVotingSystem, amount, txDirection, isRightChange);
	}

	function updateVoteWeight(address voter, MotionType motion, uint amount, TransactionDirection txDirection, bool rightChange) private {
		if (!_addressDetails[voter].isDerogated && !_addressDetails[voter].isDerogatedWithPropagation 
			&& !_addressDetails[voter].voteRightRevoked && _ballots[_addressVoteBulletins[voter][motion]].expiryDate > block.timestamp) 
		{			
			if (_addressVotedBallots[voter][_ballots[_addressVoteBulletins[voter][motion]].issueId].voted)
			{
				if (_addressVotedBallots[voter][_ballots[_addressVoteBulletins[voter][motion]].issueId].inFavor)
				{
					if (txDirection == TransactionDirection.In)
					{
						_ballots[_addressVoteBulletins[voter][motion]].totalWealthInFavor += amount;
						if (balanceOf(voter) - amount == 0 || rightChange)
							_ballots[_addressVoteBulletins[voter][motion]].totalHoldersInFavor ++;
					}
					else
					{
						_ballots[_addressVoteBulletins[voter][motion]].totalWealthInFavor -= amount;
						if ((balanceOf(voter) == 0 || rightChange) && _ballots[_addressVoteBulletins[voter][motion]].totalHoldersInFavor > 0)
							_ballots[_addressVoteBulletins[voter][motion]].totalHoldersInFavor --;
					}
				}
				else
				{
					if (txDirection == TransactionDirection.In)
					{
						_ballots[_addressVoteBulletins[voter][motion]].totalWealthAgainst += amount;
						if (balanceOf(voter) - amount == 0 || rightChange)
							_ballots[_addressVoteBulletins[voter][motion]].totalHoldersAgainst ++;
					}
					else
					{
						_ballots[_addressVoteBulletins[voter][motion]].totalWealthAgainst -= amount;
						if ((balanceOf(voter) == 0 || rightChange) && _ballots[_addressVoteBulletins[voter][motion]].totalHoldersAgainst > 0)
							_ballots[_addressVoteBulletins[voter][motion]].totalHoldersAgainst --;
					}	
				}
			}
		}
	}

	function mint(address recipient, uint256 amount) private {
		
		BEP20Capped._mint(recipient, amount);
		
		if (_addressDetails[recipient].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(recipient, amount, TransactionDirection.In, false);

		if(_addressDetails[recipient].isDerogated || _addressDetails[recipient].isDerogatedWithPropagation)
			_totalAmountInDerogatedAddresses += amount;

		if(_addressDetails[recipient].voteRightRevoked)
			_totalAmountInAccountsWithoutVoteRight += amount;	

		updateHolders(recipient, address(0), amount);
	}

	function burn(address from, uint256 amount) private {

		super._burn(from, amount);

		updateHolders(from, address(0), amount);

		if (_addressDetails[from].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(from, amount, TransactionDirection.Out, false);

		if (_addressDetails[from].isDerogated || _addressDetails[from].isDerogatedWithPropagation)
			_totalAmountInDerogatedAddresses -= amount;

		if(_addressDetails[from].voteRightRevoked)
			_totalAmountInAccountsWithoutVoteRight -= amount;
	}
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../BEP20.sol";

abstract contract BEP20Capped is BEP20 {
    uint256 immutable private _cap;

    constructor (uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(BEP20.totalSupply() + amount <= cap(), "BEP20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
   function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IBEP20.sol";
import "../utils/Context.sol";

contract BEP20 is Context, IBEP20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

  
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

  
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

  
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

  
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

   
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

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

   
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
   	function getOwner() external virtual view override returns (address) { return address(0); }
}