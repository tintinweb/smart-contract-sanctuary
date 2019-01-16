pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract CodeExamples_00 {
  using SafeMath for uint256;
  address owner = msg.sender;
  address multisig = msg.sender;
  
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;


  modifier onlyOwner() {
        require(msg.sender == owner);
        _;
  }
  
  function() public payable {
    multisig.transfer(msg.value);
  }

  function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
  }
  
  function withdrawForeignTokensTo(address _tokenContract, address _to) onlyOwner public returns (bool) {
        require(_to != address(0));
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(_to, amount);
  }
  
  function withdrawForeignTokensTo(address _tokenContract, address _to, uint256 _wdamount) onlyOwner public returns (bool) {
        require(_to != address(0));
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 wantAmount = _wdamount;
        return token.transfer(_to, wantAmount);
  }

}