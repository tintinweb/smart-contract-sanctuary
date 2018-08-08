pragma solidity ^0.4.8;

contract SafeMath {

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }

    function safeAddCheck(uint256 x, uint256 y) internal returns(bool) {
      uint256 z = x + y;
      if ((z >= x) && (z >= y)) {
          return true;
      }
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
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


/*  ERC 20 token */
contract LeeroyPoints is Token, SafeMath {
    address public owner;
    mapping (address => bool) public controllers;

    string public constant name = "Leeroy Points";
    string public constant symbol = "LRP";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    uint256 public constant baseUnit = 1 * 10**decimals;

    event CreateLRP(address indexed _to, uint256 _value);

    function LeeroyPoints() {
        owner = msg.sender;
    }

    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    modifier onlyController { if (controllers[msg.sender] == false) throw; _; }

    function enableController(address controller) onlyOwner {
        controllers[controller] = true;
    }

    function disableController(address controller) onlyOwner {
        controllers[controller] = false;
    }

    function create(uint num, address targetAddress) onlyController {
        uint points = safeMult(num, baseUnit);
        // use bool instead of assert, controller can run indefinitely
        // regardless of totalSupply
        bool checked = safeAddCheck(totalSupply, points);
        if (checked) {
            totalSupply = totalSupply + points;
            balances[targetAddress] += points;
            CreateLRP(targetAddress, points);
        }
   }

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