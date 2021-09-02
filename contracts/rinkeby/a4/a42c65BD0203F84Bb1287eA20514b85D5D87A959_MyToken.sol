pragma solidity ^0.8.7;

contract MyToken {

    string public name = "Very Bad Token";
    string public symbol = "VBT";
    uint8 public decimals = 2;
    mapping (address => uint256) public balances;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function balanceOf(address owner) public view returns (uint256) {
    	return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
    	balances[msg.sender] -= value;
    	balances[to] += value;
    	emit Transfer(msg.sender, to, value); 
    }
    
    function _mint(address account, uint256 value) public {
    	totalSupply += value;
    	balances[account] += value;
    	emit Transfer(address(0), account, value);
    }

}

// Function transfer SHOULD throw if the message caller’s account balance does not have enough tokens to spend.(EIP-20 token standart)
// Function mint shouldn't be public(?)

{
  "evmVersion": "london",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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