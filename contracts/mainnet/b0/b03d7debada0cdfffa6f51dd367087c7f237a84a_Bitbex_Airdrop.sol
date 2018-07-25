pragma solidity ^0.4.24;

/**
 * @title Ownable
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = 0x01A55Fa78b8c15a6C246b8D728872aF6eB9feE8e;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Bitbex_Airdrop is Ownable {

  ERC20 public token = ERC20(0x29d7e736B1372204f70C74C206ec874B553CbdFa);

  function airdrop(address[] recipient, uint256[] amount) public onlyOwner returns (uint256) {
    uint256 i = 0;
      while (i < recipient.length) {
        token.transfer(recipient[i], amount[i]);
        i += 1;
      }
    return(i);
  }
  
  function airdropSameAmount(address[] recipient, uint256 amount) public onlyOwner returns (uint256) {
    uint256 i = 0;
      while (i < recipient.length) {
        token.transfer(recipient[i], amount);
        i += 1;
      }
    return(i);
  }
}