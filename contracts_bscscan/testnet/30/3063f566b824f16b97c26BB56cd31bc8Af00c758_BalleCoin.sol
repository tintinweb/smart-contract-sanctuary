/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BalleCoin{
    address public onwer;
    mapping (address => uint) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances; 
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(string memory name_ , string memory symbol_){
        onwer = msg.sender;
        _name = name_;
        _symbol = symbol_;
    }
    function mint(address receiver, uint amount) public onlyYou{
        require(amount < 1e60);
        _balances[receiver] += amount;
        _totalSupply += amount;
    }
    modifier onlyYou(){
        require(msg.sender == onwer , "Only you");
        _;
    }
    function totalSupply()public view returns (uint256){
        return _totalSupply;
    }
    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function balanceOf(address adr) public view onlyYou returns (uint256) {
       return _balances[adr];
    }
    //转钱给别人
    function transfer(address receiver , uint8 amount) public onlyYou {
        require(_balances[msg.sender] >= amount , "no money");
        _balances[msg.sender] -= amount;
        _balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
    }

    function transferFrom(address sender,address receiver , uint amount) public onlyYou returns (bool){
        _allowances[sender][receiver] = amount;
        _balances[sender] -= amount;
        return true;
    }

    function approve(address spender, uint256 amount) public onlyYou returns (bool){
        _allowances[msg.sender][spender] = amount;
        _balances[msg.sender] -= amount;
        emit Approval(msg.sender,spender,amount);

        return true;
    }
}