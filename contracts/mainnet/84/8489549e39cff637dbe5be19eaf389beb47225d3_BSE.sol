pragma solidity ^0.4.18;

library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {

    uint256 public totalSupply;

    function balanceOf(address _owner) constant public returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Auth {
    address public owner = 0x00;
    mapping (address => bool) public founders;
    struct ProposeOwner {
        address owner;
        bool active;
    }
    ProposeOwner[] public proposes;

    function Auth () {
        founders[0x18177d9743c1dfd9f4b9922986b3d7dbdc6683a6] = true;
        founders[0x94fc42a2f94f998dfb07e077c8610f7b72977ce3] = true;
    }

    function proposeChangeOwner (address _address) public isFounder {
        proposes.push(ProposeOwner({
            owner: _address,
            active: true
        }));
    }

    function approveChangeOwner (uint _index) public isFounder {
        assert(proposes[_index].owner != msg.sender);
        assert(proposes[_index].active);

        proposes[_index].active = false;
        owner = proposes[_index].owner;
    }

    modifier auth {
        assert(msg.sender == owner);
        _;
    }

    modifier isFounder() {
        assert(founders[msg.sender]);
        _;
    }
}

contract Stop is Auth {

    bool public stopped = false;

    modifier stoppable {
        assert (!stopped);
        _;
    }

    function stop() auth {
        stopped = true;
    }

    function start() auth {
        stopped = false;
    }

}

contract StandardToken is Token, Stop {

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public stoppable returns (bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[msg.sender]);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public stoppable returns (bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function approve(address _spender, uint256 _value) public stoppable returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract BSE is StandardToken {

    function () public {
        revert();
    }

    string public name = "BiSale";
    uint8 public decimals = 18;
    string public symbol = "BSE";
    string public version = &#39;v0.1&#39;;
    uint256 public totalSupply = 0;

    function BSE () {
        owner = msg.sender;
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function mint(address _target, uint256 _value) auth stoppable {
        require(_target != address(0));
        require(_value > 0);
        balanceOf[_target] = SafeMath.safeAdd(balanceOf[_target], _value);
        totalSupply = SafeMath.safeAdd(totalSupply, _value);
    }

    function burn(uint256 _value) auth stoppable {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply, _value);
    }
}