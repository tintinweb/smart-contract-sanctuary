/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

contract EVOLTcoin {
    // Exogenous DAO with ERC20 compliant functions

    // Credit - used to set preferences and vote
    string public constant name     = "eVoltCoin";
    string public constant symbol   = "EVOLT";
    uint8  public constant decimals = 0;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 private totalSupply_ = 369000000000000; //369 Trillion

    address public admin;
    bool public _paused;

    constructor() {
        admin = msg.sender;
        balances[msg.sender] = totalSupply_;
    }

    function pause() external returns (bool success) {
        require(msg.sender == admin, "Not authorized");
        _paused = true;
        return _paused;
    }

    function unpause() external returns (bool success) {
        require(msg.sender == admin, "Not authorized");
        _paused = false;
        return _paused;
    }

    function adminChange(address newAdmin) external returns (address to) {
        require(msg.sender == admin, "Not authorized");
        admin = newAdmin;
        return newAdmin;
    }


    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_paused == false);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_paused == false);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);


        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function adminWithdraw() external returns (bool success) {
        require(msg.sender == admin, "Not authorized");
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }


    // Simple Voting

    struct Voter {
    uint weight; // weight is accumulated by delegation
    bool voted;  // if true, that person already voted
    address delegate; // person delegated to
    uint vote;   // index of the voted proposal
}

struct Proposal {
    bytes32 name;   // short name (up to 32 bytes)
    uint voteCount; // number of accumulated votes
}

address public chairperson;

mapping(address => Voter) public voters;

Proposal[] public proposals;

/**
 */
function giveRightToVote(address voter) public {
    require(
        msg.sender == chairperson,
        "Only chairperson can give right to vote."
    );
    require(
        !voters[voter].voted,
        "The voter already voted."
    );
    require(voters[voter].weight == 0);
    voters[voter].weight = 1;
}

/**
 * @dev Delegate your vote to the voter 'to'.
 * @param to address to which vote is delegated
 */
function delegate(address to) public {
    Voter storage sender = voters[msg.sender];
    require(!sender.voted, "You already voted.");
    require(to != msg.sender, "Self-delegation is disallowed.");

    while (voters[to].delegate != address(0)) {
        to = voters[to].delegate;

        // We found a loop in the delegation, not allowed.
        require(to != msg.sender, "Found loop in delegation.");
    }
    sender.voted = true;
    sender.delegate = to;
    Voter storage delegate_ = voters[to];
    if (delegate_.voted) {
        // If the delegate already voted,
        // directly add to the number of votes
        proposals[delegate_.vote].voteCount += sender.weight;
    } else {
        // If the delegate did not vote yet,
        // add to her weight.
        delegate_.weight += sender.weight;
    }
}

 
 // Minimal amount of token a user needs to own in order to vote
 uint256 public voteMinToken = 10000;
 
 function setVoteMinToken(uint256 newMinTokenVal) external returns (bool success) {
    require(msg.sender == admin, "Not authorized");
    voteMinToken = newMinTokenVal;
    return true;
 }
 
function vote(uint proposal) public {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, "Has no right to vote");
    require(!sender.voted, "Already voted.");
    require(voteMinToken >= balances[msg.sender], "No tokens!");
    sender.voted = true;
    sender.vote = proposal;

    proposals[proposal].voteCount += sender.weight;
}


function winningProposal() public view
        returns (uint winningProposal_)
{
    uint winningVoteCount = 0;
    for (uint p = 0; p < proposals.length; p++) {
        if (proposals[p].voteCount > winningVoteCount) {
            winningVoteCount = proposals[p].voteCount;
            winningProposal_ = p;
        }
    }
}


function winnerName() public view
        returns (bytes32 winnerName_)
{
    winnerName_ = proposals[winningProposal()].name;
}

bytes32[] proposalNames;



    // General functions
    fallback() external payable {}
    receive() external payable {} // Donations
}