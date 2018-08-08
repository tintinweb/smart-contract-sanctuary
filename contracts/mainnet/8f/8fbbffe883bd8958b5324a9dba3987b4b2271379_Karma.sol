pragma solidity ^0.4.10;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Karma is SafeMath, StandardToken {

    string public constant name = "Karma PreSale Token";
    string public constant symbol = "KRMP";
    uint256 public constant decimals = 18;
    uint256 public constant tokenCreationCap =  5000*10**decimals;

    address public multiSigWallet;
    address public owner;

    // 1 ETH = 300 USD Date: 11.08.2017
    uint public oneTokenInWei = 333333333333333000;

    modifier onlyOwner {
        if(owner!=msg.sender) revert();
        _;
    }

    event CreateKRM(address indexed _to, uint256 _value);

    function Karma(address _SigWallet, address _owner) {
        multiSigWallet = _SigWallet;
        owner = _owner;
        
        balances[0xDe9a1a8CC771C12D4D85b32742688D3EC955167c] = 1900 * 10**decimals;
        balances[0x707Db60b19Cfc5d525DD2359D6181248aa0A518d] = 2900 * 10**decimals;
        balances[0xbfe3d6da33616Ae044c17e203969d37ED5aDF651] = 100 * 10**decimals;
        balances[0x45d6B3Ed3375B114F3ecD3ac5D7E9Bd2154a1E89] = 100 * 10**decimals;
    }

    function () payable {
        createTokens();
    }

    function createTokens() internal {
        if (msg.value <= 0) revert();

        uint multiplier = 10 ** decimals;
        uint256 tokens = safeMult(msg.value, multiplier) / oneTokenInWei;

        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        if (tokenCreationCap < checkedSupply) revert();

        balances[msg.sender] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
    }

    function finalize() external onlyOwner {
        multiSigWallet.transfer(this.balance);
    }
    
    // add call to oracle 
    function setEthPrice(uint _etherPrice) onlyOwner {
        oneTokenInWei = 1 ether / _etherPrice / 100;
    }

}