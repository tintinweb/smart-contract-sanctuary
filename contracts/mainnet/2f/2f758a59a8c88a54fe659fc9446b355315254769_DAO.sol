pragma solidity ^0.4.19;

contract DAO {

  using SafeMath for uint256;

  ERC20 public typeToken;
  address public owner;
  address public burnAddress = 0x0000000000000000000000000000000000000000;
  uint256 public tokenDecimals;
  uint256 public unburnedTypeTokens;
  uint256 public weiPerWholeToken = 0.1 ether;

  event LogLiquidation(address indexed _to, uint256 _typeTokenAmount, uint256 _ethAmount, uint256 _newTotalSupply);

  modifier onlyOwner () {
    require(msg.sender == owner);
    _;
  }

  function DAO (address _typeToken, uint256 _tokenDecimals) public {
    typeToken = ERC20(_typeToken);
    tokenDecimals = _tokenDecimals;
    unburnedTypeTokens = typeToken.totalSupply();
    owner = msg.sender;
  }

  function exchangeTokens (uint256 _amount) public {
    require(typeToken.transferFrom(msg.sender, address(this), _amount));
    uint256 percentageOfPotToSend = _percent(_amount, unburnedTypeTokens, 8);
    uint256 ethToSend = (address(this).balance.div(100000000)).mul(percentageOfPotToSend);
    msg.sender.transfer(ethToSend);
    _byrne(_amount);
    emit LogLiquidation(msg.sender, _amount, ethToSend, unburnedTypeTokens);
  }

  function _byrne(uint256 _amount) internal {
    require(typeToken.transfer(burnAddress, _amount));
    unburnedTypeTokens = unburnedTypeTokens.sub(_amount);
  }

  function updateWeiPerWholeToken (uint256 _newRate) public onlyOwner {
    weiPerWholeToken = _newRate;
  }

  function changeOwner (address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  function _percent(uint256 numerator, uint256 denominator, uint256 precision) internal returns(uint256 quotient) {
    uint256 _numerator = numerator.mul((10 ** (precision+1)));
    uint256 _quotient = ((_numerator / denominator) + 5) / 10;
    return ( _quotient);
  }

  function () public payable {}

}

contract ERC20 {
  function totalSupply() public constant returns (uint256 supply);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}