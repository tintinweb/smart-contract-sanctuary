// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./DbankToken.sol";

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function mint(address _to, uint256 _amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract SimpleBank { // CamelCase
    using SafeMath for uint256;
   
    mapping (address => uint256) private balances;
    
    address[] accounts;
    
    uint256 rate = 3;

    DbankToken token;
    IERC20 public busd;

    address public owner;

    event DepositMade(address accountAddress, uint amount);

    
    constructor(address _token) public {
        
        busd = IERC20(0x9f3402C6c5328CC7dEF27bFe6d88425e3eEd5765);
        token = DbankToken(_token);
        owner = msg.sender;
    }

    
    function deposit(uint _amount) public payable returns (uint256) {
        
        
        if (0 == balances[msg.sender]) {
            accounts.push(msg.sender);
        }
        
        busd.transferFrom(msg.sender, address(this), _amount);

        balances[msg.sender] = balances[msg.sender].add(_amount);
        
        emit DepositMade(msg.sender, _amount); // fire event

        return balances[msg.sender];
    }

   
    function withdraw(uint withdrawAmount) public returns (uint256 remainingBal) {
        require(balances[msg.sender] >= withdrawAmount);
        balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);
        
        busd.transfer(msg.sender, withdrawAmount);

        return balances[msg.sender];
    }

  
    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }

    fallback () external {
        revert(); // throw reverts state to before call
    }
    
    function calculateInterest(address user, uint256 _rate) private view returns(uint256) {
        uint256 interest = balances[user].mul(_rate).div(100);
        return interest;
    }
    
    function increaseYear() public {
        uint totalInterest = 0;
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] = balances[account].add(interest);
             totalInterest = totalInterest.add(interest);
        }
        token.mint(totalInterest);
    }
    
    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
// ** END EXAMPLE **