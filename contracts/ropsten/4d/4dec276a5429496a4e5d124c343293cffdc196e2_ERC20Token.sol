/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint);
    function allowance(address tokenOwner, address spender) public view returns (uint);
    function transfer(address to, uint tokens) public returns (bool);
    function approve(address spender, uint tokens)  public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}

library SafeMath {
        function sub(uint256 a, uint256 b) internal pure returns (uint c) {
            require(b <= a);
            c = a - b;
        }
        function add(uint256 a, uint256 b) internal pure returns (uint c) {
            c = a + b;
            require(c >= a);            
        }
    }
    
contract ERC20Token is ERC20Interface{
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;
    uint256 public totalSupply_;

    constructor() public {
        name = "SIT728Token";
        symbol = "SST";
        decimals = 18;
        totalSupply_ = 100000000000000000000000000;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function totalSupply() public view returns (uint) {
        return totalSupply_ - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool success) {
        // require(numTokens <= balances[msg.sender]);
        balances[receiver] = balances[receiver].add(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool success) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint remaining) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool success) {
        // require(numTokens <= balances[owner]);
        // require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

  
}