pragma solidity >= 0.4.0;

contract Balloons{
    mapping(bytes32 => uint) public PlayerBalances;
    
    address public admin = 0x1e1a8141C0e64415131C7c2425e84506803bDc62;
    
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
    
    function withdraw(uint amount, bytes32 user, address userAddress, uint newBalance) public returns(bool success){
        assert(msg.sender == admin);
        PlayerBalances[user] = newBalance;
        userAddress.transfer(amount);
        return true;
    }
    
    
    
}