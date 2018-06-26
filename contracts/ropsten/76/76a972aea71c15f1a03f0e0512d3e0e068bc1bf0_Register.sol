pragma solidity ^0.4.24;
 
contract Register {
    struct MyMail {
        string mail;
        string name;
        string home_address;
        bool isKYCReady;
    }
    event Record(string mail, string name, string home_address, bool isKYCReady);
    function record(string mail, string name, string home_address, bool isKYCReady) public {
        isKYCReady = false;
        registry[msg.sender] = MyMail(mail, name, home_address, isKYCReady);
    }
    mapping (address => MyMail) public registry;
}