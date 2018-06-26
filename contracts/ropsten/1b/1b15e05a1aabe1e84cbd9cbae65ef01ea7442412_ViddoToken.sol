pragma solidity ^0.4.24;

contract ViddoToken  {

   function totalSupply() public constant returns (uint)
   {
       return totalSupply_;
   }
    function balanceOf(address tokenOwner) public constant returns (uint balance)
    {
        return 0;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining)
    {
        return 0;
    }
    function transfer(address to, uint tokens) public returns (bool success)
    {
        emit Transfer(msg.sender,to,tokens);
        return true;
        
    }
    
    function approve(address spender, uint tokens) public returns (bool success)
    {
        emit Approval(msg.sender,spender,tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success)
    {
        emit Transfer(from,to,tokens);
        return true;
    }
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

  string public name = &quot;test&quot;;
  string public symbol = &quot;test&quot;;
  uint256 public decimals = 18;
  uint256 totalSupply_ = 0;
  constructor ()  public
  {
    totalSupply_ = 100 * 10**24;

  }

}