pragma solidity ^0.4.23;

contract DAppsDevs {
    address public owner;

    string public constant companyName = "DApps Devs LLC";
    string public constant companySite = "dappsdevs.io, dappsdevs.com";
    string public constant phoneNumber  = "+1-302-481-9195";
    string public constant email = "info@dappsdevs.com";

    mapping(bytes32 => string) public additionalInfo;

    constructor() public {
        owner = msg.sender;
    }

    function () payable fromOwner() {
    }

    function setCompanyInfo(bytes32 key, string value) fromOwner() public {
        additionalInfo[key] = value;
    }

    function getCompanyInfo(bytes32 key) constant public returns (string) {
        return additionalInfo[key];
    }

    function kill() fromOwner() public {
        selfdestruct(owner);
    }

    modifier fromOwner() {
        require(owner == msg.sender);
        _;
    }
}