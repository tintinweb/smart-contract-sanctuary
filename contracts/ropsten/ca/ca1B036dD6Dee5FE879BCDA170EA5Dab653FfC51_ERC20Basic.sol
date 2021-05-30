// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IERC20 {
function totalSupply() external view returns (uint);
function balanceOf(address account) external view returns (uint);
function allowance(address owner, address spender) external view returns (uint);
function transfer(address recipient, uint amount) external returns (bool);
function approve(address spender, uint amount) external returns (bool);
function transferFrom(address sender, address recipient, uint amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint value);
event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20Basic is IERC20 {
    using SafeMath for uint;
    string public name = "ERC20Basic";
    string public symbol = "ERC";
    uint8 public decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint totalSupply_;

    constructor(uint total) {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() external view override returns (uint) {
        return totalSupply_;
    }

    function balanceOf(address account) external view override returns (uint) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        require(amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        allowed[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint) {
        return allowed[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        require(amount <= balances[sender]);
        require(amount <= allowed[sender][msg.sender]);

        balances[sender] = balances[sender].sub(amount);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }
}

library SafeMath {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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