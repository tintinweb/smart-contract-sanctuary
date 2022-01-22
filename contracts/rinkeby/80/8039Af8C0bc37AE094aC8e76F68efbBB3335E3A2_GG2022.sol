/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GG2022{
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    uint private _totalSupply;
    mapping(address=>uint) private _balances;
    mapping(address=>mapping(address=> uint)) private _allowances;
    address _admin;
    constructor(){
        _admin=msg.sender;
    }

    function name() public pure returns (string memory) {
        return "Z2Y Coin";
    }
    function symbol() public pure returns (string memory){
        return "Z2Y";
    }
    function decimals() public pure returns (uint8){
        return 0;
    }
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address owner) public view returns (uint256 balance){
        return _balances[owner];
    }

    function transfer(address to, uint256 amount) public returns (bool success){
        address from = msg.sender;
        require(amount <= _balances[from],"transfer amount exceeds balance");
        require(to != address(0),"transfer to zero address");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer (from,to,amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining){
        return _allowances[owner][spender];

    }
    
    function approve(address spender, uint256 amount) public returns (bool success){
        require(spender != address(0),"approve spender zero address");
        _allowances[msg.sender][spender]=amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success){
        require(from != address(0),"transfer from zero address");
        require(to != address(0),"transfer to zero address");
        require(amount<=_balances[from],"transfer amount exceeds balance");
        if(from != msg.sender){
            uint allownaceAmount=_allowances[from][msg.sender];
            require(amount <= allownaceAmount,"trasnfer amount exceeds allowance");
            _allowances[from][msg.sender]=allownaceAmount-amount;
            uint remaining=allownaceAmount-amount;
            emit Approval(from,msg.sender,remaining);
        }
        _balances[from]-=amount;
        _balances[to]+=amount;
        emit Transfer (from,to,amount);
        return true;
    }

    function mint(address to, uint amount)public{
        require(msg.sender == _admin,"not authorized");
        require(to != address(0),"transfer to zero address");
        _balances[to] = _balances[to] + amount;
        _totalSupply=_totalSupply+amount;
        address from = address(0);
        emit Transfer(from,to,amount);
    }

    function burn(address from,uint amount)public{
        require(msg.sender==_admin,"not authorized");
        require(from !=address(0),"burn from zero address");
        require(amount<=_balances[from],"burn amount exceeds balance");
        _balances[from]-=amount;
        _totalSupply-=amount;
        emit Transfer(from,address(0),amount);
    }
}