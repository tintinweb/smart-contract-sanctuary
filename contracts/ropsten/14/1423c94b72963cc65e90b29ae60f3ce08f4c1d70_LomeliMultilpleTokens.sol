pragma solidity ^0.4.24;

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract LomeliMultilpleTokens {
    address public owner;
  
    modifier onlyOwner {
		require(owner == msg.sender);
        _;
	}

    function LomeliMultilpleTokens() {
        owner = msg.sender;
    }

    function withdraw(address token, address para , uint256 amount) onlyOwner public {
        Token(token).transfer(para, amount);
    }
  
}