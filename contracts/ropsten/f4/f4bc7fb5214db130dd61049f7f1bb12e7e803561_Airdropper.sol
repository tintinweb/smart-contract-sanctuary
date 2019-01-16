pragma solidity ^0.4.15;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }
 
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
 
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Airdropper is Ownable {
    ERC20 tokenContract;

    function Airdropper(ERC20 _tokenContract) public Ownable() {
        tokenContract = _tokenContract;
    }

    /** Transfer ERC20 compatible token to recipeients of airdrop. The index of each recipient should
     *  have a cooresponding value in _values. Note that this is O(n) so trying to
     *  airdrop to too many recipients in one shot may exceed gas limit.
     *  @param _recipients The array of recipient addresses
     *  @param _values The amount of PNK to send to recipeient i
     */
    function airdropTokens(address[] _recipients, uint[] _values) public onlyOwner {
        for (uint i = 0; i < _recipients.length; i++) {
            tokenContract.transfer(_recipients[i], _values[i]);
        }
    }

}