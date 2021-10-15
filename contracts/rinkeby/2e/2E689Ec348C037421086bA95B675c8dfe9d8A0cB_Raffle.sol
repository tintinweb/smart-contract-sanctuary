// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/[email protected]/access/Ownable.sol";

//  ██████   █████  ███████ ███████ ██      ███████ 
//  ██   ██ ██   ██ ██      ██      ██      ██      
//  ██████  ███████ █████   █████   ██      █████   
//  ██   ██ ██   ██ ██      ██      ██      ██      
//  ██   ██ ██   ██ ██      ██      ███████ ███████ 

contract Raffle is Ownable {
    event WinnerPicked(uint8 indexed winnerIndex, address indexed winnerAddress);
    
    uint8 private PARTICIPANT_COUNT;
    uint256 private SEED;

    mapping(uint8 => string) private names;
    mapping(uint8 => address) private addresses;

//   ██████  ██     ██ ███    ██ ███████ ██████      ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██ ███████ 
//  ██    ██ ██     ██ ████   ██ ██      ██   ██     ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██ ██      
//  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████      █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██ ███████ 
//  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██     ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██      ██ 
//   ██████   ███ ███  ██   ████ ███████ ██   ██     ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████ ███████ 

    constructor() {
        SEED = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
    
    function destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }
    
    function pickWinner() external onlyOwner {
        uint8 winnerIndex = uint8(nextPseudoRandom(PARTICIPANT_COUNT));
        emit WinnerPicked(winnerIndex, addresses[winnerIndex]);
    }

//  ██████  ███████  █████  ██████      ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██ ███████ 
//  ██   ██ ██      ██   ██ ██   ██     ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██ ██      
//  ██████  █████   ███████ ██   ██     █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██ ███████ 
//  ██   ██ ██      ██   ██ ██   ██     ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██      ██ 
//  ██   ██ ███████ ██   ██ ██████      ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████ ███████ 

    function participantCount() external view returns (uint8) {
        return PARTICIPANT_COUNT;
    }

    function nameAtIndex(uint8 participantIndex) external view returns (string memory) {
        require(participantIndex < PARTICIPANT_COUNT);
        return names[participantIndex];
    }

    function addressAtIndex(uint8 participantIndex) external view returns (address) {
        require(participantIndex < PARTICIPANT_COUNT);
        return addresses[participantIndex];
    }

//  ██     ██ ██████  ██ ████████ ███████     ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██ ███████ 
//  ██     ██ ██   ██ ██    ██    ██          ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██ ██      
//  ██  █  ██ ██████  ██    ██    █████       █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██ ███████ 
//  ██ ███ ██ ██   ██ ██    ██    ██          ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██      ██ 
//   ███ ███  ██   ██ ██    ██    ███████     ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████ ███████ 

    function addParticipant(string memory name) external {
        uint8 participantIndex = PARTICIPANT_COUNT++;
        names[participantIndex] = name;
        addresses[participantIndex] = msg.sender;
    }
    
    function deleteParticipantAtIndex(uint8 participantIndex) external {
        require(participantIndex < PARTICIPANT_COUNT);
        PARTICIPANT_COUNT--;
        for (uint8 index = participantIndex; index < PARTICIPANT_COUNT; ++index) {
            names[index] = names[index + 1];
            addresses[index] = addresses[index + 1];
        }
    }

    function nextPseudoRandom(uint256 max) internal returns (uint) {
        SEED = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, SEED)));
        return SEED % max;
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