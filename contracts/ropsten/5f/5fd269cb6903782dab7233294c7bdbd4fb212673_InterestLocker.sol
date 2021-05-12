/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract InterestLocker {
    address public token;
    address public owner;
    uint256 public lockedAmount;
    
    constructor (address _owner, address _token) public {
        owner = _owner;
        token = _token;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function initiate() onlyOwner external {
        IERC20 Token = IERC20(token);
        
        uint256 tokenBalance = Token.balanceOf(address(this));
        
        lockedAmount = tokenBalance;
    }
    
    function transferOwnership(address newOwner) onlyOwner external {
        owner = newOwner;
    }
    
    function burnFromLocker(uint256 amount) onlyOwner external {
        require(amount <= lockedAmount, "Given amount exceeds locker balance.");
        
        IERC20 Token = IERC20(token);
        
        lockedAmount -= amount;
        
        Token.transfer(address(1), amount);
    }
    
    function withdraw(address recipient) onlyOwner external {
        IERC20 Token = IERC20(token);
        
        uint256 tokenBalance = Token.balanceOf(address(this));
        
        uint256 transferAmount = tokenBalance - lockedAmount;
        
        Token.transfer(recipient, transferAmount);
    }
}