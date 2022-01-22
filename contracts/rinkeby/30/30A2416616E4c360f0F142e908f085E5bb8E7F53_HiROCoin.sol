/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HiROCoin {
    event transfers(address indexed from,address indexed to,uint256 _value);
    event approval(address indexed owner, address indexed spender , uint256 amount);

    uint private _totalSupply;
    
    mapping(address => uint) _balances;

    mapping(address => mapping(address => uint)) private _allowance;

    address _admin;

    constructor() {
        _admin = msg.sender;
    }
    
    function name() public pure returns (string memory){
        return "HiROCoin";
    }
    
    function symbol() public pure returns (string memory){
        return "HRC";
    }
    
    function decimals() public pure returns (uint8){
        return 0;
    }
    
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        address from = msg.sender;
        require(_value <= _balances[from], "transfer amount exceeds balance");
        require(_to != address(0), "transfer to zero address");
        
        _balances[from] -= _value;
        _balances[_to] += _value;

        emit transfers(from,_to,_value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success){
        require(_from != address(0), "transfer from zero address");
        require(_to != address(0), "transfer to zero address");
        require(_amount <= _balances[_from], "transfer amount exceed balance");

        if(_from != msg.sender){
            uint allowanceAmount = _allowance[_from][msg.sender];
            require(_amount <= allowanceAmount, "transfer amount exceeds allownace");
            uint remaining = allowanceAmount - _amount;
            _allowance[_from][msg.sender] = remaining;
            emit approval(_from,msg.sender,remaining);
        }
        
        _balances[_from] -= _amount;
        _balances[_to] += _amount;
        
        emit transfers(_from,_to,_amount);
        return true;
    }
    
    function mint(address _to , uint _value) public {
        require(msg.sender == _admin, "not authorized");
        require(_to != address(0), "transfer to zero address");

        _balances[_to] += _value;
        _totalSupply += _value;

        address from = address(0);

        emit transfers(from,_to,_value);
    }


    function allowance(address owner, address spender) public view returns (uint256 remaining){
        return _allowance[owner][spender];
    }


    function approve(address spender, uint256 amount) public returns (bool success){

        require(spender != address(0),"approve spender zero address");

        _allowance[msg.sender][spender] = amount;
        emit approval(msg.sender ,spender,amount);

        return true;
    }

    function burn(address from,uint amount) public{
        require(msg.sender == _admin, "not authorized");
        require(from != address(0), "burn to zero address");
        require(amount <= _balances[from], "burn amount exceed balance");
        
        _balances[from] -= amount;
        _totalSupply -= amount;

        emit transfers(from,address(0),amount);
    }

}