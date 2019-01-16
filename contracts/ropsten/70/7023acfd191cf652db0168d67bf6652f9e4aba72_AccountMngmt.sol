pragma solidity ^0.4.25;

contract AccountMngmt {
    address public owner;
    uint public numAccts=0;
    //map of accounts - owning address + eth balance
    struct Admin {address AdminAddr; uint Bal;}
    mapping (uint => Admin) public Accounts;
    //map of users - associated account + write access --> all users have view permission
    struct UserStruct {uint AcctId; bool CanWrite;}
    mapping (address => UserStruct) public Users;
    
    //UPDATE THIS TO CHARGE FEES??
    
    constructor() public {
        owner = msg.sender;
    }
    function giveOwnership(uint _Acct, address _newowner) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender);
        //change the account&#39;s admin
        Accounts[_Acct].AdminAddr = _newowner;
    }
    function approveViewer(uint _Acct, address _User) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender);
        //add the user linked to the account
        Users[_User].AcctId = _Acct;
    }
    function approveWriter(uint _Acct, address _User) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender);
        //add the user linked to the account and give write permission
        Users[_User].AcctId = _Acct;
        Users[_User].CanWrite = true;
    }
    function deleteUser(uint _Acct, address _User) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender);
        //delete the user
        delete Users[_User];
    }
    function disallowWrite(uint _Acct, address _User) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender);
        //remove the user&#39;s write access
        Users[_User].CanWrite = false;
    }
    function ownerWithdraw(uint _Amount) public{
        require(msg.sender == owner);
        //msg.sender.send(_Amount);
        msg.sender.transfer(_Amount);
        //require(msg.sender.send(_Amount));
    }
    //create an account only with a specific function call to minimize mistakes
    function createAccount() public payable returns(uint){
        //minimum price to hold an account is 1 eth
        require(msg.value > 1 ether); // 1 or 1 000 000 or 1eth?
        //set up account
        Accounts[numAccts].AdminAddr = msg.sender;
        Accounts[numAccts].Bal = 1;
        //if extra eth was sent, return it
        if (msg.value > 1 ether){
            msg.sender.transfer(msg.value-1 ether);  
        }
        //counter for current account number
        numAccts++;
        return (numAccts-1);
        //combine into return(numAccts++) as ++ done after return? 
    }
    function() payable external{
        //can this be done better?
        revert();
    }
    
}