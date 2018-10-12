pragma solidity ^0.4.0;
contract MiCon{
    string public name="qwe";
    string public symbol= "hsee";
    uint public totalSupply;
    uint public decimals=10^18;
    
    mapping(address=>uint) balances;
    
    address public owner;
    
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    
    function MyCoin(){
        owner=msg.sender;
    }
    
    function mint(address _investor, uint amount) onlyOwner{
        balances[_investor]+=amount*decimals;
        totalSupply+=amount*decimals;
    }
    
    function buy() payable{
        balances[msg.sender]+=msg.value;
        totalSupply+=msg.value;
    }
    
    function transfer(address _to, uint amount){
        require(balances[msg.sender]>=amount);
        balances[_to]+=amount;
        balances[msg.sender]-=amount;
    }
    
}