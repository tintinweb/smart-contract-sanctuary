pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

import "./ISmileToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmileOfDAO is Ownable{

    address public executionWallet;
    ISmileToken public token;
    uint256 public proposalID;

    struct Proposal{
        address owner;
        bool isApproved;
        bool isCompleted;
        uint256 upVote;
        uint256 downVote;
        uint256 abstainVote;
    }
    mapping(uint256 => Proposal) public proposal;
    mapping(uint256 => mapping(address => bool)) public votedUser;

    event ProposalCreated(uint256 id, address createdBy);
    event ProposalApproved(uint256 id, address approvedBy);
    event ProposalCompleted(uint256 id, address completeBy);
    event Voting(uint256 id, address voteBy);

    constructor(address _token, address _executionAddress){
        token = ISmileToken(_token);
        executionWallet = _executionAddress;
    }

    function setExecutionAddress(address _newExecutionAddress) external onlyOwner{
        require(_newExecutionAddress != address(0), "Not allow 0 address");
        executionWallet = _newExecutionAddress;  
    }

    function createProposal() public onlyOwner returns(uint256 id){
        proposalID++;
        proposal[proposalID] = Proposal({
            owner: msg.sender,
            isApproved: false,
            isCompleted: false,
            upVote: 0,
            downVote: 0,
            abstainVote: 0
        });
        emit ProposalCreated(proposalID, msg.sender);
        return proposalID;
    }

    function approveProposal(uint256 _proposalID) external onlyOwner {
        require(proposalID >= _proposalID, "Proposal not exist");
        require(!proposal[_proposalID].isCompleted, "Proposal is completed");
        proposal[_proposalID].isApproved = true;
    }

    function completeProposal(uint256 _proposalID) external onlyOwner {
        require(proposalID >= _proposalID, "Proposal not exist");
        require(proposal[_proposalID].isApproved, "Proposal not approved");
        require(!proposal[_proposalID].isCompleted, "Proposal is completed");
        proposal[_proposalID].isCompleted = true;
    }

    // _voteType = 1 : Up Vote
    // _voteType = 2 : Down Vote
    // _voteType = 3 : Nutral Vote
    function voteProposal(uint256 _proposalID, uint256 _voteType) public {
        require(token.balanceOf(msg.sender) >= 1, "Not enough NFT in your account");
        require(proposalID >= _proposalID, "Proposal not exist");
        require(proposal[_proposalID].isApproved, "Proposal not approved");
        require(!proposal[_proposalID].isCompleted, "Proposal is completed");
        require(!votedUser[_proposalID][msg.sender], "Already vote on this");

        if(_voteType == 1){
            proposal[_proposalID].upVote = proposal[_proposalID].upVote + token.balanceOf(msg.sender);
        } else if(_voteType == 2){
            proposal[_proposalID].downVote = proposal[_proposalID].downVote + token.balanceOf(msg.sender);
        } else if(_voteType == 3){
            proposal[_proposalID].abstainVote = proposal[_proposalID].abstainVote + token.balanceOf(msg.sender);
        }

        votedUser[_proposalID][msg.sender] = true;
    }

}

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

interface ISmileToken {
    function mint(address to) external returns(uint256 tokenID);
    function balanceOf(address owner) external returns(uint256 balance);
    function safeTransferFrom(address sender, address receiver, uint256 tokenID) external;
    function totalSupply() external returns(uint256 tokens);
    function setTokenUri(uint256 _tokenID, string memory _tokenUri) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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