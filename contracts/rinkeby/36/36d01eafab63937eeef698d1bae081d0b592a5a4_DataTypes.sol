/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.4.26;

contract DataTypes{
    bool myBool = false;
    int8 myInt = -128;
    uint8 myUInt = 255;
    string myString; // the string is an array
    //fixed myFixed=1.0987; //255.0
    enum Action {add, remove, update}
    Action myAction = Action.add;
    //Address
    address myAddress;
    function assignAddress(){
        myAddress = msg.sender;
        
    }
    function sendMoney() public payable {
        myAddress.balance;
        myAddress.transfer(msg.value);
    }
    
    //Arrays
    uint[] myIntArr = [1,2,3];
    function arrFunc(){
        myIntArr.push(1);
        myIntArr.length;
        myIntArr[0];
    }
    ///////////
    //struct//
    //////////
    struct Account{
        uint balance;
        uint dailyLimit;
    }
    Account public myAccount;
    
    function structFunc(){
        myAccount.balance = 100;
    }
    
    ///////////////
    /// Mapping ///
    ///////////////
    
    mapping(address =>Account) public _accounts;
    function() payable {
        _accounts[msg.sender].balance += msg.value;
    }
    
    function getBalance() view returns(uint){
        return _accounts[msg.sender].balance;
    }
}