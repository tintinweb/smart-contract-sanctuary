// SPDX-License-Identifier: SpaceSeven

pragma solidity >=0.7.0 <0.9.0;

import "./i_inventory_control.sol";

contract InventoryControl is IInventoryControl {
    // Added admin
    event AdminAdded(address indexed _sender, address indexed _admin);
    // Deleted admin
    event AdminDeleted(address indexed _sender, address indexed _admin);
    // Added seller
    event SellerAdded(address indexed _sender, address indexed _admin);
    // Deleted seller
    event SellerDeleted(address indexed _sender, address indexed _admin);

    // admin => access
    mapping(address => bool) private admin;
    // seller => access
    mapping(address => bool) private seller;

    modifier onlyAdmin() {
        require(admin[msg.sender], "This operation only for admin");
        _;
    }

    constructor() {
        admin[msg.sender] = true;
    }

    // Adding new admin
    function addAdmin__(address _admin) external
    onlyAdmin
    {
        admin[_admin] = true;
        emit AdminAdded(msg.sender, _admin);
    }

    // Deleting exists admin
    function delAdmin__(address _admin) external
    onlyAdmin
    {
        require(msg.sender != _admin, "You can't delete yourself");
        delete admin[_admin];
        emit AdminDeleted(msg.sender, _admin);
    }

    // Adding new seller
    function addSeller__(address _seller) external
    onlyAdmin
    {
        seller[_seller] = true;
        emit SellerAdded(msg.sender, _seller);
    }

    // Deleting exists seller
    function delSeller__(address _seller) external
    onlyAdmin
    {
        delete seller[_seller];
        emit SellerDeleted(msg.sender, _seller);
    }

    function isControl__() override external pure returns (bool) {
        return true;
    }

    function isSeller__(address _sender) override external view returns (bool) {
        return seller[_sender];
    }
}