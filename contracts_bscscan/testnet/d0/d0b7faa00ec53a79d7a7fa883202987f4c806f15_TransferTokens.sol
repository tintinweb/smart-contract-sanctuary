/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface IERC20 {
             function totalSupply() external view returns (uint theTotalSupply);
             function balanceOf(address _owner) external view returns (uint balance);
             function transfer(address _to, uint _value) external returns (bool success);
             function transferFrom(address _from, address _to, uint _value) external returns (bool success);
             function approve(address _spender, uint _value) external returns (bool success);
             function allowance(address _owner, address _spender) external view returns (uint remaining);
             event Transfer(address indexed _from, address indexed _to, uint _value);
             event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract TransferTokens {
    
    /// Variables
    address public owner;
    address public withdrawSetter;
    address contractAddr = address(this);
    
    mapping(address => uint) public withdrawAmount;
    mapping(address => bool) public deposited;
    
    IERC20 token;
    
    event WithdrawSetterChanged(address to);
    event OwnershipTranferred(address from, address to);
    event Deposit(address from, uint amount);
    event Withdraw(address, uint);
    event Received(address, uint);
    
    /// Constructor
    constructor(address token_, address owner_) {
        token = IERC20(token_);
        owner = owner_;
    }
    
    /// Deposit function with checks
    function deposit(uint amount) public returns (bool) {
      require(amount > 0, "Deposit amount cannot be zero");
      require(token.allowance(msg.sender, contractAddr) > amount, "Allowance error");
      
      token.transferFrom(msg.sender, contractAddr, amount);
      deposited[msg.sender] = true;
      emit Deposit(msg.sender, amount);
      return true;
    }
    
    /**
     * @dev Set withdraw amount
     * 
     * Requirements:
     * 
     * sender has to be either owner or withdrawSetter
     */
    function setWithdrawAmount(address user, uint amount) public returns (bool) {
        require(msg.sender == owner || msg.sender == withdrawSetter, "Access error");
        withdrawAmount[user] = amount;
        return true;
    }
    
    /// Withdraw tokens 
    function withdraw() public returns (bool) {
        require(deposited[msg.sender] == true, "Deposit not done");
        uint transferAmount = withdrawAmount[msg.sender];
        require(transferAmount > 0, "Zero amount withdraw");
        token.transfer(msg.sender, transferAmount);
        emit Withdraw(msg.sender, transferAmount);
        return true;
    }
    
    /**
     * @dev Transfer ownership 
     * 
     * Requirements:
     * 
     * msg.sender has to be owner 
     */
    function ownershipTransfer(address to) public {
         require(msg.sender == owner, "Only owner");
         owner = to;
         emit OwnershipTranferred(msg.sender, to);
     }
     
     /**
      * @dev Change withdraw amount setter 
      * 
      * Requirements:
      * 
      * msg.sender has to be owner 
      */
    function changeWithdrawSetter(address to) public {
          require(msg.sender == owner, "Only owner");
          withdrawSetter = to;
          emit WithdrawSetterChanged(to);
      }
      
     /// Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
}