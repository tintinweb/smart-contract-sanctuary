pragma solidity ^0.4.17;
//import &#39;./IERC20.sol&#39;;

//contract FuncToken is IERC20 {

 interface IERC20 {
    function totalSupply() constant returns(uint256 total);
    function balanceOf(address _owner)constant returns(uint256 balance);
    function transfer(address to, uint256 value)returns(bool success);
    function transferFrom(address from,address to,uint256 _value) returns(bool success);
    function approve(address spender,uint256 value)returns(bool success);
    function allowance(address owner,address spender)constant returns(uint256 remaining);

    event Transfer(address indexed from,address indexed to,uint256 _value);
    event Approval(address indexed owner,address indexed spender,uint256 _value);
}

 contract PerlToken{ 
    uint public constant _totalSupply=100000;
    string public constant symbol=&quot;perl&quot;;
    string public constant name=&quot;PERL Token&quot;;
    uint8 public constant decimals=3;

    mapping(address=>uint256) balances;
    mapping(address=>mapping(address =>uint256)) allowed;

    function PerlToken(){
        balances[msg.sender]=_totalSupply;
    }
    function totalSupply() constant returns(uint256 total){

        return _totalSupply;
    }
    function balanceOf(address _owner)constant returns(uint256 balance){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value)returns(bool success){
        require(
            balances[msg.sender]>=_value && _value>0
            );
        balances[msg.sender] -=_value;
        balances[_to] +=+_value;
        Transfer(msg.sender,_to,_value);
        return true;

    }
    function transferFrom(address _from,address _to,uint256 _value) returns(bool success){
        require(
            allowed[_from][msg.sender]>=_value
            && balances[_from]>=_value
            && _value>0
            );

            balances[_from]-=_value;
            balances[_to]+= _value;
            allowed[_from][msg.sender]-=_value;
            Transfer(_from,_to,_value);
            return true;
    }
    function approve(address _spender,uint256 _value)returns(bool success){
        allowed[msg.sender][_spender]=_value;
        Approval(msg.sender,_spender,_value);
        return true;

    }
    function allowance(address _owner,address _spender)constant returns(uint256 remaining){
        allowed[_owner][_spender];

    }

    event Transfer(address indexed from,address indexed to,uint256 _value);
    event Approval(address indexed owner,address indexed spender,uint256 _value);
}