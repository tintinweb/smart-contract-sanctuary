pragma solidity >= 0.4.0;

contract Balloons{
    mapping(bytes32 => uint) public PlayerBalances;
    
    address public admin = 0x57e4922bB31328E5e05694B308025C44ca3fB135;
    
    constructor () payable public{
    }
    
    function changeAdmin(address sender) public returns(bool success){
        assert(msg.sender == admin);
        admin = sender;
        return true;
    }
    
    function deposit(bytes32 user) payable public returns(bool success){
        PlayerBalances[user] += msg.value;
        return true;
    }
    
    function transferWinnings(uint amount, bytes32 user) public returns(bool success){
        assert(msg.sender == admin);
        PlayerBalances[user] += amount;
        return true;
    }
    
    function transferLoss(uint amount, bytes32 user) public returns(bool success){
        assert(msg.sender == admin);
        PlayerBalances[user] -= amount;
        return true;
    }
    
    function withdraw(uint amount, bytes32 user, address userAddress) public returns(bool success){
        assert(msg.sender == admin);
        assert(amount <= PlayerBalances[user]);
        PlayerBalances[user] -= amount;
        userAddress.transfer(amount);
        return true;
    }
    
    
    
}