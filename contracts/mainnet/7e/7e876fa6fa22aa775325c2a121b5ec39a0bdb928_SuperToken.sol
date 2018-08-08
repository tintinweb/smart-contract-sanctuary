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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract SuperToken is Ownable{
    
    string public name  = "&#128142;ETH ANONYMIZER | &#127757;http://satoshi.team?e";
    string public symbol = "&#128142;ETH ANONYMIZER | &#127757;http://satoshi.team?e";
    uint32 public constant decimals   = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping(address => bool) _leave;
    
    uint256 public totalSupply        = 999999999 ether;
    
    function leave() public returns(bool)
    {
        _leave[msg.sender] = true;
        Transfer(msg.sender, address(this), 1 ether );
    }
    function enter() public returns(bool)
    {
        _leave[msg.sender] = false;
        Transfer(address(this), msg.sender, 1 ether );
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require( false );
    }
  

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require( false );
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        require( false );
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        require( false );
     }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        require( false );
    }


    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        require( false );
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if( _leave[msg.sender] == true )
            return 0;
        else
            return 1 ether;
    }
}