/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/Lottery.sol


pragma solidity ^0.8.0;

contract Lottery is Ownable {
  address[] public participants;
  address[] public winners;
  mapping(address => bool) private isParticipating;
  bool public winnersSelected;
  mapping(address => bool) public isWinner;

  function initParticipants(address[] memory _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      enterLottery(_addresses[i]);
    }
  }

  function enterLottery(address _address) public {
    require(winnersSelected == false, 'Winners has been selected');
    require(
      isParticipating[_address] == false,
      'you are already in the lottery'
    );
    participants.push(_address);
    isParticipating[_address] = true;
  }

  function selectWinners() external onlyOwner {
    require(winnersSelected == false, 'winners have been selected');
    for (uint256 i = 0; i < 10; i++) {
      _pickWinner();
    }
    winnersSelected = true;
  }

  function _pickWinner() internal {
    uint256 randomNum = _randomNum();
    address selected = participants[randomNum];
    isWinner[selected] = true;
    winners.push(selected);
    participants[randomNum] = participants[participants.length - 1];
    participants.pop();
  }

  function _randomNum() internal view returns (uint256) {
    require(participants.length > 0, 'There are no participants');
    uint256 randomNumber = uint256(
      keccak256(
        abi.encodePacked(block.timestamp, block.difficulty, participants)
      )
    ) % participants.length;
    return randomNumber;
  }
}