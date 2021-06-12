// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract BasicToken {
    uint256 public totalSupply;
    bool public allowTransfer;

    function balanceOf(address _owner) public virtual returns (uint256 balance);
    function transfer(address payable _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address payable _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public virtual returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is BasicToken {
    function transfer(address payable _to, uint256 _value) public override returns (bool success) {
        require(allowTransfer, "Unauthorized transfer");
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(address _from, address payable _to, uint256 _value) public override returns (bool success) {
        require(allowTransfer, "Unauthorized");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "Insufficient or Uauthorized");
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        balance = balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        require(allowTransfer, "Unauthorized");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
      remaining = allowed[_owner][_spender];
    }

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
}

contract Token is StandardToken {
    string public name = "TEMPLATE ERC20 TOKEN";
    string public symbol = "TEMPLATE";
    string public version = "TEMPLATE 0.1";
    uint public constant TOTAL_SUPPLY = 5000000000000000000000000;
    address payable public mintableAddress;
    uint8 public decimals = 18;
    string public generator = "https://pleasemarkdarkly.github.io/";

    event Log(bool success, bytes data, address _from, uint amount);
    
    constructor(address payable saleAddress,
    string memory _name, 
    string memory _symbol, 
    string memory _version) {
        balances[msg.sender] = 0;
        totalSupply = 0;
        name = _name;
        symbol = _symbol;
        version = _version;
        decimals = decimals;
        mintableAddress = saleAddress;
        allowTransfer = true;
        createTokens();
    }

    function createTokens() internal {
        uint256 total = TOTAL_SUPPLY;
        balances[address(this)] = total;
        totalSupply = total;
    }

    function changeTransfer(bool allowed) external {
        require(msg.sender == mintableAddress, "Unauthorized");
        allowTransfer = allowed;
    }

    function mintToken(address payable to, uint256 amount) external returns (bool success) {
        require(msg.sender == mintableAddress, "Unauthorized");
        require(balances[address(this)] >= amount, "Insufficent funds");
        balances[address(this)] -= amount;
        balances[to] += amount;
        emit Transfer(address(this), to, amount);
        success = true;
    }

    function approveAndCall(address payable _spender, uint256 _value) public returns (bool _success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);        
        // solhint-disable-next-line
        (bool success, bytes memory data) = _spender.call{value: _value}(
            abi.encodeWithSignature("receiveApproval(address,uint256,address)", msg.sender, _value, address(this))
        );
        emit Log(success, data, msg.sender, _value);
        _success = success;
    }
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}