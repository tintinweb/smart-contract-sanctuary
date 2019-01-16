pragma solidity ^0.4.25;

contract AccountMngmt {

    address public owner;
    uint public numAccts=1;
    uint public currentAccPrice;

    //map of accounts - owning address + eth balance
    struct Admin {address AdminAddr; uint Bal;}
    mapping (uint => Admin) public Accounts;

    //map of users - associated account + write access --> all users have view permission
    struct UserStruct {uint AcctId; bool CanWrite;}
    mapping (address => UserStruct) public Users;
    
    constructor() public {
        owner = msg.sender;
        currentAccPrice = 100000000000000000; //unit = wei (0.1 ether)
    }
    function setAccPrice(uint _newPrice) public {
        require(msg.sender == owner, "You must be the contract owner to change the account price");
        currentAccPrice = _newPrice * 1 wei;
    }
    function giveOwnership(uint _Acct, address _newowner) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to transfer ownership");
        //change the account&#39;s admin
        Accounts[_Acct].AdminAddr = _newowner;
    }
    function approveViewer(uint _Acct, address _User) public {
        //ensure the viewer to add is not already associated with an account
        require (Users[_User].AcctId == 0, "You cannot add users already associated with an account");
        //ensure the message sender is the admin of the specified account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to approve viewers");
        //add the user linked to the account
        Users[_User].AcctId = _Acct;
    }
    function approveWriter(uint _Acct, address _User) public {
        //ensure the writer to add is not already associated with an account
        require (Users[_User].AcctId == 0, "You cannot add users already associated with an account");
        //ensure the message sender is the admin of the specified account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to approve writers");
        //link the user to the account and give write permission
        Users[_User].AcctId = _Acct;
        Users[_User].CanWrite = true;
    }
    function deleteUser(uint _Acct, address _User) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to delete users");
        //ensure thebuser address belongs to the specified account
        require(Users[_User].AcctId == _Acct, "The user must belong to the account specified to delete");
        //delete the user
        delete Users[_User];
    }
    function disallowWrite(uint _Acct, address _User) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to disallow writers");
        //ensure the specified user address belongs to the specified account address 
        require(Users[_User].AcctId == _Acct, "The specified user must belong to the account");
        //remove the user&#39;s write access
        Users[_User].CanWrite = false;
    }
    function ownerWithdraw(uint _Amount) public{
        require(msg.sender == owner, "You must be the contract owner to withdraw");
        msg.sender.transfer(_Amount);
    }
    function createAccount() public payable returns(uint){
        require(msg.value >= currentAccPrice, "You must send enough funds to create an account");
        //set up account
        Accounts[numAccts].AdminAddr = msg.sender;
        Accounts[numAccts].Bal = currentAccPrice;
        //if extra eth was sent, return it
        if (msg.value > currentAccPrice){
            msg.sender.transfer(msg.value - currentAccPrice);  
        }
        //counter for current account number
        numAccts++;
        return (numAccts-1);
    }
    function() external payable {
        revert("You must call a function to interact with this contract");
    }
}