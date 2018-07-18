pragma solidity 0.4.24;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public returns (bool success) {
        owner = newOwner;
        return true;
    }
}

contract Stopped is Owned {

    bool public stopped = true;

    modifier noStopped {
        require(!stopped);
        _;
    }

    function start() onlyOwner public {
      stopped = false;
    }

    function stop() onlyOwner public {
      stopped = true;
    }

}

contract MathTCT {

    function add(uint256 x, uint256 y) pure internal returns(uint256 z) {
      assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) pure internal returns(uint256 z) {
      assert((z = x - y) <= x);
    }
}

contract TokenERC20 {

    function totalSupply() view public returns (uint256 supply);
    function balanceOf(address who) view public returns (uint256 value);
    function allowance(address owner, address spender) view public returns (uint256 _allowance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract TCT is Owned, Stopped, MathTCT, TokenERC20 {

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address indexed target, bool frozen);
    event Burn(address indexed from, uint256 value);

    constructor(string _name, string _symbol) public {
        totalSupply = 200000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() view public returns (uint256 supply) {
        return totalSupply;
    }

    function balanceOf(address who) view public returns (uint256 value) {
        return balanceOf[who];
    }

    function allowance(address owner, address spender) view public returns (uint256 _allowance) {
        return allowance[owner][spender];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] >= _value);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] = sub(balanceOf[_from], _value);
        balanceOf[_to] = add(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) noStopped public returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) noStopped public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) noStopped public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_spender]);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) noStopped public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_spender]);
        allowance[msg.sender][_spender] = add(allowance[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) noStopped public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_spender]);
        uint256 oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function freezeAccount(address target, bool freeze) noStopped onlyOwner public returns (bool success) {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
        return true;
    }

    function burn(uint256 _value) noStopped onlyOwner public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
        totalSupply = sub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }

}