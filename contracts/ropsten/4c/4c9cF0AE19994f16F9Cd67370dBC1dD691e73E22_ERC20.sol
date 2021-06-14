pragma solidity 0.8.0;

contract ERC20 {
  string public name;
  string public symbol;
  uint256 public totalSupply;
  uint8 public decimals = 18;

  mapping(address => uint256) public balances;

  constructor(string memory _name, string memory _symbol, uint256 _totalSupply) public {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;

    balances[msg.sender] = _totalSupply;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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