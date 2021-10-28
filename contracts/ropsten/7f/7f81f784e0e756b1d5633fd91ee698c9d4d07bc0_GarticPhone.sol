/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: contracts/GarticPhone1.sol

pragma solidity 0.8.7;


/** @notice A simple gartic phone game on-chain
    @author Loïs L. */
contract GarticPhone is Ownable {
    /** @dev store all the words played */
    string[] private wordsChain;
    /** store how many try of guess got effectued */
    uint guessCount;
    /** @dev track how many words got played and is stored in 'wordsChain' */
    uint8 private wordsCount;
    /** @dev index for an address if address have put a word in the game 
    (1 word per address possible) */
    mapping (address => bool) private havePlayed;
    /** @notice contains the state of the game */
    gameStates public state;
    /** @param RUNNING the game is running and players can propose a word
        @param GUESS_WAITING 20 words is played and contract wait a correct guess in 'guessFirstWord()' 
        @param FINISHED the game is finished */
    enum gameStates{RUNNING, GUESS_WAITING, FINISHED}

    /** @notice construct the contract and initialize the game with the first word
        @param _firstWord the first word to start the game */
    constructor(string memory _firstWord){
        require(keccak256(abi.encode(_firstWord)) != keccak256(abi.encode("")), "word can't be empty");

        state = gameStates.RUNNING;
        wordsChain.push(_firstWord);
        wordsCount = 1;
        havePlayed[msg.sender] = true;

        emit onStateChange(state, block.timestamp);
    }

    /** @notice put a new word in the game and disallow 'msg.sender' to put other words 
        @param _word the word to put in the word chain */
    function putNewWord(string memory _word) public {
        require(keccak256(abi.encode(_word)) != keccak256(abi.encode("")), "word can't be empty");
        require(state == gameStates.RUNNING, "you can't enter word anymore");
        require(havePlayed[msg.sender] == false, "address already played");
        require(keccak256(abi.encode(_word)) != keccak256(abi.encode(wordsChain[wordsCount - 1])), "word is the same than the previous word");

        wordsChain.push(_word);
        havePlayed[msg.sender] = true;
        wordsCount++;

        //if word chain have 20 word, the game get in GUESS WAITING Mode
        if(wordsCount == 20){
            state = gameStates.GUESS_WAITING;
            emit onStateChange(state, block.timestamp);
        }
    }

    /** @notice get the last word of the chain, accessing by all the player who wanna put a word or guess 
        @return the last word of the chain*/
    function getLastWord() public view returns(string memory){
        return wordsChain[wordsCount - 1];
    }

    /** @notice get all the words of the chain, accessing only by the contract owner (the game starter) */
    function getAllWords() public view onlyOwner() returns(string[] memory){
        return wordsChain;
    }

    /** @notice try to guess what was the first word of the chain 
        @param _word the word to try 
        @return true if the word was the first word, false if the word is incorrect */
    function guessFirstWord(string memory _word) public returns(bool){
        require(state == gameStates.GUESS_WAITING, "the game isn't in guess mode");
        require(keccak256(abi.encode(_word)) != keccak256(abi.encode("")), "word can't be empty");
        guessCount++;

        if(keccak256(abi.encode(_word)) == keccak256(abi.encode(wordsChain[0]))){
            state = gameStates.FINISHED;

            emit onStateChange(state, block.timestamp);
            emit onFinishedGame(wordsChain[0], guessCount);

            return true;
        }
        else return false;
    }

    event onStateChange(gameStates newState, uint timestamp);
    event onFinishedGame(string firstWord, uint numberOfTry);
}