/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;
pragma abicoder v2;


contract DeliCon {

    //Dev Stage only    
    address payable public owner; 
    
    struct Courier {
        address addr;
        uint256 funds;
        uint256 min_pledge_nonce;
        bool available; 
        address pledged_by;
    }
    
    struct Location {
        string name;
        string street_and_number;
        string zip;
    }
    
    struct Restaurant {
        address addr;
        uint256 funds;
        Location location;
        string phone_number;
        bytes public_key;
        mapping(uint256 => uint256) menu;

    }
    
    struct Pledge {
        uint256 nonce;
        address restaurant;
        uint256 max_time_till_arrival;
        uint256 max_deposit;
        address courier;
        bytes signature;
    }
    
    struct Item {
        uint256 id;
        uint256 quantity;
    }
    
    enum OrderStatus {proposed, restaurant_accepted, confirmed, in_delivery, fulfilled, cancelled}
    
    struct Order {
        uint256 amount;
        string customer_data;
        uint256 number; 
        address restaurant;
        address customer;
        address courier;
        uint256 rest_deposit;
        uint256 cour_deposit;
        OrderStatus status;
        uint256 last_status_change;
        uint256 customer_refund;
    }
    mapping(address => Courier) public couriers;
    mapping(address => Restaurant) public restaurants;
    mapping(uint256 => Order) public orders;
    //Order[] orders;
    
    address[] courier_addrs;
    address[] restaurant_addrs;
    
    
    uint256 order_count;
    uint256 courier_count;
    uint256 restaurant_count;
    
    function courier_register() public {
        
        require(couriers[msg.sender].addr == address(0), "Courier already registered!");
        
        couriers[msg.sender] = Courier(msg.sender, 0, 0, false, address(0));
        courier_addrs.push(msg.sender);
        courier_count++;

    }
    
    event LogCourierDepositFunds(address indexed from, uint256 indexed value);
    
    function courier_deposit_funds() public payable {
        
        require(couriers[msg.sender].addr != address(0), "Called courier_deposit_funds for a not registered courier");
        
        couriers[msg.sender].funds += msg.value;
        
        emit LogCourierDepositFunds(msg.sender,msg.value);
        
    }
    
     function courier_withdraw_funds(uint256 amount, address payable target) public returns (bool) {
        
        require(couriers[msg.sender].addr != address(0), "Called courier_withdraw_funds for a not registered courier");
        
        Courier storage cour = couriers[msg.sender]; 
        if (cour.funds < amount) {
            return false;
        }
 
        cour.funds -= amount;

        if (!target.send(amount)) {
            // No need to call throw here, just reset the amount 
            cour.funds += amount;
            return false;
        }
        return true;
    }
    
    
    /* 
        struct Courier {
        address addr;
        uint256 funds;
        uint256 min_pledge_nonce;
        bool available; 
        address pledged_by;
    }
    */ 
    
    function courier_view(address cour_addr) public view returns (address, uint256, uint256, bool, address) {
        Courier memory cour = couriers[cour_addr];
        
        return (cour.addr, cour.funds, cour.min_pledge_nonce, cour.available, cour.pledged_by);
        
        
    }
    
    function courier_view_addresses() public view returns (address[] memory) {
        return courier_addrs;

        
    }

 // ["test", "test", "test"], "hello", 0xDEADBEEF
    function restaurant_register(Location calldata location, string calldata phone_number, bytes memory public_key) public {
        
        require(restaurants[msg.sender].addr == address(0), "The requested restaurant is already registered.");
                
        Restaurant storage rest = restaurants[msg.sender];

        rest.addr = msg.sender;
        rest.funds = 0;
        rest.location = location;
        rest.phone_number = phone_number;
        rest.public_key = public_key;
        restaurant_addrs.push(msg.sender);
        restaurant_count++;
    }
    
    /* 
        struct Restaurant {
        address  addr;
        uint256 funds;
        Location location;
        string phone_number;
        mapping(uint256 => uint256) menu;

        }
    */
    
    event LogRestaurantDepositFunds(address indexed from, uint256 indexed value);
    
    function restaurant_deposit_funds() public payable {
        
        require(restaurants[msg.sender].addr != address(0), "Called restaurant_deposit_funds for a not registered restaurant");
        
        restaurants[msg.sender].funds += msg.value;
        
        emit LogRestaurantDepositFunds(msg.sender,msg.value);
    }

    function restaurant_withdraw_funds(uint256 amount, address payable target) public returns (bool) {
        
        require(restaurants[msg.sender].addr != address(0), "Called restaurant_withdraw_funds for a not registered restaurant");
        
        Restaurant storage rest = restaurants[msg.sender]; 
        if (rest.funds < amount) {
            return false;
        }
 
        rest.funds -= amount;

        if (!target.send(amount)) {
            // No need to call throw here, just reset the amount 
            rest.funds += amount;
            return false;
        }
        return true;
    }
    
    function restaurant_view(address rest_addr) public view returns(address, uint256, string memory, string memory ,string memory, string memory, bytes memory) {
        Restaurant storage rest = restaurants[rest_addr];
        return (rest.addr, rest.funds, rest.location.name, rest.location.street_and_number, rest.location.zip, rest.phone_number, rest.public_key);
    }
    
    function restaurant_view_addresses() public view returns (address[] memory) {
        return restaurant_addrs;
    }
    
    event LogCustomerCreateOrder(address indexed from, address indexed restaurant_address,uint256 indexed order_nr); 
    // "Some data, hopefully encrypted", 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    function customer_create_order(string calldata customer_data, address restaurant_address) public payable returns (uint256)  {
        
        require(restaurants[restaurant_address].addr != address(0), "You tried to open an order for a not registered restaurant");
        
        Order storage order = orders[order_count];
        order.customer_data = customer_data;
        order.number = order_count;
        order.amount = msg.value;
        order_count++;
        order.restaurant = restaurant_address;
        order.customer = msg.sender;
        order.status = OrderStatus.proposed;
        order.last_status_change = block.timestamp;
        
        emit LogCustomerCreateOrder(msg.sender,restaurant_address,order.number);
        
        return order.number;
        
    }
    
    function restaurant_accept_order(uint256 order_num) payable public {
        require(orders[order_num].restaurant == msg.sender, "You cannot accept this order, it's for another restaurant");
        require(orders[order_num].status == OrderStatus.proposed, "You cannot accept this order, status is not proposed");
        /* Well restaurants actually don't need funds */
        require((restaurants[msg.sender].funds + msg.value) >= orders[order_num].amount, "You don't have enough funds to cover the deposit.");
        
        Restaurant storage rest = restaurants[msg.sender];
        Order storage order = orders[order_num];
        
        
        /* Add funds and pay the deposit */
        rest.funds += msg.value;
        rest.funds -= order.amount;
        
        /* If you make no mistakes this is not necessary, but if you are agile and want to jump high you better have a safety net */ 
        order.rest_deposit = order.amount; 
        
        order.status = OrderStatus.restaurant_accepted;
        order.last_status_change = block.timestamp;
    }

    function restaurant_pledge_courier(uint256 nonce, address restaurant_address, uint256 max_time_till_arrival, uint256 max_deposit, address courier_address, bytes calldata signature, uint256 order_num) public {
       
        require(restaurants[restaurant_address].addr != address(0), "Called restaurant_pledge_courier for a not registered restaurant");
        require(couriers[courier_address].addr != address(0), "Called restaurant_pledge_courier for a not registered courier");
        
        require(couriers[courier_address].funds >= orders[order_num].amount, "The given courier has not enough funds to cover the deposit");
        require(couriers[courier_address].available == true, "The given courier is currently not available");
        require(nonce >= couriers[courier_address].min_pledge_nonce, "The courier revoked the given pledge");
        
        require(orders[order_num].restaurant == msg.sender, "You are not the restaurant of the given order");
        require(orders[order_num].status == OrderStatus.restaurant_accepted, "The status of the given order is not restaurant_accepted");
        
        Courier storage p_courier = couriers[courier_address];
        Order storage order = orders[order_num];
        bytes32 message;
        
        message = _prefixed(keccak256(abi.encodePacked(nonce, msg.sender, max_time_till_arrival, max_deposit, courier_address, this)));
        require(_recoverSigner(message, signature) == courier_address, "Signature is not valid");
    
        p_courier.available = false;
        p_courier.pledged_by = msg.sender;
        
        p_courier.funds -= order.amount;
        order.cour_deposit = order.amount;
        
        order.status = OrderStatus.confirmed;
        /* Not 100% clear, but to prevent the restaurant from cheating this does not update the status */
    }
    function restaurant_reclaim_deposit(uint256 order_num, bytes calldata signature) public {
        require(orders[order_num].restaurant == msg.sender);
        require(orders[order_num].rest_deposit > 0);
        
        Order storage order = orders[order_num];
        Restaurant storage rest = restaurants[order.restaurant];
        require(is_valid_release_signature(order.courier, signature, order_num));
        
        rest.funds += order.rest_deposit;
        order.rest_deposit = 0;
    }
    function courier_reclaim_deposit(uint256 order_num, bytes calldata signature) public {
        require(orders[order_num].courier == msg.sender);
        require(orders[order_num].cour_deposit > 0);
        
        Order storage order = orders[order_num];
        Courier storage cour = couriers[order.courier];
        require(is_valid_release_signature(order.customer, signature, order_num));
        
        cour.funds += order.cour_deposit;
        order.cour_deposit = 0;
    }
    
    
    function is_valid_release_signature(address signer, bytes calldata signature, uint256 order_num) internal view returns(bool) {
        bytes32 release_data;
        
        release_data = prefixed_bytes(abi.encodePacked(order_num, this));
        return _recoverSigner(release_data, signature) == signer;
    }
    
    function customer_current_cancel_order_percentage(uint256 order_num) public view returns (uint256) {
        require(orders[order_num].customer == msg.sender, "You can only request details for your own order");
        
        Order memory order = orders[order_num];
        
        if (order.status == OrderStatus.proposed) {
            return 100;
        } 
        
        uint256 time_since_last_status_change = block.timestamp - order.last_status_change;
        
        if (order.status == OrderStatus.restaurant_accepted || order.status == OrderStatus.confirmed) {
            if (time_since_last_status_change <= 30 minutes) {
                return 0;
            }
            if (time_since_last_status_change > 30 minutes && time_since_last_status_change < 120 minutes) {
                return (time_since_last_status_change / 1 minutes) - 30;
            }
            if (time_since_last_status_change >= 120 minutes) {
                return 100;
            }
        }
        if (order.status == OrderStatus.in_delivery) {
        
             if (time_since_last_status_change <= 30 minutes) {
                return 0;
            }
            if (time_since_last_status_change > 30 minutes && time_since_last_status_change < 60 minutes) {
                return (((time_since_last_status_change / 1 minutes) + 30) * order.amount);
            }
            if (time_since_last_status_change >= 60 minutes) {
                return 100;
            }
        }
        require(true == false, "Reached unreachable code!");
        return 0;
    }
    

    
    function customer_current_cancel_order_payout(uint256 order_num) public view returns (uint256) {
        /* I would not call it privacy, but it stops the intersection between nosy and lazy ;) */
        require(orders[order_num].customer == msg.sender, "You can only request details for your own order");
        
        Order memory order = orders[order_num];
        uint256 percentage = customer_current_cancel_order_percentage(order_num);
        
        require(percentage <= 100, "Calculated percentage for this order is above 100. Something is wrong.");
        
    
        
        return (percentage * order.amount) / 100;
    }
   
    function customer_cancel_order(uint256 order_num, uint256 min_expected_payout) public returns (bool successful, uint256 payout) {
        require(orders[order_num].customer == msg.sender, "You can only cancel your own orders");
        require(orders[order_num].status != OrderStatus.fulfilled, "You can not cancel an already fulfilled contract");
        
        Order storage order = orders[order_num];
        payout = customer_current_cancel_order_payout(order_num);
        
        if (min_expected_payout > payout) {
            successful = false;
            return (successful, payout);
        }
        
        successful = true;
        order.status = OrderStatus.cancelled;
        order.last_status_change = block.timestamp;
        order.customer_refund = payout;
       
        return (successful, payout);
    }
    
 function customer_claim_refund(uint256 order_num, address payable target) public returns (bool) {
        require(orders[order_num].customer == msg.sender, "You can only claim your own refunds");
        require(orders[order_num].status != OrderStatus.cancelled, "You can only claim refunds for cancelled Orders");
        //require((block.timestamp - orders[order_num].last_status_change) >= 24 hours, "You can claim your refunds when 24 hours have passed since the cancelation");
        require(orders[order_num].customer_refund > 0, "You already claimed this refund");
        

        Order storage order = orders[order_num];
        uint256 customer_refund = order.customer_refund;
        
        /* Prevent that rentry */
        order.customer_refund = 0;
        if (!target.send(order.customer_refund)) {
            // No need to call throw here, just reset the amount 
            order.customer_refund = customer_refund;
            return false;
        }
    return true;
    }
    

    function courier_set_available() public{
        require(couriers[msg.sender].addr != address(0), "You are not registered as courier");
        Courier storage p_courier = couriers[msg.sender];
        p_courier.available = true;
    }
    
    constructor () payable {  
        owner = payable(msg.sender);
        order_count = 0;
        courier_count = 0;
        restaurant_count = 0;
    }

    /// All functions below this are just taken from the chapter
    /// 'creating and verifying signatures' chapter.
    /// TODO IMPLEMENT SECURITY CHECKS:
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
    /// https://docs.openzeppelin.com/contracts/2.x/api/cryptography#ECDSA

    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function _recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
        /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed_bytes(bytes memory value) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", value));
    }
    
    function kill() public {
        require(msg.sender == owner, "Only the contract owner can kill the contract, sorry.");
        selfdestruct(owner);
    }
}