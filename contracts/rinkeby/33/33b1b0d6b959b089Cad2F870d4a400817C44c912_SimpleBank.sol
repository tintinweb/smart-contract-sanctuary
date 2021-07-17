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


contract SimpleBank is Ownable { // CamelCase
    using SafeMath for uint256;
    // Declare state variables outside function, persist through life of contract

    
    // dictionary that maps addresses to balances and interests
    mapping (address => uint256) private balances;

    // Users in system
    address[] accounts;
        
    uint public totalInterest;
    
    // Interest rate
    uint256 rate = 3;
    
    // "private" means that other contracts can't directly query balances
    // but data is still viewable to other parties on blockchain

    DbankToken token;
    IERC20 public busd = IERC20(0x514D9176948a8ACC31B11aab7B8137F14F0bA70B);

    // Events - publicize actions to external listeners
    event DepositMade(address accountAddress, uint amount);

    // Constructor, can receive one or many variables here; only one allowed
    constructor(address _token) public {
        
        token = DbankToken(_token);
        //owner = msg.sender;
    }

    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    function deposit(uint _amount) public payable returns (uint256) {
        
        // Record account in array for looping
        if (0 == balances[msg.sender]) {
            accounts.push(msg.sender);
        }
        
        busd.transferFrom(msg.sender, address(this), _amount);

        balances[msg.sender] = balances[msg.sender].add(_amount);
        
        emit DepositMade(msg.sender, msg.value); // fire event

        return balances[msg.sender];
    }

    /// @notice Withdraw ether from bank
    /// @dev This does not return any excess ether sent to it
    /// @param withdrawAmount amount you want to withdraw
    /// @return remainingBal The balance remaining for the user
    function withdraw(uint withdrawAmount) public returns (uint256 remainingBal) {
        require(balances[msg.sender] >= withdrawAmount);
        balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);
        
        //Withdraw BUSD Token
        busd.transfer(msg.sender, withdrawAmount);
        
        //Withdraw Interest Token (Dbank-Token)
        token.transfer(msg.sender, totalInterest);

        return balances[msg.sender];
    }

  
    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    // Fallback function - Called if other functions don't match call or
    // sent ether without data
    // Typically, called when invalid data is sent
    // Added so ether sent to this contract is reverted if the contract fails
    // otherwise, the sender's money is transferred to contract
    fallback () external {
        revert(); // throw reverts state to before call
    }
    
    function calculateInterest(address user, uint256 _rate) private view returns(uint256) {
        uint256 interest = balances[user].mul(_rate).div(100);
        return interest;
    }
    
    function increaseYear() public {
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] = balances[account].add(interest);
            
            totalInterest = totalInterest.add(interest);
        }
        token.mint(totalInterest);

    }
    
    function systemBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }
}
// ** END EXAMPLE **