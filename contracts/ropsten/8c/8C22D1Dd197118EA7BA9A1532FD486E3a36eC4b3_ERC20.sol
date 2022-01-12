/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
  function name() external view returns (string memory);

  function decimals() external view returns (uint);

  function symbol() external view returns (string memory);

  function totalSupply() external view returns (uint);

  function balanceOf(address who) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function transfer(address to, uint value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20 is IERC20{

    string _name;
    string _symbol;
    uint _totalSupply;
    uint _decimals = 12;
    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) allowances;


    constructor (string memory name_,string memory symbol_, uint totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
    }

    function name() external view returns(string memory) {
        return _name;
    }
    function decimals() external view returns(uint) {
        return _decimals;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function totalSupply() external view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address who) external view returns (uint256){
        return balances[who];
    }

    function allowance(address owner, address spender) external view returns (uint){
        return allowances[owner][spender];
    }

    function transfer(address to, uint value) external returns (bool){
        require(value > 0 ,"ERROR: VALUE IS ZERO!");
        require(balances[msg.sender] >= value ,"ERROR: INSUFFICIENT BALANCE!");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender,to,value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool){
        require(value > 0 ,"ERROR: VALUE IS ZERO!");
        allowances[msg.sender][spender]+=value;
        emit Approval(msg.sender,spender,value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool){
        require(balances[from] >= value , "ERROR: INSUFFICIENT BALANCE!");
        require(value > 0 ,"ERROR: VALUE IS ZERO!");
        require(allowances[from][msg.sender] >= value ,"ERROR: NOT ALLOWED!");
        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;
        emit Transfer(from,to,value);
        return true;
    }

}