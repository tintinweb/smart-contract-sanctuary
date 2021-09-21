/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ERC20Interface{
   // function totalsupply() external view returns(uint);
    
    ///function balanceOf(address tokenOwner) external view returns(uint256 balance);
    
   // function allowance(address tokenOwner, address spender) external view returns(uint256 remaining);
    
    function transfer(address to, uint256 tokens) external returns (bool success);
    
    function approve(address _spender, uint256 _value) external returns(bool success);
    
    function transferFrom(address  _from, address _to, uint256 _value) external returns(bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    
    event Approve (address indexed _Owner, address indexed _spender, uint256 _value);
}

contract Mytoken is ERC20Interface{
    string public name;
    string public symbol;
    uint public TotalSupply;
    
    mapping (address => uint256) public Balanceof;
    mapping(address => mapping(address => uint256)) private allowance;
    
    constructor(uint256 _initialsupply){
        name = "snapper";
        symbol = "SFT";
        Balanceof[msg.sender] = _initialsupply;
        TotalSupply = _initialsupply;
    }
    function transfer (address _to, uint256 _value) public override returns(bool success){
        require(Balanceof [msg.sender]>=_value);
        Balanceof [msg.sender] = _value;
        Balanceof [_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function approve(address _spender, uint256 _value)public override returns(bool success){
        allowance[msg.sender][_spender]=_value;
        emit Approve(msg.sender,_spender,_value);
        return true;}
        
    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool success){
        require(_value <= Balanceof[_from]); //CHECKING IF OWNER ENOUGH Balance
        require(_value<=allowance[_from][msg.sender]);
        allowance[_from][msg.sender]-=_value;
        Balanceof[_from]-=_value;
        Balanceof[_to]+=_value;
        emit Transfer(_from, _to, _value);
        return true;
        
        
    }
}