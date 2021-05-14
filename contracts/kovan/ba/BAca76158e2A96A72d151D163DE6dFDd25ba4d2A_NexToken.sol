/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender  , uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract NexToken is IERC20 {

    address public creator;

    string public constant name = "NexToken";
    string public constant symbol = "NXTN";
    uint8 public constant decimals = 18;

    mapping(address => uint) balances;

    mapping(address => mapping (address => uint)) allowed;
    
    uint _totalSupply;

    using SafeMath for uint;

    constructor(uint total) {
        creator = msg.sender;
        _totalSupply = total;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view override returns (uint) {
	    return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint) {
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public view override returns (uint) {
        return allowed[owner][delegate];
    }

    function approve(address delegate, uint numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);

        return true;
    }

    function transfer(address receiver, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);

        return true;
    }

    function transferFrom(address owner, address buyer, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);

        return true;
    }

    function mint(uint amount) public {
        require(msg.sender == creator, "ERC20: only token creator is able to mint");

        _totalSupply += amount;
        balances[creator] += amount;
        emit Transfer(address(0), creator, amount);
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