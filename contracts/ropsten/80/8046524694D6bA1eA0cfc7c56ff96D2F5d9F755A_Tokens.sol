pragma solidity ^0.8.6;

import {SimpleMath} from './math.sol';    //для add и sub в transfer,transferFrom

interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
    function totalSupply() external pure returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address to, uint256 tokens) external returns (bool);
	function allowance(address tokenOwner, address spender) external view returns (uint256);
	function approve(address spender, uint256 tokens) external returns (bool);
	function transferFrom(address from, address to, uint256 tokens) external returns (bool);
}

contract Tokens is IERC20 {       //интерфейс по рекомендации спецификации
    using SimpleMath for uint256;

    address payable public owner;
    string public _name;            
    string public _symbol;
    uint256 public constant _totalSupply = 1000; 

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances; //разрешения на передачу 
                        //токенов, от владельца к другому адресу

    constructor(string memory name_, string memory symbol_) {
        owner = payable(msg.sender);
        _name = name_;
        _symbol = symbol_;
        balances[msg.sender] = _totalSupply;    //все токены у создателя, потом - распределяет
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    //случайные деньги - к создателю контракта
    receive () external payable {    
        owner.call{value: msg.value}; 
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public override pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }
    
     ///от `msg.sender` отсылаются токены, вызывается tokenOwner
    function transfer(address to, uint256 tokens) external override returns (bool) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    ///если tokenOwner согласен с пересылкой токенов, то происходит их пересылка конкретному адресу
    ///вызывается не владельцем токена, а тем, у кого есть разрешение на пересылку
    function transferFrom(
        address from,           ///tokenOwner
        address to,
        uint256 tokens
    ) public override returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender];
        require(currentAllowance >= tokens && balances[from] >= tokens);
        balances[from] = balances[from].sub(tokens);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool) {
        require(spender != address(0) && tokens <= _totalSupply);        
        allowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) external override view returns (uint256) {
        return allowances[tokenOwner][spender];
    }
    
    ///extra functions, вызываются tokenOwner
    function increaseAllowance(address spender, uint256 addTokens) external returns (bool) {
        approve(spender, allowances[msg.sender][spender] + addTokens);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subTokens) external  returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subTokens, "ERC20: decreased allowance below zero");
        approve(spender, currentAllowance - subTokens);
        return true;
    }
}

pragma solidity ^0.8.6;

library SimpleMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) revert("something went wrong");
            return c;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) revert("amount should be less than balances[sender]");
            return (a - b);
        }
    }
}

{
  "optimizer": {
    "enabled": false,
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
  }
}