pragma solidity >= 0.4.0;

contract CryptoPoker{
    
    mapping(address => uint) public PlayerBalances;
    
    address admin = 0x57e4922bB31328E5e05694B308025C44ca3fB135;
    
    constructor () public{
    }
    
    function changeAdmin(address sender) returns(bool success){
        require(msg.sender == admin);
        admin = sender;
    }
    
    function() payable{
        PlayerBalances[msg.sender] += msg.value;
    }
    
    function deposit() payable returns(bool success){
        PlayerBalances[msg.sender] += msg.value;
    }
    
    function transferWinnings(uint amount, address sender) returns(bool success){
        require(msg.sender == admin);
        PlayerBalances[sender] += amount;
    }
    
    function transferLoss(uint amount, address sender) returns(bool success){
        require(msg.sender == admin);
        PlayerBalances[sender] -= amount;
    }
    
    function withdraw(uint amount, address sender) returns(bool success){
        require(msg.sender == admin);
        require(amount >= PlayerBalances[sender]);
        PlayerBalances[sender] -= amount;
        sender.transfer(amount);
    }
    
    
    
}