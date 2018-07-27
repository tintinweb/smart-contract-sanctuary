pragma solidity ^0.4.18;

contract BsToken {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MultiTransfer {
    function multiTransfer(address _tokenAddress, address[] _addresses, uint256 amount) public returns(address) {
        BsToken token = BsToken(_tokenAddress);
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], amount);
        }
        
        return msg.sender;
    }
    
    function getBalance(address _tokenAddress, address _address) public returns(uint256) {
        BsToken token = BsToken(_tokenAddress);
        return token.balanceOf(_address);
    }
}