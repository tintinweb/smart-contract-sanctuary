/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.8.6;


contract Eco {
    
    string public name = 'ECCO coin';
    string public symbol = 'ECCO';
    uint8 public decimal = 18;
    uint256 private _totalsupply = 1000000000000000000000000;
    mapping(address => uint256) public balanceOf;
    mapping(address =>mapping(address => uint256)) allowances;
    address owner;
    
    constructor(){
        owner = msg.sender;
        balanceOf[owner] =1000000000000000000000000;
    }
    
    event transfered(address _to, address _from, uint256 _value);
    event approved(address _owner, address _spender, uint256 _value);
    
    
    function totalsupply()public view returns(uint256 value){
        return _totalsupply;
    }
    
    function transfer(address _to, uint256 _value)public returns(bool sucess){
        require(owner == msg.sender,'You do not have authorisation');
        require(balanceOf[msg.sender] >= _value,'issufucient funds');
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit transfered(_to,msg.sender, _value);
        return true;
    }
    
    
    function tranferFrom(address _to, address _from, uint256 _value) public returns(bool sucess){
        
        uint256 _allowance =  allowances[_from][_to] ;
        // check if there is enough funds
        require(balanceOf[_from] >= balanceOf[_to],'not enough balance');
    
        // check allowance
        require(_allowance >=  _value,'not approved');
        
        // trranfer funds
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        if(_allowance > _totalsupply){
            allowances[_from][msg.sender] -= _value;
        }
        
        emit transfered(_to,_from, _value);
        return true;
        
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
         
         allowances[msg.sender][_spender] = _value;
         emit approved(msg.sender, _spender, _value);
         return true;
    }
    
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        
        return  allowances[_owner][_spender];
        
    }
    
    
    
}