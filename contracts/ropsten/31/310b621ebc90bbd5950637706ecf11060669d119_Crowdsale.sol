/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity ^0.4.25;
contract ERC20 {

    function totalSupply() public constant returns (uint supply);
    
    function balanceOf(address _owner) public constant returns (uint balance);
    
    function transfer(address _to, uint _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    
    function approve(address _spender, uint _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract StandardToken is ERC20 {

    using SafeMath for uint;

    uint public totalSupply;

    mapping (address => uint) balances;
    
    mapping (address => mapping (address => uint)) allowed;

    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply_;
  function DetailedERC20(string _name, string _symbol, uint8 _decimals, uint256 totalSupply_) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply_ = totalSupply_;
  }
}
contract SimpleToken is DetailedERC20, StandardToken {
  constructor(
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 totalSupply_
  )
    DetailedERC20(_name, _symbol, _decimals,totalSupply_)
    public
  {
    require(totalSupply_ > 0, "amount has to be greater than 0");
    totalSupply_ = totalSupply_.mul(10 ** uint256(_decimals));
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }
}


contract Crowdsale {
  using SafeMath for uint256;

  ERC20 public token;
  address public wallet;
  uint256 public rate;
  uint256 public weiRaised;

  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != address(0));
    require(msg.value != 0);

    uint256 tokens = msg.value.mul(rate);
    weiRaised = weiRaised.add(msg.value);

    token.transfer(_beneficiary, tokens);
    wallet.transfer(msg.value);
  }
}
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}