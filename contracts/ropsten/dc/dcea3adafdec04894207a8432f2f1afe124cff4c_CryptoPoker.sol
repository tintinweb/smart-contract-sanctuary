pragma solidity >= 0.4.0;

contract CryptoPoker{
    
    mapping(address => uint) public PlayerBalances;
    
    address admin = 0x3aF856Cb6226f3cd532C2CEE2B649CEF1b4De516;
    
    constructor () public{

        
    }
    
    function() payable{
        PlayerBalances[msg.sender] += msg.value;
    }
    
    function deposit() payable returns(bool success){
        PlayerBalances[msg.sender] += msg.value;
    }
    
    function withdraw(uint amount, address sender) payable returns(bool success){
        require(msg.sender == admin);
        require(amount >= PlayerBalances[sender]);
        PlayerBalances[sender] -= amount;
        sender.transfer(amount);
    }
    
    
    
}