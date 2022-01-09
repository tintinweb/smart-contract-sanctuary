/**
 *Submitted for verification at polygonscan.com on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/** Deployment Steps:
  *     1.
  *     2.
  *     3.
  *
  * Upgrade Steps:
  *     1.
  *     2.
  *     3.
  **/

//ERC20 Interface
interface IERC20 {
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

//wLiti DAO contract implementation v1
contract wLitiDAO is Ownable {

    /***************************************************/
    // Events
    /***************************************************/

    event SubmitProposal(

        address indexed proposer,
        uint256 indexed index,
        string title,
        uint256 expireTime,
        address indexed to,
        uint256 value,
        bytes data

    );
    event Vote(address indexed owner, uint256 indexed index);
    event VoteRemoved(address indexed owner, uint256 indexed index);
    event VotesRemoved(address indexed owner);
    event ExecuteProposal(address indexed owner, uint256 indexed index);
    event LockedDAO();
    event UnlockedDAO();
    event Upgraded(address indexed cAddress);

    /***************************************************/
    // Variables
    /***************************************************/

    struct TransactionProposal {

        address proposer;
        string title;
        uint256 expireTime;
        uint256 earliestExecutionTime;
        uint256 numVotes;
        address to;
        uint256 value;
        bytes data;
        bool executed;

    }

    TransactionProposal[] public _proposals;
    mapping(uint256 => mapping(address => bool)) public voted;
    mapping (address => uint256[]) public votedFor;

    IERC20 private _wLitiToken;
    IERC20 private _daoToken;
    address private _partnerAddress;
    address private _newContract;

    bool private _contractLocked = false;
    bool private _contractUpgraded = false;

    uint256 private _votingDuration = 30 minutes;
    uint256 private _minimumVotingTime = 5 minutes;

    /***************************************************/
    // Modifiers
    /***************************************************/

    modifier onlyDAO() {
        require(msg.sender == address(this), "not DAO");
        _;
    }

    modifier onlyDAOMember() {
        require(_daoToken.balanceOf(msg.sender) > 0, "not DAO member");
        _;
    }

    modifier proposalExists(uint _index) {
        require(_index < _proposals.length, "proposal does not exist");
        _;
    }

    modifier proposalNotExecuted(uint _index) {
        require(!_proposals[_index].executed, "proposal executed");
        _;
    }

    modifier notVotedForProposal(uint _index) {
        require(!voted[_index][msg.sender], "proposal voted for");
        _;
    }

    modifier votedForProposal(uint _index) {
        require(voted[_index][msg.sender], "proposal not voted for");
        _;
    }

    modifier contractLocked() {
        require(_contractLocked, "not locked");
        _;
    }

    modifier notContractLocked() {
        require(!_contractLocked, "locked");
        _;
    }

    modifier notContractUpgraded() {
        require(!_contractUpgraded, "upgraded");
        _;
    }

    modifier contractUpgraded() {
        require(_contractUpgraded, "not upgraded");
        _;
    }

    /***************************************************/
    // Constructors
    /***************************************************/

    constructor (address wLitiAddress, address partnerAddress) {

        _wLitiToken = IERC20(wLitiAddress);
        _partnerAddress = partnerAddress;

    }

    /***************************************************/
    // Only Owner Functions
    /***************************************************/

    //If an address is currently voting, then add the amount of tokens that were deposited to the proposals that they have already voted for
    function onDeposit(address a, uint256 amount) public onlyOwner notContractLocked {

        if(votedFor[a].length > 0) {

            for (uint256 i = 0; i < votedFor[a].length; i++) {

                if(!_proposals[votedFor[a][i]].executed)
                    _proposals[votedFor[a][i]].numVotes += amount;

            }

        }

    }

    //Withdraw wLiti tokens from this contract
    function onWithdraw(address a, uint256 amount) public onlyOwner notContractLocked {

        _wLitiToken.transfer(a, amount);

    }

    //Set the address of the DAO governance token contract
    function setDAOTokenAddress(address a) public onlyOwner {

        _daoToken = IERC20(a);

    }

    /***************************************************/
    // Only DAO Member Functions
    /***************************************************/

    //Submit a transaction proposal to be voted on by the DAO members
    function submitProposal(string memory _title, address _to, uint256 _value, bytes memory _data) public onlyDAOMember {

        uint256 index = _proposals.length;

        _proposals.push(
            TransactionProposal({
                proposer: msg.sender,
                title: _title,
                expireTime: block.timestamp + _votingDuration,
                earliestExecutionTime: block.timestamp + _minimumVotingTime,
                numVotes: 0,
                to: _to,
                value: _value,
                data: _data,
                executed: false
            })
        );

        emit SubmitProposal(msg.sender, index, _title, block.timestamp + _votingDuration, _to, _value, _data);

    }

    //Vote for a proposal
    function vote(uint _index) public onlyDAOMember proposalExists(_index) proposalNotExecuted(_index) notVotedForProposal(_index) {

        TransactionProposal storage transaction = _proposals[_index];

        require(block.timestamp < transaction.expireTime, "proposal expired");

        transaction.numVotes += _daoToken.balanceOf(msg.sender);
        voted[_index][msg.sender] = true;
        votedFor[msg.sender].push(_index);

        emit Vote(msg.sender, _index);

    }

    //Remove votes from a proposal
    function removeVote(uint _index) public onlyDAOMember proposalExists(_index) votedForProposal(_index) {

        TransactionProposal storage transaction = _proposals[_index];

        if(!transaction.executed && !(transaction.expireTime < block.timestamp))
            transaction.numVotes -= _daoToken.balanceOf(msg.sender);

        for (uint256 i = 0; i < votedFor[msg.sender].length - 1; i++)
            if (votedFor[msg.sender][i] == _index) {
                votedFor[msg.sender][i] = votedFor[msg.sender][votedFor[msg.sender].length - 1];
                break;
            }

        votedFor[msg.sender].pop();
        voted[_index][msg.sender] = false;

        emit VoteRemoved(msg.sender, _index);

    }

    //Remove votes from all proposals
    function removeVotes() public onlyDAOMember {

        require(votedFor[msg.sender].length > 0, "no votes");

        uint256 len = votedFor[msg.sender].length;

        for (uint256 i = 0; i < len; i++) {

            uint256 pos = votedFor[msg.sender].length - 1;
            TransactionProposal storage transaction = _proposals[votedFor[msg.sender][pos]];

            if(!transaction.executed && !(transaction.expireTime < block.timestamp))
                transaction.numVotes -= _daoToken.balanceOf(msg.sender);

            votedFor[msg.sender].pop();

        }

        emit VotesRemoved(msg.sender);

    }

    //Execute a propased transaction after it has passed
    function executeTransaction(uint _index) public onlyDAOMember proposalExists(_index) proposalNotExecuted(_index) {

        TransactionProposal storage transaction = _proposals[_index];
        uint256 votesRequired = _daoToken.totalSupply() / 2;

        require(transaction.numVotes >= votesRequired, "not enough votes");
        require(transaction.expireTime > block.timestamp, "expired");
        require(transaction.earliestExecutionTime < block.timestamp, "can't execute yet");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteProposal(msg.sender, _index);

    }

    //Unlock contract when all of the wLiti tokens are returned to this contract
    function unlockDAO() public onlyDAOMember contractLocked {

        require(_wLitiToken.balanceOf(address(this)) == _daoToken.totalSupply(), "wLiti not returned");

        _contractLocked = false;

        emit UnlockedDAO();

    }

    /***************************************************/
    // Only DAO Contract Functions
    /***************************************************/

    function setPartnerAddress(address a) public onlyDAO {

        _partnerAddress = a;

    }

    function setVotingDuration(uint256 t) public onlyDAO {

        _votingDuration = t;

    }

    function setMinimumVotingTime(uint256 t) public onlyDAO {

        _minimumVotingTime = t;

    }

    function transferToPartner() public onlyDAO notContractLocked {

        _contractLocked = true;
        _wLitiToken.transfer(_partnerAddress, _wLitiToken.balanceOf(address(this)));

        emit LockedDAO();

    }

    function upgradeContract(address upgradedContract) public onlyDAO notContractLocked notContractUpgraded {

        _contractUpgraded = true;
        _newContract = upgradedContract;

        _wLitiToken.transfer(upgradedContract, _wLitiToken.balanceOf(address(this)));

        emit Upgraded(upgradedContract);

    }

    /***************************************************/
    // Getters
    /***************************************************/

    function isVoting(address a) public view returns (bool) {

        return votedFor[a].length > 0;

    }

    function getVotingFor(address a) public view returns (uint256[] memory) {

        return votedFor[a];

    }

    function isLocked() public view returns (bool) {

        return _contractLocked;

    }

    function isUpgraded() public view returns (bool) {

        return _contractUpgraded;

    }

    function getNewAddress() public view returns (address) {

        return _newContract;

    }

    function getProposalCount() public view returns (uint) {

        return _proposals.length;

    }

    function getProposals(uint _txIndex)
        public
        view
        returns (
            address proposer,
            string memory title,
            uint256 expireTime,
            uint256 earliestExecutionTime,
            uint256 numVotes,
            address to,
            uint256 value,
            bytes memory data,
            bool executed
        )
    {
        TransactionProposal storage transaction = _proposals[_txIndex];

        return (
            transaction.proposer,
            transaction.title,
            transaction.expireTime,
            transaction.earliestExecutionTime,
            transaction.numVotes,
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed
        );

    }

    function getVotingDuration() public view returns (uint256) {

        return _votingDuration;

    }

    function getMinimumVotingTime() public view returns (uint256) {

        return _minimumVotingTime;

    }

    function getMinimumVotesRequired() public view returns (uint256) {

        return _daoToken.totalSupply() / 2;

    }

    /*function makeProposals() public {

        address a = 0x644011EF0b9cc80c0dbcB34A9f3306F349e46776;

        submitProposal("test", a, 0, "0xeb2c0223000000000000000000000000e333fEce63b0A958fe516F510C7b315f7aD36D11");
        submitProposal("test", a, 0, "0xeb2c0223000000000000000000000000e333fEce63b0A958fe516F510C7b315f7aD36D11");

    }

    function makeVote() public {

        address a = 0x644011EF0b9cc80c0dbcB34A9f3306F349e46776;

        votedFor[a].push(0);
        votedFor[a].push(1);
        votedFor[a].push(2);
        votedFor[a].push(3);

    }

    function addVotes() public {

        address a = 0x644011EF0b9cc80c0dbcB34A9f3306F349e46776;

        if(votedFor[a].length > 0) {

            for (uint256 i = 0; i < votedFor[a].length; i++) {

                TransactionProposal storage transaction = _proposals[votedFor[a][i]];

                if(!transaction.executed)
                    transaction.numVotes += 10;

            }

        }

    }*/

}