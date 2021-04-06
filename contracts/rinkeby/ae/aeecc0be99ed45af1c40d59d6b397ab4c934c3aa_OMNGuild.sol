// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../erc20guild/ERC20Guild.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

/// @title OMNGuild - OMEN Token ERC20Guild
/// The OMN guild will use the OMN token for governance, having to lock the tokens, and needing a minimum amount of 
/// tokens locked to create proposals.
/// The guild will be used for OMN token governance and to arbitrate markets validation in omen, using reality.io
/// boolean question markets "Is market MARKET_ID valid?".
/// The guild will be summoned to arbitrate a market validation if required.
/// The voters who vote in market validation proposals will recieve a vote reward.
contract OMNGuild is ERC20Guild {
    using SafeMathUpgradeable for uint256;

    // The max amount of votes that can de used in a proposal
    uint256 public maxAmountVotes;
    
    // The address of the reality.io smart contract
    address public realityIO;
    
    // The function signature of function to be exeucted by the guild to resolve a question in reality.io
    bytes4 public submitAnswerByArbitratorSignature;
    
    // This amount of OMN tokens to be distributed among voters depending on their vote decision and amount
    uint256 public successfulVoteReward;
    uint256 public unsuccessfulVoteReward;
    
    // Reality.io Question IDs => Market validation proposals
    struct MarketValidationProposal {
      bytes32 marketValid;
      bytes32 marketInvalid;
    }
    mapping(bytes32 => MarketValidationProposal) public marketValidationProposals;
    
    // Market validation proposal ids => Reality.io Question IDs
    mapping(bytes32 => bytes32) public proposalsForMarketValidation;

    // Saves which accounts claimed their market validation vote rewards
    mapping(bytes32 => mapping(address => bool)) public rewardsClaimed;
    
    // Save how much accounts voted in a proposal
    mapping(bytes32 => uint256) public positiveVotesCount;

    /// @dev Initilizer
    /// Sets the call permission to arbitrate markets allowed by default and create the market question tempate in 
    /// reality.io to be used on markets created with the guild
    /// @param _token The address of the token to be used
    /// @param _proposalTime The minimun time for a proposal to be under votation
    /// @param _timeForExecution The amount of time that has a proposal has to be executed before being ended
    /// @param _votesForExecution The % of votes needed for a proposal to be executed based on the token total supply.
    /// 10000 == 100%, 5000 == 50% and 2500 == 25%
    /// @param _votesForCreation The % of votes needed for a proposal to be created based on the token total supply.
    /// 10000 == 100%, 5000 == 50% and 2500 == 25%
    /// @param _voteGas The gas to be used to calculate the vote gas refund
    /// @param _maxGasPrice The maximum gas price to be refunded
    /// @param _lockTime The minimum amount of seconds that the tokens would be locked
    /// @param _maxAmountVotes The max amount of votes allowed ot have
    /// @param _realityIO The address of the realityIO contract
    function initialize(
        address _token,
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votesForExecution,
        uint256 _votesForCreation,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _lockTime,
        uint256 _maxAmountVotes,
        address _realityIO
    ) public initializer {
        super.initialize(
          _token,
          _proposalTime,
          _timeForExecution,
          _votesForExecution,
          _votesForCreation,
          "OMNGuild", 
          _voteGas,
          _maxGasPrice,
          _lockTime
        );
        realityIO = _realityIO;
        maxAmountVotes = _maxAmountVotes;
        submitAnswerByArbitratorSignature = bytes4(
          keccak256("submitAnswerByArbitrator(bytes32,bytes32,address)")
        );
        callPermissions[realityIO][submitAnswerByArbitratorSignature] = true;
        callPermissions[address(this)][bytes4(keccak256("setOMNGuildConfig(uint256,address,uint256,uint256"))] = true;
    }
    
    /// @dev Set OMNGuild specific parameters
    /// @param _maxAmountVotes The max amount of votes allowed ot have
    /// @param _realityIO The address of the realityIO contract
    /// @param _successfulVoteReward The amount of OMN tokens in wei unit to be reward to a voter after a succesful 
    ///  vote
    /// @param _unsuccessfulVoteReward The amount of OMN tokens in wei unit to be reward to a voter after a unsuccesful
    ///  vote
    function setOMNGuildConfig(
        uint256 _maxAmountVotes,
        address _realityIO,
        uint256 _successfulVoteReward,
        uint256 _unsuccessfulVoteReward
    ) public isInitialized {
        realityIO = _realityIO;
        maxAmountVotes = _maxAmountVotes;
        successfulVoteReward = _successfulVoteReward;
        unsuccessfulVoteReward = _unsuccessfulVoteReward;
    }
    
    /// @dev Create proposals with an static call data and extra information
    /// @param to The receiver addresses of each call to be executed
    /// @param data The data to be executed on each call to be executed
    /// @param value The ETH value to be sent on each call to be executed
    /// @param description A short description of the proposal
    /// @param contentHash The content hash of the content reference of the proposal for the proposal to be executed
    function createProposals(
        address[] memory to,
        bytes[] memory data,
        uint256[] memory value,
        string[] memory description,
        bytes[] memory contentHash
    ) public isInitialized returns(bytes32[] memory) {
        require(votesOf(msg.sender) >= getVotesForCreation(), "OMNGuild: Not enough tokens to create proposal");
        require(
            (to.length == data.length) && (to.length == value.length),
            "OMNGuild: Wrong length of to, data or value arrays"
        );
        require(
            (description.length == contentHash.length),
            "OMNGuild: Wrong length of description or contentHash arrays"
        );
        require(to.length > 0, "OMNGuild: to, data value arrays cannot be empty");
        bytes32[] memory proposalsCreated;
        uint256 proposalsToCreate = description.length;
        uint256 callsPerProposal = to.length.div(proposalsToCreate);
        for(uint proposalIndex = 0; proposalIndex < proposalsToCreate; proposalIndex ++) {
            address[] memory _to;
            bytes[] memory _data;
            uint256[] memory _value;
            uint256 callIndex;
            for(
                uint callIndexInProposals = callsPerProposal.mul(proposalIndex);
                callIndexInProposals < callsPerProposal;
                callIndexInProposals ++
            ) {
                _to[callIndex] = to[callIndexInProposals];
                _data[callIndex] = data[callIndexInProposals];
                _value[callIndex] = value[callIndexInProposals];
                callIndex ++;
            }
            proposalsCreated[proposalIndex] =
              _createProposal(_to, _data, _value, description[proposalIndex], contentHash[proposalIndex]);
        }
        return proposalsCreated;
    }
    
    /// @dev Create two proposals one to vote for the validation fo a market in realityIo
    /// @param questionId the id of the question to be validated in realitiyIo
    function createMarketValidationProposal(bytes32 questionId) public isInitialized {
        require(votesOf(msg.sender) >= getVotesForCreation(), "OMNGuild: Not enough tokens to create proposal");      
        
        address[] memory _to;
        bytes[] memory _data;
        uint256[] memory _value;
        bytes memory _contentHash = abi.encodePacked(questionId);
        _value[0] = 0;
        _to[0] = realityIO;
          
        // Create market valid proposal
        _data[0] = abi.encodeWithSelector(
            submitAnswerByArbitratorSignature, questionId, keccak256(abi.encodePacked(true)), address(this)
        );
        marketValidationProposals[questionId].marketValid = 
            _createProposal( _to, _data, _value, string("Market valid"), _contentHash );
        
        proposalsForMarketValidation[marketValidationProposals[questionId].marketValid] = questionId;
        // Create market invalid proposal
        _data[0] = abi.encodeWithSelector(
            submitAnswerByArbitratorSignature, questionId, keccak256(abi.encodePacked(false)), address(this)
        );
        marketValidationProposals[questionId].marketInvalid = 
            _createProposal( _to, _data, _value, string("Market invalid"), _contentHash );
        proposalsForMarketValidation[marketValidationProposals[questionId].marketInvalid] = questionId;
    }
    
    /// @dev Ends the market validation by executing the proposal with higher votes and rejecting the other
    /// @param questionId the proposalId of the voting machine
    function endMarketValidationProposal( bytes32 questionId ) public {
        Proposal storage marketValidProposal = proposals[marketValidationProposals[questionId].marketValid];
        Proposal storage marketInvalidProposal = proposals[marketValidationProposals[questionId].marketInvalid];
        
        require(marketValidProposal.state == ProposalState.Submitted, "OMNGuild: Market valid proposal already executed");
        require(marketInvalidProposal.state == ProposalState.Submitted, "OMNGuild: Market invalid proposal already executed");
        require(marketValidProposal.endTime < block.timestamp, "OMNGuild: Market valid proposal hasnt ended yet");
        require(marketInvalidProposal.endTime < block.timestamp, "OMNGuild: Market invalid proposal hasnt ended yet");
        
        if (marketValidProposal.totalVotes > marketInvalidProposal.totalVotes) {
            _endProposal(marketValidationProposals[questionId].marketValid);
            marketInvalidProposal.state = ProposalState.Rejected;
            emit ProposalRejected(marketValidationProposals[questionId].marketInvalid);
        } else {
            _endProposal(marketValidationProposals[questionId].marketInvalid);
            marketValidProposal.state = ProposalState.Rejected;
            emit ProposalRejected(marketValidationProposals[questionId].marketValid);
        }
    }
    
    /// @dev Execute a proposal that has already passed the votation time and has enough votes
    /// This function cant end market validation proposals
    /// @param proposalId The id of the proposal to be executed
    function endProposal(bytes32 proposalId) override public {
        require(
            proposalsForMarketValidation[proposalId] == bytes32(0),
            "OMNGuild: Use endMarketValidationProposal to end proposals to validate market"
        );
        require(proposals[proposalId].state == ProposalState.Submitted, "ERC20Guild: Proposal already executed");
        require(proposals[proposalId].endTime < block.timestamp, "ERC20Guild: Proposal hasnt ended yet");
        _endProposal(proposalId);
    }
    
    /// @dev Claim the vote rewards of multiple proposals at once
    /// @param proposalIds The ids of the proposal already finished were a vote was set and vote reward not claimed
    /// @param voter The address of the voter to receiver the rewards
    function claimMarketValidationVoteRewards(bytes32[] memory proposalIds, address voter) public {
      uint256 reward;
      for(uint i = 0; i < proposalIds.length; i ++) {
          require(
              proposalsForMarketValidation[proposalIds[i]] != bytes32(0),
              "OMNGuild: Cant claim from proposal that isnt for market validation"
          );
          require(
              proposals[proposalIds[i]].state == ProposalState.Executed ||
              proposals[proposalIds[i]].state == ProposalState.Rejected,
              "OMNGuild: Proposal to claim should be executed or rejected"
          );
          require(!rewardsClaimed[proposalIds[i]][voter], "OMNGuild: Vote reward already claimed");
          // If proposal was executed and vote was positive the vote was for a succesful action
          if (
            proposals[proposalIds[i]].state == ProposalState.Executed && 
            proposals[proposalIds[i]].votes[voter] > 0
          ) {
            reward.add(successfulVoteReward.div(positiveVotesCount[proposalIds[i]]));
          // If proposal was rejected and vote was positive the vote was for a unsuccesful action
          } else if (
            proposals[proposalIds[i]].state == ProposalState.Rejected && 
            proposals[proposalIds[i]].votes[voter] > 0
          ) {
            reward.add(unsuccessfulVoteReward.div(positiveVotesCount[proposalIds[i]]));
          }
          
          // Mark reward as claimed
          rewardsClaimed[proposalIds[i]][voter] = true;
      }
      
      // Send the total reward
      _sendTokenReward(voter, reward);
    }
    
    /// @dev Set the amount of tokens to vote in a proposal
    /// @param proposalId The id of the proposal to set the vote
    /// @param amount The amount of votes to be set in the proposal
    function setVote(bytes32 proposalId, uint256 amount) override public virtual {
        require(
            votesOfAt(msg.sender, proposals[proposalId].snapshotId) >=  amount,
            "ERC20Guild: Invalid amount"
        );
        require(proposals[proposalId].votes[msg.sender] == 0, "OMNGuild: Already voted");
        require(amount <= maxAmountVotes, "OMNGuild: Cant vote with more votes than max amount of votes");
        if (amount > 0) {
          positiveVotesCount[proposalId].add(1);
        }
        _setVote(msg.sender, proposalId, amount);
        _refundVote(msg.sender);
    }

    /// @dev Set the amount of tokens to vote in multiple proposals
    /// @param proposalIds The ids of the proposals to set the votes
    /// @param amounts The amount of votes to be set in each proposal
    function setVotes(bytes32[] memory proposalIds, uint256[] memory amounts) override public virtual {
        require(
            proposalIds.length == amounts.length,
            "ERC20Guild: Wrong length of proposalIds or amounts"
        );
        for(uint i = 0; i < proposalIds.length; i ++){
            require(
                votesOfAt(msg.sender, proposals[proposalIds[i]].snapshotId) >=  amounts[i],
                "ERC20Guild: Invalid amount"
            );
            require(proposals[proposalIds[i]].votes[msg.sender] == 0, "OMNGuild: Already voted");
            require(amounts[i] <= maxAmountVotes, "OMNGuild: Cant vote with more votes than max amount of votes");
            if (amounts[i] > 0) {
                positiveVotesCount[proposalIds[i]].add(1);
            }
            _setVote(msg.sender, proposalIds[i], amounts[i]);
        }
    }
    
    /// @dev Internal function to send a reward of OMN tokens (if the balance is enough) to an address
    /// @param to The address to recieve the token
    /// @param amount The amount of OMN tokens to be sent in wei units
    function _sendTokenReward(address to, uint256 amount) internal {
        if (token.balanceOf(address(this)) > amount) {
            token.transfer(to, amount);
        }
    }
    
    /// @dev Get minimum amount of votes needed for creation
    function getVotesForCreation() override public view returns (uint256) {
        return token.totalSupply().mul(votesForCreation).div(10000);
    }
    
    /// @dev Get minimum amount of votes needed for proposal execution
    function getVotesForExecution() override public view returns (uint256) {
        return token.totalSupply().mul(votesForExecution).div(10000);
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../utils/TokenVault.sol";
import "../utils/Arrays.sol";

/// @title ERC20Guild
/// @author github:AugustoL
/// @dev Extends an ERC20 functionality into a Guild, adding a simple governance system over an ERC20 token.
/// An ERC20Guild is a simple organization that execute actions if a minimun amount of positive votes are reached in 
/// a certain amount of time.
/// In order to vote a token hodler need to lock tokens in the guild.
/// The tokens are locked for a minimum amount of time.
/// The voting power equals the amount of tokens locked in the guild.
/// A proposal is executed only when the mimimum amount of votes are reached before it finishes.
/// The guild can execute only allowed functions, if a function is not allowed it first will need to set the allowance
/// for it and then after being succesfully added to allowed functions a proposal for it execution can be created.
/// Once a proposal is approved it can execute only once during a certain period of time.
contract ERC20Guild is Initializable {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using Arrays for uint256[];
    
    enum ProposalState {Submitted, Rejected, Executed, Failed}

    IERC20Upgradeable public token;
    bool public initialized;
    string public name;
    uint256 public proposalTime;
    uint256 public timeForExecution;
    uint256 public votesForExecution;
    uint256 public votesForCreation;
    uint256 public voteGas;
    uint256 public maxGasPrice;
    uint256 public lockTime;
    uint256 public totalLocked;
    TokenVault public tokenVault;
    uint256 public proposalNonce;
    
    // All the signed votes that were executed, to avoid double signed vote execution.
    mapping(bytes32 => bool) public signedVotes;
    
    // The signatures of the functions allowed, indexed first by address and then by function signature
    mapping(address => mapping(bytes4 => bool)) public callPermissions;
    
    // The tokens locked indexed by token holder address.
    struct TokenLock {
      uint256 amount;
      uint256 timestamp;
    }
    mapping(address => TokenLock) public tokensLocked;
    
    // Proposals indexed by proposal id.
    struct Proposal {
        address creator;
        uint256 startTime;
        uint256 endTime;
        address[] to;
        bytes[] data;
        uint256[] value;
        string description;
        bytes contentHash;
        uint256 totalVotes;
        ProposalState state;
        uint256 snapshotId;
        mapping(address => uint256) votes;
    }
    mapping(bytes32 => Proposal) public proposals;
    
    // Array to keep track of the proposalsIds in contract storage
    bytes32[] public proposalsIds;
    
    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    // The snapshots used for votes and total tokens locked.
    mapping (address => Snapshots) private _votesSnapshots;
    Snapshots private _totalLockedSnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    uint256 private _currentSnapshotId;
    
    event ProposalCreated(bytes32 indexed proposalId);
    event ProposalRejected(bytes32 indexed proposalId);
    event ProposalExecuted(bytes32 indexed proposalId);
    event ProposalEnded(bytes32 indexed proposalId);
    event VoteAdded(bytes32 indexed proposalId, address voter, uint256 amount);
    event VoteRemoved(bytes32 indexed proposalId, address voter, uint256 amount);
    event SetAllowance(address indexed to, bytes4 functionSignature, bool allowance);
    event TokensLocked(address voter, uint256 value);
    event TokensReleased(address voter, uint256 value);
    
    /// @dev Allows the voting machine to receive ether to be used to refund voting costs
    fallback() external payable {}
    receive() external payable {}
    
    /// @dev Initialized modifier to require the contract to be initialized
    modifier isInitialized() {
        require(initialized, "ERC20Guild: Not initilized");
        _;
    }
    
    /// @dev Initilizer
    /// @param _token The address of the token to be used
    /// @param _proposalTime The minimun time for a proposal to be under votation
    /// @param _timeForExecution The amount of time that has a proposal has to be executed before being ended
    /// @param _votesForExecution The token votes needed for a proposal to be executed
    /// @param _votesForCreation The minimum balance of tokens needed to create a proposal
    /// @param _voteGas The gas to be used to calculate the vote gas refund
    /// @param _maxGasPrice The maximum gas price to be refunded
    /// @param _lockTime The minimum amount of seconds that the tokens would be locked
    function initialize(
        address _token,
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votesForExecution,
        uint256 _votesForCreation,
        string memory _name,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _lockTime
    ) public virtual initializer {
        require(address(_token) != address(0), "ERC20Guild: token is the zero address");
        name = _name;
        token = IERC20Upgradeable(_token);
        tokenVault = new TokenVault();
        tokenVault.initialize(address(token), address(this));
        _setConfig(
          _proposalTime,
          _timeForExecution,
          _votesForExecution,
          _votesForCreation,
          _voteGas,
          _maxGasPrice,
          _lockTime
        );
        callPermissions[address(this)][
          bytes4(keccak256("setConfig(uint256,uint256,uint256,uint256,uint256,uint256,uint256)"))
        ] = true;
        callPermissions[address(this)][bytes4(keccak256("setAllowance(address[],bytes4[],bool[])"))] = true;
        initialized = true;
    }
    
    /// @dev Set the ERC20Guild configuration, can be called only executing a proposal 
    /// or when it is initilized
    /// @param _proposalTime The minimun time for a proposal to be under votation
    /// @param _timeForExecution The amount of time that has a proposal has to be executed before being ended
    /// @param _votesForExecution The token votes needed for a proposal to be executed
    /// @param _votesForCreation The minimum balance of tokens needed to create a proposal
    /// @param _voteGas The gas to be used to calculate the vote gas refund
    /// @param _maxGasPrice The maximum gas price to be refunded
    /// @param _lockTime The minimum amount of seconds that the tokens would be locked
    function setConfig(
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votesForExecution,
        uint256 _votesForCreation,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _lockTime
    ) public virtual {
        _setConfig(
          _proposalTime,
          _timeForExecution,
          _votesForExecution,
          _votesForCreation,
          _voteGas,
          _maxGasPrice,
          _lockTime
        );
    }
    
    /// @dev Set the allowance of a call to be executed by the guild
    /// @param to The address to be called
    /// @param functionSignature The signature of the function
    /// @param allowance If the function is allowed to be called or not
    function setAllowance(
        address[] memory to,
        bytes4[] memory functionSignature,
        bool[] memory allowance
    ) public virtual isInitialized {
        require(msg.sender == address(this), "ERC20Guild: Only callable by ERC20guild itself");
        require(
            (to.length == functionSignature.length) && (to.length == allowance.length),
            "ERC20Guild: Wrong length of to, functionSignature or allowance arrays"
        );
        for (uint256 i = 0; i < to.length; i++) {
            require(functionSignature[i] != bytes4(0), "ERC20Guild: Empty sigantures not allowed");
            callPermissions[to[i]][functionSignature[i]] = allowance[i];
            emit SetAllowance(to[i], functionSignature[i], allowance[i]);
        }
        require(
          callPermissions[address(this)][
            bytes4(keccak256("setConfig(uint256,uint256,uint256,uint256,uint256,uint256,uint256)"))
          ],
          "ERC20Guild: setConfig function allowance cant be turned off"
        );
        require(
          callPermissions[address(this)][bytes4(keccak256("setAllowance(address[],bytes4[],bool[])"))],
          "ERC20Guild: setAllowance function allowance cant be turned off"
        );
    }

    /// @dev Create a proposal with an static call data and extra information
    /// @param to The receiver addresses of each call to be executed
    /// @param data The data to be executed on each call to be executed
    /// @param value The ETH value to be sent on each call to be executed
    /// @param description A short description of the proposal
    /// @param contentHash The content hash of the content reference of the proposal for the proposal to be executed
    function createProposal(
        address[] memory to,
        bytes[] memory data,
        uint256[] memory value,
        string memory description,
        bytes memory contentHash
    ) public virtual isInitialized returns(bytes32) {
        require(votesOf(msg.sender) >= getVotesForCreation(), "ERC20Guild: Not enough tokens to create proposal");
        require(
            (to.length == data.length) && (to.length == value.length),
            "ERC20Guild: Wrong length of to, data or value arrays"
        );
        require(to.length > 0, "ERC20Guild: to, data value arrays cannot be empty");
        return _createProposal(to, data, value, description, contentHash);
    }
    
    /// @dev Execute a proposal that has already passed the votation time and has enough votes
    /// @param proposalId The id of the proposal to be executed
    function endProposal(bytes32 proposalId) public virtual {
      require(proposals[proposalId].state == ProposalState.Submitted, "ERC20Guild: Proposal already executed");
      require(proposals[proposalId].endTime < block.timestamp, "ERC20Guild: Proposal hasnt ended yet");
      _endProposal(proposalId);
    }
    
    /// @dev Set the amount of tokens to vote in a proposal
    /// @param proposalId The id of the proposal to set the vote
    /// @param amount The amount of votes to be set in the proposal
    function setVote(bytes32 proposalId, uint256 amount) public virtual {
        require(
            votesOfAt(msg.sender, proposals[proposalId].snapshotId) >=  amount,
            "ERC20Guild: Invalid amount"
        );
        _setVote(msg.sender, proposalId, amount);
        _refundVote(msg.sender);
    }

    /// @dev Set the amount of tokens to vote in multiple proposals
    /// @param proposalIds The ids of the proposals to set the votes
    /// @param amounts The amount of votes to be set in each proposal
    function setVotes(bytes32[] memory proposalIds, uint256[] memory amounts) public virtual {
        require(
            proposalIds.length == amounts.length,
            "ERC20Guild: Wrong length of proposalIds or amounts"
        );
        for(uint i = 0; i < proposalIds.length; i ++)
            _setVote(msg.sender, proposalIds[i], amounts[i]);
    }
    
    /// @dev Set the amount of tokens to vote in a proposal using a signed vote
    /// @param proposalId The id of the proposal to set the vote
    /// @param amount The amount of tokens to use as voting for the proposal
    /// @param voter The address of the voter
    /// @param signature The signature of the hashed vote
    function setSignedVote(
        bytes32 proposalId, uint256 amount, address voter, bytes memory signature
    ) public virtual isInitialized {
        bytes32 hashedVote = hashVote(voter, proposalId, amount);
        require(!signedVotes[hashedVote], 'ERC20Guild: Already voted');
        require(
          voter == hashedVote.toEthSignedMessageHash().recover(signature),
          "ERC20Guild: Wrong signer"
        );
        _setVote(voter, proposalId, amount);
        signedVotes[hashedVote] = true;
    }
    
    /// @dev Set the amount of tokens to vote in multiple proposals using signed votes
    /// @param proposalIds The ids of the proposals to set the votes
    /// @param amounts The amounts of tokens to use as voting for each proposals
    /// @param voters The accounts that signed the votes
    /// @param signatures The vote signatures
    function setSignedVotes(
        bytes32[] memory proposalIds, uint256[] memory amounts, address[] memory voters, bytes[] memory signatures
    ) public virtual {
        for (uint i = 0; i < proposalIds.length; i ++) {
            setSignedVote(proposalIds[i], amounts[i], voters[i], signatures[i]);
        }
    }
    
    /// @dev Lock tokens in the guild to be used as voting power
    /// @param amount The amount of tokens to be locked
    function lockTokens(uint256 amount) public virtual {
        _updateAccountSnapshot(msg.sender);
        _updateTotalSupplySnapshot();
        tokenVault.deposit(msg.sender, amount);
        tokensLocked[msg.sender].amount = tokensLocked[msg.sender].amount.add(amount);
        tokensLocked[msg.sender].timestamp = block.timestamp.add(lockTime);
        totalLocked = totalLocked.add(amount);
        emit TokensLocked(msg.sender, amount);
    }

    /// @dev Release tokens locked in the guild, this will decrease the voting power
    /// @param amount The amount of tokens to be released
    function releaseTokens(uint256 amount) public virtual {
        require(votesOf(msg.sender) >= amount, "ERC20Guild: Unable to release more tokens than locked");
        require(tokensLocked[msg.sender].timestamp < block.timestamp, "ERC20Guild: Tokens still locked");
        _updateAccountSnapshot(msg.sender);
        _updateTotalSupplySnapshot();
        tokensLocked[msg.sender].amount = tokensLocked[msg.sender].amount.sub(amount);
        totalLocked = totalLocked.sub(amount);
        tokenVault.withdraw(msg.sender, amount);
        emit TokensReleased(msg.sender, amount);
    }
    
    /// @dev Create a proposal with an static call data and extra information
    /// @param to The receiver addresses of each call to be executed
    /// @param data The data to be executed on each call to be executed
    /// @param value The ETH value to be sent on each call to be executed
    /// @param description A short description of the proposal
    /// @param contentHash The content hash of the content reference of the proposal for the proposal to be executed
    function _createProposal(
        address[] memory to,
        bytes[] memory data,
        uint256[] memory value,
        string memory description,
        bytes memory contentHash
    ) internal returns(bytes32) {
        bytes32 proposalId = keccak256(abi.encodePacked(msg.sender, block.timestamp, proposalNonce));
        proposalNonce = proposalNonce.add(1);
        _currentSnapshotId = _currentSnapshotId.add(1);
        Proposal storage newProposal = proposals[proposalId];
        newProposal.creator = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp.add(proposalTime);
        newProposal.to = to;
        newProposal.data = data;
        newProposal.value = value;
        newProposal.description = description;
        newProposal.contentHash = contentHash;
        newProposal.totalVotes = 0;
        newProposal.state = ProposalState.Submitted;
        newProposal.snapshotId = _currentSnapshotId;
        
        emit ProposalCreated(proposalId);
        _setVote(msg.sender, proposalId, votesOf(msg.sender));
        proposalsIds.push(proposalId);
        return proposalId;
    }
    
    /// @dev Execute a proposal that has already passed the votation time and has enough votes
    /// @param proposalId The id of the proposal to be executed
    function _endProposal(bytes32 proposalId) internal {
        if (
          proposals[proposalId].totalVotes < getVotesForExecution()
          && proposals[proposalId].state == ProposalState.Submitted
        ){
          proposals[proposalId].state = ProposalState.Rejected;
          emit ProposalRejected(proposalId);
        } else if (
          proposals[proposalId].endTime.add(timeForExecution) < block.timestamp
          && proposals[proposalId].state == ProposalState.Submitted
        ) {
          proposals[proposalId].state = ProposalState.Failed;
          emit ProposalEnded(proposalId);
        } else if (proposals[proposalId].state == ProposalState.Submitted) {
          proposals[proposalId].state = ProposalState.Executed;
          for (uint i = 0; i < proposals[proposalId].to.length; i ++) {
            bytes4 proposalSignature = getFuncSignature(proposals[proposalId].data[i]);
            require(
              getCallPermission(proposals[proposalId].to[i], proposalSignature),
              "ERC20Guild: Not allowed call"
              );
              (bool success,) = proposals[proposalId].to[i]
                .call{value: proposals[proposalId].value[i]}(proposals[proposalId].data[i]);
              require(success, "ERC20Guild: Proposal call failed");
            }
            emit ProposalExecuted(proposalId);
        }
    }

    /// @dev Internal function to set the configuration of the guild
    /// @param _proposalTime The minimum time for a proposal to be under votation
    /// @param _timeForExecution The amount of time that has a proposal has to be executed before being ended
    /// @param _votesForExecution The token votes needed for a proposal to be executed
    /// @param _votesForCreation The minimum balance of tokens needed to create a proposal
    /// @param _voteGas The gas to be used to calculate the vote gas refund
    /// @param _maxGasPrice The maximum gas price to be refunded
    /// @param _lockTime The minimum amount of seconds that the tokens would be locked
    function _setConfig(
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votesForExecution,
        uint256 _votesForCreation,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _lockTime
    ) internal {
      require(
          !initialized || (msg.sender == address(this)),
          "ERC20Guild: Only callable by ERC20guild itself when initialized"
      );
      require(_proposalTime >= 0, "ERC20Guild: proposal time has to be more tha 0");
      require(_votesForExecution > 0, "ERC20Guild: votes for execution has to be more than 0");
      require(_lockTime > 0, "ERC20Guild: lockTime should be higher than zero");
      proposalTime = _proposalTime;
      timeForExecution = _timeForExecution;
      votesForExecution = _votesForExecution;
      votesForCreation = _votesForCreation;
      voteGas = _voteGas;
      maxGasPrice = _maxGasPrice;
      lockTime = _lockTime;
    }

    /// @dev Internal function to set the amount of tokens to vote in a proposal
    /// @param voter The address of the voter
    /// @param proposalId The id of the proposal to set the vote
    /// @param amount The amount of tokens to use as voting for the proposal
    function _setVote(address voter, bytes32 proposalId, uint256 amount) internal isInitialized {
        require(proposals[proposalId].state == ProposalState.Submitted, "ERC20Guild: Proposal already executed");
        require(votesOf(voter) >=  amount, "ERC20Guild: Invalid amount");
        if (amount > proposals[proposalId].votes[voter]) {
            proposals[proposalId].totalVotes = proposals[proposalId].totalVotes.add(
                amount.sub(proposals[proposalId].votes[voter])
            );
            emit VoteAdded(
                proposalId, voter, amount.sub(proposals[proposalId].votes[voter])
            );
        } else {
            proposals[proposalId].totalVotes = proposals[proposalId].totalVotes.sub(
                proposals[proposalId].votes[voter].sub(amount)
            );
            emit VoteRemoved(
                proposalId, voter, proposals[proposalId].votes[voter].sub(amount)
            );
        }
        proposals[proposalId].votes[voter] = amount;
    }
    
    /// @dev Internal function to refund a vote cost to a sender
    /// The refund will be exeuted only if the voteGas is higher than zero and there is enough ETH balance in the guild.
    /// @param toAddress The address where the refund should be sent
    function _refundVote(address payable toAddress) internal isInitialized {
      if (voteGas > 0) {
        uint256 gasRefund = voteGas.mul(tx.gasprice.min(maxGasPrice));
        if (address(this).balance >= gasRefund) {
          toAddress.transfer(gasRefund);
        }
      }
    }

    /// @dev Get the voting power of an address
    /// @param account The address of the account
    function votesOf(address account) public view returns(uint256) {
      return tokensLocked[account].amount;
    }
    
    /// @dev Get the voting power of multiple addresses
    /// @param accounts The addresses of the accounts
    function votesOf(address[] memory accounts) public view virtual returns(uint256[] memory) {
      uint256[] memory votes = new uint256[](accounts.length);
      for (uint i = 0; i < accounts.length; i ++) {
        votes[i] = votesOf(accounts[i]);
      }
      return votes;
    }
    
    /// @dev Get the voting power of an address at a certain snapshotId
    /// @param account The address of the account
    /// @param snapshotId The snapshotId to be used
    function votesOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _votesSnapshots[account]);
        if (snapshotted)
            return value;
        else 
            return votesOf(account);
    }
    
    /// @dev Get the voting power of multiple addresses at a certain snapshotId
    /// @param accounts The addresses of the accounts
    /// @param snapshotIds The snapshotIds to be used
    function votesOfAt(address[] memory accounts, uint256[] memory snapshotIds) public view virtual returns(uint256[] memory) {
        uint256[] memory votes = new uint256[](accounts.length);
        for(uint i = 0; i < accounts.length; i ++)
            votes[i] = votesOfAt(accounts[i], snapshotIds[i]);
        return votes;
    }

    /// @dev Get the total amount of tokes locked at a certain snapshotId
    /// @param snapshotId The snapshotId to be used
    function totalLockedAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalLockedSnapshots);
        if (snapshotted)
            return value;
        else 
            return totalLocked;
    }

    /// @dev Get the information of a proposal
    /// @param proposalId The id of the proposal to get the information
    /// @return creator The address that created the proposal
    /// @return startTime The time at the proposal was created
    /// @return endTime The time at the proposal will end
    /// @return to The receiver addresses of each call to be executed
    /// @return data The data to be executed on each call to be executed
    /// @return value The ETH value to be sent on each call to be executed
    /// @return description A short description of the proposal
    /// @return contentHash The content hash of the content reference of the proposal
    /// @return totalVotes The total votes of the proposal
    /// @return state If the proposal state
    /// @return snapshotId The snapshotId used for the proposal
    function getProposal(bytes32 proposalId) public view virtual returns(
        address creator,
        uint256 startTime,
        uint256 endTime,
        address[] memory to,
        bytes[] memory data,
        uint256[] memory value,
        string memory description,
        bytes memory contentHash,
        uint256 totalVotes,
        ProposalState state,
        uint256 snapshotId
    ) {
        Proposal storage proposal = proposals[proposalId];
        return(
            proposal.creator,
            proposal.startTime,
            proposal.endTime,
            proposal.to,
            proposal.data,
            proposal.value,
            proposal.description,
            proposal.contentHash,
            proposal.totalVotes,
            proposal.state,
            proposal.snapshotId
        );
    }

    /// @dev Get the votes of a voter in a proposal
    /// @param proposalId The id of the proposal to get the information
    /// @param voter The address of the voter to get the votes
    /// @return the votes of the voter for the requested proposal
    function getProposalVotes(bytes32 proposalId, address voter) public view virtual returns(uint256) {
        return(proposals[proposalId].votes[voter]);
    }
    
    /// @dev Get minimum amount of votes needed for creation
    function getVotesForCreation() public view virtual returns (uint256) {
        return votesForCreation;
    }
    
    /// @dev Get minimum amount of votes needed for proposal execution
    function getVotesForExecution() public view virtual returns (uint256) {
        return votesForExecution;
    }
    
    /// @dev Get the first four bytes (function signature) of a bytes variable
    function getFuncSignature(bytes memory data) public view virtual returns (bytes4) {
        bytes32 functionSignature = bytes32(0);
        assembly {
            functionSignature := mload(add(data, 32))
        }
        return bytes4(functionSignature);
    }

    /// @dev Get call signature permission
    function getCallPermission(address to, bytes4 functionSignature) public view virtual returns (bool) {
        return callPermissions[to][functionSignature];
    }
    
    /// @dev Get the length of the proposalIds array
    function getProposalsIdsLength() public view virtual returns (uint256) {
        return proposalsIds.length;
    }
    
    /// @dev Get teh hash of the vote, this hash is later signed by the voter.
    /// @param voter The address that will be used to sign the vote
    /// @param proposalId The id fo the proposal to be voted
    function hashVote(address voter, bytes32 proposalId, uint256 amount) public pure returns(bytes32) {
    /// @param amount The amount of votes to be used
        return keccak256(abi.encodePacked(voter, proposalId, amount));
    }
    
    ///
    /// Private functions used to take track of snapshots in contract storage
    ///
    
    function _valueAt(
      uint256 snapshotId, Snapshots storage snapshots
    ) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Guild: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId, "ERC20Guild: nonexistent id");

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
        _updateSnapshot(_votesSnapshots[account], votesOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalLockedSnapshots, totalLocked);
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId;
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

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title TokenVault
 * @dev A smart contract to lock an ERC20 token in behalf of user trough an intermediary admin contract.
 * User -> Admin Contract -> Token Vault Contract -> Admin Contract -> User.
 * Tokens can be deposited and withdrawal only with authorization of the locker account from the admin address.
 */
contract TokenVault is Initializable{
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable public token;
    address public admin;
    bool public initialized = false;
    mapping(address => uint256) public balances;

  /// @dev Initialized modifier to require the contract to be initialized
    modifier isInitialized() {
        require(initialized, "TokenVault: Not initilized");
        _;
    }

    /// @dev Initializer
    /// @param _token The address of the token to be used
    /// @param _admin The address of the contract that will execute deposits and withdrawals 
    function initialize(address _token, address _admin) initializer public {
        token = IERC20Upgradeable(_token);
        admin = _admin;
        initialized = true;
    }
    
    // @dev Deposit the tokens from the user to the vault from the admin contract
    function deposit(address user, uint256 amount) public isInitialized {
      require(msg.sender == admin);
      token.transferFrom(user, address(this), amount);
      balances[user] = balances[user].add(amount);
    }
    
    // @dev Withdraw the tokens to the user from the vault from the admin contract
    function withdraw(address user, uint256 amount) public isInitialized {
      require(msg.sender == admin);
      token.transfer(user, amount);
      balances[user] = balances[user].sub(amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.6;

library Arrays {
  
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }

  function findUpperBound(uint256[] storage _array, uint256 _element) internal view returns (uint256) {
    uint256 low = 0;
    uint256 high = _array.length;

    while (low < high) {
      uint256 mid = average(low, high);

      if (_array[mid] > _element) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point at `low` is the exclusive upper bound. We will return the inclusive upper bound.

    if (low > 0 && _array[low - 1] == _element) {
      return low - 1;
    } else {
      return low;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}