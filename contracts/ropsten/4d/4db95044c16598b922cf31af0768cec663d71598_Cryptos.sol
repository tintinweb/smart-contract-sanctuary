/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;


interface ERC20Interface {
    
function totalSupply() external view returns (uint256);
function balanceOf(address _tokenowner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);

function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
function allowance(address _tokenowner, address _spender) external view returns (uint256 remaining);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    
}

contract Cryptos is ERC20Interface{
    string public name = "Tester";
    string public symbol = "TSR";
    uint public decimal = 0; //18;
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances; //stores individual balances
    
    
    mapping(address => mapping(address => uint)) allowed; //
    
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    function balanceOf(address _tokenowner) public view override returns (uint256 balance){
        return balances[_tokenowner];
    }
    
    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(balances[msg.sender] >= _value,"You dont have enough tokens to Transfer!");
        
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function allowance(address _tokenowner, address _spender) view public override returns (uint256 remaining){
        
    return allowed[_tokenowner][_spender];      
            
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool success){
        require(balances[msg.sender] >= _value, "No Enough Tokens for Approval");
        require(_value > 0);
        
        allowed[msg.sender][_spender] += _value;
        //balances[msg.sender] -= _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(allowed[_from][_to] >= _value);
        require(balances[_from] >= _value);
        require(_value > 0);
        
        balances[_from] -= _value;
        balances[_to] += _value;
        
        allowed[_from][_to] -= _value;
        

        
        return true;
        
        
    }


}