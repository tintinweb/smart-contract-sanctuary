// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registry {
    struct Domain {
        address admin;
        address factory;
        address router;
    }

    mapping(string => Domain) public domainData;

    modifier notEmpty(string memory _value) {
        bytes memory byteValue = bytes(_value);
        require(byteValue.length != 0, 'NO_VALUE');
        _;
    }

    function addDomainData(
        string memory _domain,
        address _admin,
        address _factory,
        address _router
    ) external notEmpty(_domain) {
        if (domainData[_domain].admin != address(0)) {
            require(msg.sender == domainData[_domain].admin, 'Admin: FORBIDDEN');
        }
        domainData[_domain].admin = _admin;
        domainData[_domain].factory = _factory;
        domainData[_domain].router = _router;
    }

    function removeDomain(string memory _domain) external notEmpty(_domain) {
        delete domainData[_domain];
    }

    function domain(string memory _domain) external view returns(Domain memory) {
        return domainData[_domain];
    }
}