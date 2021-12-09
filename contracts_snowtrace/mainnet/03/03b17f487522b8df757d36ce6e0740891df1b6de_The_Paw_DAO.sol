/**
 *Submitted for verification at snowtrace.io on 2021-12-09
*/

/**

The PAW DAO ($PAW) is building a 
community-owned decentralized 
financial infrastructure to bring 
more stability and transparency 
for the world. https://thepawdao.net/

            /~~~\   /~~\
           (     | |    )
           |     | |    |
            \   (  |   /'/~\
        /~~\ \   )  \/' /'  |
        |   \ `\/      /    |
         \   )   /~\  |    /'
          `~~  /'   `\ \__/
             /~       ~\
            /~          \
            `\  __     /'
              `~  `~~~'
*/

/**


This file is part of the DAO.

The DAO is free software: you can redistribute it andor modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the DAO.  If not, see <http:www.gnu.orglicenses>.


Standard smart contract for a Decentralized Autonomous Organization (DAO)
to automate organizational governance and decision-making.


import ".TokenCreation.sol";

pragma solidity ^0.4.4;

contract DAOInterface {
     The minimum debate period that a generic proposal can have
    uint constant minProposalDebatePeriod = 2 weeks;
     The minimum debate period that a split proposal can have
    uint constant quorumHalvingPeriod = 25 weeks;
     Period after which a proposal is closed
     (used in the case `executeProposal` fails because it throws)
    uint constant executeProposalPeriod = 10 days;
     Time for vote freeze. A proposal needs to have majority support before votingDeadline - preSupportTime
    uint constant preSupportTime = 2 days;
     Denotes the maximum proposal deposit that can be given. It is given as
     a fraction of total Ether spent plus balance of the DAO
    uint constant maxDepositDivisor = 100;

    Token contract
    Token token;

     Proposals to spend the DAO's ether
    Proposal[] public proposals;
     The quorum needed for each proposal is partially calculated by
     totalSupply  minQuorumDivisor
    uint public minQuorumDivisor;
     The unix time of the last time quorum was reached on a proposal
    uint public lastTimeMinQuorumMet;

     Address of the curator
    address public curator;
     The whitelist: List of addresses the DAO is allowed to send ether to
    mapping (address => bool) public allowedRecipients;

     Map of addresses blocked during a vote (not allowed to transfer DAO
     tokens). The address points to the proposal ID.
    mapping (address => uint) public blocked;

     Map of addresses and proposal voted on by this address
    mapping (address => uint[]) public votingRegister;

     The minimum deposit (in wei) required to submit any proposal that is not
     requesting a new Curator (no deposit is required for splits)
    uint public proposalDeposit;

     the accumulated sum of all current proposal deposits
    uint sumOfProposalDeposits;

     A proposal with `newCurator == false` represents a transaction
     to be issued by this DAO
     A proposal with `newCurator == true` represents a DAO split
    struct Proposal {
         The address where the `amount` will go to if the proposal is accepted
        address recipient;
         The amount to transfer to `recipient` if the proposal is accepted.
        uint amount;
         A plain text description of the proposal
        string description;
         A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
         True if the proposal's votes have yet to be counted, otherwise False
        bool open;
         True if quorum has been reached, the votes have been counted, and
         the majority said yes
        bool proposalPassed;
         A hash to check validity of a proposal
        bytes32 proposalHash;
         Deposit in wei the creator added when submitting their proposal. It
         is taken from the msg.value of a newProposal call.
        uint proposalDeposit;
         True if this proposal is to assign a new Curator
        bool newCurator;
         true if more tokens are in favour of the proposal than opposed to it at
         least `preSupportTime` before the voting deadline
        bool preSupport;
         Number of Tokens in favor of the proposal
        uint yea;
         Number of Tokens opposed to the proposal
        uint nay;
         Simple mapping to check if a shareholder has voted for it
        mapping (address => bool) votedYes;
         Simple mapping to check if a shareholder has voted against it
        mapping (address => bool) votedNo;
         Address of the shareholder who created the proposal
        address creator;
    }

     @dev Constructor setting the Curator and the address
     for the contract able to create another DAO as well as the parameters
     for the DAO Token Creation
     @param _curator The Curator
     @param _daoCreator The contract able to (re)create this DAO
     @param _proposalDeposit The deposit to be paid for a regular proposal
     @param _minTokensToCreate Minimum required wei-equivalent tokens
            to be created for a successful DAO Token Creation
     @param _closingTime Date (in Unix time) of the end of the DAO Token Creation
     @param _parentDAO If zero the DAO Token Creation is open to public, a
     non-zero address represents the parentDAO that can buy tokens in the
     creation phase.
     @param _tokenName The name that the DAO's token will have
     @param _tokenSymbol The ticker symbol that this DAO token should have
     @param _decimalPlaces The number of decimal places that the token is
            counted from.
     This is the constructor: it can not be overloaded so it is commented out
      function DAO(
          address _curator,
          DAO_Creator _daoCreator,
          uint _proposalDeposit,
          uint _minTokensToCreate,
          uint _closingTime,
          address _parentDAO,
          string _tokenName,
          string _tokenSymbol,
          uint8 _decimalPlaces
      );

     @notice donate without getting tokens
    function() payable;

     @notice `msg.sender` creates a proposal to send `_amount` Wei to
     `_recipient` with the transaction data `_transactionData`. If
     `_newCurator` is true, then this is a proposal that splits the
     DAO and sets `_recipient` as the new DAO's Curator.
     @param _recipient Address of the recipient of the proposed transaction
     @param _amount Amount of wei to be sent with the proposed transaction
     @param _description String describing the proposal
     @param _transactionData Data of the proposed transaction
     @param _debatingPeriod Time used for debating a proposal, at least 2
     weeks for a regular proposal, 10 days for new Curator proposal
     @param _newCurator Bool defining whether this proposal is about
     a new Curator or not
     @return The proposal ID. Needed for voting on the proposal
    function newProposal(
        address _recipient,
        uint _amount,
        string _description,
        bytes _transactionData,
        uint _debatingPeriod,
        bool _newCurator
    ) payable returns (uint _proposalID);

     @notice Check that the proposal with the ID `_proposalID` matches the
     transaction which sends `_amount` with data `_transactionData`
     to `_recipient`
     @param _proposalID The proposal ID
     @param _recipient The recipient of the proposed transaction
     @param _amount The amount of wei to be sent in the proposed transaction
     @param _transactionData The data of the proposed transaction
     @return Whether the proposal ID matches the transaction data or not
    function checkProposalCode(
        uint _proposalID,
        address _recipient,
        uint _amount,
        bytes _transactionData
    ) constant returns (bool _codeChecksOut);

     @notice Vote on proposal `_proposalID` with `_supportsProposal`
     @param _proposalID The proposal ID
     @param _supportsProposal YesNo - support of the proposal
    function vote(uint _proposalID, bool _supportsProposal);

     @notice Checks whether proposal `_proposalID` with transaction data
     `_transactionData` has been voted for or rejected, and executes the
     transaction in the case it has been voted for.
     @param _proposalID The proposal ID
     @param _transactionData The data of the proposed transaction
     @return Whether the proposed transaction has been executed or not
    function executeProposal(
        uint _proposalID,
        bytes _transactionData
    ) returns (bool _success);


     @dev can only be called by the DAO itself through a proposal
     updates the contract of the DAO by sending all ether and rewardTokens
     to the new DAO. The new DAO needs to be approved by the Curator
     @param _newContract the address of the new contract
    function newContract(address _newContract);


     @notice Add a new possible recipient `_recipient` to the whitelist so
     that the DAO can send transactions to them (using proposals)
     @param _recipient New recipient address
     @dev Can only be called by the current Curator
     @return Whether successful or not
    function changeAllowedRecipients(address _recipient, bool _allowed) external returns (bool _success);


     @notice Change the minimum deposit required to submit a proposal
     @param _proposalDeposit The new proposal deposit
     @dev Can only be called by this DAO (through proposals with the
     recipient being this DAO itself)
    function changeProposalDeposit(uint _proposalDeposit) external;

     @notice Doubles the 'minQuorumDivisor' in the case quorum has not been
     achieved in 52 weeks
     @return Whether the change was successful or not
    function halveMinQuorum() returns (bool _success);

     @return total number of proposals ever created
    function numberOfProposals() constant returns (uint _numberOfProposals);

     @param _account The address of the account which is checked.
     @return Whether the account is blocked (not allowed to transfer tokens) or not.
    function getOrModifyBlocked(address _account) internal returns (bool);

     @notice If the caller is blocked by a proposal whose voting deadline
     has exprired then unblock him.
     @return Whether the account is blocked (not allowed to transfer tokens) or not.
    function unblockMe() returns (bool);

    event ProposalAdded(
        uint indexed proposalID,
        address recipient,
        uint amount,
        string description
    );
    event Voted(uint indexed proposalID, bool position, address indexed voter);
    event ProposalTallied(uint indexed proposalID, bool result, uint quorum);
    event AllowedRecipientChanged(address indexed _recipient, bool _allowed);
}

 The DAO contract itself
contract DAO is DAOInterface{

     Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {
        if (token.balanceOf(msg.sender) == 0) throw;
            _;
    }

    function DAO(
        address _curator,
        uint _proposalDeposit,
        Token _token
    )  {
        token = _token;
        curator = _curator;
        proposalDeposit = _proposalDeposit;
        lastTimeMinQuorumMet = now;
        minQuorumDivisor = 7;  sets the minimal quorum to 14.3%
        proposals.length = 1;  avoids a proposal with ID 0 because it is used

        allowedRecipients[address(this)] = true;
        allowedRecipients[curator] = true;
    }

    function() payable {
    }

    function newProposal(
        address _recipient,
        uint _amount,
        string _description,
        bytes _transactionData,
        uint64 _debatingPeriod
    ) onlyTokenholders payable returns (uint _proposalID) {

        if (!allowedRecipients[_recipient]
            || _debatingPeriod < minProposalDebatePeriod
            || _debatingPeriod > 8 weeks
            || msg.value < proposalDeposit
            || msg.sender == address(this) to prevent a 51% attacker to convert the ether into deposit
            )
                throw;

         to prevent curator from halving quorum before first proposal
        if (proposals.length == 1)  initial length is 1 (see constructor)
            lastTimeMinQuorumMet = now;

        _proposalID = proposals.length++;
        Proposal p = proposals[_proposalID];
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.proposalHash = sha3(_recipient, _amount, _transactionData);
        p.votingDeadline = now + _debatingPeriod;
        p.open = true;
        p.proposalPassed = False;  that's default
        p.creator = msg.sender;
        p.proposalDeposit = msg.value;

        sumOfProposalDeposits += msg.value;

        ProposalAdded(
            _proposalID,
            _recipient,
            _amount,
            _description
        );
    }

    function checkProposalCode(
        uint _proposalID,
        address _recipient,
        uint _amount,
        bytes _transactionData
    ) constant returns (bool _codeChecksOut) {
        Proposal p = proposals[_proposalID];
        return p.proposalHash == sha3(_recipient, _amount, _transactionData);
    }

    function vote(uint _proposalID, bool _supportsProposal) {

        Proposal p = proposals[_proposalID];

        unVote(_proposalID);

        if (_supportsProposal) {
            p.yea += token.balanceOf(msg.sender);
            p.votedYes[msg.sender] = true;
        } else {
            p.nay += token.balanceOf(msg.sender);
            p.votedNo[msg.sender] = true;
        }

        if (blocked[msg.sender] == 0) {
            blocked[msg.sender] = _proposalID;
        } else if (p.votingDeadline > proposals[blocked[msg.sender]].votingDeadline) {
             this proposal's voting deadline is further into the future than
             the proposal that blocks the sender so make it the blocker
            blocked[msg.sender] = _proposalID;
        }

        votingRegister[msg.sender].push(_proposalID);
        Voted(_proposalID, _supportsProposal, msg.sender);
    }

    function unVote(uint _proposalID){
        Proposal p = proposals[_proposalID];

        if (now >= p.votingDeadline) {
            throw;
        }

        if (p.votedYes[msg.sender]) {
            p.yea -= token.balanceOf(msg.sender);
            p.votedYes[msg.sender] = false;
        }

        if (p.votedNo[msg.sender]) {
            p.nay -= token.balanceOf(msg.sender);
            p.votedNo[msg.sender] = false;
        }
    }

    function unVoteAll() {
         DANGEROUS loop with dynamic length - needs improvement
        for (uint i = 0; i < votingRegister[msg.sender].length; i++) {
            Proposal p = proposals[votingRegister[msg.sender][i]];
            if (now < p.votingDeadline)
                unVote(i);
        }

        votingRegister[msg.sender].length = 0;
        blocked[msg.sender] = 0;
    }
    
    function verifyPreSupport(uint _proposalID) {
        Proposal p = proposals[_proposalID];
        if (now < p.votingDeadline - preSupportTime) {
            if (p.yea > p.nay) {
                p.preSupport = true;
            }
            else
                p.preSupport = false;
        }
    }

    function executeProposal(
        uint _proposalID,
        bytes _transactionData
    ) returns (bool _success) {

        Proposal p = proposals[_proposalID];

         If we are over deadline and waiting period, assert proposal is closed
        if (p.open && now > p.votingDeadline + executeProposalPeriod) {
            closeProposal(_proposalID);
            return;
        }

         Check if the proposal can be executed
        if (now < p.votingDeadline   has the voting deadline arrived?
             Have the votes been counted?
            || !p.open
            || p.proposalPassed  anyone trying to call us recursively?
             Does the transaction code match the proposal?
            || p.proposalHash != sha3(p.recipient, p.amount, _transactionData)
            )
                throw;

         If the curator removed the recipient from the whitelist, close the proposal
         in order to free the deposit and allow unblocking of voters
        if (!allowedRecipients[p.recipient]) {
            closeProposal(_proposalID);
             the return value is not checked to prevent a malicious creator
             from delaying the closing of the proposal
            p.creator.send(p.proposalDeposit);
            return;
        }

        bool proposalCheck = true;

        if (p.amount > actualBalance() || p.preSupport == false)
            proposalCheck = false;

        uint quorum = p.yea;

         require max quorum for calling newContract()
        if (_transactionData.length >= 4 && _transactionData[0] == 0x68
            && _transactionData[1] == 0x37 && _transactionData[2] == 0xff
            && _transactionData[3] == 0x1e
            && quorum < minQuorum(actualBalance())
            )
                proposalCheck = false;

        if (quorum >= minQuorum(p.amount)) {
            if (!p.creator.send(p.proposalDeposit))
                throw;

            lastTimeMinQuorumMet = now;
             set the minQuorum to 14.3% again, in the case it has been reached
            if (quorum > token.totalSupply()  7)
                minQuorumDivisor = 7;
        }

         Execute result
        if (quorum >= minQuorum(p.amount) && p.yea > p.nay && proposalCheck) {
             we are setting this here before the CALL() value transfer to
             assure that in the case of a malicious recipient contract trying
             to call executeProposal() recursively money can't be transferred
             multiple times out of the DAO
            p.proposalPassed = true;

             this call is as generic as any transaction. It sends all gas and
             can do everything a transaction can do. It can be used to reenter
             the DAO. The `p.proposalPassed` variable prevents the call from 
             reaching this line again
            if (!p.recipient.call.value(p.amount)(_transactionData))
                throw;

            _success = true;
        }

        closeProposal(_proposalID);

         Initiate event
        ProposalTallied(_proposalID, _success, quorum);
    }


    function closeProposal(uint _proposalID) internal {
        Proposal p = proposals[_proposalID];
        if (p.open)
            sumOfProposalDeposits -= p.proposalDeposit;
        p.open = false;
    }

Since it is possible to continuously send ETH to the contract and create tokens,
this withdraw functions is flawed and needs to be replaced by an improved version
    function withdraw() onlyTokenholders returns (bool _success) {

        unVoteAll();

         Move ether
        uint senderBalance = balances[msg.sender];
         TODO this is flawed
        uint fundsToBeMoved = (senderBalance  actualBalance())  totalSupply;
        balances[msg.sender] = 0;
        msg.sender.send(fundsToBeMoved);

         Burn DAO Tokens
        totalSupply -= senderBalance;
         event for light client notification
        Transfer(msg.sender, 0, senderBalance);
        return true;
    }


    function newContract(address _newContract){
        if (msg.sender != address(this) || !allowedRecipients[_newContract]) return;
         move all ether
        if (!_newContract.call.value(address(this).balance)()) {
            throw;
        }
    }

    function changeProposalDeposit(uint _proposalDeposit) external {
        if (msg.sender != address(this) || _proposalDeposit > (actualBalance())
             maxDepositDivisor) {
            throw;
        }
        proposalDeposit = _proposalDeposit;
    }


    function changeAllowedRecipients(address _recipient, bool _allowed) external returns (bool _success) {
        if (msg.sender != curator)
            throw;
        allowedRecipients[_recipient] = _allowed;
        AllowedRecipientChanged(_recipient, _allowed);
        return true;
    }


    function actualBalance() constant returns (uint _actualBalance) {
        return this.balance - sumOfProposalDeposits;
    }


    function minQuorum(uint _value) internal constant returns (uint _minQuorum) {
         minimum of 14.3% and maximum of 47.6%
        return token.totalSupply()  minQuorumDivisor +
            (_value  token.totalSupply())  (3  (actualBalance()));
    }
  
*/
pragma solidity ^0.4.24;

contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

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

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
// PAW DAO
contract The_Paw_DAO is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "PAW";
        name = "The Paw DAO";
        decimals = 18;
        _totalSupply = 100000000000000000000000000000;
        balances[0xa86a7FcAA847E31a6A6b20360D8118E1A50fC13B] = _totalSupply;
        emit Transfer(address(0), 0xa86a7FcAA847E31a6A6b20360D8118E1A50fC13B, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    function () public payable {
        revert();
    }
}