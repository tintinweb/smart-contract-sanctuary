pragma solidity ^0.6.0;

interface JUL{
 function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external  view returns (uint);
  function transfer(address to, uint value) external  returns (bool ok);
  function transferFrom(address from, address to, uint value) external returns (bool ok);
  function approve(address spender, uint value)external returns (bool ok);

}

contract TimeLock{
    address payable public owner;
    uint public endDate;
  
    JUL public Token;
    
    modifier onlyOwner(){
        require(msg.sender==owner,"You aren't owner");
        _;
    }
    constructor(address _JUL) public{
        owner=msg.sender;
        Token=JUL(_JUL);
        endDate=1601366400; // 29th of september 2020, 8:00 AM UTC
    }
    
    
    //function to withdraw deposited JUL
    //only owner can call this function
    function withdrawJUL()onlyOwner public{
        require(endDate<=now);
        require(availableJUL()>0);
        Token.transfer(owner,availableJUL());
    }
    
    //returns JUL token balance of this contract
    function availableJUL()public view returns(uint256) {
        return Token.balanceOf(address(this));
    }
    
  
}