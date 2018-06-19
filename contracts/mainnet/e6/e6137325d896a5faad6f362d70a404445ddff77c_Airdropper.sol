pragma solidity ^0.4.24;
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address _owner) constant public returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Airdropper
{
  function multisend(address _tokenAddr, address[] addr, uint256[] values) public
  {
    require(addr.length == values.length && addr.length > 0);
    uint256 i=0;
    while(i < addr.length)
    {
      require(addr[i] != address(0));
      require(values[i] > 0);
      require(ERC20(_tokenAddr).transferFrom(msg.sender, addr[i], values[i]));
      i++;
    }
  }
}