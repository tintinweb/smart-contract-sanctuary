pragma solidity ^0.4.24;
 
contract Register {
    
    struct MyProfile {
        // Wallet owner&#39;s email
        string mail;
        // Wallet owner&#39;s Full Name
        string name;
        // Wallet owner&#39;s Home Adress
        string home_address;
        // The owner can choose to set ot YES/NO (True/False)
        // this feature can be used by other smart contracts to read the record  
        bool isKYCAllowed;
        // Internal Record ID
        bytes32 randomHash;
    }
    event Record(string mail, string name, string home_address, bool isKYCAllowed);
    function record(string mail, string name, string home_address, bool isKYCAllowed) public {
        isKYCAllowed = false;
        bytes32 randomHash =&#39;12345678900&#39;;
        registry[msg.sender] = MyProfile(mail, name, home_address, isKYCAllowed, randomHash);
    }
    mapping (address => MyProfile) public registry;
}