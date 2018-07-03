pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;FINX2&#39; &#39;FINX2 Token&#39; token contract
//
// Symbol	: FINX2
// Name		: FINX2 Token
// Total supply: 100,000,000,000
// Decimals	: 18
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


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract FINX2Token is ERC20Interface {
	using SafeMath for uint;

	string constant public symbol = &quot;FINX2&quot;;
	string constant public name = &quot;FINX2&quot;;
	uint8 constant public decimals = 18;
	uint public _totalSupply = 100000000000e18;

	uint constant endTime = 1543622400; // 2018-12-01 00:00:00 GMT+00:00
	uint constant unlockTime = 1622505600; // 2021-06-01 00:00:00 GMT+00:00

	address founder1 = 0x749182D6B36b8A73Dc051f1460DfD390BAAeF0A0;
  address founder2 = 0x645e3a533463eE4d61EF3FabcB0B68dDf3E445C7;

	address crowdSale = 0xbA6f85b45F21FAd64Af2e19952c2CEAf6Ed51C29;

	uint constant founder1Tokens = 1000000000e18;
  uint constant founder2Tokens = 500000000e18;

	uint constant crowdSaleTokens = 68500000000e18;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;


	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	function FINX2Token() public {
		preSale(founder1, founder1Tokens);
		preSale(founder2, founder2Tokens);

		preSale(crowdSale, crowdSaleTokens);
	}


	function preSale(address _address, uint _amount) internal returns (bool) {
		balances[_address] = _amount;
		emit Transfer(address(0x0), _address, _amount);
	}


	function transferPermissions(address spender) internal constant returns (bool) {
		if (spender == crowdSale) {
			return true;
		}

		if (now < endTime) {
			return false;
		}

		if (now < unlockTime) {
			if (spender == founder1 || spender == founder2) {
				return false;
			}
		}

		return true;
	}


	// ------------------------------------------------------------------------
	// Total supply
	// ------------------------------------------------------------------------
	function totalSupply() public constant returns (uint) {
		return _totalSupply;
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
		require(transferPermissions(msg.sender));
		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(msg.sender, to, tokens);
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
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		require(transferPermissions(from));
		balances[from] = balances[from].sub(tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(from, to, tokens);
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
	// Don&#39;t accept ETH
	// ------------------------------------------------------------------------
	function () public payable {
		revert();
	}
}


contract Ballot {

    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        address delegate;
    }
    struct Proposal {
        uint voteCount;
    }

    address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;

    /// Create a new ballot with $(_numProposals) different proposals.
    function Ballot(uint8 _numProposals) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        proposals.length = _numProposals;
    }

    /// Give $(toVoter) the right to vote on this ballot.
    /// May only be called by $(chairperson).
    function giveRightToVote(address toVoter) public {
        if (msg.sender != chairperson || voters[toVoter].voted) return;
        voters[toVoter].weight = 1;
    }

    /// Delegate your vote to the voter $(to).
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted) return;
        while (voters[to].delegate != address(0) && voters[to].delegate != msg.sender)
            to = voters[to].delegate;
        if (to == msg.sender) return;
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegateTo = voters[to];
        if (delegateTo.voted)
            proposals[delegateTo.vote].voteCount += sender.weight;
        else
            delegateTo.weight += sender.weight;
    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint8 toProposal) public {
        Voter storage sender = voters[msg.sender];
        if (sender.voted || toProposal >= proposals.length) return;
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
    }

    function winningProposal() public constant returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }
    }
}