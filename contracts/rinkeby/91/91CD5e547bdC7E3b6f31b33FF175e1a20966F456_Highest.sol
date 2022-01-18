/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

// import "../utils/Context.sol";

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

pragma solidity ^0.8.7;

contract Highest is Ownable {
    //key is round number and second mapping key is session ID and value is scores struct
    mapping(uint => mapping(uint256 => Scores)) public roundScores;

    // Mapping of the winners address and amount won
    mapping(address => uint256) public _addressOfWinners;

    struct Scores {
        address _address; 
        uint256 _score;
    }


    uint256 public _minPymt = 1 ether;
    uint256 public session_ID = 1;
    bool public paused = false;
    uint256 public round = 1;


    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
//event that will be emited in the below function
    event newGame (address indexed _player, uint256 indexed _roundNum, uint256 indexed _sessionID);


    function play() public payable{
        require(msg.value >= _minPymt);
        require(!paused);

        emit newGame(msg.sender, round, session_ID);

        roundScores[round][session_ID] = Scores(msg.sender,0);

        session_ID += 1;

    }

// event for new score being added
    event newScoreAdded (address indexed _player, uint256 indexed _sessionID, uint256 indexed scoreAmt );

    function updateScore(uint256 currRound, uint256 playerSID, address plyrAddress, uint256 scoreAmt) public onlyOwner {
        
        roundScores[currRound][playerSID] = Scores(plyrAddress,scoreAmt);
        emit newScoreAdded(plyrAddress, playerSID, scoreAmt);
        
    }

// this function covers the fee to run the game and write the results to the blockchain and starts new round

    function closeRound(uint256 percent) public onlyOwner {
        paused = true;

        (bool os, ) = payable(owner()).call{value: address(this).balance * percent / 100}("");
        require(os);
        
        round += 1;
        
        session_ID = 0; }


// this function splits all the fund colleced in the current round and starts a new round.
    function startNewRound(
        address first,
        address second,
        address third) public onlyOwner {
           _addressOfWinners[first] += address(this).balance * 50/100;
           _addressOfWinners[second] += address(this).balance * 30/100;
           _addressOfWinners[third] += address(this).balance * 20/100;

        paused = false;

    }


    function withdraw() public {
        uint withdrawAmt = _addressOfWinners[msg.sender];

        require(withdrawAmt > 0);

        _addressOfWinners[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawAmt);
    
    }







}