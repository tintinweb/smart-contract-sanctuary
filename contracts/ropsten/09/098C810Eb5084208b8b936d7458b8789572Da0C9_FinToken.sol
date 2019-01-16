pragma solidity ^0.4.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    //function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    //function approve(address spender, uint256 value) external returns (bool);
    //function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FinToken is IERC20{
    uint private totalSupply_;
    mapping (address => uint) private balances;
    
    string public name = "FinUniversity Token";
    string public symbol = "FUT";
    uint8 public decimals = 8;
    
    constructor() public {
        totalSupply_ = 10000 * (10**uint(decimals));
        balances[msg.sender] = totalSupply_;
        emit Transfer(0, msg.sender, totalSupply_);
    }
    
    function totalSupply() external view returns (uint256){
        return totalSupply_;
    }
    
    function balanceOf(address who) external view returns (uint256){
        return balances[who];
    }
    
    function transfer(address to, uint amount) external returns (bool){
        require(balances[msg.sender] >= amount, "Not enough fund");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        
        return true;
    }
}