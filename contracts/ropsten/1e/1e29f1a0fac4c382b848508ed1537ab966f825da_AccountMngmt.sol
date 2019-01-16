pragma solidity ^0.4.25;
    
contract AccountMngmt {
    
    struct User {address UserAddy; bool CanWrite;}
    struct Account {address AdminAddr; uint Bal; User[] Users;}
    Account[] public  Accounts;
    address public owner;
    uint public currentAccPrice;
    
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
        require(Accounts[_Acct].Bal>(currentAccPrice/100), "Not enough funds!");
        Accounts[_Acct].Bal-=(currentAccPrice/100);
        //add the user linked to the account
        Accounts[_Acct].Users.length++;
        uint numUsersInAcct = Accounts[_Acct].Users.length-1;
        Accounts[_Acct].Users[numUsersInAcct].UserAddy = _User;
    }
    function approveWriter(uint _Acct, address _User) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to approve viewers");
        require(Accounts[_Acct].Bal>(currentAccPrice/100), "Not enough funds!");
        Accounts[_Acct].Bal-=(currentAccPrice/100);
        //add the user linked to the account and give write permission
        Accounts[_Acct].Users.length++;
        uint numUsersInAcct = Accounts[_Acct].Users.length-1;
        Accounts[_Acct].Users[numUsersInAcct].UserAddy = _User;
        Accounts[_Acct].Users[numUsersInAcct].CanWrite = true;
    }
    function deleteUser(uint _Acct, uint _UserNum) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to delete users");
        //delete the user
        delete Accounts[_Acct].Users[_UserNum];
    }
    function disallowWrite(uint _Acct, uint _UserNum) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to disallow writers");
        //remove the user’s write access
        Accounts[_Acct].Users[_UserNum].CanWrite = false;
    }
    function allowWrite(uint _Acct, uint _UserNum) public {
        //ensure the message sender is the admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to sallow writers");
        require(Accounts[_Acct].Bal>(currentAccPrice/200), "Not enough funds!");
        Accounts[_Acct].Bal-=(currentAccPrice/200);
        //remove the user’s write access
        Accounts[_Acct].Users[_UserNum].CanWrite = true;
    }
    function ownerWithdraw(uint _Amount) public{
        require(msg.sender == owner, "You must be the contract owner to withdraw");
        //msg.sender.send(_Amount);
        msg.sender.transfer(_Amount);
        //require(msg.sender.send(_Amount));
    }
    //create an account only with a specific function call to minimize mistakes
    function createAccount() public payable{
        //minimum price to hold an account is 0.1 eth
        require(msg.value >= currentAccPrice * 1 wei, "You must send enough funds to create an account");
        //set up account
        Accounts.length++;
        uint acctN = Accounts.length-1;
        Accounts[acctN].AdminAddr = msg.sender;
        Accounts[acctN].Bal = msg.value;
        //Accounts.length++;
    }
    function() external payable {
        revert("You must call a function to interact with this contract");
    }
    function usersOfAccount(uint _Acct,uint _User) public view returns(address, bool){
        return (Accounts[_Acct].Users[_User].UserAddy,Accounts[_Acct].Users[_User].CanWrite );
    }
    function accountCount() public constant returns(uint) {
        return Accounts.length;
    }
    function userCountsInAccount(uint _Acct) public constant returns(uint) {
        return Accounts[_Acct].Users.length;
    }
}