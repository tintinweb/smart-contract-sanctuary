pragma solidity ^0.4.24;

contract ERC20Interface {
      function totalSupply() constant public returns (uint);
      function balanceOf(address who) constant public returns (uint256);
      function transfer(address to, uint256 value) public;
      function allowance(address owner, address spender) public constant returns (uint256);
      function transferFrom(address from, address to, uint256 value) public returns (bool);
      function approve(address spender, uint256 value) public returns (bool);
}

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner()  {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract TokenUtils is Ownable {

  function () public payable {
     // do nothing.
  }

  function batchRefund(address[] DesAddr, uint[] ethAmounts) public payable {
     require(msg.sender == owner);
     require(DesAddr.length > 0);
     require(DesAddr.length == ethAmounts.length);
     uint total = 0;
      for (uint i = 0; i < DesAddr.length; i++) {
         total += ethAmounts[i];
      }

      require(total <= address(this).balance);
        for (i = 0; i < DesAddr.length; i++) {
           if (ethAmounts[i] > 0) {
               DesAddr[i].transfer(ethAmounts[i]);
           }
        }
  }

  function batchRefundzFixed(address[] DesAddr, uint ethAmount) public payable {
     require(msg.sender == owner);
     require(DesAddr.length > 0);
     for (uint i = 0; i < DesAddr.length; i++) {
       DesAddr[i].transfer(ethAmount);
     }
  }

  function airDrop (address TokenAddr,address[] DesAddr,uint256[] amounts) public onlyOwner{
    for( uint i = 0 ; i < DesAddr.length ; i++ ) {
        ERC20Interface(TokenAddr).transfer(DesAddr[i],amounts[i]);
    }
  }

  function airDropSame (address TokenAddr,address[] DesAddr,uint256 amounts) public onlyOwner{
    for( uint i = 0 ; i < DesAddr.length ; i++ ) {
        ERC20Interface(TokenAddr).transfer(DesAddr[i],amounts);
    }
  }

  function draw() public payable {
     require(msg.sender == owner);
     owner.transfer(address(this).balance);
  }

  function drawToken(address TokenAddr) {
     require(msg.sender == owner);
     ERC20Interface token = ERC20Interface(TokenAddr);
     uint256 amount = token.balanceOf(address(this));
     token.transfer(owner, amount);
  }
}