/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity^0.5.3;

interface NERC20{
    //totalSupply() - return initial quantity of the NToken
    function totalSupply()external view returns(uint256);
    // balanceOf() - return the number of token a particular account have
    function balanceOf(address _address) external view returns(uint256);
    //transfer - transfer Ntoken from one account to another account
    function transfer(address _to , uint256 _value)external  returns(bool success);
    // approve - giving  approval to spender use the Ntoken 
    function approve(address _spender , uint256 _value)external  returns(bool success);
    // transferFrom - Onced Apporved  used to transfer all or particular allowed Ntoken
    //function transferFrom(address _approver, address _spender, uint256 _value) external view returns(bool success);
    // allowance - returns remaining number of approved Ntoken 
    function allowance(address _owner,address _spender) external  returns(uint256 remaining);
    
    // Transfer() used to log the transfer() activity 
    event Transfer(address indexed from , address indexed to , uint256 _value);
    // Approval() used to log the approve() activity
    event Approval(address indexed _owner,address indexed _spender, uint256 _value);
    
}

contract NToken is NERC20{
    mapping(address => uint256) public _balance;
    
    // 1111 => 2222 => 10
    // 1111 => 3333 => 50
    mapping(address => mapping(address=>uint256)) _allowed;
    
    // name symbol decimal
    string public names = 'NToken';
    string public symbol = 'NTK';
    uint256 public decimal = 0;
    
    // Initial totalSupply
     uint256 public _totalSupply;
     
     // Contract Creater
     address public owner;
    
    constructor()public{
        owner = msg.sender;
        _totalSupply = 5000;
        _balance[owner] = _totalSupply;
        
    }
    
    function totalSupply()external view returns(uint256){
        return _totalSupply;
    }
    
    function balanceOf(address _address) external view returns(uint256){
        return _balance[_address];
    }
    
    function transfer(address _to , uint256 _value)external  returns(bool success){
        require(_value> 0 &&  _balance[owner] >= _value);
        _balance[_to] += _value;
        _balance[msg.sender] -=_value;
        emit Transfer(owner,_to,_value);
        return true;
    }
    
    function approve(address _spender, uint _value)external returns(bool success)
    {
        require(_value> 0 &&  _balance[owner] >= _value);
        _allowed[msg.sender][_spender] = _value;
        
        emit Approval(owner,_spender,_value);
        return true;
    }
    
    function transferFrom(address _from , address _to , uint _value) external returns(bool success){
        require(_value> 0 &&  _balance[owner] >= _value && _allowed[_from][_to]>=_value);
        _balance[_from] += _value;
        _balance[_to] -= _value;
        _allowed[_from][_to] -= _value;
        return true;
    }
    
    function allowance(address _owner,address _spender) external  returns(uint256 remaining){
        return _allowed[_owner][_spender];
    }
        
}