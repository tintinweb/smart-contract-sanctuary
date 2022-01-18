/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CiRALicense {
    struct License {
        string name;
        uint256 price; // Wei
        uint256 duration; // Minute
    }

    struct Licensed {
        string name;
        uint256 expirationDate;
    }

    address _officialAddress;
    string[] _lcNameList;
    mapping(string => License) _lcList;
    mapping(address => Licensed) _member;

    constructor() {
        _officialAddress = msg.sender;
    }

    modifier onlyOfficial() {
        require(msg.sender == _officialAddress, "Only Official");
        _;
    }

    function addLicense(
        string memory name,
        uint256 price,
        uint256 duration
    ) public onlyOfficial {
        require(
            price > 0 && duration * 1 minutes >= 1 minutes,
            "Require --> Price > 0 and duration >= 1 minute"
        );
        require(_lcList[name].price <= 0, "License already exists");
        _lcNameList.push(name);
        _lcList[name] = License(name, price, duration * 1 minutes);
    }

    function removeLicense(uint256 index) public onlyOfficial {
        require(index < _lcNameList.length, "index out of bound");
        delete _lcList[_lcNameList[index]];
        _lcNameList[index] = _lcNameList[_lcNameList.length - 1];
        _lcNameList.pop();
    }

    function updateLicense(
        string memory name,
        uint256 price,
        uint256 duration
    ) public onlyOfficial {
        _lcList[name].name = name;
        _lcList[name].price = price;
        _lcList[name].duration = duration * 1 minutes;
    }

    function getAllLicense() public view returns (License[] memory) {
        License[] memory licenseArr = new License[](_lcNameList.length);
        for (uint256 i = 0; i < _lcNameList.length; i++) {
            licenseArr[i] = _lcList[_lcNameList[i]];
        }
        return licenseArr;
    }

    function buyLicense(string memory name)
        public
        payable
        returns (Licensed memory)
    {
        require(_lcList[name].price > 0, "License not found");
        require(msg.value == _lcList[name].price, "License Price Invalid");
        require(
            block.timestamp > _member[msg.sender].expirationDate,
            "Licensed"
        );
        (bool sent, ) = _officialAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        _member[msg.sender].name = name;
        _member[msg.sender].expirationDate =
            block.timestamp +
            _lcList[name].duration;
        return _member[msg.sender];
    }

    function getLicensed() public view returns (Licensed memory) {
        require(
            block.timestamp <= _member[msg.sender].expirationDate,
            "License Expired"
        );
        return _member[msg.sender];
    }
}