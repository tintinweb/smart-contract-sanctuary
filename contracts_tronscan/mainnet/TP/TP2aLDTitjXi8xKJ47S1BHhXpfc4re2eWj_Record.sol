//SourceUnit: test.sol

// SPDX-License-Identifier: Test

pragma solidity ^0.4.0;

contract Record
{
    
    struct Details{
        string domainName;
        string price;
        string sellerId;
        string buyerId;
    }
    event RecordTransaction(string domainName,string price,string sellerId,string buyerId);
    
    uint id=0;
    
    mapping(uint=>Details) public details;
    
    function recordTransaction(string memory domainName,string memory price,string memory sellerId,string memory buyerId) public
    {
        require(bytes(domainName).length > 0,"Invalid domain name");
        require(bytes(price).length > 0,"Invalid price");
        id++;
        details[id]=Details(domainName,price,sellerId,buyerId);
        emit RecordTransaction(domainName,price,sellerId,buyerId);
    }
    
    function recordHiddenTransaction(string memory domainName,string memory price,string memory sellerId,string memory buyerId) public
    {
        require(bytes(domainName).length > 0,"Invalid domain name");
        require(bytes(price).length > 0,"Invalid price");
        id++;
        details[id]=Details(domainName,price,sellerId,buyerId);
        emit RecordTransaction(domainName,price,sellerId,buyerId);
    }
    
    function getDetails(uint id1)  external view returns (string memory)
    {
        return details[id1].domainName;
    } 
}