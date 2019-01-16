pragma solidity ^0.4.13;
// https://ropsten.etherscan.io/address/0x60886ee2b92fa391fcf1ba40e32b07e45d58ab9f#code

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract AbstractOwnable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract NewPausable is AbstractOwnable {

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause()  returns (bool) {
    paused = true;
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause()  returns (bool) {
    paused = false;
    return true;
  }
}

contract B {
  function doYourThing(address addressOfA) returns(bool) {
    NewPausable my_a = NewPausable(addressOfA);
    return my_a.pause();
  }
}