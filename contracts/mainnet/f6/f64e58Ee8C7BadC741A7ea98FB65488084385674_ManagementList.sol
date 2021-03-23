/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;



// File: ManagementList.sol

contract ManagementList {
    string public name;
    address public owner;
    uint256 public managersCount;
    mapping(uint256 => address) public managerAddressByIdx;
    mapping(address => uint256) public managerIdxByAddress;

    constructor(string memory _name, address _owner) {
        name = _name;
        owner = _owner;
        managersCount = 1;
        managerAddressByIdx[1] = owner;
        managerIdxByAddress[owner] = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ManagementList: caller is not the owner");
        _;
    }

    modifier onlyManagers() {
        require(
            isManager(msg.sender),
            "ManagementList: caller is not a manager"
        );
        _;
    }

    function managersList() external view returns (address[] memory) {
        address[] memory managersAddresses = new address[](managersCount);
        for (uint256 i = 0; i < managersCount; i++) {
            address managerAddress = managerAddressByIdx[i + 1];
            managersAddresses[i] = managerAddress;
        }
        return managersAddresses;
    }

    function isManager(address managerAddress) public view returns (bool) {
        return managerIdxByAddress[managerAddress] > 0;
    }

    function addManager(address managerAddress) public onlyManagers {
        require(
            isManager(managerAddress) == false,
            "ManagementList: user is already a manager"
        );
        managersCount += 1;
        managerAddressByIdx[managersCount] = managerAddress;
        managerIdxByAddress[managerAddress] = managersCount;
    }

    function removeManager(address managerAddress) public onlyManagers {
        require(
            isManager(managerAddress),
            "ManagementList: non-managers cannot be removed"
        );
        require(
            managerAddress != owner,
            "ManagemenetList: owner cannot be removed"
        );
        uint256 managerIdx = managerIdxByAddress[managerAddress];
        delete managerAddressByIdx[managerIdx];
        delete managerIdxByAddress[managerAddress];
        managersCount -= 1;
    }

    function resetManagers() public onlyOwner {
        for (uint256 i = 0; i < managersCount; i++) {
            address managerAddress = managerAddressByIdx[i + 2];
            removeManager(managerAddress);
        }
    }
}