/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function transfer(address to, uint amount) external returns (bool);
    
    function allowance(address account, address from) external view returns (uint256);
    function approve(address from, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed account, address indexed from, uint amount);
}

contract Token is IERC20 {
    string public name;
    string public symbol;
    uint public decimals;
    uint private total_supply;
    uint private max_total_supply;
    address public founder;
    mapping(address => uint) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping (address => bool)) private _is_approved;
    
    modifier onlyFounder() {
        require(msg.sender == founder);
        _;
    }

    constructor(uint256 _initial_supply) {
        name = "My Finance";
        symbol = "MYFI";
        decimals = 18;
        total_supply = _initial_supply * 1000000000000000000;
        max_total_supply = 80000 * 1000000000000000000;
        founder = msg.sender;
        balances[founder] = total_supply;
    }
    
    function _approve(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(recipient != address(0), "ERC20: approve to the zero address");

        _is_approved[sender][recipient] = true;
        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function totalSupply() override public view returns(uint) {
        return total_supply;
    }

    function maxTotalSupply() public view returns(uint) {
        return max_total_supply;
    }

    function balanceOf(address account) override public view returns (uint balance) {
        return balances[account];
    }
    
    function allowance(address _account, address _contract) override public view returns (uint256) {
        return _allowances[_account][_contract];
    }
    
    function isApproved(address _account, address _contract) public view returns (bool) {
        return _is_approved[_account][_contract];
    }
    
    function approve(address _contract, uint _amount) override public returns (bool) {
        _approve(msg.sender, _contract, _amount);
        return true;
    }

    function transfer(address recipient, uint amount) override public returns (bool) {
        require(balances[msg.sender] >= amount && amount > 0);
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _amount) override public returns (bool) {
        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, _allowances[_from][msg.sender] - _amount);
        return true;
    }
    
    function mint(address to, uint256 amount) public onlyFounder {
        require(total_supply + amount < max_total_supply);
        total_supply = total_supply + amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
    }
}