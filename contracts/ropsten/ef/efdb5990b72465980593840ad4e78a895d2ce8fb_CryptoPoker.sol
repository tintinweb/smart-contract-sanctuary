pragma solidity >= 0.4.0;

contract CryptoPoker{
    uint public rake = 50; // 1 is 0.1% rake
    mapping(address => uint) public PlayerBalances;
    
    address public admin = 0x57e4922bB31328E5e05694B308025C44ca3fB135;
    
    constructor () public{
    }
    
    function changeRake(uint value) public returns(bool success){
        require(msg.sender == admin);
        rake = value;
    }
    
    function changeAdmin(address sender) public returns(bool success){
        require(msg.sender == admin);
        admin = sender;
    }
    
    function() external payable{
        PlayerBalances[msg.sender] += msg.value;
    }
    
    function deposit() payable public returns(bool success){
        PlayerBalances[msg.sender] += msg.value;
    }
    
    function transferWinnings(uint amount, address sender) public returns(bool success){
        require(msg.sender == admin);
        PlayerBalances[sender] += amount;
    }
    
    function transferLoss(uint amount, address sender) public returns(bool success){
        require(msg.sender == admin);
        PlayerBalances[sender] -= amount;
    }
    
    function withdraw(uint amount, address payable sender) public returns(bool success){
        require(msg.sender == admin);
        require(amount >= PlayerBalances[sender]);
        PlayerBalances[sender] -= amount;
        sender.transfer(amount);
    }
    
    
    
}