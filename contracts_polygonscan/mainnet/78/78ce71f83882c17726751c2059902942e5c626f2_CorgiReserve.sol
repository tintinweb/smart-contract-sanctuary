/**
 *Submitted for verification at polygonscan.com on 2021-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the BSC standard as defined in the EIP.
 */
interface IBSC {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CorgiReserve is Ownable {
  struct Recipient {
    string reason;
    uint256 balance;
  }

  IBSC public currency;

  mapping (address => Recipient[]) public recipients;
  event Reserve(address user, uint256 amount, string reason);

  constructor(address _currency) public {
    currency = IBSC(_currency);
  }

  function pay(address user, uint256 balance, string memory reason) public onlyOwner {
    require(IBSC(currency).transfer(user, balance), 'reserve was failure');
    Recipient memory recipient;
    recipient.reason = reason;
    recipient.balance = balance;
    recipients[user].push(recipient);

    emit Reserve(user, balance, reason);
  }

  function availabe() public view returns (uint256) {
    return IBSC(currency).balanceOf(address(this));
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
  
  function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner { 
    IBSC(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
  }
  
  function changeCurrency(address _currency) public onlyOwner {
    currency = IBSC(_currency);
  }
}