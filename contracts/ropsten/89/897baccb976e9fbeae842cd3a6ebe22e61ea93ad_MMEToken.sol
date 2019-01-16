pragma solidity 0.4.25;

contract MMEToken {
    string public name = "MME Token";
    address public owner;
    mapping(address=>uint256) public balances;
    
    constructor() public {
        owner = msg.sender;
        balances[owner] = 10;
    }
    
    function transferOwnership(address newOwner) public returns (bool) {
        require(newOwner != address(0));
        require(owner == msg.sender);
        owner = newOwner;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value);
        require(to != address(0));
        
        balances[msg.sender] -= value;
        balances[to] += value;
        return true;
    }
}