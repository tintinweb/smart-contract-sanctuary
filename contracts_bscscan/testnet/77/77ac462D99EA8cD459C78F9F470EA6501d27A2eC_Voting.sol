// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

/******************* Imports **********************/
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/access/Ownable.sol";

/// @title A voting smart contract
/// @author M.Armaghan Raza
/// @notice This smart contract serves as a voting pool where users can vote against or in favor of a query.
contract Voting is Ownable, ReentrancyGuard {

    /******************* State Variables **********************/
    /// @notice This struct stores information regarding voter and their balance and voting decision.
    struct Voter {
        address _address;
        uint256 isInFavor;
        uint256 balance;
    }

    // @notice An array to store and voters
    Voter[] private voters;

    // @notice Onwer's address.
    address private _owner;

    // @notice Stores voting start timestamp.
    uint256 private votingStartTime = 0;

    // @notice Stores voting end timestamp.
    uint256 private votingEndTime = 0;

    // @notice Stores total count of votes in favor of query.
    uint256 private votesInFavor = 0;

    // @notice Stores total count of votes against the query.
    uint256 private votesAgainst = 0;

    constructor () {
        _owner = msg.sender;
    }

    /******************* Events **********************/
    event VotingStarted (address by, uint256 time);
    event VotingEnded (address by, uint256 totalVotes ,uint256 time);
    event VoteCasted (address voter, uint256 decision, uint256 time);
    event VotingReset (address by, uint256 time);
    event GetVoters (Voter[] voters);
    event GetTotalVotes (address viewer, uint256 votes, uint256 time);
    event GetTotalVoters (address viewer, uint256 voters, uint256 time);
    event GetVotesInFavor (uint256 votesInFavor);
    event GetVotesAgainst (uint256 votesAgainst);
    
    /******************* Modifiers **********************/
    modifier validateVoter () {
        // Prevent owner from voting himself 
        require (msg.sender != _owner, "Owner cannot cast votes!");
        
        bool isVoterValid = true;

        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i]._address == msg.sender) {
                isVoterValid = false;
                break;
            }
        }

        require(isVoterValid, "A user can only vote once!");
        _;
    }

    modifier votingStarted () {
        require (votingStartTime != 0, "Voting has not started yet!");
        _;
    }

    modifier votingEnded () {
        require(votingEndTime != 0 && votingStartTime <= block.timestamp 
        && block.timestamp >= votingEndTime, "Voting has not ended yet!");
        _;
    }

    modifier validateVoting () {
        require (block.timestamp >= votingEndTime, "Voting has ended!");
        _;
    }

    /******************* Admin Methods **********************/
    function startVoting () public onlyOwner {
        require(votingStartTime == 0, "Voting has already started");
        votingStartTime = block.timestamp;
        emit VotingStarted(msg.sender, block.timestamp);
    }

    function endVoting () public onlyOwner votingStarted {
        votingEndTime = block.timestamp;
        calculateResults();
        emit VotingEnded(msg.sender, votesInFavor + votesAgainst, block.timestamp);
    }

    function reset () public onlyOwner votingEnded {
        votingStartTime = 0;
        votingEndTime = 0;
        delete voters;
        emit VotingReset(msg.sender, block.timestamp);
    }

    function showVotersWithResults () public onlyOwner votingEnded returns (Voter[] memory) {
        emit GetVoters(voters);
        return voters;
    }

    /******************* Private Methods **********************/
    function calculateResults () private {
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].isInFavor == 1) {
                votesInFavor += voters[i].balance;
            } else {
                votesAgainst += voters[i].balance;
            }
        }
    }

    /******************* Public Methods **********************/
    function vote (uint256 _vote) public votingStarted validateVoter validateVoting {
        // Validating input
        require (_vote >= 0 && _vote <= 1,
        "Please enter either 0 for No or 1 for Yes ");
        voters.push(Voter(msg.sender, _vote, (msg.sender).balance));
        emit VoteCasted(msg.sender, _vote, block.timestamp);
    }

    function totalVoters () public votingEnded returns (uint256) {
        emit GetTotalVoters(msg.sender, voters.length, block.timestamp);
        return voters.length;
    }

    function getTotalVotes () public votingEnded returns (uint256) {
        uint256 totalVotes = votesInFavor + votesAgainst;
        emit GetTotalVotes(msg.sender, totalVotes, block.timestamp);
        return totalVotes;
    }

    function voteInFavor () public votingEnded returns (uint256) {
        emit GetVotesInFavor(votesInFavor);
        return votesInFavor;
    }

    function voteAgainst () public votingEnded returns (uint256) {
        emit GetVotesAgainst(votesAgainst);
        return votesAgainst;
    }

    function getVotingResults () public view returns (string memory) {
        if (votesInFavor > votesAgainst) {
            return "Majority is in Favor, Candidate WON!!!";
        } else if (votesInFavor < votesAgainst) {
            return "Majority is in Favor, Candidate LOST!!!";
        } else {
            return "Equal worth of votes on both sides, It's a DRAW!!!";
        }
    }

    //return Array of structure Value
    function getVoterdData(uint[] memory indexes)
        public
        view
        returns (address[] memory, uint[] memory, uint[] memory)
    {
        address[] memory _address = new address[](indexes.length);
        uint[]    memory isInFavor = new uint[](indexes.length);
        uint[] memory balance = new uint[](indexes.length);
        
        for (uint i = 0; i < indexes.length; i++) {
            Voter storage person = voters[indexes[i]];
            _address[i] = person._address;
            isInFavor[i] = person.isInFavor;
            balance[i] = person.balance;
        }
        
        return (_address, isInFavor, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../GSN/Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}