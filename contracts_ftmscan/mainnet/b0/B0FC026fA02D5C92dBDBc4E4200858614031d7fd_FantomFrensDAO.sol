/**
 *Submitted for verification at FtmScan.com on 2022-01-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/FrensDAO.sol


pragma solidity ^0.8.4;




contract FantomFrensDAO is Ownable, Pausable {

    IERC20 frensContract;

    uint public minVoteTokens;
    uint public minProposalTokens;

    uint public proposalCount = 0;
    uint[] public proposals;
    mapping(uint => Proposal) public proposalList;

    //Track Votes
    // proposal ID => option 1/2/3 => vote count
    mapping(uint => mapping(uint => uint)) public votes;

    // address => proposal ID => bool
    mapping(address => mapping(uint => bool)) public hasVoted;
    
    struct Proposal {
        uint  proposalId;
        string title;
        uint256 initiationTimestamp;
        uint256 completionTimestamp;
        string description;
        string options;
        uint256 totalVotes;
        address proposer;
    }

    // Events
    event ProposalSubmitted(
        uint  proposalId,
        string title,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        string description,
        string options,
        uint256 totalVotes,
        address proposer
    );

    
    event ProposalDeleted(
        uint  proposalId
    );

    event ProposalVoted(
        uint  proposalId,
        address voter,
        uint256 vote
    );

    
    

    function setContractAddress(address _frensContractAddress) external onlyOwner {
        frensContract = IERC20(_frensContractAddress);
    }

    
    function submitVote(uint proposalId, uint option) external {
        require(!paused(), "Contract is paused");
        require(option > 0 && option <= 3, "Invalid option");
        require(msg.sender != address(0), "Proposal sender cannot be the zero address");
        require(frensContract.balanceOf(msg.sender) >= minVoteTokens, "Not enough tokens to submit vote");
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal id");
        require(proposalList[proposalId].initiationTimestamp >= block.timestamp, "Proposal has not started yet");
        require(proposalList[proposalId].completionTimestamp < block.timestamp, "Proposal has already ended");
        require(hasVoted[msg.sender][proposalId] == false, "You have already voted on this proposal");


        Proposal memory proposal = proposalList[proposalId];
        proposal.totalVotes += 1;

        votes[proposalId][option] += 1;
        hasVoted[msg.sender][proposalId] = true;
        
        emit ProposalVoted(
            proposalId,
            msg.sender,
            option
        );

    }


    function submitProposal(
        string calldata title,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        string calldata description,
        string calldata options
        
    ) external whenNotPaused {
        require(!paused(), "Contract is paused");
        require(msg.sender != address(0), "Proposal sender cannot be the zero address");
        require(frensContract.balanceOf(msg.sender) >= minProposalTokens, "Not enough tokens to submit proposal");

        uint proposalId = proposalCount++;
        require(
            proposalList[proposalId].proposer == address(0),
            "Proposal already submitted"
        );


        proposalList[proposalId] = Proposal(
            proposalId,
            title,
            initiationTimestamp,
            completionTimestamp,
            description,
            options,
            0,
            msg.sender
        );

        proposals.push(proposalId);

        emit ProposalSubmitted(
            proposalId,
            title,
            initiationTimestamp,
            completionTimestamp,
            description,
            options,
            0,
            msg.sender
        );
    }

    function deleteProposal(uint proposalId) external {
        require(!paused(), "Contract is paused");
        require(msg.sender == owner() || proposalList[proposalId].proposer == msg.sender, "Only owner or proposer can delete proposal");

        delete proposalList[proposalId];

        for (uint i = proposalId; i<proposals.length-1; i++){
            proposals[i] = proposals[i+1];
        }
        proposals.pop();

        emit ProposalDeleted(proposalId);
    }

    function getProposal(uint proposalId) external view returns (Proposal memory) {
        return proposalList[proposalId];
    }

    function getProporsalIds() external view returns (uint[] memory) {
        return proposals;
    }

    function setMinVoteTokens(uint _minVoteTokens) external onlyOwner {
        minVoteTokens = _minVoteTokens;
        
    }

    function setMinProposalTokens(uint _minProposalTokens) external onlyOwner {
        minProposalTokens = _minProposalTokens;
        
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

}