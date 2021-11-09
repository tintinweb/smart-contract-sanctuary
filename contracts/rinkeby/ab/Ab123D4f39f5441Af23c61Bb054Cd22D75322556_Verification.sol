// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Verification{
    
    address private owner;
    
    struct Users {
      
       string Name;
       uint balance;
       bool isapproved;
       uint timestamp;
    }
    
    mapping  (address => Users) private accounts;
    
    uint public counter;
    
    address [] private useraddresses; //dynamic array to store useraddresses
    address [] private accountsClosedRequest; // dynamic array to store closed  request for useraddresses
    
    event Deposit(address user , uint amount );
    event Approve(address users, bool Approved);
    event Transfer (address sender, address reciever, uint amount);
    event Withdraw (address reciever, uint amount);
    event Delete(address user);
    
    constructor() payable {
        
        //require( msg.value>= 50 ether, "The Owner must have to deposit 50 ether or more to start the bank");
        owner = msg.sender;
        counter=0;
        emit Deposit ( msg.sender , msg.value);
    } 
    
    // function to Check Balance of User 
    
    function CheckBalanceOfUser(address CheckAddressBalance) public view returns(uint) 
    {    
        require(accounts[CheckAddressBalance].isapproved == true || msg.sender==owner, "The account is not approved by the bank's owner ");
        return accounts[CheckAddressBalance].balance;
        
    }
    
    // return The balance of the Simple Bank contract
    function CheckBanksBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    // User registering function
    
    function RegisterUser (string memory name) public payable
    {
        require( msg.value > 0 ether,"User need to put something as stake to open the account");
        Users memory newuser = Users( name, msg.value, false, block.timestamp+2678400);
        accounts[msg.sender] = newuser;
        useraddresses.push(payable(msg.sender));
        
        if(counter < 5 )
        {
            counter++;
            accounts[msg.sender].balance = 2 ether;
        }
    }
    
    // approving user function
    
    function Approved_Accounts (address user_address) public
    {
        require(msg.sender == owner,"Only Contract Owner Can Approve the users");
        accounts[user_address].isapproved = true;
        emit Approve(user_address, accounts[user_address].isapproved);
    }
    
    // function to Approve all users
    
    function Approve_All_Users () public
    {
        require(msg.sender == owner,"Only Contract Owner Can Approve the users");
        
        for(uint i=0; i< useraddresses.length;i++)
        {
            accounts[useraddresses[i]].isapproved = true;
        }
    }
    
    // check approval function 
    
    function check_Approval (address ad) public view returns(bool)
    {
        return accounts[ad].isapproved;
    }
    
    //  Tranfer Amount function
    
    function TransferAmount (address Reciever, uint amount) public payable
    {
        require (amount <= accounts[msg.sender].balance," The amount being transfered should be less than or equal to sender's account balance");
        require (accounts[Reciever].isapproved == true," The Reciever should be an approved member of the bank" );
        accounts[msg.sender].balance -= msg.value;
        accounts[Reciever].balance += msg.value;
        emit Transfer(msg.sender, Reciever, amount) ;
    }
    
    // function to Deposit_Amount in bank
    
    function Deposit_Amount (uint amount) public payable
    {
        require(accounts[msg.sender].isapproved == true," The depositer must be an approved member of the bank");
        require( msg.value >= 1 ether );
        accounts[msg.sender].balance += msg.value;
        emit Deposit (msg.sender, amount);
        
    }
    
    // function to Withdraw_Amount from bank
    
    function Withdraw_Amount (uint amount) public
    {
        require(accounts[msg.sender].isapproved == true," The Withdrawer must be an approved member of the bank");
        require( amount <= accounts[msg.sender].balance,"The amount being withdrawed should be less than or equal to the account balance of the Withdrawer");
        accounts[msg.sender].balance -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw (msg.sender, amount);
        
    }
    
    // function for applying accounts closing request
    
     function ApplyToCloseAccount (address ClosingAccountAddress) public
     {
          require(accounts[ClosingAccountAddress].isapproved == true,"Only accounts that are approved can call this function");
         require(block.timestamp >= accounts[ClosingAccountAddress].timestamp,"you cannot apply to close account before the 1 month period of its creation.");
         accountsClosedRequest.push(ClosingAccountAddress);
         
     }
     
     // function to approve the closing account request
     
     function ApproveTheCloseAccountRequest (address ClosingAccountAddress) public
     {
         require(msg.sender == owner, "Only owner can call this function");
         payable(ClosingAccountAddress).transfer(accounts[ClosingAccountAddress].balance);
         emit Transfer(address(this),ClosingAccountAddress,accounts[ClosingAccountAddress].balance);
         delete accounts[ClosingAccountAddress];
         delete accountsClosedRequest[ReturnIndexOfTheClosingAccount(ClosingAccountAddress)-1]; 
         emit Delete(ClosingAccountAddress);
     }
     
     // function to return index of the closing account address
     
     function ReturnIndexOfTheClosingAccount(address ClosingAccountAddress) internal  view returns(uint)
     {
        for(uint i=0; i<=accountsClosedRequest.length; i++)
        {
            if (ClosingAccountAddress == accountsClosedRequest[i])
            return i+1;
        }
        return 0;
     }
     
     function showCloseAccountRequests() view public returns(address [] memory)
     
     {
         require(msg.sender == owner,"Only contract owner can check the closed accounts list");
         return accountsClosedRequest;
     }
    // selfdestruct function
    
    function Destroy_Contract () public {
        require (msg.sender==owner,"Only owner can call this function");
        selfdestruct(payable(owner));
    }
      
    
    
    
    
    
}// end of contract