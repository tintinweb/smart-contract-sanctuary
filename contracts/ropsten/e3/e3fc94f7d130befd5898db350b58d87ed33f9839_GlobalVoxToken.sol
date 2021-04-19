/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract ERC20{
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address _owner) virtual public view returns (uint256);
    function transfer(address _to, uint256 _value) virtual public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool);
    function approve(address _spender, uint256 _value) virtual public returns (bool);
    function allowance(address _owner, address _spender) virtual public view returns (uint256);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract safeMath{
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256){
        uint c = a+b;
        require(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256){
        require(a >= b);
        uint c = a-b;
        return c;
    }
}

contract GlobalVoxToken is ERC20, safeMath{
    string Name;
    string Symbol;
    uint8 Decimals;
    uint256 totalsupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    constructor(){
        Name = "GlobalVoxToken";
        Symbol = "GVT";
        Decimals = 2;  //token denomination upto 2d.p.
        totalsupply = 100000000; //1 million tokens
        balances[msg.sender] = totalsupply;
        emit Transfer(address(0), msg.sender, totalsupply);
    }
    function name() public override view returns (string memory){
        return Name;
    }
    function symbol() public override view returns (string memory){
        return Symbol;
    }
    function decimals() public override view returns (uint8){
        return Decimals;
    }
    function totalSupply() public override view returns (uint256){
        return totalsupply;
    }
    function balanceOf(address _owner) public override view returns (uint256){
        return balances[_owner]; 
    }
    function transfer(address _to, uint256 _value) public override returns (bool){
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public override returns (bool){
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public override view returns (uint256){
        return allowances[_owner][_spender];
    }
    
}