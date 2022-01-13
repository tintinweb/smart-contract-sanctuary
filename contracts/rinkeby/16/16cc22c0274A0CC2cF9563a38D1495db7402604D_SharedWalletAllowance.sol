// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract SharedWalletAllowance {
    
// MARK: Modifier

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
// MARK: Properties
    
    uint public allowanceAmountTotal;
    address owner;
    mapping(address => uint) public balanceReceived;
    mapping(address => uint) public accountAllowance;
    
// MARK: Lifecycle
    
    /// constructor is called only once, set the owner to the person who deployed the contract
    constructor() {
        owner = msg.sender;
    }
    
// MARK: Allowance Functions 

    /// Set the allowance for an address
    function addAllowance(address _to, uint _amount) public onlyOwner {
        
        // Can't set the allowance higher than the total amount in the contract
        assert(_amount <= getBalance());
        
        // TODO: Can't set the allowance higher than the current set allowance for other accounts 
        assert(_amount <= allowanceAmountTotal);
        
        accountAllowance[_to] += _amount;
        allowanceAmountTotal -= _amount;
    }
    
// MARK: Withdrawl Functions
    
    /// Withdraw all of the funds to an address
    function withdrawMoney() public onlyOwner {
        address payable to = payable(0xC725d8D40e3ea07f17C5686eeC45dBE784154e6f);
        to.transfer(getBalance());
    }
    
    function withdrawAllowance(uint _amount) public {
        accountAllowance[msg.sender] -= _amount;
        
        address payable to = payable(msg.sender);
        to.transfer(_amount);
    }
     function transferToFallback(address payable _to) public payable {
        _to.transfer(msg.value);
    }
     fallback() external payable{
          address payable to = payable(0xC725d8D40e3ea07f17C5686eeC45dBE784154e6f);
          to.transfer(msg.value);
     }   
     receive() external payable{
          address payable to = payable(0xC725d8D40e3ea07f17C5686eeC45dBE784154e6f);
          to.transfer(msg.value);
     }
// MARK: Deposit Functions
    
  
// MARK: Balance Functions 
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
}