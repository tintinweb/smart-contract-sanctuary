pragma solidity ^0.4.24;

/**
 * SmartEth.co
 * ERC20 Token and ICO smart contracts development, smart contracts audit, ICO websites.
 * <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b3d0dcddc7d2d0c7f3c0ded2c1c7d6c7db9dd0dc">[email&#160;protected]</a>
 */

/**
 * @title Ownable
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = 0x9Ea4bDe981C00bc7a10d491B8947412BE18cC260;
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

contract Airdrop is Ownable {

  ERC20 public token = ERC20(0x816c9a82841e01c1ab7719c82d4904439922d6c0);

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