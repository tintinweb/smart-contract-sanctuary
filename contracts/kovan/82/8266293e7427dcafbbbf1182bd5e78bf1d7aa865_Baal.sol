/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/// @notice Interface for Baal membership & banking minions.
interface IBaalBank {
    function balanceOf(address account) external view returns (uint); // erc20 token helper for balance checks
    function memberAction(address account, uint amount) external payable returns (uint); // execute membership action to mint or burn votes via whitelisted minions
}

// ["0x11cb374beee797dbbb4c848195bf24d7085acd68"],["0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20"],["0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20"],["1"],"25","60","Baal","B"

/// @title Baal
/// @notice Maximalized minimalist guild contract inspired by Moloch DAO framework.
contract Baal {
    address[] guildTokens; // array list of erc20 tokens approved for {ragequit}
    address[] memberList; // array list of {members} summoned or added by proposal
    uint public proposalCount = proposals.length; // counter for proposals submitted
    uint public totalSupply; // counter for {members} votes minted with erc20 accounting
    uint public minVotingPeriod; // min. period for voting in seconds
    uint public maxVotingPeriod; // max. period for voting in seconds
    uint8 constant public decimals = 18; // token 'decimals' unit scaling factor for erc20 vote accounting - '18' is default to match ETH & most erc20 units
    string public name; // token 'name' for erc20 vote accounting
    string public symbol; // token 'symbol' for erc20 vote accounting
    bytes4 constant SIG_TRANSFER = 0xa9059cbb; // erc20 function signature for simple 'safeTransfer' - 'transfer(address,uint)''
    bytes4 constant SIG_TRANSFER_FROM = 0x23b872dd; // erc20 function signature for simple 'safeTransferFrom' - 'transferFrom(address,address,uint)'
    Proposal[] public proposals; // array list of Baal proposal structs per order proposed
    
    mapping(address => uint) public balanceOf; // maps {members} accounts to votes with erc20 accounting
    mapping(address => bool) public minions; // maps [IBaalBank] accounts approved in summoning or 'whitelist' (3) proposal for {memberAction} that burns or mints votes
    mapping(address => uint) public participation; // maps {members} accounts to vote details
    mapping(address => Member) public members; // maps {members} accounts to struct details
    
    event SummonComplete(address[] guildTokens, address[] minions, address[] summoners, uint[] votes, uint minVotingPeriod, uint maxVotingPeriod, string name, string symbol); // emits after Baal is summoned into the ether
    event SubmitProposal(address[] to, uint[] value, uint votingLength, uint indexed proposal, uint8 indexed flag, bytes[] data, bytes32 details); // emits after proposal is submitted
    event SubmitVote(address indexed member, uint balance, uint indexed proposal, uint8 indexed vote); // emits after vote on proposal is submitted
    event ProcessProposal(uint indexed proposal, bool passed); // emits after proposal is processed & executed & flags whether passed
    event Transfer(address indexed from, address indexed to, uint amount); // emits after {members} votes are minted or burned with erc20 accounting
    event Ragequit(address indexed memberAddress, address indexed to, uint sharesToBurn); // emits after {members} burn votes or loot to claim fair share of {guildTokens}
    
    /// @dev Reentrancy guard.
    uint unlocked = 2;
    modifier lock() {
        require(unlocked == 2, 'Baal::locked');
        unlocked = 1;
        _;
        unlocked = 2;
    }
    
    enum Vote {
        Null, // default vote value - counted as abstention
        Yes, // vote to approve proposal
        No // vote to revoke proposal
    }
    
    struct Member {
        uint id; // tracks registration # & {memberList} array position
        bool exists; // tracks registration status ('good standing') - revokeable by membership (1) proposal
        uint highestIndexYesVote; // highest proposal index # on which the member voted YES - used as {ragequit} check
        mapping(uint => mapping(uint => uint8)) voted; // maps votes on proposals by {members} - gets votes cast & whether approved
    }
    
    struct Proposal {
        address[] to; // if 'action' (0), receive(s) low-level call(s) `data` & ETH `value` - if `membership` (1), receive(s) `value` votes or revocation - if (3) whitelist, [IBaalBank] or {guildTokens} accounts for approval or revocation 
        uint[] value; // if 'action' (0), ETH for approved proposal low-level call(s) - if `membership` (1), vote weight granted to {members}
        uint yesVotes; // counter for `members` 'yes' votes to calculate approval on processing
        uint noVotes; // counter for `members` 'no' votes to calculate approval on processing
        uint votingEnds; // termination date for proposal in seconds since unix epoch - derived from `votingPeriod`
        bytes[] data; // raw data sent to `target` account for low-level call
        bool[4] flags; // flags for proposal type & status - [action, member, period, whitelist] 
        bytes32 details; // context for proposal - could be IPFS hash, plaintext, or JSON
    }
    
    /// @notice Deploy Baal & initialize array of `members` with ragequittable voting weights.
    /// @param _guildTokens Tokens approved for internal accounting - `ragequit()` of votes.
    /// @param _minions External contracts approved for `memberAction()`.
    /// @param summoners Accounts to add as `members`.
    /// @param votes Voting weights among `members`.
    /// @param _minVotingPeriod Minimum voting period in seconds for `members` to cast votes on proposals.
    /// @param _maxVotingPeriod Maximum voting period in seconds for `members` to cast votes on proposals.
    /// @param _name Name for erc20 vote accounting.
    /// @param _symbol Symbol for erc20 vote accounting.
    constructor(address[] memory _guildTokens, address[] memory _minions, address[] memory summoners, uint[] memory votes, uint _minVotingPeriod, uint _maxVotingPeriod, string memory _name, string memory _symbol) {
        for (uint i = 0; i < summoners.length; i++) {
             require(summoners.length == votes.length,'Baal:arrays must match');
             guildTokens.push(_guildTokens[i]); // initialize array of whitelisted `guildTokens` for `ragequit()`
             memberList.push(summoners[i]); // initialize array of `members`
             totalSupply += votes[i]; // increment total votes with erc20 accounting
             balanceOf[summoners[i]] = votes[i]; // initialize vote weights to summoning `members` with erc20 accounting
             minions[_minions[i]] = true; // initialize mapping of approved `minions`
             members[summoners[i]].exists = true; // record that summoning `members` `exists`
             emit Transfer(address(0), summoners[i], votes[i]); // event reflects mint of erc20 votes to summoning `members`
        }
        minVotingPeriod = _minVotingPeriod; // set minumum voting period for proposals
        maxVotingPeriod = _maxVotingPeriod; // set minumum voting period for proposals
        name = _name; // set Baal 'name' with erc20 accounting
        symbol = _symbol; // set Baal 'symbol' with erc20 accounting
        emit SummonComplete(_guildTokens, _minions, summoners, votes, _minVotingPeriod, _maxVotingPeriod, _name, _symbol);
    }
    
    /// @notice Execute membership action to mint or burn votes against whitelisted `minions` in consideration of `msg.sender` & given `amount`.
    /// @param minion Whitelisted contract to trigger action.
    /// @param amount Number to submit in action - e.g., votes to mint for tribute or to burn in asset claim.
    /// @param mint Confirm whether action involves vote request - if `false`, perform burn.
    /// @return reaction Output number for vote mint or burn based on minion logic.
    function memberAction(IBaalBank minion, uint amount, bool mint) external lock payable returns (uint reaction) {
        require(minions[address(minion)], 'Baal::!minion'); // check `minion` is approved
        if (mint) {
            reaction = minion.memberAction{value: msg.value}(msg.sender, amount); // mint per `msg.sender`, `amount` & `msg.value`
            if (!members[msg.sender].exists) memberList.push(msg.sender); // update membership list if new
            totalSupply += reaction; // add to total `members`' votes with erc20 accounting
            balanceOf[msg.sender] += reaction; // add votes to member account with erc20 accounting
            emit Transfer(address(0), msg.sender, reaction); // event reflects mint of votes with erc20 accounting
        } else {
            reaction = minion.memberAction{value: msg.value}(msg.sender, amount); // burn per `msg.sender`, `amount` & `msg.value`
            totalSupply -= reaction; // subtract from total `members`' votes with erc20 accounting
            balanceOf[msg.sender] -= reaction; // subtract votes from member account with erc20 accounting
            emit Transfer(msg.sender, address(0), reaction); // event reflects burn of votes with erc20 accounting
        }
    }
    
    /*****************
    PROPOSAL FUNCTIONS
    *****************/
    /// @notice Submit proposal to Baal `members` for approval within voting period - proposer must be registered member.
    /// @param to Account that receives low-level call `data` & ETH `value` - if `membership` flag (2), the account that will receive `value` votes - if `removal` (3), the account that will lose `value` votes.
    /// @param value ETH sent from Baal to execute approved proposal low-level call.
    /// @param data Raw data sent to `target` account for low-level call.
    /// @param details Context for proposal.
    /// @return proposal Id for proposal from count.
    function submitProposal(address[] calldata to, uint[] calldata value, uint votingLength, uint8 flag, bytes[] calldata data, bytes32 details) external lock returns (uint proposal) {
        require(to.length == value.length && value.length == data.length,'Baal:arrays must match');
        require(votingLength >= minVotingPeriod && votingLength <= maxVotingPeriod, 'Baal::period out of bounds');
        require(flag <= 6, 'Baal::!flag'); // check flag is not out of bounds
        bool[4] memory flags; // stage flags - [action, member, period, whitelist]
        flags[flag] = true; // flag proposal type 
        proposals.push(Proposal(to, value, 0, 0, block.timestamp + votingLength, data, flags, details)); // push params into proposal struct - start vote timer
        emit SubmitProposal(to, value, votingLength, proposal, flag, data, details);
    }
    
    /// @notice Submit vote - proposal must exist & voting period must not have ended - non-member can cast `0` vote to signal.
    /// @param proposal Number of proposal in `proposals` mapping to cast vote on.
    /// @param uintVote If '1', member will cast `yesVotes` onto proposal - if '2', `noVotes` will be counted.
    function submitVote(uint proposal, uint8 uintVote) external lock {
        Proposal storage prop = proposals[proposal];
        require(prop.votingEnds >= block.timestamp, 'Baal::ended'); // check voting period has not ended
        Vote vote = Vote(uintVote);
        uint balance = balanceOf[msg.sender]; // gas-optimize variable
        if (vote == Vote.Yes) {prop.yesVotes += balance;} // cast 'yes' votes per member balance to proposal
        if (vote == Vote.No) {prop.noVotes += balance;} // cast 'no' votes per member balance to proposal
        members[msg.sender].voted[proposal][balance] = uintVote; // record vote to member struct per account
        emit SubmitVote(msg.sender, balance, proposal, uintVote);
    }
    
    // ********************
    // PROCESSING FUNCTIONS
    // ********************
    /// @notice Process 'action' proposal (0) & execute low-level call(s) - proposal must be counted, unprocessed & in voting period.
    /// @param proposal Number of proposal in {proposals} array to process for execution.
    /// @return passed results Array of return data from low-level calls.
    function processActionProposal(uint proposal) external lock returns (bool passed, bytes[] memory results) {
        Proposal storage prop = proposals[proposal];
        processingReady(proposal, prop); // validate processing requirements
        require(prop.flags[0], 'Baal::!action'); // check proposal type
        if (passed = prop.yesVotes > prop.noVotes)  // check if proposal approved
            for (uint i = 0; i < prop.to.length; i++)
                (, results[i]) = prop.to[i].call{value:prop.value[i]}(prop.data[i]); // execute low-level call(s)
         delete proposals[proposal]; // gas refund
         emit ProcessProposal(proposal, passed);
    }
    
    /// @notice Process 'membership' proposal (2) - proposal must be counted, unprocessed & in voting period.
    /// @param proposal Number of proposal in {proposals} array to process for execution.
    function processMemberProposal(uint proposal) external lock returns (bool passed) {
        Proposal storage prop = proposals[proposal];
        processingReady(proposal, prop); // validate processing requirements
        require(prop.flags[1], 'Baal::!member'); // check proposal type
        if (passed = prop.yesVotes > prop.noVotes)  // check if proposal approved
            for (uint i = 0; i < prop.to.length; i++) 
                if (prop.data[i].length == 0) {
                    if (!members[prop.to[i]].exists) // update membership if new
                        members[prop.to[i]].id = memberList.length; // id set to current member list length to help array accounting
                        memberList.push(prop.to[i]); // update member list array
                        members[prop.to[i]].exists = true; // initiate into membership
                    totalSupply += prop.value[i]; // add to total member votes
                    balanceOf[prop.to[i]] += prop.value[i]; // add to `target` member votes
                    emit Transfer(address(0), prop.to[i], prop.value[i]); // event reflects mint of erc20 votes 
                } else {
                    memberList[members[prop.to[i]].id] = memberList[memberList.length-1]; // swap list position with last member
                    memberList.pop(); // trim member list array
                    members[prop.to[i]].exists = false; // revoke membership
                    totalSupply -= balanceOf[prop.to[i]]; // subtract burn `balance` from total member votes
                    balanceOf[prop.to[i]] = 0; // revoke `target` member votes
                    emit Transfer(prop.to[i], address(0), prop.value[i]);} // event reflects burn of erc20 votes
        delete proposals[proposal]; // gas refund
        emit ProcessProposal(proposal, passed);
    }
    
    /// @notice Process 'period' proposal (2) - proposal must be counted, unprocessed & in voting period.
    /// @param proposal Number of proposal in {proposals} array to process for execution.
    function processPeriodProposal(uint proposal) external lock returns (bool passed) {
        Proposal storage prop = proposals[proposal];
        processingReady(proposal, prop); // validate processing requirements
        require(prop.flags[2], 'Baal::!governance'); // check proposal type
        if (passed = prop.yesVotes > prop.noVotes)  // check if proposal approved
            minVotingPeriod = prop.value[0]; // reset min. voting period to first `value`
            maxVotingPeriod = prop.value[1]; // reset max. voting period to second `value`
        delete proposals[proposal]; // gas refund
        emit ProcessProposal(proposal, passed);
    }
    
    /// @notice Process 'whitelist' proposal (3) - proposal must be counted, unprocessed & in voting period.
    /// @param proposal Number of proposal in {proposals} array to process for execution.
    function processWhitelistProposal(uint proposal) external lock returns (bool passed) {
        Proposal storage prop = proposals[proposal];
        processingReady(proposal, prop); // validate processing requirements
        require(prop.flags[3], 'Baal::!governance'); // check proposal type
        if (passed = prop.yesVotes > prop.noVotes)  // check if proposal approved
            for (uint i = 0; i < prop.to.length; i++) 
                if (prop.data[i].length == 0) // check `data` length to toggle between `minion` & {guildTokens} sub-type
                    if (prop.value[i] == 0) { // check `value` to toggle between approving or removing 'minion'
                        minions[prop.to[i]] = true;} else {minions[prop.to[i]] = false; // execute approve or remove
                } else {
                    if (prop.data[i].length == 1) { // check `data` is '1' length to toggle between approving or removing 'guildTokens'
                        guildTokens.push(prop.to[i]);} else {guildTokens[prop.value[i]] = guildTokens[guildTokens.length-1]; guildTokens.pop();}} // execute approve or remove
        delete proposals[proposal]; // gas refund
        emit ProcessProposal(proposal, passed);
    }
    
    /// @notice Process member burn of votes and/or loot.
    /// @param votes Baal membership weight to burn for transfer of 'fair share' of {guildTokens}.
    function ragequit(address to, uint votes) external {
        require(members[msg.sender].highestIndexYesVote < proposals.length, 'Baal::highestIndexYesVote !processed');
        for (uint i = 0; i < guildTokens.length; i++) {
            uint amountToRagequit = votes * (IBaalBank(guildTokens[i]).balanceOf(address(this)) / totalSupply); // compute fair share
            if (amountToRagequit != 0) { // gas optimization to allow a higher maximum token limit
                (bool success, bytes memory data) = guildTokens[i].call(abi.encodeWithSelector(SIG_TRANSFER, to, amountToRagequit)); // transfer tokens
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'Baal::transfer failed');}} // check for safe transfer
        balanceOf[msg.sender] -= votes; // burn member votes
        totalSupply -= votes; // subtract burn from total member votes
        emit Ragequit(msg.sender, to, votes); // event reflects claim & assignment of assets
        emit Transfer(msg.sender, address(0), votes); // event reflects burn of erc20 votes
    }
    
    /***************
    GETTER FUNCTIONS
    ***************/
    /// @notice Returns array list of approved guild tokens in Baal for member exits.
    function getGuildTokens() external view returns (address[] memory tokens) {
        tokens = guildTokens;
    }

    /// @notice Returns array list of member accounts in Baal.
    function getMemberList() external view returns (address[] memory membership) {
        membership = memberList;
    }
    
    /// @notice Returns member accounts listed in Baal per `id` #s.
    function getMembersById(uint[] calldata id) external view returns (address[] memory listed) {
        for (uint i = 0; i < id.length; i++) listed[i] = memberList[id[i]];
    }

    /// @notice Returns flags for proposal type & status in Baal.
    function getProposalFlags(uint proposal) external view returns (bool[4] memory flags) {
        flags = proposals[proposal].flags;
    }
    
    /***************
    HELPER FUNCTIONS
    ***************/
    /// @notice Fallback that deposits ETH sent to Baal.
    receive() external payable {}

    /// @dev Internal check for proposal processing requirements.
    function processingReady(uint proposal, Proposal memory prop) private view returns (bool ready) {
        require(prop.votingEnds != 0, 'Baal::!exist'); // check proposal exists & has not been processed through deletion
        require(proposals[proposal-1].votingEnds == 0, 'Baal::prev. !processed'); // check previous proposal has processed
        if (memberList.length == 1) 
            ready = true; // if single member, process early
         else if (prop.yesVotes > totalSupply / 2)  
            ready = true; // process early if simple majority approved
         else if (prop.votingEnds >= block.timestamp) 
            ready = true; // otherwise, process if voting period ended
    }
}