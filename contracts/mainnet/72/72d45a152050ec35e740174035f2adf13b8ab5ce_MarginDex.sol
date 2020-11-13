pragma solidity ^0.4.4;

contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract MarginDex is StandardToken  {
    string public name;                  
    uint8 public decimals;               
    string public symbol;                
    address public contractOwner;  
    uint256 public tokenPerOneETH; // how many token = 1 ethereum
    uint256 public timeUnlockToken; // lock all token  5 years
    uint256 public lockToken;
    constructor() public {
        totalSupply = 100000000000000000000000000;    
        lockToken = 61000000000000000000000000;
        name = "MarginDex";                                   
        decimals = 18;                            
        symbol = "DMAX";    
        tokenPerOneETH = 4000;
        timeUnlockToken =  now +  5 years; // Lock 5 year
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
        balances[address(this)] = totalSupply;
        Transfer(address(0),address(this), totalSupply);
    }
    
    function () public  payable {
        require(msg.value > 0);
        if(msg.value > 0){
        StandardToken(address(this)).transfer(msg.sender , msg.value * tokenPerOneETH);
        }
    }
    function  ownerWithdrawToken(address _addr , uint256 _value) public returns (bool ){
       require(msg.sender == contractOwner);
       _value = _value * 1000000000000000000;
       if(msg.sender == contractOwner &&  now >= timeUnlockToken){
          StandardToken(address(this)).transfer(_addr , _value );
            return true;         
       }else{
        if(msg.sender == contractOwner){
            if((balanceOf(address(this))  - _value) >=  lockToken  ){
             StandardToken(address(this)).transfer(_addr , _value );
               return true;
            }else{
                return false;
            }
        }else{
            return false;
        }   
           
       }
       
    } 
    function ownerWithdrawETH() public returns (bool ){
        require(msg.sender == contractOwner );
        if(msg.sender == contractOwner ){
            uint256 bal = address(this).balance;
            address(contractOwner).transfer(bal);   
            return true;
        }else{
            return false;
        }
    }    
    function setTokenPerETH(uint256 _value) public returns (bool ){
        require(msg.sender == contractOwner );
        if(msg.sender == contractOwner){
        tokenPerOneETH = _value;  
        return true;
        }else{
        return false;
        }
    }
}