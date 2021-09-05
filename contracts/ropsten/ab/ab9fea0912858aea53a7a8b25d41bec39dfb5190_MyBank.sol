/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity 0.5.16;

contract SafeMath{
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");


        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a, "SafeMath: subtraction overflow");
      return a - b;
    }
}

contract MyBank is SafeMath {
   event Deposit(address from, uint value); //Declares an event
    
    mapping (address=>uint) public deposits;
    uint public totalDeposits = 0;
    

    function deposit() public payable {
       /*
          Requires the deposit value to be greater than zero.
          Errors when msg.value is equal to zero
       */
        require (msg.value > 0, "Your deposit amount must be greater than zero.");
        
        deposits [msg.sender] = add(deposits [msg.sender],  msg.value);
        totalDeposits = add(totalDeposits, msg.value); 
        emit Deposit(msg.sender,msg.value);// Emits an event

     }
     
     function withdraw(uint amount) public {
        require (amount <=deposits[msg.sender]);
        msg.sender. transfer (amount);
        deposits [msg.sender] = sub(deposits[msg.sender],amount);
        totalDeposits = sub(totalDeposits, amount);
    }
}