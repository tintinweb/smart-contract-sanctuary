pragma solidity ^0.4.24;
 
contract Register {
    struct MyMail {
        string mail;
        string name;
    }
    event Record(string mail, string name);
    function record(string mail, string name) public {
        registry[msg.sender] = MyMail(mail, name);
    }
    mapping (address => MyMail) public registry;
}