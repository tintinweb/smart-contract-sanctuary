pragma solidity 0.4.20;

contract ERC20 {
  uint public totalSupply;
  
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract CanSend {

  uint8 MAX_RECIPIENTS = 255;

  event TokensSent (address indexed token, uint256 total);

  function multisend (address _token, address[] _recipients, uint256[] _amounts) public {
    require(_token != address(0));
    require(_recipients.length != 0);
    require(_recipients.length <= MAX_RECIPIENTS);
    require(_recipients.length == _amounts.length);
    ERC20 tokenToSend = ERC20(_token);
    uint256 totalSent = 0;
    for (uint8 i = 0; i < _recipients.length; i++) {
      require(tokenToSend.transferFrom(msg.sender, _recipients[i], _amounts[i]));
      totalSent += _amounts[i];
    }
    TokensSent(_token, totalSent);
  }

}