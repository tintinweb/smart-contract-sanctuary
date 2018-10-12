pragma solidity ^0.4.25;

contract MyCoin{
    
    string public name = "MEMoin";
    
    string public symbol = "MEMC";
    
    uint public decimals = 10^10;
    
    uint public totalSuply;
    
    mapping(address=>uint) ballances;
    
    address public owner;
    
    function MyCoin(){
        owner=msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender==owner);
        _;
    }
    function mint (address _investor, uint amount) onlyOwner {
        ballances[_investor]+=amount*decimals;totalSuply+=amount*decimals;
    }
    function buy ( ) payable {
        ballances[msg.sender]+=msg.value;totalSuply+=msg.value;
    }
    function transfer ( address _to, uint amount){
        require(ballances[msg.sender]>=amount);
        ballances[_to]+=amount;
        ballances[msg.sender]-=amount;
    }
}