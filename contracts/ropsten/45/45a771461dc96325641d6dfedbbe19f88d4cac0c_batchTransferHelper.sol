pragma solidity ^0.4.24;
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract batchTransferHelper {
  ERC20 token;
  address public admin;

  function batchTransfer(address[] _receivers, uint256[] _balances) public returns(bool){
    require(msg.sender == admin);
    for(uint256 i = 0; i < _receivers.length; i++) {
      require(token.transfer(_receivers[i], _balances[i]));
    }
    return true;
  }

  constructor(address tokenAddress) public{
    token = ERC20(tokenAddress);
    admin = msg.sender;
  }
}