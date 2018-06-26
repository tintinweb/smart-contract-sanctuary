pragma solidity ^0.4.24;
 
contract Register {
    struct MyMail {
        string mail;
    }
    event Record(string mail);
    function record(string mail) public {
        registry[msg.sender] = MyMail(mail);
    }
    mapping (address => MyMail) public registry;
}