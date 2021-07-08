// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract Settings {
    address adminAddress;

    uint256 public auditDeliveryFeesPercentage;
    uint256 public auditorCreationPrice;

    enum MAX_LENGTH {
        COMPANY_NAME,
        URL,
        CONTRACTS
    }
    mapping(MAX_LENGTH => uint256) public maxLengths;

    constructor() {
        adminAddress = msg.sender;

        auditDeliveryFeesPercentage = 5; // 5%
        maxLengths[MAX_LENGTH.COMPANY_NAME] = 20;
        maxLengths[MAX_LENGTH.URL] = 100;
        maxLengths[MAX_LENGTH.CONTRACTS] = 20;
    }

    function getMaxLength(MAX_LENGTH _index) external view returns (uint256) {
        return maxLengths[_index];
    }

    function getAuditDeliveryFeesPercentage() external view returns (uint256) {
        return auditDeliveryFeesPercentage;
    }

    function getAdminAddress() external view returns (address) {
        return adminAddress;
    }

    function setAuditDeliveryFeesPercentage(uint256 _auditDeliverFeesPercentage)
        external
        onlyAdmin
    {
        auditDeliveryFeesPercentage = _auditDeliverFeesPercentage;
    }

    function setMaxLength(MAX_LENGTH _index, uint256 _value) external onlyAdmin {
        maxLengths[_index] = _value;
    }

    function setAdminAddress(address payable _adminAddress) external onlyAdmin {
        adminAddress = _adminAddress;
    }

    modifier onlyAdmin() {
        require(adminAddress == msg.sender, "NOT ADMIN");
        _;
    }
}