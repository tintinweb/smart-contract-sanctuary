/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
//BEP20
contract HeroCats{
    string constant _name = "FFV Hero Cats 1";
    string constant _symbol = "FFVHCC1";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 29000000*(10**_decimals);
    //Ten token
    function name() public pure returns(string memory){
        return _name;
    }
    //Ky hieu
    function symbol() public pure returns(string memory){
        return _symbol;
    }
    //Do chia nho toi da
    function decimals() public pure returns(uint8){
        return _decimals;
    }
    //Tong cung
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }
    //Anh xa so du cua tai khoan
    mapping(address => uint) public _balances;
    //Anh xa dia chi so huu token va dia chi duoc uy thac mapping(sohuu=>uythac)
    mapping(address => mapping(address => uint)) public _allowances;
    //khoi tao event Transfer
    event Transfer(address indexed _from, address indexed _to, uint _amount);
    //khoi tao event approve
    event Approval(address indexed _owner, address indexed _spender, uint _amount);
    //Khoi tao contract
    constructor(){
        //thiet lap tong cung cho dia chi trien khai smart contract
        _balances[msg.sender] = _totalSupply;
    }
    //lay so du cua dia chi nao do
    function balanceOf(address _owner) public view returns(uint){
        return _balances[_owner];
    }
    //Transfer token tu dia chi khoi tao contract toi mot dia chi khac
    function transfer(address _to, uint _amount) public returns(bool){
        require(balanceOf(msg.sender) >= _amount, "Balance is to low");
        _balances[_to] += _amount;
        _balances[msg.sender] -= _amount;
        //emit event Transfer
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    //uy thac transfer cho mot dia chi khac
    function allowance(address _owner, address _spender) public view returns(uint256){
        return _allowances[_owner][_spender];
    }
    //Can phai Approve(Chap thuan viec uy thac) va Allowance(Cho phep chi duoc transfer so luong token nao do)
    function approve(address _spender, uint _amount) public returns(bool){
        //gan gia tri cho phep transfer
        _allowances[msg.sender][_spender] = _amount;
        //Thuc thi event Approval
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    //Thuc hien transfer
    function transferFrom(address _from, address _to, uint _amount) public returns(bool){
        //Kiem tra so du tai khoan
        require(balanceOf(_from) >= _amount, "Balance to low");
        require(_allowances[_from][msg.sender] >= _amount, "Allowance to low");
        _balances[_to] += _amount;
        _balances[_from] -= _amount; 
        emit Transfer(_from, _to, _amount);
        return true;
    }
}