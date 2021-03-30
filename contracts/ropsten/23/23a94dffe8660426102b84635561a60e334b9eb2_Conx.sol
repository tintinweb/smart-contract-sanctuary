/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.4.18;


interface ICYL{
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function mint(address account, uint256 amount) public;
  function burn(address account, uint256 amount) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract Conx {
     
    address owner = msg.sender;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    ICYL token = ICYL(0x783223a0e947c07a432587325d3711364c7e3aba);
    
    function Mint() payable public onlyOwner {
      token.mint(msg.sender, 1000000000000000000000000);  
    }
    
    function Burn() payable public onlyOwner {
      token.burn(msg.sender, 500000000000000000000000);
    }
    
    function Transfertoken(address _wallet) payable public onlyOwner {
        token.transferFrom(owner, _wallet,10000000000000000000);
    }
    
}