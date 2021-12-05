// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Istack.sol";

contract BridgeAvax is Ownable {
    
  address nullAddress = 0x0000000000000000000000000000000000000000;
  Istack public wSTACK;
  uint public nonce;
  uint public minimumBurn;
  bool public paused;
  mapping(uint => bool) public processedNonces;
  mapping(address => bool) public bridged;
  address [] public bridgers;
  

  enum Step { burn, mint }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );
    

  constructor (address _wstackAddress, uint _minimumBurn) {
    wSTACK = Istack(_wstackAddress);
    minimumBurn = _minimumBurn;
    paused = true;
  }

  function burn(uint amount) external onlyNotBridged() {
    require(!paused, 'bridging is paused');
    require(amount >= minimumBurn, 'minimum bridge amount not met');
    bridged[msg.sender] = true;
    bridgers.push(msg.sender);
    wSTACK.burn(msg.sender, amount);
    emit Transfer(
      msg.sender,
      nullAddress,
      amount,
      block.timestamp,
      nonce,
      Step.burn
      );
    nonce++;
  }

  function mint(address to, uint amount, uint otherChainNonce) external onlyOwner{
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    wSTACK.mint(to, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.mint
    );
  }

  function setPause(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function setMinimumBurn(uint _minimumBurn) external onlyOwner {
    minimumBurn = _minimumBurn;
  }

  function resetBridgeEpoch () external onlyOwner {
    for (uint i=0; i< bridgers.length ; i++){
      bridged[bridgers[i]] = false;
    }
  }

  modifier onlyNotBridged () {
    require(bridged[msg.sender] == false, 'you have already bridged in this epoch'); 
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Istack {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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