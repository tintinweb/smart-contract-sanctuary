/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract CheckoutManager {

    address public admin;
    address payable public vaultWallet;
    
    event BuyItems(string orderId, string buyerId, address buyer, string[] itemIds, uint256[] amounts);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address payable _vaultWallet) {
        require(_vaultWallet != address(0), "Invalid vault address");
        admin = msg.sender;
        vaultWallet = _vaultWallet;
    }

    function buyItems(string calldata orderId, string calldata buyerId, string[] calldata itemIds, uint256[] calldata amounts) external payable {
        require(msg.value > 0, "Wrong ETH value!");
        require(itemIds.length > 0, "No items");
        require(itemIds.length == amounts.length, "Items and amounts length should be the same");

        vaultWallet.transfer(msg.value);

        emit BuyItems(orderId, buyerId, msg.sender, itemIds, amounts);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        
        admin = _newAdmin;
    }

    function setVaultAddress(address payable _vaultWallet) public onlyAdmin {
        require(_vaultWallet != address(0), "Invalid vault address");
        
        vaultWallet = _vaultWallet;
    }
}