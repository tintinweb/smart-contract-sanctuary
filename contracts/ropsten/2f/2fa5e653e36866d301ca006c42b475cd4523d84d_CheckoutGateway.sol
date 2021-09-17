/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract CheckoutGateway {

    address public admin;
    address payable public vaultWallet;
    mapping(address => uint) public counters;
    mapping(uint => mapping(uint => uint)) public packages;

    event PurchasePackage(uint256 projectId, uint256 packageId, uint counter);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address payable _vaultWallet) {
        require(_vaultWallet != address(0), "Invalid vault address");
        admin = msg.sender;
        vaultWallet = _vaultWallet;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        admin = _newAdmin;
    }

    function setVaultAddress(address payable _vaultWallet) public onlyAdmin {
        require(_vaultWallet != address(0), "Invalid vault address");
        vaultWallet = _vaultWallet;
    }

    // set price for one package, price is wei format
    function setPackage(uint256 projectId, uint256 packageId, uint256 price) public onlyAdmin {
        require(projectId > 0, 'Invalid projectId');
        require(packageId > 0, 'Invalid packageId');
        require(price > 0, 'Invalid price');

        packages[projectId][packageId] = price;
    }

    function setPackages(uint256[] calldata projectIds, uint256[] calldata packageIds, uint256[] calldata prices) public onlyAdmin {
        require(projectIds.length == packageIds.length, 'Invalid length');
        require(projectIds.length == prices.length, 'Invalid length');

        for(uint256 idx = 0; idx < projectIds.length; idx++) {
            setPackage(projectIds[idx], packageIds[idx], prices[idx]);
        }
    }

    function purchasePackage(uint256 projectId, uint256 packageId) external payable {
        require(packages[projectId][packageId] > 0, "Invalid project || package");
        require(msg.value >= packages[projectId][packageId], "Wrong price value!");

        vaultWallet.transfer(msg.value);
        counters[msg.sender] += 1;

        emit PurchasePackage(projectId, packageId, counters[msg.sender]);
    }
}