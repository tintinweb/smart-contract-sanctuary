pragma solidity ^0.4.25;
    
contract AccountMngmt {
    
    address public owner;
    uint public accPrice;
    uint public userPrice;
    uint public initialBal;

    Account[] public Accounts;
    struct Account {address AdminAddr; uint Bal; User[] Users;}
    struct User {address UserAddy; bool CanWrite;}
    
    constructor() public {
        owner = msg.sender;
        // currency unit is wei
        accPrice = 0;
        userPrice = 0;
        initialBal = 0;
    }

    // Owner functions
    function setAccPrice(uint _newAccPrice) public {
        require(msg.sender == owner, "You must be the owner to change the account price.");
        accPrice = _newAccPrice * 1 wei;
    }
    function setUserPrice(uint _newUserPrice) public {
        require(msg.sender == owner, "You must be the owner to change the user price.");
        userPrice = _newUserPrice * 1 wei;
    }
    function setInitialBal(uint _newInitialBal) public {
        require(msg.sender == owner, "You must be the owner to change the initial balance.");
        initialBal = _newInitialBal * 1 wei;
    }
    
    function ownerWithdraw(uint _Amount) public{
        require(msg.sender == owner, "You must be the contract owner to withdraw");
        msg.sender.transfer(_Amount);
    }

    // Core functions
    function createAccount() public payable {
        //ensure total price is paid
        require(msg.value >= accPrice * 1 wei, "You must send enough funds to create an account");
        //set up account
        Accounts.length++;
        uint acctN = Accounts.length-1;
        Accounts[acctN].AdminAddr = msg.sender;
        Accounts[acctN].Bal = initialBal;
    }
    function addFunds(uint _Acct) public payable {
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to add funds");
        Accounts[_Acct].Bal += msg.value;
    }
    function approveViewer(uint _Acct, address _User) public {
        //ensure message sender is admin of the account and has sufficient balance
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to approve viewers");
        require(Accounts[_Acct].Bal >= userPrice, "Not enough funds!");
        Accounts[_Acct].Bal -= userPrice;

        //add the user linked to the account
        Accounts[_Acct].Users.length++;
        uint numUsersInAcct = Accounts[_Acct].Users.length-1;
        Accounts[_Acct].Users[numUsersInAcct].UserAddy = _User;
    }
    function approveWriter(uint _Acct, address _User) public {
        //ensure message sender is admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to approve viewers");
        require(Accounts[_Acct].Bal >= userPrice, "Not enough funds!");
        Accounts[_Acct].Bal -= userPrice;

        //add user to the account
        Accounts[_Acct].Users.length++;
        uint numUsersInAcct = Accounts[_Acct].Users.length-1;
        Accounts[_Acct].Users[numUsersInAcct].UserAddy = _User;
        //give write permission
        Accounts[_Acct].Users[numUsersInAcct].CanWrite = true;
    }
    function giveOwnership(uint _Acct, address _newowner) public {
        //ensure message sender is admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to transfer ownership");
        //change the account’s admin
        Accounts[_Acct].AdminAddr = _newowner;
    }
    function disallowWrite(uint _Acct, uint _UserNum) public {
        //ensure message sender is admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to disallow writers");
        //remove user’s write access
        Accounts[_Acct].Users[_UserNum].CanWrite = false;
    }
    function allowWrite(uint _Acct, uint _UserNum) public {
        //ensure message sender is admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to allow writers");
        //give the user write access
        Accounts[_Acct].Users[_UserNum].CanWrite = true;
    }
    function deleteUser(uint _Acct, uint _UserNum) public {
        //ensure message sender is admin of the account
        require(Accounts[_Acct].AdminAddr == msg.sender, "You must be the account admin to delete users");
        //delete the user
        delete Accounts[_Acct].Users[_UserNum];
    }

    // View functions
    function usersOfAccount(uint _Acct, uint _User) public view returns(address, bool){
        return (Accounts[_Acct].Users[_User].UserAddy,Accounts[_Acct].Users[_User].CanWrite );
    }
    function accountCount() public view returns(uint) {
        return Accounts.length;
    }
    function userCountsInAccount(uint _Acct) public view returns(uint) {
        return Accounts[_Acct].Users.length;
    }

    // Fallback
    function() external payable {
        revert("You must call a function to interact with this contract");
    }
}