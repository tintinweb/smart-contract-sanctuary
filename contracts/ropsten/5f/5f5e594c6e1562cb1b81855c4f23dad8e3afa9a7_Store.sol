pragma solidity ^0.4.24;

interface Warehouse {
    function setDeliveryAddress(string where) external;
    function ship(uint id, address customer) external returns (bool handled);
}

contract Store {
    address wallet;
    Warehouse warehouse;

    constructor(address _wallet, address _warehouse) public {
        wallet = _wallet;
        warehouse = Warehouse(_warehouse);
    }

    function purchase(uint id) payable public returns (bool success) {
        wallet.transfer(msg.value);
        return warehouse.ship(id, msg.sender);
    }
}

contract TestWarehouse is Warehouse {
    struct Order {
        string deliveryAddress; // Package destination
        address buyer; // Buyer
        uint id; // Order ID
        bool shipped; // Order shipped
    }

    mapping(address => string) customerDeliveryAddresses; // Delivery addresses
    mapping(uint => Order) orders; // Orders

    function setDeliveryAddress(string where) external {
        customerDeliveryAddresses[msg.sender] = where; // Set delivery address
    }

    function ship(uint id, address customer) external returns (bool handled) {
        if (keccak256(abi.encodePacked(customerDeliveryAddresses[customer])) == keccak256(abi.encodePacked("")) || orders[id].shipped == true) { // Check delivery address set
            return false; // Return failed
        }

        orders[id] = Order(customerDeliveryAddresses[customer], customer, id, true); // Init shipped order
        
        return true; // Return success
    }
}