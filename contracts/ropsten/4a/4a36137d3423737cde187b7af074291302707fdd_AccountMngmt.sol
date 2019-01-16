pragma solidity ^0.4.25;
    
contract AccountMngmt {
    
    address public owner;
    uint public numAccts=0;
    uint public currentAccPrice;
    
    //map of accounts - owning address + eth balance
    struct Admin {address AdminAddr; uint Bal;}
    mapping (uint => Admin) public Accounts;
    
    //map of users - associated account + write access --> all users have view permission
    struct UserStruct {uint AcctId; bool CanWrite;}
    mapping (address => UserStruct) public Users;
    
    //UPDATE THIS TO CHARGE FEES??
    
    constructor() public {
       owner = msg.sender;
       currentAccPrice = 100000000000000000; // unit = wei (0.1 ether)
    }
    function setAccPrice(uint _newPrice) public {
      require(msg.sender == owner, "You must be the owner to change the price.");
      currentAccPrice = _newPrice * 1 wei;
    }
    function giveOwnership(uint _Acct, address _newowner) public {
      //ensure the message sender is the admin of the account
      require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to transfer ownership");
      //change the account’s admin
      Accounts[_Acct].AdminAddr = _newowner;
    }
    function approveViewer(uint _Acct, address _User) public {
       //ensure the message sender is the admin of the account
       require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to approve viewers");
       //add the user linked to the account
       Users[_User].AcctId = _Acct;
    }
    function approveWriter(uint _Acct, address _User) public {
       //ensure the message sender is the admin of the account
       require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to approve writers");
       //add the user linked to the account and give write permission
       Users[_User].AcctId = _Acct;
       Users[_User].CanWrite = true;
    }
    function deleteUser(uint _Acct, address _User) public {
       //ensure the message sender is the admin of the account
       require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to delete users");
       //delete the user
       delete Users[_User];
    }
    function disallowWrite(uint _Acct, address _User) public {
       //ensure the message sender is the admin of the account
       require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to disallow writers");
       //remove the user’s write access
       Users[_User].CanWrite = false;
    }
    function ownerWithdraw(uint _Amount) public{
       require(msg.sender == owner, "You must be the contract owner to withdraw");
       //msg.sender.send(_Amount);
       msg.sender.transfer(_Amount);
       //require(msg.sender.send(_Amount));
    }
    //create an account only with a specific function call to minimize mistakes
    function createAccount() public payable returns(uint){
       //minimum price to hold an account is 0.1 eth
       require(msg.value >= currentAccPrice * 1 wei, "You must send enough funds to create an account");
       //set up account
       Accounts[numAccts].AdminAddr = msg.sender;
       Accounts[numAccts].Bal = currentAccPrice * 1 wei;
       //if extra eth was sent, return it
       if (msg.value > currentAccPrice * 1 wei){
           msg.sender.transfer(msg.value - currentAccPrice * 1 wei);
       }
       //counter for current account number
       numAccts++;
       return (numAccts-1);
       //combine into return(numAccts++) as ++ done after return?
    }
    function() external payable {
       revert("You must call a function to interact with this contract");
    }
}