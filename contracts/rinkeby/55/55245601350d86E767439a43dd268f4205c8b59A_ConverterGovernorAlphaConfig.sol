/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts/ConverterGovernorAlphaConfig.sol

pragma solidity 0.6.12;


contract ConverterGovernorAlphaConfig is Ownable {
    uint public constant MINIMUM_DELAY = 1 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    // 1000 / quorumVotesDivider = percentage needed
    uint public quorumVotesDivider;
    // 1000 / proposalThresholdDivider = percentage needed
    uint public proposalThresholdDivider;
    // The maximum number of individual transactions that can make up a proposal
    uint public proposalMaxOperations;
    // Time period (in blocks) during which the proposal can be voted on
    uint public votingPeriod;
    // Delay (in blocks) that must be waited after a proposal has been added before the voting phase begins
    uint public votingDelay;

    // Time period in which the transaction must be executed after the delay expires
    uint public gracePeriod;
    // Delay that must be waited after the voting period has ended and a proposal has been queued before it can be executed
    uint public delay;

    event NewQuorumVotesDivider(uint indexed newQuorumVotesDivider);
    event NewProposalThresholdDivider(uint indexed newProposalThresholdDivider);
    event NewProposalMaxOperations(uint indexed newProposalMaxOperations);
    event NewVotingPeriod(uint indexed newVotingPeriod);
    event NewVotingDelay(uint indexed newVotingDelay);

    event NewGracePeriod(uint indexed newGracePeriod);
    event NewDelay(uint indexed newDelay);

    constructor () public {
        quorumVotesDivider = 16; // 62.5%
        proposalThresholdDivider = 2000; // 0.5%
        proposalMaxOperations = 10;
        votingPeriod = 17280;
        votingDelay = 1;

        gracePeriod = 14 days;
        delay = 2 days;
    }

    function setQuorumVotesDivider(uint _quorumVotesDivider) external onlyOwner {
        quorumVotesDivider = _quorumVotesDivider;
        emit NewQuorumVotesDivider(_quorumVotesDivider);
    }
    function setProposalThresholdDivider(uint _proposalThresholdDivider) external onlyOwner {
        proposalThresholdDivider = _proposalThresholdDivider;
        emit NewProposalThresholdDivider(_proposalThresholdDivider);
    }
    function setProposalMaxOperations(uint _proposalMaxOperations) external onlyOwner {
        proposalMaxOperations = _proposalMaxOperations;
        emit NewProposalMaxOperations(_proposalMaxOperations);
    }
    function setVotingPeriod(uint _votingPeriod) external onlyOwner {
        votingPeriod = _votingPeriod;
        emit NewVotingPeriod(_votingPeriod);
    }
    function setVotingDelay(uint _votingDelay) external onlyOwner {
        votingDelay = _votingDelay;
        emit NewVotingDelay(_votingDelay);
    }

    function setGracePeriod(uint _gracePeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
        emit NewGracePeriod(_gracePeriod);
    }
    function setDelay(uint _delay) external onlyOwner {
        require(_delay >= MINIMUM_DELAY, "TimeLock::setDelay: Delay must exceed minimum delay.");
        require(_delay <= MAXIMUM_DELAY, "TimeLock::setDelay: Delay must not exceed maximum delay.");
        delay = _delay;
        emit NewDelay(_delay);
    }
}