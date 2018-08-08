pragma solidity ^0.4.18;

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

contract Prod is Ownable {
    
    string public name = "https://t.me/this_crypto";
    string public symbol = "https://t.me/this_crypto";
    uint256 public num = 1;
    uint256 public totalSupply = 2100005 ether;
    uint32 public constant decimals = 18;


    function() public payable
    {
        require( msg.value > 0 );
        
        owner.transfer(msg.value);

    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return num  * 1 ether;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return 0;
     }

}