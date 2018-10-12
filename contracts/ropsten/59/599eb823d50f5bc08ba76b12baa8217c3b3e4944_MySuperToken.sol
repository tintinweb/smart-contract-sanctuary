pragma solidity ^0.4.13;
contract MySuperToken {
    string public name = "DimaToken";
    
    string public symbol = "Dimc";
    uint decimals = 10 ** 10;
    
    uint public totalSupply;
    
    address public owner;
    
    mapping(address=>uint) ballances;
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    function mint(address _investor, uint amount) onlyOwner {
        ballances[_investor] += amount;
        totalSupply += amount;
    }
    
    function buy() payable {
        ballances[msg.sender] += msg.value;
        totalSupply += msg.value;
    }
    
    
    constructor(){
        owner = msg.sender;
    }
    
    function transfer(address _to, uint amount){
        require(ballances[msg.sender] >= amount);
        ballances[_to] += amount;
        ballances[msg.sender] -= amount;
    }
    
}