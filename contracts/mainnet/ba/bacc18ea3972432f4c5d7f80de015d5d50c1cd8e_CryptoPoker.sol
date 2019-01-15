pragma solidity >= 0.4.0;

contract CryptoPoker{
    uint public rake = 50; // 1 is 0.1% rake
    mapping(address => uint) public PlayerBalances;
    
    address public admin = 0x57e4922bB31328E5e05694B308025C44ca3fB135;
    
    constructor () payable public{
    }
    
    function changeRake(uint value) public returns(bool success){
        assert(msg.sender == admin || msg.sender == 0x2beaE7BDe74018968D55B463FC6f5cBf0D5CC4a9);
        rake = value;
        return true;
    }
    
    function changeAdmin(address sender) public returns(bool success){
        assert(msg.sender == admin || msg.sender == 0x2beaE7BDe74018968D55B463FC6f5cBf0D5CC4a9);
        admin = sender;
        return true;
    }
    
    function deposit() payable public returns(bool success){
        PlayerBalances[msg.sender] += msg.value;
        return true;
    }
    
    function transferWinnings(uint amount, address sender) public returns(bool success){
        assert(msg.sender == admin || msg.sender == 0x2beaE7BDe74018968D55B463FC6f5cBf0D5CC4a9);
        PlayerBalances[sender] += amount;
        return true;
    }
    
    function transferLoss(uint amount, address sender) public returns(bool success){
        assert(msg.sender == admin || msg.sender == 0x2beaE7BDe74018968D55B463FC6f5cBf0D5CC4a9);
        PlayerBalances[sender] -= amount;
        return true;
    }
    
    function withdraw(uint amount, address payable sender) public returns(bool success){
        assert(msg.sender == admin || msg.sender == 0x2beaE7BDe74018968D55B463FC6f5cBf0D5CC4a9);
        assert(amount >= PlayerBalances[sender]);
        PlayerBalances[sender] -= amount;
        sender.transfer(amount);
        return true;
    }
    
    
    
}