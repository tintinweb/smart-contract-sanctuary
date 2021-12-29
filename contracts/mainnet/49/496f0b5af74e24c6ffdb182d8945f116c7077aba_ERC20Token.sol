/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

interface ERC20 {
    // Get the total token supply
    function totalSupply() view external returns (uint256);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) view external returns (uint256);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) external returns (bool success);
 
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) external returns (bool);
 
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) view external returns (uint256);
 
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Token {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event DepositTo(address indexed to, bytes8 id, uint256 amount);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor() public{

        name = "The Myth Of America";
        symbol = "GUMP";
        decimals = 0;
        
        totalSupply = 720000000000 * 10 ** uint256(decimals);
	    balances[msg.sender] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender], "Not Enough Tokens");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner], "Not Enough Tokens");
        require(numTokens <= allowed[owner][msg.sender], "Not Enough Tokens");

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function checksumMatch(bytes8 id) internal view returns (bool) {
        bytes32 chkhash = keccak256(
            abi.encodePacked(address(this), bytes5(id))
        );
        bytes3 chkh = bytes3(chkhash);
        bytes3 chki = bytes3(bytes8(uint64(id) << 40));
        return chkh == chki;
    }

    // deposit to target address with id
    function depositTo(address to, uint256 amount, bytes8 id) external {
        require(checksumMatch(id), 'checksum mismatch');
        require(transfer(to, amount), 'Could not forward funds');
        emit DepositTo(to, id, amount);
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}