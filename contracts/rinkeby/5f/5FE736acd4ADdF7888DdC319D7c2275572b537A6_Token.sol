/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
}

interface ERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract Token is ERC20 {
    
    using SafeMath for uint256;
    
    address public owner;
    mapping(address => uint256) balances;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public tsupply;
    mapping(address => mapping(address => uint256)) allowed;

    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        tsupply = _supply * 10**uint256(decimals);
        owner = msg.sender;
        balances[owner] = tsupply;
        emit Transfer(address(0), owner, tsupply);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Prohibited");
        _;
    }

    function totalSupply() public override view returns (uint256) {
        return tsupply;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 bal) {
        bal = balances[tokenOwner];
    }

    function transfer(address _to, uint256 amount) public override returns (bool success) {
        if(balances[msg.sender] >= amount) {
            balances[msg.sender] = balances[msg.sender].sub(amount);
            balances[_to] = balances[_to].add(amount);
            emit Transfer(msg.sender, _to, amount);
            success = true;
        } else {
            success = false;
        }
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        remaining = allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool success) {
        if(balances[msg.sender] >= amount) {
            allowed[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            success = true;
        } else {
            success = false;
        }
    }

    function transferFrom(address _from, address _to, uint256 amount) public override returns (bool success) {
        if(balances[_from] >= amount && allowed[_from][msg.sender] >= amount) {
            balances[_from] = balances[_from].sub(amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(amount);
            balances[_to] = balances[_to].add(amount);
            emit Transfer(_from, _to, amount);
            success = true;
        } else {
            success = false;
        }
    }

}