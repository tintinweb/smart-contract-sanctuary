/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.5;
/// @title Baal
/// @notice Maximalized minimalist guild contract inspired by Moloch DAO framework.
contract Baal{
    address[]     guildTokens; // array list of erc20 tokens approved for {ragequit} claims
    address[]     memberList; // array list of `members` summoned or added by `proposals`
    uint   public proposalCount; // counter for total `proposals` submitted
    uint96 public totalLoot; // counter for total loot economic weight held by accounts
    uint   public totalSupply; // counter for total `members` voting shares with erc20 accounting
    uint96        totalSharesAndLoot; // internal counter for total 'loot' and 'shares' in Baal
    uint32 public minVotingPeriod; // minimum period for voting in seconds
    uint32 public maxVotingPeriod; // maximum period for voting in seconds
    uint8  public constant decimals = 18; // unit scaling factor in erc20 shares accounting - '18' is default to match ETH & common erc20s
    string public name; // 'name' for erc20 shares accounting
    string public symbol; // 'symbol' for erc20 shares accounting

    mapping(address => uint)   public balanceOf; // maps `members` accounts to shares with erc20 accounting
    mapping(address => bool)   public minions; // maps contracts approved in 'governance' (1) proposals for {memberAction} that mints or burns shares
    mapping(address => Member) public members; // maps `members` accounts to struct details
    mapping(uint => Proposal)  public proposals; // maps `proposalCount` to struct details
    
    event SummonComplete(address[] minions, address[] guildTokens, address[] summoners, uint96[] loot, uint96[] shares, uint minVotingPeriod, uint maxVotingPeriod, string name, string symbol); // emits after Baal summoning
    event SubmitProposal(address[] to, uint96[] value, uint32 votingPeriod, uint indexed proposal, uint8 indexed flag, bytes[] data, bytes32 details); // emits after proposal submitted
    event SubmitVote(address indexed member, uint balance, uint indexed proposal, uint8 indexed vote); // emits after vote submitted on proposal
    event ProcessProposal(uint indexed proposal); // emits when proposal is processed & executed
    event Transfer(address indexed from, address indexed to, uint amount); // emits when Baal shares are minted or burned with erc20 accounting
    event Ragequit(address indexed memberAddress, address to, uint96 lootToBurn, uint96 sharesToBurn); // emits when callers burn Baal shares and/or loot for a given `to` account
    
    /// @dev Reentrancy guard from OpenZeppelin.
    uint constant _NOT_ENTERED = 1;
    uint constant _ENTERED = 2;
    uint          _status;
    modifier nonReentrant(){
        require(_status != _ENTERED, 'reentrant');
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;}
    
    enum   Vote{Null,Yes,No}
    struct Member{
        bool exists; // tracks `members` account registration for `memberAction()` & `submitProposal()`
        uint96 loot; // amount of loot held by `members` - can be set on summoning & adjusted via {memberAction}
        uint highestIndexYesVote; // highest proposal index # on which the member voted YES
        mapping(uint => Vote) voted;} // maps vote decisions on proposals by `members` account
    struct Proposal{
        uint32 votingEnds; // termination date for proposal in seconds since unix epoch - derived from `votingPeriod`
        uint96 yesVotes; // counter for `members` 'yes' votes to calculate approval on processing
        uint96 noVotes; // counter for `members` 'no' votes to calculate approval on processing
        bool[4] flags; // flags for proposal type & status - [action, governance, membership, passed] 
        address[] to; // account(s) that receives low-level call `data` & ETH `value` - if `membership` flag (2) or `removal` (3), account(s) that will receive or lose `value` shares, respectively
        uint96[] value; // ETH sent from Baal to execute approved proposal low-level call(s)
        bytes[] data; // raw data sent to `target` account for low-level call
        bytes32 details;} // context for proposal - could be IPFS hash, plaintext, or JSON
    
    /// @notice Summon Baal & create initial array of `members` accounts with specific voting weights.
    /// @param _guildTokens Tokens approved for internal accounting - {ragequit} of shares or loot.
    /// @param _minions External contracts approved for {memberAction}.
    /// @param summoners Accounts to add as `members`.
    /// @param loot Economic weight among `members`.
    /// @param shares Voting weight among `members` (shares also have economic weight).
    /// @param _minVotingPeriod Minimum voting period in seconds for `members` to cast votes on proposals.
    /// @param _maxVotingPeriod Maximum voting period in seconds for `members` to cast votes on proposals.
    /// @param _name Name for erc20 shares accounting.
    /// @param _symbol Symbol for erc20 shares accounting.
    constructor(
        address[] memory _minions, 
        address[] memory _guildTokens, 
        address[] memory summoners, 
        uint96[] memory loot, 
        uint96[] memory shares, 
        uint32 _minVotingPeriod, 
        uint32 _maxVotingPeriod, 
        string memory _name, 
        string memory _symbol){
        uint96 initialTotalSharesAndLoot;
        unchecked{for(uint i; i < summoners.length; i++){
            guildTokens.push(_guildTokens[i]); // update array of `guildTokens` approved for {ragequit}
            memberList.push(summoners[i]); // push summoners to `members` array
            balanceOf[summoners[i]] = shares[i]; // add shares to summoning `members` account with erc20 accounting
            totalLoot += loot[i]; // add to total Baal loot
            totalSupply += shares[i]; // add to total Baal shares with erc20 accounting
            minions[_minions[i]] = true; // update mapping of approved `minions` in Baal
            members[summoners[i]].exists = true; // record that summoning `members` `exists`
            members[summoners[i]].loot = loot[i]; // add loot to summoning `members` account
            initialTotalSharesAndLoot += (loot[i] + shares[i]);
            emit Transfer(address(0), summoners[i], shares[i]);}} // event reflects mint of erc20 shares to summoning `members`
        require(initialTotalSharesAndLoot <= (2**96)-1); // set reasonable max limit for Baal loot & shares.
        minVotingPeriod = _minVotingPeriod; // set minimum voting period - adjustable via 'governance' [1] proposal
        maxVotingPeriod = _maxVotingPeriod; // set maximum voting period - adjustable via 'governance' [1] proposal
        name = _name; // set Baal 'name' with erc20 accounting
        symbol = _symbol; // set Baal 'symbol' with erc20 accounting
        _status = _NOT_ENTERED; // set reentrancy guard status
        emit SummonComplete(_minions, _guildTokens, summoners, loot, shares, _minVotingPeriod, _maxVotingPeriod, _name, _symbol);} // emit event reflecting Baal summoning completed

    /// @notice Execute membership action to mint or burn shares or loot against whitelisted `minions` in consideration of `msg.sender` & given `amount`.
    /// @param extension Whitelisted contract to trigger action.
    /// @param loot Loot involved in external call.
    /// @param shares Shares involved in external call.
    /// @param mint Confirm whether action involves shares or loot request - if `false`, perform burn.
    function memberAction(address extension, uint loot, uint shares, bool mint)external nonReentrant payable returns(uint96 lootReaction, uint96 sharesReaction){
        require(minions[address(extension)], '!extension'); // check `extension` is approved
        if(mint){
            (, bytes memory reactionData) = extension.call{value: msg.value}(abi.encodeWithSelector(0xff4c9884, msg.sender, loot, shares)); //  fetch 'reaction' mint per inputs
            (lootReaction, sharesReaction) = abi.decode(reactionData, (uint96, uint96));
            if (!members[msg.sender].exists) memberList.push(msg.sender); // update membership list if new
            balanceOf[msg.sender] += sharesReaction; // add shares to `msg.sender` account with erc20 accounting
            totalLoot += lootReaction; // add to total Baal loot 
            totalSupply += sharesReaction; // add to total Baal shares with erc20 accounting
            emit Transfer(address(0), msg.sender, sharesReaction); // event reflects mint of shares or loot with erc20 accounting
        }else{
            (, bytes memory reactionData) = extension.call{value: msg.value}(abi.encodeWithSelector(0xff4c9884, msg.sender, loot, shares)); // fetch 'reaction' burn per inputs
            (lootReaction, sharesReaction) = abi.decode(reactionData, (uint96, uint96));
            balanceOf[msg.sender] -= sharesReaction; // subtract shares from member account with erc20 accounting
            totalLoot -= lootReaction; // subtract from total Baal loot
            totalSupply -= sharesReaction; // subtract from total Baal shares with erc20 accounting
            emit Transfer(msg.sender, address(0), sharesReaction);}} // event reflects burn of shares or loot with erc20 accounting
    
    /*****************
    PROPOSAL FUNCTIONS
    *****************/
    /// @notice Submit proposal to Baal `members` for approval within voting period - proposer must be registered member.
    /// @param to Account that receives low-level call `data` & ETH `value` - if `membership` flag (2), the account that will receive `value` shares - if `removal` (3), the account that will lose `value` shares.
    /// @param value ETH sent from Baal to execute approved proposal low-level call.
    /// @param data Raw data sent to `target` account for low-level call.
    /// @param details Context for proposal - could be IPFS hash, plaintext, or JSON.
    function submitProposal(address[] calldata to, uint96[] calldata value, uint32 votingPeriod, uint8 flag, bytes[] calldata data, bytes32 details)external nonReentrant returns (uint proposal){
        require(votingPeriod >= minVotingPeriod && votingPeriod <= maxVotingPeriod, '!votingPeriod');
        require(to.length == value.length && value.length == data.length, '!arrays');
        require(to.length <= 10, 'array max'); // limit executable actions to help avoid block gas limit errors on processing
        require(flag <= 5, '!flag'); // check flag is in bounds
        bool[4] memory flags; // plant flags - [action, governance, membership, passed]
        flags[flag] = true; // flag proposal type for struct storage 
        proposalCount++; // increment total proposal counter
        unchecked{proposals[proposalCount] = Proposal(uint32(block.timestamp) + votingPeriod, 0, 0, flags, to, value, data, details);} // push params into proposal struct - start voting period timer
        emit SubmitProposal(to, value, votingPeriod, proposal, flag, data, details);}
    
    /// @notice Submit vote - proposal must exist & voting period must not have ended - non-member can cast `0` vote to signal.
    /// @param proposal Number of proposal in `proposals` mapping to cast vote on.
    /// @param uintVote If '1', member will cast `yesVotes` onto proposal - if '2', `noVotes` will be counted.
    function submitVote(uint proposal, uint8 uintVote)external nonReentrant{
        Proposal storage prop = proposals[proposal]; // alias proposal storage pointers
        Vote vote = Vote(uintVote); // alias uintVote
        uint balance = balanceOf[msg.sender]; // gas-optimize variable
        require(prop.votingEnds >= block.timestamp, 'ended'); // check voting period has not ended
        if(vote == Vote.Yes){prop.yesVotes += uint96(balance);} // cast 'yes' votes per member balance to proposal
        if(vote == Vote.No){prop.noVotes += uint96(balance);} // cast 'no' votes per member balance to proposal
        members[msg.sender].voted[proposal] = vote; // record vote to member struct per account
        emit SubmitVote(msg.sender, balance, proposal, uintVote);}
        
    // ********************
    // PROCESSING FUNCTIONS
    // ********************
    /// @notice Process 'proposal' & execute internal functions based on 'flag'.
    /// @param proposal Number of proposal in `proposals` mapping to process for execution.
    function processProposal(uint proposal)external nonReentrant{
        Proposal storage prop = proposals[proposal]; // alias `proposal` storage pointers
        processingReady(proposal, prop); // validate `proposal` processing requirements
        if(prop.yesVotes > prop.noVotes) { // check if `proposal` approved by simple majority of members
            if(prop.flags[0]){processActionProposal(prop); // check 'flag', execute 'action'
        }else if(prop.flags[1]){processGovernanceProposal(prop); // check 'flag', execute 'governance'
        }else{processMemberProposal(prop);}} // otherwise, execute 'membership'
        delete proposals[proposal]; // delete given proposal struct details for gas refund & the commons
        emit ProcessProposal(proposal);} // emit event reflecting proposal processed
    
    /// @notice Process 'action' proposal [0] & execute low-level call(s).
    function processActionProposal(Proposal memory prop)private{
        unchecked{for(uint i; i < prop.to.length; i++) {prop.to[i].call{value:prop.value[i]}(prop.data[i]);}}} // execute low-level call(s)
    
    /// @notice Process 'governance' [1] proposal.
    function processGovernanceProposal(Proposal memory prop)private{
        unchecked{for(uint i; i < prop.to.length; i++) 
                    if(prop.value[i] != 0){minions[prop.to[i]] = true; // check `value` to toggle between approving or removing 'minion' extension
                    }else{minions[prop.to[i]] = false;}} // remove 'extension'
        if(prop.value[0] > 0) maxVotingPeriod = uint32(prop.value[0]);} // reset voting period to first `value`
    
    /// @notice Process 'membership' [2] proposal (2).
    function processMemberProposal(Proposal memory prop)private{
        unchecked{for(uint i; i < prop.to.length; i++){
                    if(prop.data.length == 0){
                        if(!members[prop.to[i]].exists) memberList.push(prop.to[i]); // update membership list if new
                        totalSupply += prop.value[i]; // add to total member votes
                        balanceOf[prop.to[i]] += prop.value[i]; // add to `target` member votes
                        emit Transfer(address(0), prop.to[i], prop.value[i]); // event reflects mint of erc20 votes
                    }else{
                        totalSupply -= prop.value[i]; // subtract `balance` from total member votes
                        balanceOf[prop.to[i]] -= prop.value[i]; // subtract member votes
                        emit Transfer(prop.to[i], address(0), prop.value[i]);}}}} // event reflects burn of erc20 votes

    /// @notice Process member 'ragequit'.
    /// @param lootToBurn Baal pure economic weight to burn to claim 'fair share' of `guildTokens`.
    /// @param sharesToBurn Baal voting weight to burn to claim 'fair share' of `guildTokens`.
    /// @return successes Logs transfer results of claimed `guildTokens`.
    function ragequit(address to, uint96 lootToBurn, uint96 sharesToBurn)external nonReentrant returns (bool[] memory successes){
        require(members[msg.sender].highestIndexYesVote < proposalCount, 'highestIndexYesVote !processed'); // highest index proposal member voted YES on must process first
        unchecked{uint sharesAndLootToBurn = lootToBurn + sharesToBurn;
        for(uint i; i < guildTokens.length; i++) {
            (, bytes memory balanceData) = guildTokens[i].staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
            uint balance = abi.decode(balanceData, (uint));
            uint amountToRagequit = (sharesAndLootToBurn * balance) / totalSupply;
            if(amountToRagequit != 0) { // gas optimization to allow higher maximum token limit
                (bool success, ) = guildTokens[i].call(abi.encodeWithSelector(0xa9059cbb, to, amountToRagequit)); successes[i] = success;}}}
        if(lootToBurn != 0) 
            members[msg.sender].loot -= lootToBurn; // subtract loot from caller account
            totalLoot -= lootToBurn; // subtract from total Baal loot
        if(sharesToBurn != 0)
            balanceOf[msg.sender] -= sharesToBurn; // subtract shares from caller account with erc20 accounting
            totalSupply -= sharesToBurn; // subtract from total Baal shares with erc20 accounting
        emit Ragequit(msg.sender, to, lootToBurn, sharesToBurn);}
    
    /***************
    GETTER FUNCTIONS
    ***************/
    /// @notice Returns array list of approved `guildTokens` in Baal for `members` {ragequit}.
    function getGuildTokens()external view returns(address[] memory tokens){tokens = guildTokens;}

    /// @notice Returns array list of registered `members` accounts in Baal.
    function getMemberList()external view returns(address[] memory membership){membership = memberList;}
    
    /// @notice Returns <uint8> 'vote' by a given `voter` account on Baal `proposal`.
    function getProposalVoteByVoter(address voter, uint proposal)external view returns(Vote vote){vote = members[voter].voted[proposal];}

    /// @notice Returns 'flags' for given Baal `proposal` describing type ('action' [0], 'governance' [1], 'membership' [2]).
    function getProposalFlags(uint proposal)external view returns(bool[4] memory flags){flags = proposals[proposal].flags;}
    
    /***************
    HELPER FUNCTIONS
    ***************/
    /// @notice Deposits ETH sent to Baal.
    receive()external payable{}

    /// @dev Internal checks to validate basic proposal processing requirements. 
    function processingReady(uint proposal, Proposal memory prop)private view returns (bool ready){
        require(proposal <= proposalCount, '!exist'); // check proposal exists
        if(proposal != 0) require(proposals[proposal - 1].votingEnds == 0, 'prev. !processed'); // check previous proposal has processed by deletion
        require(!prop.flags[3], 'processed'); // check given proposal has not yet processed
        if(memberList.length == 1){ready = true; // if single membership, process early
        }else if(prop.yesVotes > totalSupply / 2){ready = true; // process early if majority member support
        }else if(prop.votingEnds >= block.timestamp){ready = true;}} // otherwise, process if voting period done
}