pragma solidity ^0.4.16;

contract Owned {
    address public owner;
    address public newOwner;
    modifier onlyOwner { assert(msg.sender == owner); _; }

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
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


contract wolkair is Owned {
    address public constant wolkAddress = 0x728781E75735dc0962Df3a51d7Ef47E798A7107E;
    function multisend(address[] dests, uint256[] values) onlyOwner returns (uint256) {
        uint256 i = 0;
        require(dests.length == values.length);
        while (i < dests.length) { 
           ERC20(wolkAddress).transfer(dests[i], values[i] * 10**18);
           i += 1;
        }
        return(i);
    }
}