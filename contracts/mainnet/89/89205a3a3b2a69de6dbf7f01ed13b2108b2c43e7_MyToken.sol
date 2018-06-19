contract owned {
        address public owner;

        function owned() {
                owner = msg.sender;
        }

        modifier onlyOwner {
                if (msg.sender != owner) throw;
                _
        }

        function transferOwnership(address newOwner) onlyOwner {
                owner = newOwner;
        }
}

/* The token is used as a voting shares */
contract token {
        function mintToken(address target, uint256 mintedAmount);
}

contract Congress is owned {

        /* Contract Variables and events */
        uint public minimumQuorum;
        uint public debatingPeriodInMinutes;
        int public majorityMargin;
        Proposal[] public proposals;
        uint public numProposals;
        mapping(address => uint) public memberId;
        Member[] public members;

        address public unicornAddress;
        uint public priceOfAUnicornInFinney;

        event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
        event Voted(uint proposalID, bool position, address voter, string justification);
        event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
        event MembershipChanged(address member);
        event ChangeOfRules(uint minimumQuorum, uint debatingPeriodInMinutes, int majorityMargin);

        struct Proposal {
                address recipient;
                uint amount;
                string description;
                uint votingDeadline;
                bool executed;
                bool proposalPassed;
                uint numberOfVotes;
                int currentResult;
                bytes32 proposalHash;
                Vote[] votes;
                mapping(address => bool) voted;
        }

        struct Member {
                address member;
                uint voteWeight;
                bool canAddProposals;
                string name;
                uint memberSince;
        }

        struct Vote {
                bool inSupport;
                address voter;
                string justification;
        }


        /* First time setup */
        function Congress(uint minimumQuorumForProposals, uint minutesForDebate, int marginOfVotesForMajority, address congressLeader) {
                minimumQuorum = minimumQuorumForProposals;
                debatingPeriodInMinutes = minutesForDebate;
                majorityMargin = marginOfVotesForMajority;
                members.length++;
                members[0] = Member({
                        member: 0,
                        voteWeight: 0,
                        canAddProposals: false,
                        memberSince: now,
                        name: &#39;&#39;
                });
                if (congressLeader != 0) owner = congressLeader;

        }

        /*make member*/
        function changeMembership(address targetMember, uint voteWeight, bool canAddProposals, string memberName) onlyOwner {
                uint id;
                if (memberId[targetMember] == 0) {
                        memberId[targetMember] = members.length;
                        id = members.length++;
                        members[id] = Member({
                                member: targetMember,
                                voteWeight: voteWeight,
                                canAddProposals: canAddProposals,
                                memberSince: now,
                                name: memberName
                        });
                } else {
                        id = memberId[targetMember];
                        Member m = members[id];
                        m.voteWeight = voteWeight;
                        m.canAddProposals = canAddProposals;
                        m.name = memberName;
                }

                MembershipChanged(targetMember);

        }

        /*change rules*/
        function changeVotingRules(uint minimumQuorumForProposals, uint minutesForDebate, int marginOfVotesForMajority) onlyOwner {
                minimumQuorum = minimumQuorumForProposals;
                debatingPeriodInMinutes = minutesForDebate;
                majorityMargin = marginOfVotesForMajority;

                ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
        }

        // ribbonPriceInEther
        function changeUnicorn(uint newUnicornPriceInFinney, address newUnicornAddress) onlyOwner {
                unicornAddress = newUnicornAddress;
                priceOfAUnicornInFinney = newUnicornPriceInFinney;
        }

        /* Function to create a new proposal */
        function newProposalInWei(address beneficiary, uint weiAmount, string JobDescription, bytes transactionBytecode) returns(uint proposalID) {
                if (memberId[msg.sender] == 0 || !members[memberId[msg.sender]].canAddProposals) throw;

                proposalID = proposals.length++;
                Proposal p = proposals[proposalID];
                p.recipient = beneficiary;
                p.amount = weiAmount;
                p.description = JobDescription;
                p.proposalHash = sha3(beneficiary, weiAmount, transactionBytecode);
                p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
                p.executed = false;
                p.proposalPassed = false;
                p.numberOfVotes = 0;
                ProposalAdded(proposalID, beneficiary, weiAmount, JobDescription);
                numProposals = proposalID + 1;
        }

        /* Function to create a new proposal */
        function newProposalInEther(address beneficiary, uint etherAmount, string JobDescription, bytes transactionBytecode) returns(uint proposalID) {
                if (memberId[msg.sender] == 0 || !members[memberId[msg.sender]].canAddProposals) throw;

                proposalID = proposals.length++;
                Proposal p = proposals[proposalID];
                p.recipient = beneficiary;
                p.amount = etherAmount * 1 ether;
                p.description = JobDescription;
                p.proposalHash = sha3(beneficiary, etherAmount * 1 ether, transactionBytecode);
                p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
                p.executed = false;
                p.proposalPassed = false;
                p.numberOfVotes = 0;
                ProposalAdded(proposalID, beneficiary, etherAmount, JobDescription);
                numProposals = proposalID + 1;
        }

        /* function to check if a proposal code matches */
        function checkProposalCode(uint proposalNumber, address beneficiary, uint amount, bytes transactionBytecode) constant returns(bool codeChecksOut) {
                Proposal p = proposals[proposalNumber];
                return p.proposalHash == sha3(beneficiary, amount, transactionBytecode);
        }

        function vote(uint proposalNumber, bool supportsProposal, string justificationText) returns(uint voteID) {
                if (memberId[msg.sender] == 0) throw;

                uint voteWeight = members[memberId[msg.sender]].voteWeight;

                Proposal p = proposals[proposalNumber]; // Get the proposal
                if (p.voted[msg.sender] == true) throw; // If has already voted, cancel
                p.voted[msg.sender] = true; // Set this voter as having voted
                p.numberOfVotes += voteWeight; // Increase the number of votes
                if (supportsProposal) { // If they support the proposal
                        p.currentResult += int(voteWeight); // Increase score
                } else { // If they don&#39;t
                        p.currentResult -= int(voteWeight); // Decrease the score
                }
                // Create a log of this event
                Voted(proposalNumber, supportsProposal, msg.sender, justificationText);
        }

        function executeProposal(uint proposalNumber, bytes transactionBytecode) returns(int result) {
                Proposal p = proposals[proposalNumber];
                /* Check if the proposal can be executed */
                if (now < p.votingDeadline // has the voting deadline arrived?  
                        || p.executed // has it been already executed? 
                        || p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode) // Does the transaction code match the proposal? 
                        || p.numberOfVotes < minimumQuorum) // has minimum quorum?
                        throw;

                /* execute result */
                if (p.currentResult > majorityMargin) {
                        /* If difference between support and opposition is larger than margin */
                        p.recipient.call.value(p.amount)(transactionBytecode);
                        p.executed = true;
                        p.proposalPassed = true;
                } else {
                        p.executed = true;
                        p.proposalPassed = false;
                }
                // Fire Events
                ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
        }

        function() {
                if (msg.value > priceOfAUnicornInFinney) {
                        token unicorn = token(unicornAddress);
                        unicorn.mintToken(msg.sender, msg.value / (priceOfAUnicornInFinney * 1 finney));
                }

        }
}


contract MyToken is owned {
        /* Public variables of the token */
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public totalSupply;

        /* This creates an array with all balances */
        mapping(address => uint256) public balanceOf;
        mapping(address => bool) public frozenAccount;
        mapping(address => mapping(address => uint)) public allowance;
        mapping(address => mapping(address => uint)) public spentAllowance;


        /* This generates a public event on the blockchain that will notify clients */
        event Transfer(address indexed from, address indexed to, uint256 value);
        event FrozenFunds(address target, bool frozen);

        /* Initializes contract with initial supply tokens to the creator of the contract */
        function MyToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol, address centralMinter) {
                if (centralMinter != 0) owner = centralMinter; // Sets the minter
                balanceOf[msg.sender] = initialSupply; // Give the creator all initial tokens                    
                name = tokenName; // Set the name for display purposes     
                symbol = tokenSymbol; // Set the symbol for display purposes    
                decimals = decimalUnits; // Amount of decimals for display purposes        
                totalSupply = initialSupply;
        }

        /* Send coins */
        function transfer(address _to, uint256 _value) {
                if (balanceOf[msg.sender] < _value) throw; // Check if the sender has enough   
                if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
                if (frozenAccount[msg.sender]) throw; // Check if frozen
                balanceOf[msg.sender] -= _value; // Subtract from the sender
                balanceOf[_to] += _value; // Add the same to the recipient            
                Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        }

        function mintToken(address target, uint256 mintedAmount) onlyOwner {
                balanceOf[target] += mintedAmount;
                totalSupply += mintedAmount;
                Transfer(owner, target, mintedAmount);
        }

        function freezeAccount(address target, bool freeze) onlyOwner {
                frozenAccount[target] = freeze;
                FrozenFunds(target, freeze);
        }

        function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
                if (balanceOf[_from] < _value) throw; // Check if the sender has enough   
                if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
                if (frozenAccount[_from]) throw; // Check if frozen
                if (spentAllowance[_from][msg.sender] + _value > allowance[_from][msg.sender]) throw; // Check allowance
                balanceOf[_from] -= _value; // Subtract from the sender
                balanceOf[_to] += _value; // Add the same to the recipient            
                spentAllowance[_from][msg.sender] += _value;
                Transfer(msg.sender, _to, _value);
        }

        function approve(address _spender, uint256 _value) returns(bool success) {
                allowance[msg.sender][_spender] = _value;
        }

        function() {
                //owner.send(msg.value);
                throw;
        }
}