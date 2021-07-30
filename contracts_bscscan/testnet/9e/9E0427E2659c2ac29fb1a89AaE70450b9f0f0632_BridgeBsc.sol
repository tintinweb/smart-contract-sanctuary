/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
} 

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract BridgeBase is Ownable {

  IToken public token;
  uint public nonce;
  bool public isActive = true;
  mapping (uint => bool) public processedNonces;

  enum Step {Burn, Mint}

  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint indexed nonce,
    Step indexed step
  );

  modifier isContractActive() {
    require(isActive, "Contract have been disabled by the owner");
    _;
  }

  constructor(address _token) {
    token = IToken(_token);
  }

  function toggleContractActive() external onlyOwner {
    isActive = !isActive;
  }

  function burn(address to, uint amount) external isContractActive {
    token.burn(msg.sender, amount);
    emit Transfer(
      msg.sender,
      to, 
      amount,
      block.timestamp,
      nonce,
      Step.Burn
    );
    nonce++;

  }

  function mint(address to, uint amount, uint otherChainNonce) external onlyOwner isContractActive {
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');

    processedNonces[otherChainNonce] = true;
    token.mint(to, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
    
  }





}
contract BridgeBsc is BridgeBase {
  constructor(address token) BridgeBase(token) {}
}