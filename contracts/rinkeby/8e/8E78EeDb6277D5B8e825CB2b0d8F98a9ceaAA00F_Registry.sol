// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registry {
    struct Domain {
        address admin;
        address factory;
        address router;
    }

    mapping(string => Domain) public domainData;
    mapping(string => address) public domainStorage;

    modifier onlyAdmin(string memory _domain) {
        require(domainData[_domain].admin != address(0), 'Registry: NO_DOMAIN_DATA');
        require(msg.sender == domainData[_domain].admin, 'Registry: FORBIDDEN');
        _;
    }

    modifier notEmpty(string memory _value) {
        bytes memory byteValue = bytes(_value);
        require(byteValue.length != 0, 'Registry: NO_VALUE');
        _;
    }

    function addDomainData(string memory _domain, Domain memory _data) external notEmpty(_domain) {
        if (domainData[_domain].admin != address(0)) {
            require(msg.sender == domainData[_domain].admin, 'Registry: FORBIDDEN');
        }
        domainData[_domain].admin = _data.admin;
        domainData[_domain].factory = _data.factory;
        domainData[_domain].router = _data.router;
    }

    function addDomainStorage(string memory _domain, address _storage) external notEmpty(_domain) onlyAdmin(_domain) {
        domainStorage[_domain] = _storage;
    }

    function removeDomain(string memory _domain) external notEmpty(_domain) onlyAdmin(_domain) {
        delete domainData[_domain];
        delete domainStorage[_domain];
    }
}