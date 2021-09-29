/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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


/**
 * @title Vocabulary
 * @dev A simple distributed vocabulary 
 */
contract Vocabulary is Ownable {

    struct Word {
        string orig;
        string[] translations;
        string[] dependencies;
    }

    Word[] private _words;

    event WordAdded(Word word);
    event VocabularyImported(Word[] newWords);

    /**
     * @dev Retrieves random word from the vocabulary.
     * Uses unfairness predictable randomness preferring simplicity
     */
    function randWord() public view returns (Word memory) {
        require(_words.length > 0, "Dictionary must not be empty");

        return _words[uint(blockhash(block.number - 1)) % _words.length];
    }

    /**
     * @dev Appends new word to the vocabulary
     */
    function addWord(Word memory word) public onlyOwner {
        _words.push(word);
        emit WordAdded(word);
    }

    /**
     * @dev Appends several new words to the vocabulary
     */
    function addWords(Word[] memory words) public onlyOwner {
        for (uint i = 0; i < words.length; i++) {
            _words.push(words[i]);
            emit WordAdded(words[i]);
        }
    }

    /**
     * @dev Exports full vocabulary backup so you can use it if something goes wrong
     */
    function exportVocabulary() public view returns (Word[] memory words) {
        return _words;
    }

    /**
     * @dev Imports and replaces excisting vocabulary with provided one
     */
    function importVocabulary(Word[] memory words) public onlyOwner {
        delete _words;
        for (uint i = 0; i < words.length; i++) {
            _words.push(words[i]);
        }
        emit VocabularyImported(words);
    }

    /**
     * @dev Permanently deletes contract from blockchain with all words.
     * Do not forget to export vocabulary before
     */
    function destruct() public onlyOwner {
        selfdestruct(payable(owner()));
    }
}