pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  uint8 public decimals;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Exchange is Ownable {
  mapping (address => bool) public supportedTokens;
  event ExchangeEvent(address tokenToSell, address tokenToBuy, uint256 value);
  
  function setSupportedTokens(address tokenAddress, bool op) onlyOwner public {
    supportedTokens[tokenAddress] = op;
  }
  
    /**
   *  exchange ERC20 tokens with 1:1.
   */
  function exchangeERC20(address _tokenToSell, address _tokenToBuy, uint256 _value) {
    require(supportedTokens[_tokenToSell]);
    require(supportedTokens[_tokenToBuy]);
    require(_tokenToSell != _tokenToBuy);
    
    ERC20Basic tokenToSell = ERC20Basic(_tokenToSell);
    ERC20Basic tokenToBuy = ERC20Basic(_tokenToBuy);

    require(_value > 0 && tokenToBuy.balanceOf(this) >= _value);

    if (!tokenToSell.transferFrom(msg.sender, address(this), _value)) throw;
    tokenToBuy.transfer(msg.sender, _value);
  
    ExchangeEvent(_tokenToSell,_tokenToBuy,_value);
  }
}