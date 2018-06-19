pragma solidity ^0.4.18;

contract Ownable {

	// Contract&#39;s owner.
	address owner;

	modifier onlyOwner() {
		require (msg.sender == owner);
		_;
	}

	// Constructor.
	function Ownable() public {
		owner = msg.sender;
	}

	// Returns current contract&#39;s owner.
	function getOwner() public constant returns(address) {
		return owner;
	}

	// Transfers contract&#39;s ownership.
	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		owner = newOwner;
	}
}

contract ICKBase {

	function ownerOf(uint256) public pure returns (address);
}

contract IKittyKendoStorage {

	function createProposal(uint proposal, address proposalOwner) public;
	function createVoter(address account) public;

	function updateProposalOwner(uint proposal, address voter) public;

	function voterExists(address voter) public constant returns (bool);
	function proposalExists(uint proposal) public constant returns (bool);

	function proposalOwner(uint proposal) public constant returns (address);
	function proposalCreateTime(uint proposal) public constant returns (uint);

	function voterVotingTime(address voter) public constant returns (uint);

	function addProposalVote(uint proposal, address voter) public;
	function addVoterVote(address voter) public;

	function updateVoterTimes(address voter, uint time) public;

	function getProposalTTL() public constant returns (uint);
	function setProposalTTL(uint time) public;

	function getVotesPerProposal() public constant returns (uint);
	function setVotesPerProposal(uint votes) public;

	function getTotalProposalsCount() public constant returns(uint);
	function getTotalVotersCount() public constant returns(uint);

	function getProposalVotersCount(uint proposal) public constant returns(uint);
	function getProposalVotesCount(uint proposal) public constant returns(uint);
	function getProposalVoterVotesCount(uint proposal, address voter) public constant returns(uint);

	function getVoterProposalsCount(address voter) public constant returns(uint);
	function getVoterVotesCount(address voter) public constant returns(uint);
	function getVoterProposal(address voter, uint index) public constant returns(uint);
}

contract KittyKendoCore is Ownable {

	IKittyKendoStorage kks;
	address kksAddress;

	// Event is emitted when new votes have been recorded.
	event VotesRecorded (
		address indexed from,
		uint[] votes
	);

	// Event is emitted when new proposal has been added.
	event ProposalAdded (
		address indexed from,
		uint indexed proposal
	);

	// Registering fee.
	uint fee;

	// Constructor.
	function KittyKendoCore() public {
		fee = 0;
		kksAddress = address(0);
	}
	
	// Returns storage&#39;s address.
	function storageAddress() onlyOwner public constant returns(address) {
		return kksAddress;
	}

	// Sets storage&#39;s address.
	function setStorageAddress(address addr) onlyOwner public {
		kksAddress = addr;
		kks = IKittyKendoStorage(kksAddress);
	}

	// Returns default register fee.
	function getFee() public constant returns(uint) {
		return fee;
	}

	// Sets default register fee.
	function setFee(uint val) onlyOwner public {
		fee = val;
	}

	// Contract balance withdrawal.
	function withdraw(uint amount) onlyOwner public {
		require(amount <= address(this).balance);
		owner.transfer(amount);
	}
	
	// Returns contract&#39;s balance.
	function getBalance() onlyOwner public constant returns(uint) {
	    return address(this).balance;
	}

	// Registering proposal in replacement for provided votes.
	function registerProposal(uint proposal, uint[] votes) public payable {

		// Value must be at least equal to default fee.
		require(msg.value >= fee);

		recordVotes(votes);

		if (proposal > 0) {
			addProposal(proposal);
		}
	}

	// Recording proposals votes.
	function recordVotes(uint[] votes) private {

        require(kksAddress != address(0));

		// Checking if voter already exists, otherwise adding it.
		if (!kks.voterExists(msg.sender)) {
			kks.createVoter(msg.sender);
		}

		// Recording all passed votes from voter.
		for (uint i = 0; i < votes.length; i++) {
			// Checking if proposal exists.
			if (kks.proposalExists(votes[i])) {
				// Proposal owner can&#39;t vote for own proposal.
				require(kks.proposalOwner(votes[i]) != msg.sender);

				// Checking if proposal isn&#39;t expired yet.
				if (kks.proposalCreateTime(votes[i]) + kks.getProposalTTL() <= now) {
					continue;
				}

				// Voter can vote for each proposal only once.
				require(kks.getProposalVoterVotesCount(votes[i], msg.sender) == uint(0));

				// Adding proposal&#39;s voter and updating total votes count per proposal.
				kks.addProposalVote(votes[i], msg.sender);
			}

			// Recording vote per voter.
			kks.addVoterVote(msg.sender);
		}

		// Updating voter&#39;s last voting time and updating create time for voter&#39;s proposals.
		kks.updateVoterTimes(msg.sender, now);

		// Emitting event.
		VotesRecorded(msg.sender, votes);
	}

	// Adding new voter&#39;s proposal.
	function addProposal(uint proposal) private {

        require(kksAddress != address(0));

		// Only existing voters can add own proposals.
		require(kks.voterExists(msg.sender));

		// Checking if voter has enough votes count to add own proposal.
		require(kks.getVoterVotesCount(msg.sender) / kks.getVotesPerProposal() > kks.getVoterProposalsCount(msg.sender));

		// Prevent voter from adding own proposal&#39;s too often.
		//require(now - kks.voterVotingTime(msg.sender) > 1 minutes);

		// Checking if proposal(i.e. Crypto Kitty Token) belongs to sender.
		require(getCKOwner(proposal) == msg.sender);

		// Checking if proposal already exists.
		if (!kks.proposalExists(proposal)) {
			// Adding new proposal.
			kks.createProposal(proposal, msg.sender);
		} else {
			// Updating proposal&#39;s owner.
			kks.updateProposalOwner(proposal, msg.sender);
		}

		// Emitting event.
		ProposalAdded(msg.sender, proposal);
	}

	// Returns the CryptoKitty&#39;s owner address.
	function getCKOwner(uint proposal) private pure returns(address) {
		ICKBase ckBase = ICKBase(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d);
		return ckBase.ownerOf(uint256(proposal));
	}

}