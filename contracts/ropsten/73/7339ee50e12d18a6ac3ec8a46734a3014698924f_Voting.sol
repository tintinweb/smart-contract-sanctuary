/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity ^0.8.4;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
contract WhitelistedAddresses is Ownable{
    
    //mapping from voter's address to their ID
    mapping (address => uint) public whitelist;
    
    //mapping that keeps track of addresses allowed to propose
    mapping (address => bool) public isProposer;
    
    //number of voters
    uint128 _voters;
    
    //counter for current voter ID
    uint128 counter;
    
    //I LIKE PACKING!!!
    
    constructor(){
        whitelistAddress(msg.sender);
        addProposer(msg.sender);
    }
    
    //Returns whether an address is whitelisted
    function isWhitelisted(address addr) public view returns (bool) {
        return whitelist[addr]!=0;
    }
    
    //Whitelist an address to be able to vote
    function whitelistAddress(address addr) public onlyOwner{
        require(!isWhitelisted(addr), "Already whitelisted");
        counter++;
        _voters++;
        whitelist[addr]=counter;
    }
    
    //Revoke an address from being able to vote
    function removeAddress(address addr) public onlyOwner{
        require(isWhitelisted(addr), "Not whitelisted");
        require(addr != owner()); 
        _voters--;
        whitelist[addr] = 0;
    }
    
    //Returns number of voters
    function numVoters() public view returns (uint){
        return _voters;
    }
    
    //Adds proposer
    function addProposer(address addr) public onlyOwner{
        isProposer[addr]=true;
    }
    
    //REmoves proposer
    function removeProposer(address addr) public onlyOwner{
        isProposer[addr]=false;

    }
    
    modifier onlyProposer{
        require(isProposer[msg.sender]);
        _;
    }
}

contract Voting is Ownable, WhitelistedAddresses{
    
    uint64 public quorum;
    uint64 public timeToVote;
    uint64 public month; 
    uint64 public monthTimelock;  //I like packing 
    // REMEMBER TO CHANGE TO 30 DAYS!!!!!!!!!!!!
    uint constant ONEMONTH = 30 seconds;
    constructor() {
        quorum = 15;
        //REMEMBER TO CHANGE TO 3 DAYS!!!!!!!!
        timeToVote = 30 seconds;
        monthTimelock = uint64(block.timestamp + ONEMONTH);
    }
    
    
    //events for voting and proposing
    event Vote(uint indexed id, bool indexed vote, string indexed reason);
    event Propose(uint indexed id, string indexed proposal);
    
    struct Proposal {
        uint64 timestampEnd; 
        uint64 votesYes; 
        uint64 votesNo; 
        uint56 quorum;
        bool executed; //i like packing 
        address[] toCall;
        bytes[] _calldata;
        string proposal;
    } 
    
    mapping (uint => mapping(uint => uint)) voted;
    
    Proposal[] public proposals;
    
    //Array keeping track of token rewards
    address[] public claimableTokens;
    mapping (address => uint) snapshotBalance;
    
    mapping (address => mapping( uint => uint)) voteCounter;
    mapping (uint => uint) totalVotes;
    
    modifier onlyGovernance{
        require(msg.sender == address(this));
        _;
    }
    
    function addProposal(address[] calldata _callAddress, bytes[] calldata __calldata, string calldata _proposal) external onlyProposer {
        require(_callAddress.length == __calldata.length);
        Proposal memory newProposal;
        newProposal.timestampEnd = uint64(block.timestamp + timeToVote);
        newProposal.quorum = uint56(numVoters()*quorum/100);
        newProposal.toCall = _callAddress;
        newProposal._calldata = __calldata;
        newProposal.proposal = _proposal;
        proposals.push(newProposal);
        emit Propose(proposals.length-1, _proposal);
    }
    
    function vote(uint proposalID, bool voteYes, string calldata reason) external {
        uint voterID = whitelist[msg.sender];
        require(voterID!=0, "Not whitelisted");
        require(!hasVoted(voterID, proposalID), "Already voted");
        require(proposals[proposalID].timestampEnd >= block.timestamp, "Voting over");
        if (voteYes){
            proposals[proposalID].votesYes++;
        }
        else{
            proposals[proposalID].votesNo++;
        }
        setVoted(voterID, proposalID);
        _incrementCounter();
        emit Vote( proposalID, voteYes, reason);
    }
    
    function _incrementCounter() internal {
        uint slot = month % 8;
        uint mask = 1 << (slot*32);
        totalVotes[month/8]+=mask;
        uint slot2 = month % 16;
        uint mask2 = 1 << (slot2 * 16);
        voteCounter[msg.sender][month/16] += mask2;
    }
    
    function getVotesForMonth(uint _month) public view returns (uint){
        uint slot = _month % 8;
        uint mask = (2**32-1) << (slot*32);
        return totalVotes[_month/8] & mask >> (slot*32);
    }
    
    function getAddressVotesForMonth(address addr, uint _month) internal view returns (uint){
        uint slot = _month % 16;
        uint mask = (2**16-1) << (slot*16);
        return voteCounter[addr][_month/16] & mask >> (slot*16);
    }
    
    function setClaimed(address addr, uint _month) internal {
        uint slot = _month % 16;
        uint mask = ~((2**16-1) << (slot*16));
        voteCounter[addr][_month/16] = voteCounter[addr][_month/16] & mask;
    }
    
    function hasVoted(uint voterID, uint proposalID) public view returns(bool){
        uint index = voterID/256;
        uint pos = voterID%256;
        uint mask = 1<<pos;
        return voted[proposalID][index] & mask == mask;
    }
    
    function setVoted(uint voterID, uint proposalID) internal{
        uint index = voterID/256;
        uint pos = voterID%256;
        uint mask = 1<<pos;
        voted[proposalID][index] = voted[proposalID][index] | mask;
    }
    
    function execute(uint proposalID) public{
        Proposal memory proposal = proposals[proposalID];
        require(block.timestamp > proposal.timestampEnd, "Voting not over");
        require(proposal.votesYes > proposal.votesNo , "Yes didn't win");
        require(proposal.votesYes + proposal.votesNo >= proposal.quorum, "Under quorum");
        require(!proposal.executed, "Already executed");
        proposals[proposalID].executed = true;
        for (uint i = 0; i < proposal.toCall.length; i++){
            Address.functionCallWithValue(proposal.toCall[i], proposal._calldata[i], 0, "Execution failed");
        }
    }
    
    function setQuorum(uint64 newQuorum) public onlyGovernance{
        require(newQuorum <= 75);
        quorum = newQuorum;
    }
    
    function setVotingTime(uint64 _timeToVote) public onlyGovernance{
        //REMEMBER TO UNCOMMENT!!!!!!!
        //require(timeToVote <= 1 weeks &&  1 days < timeToVote);
        timeToVote = _timeToVote;
    }
    
    function snapshot() public {
        require (block.timestamp > monthTimelock);
        month++;    
        for (uint i = 0 ; i < claimableTokens.length; i++){
            IERC20 token = IERC20(claimableTokens[i]);
            snapshotBalance[claimableTokens[i]]+=token.balanceOf(address(this));
        }
    }
    
    function addClaimableToken(address addr) public onlyProposer{
        claimableTokens.push(addr);
    }
    
    function removeClaimableToken(uint pos) public onlyGovernance{
        claimableTokens[pos] = address(0);
    }
    
    function claimTokens() public{
        uint currMonth = month-1;
        uint voteCount = getVotesForMonth(currMonth);
        uint myVotes = getAddressVotesForMonth(msg.sender, currMonth);
        setClaimed(msg.sender, currMonth);
        for (uint i = 0; i < claimableTokens.length; i++){
            address tokenAddr = claimableTokens[i];
            if (tokenAddr != address(0)){
            IERC20 token = IERC20(tokenAddr);
            token.transfer(address(this), snapshotBalance[tokenAddr]*myVotes/voteCount);
            }
        }
    }
}