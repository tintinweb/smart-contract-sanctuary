pragma solidity ^0.4.23;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract OwnablePausable {

    bool public paused;
    address public owner;
    uint public ownershipTransferTime;

    event OwnershipTransferred (
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
        ownershipTransferTime = now;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) whenNotPaused public {
        owner = newOwner;
        ownershipTransferTime = now;
    }

    function togglePaused() onlyOwner public {
        paused = !paused;
    }

}
/**
 * @dev this contract has an internal balance which can only be withdrawn by the owner of the contract.
 * if you manage to pull all the value out of this contract you can trigger the winnerAnnounced event and
 * declare yourself a winner!
 */
contract Honeypot is OwnablePausable {

  constructor() public payable {
    require(msg.value != 0);
    balance = msg.value;
  }

  uint public balance;

  event winnerAnnounced(address winner, string yourName);

  /**
   * @dev The transferBalance function sends the current balance of this contract to the owner,
   * but will revert if the owner is a new owner (less than 15 minutes)
   */
  function transferBalance() public onlyOwner {
    require(ownershipTransferTime <= now + 15 minutes);
    balance = 0;
    owner.transfer(balance);
  }

  /**
   * @dev only the current owner of the contract can call this function
   * and the winner will be announced if the balance is 0
   */
  function announceWinner(string yourName) public onlyOwner {
    require(balance == 0);
    emit winnerAnnounced(msg.sender, yourName);
  }

  /**
   * @dev non-payable fallback function that has no functionality
   */
  function () {

  }
}