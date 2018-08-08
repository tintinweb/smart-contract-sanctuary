pragma solidity ^0.4.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = 0xeb57e7187ddd1d07a45b791c18070d42ef1b6b0c;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Token {
  function transfer(address to, uint value) public returns (bool);
}

contract BITXMultiTransfer is Ownable {
  Token bitx = Token(0xf47ae542aca2f35ec30f93a3dad9a67fa69be207);
  
  function multisend(address[] _to, uint256[] _value)
  public returns (bool _success) {
    assert(_to.length == _value.length);
    assert(_to.length <= 150);
    // loop through to addresses and send value
    for (uint8 i = 0; i < _to.length; i++) {
      assert(bitx.transfer(_to[i], _value[i]) == true);
    }
    return true;
  }
}