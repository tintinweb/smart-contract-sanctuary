pragma solidity ^0.4.24;
//  Decentralized Identity verification on a Blockchain
//  Ether decentralized identity documents (DIDs)
//
//  List of approved KYC Rules https://www.irs.gov/businesses/international-businesses/list-of-approved-kyc-rules
//
//  Know Your Customer Regions
//
//  Americas        = 1
//  Europe          = 2 
//  Asia Pacific    = 3
//  Middle East     = 4 
//  Africa          = 5

contract Register {
    address private owner;
    
    struct MyProfile {
        // Wallet owner&#39;s email
        string mail;
        // Wallet owner&#39;s Full Name
        string name;
        // Wallet owner&#39;s Home Adress
        string home_address;
        // The owner can choose to set ot YES/NO (True/False)
        // this feature can be used by other smart contracts to read the record
        // this value is set the the owner to allow or prevent anyone reading the details. The current status has only 2 options Y/N
        // in the future it should be able to validate keys for access based on bool status
        bool isKYCAllowed;  
        // Internal Record ID
        bytes32 randomHash;
        //
        string IPFSHash;
        //
        string dIdLink;
        //
        string kyc_region;
    }
    event Record(string mail, string name, string home_address, bool isKYCAllowed, string IPFSHash, string dIdLink);
    
    function record(string mail, string name, string home_address, bool isKYCAllowed, string IPFSHash, string dIdLink, string kyc_region) public {
        owner = msg.sender;
        isKYCAllowed = false;
        bytes32 randomHash =&#39;01234567899876543210&#39;;
//        IPFSHash =&#39;&#39;;  // QmPJvUcAamK6XVGFUiB2R7E39Vn6JuqNYdydDk125dk1Lp
//        dIdLink = &#39;&#39;; // Provide link of ddecentralized identity documents  https://ipfs.io/ipfs/QmPJvUcAamK6XVGFUiB2R7E39Vn6JuqNYdydDk125dk1Lp
        registry[msg.sender] = MyProfile(mail, name, home_address, isKYCAllowed, randomHash, IPFSHash, dIdLink, kyc_region);
    
    }
    
    mapping (address => MyProfile) public registry;
      
      function CleanSweap() public {
       if (owner == msg.sender) {    // We check who is calling
          selfdestruct(owner);      //Destruct the contract
       }
      }
}