pragma solidity ^0.4.11;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
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

contract AirDrop is Ownable {

    function contractTokenBalance(address _tokenAddr) onlyOwner public constant returns(uint256) {
       return  ERC20(_tokenAddr).balanceOf(msg.sender);
    }
    
    function send(address _tokenAddr, address _to, uint256 amount) onlyOwner public returns(bool) {
       return ERC20(_tokenAddr).transfer(_to, amount);
    }
    
    function multisend(address _tokenAddr, address[] dests, uint256 amount) onlyOwner public returns(uint256) {
      
        uint256 i = 0;
        while (i < dests.length) {
          ERC20(_tokenAddr).transfer(dests[i], amount);
          i += 1;
        }
        return(i);
    }
    
    function () payable public {
    }
}