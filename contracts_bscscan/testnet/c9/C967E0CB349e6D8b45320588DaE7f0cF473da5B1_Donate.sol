// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Donate {
    event Received(address sender, uint256 value);

    uint256 public totalDonations; // the amount of donations
    address payable beneficiary; // contract creator's address
    mapping(address => uint256) donorDonations;

    // contract settings
    constructor(address _beneficiary) {
        beneficiary = payable(_beneficiary); // setting the contract creator
    }

    // external function to make donate
    function donate() external payable {
        donorDonations[msg.sender] += msg.value;
        totalDonations += msg.value;
        (bool success, ) = beneficiary.call{value: msg.value}("");
        require(success, "Error en el envio");
        emit Received(msg.sender, msg.value);
    }

    // public function to return total of donations
    function getTotalDonations() public view returns (uint256) {
        return totalDonations;
    }

    // public function to return total donor donations
    function getDonorDonations(address _donor) public view returns (uint256) {
        return donorDonations[_donor];
    }

    // just in case
    receive() external payable {
        donorDonations[msg.sender] += msg.value;
        totalDonations += msg.value;
        (bool success, ) = beneficiary.call{value: msg.value}("");
        require(success, "Error en el envio");
        emit Received(msg.sender, msg.value);
    }
}