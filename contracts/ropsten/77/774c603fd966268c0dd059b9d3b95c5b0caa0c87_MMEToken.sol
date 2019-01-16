pragma solidity 0.4.25;

contract MMEToken {
    string public constant name = "MME Token";
    string public constant symbol = "MME";
    uint256 public constant decimals = 18;
    mapping(address=>uint256) balances;
    address public owner;
    
    constructor() public {
        owner = msg.sender; 
        balances [owner] = 100; 
    }
    
    function balancesOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];

    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value);
        require(to != address(0));
        
        balances [msg.sender] = balances[msg.sender] - value;
        balances[to] += value;
        return true;
    
}

}