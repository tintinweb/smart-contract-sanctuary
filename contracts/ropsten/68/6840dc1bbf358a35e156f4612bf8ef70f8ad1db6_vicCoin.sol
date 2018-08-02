pragma solidity ^0.4.23;

contract vicCoin {
    
    mapping(address => uint256) balance;
    address owner;
    
    constructor() public {
        owner = msg.sender;
        balance[owner] = 1000000;
    }
    
    function balanceOf (address tokenOwner) public constant returns (uint thisBalance) {
        return balance[tokenOwner];
    }
    
    function transfer(address _to, uint256 _amount) public {
        require (balance[msg.sender] >= _amount);
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
    }
}