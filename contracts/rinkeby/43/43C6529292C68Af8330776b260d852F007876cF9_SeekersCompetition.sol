// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.0;

import "./utils/Ownable.sol";

/*
▄▄▄█████▓ ██░ ██ ▓█████      ██████ ▓█████ ▓█████  ██ ▄█▀▓█████  ██▀███    ██████ 
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▒██    ▒ ▓█   ▀ ▓█   ▀  ██▄█▒ ▓█   ▀ ▓██ ▒ ██▒▒██    ▒ 
▒ ▓██░ ▒░▒██▀▀██░▒███      ░ ▓██▄   ▒███   ▒███   ▓███▄░ ▒███   ▓██ ░▄█ ▒░ ▓██▄   
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄      ▒   ██▒▒▓█  ▄ ▒▓█  ▄ ▓██ █▄ ▒▓█  ▄ ▒██▀▀█▄    ▒   ██▒
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ▒██████▒▒░▒████▒░▒████▒▒██▒ █▄░▒████▒░██▓ ▒██▒▒██████▒▒
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░   ▒ ▒▓▒ ▒ ░░░ ▒░ ░░░ ▒░ ░▒ ▒▒ ▓▒░░ ▒░ ░░ ▒▓ ░▒▓░▒ ▒▓▒ ▒ ░
    ░     ▒ ░▒░ ░ ░ ░  ░   ░ ░▒  ░ ░ ░ ░  ░ ░ ░  ░░ ░▒ ▒░ ░ ░  ░  ░▒ ░ ▒░░ ░▒  ░ ░
  ░       ░  ░░ ░   ░      ░  ░  ░     ░      ░   ░ ░░ ░    ░     
░░   ░ ░  ░  ░  
          ░  ░  ░   ░  ░         ░     ░  ░   ░  ░░  ░      ░  ░   ░           ░  
*/

contract SeekersCompetition is Ownable {
    mapping(bytes32 => bool) public isCorrectAnswer;
    mapping(address => bool) public isWinner;

    uint256 public totalWinners;

    function submitKnowledgeChallenge(string memory answer) external {
        if (isCorrectAnswer[keccak256(abi.encodePacked(answer))] == true) {
            require(totalWinners <= 50, "knowledge submissions are maxed out");
            isWinner[msg.sender] = true;
            totalWinners++;
        }
    }

    function submitManifestorChallenge(string memory answer) external {
        if (isCorrectAnswer[keccak256(abi.encodePacked(answer))] == true) {
            require(totalWinners <= 100, "manifestor submissions are maxed out");
            isWinner[msg.sender] = true;
            totalWinners++;
        }
    }

    function submitAdventurerChallenge(string memory answer) external {
        if (isCorrectAnswer[keccak256(abi.encodePacked(answer))] == true) {
            require(totalWinners <= 150, "adventurer submissions are maxed out");
            isWinner[msg.sender] = true;
            totalWinners++;
        }
    }

    function submitMysticChallenge(string memory answer) external {
        if (isCorrectAnswer[keccak256(abi.encodePacked(answer))] == true) {
            require(totalWinners <= 200, "mystic submissions are maxed out");
            isWinner[msg.sender] = true;
            totalWinners++;
        }
    }

    function uploadAnswers(string[] memory answers) external onlyOwner {
        for (uint256 i = 0; i < answers.length; i++) {
            isCorrectAnswer[keccak256(abi.encodePacked(answers[i]))] = true;
        }
    }

    function theDataWeCall(bytes calldata data) external onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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