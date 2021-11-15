// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract USElection is Ownable {
    event LogStateResult(uint8 indexed winner, uint8 stateSeats, string state);
    event LogElectionEnded(uint winner);
    modifier onlyActiveElection() {
      require(!electionEnded, "The election has ended already");
       _;
    }
    uint8 public constant BIDEN = 1;
    uint8 public constant TRUMP = 2;
    bool public electionEnded;
    mapping(uint8 => uint8) public seats;
    mapping(string => bool) public resultsSubmitted;
    struct StateResult {
        string name;
        uint votesBiden;
        uint votesTrump;
        uint8 stateSeats;
    }
   function submitStateResult(StateResult memory result) public onlyActiveElection {
        require(result.stateSeats > 0, "States must have at least 1 seat");
        require(result.votesBiden != result.votesTrump, "There cannot be a tie");
        require(!resultsSubmitted[result.name], "This state result was already submitted!");
        uint8 winner;
        if(result.votesBiden > result.votesTrump) {
            winner = BIDEN;
        } else {
            winner = TRUMP;
        }
        seats[winner] += result.stateSeats;
        resultsSubmitted[result.name] = true;
        emit LogStateResult(winner, result.stateSeats, result.name);
    }
   function currentLeader() public view returns(uint8) {
            if(seats[BIDEN] > seats[TRUMP]) {
                return BIDEN;
            }
            if(seats[TRUMP] > seats[BIDEN]) {
                return TRUMP;
            }
            return 0;
        }
    function endElection() public onlyActiveElection {
        electionEnded = true;
        emit LogElectionEnded(currentLeader());
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
        return msg.data;
    }
}

