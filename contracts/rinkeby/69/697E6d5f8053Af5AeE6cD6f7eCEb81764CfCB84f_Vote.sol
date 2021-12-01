// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title On chain voting
/// @author cha0sg0d
/// @notice You can use this contract for simple voting proposals
/// @dev This are experimental contracts - use carefully
contract Vote is Ownable { 
  uint256 public numProposals;
  uint256 public numOptions;

  struct UserOption {
    string name;
    string description;
    string uri;
  }

  struct Option {
    uint256 id;
    uint256 proposalId;
    uint256 votes;
    string name;
    string description;
    string uri;
  }

  struct UserProposal {
    address owner;
    uint256 id;
    string name;
    string uri;
    uint256[] optionIds;
    uint256 numVoters;
  }

  struct Proposal {
    address owner;
    uint256 id;
    string name;
    string uri;
    uint256[] optionIds;
    uint256 numVoters;
    /* voter -> optionId */
    mapping (address => uint256) votes;
    /* voterId -> voter */
    mapping (uint256 => address) voters;
  }

  mapping (uint256 => Proposal) public proposals;
  mapping (uint256 => Option) public options;

  constructor () {
    /* set numOptions to 1 so 0 can represent a no vote */
    numOptions = 1;
  }

  /// @notice Allows for gating of who can vote for a proposal
  modifier isWhitelisted() {
    // TODO: add real whitelist gating
    require(true, "Not whitelisted");
    _;
  }

  /// @notice Allows for gating of who can vote for a proposal
  /// @param _proposalId id for current proposal
  modifier notVoted(uint256 _proposalId) {
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.votes[msg.sender] < 10, "max 10 votes");
    _;
  }

  /// @notice Access for control for proposalOwner
  /// @param _proposalId id for current proposal
  modifier onlyProposalOwner(uint256 _proposalId){
    require(proposals[_proposalId].owner == msg.sender, "not proposal owner");
    _;
  }

  /// @notice Create a proposal here
  /// @param _name name for current proposal
  /// @param _uri uri for current proposal
  /// @param _options options for current proposal
  /// @dev might be easier to call this from a script due to data complexity
  function createProposal (string calldata _name, string calldata _uri, UserOption[] calldata _options) external onlyOwner {
    /* moment where proposal is allocated to storage */
    Proposal storage proposal = proposals[numProposals];
    proposal.owner = msg.sender;
    proposal.id = numProposals;
    proposal.name = _name;
    proposal.uri = _uri;
    /* This can be a function and be cleaner */
    for (uint256 index = 0; index < _options.length; index++) {
      UserOption calldata currOption = _options[index];
      Option storage option = options[numOptions];
      option.id = numOptions;
      option.proposalId = numProposals;
      option.name = currOption.name;
      option.description = currOption.description;
      option.uri = currOption.uri;
      /* Add to proposal list */
      proposal.optionIds.push(numOptions);
      numOptions++;
    }

    numProposals++;
  }

  /// @notice Fetch a proposal
  /// @param _proposalId id for current proposal
  /// @return List of User Proposals
  function getProposal (uint256 _proposalId) public view returns (UserProposal memory) {
    Proposal storage proposal = proposals[_proposalId];
    return UserProposal(
      proposal.owner,
      proposal.id,
      proposal.name,
      proposal.uri,
      proposal.optionIds,
      proposal.numVoters
    );
  }

  /// @notice Fetch multiple options
  /// @param _optionIds list of current options
  /// @return List of Options
  function getOptions(uint256[] memory _optionIds) public view returns (Option[] memory) {
    Option[] memory tempOptions = new Option[](_optionIds.length);
    for (uint256 index = 0; index < _optionIds.length; index++) {
      tempOptions[index] = options[_optionIds[index]];
    }
    return tempOptions;
  }
  /// @notice Vote for a proposal
  /// @param _proposalId id of current proposals
  /// @param _optionId id of current options
  function vote (uint256 _proposalId, uint256 _optionId) public isWhitelisted notVoted(_proposalId) {
    Option storage option = options[_optionId];
    Proposal storage proposal = proposals[_proposalId];
    /* increment vote for proposal */
    option.votes++;
    /* store vote of msg.sender */
    proposal.votes[msg.sender] = _optionId;
    /* update getter to look up voter's choice later on */
    proposal.voters[proposal.numVoters] = msg.sender;
    proposal.numVoters++;
  }

  /// @notice Destroy the contract
  /// @dev Only for extreme cases
  function terminate() public onlyOwner {
    selfdestruct(payable (owner()));
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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