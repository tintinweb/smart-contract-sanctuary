pragma solidity ^0.5.0;


contract TokenInterface {
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function burn(uint256 _value) public returns (bool);
    function burnFrom(address _from, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function balanceOf(address _owner) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address _from, address _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract TestERC20 is TokenInterface {
    string public name = "Republic Token";
    string public symbol = "REN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000 * 10 ** uint256(decimals);

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        return _burn(msg.sender, _value);
    }

    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return _burn(_from, _value);
    }

    // Approve spender from owner's account
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Return balance
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Return allowance
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // Burn amount from account (may require approval)
    function _burn(address _from, uint256 _value) internal returns (bool) {
        require(balances[_from] >= _value && _value > 0);
        balances[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    // Transfer amount from one account to another (may require approval)
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0) && balances[_from] >= _value && _value > 0);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}