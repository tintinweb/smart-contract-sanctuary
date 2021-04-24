/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity ^0.8.4;
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
    mapping (address => uint) public whitelist;
    mapping (address => bool) public isProposer;
    uint _voters;
    uint private counter;
    
    constructor(){
        whitelistAddress(msg.sender);
        addProposer(msg.sender);
    }
    
    
    function isWhitelisted(address addr) public view returns (bool) {
        return whitelist[addr]!=0;
    }
    function whitelistAddress(address addr) public onlyOwner{
        require(!isWhitelisted(addr), "Already whitelisted");
        counter++;
        _voters++;
        whitelist[addr]=counter;
    }
    function removeAddress(address addr) public onlyOwner{
        require(isWhitelisted(addr), "Not whitelisted");
        require(addr != owner()); //nice try but you can't vote multiple times by adding and removing yourself
        _voters--;
        whitelist[addr] = 0;
    }
    function numVoters() public view returns (uint){
        return _voters;
    }
    function addProposer(address addr) public onlyOwner{
        isProposer[addr]=true;
    }
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
    
    constructor() {
        quorum = 15;
        //REMEMBER TO CHANGE TO 3 DAYS!!!!!!!!
        timeToVote = 30 seconds;
    }
    
    
    //events for voting and proposing
    event Vote(uint indexed id, bool indexed vote, string indexed reason);
    event Propose(uint indexed id, string indexed proposal);
    
    
    struct Proposal {
        uint64 timestampEnd; 
        uint64 votesYes; 
        uint64 votesNo; 
        uint64 quorum; //slot 1
        address toCall;
        uint88 value; 
        bool executed; //slot 2
        bytes _calldata;
        string proposal;
    } 
    mapping (uint => mapping(uint => uint)) voted;
    
    Proposal[] public proposals;
    
    function addProposal(address _callAddress, bytes calldata __calldata, uint88 _value, string calldata _proposal) public onlyProposer {
        Proposal memory newProposal;
        newProposal.timestampEnd = uint64(block.timestamp + timeToVote);
        newProposal.quorum = uint64(numVoters()*quorum/100);
        newProposal.toCall = _callAddress;
        newProposal._calldata = __calldata;
        newProposal.proposal = _proposal;
        newProposal.value = _value; 
        proposals.push(newProposal);
        emit Propose(proposals.length-1, _proposal);
    }
    
    function vote(uint proposalID, bool voteYes, string calldata reason) public {
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
        emit Vote( proposalID, voteYes, reason);
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
        
        Address.functionCallWithValue(proposal.toCall, proposal._calldata, proposal.value);
        
        proposals[proposalID].executed = true;
    }
    
    function setQuorum(uint64 newQuorum) public{
        require(msg.sender == address(this));
        require(newQuorum <= 75);
        quorum = newQuorum;
    }
    
    function setVotingTime(uint64 _timeToVote) public{
        require(msg.sender == address(this));
        
        //REMEMBER TO UNCOMMENT!!!!!!!
        //require(timeToVote <= 1 weeks &&  1 days < timeToVote);
        timeToVote = _timeToVote;
    }
    
    fallback() external payable{}
    receive() external payable{}
}