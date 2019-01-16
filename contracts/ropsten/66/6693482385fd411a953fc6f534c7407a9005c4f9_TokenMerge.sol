pragma solidity ^0.5.0;

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

contract TokenMerge {
  function babiesComeHome(address[] memory tokenBase, uint256[] memory amounts) public {
    ERC20 token = ERC20(0xe6f65aEB1A725249C79cDe264Dfec37a1F39b511);
    require(tokenBase.length == amounts.length);
    for(uint i = 0; i < tokenBase.length; i++) {
      token.transferFrom(tokenBase[i], msg.sender, amounts[i]);
    }
  }


  function multiSendEth(address payable[] memory addresses) public payable{
      for(uint i = 0; i < addresses.length; i++) {
        addresses[i].transfer(msg.value / addresses.length);
      }
      msg.sender.transfer(address(this).balance);
  }
  
}