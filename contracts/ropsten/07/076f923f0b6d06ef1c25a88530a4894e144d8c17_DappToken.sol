/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity ^0.8.0;

interface ERC20Interface{
//function name() public view returns (string);
//function symbol() public view returns (string);
//function decimals() external view returns (uint8);
//function totalSupply() external view returns (uint256);
//function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value)  external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
//function allowance(address _owner, address _spender) external view returns (uint256 remaining);


event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//ERC20 token
 contract DappToken is ERC20Interface{
    string public name;
    string public symbol;
    uint256 public totalSupply;
    
    mapping(address=>uint256) public BalanceOf;
    mapping(address=>mapping(address=>uint256)) public Allowance;
    
    constructor(uint256 _initialSupply){
        name = "ck token";
        symbol = "CKT";
        totalSupply = _initialSupply;
    }
    
    function transfer(address _to, uint256 _value)  public override returns (bool success){
        require(BalanceOf[msg.sender]>= _value);
        
        BalanceOf[msg.sender] -= _value;
        BalanceOf[_to] += _value;
        
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        Allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender,_spender,_value);
        return true;
    }


function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){   
    require(_value<=BalanceOf[_from]);
    require(_value<= Allowance[_from][msg.sender]);
    
    Allowance[_from][msg.sender] -= _value;
    BalanceOf[_from] -= _value;
    BalanceOf[_to] += _value;
    
    emit Transfer(_from,_to,_value);
    
    return true;
    
}

    
}