pragma solidity ^0.4.21;



/**
 * @title BytesTools
 * @dev Useful tools for bytes type
 */
library BytesTools {
	
	/**
	 * @dev Parses n of type bytes to uint256
	 */
	function parseInt(bytes n) internal pure returns (uint256) {
		
		uint256 parsed = 0;
		bool decimals = false;
		
		for (uint256 i = 0; i < n.length; i++) {
			if ( n[i] >= 48 && n[i] <= 57) {
				
				if (decimals) break;
				
				parsed *= 10;
				parsed += uint256(n[i]) - 48;
			} else if (n[i] == 46) {
				decimals = true;
			}
		}
		
		return parsed;
	}
	
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	
	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	
	
	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}
	
	
	/**
	* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	
	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
	
	
	/**
	* @dev Powers the first number to the second, throws on overflow.
	*/
	function pow(uint a, uint b) internal pure returns (uint) {
		if (b == 0) {
			return 1;
		}
		uint c = a ** b;
		assert(c >= a);
		return c;
	}
	
	
	/**
	 * @dev Multiplies the given number by 10**decimals
	 */
	function withDecimals(uint number, uint decimals) internal pure returns (uint) {
		return mul(number, pow(10, decimals));
	}
	
}

/**
* @title Contract that will work with ERC223 tokens
*/
contract ERC223Reciever {
	
	/**
	 * @dev Standard ERC223 function that will handle incoming token transfers
	 *
	 * @param _from address  Token sender address
	 * @param _value uint256 Amount of tokens
	 * @param _data bytes  Transaction metadata
	 */
	function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
	
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	
	address public owner;
	address public potentialOwner;
	
	
	event OwnershipRemoved(address indexed previousOwner);
	event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	
	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function Ownable() public {
		owner = msg.sender;
	}
	
	
	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	
	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyPotentialOwner() {
		require(msg.sender == potentialOwner);
		_;
	}
	
	
	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param newOwner The address of potential new owner to transfer ownership to.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransfer(owner, newOwner);
		potentialOwner = newOwner;
	}
	
	
	/**
	 * @dev Allow the potential owner confirm ownership of the contract.
	 */
	function confirmOwnership() public onlyPotentialOwner {
		emit OwnershipTransferred(owner, potentialOwner);
		owner = potentialOwner;
		potentialOwner = address(0);
	}
	
	
	/**
	 * @dev Remove the contract owner permanently
	 */
	function removeOwnership() public onlyOwner {
		emit OwnershipRemoved(owner);
		owner = address(0);
	}
	
}

/**
 * @title  UKT Token Voting contract
 * @author  Oleg Levshin <levshin@ucoz-team.net>
 */
contract UKTTokenVoting is ERC223Reciever, Ownable {
	
	using SafeMath for uint256;
	using BytesTools for bytes;
	
	struct Vote {
		uint256 proposalIdx;
		uint256 tokensValue;
		uint256 weight;
		address tokenContractAddress;
		uint256 blockNumber;
	}
	
	mapping(address => bool) public acceptedTokens;
	mapping(address => uint256) public acceptedTokensValues;
	
	bytes32[] public proposals;
	mapping (uint256 => uint256) public proposalsWeights;
	
	uint256 public dateStart;
	uint256 public dateEnd;
	
	address[] public voters;
	mapping (address => Vote) public votes;
	
	bool public isFinalized = false;
	bool public isFinalizedValidly = false;
	
	event NewVote(address indexed voter, uint256 proposalIdx, uint256 proposalWeight);
	event TokensClaimed(address to);
	event TokensRefunded(address to);
	
	
	function UKTTokenVoting(
		uint256 _dateEnd,
		bytes32[] _proposals,
		address[] _acceptedTokens,
		uint256[] _acceptedTokensValues
	) public {
		require(_dateEnd > now);
		require(_proposals.length > 1);
		require(_acceptedTokens.length > 0);
		require(_acceptedTokensValues.length > 0);
		require(_acceptedTokens.length == _acceptedTokensValues.length);
		
		dateStart = now;
		dateEnd = _dateEnd;
		
		proposals.push("Not valid proposal");
		proposalsWeights[0] = 0;
		for(uint256 i = 0; i < _proposals.length; i++) {
			proposals.push(_proposals[i]);
			proposalsWeights[i+1] = 0;
		}
		
		for(uint256 j = 0; j < _acceptedTokens.length; j++) {
			acceptedTokens[_acceptedTokens[j]] = true;
			acceptedTokensValues[_acceptedTokens[j]] = _acceptedTokensValues[j];
		}
	}
	
	
	/**
	 * @dev Executes automatically when user transfer his token to this contract address
	 */
	function tokenFallback(
		address _from,
		uint256 _value,
		bytes _data
	) external returns (bool) {
		// voting hasn&#39;t ended yet
		require(now < dateEnd);
		
		// executed from contract in acceptedTokens
		require(acceptedTokens[msg.sender] == true);
		
		// value of tokens is enough for voting
		require(_value >= acceptedTokensValues[msg.sender]);
		
		// give proposal index is valid
		uint256 proposalIdx = _data.parseInt();
		require(isValidProposal(proposalIdx));
		
		// user hasn&#39;t voted yet
		require(isAddressNotVoted(_from));
		
		uint256 weight = _value.div(acceptedTokensValues[msg.sender]);
		
		votes[_from] = Vote(proposalIdx, _value, weight, msg.sender, block.number);
		voters.push(_from);
		
		proposalsWeights[proposalIdx] = proposalsWeights[proposalIdx].add(weight);
		
		emit NewVote(_from, proposalIdx, proposalsWeights[proposalIdx]);
		
		return true;
	}
	
	
	/**
	 * @dev Gets winner tuple after voting is finished
	 */
	function getWinner() external view returns (uint256 winnerIdx, bytes32 winner, uint256 winnerWeight) {
		require(now >= dateEnd);
		
		winnerIdx = 0;
		winner = proposals[winnerIdx];
		winnerWeight = proposalsWeights[winnerIdx];
		
		for(uint256 i = 1; i < proposals.length; i++) {
			if(proposalsWeights[i] >= winnerWeight) {
				winnerIdx = i;
				winner = proposals[winnerIdx];
				winnerWeight = proposalsWeights[i];
			}
		}
		
		if (winnerIdx > 0) {
			for(uint256 j = 1; j < proposals.length; j++) {
				if(j != winnerIdx && proposalsWeights[j] == proposalsWeights[winnerIdx]) {
					return (0, proposals[0], proposalsWeights[0]);
				}
			}
		}
		
		return (winnerIdx, winner, winnerWeight);
	}
	
	
	/**
	 * @dev Finalizes voting
	 */
	function finalize(bool _isFinalizedValidly) external onlyOwner {
		require(now >= dateEnd && ! isFinalized);
		
		isFinalized = true;
		isFinalizedValidly = _isFinalizedValidly;
	}
	
	
	/**
	 * @dev Allows voter to claim his tokens back to address
	 */
	function claimTokens() public returns (bool) {
		require(isAddressVoted(msg.sender));
		
		require(transferTokens(msg.sender));
		emit TokensClaimed(msg.sender);
		
		return true;
	}
	
	
	/**
	 * @dev Refunds tokens for all voters
	 */
	function refundTokens(address to) public onlyOwner returns (bool) {
		if(to != address(0)) {
			return _refundTokens(to);
		}
		
		for(uint256 i = 0; i < voters.length; i++) {
			_refundTokens(voters[i]);
		}
		
		return true;
	}
	
	
	/**
	 * @dev Checks proposal index for validity
	 */
	function isValidProposal(uint256 proposalIdx) private view returns (bool) {
		return (
			proposalIdx > 0 &&
			proposals[proposalIdx].length > 0
		);
	}
	
	
	/**
	 * @dev Return true if address not voted yet
	 */
	function isAddressNotVoted(address _address) private view returns (bool) {
		// solium-disable-next-line operator-whitespace
		return (
			// solium-disable-next-line operator-whitespace
			votes[_address].proposalIdx == 0 &&
			votes[_address].tokensValue == 0 &&
			votes[_address].weight == 0 &&
			votes[_address].tokenContractAddress == address(0) &&
			votes[_address].blockNumber == 0
		);
	}
	
	
	/**
	 * @dev Return true if address already voted
	 */
	function isAddressVoted(address _address) private view returns (bool) {
		return ! isAddressNotVoted(_address);
	}
	
	
	/**
	 * @dev Trasnfer tokens to voter
	 */
	function transferTokens(address to) private returns (bool) {
		
		Vote memory vote = votes[to];
		
		if(vote.tokensValue == 0) {
			return true;
		}
		votes[to].tokensValue = 0;
		
		if ( ! isFinalized) {
			votes[to] = Vote(0, 0, 0, address(0), 0);
			proposalsWeights[vote.proposalIdx] = proposalsWeights[vote.proposalIdx].sub(vote.weight);
		}
		
		return vote.tokenContractAddress.call(bytes4(keccak256("transfer(address,uint256)")), to, vote.tokensValue);
	}
	
	
	/**
	 * @dev Refunds tokens to particular address
	 */
	function _refundTokens(address to) private returns (bool) {
		require(transferTokens(to));
		emit TokensRefunded(to);
		
		return true;
	}
	
}

/**
 * @title  UKT Token Voting Factory contract
 * @author  Oleg Levshin <levshin@ucoz-team.net>
 */
contract UKTTokenVotingFactory is Ownable {
	
	address[] public votings;
	mapping(address => int256) public votingsWinners;
	
	event VotingCreated(address indexed votingAddress, uint256 dateEnd, bytes32[] proposals, address[] acceptedTokens, uint256[] acceptedTokensValues);
	event WinnerSetted(address indexed votingAddress, uint256 winnerIdx, bytes32 winner, uint256 winnerWeight);
	event VotingFinalized(address indexed votingAddress, bool isFinalizedValidly);
	
	
	/**
	 * @dev Checks voting contract address for validity
	 */
	function isValidVoting(address votingAddress) private view returns (bool) {
		for (uint256 i = 0; i < votings.length; i++) {
			if (votings[i] == votingAddress) {
				return true;
			}
		}
		
		return false;
	}
	
	
	/**
	 * @dev Creates new instance of UKTTokenVoting contract with given params
	 */
	function getNewVoting(
		uint256 dateEnd,
		bytes32[] proposals,
		address[] acceptedTokens,
		uint256[] acceptedTokensValues
	) public onlyOwner returns (address votingAddress) {
		
		votingAddress = address(new UKTTokenVoting(dateEnd, proposals, acceptedTokens, acceptedTokensValues));
		
		emit VotingCreated(votingAddress, dateEnd, proposals, acceptedTokens, acceptedTokensValues);
		
		votings.push(votingAddress);
		votingsWinners[votingAddress] = -1;
		
		return votingAddress;
	}
	
	
	/**
	 * @dev Refunds tokens for all voters
	 */
	function refundVotingTokens(address votingAddress, address to) public onlyOwner returns (bool) {
		require(isValidVoting(votingAddress));
		
		return UKTTokenVoting(votingAddress).refundTokens(to);
	}
	
	
	/**
	 * @dev Sets calculated proposalIdx as voting winner
	 */
	function setVotingWinner(address votingAddress) public onlyOwner {
		require(votingsWinners[votingAddress] == -1);
		
		uint256 winnerIdx;
		bytes32 winner;
		uint256 winnerWeight;
		
		(winnerIdx, winner, winnerWeight) = UKTTokenVoting(votingAddress).getWinner();
		
		bool isFinalizedValidly = winnerIdx > 0;
		
		UKTTokenVoting(votingAddress).finalize(isFinalizedValidly);
		
		emit VotingFinalized(votingAddress, isFinalizedValidly);
		
		votingsWinners[votingAddress] = int256(winnerIdx);
		
		emit WinnerSetted(votingAddress, winnerIdx, winner, winnerWeight);
	}
	
	
	/**
	 * @dev Gets voting winner
	 */
	function getVotingWinner(address votingAddress) public view returns (bytes32) {
		require(votingsWinners[votingAddress] > -1);
		
		return UKTTokenVoting(votingAddress).proposals(uint256(votingsWinners[votingAddress]));
	}
}