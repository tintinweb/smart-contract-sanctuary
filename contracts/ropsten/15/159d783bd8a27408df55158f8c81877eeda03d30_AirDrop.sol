pragma solidity ^0.4.19;

/**
 * @title Token
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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

contract AirDrop is Ownable {

  // This declares a state variable that would store the contract address
  ERC20 public tokenInstance;

  /*
    constructor function to set token address
   */
  function AirDrop(address _tokenAddress) public {
    tokenInstance = ERC20(_tokenAddress);
  }

  /*
    Airdrop function which take up a array of address,token amount
   */
  function doAirDrop(address[] _address, uint256[] _amount) onlyOwner public returns (bool) {
    uint256 count = _address.length;
    for (uint256 i = 0; i < count; i++)
    {
      /* calling transfer function from contract */
      tokenInstance.transferFrom(msg.sender, _address [i], _amount [1]);
    }
  }

  /*
    function to add eth to the contract
   */
  function() payable public {

  }

  /*
    function to kill contract
  */

  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}