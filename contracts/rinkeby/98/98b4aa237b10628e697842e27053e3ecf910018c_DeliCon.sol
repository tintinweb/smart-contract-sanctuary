/**
 *Submitted for verification at Etherscan.io on 2021-06-18
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
        address  addr;
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
    
    struct Order {
        string customer_data;
        uint256 number; 
        address restaurant;
        address customer;
        address courier;
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
    
    function register_courier() public payable {
        couriers[msg.sender] = Courier(msg.sender, 0, 0, false, address(0));
        courier_addrs.push(msg.sender);
        courier_count++;
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
    function show_courier(address cour_addr) public view returns (address, uint256, uint256, bool, address) {
        Courier memory cour = couriers[cour_addr];
        return (cour.addr, cour.funds, cour.min_pledge_nonce, cour.available, cour.pledged_by);
    }
    function show_courier_addresses() public view returns (address[] memory) {
        return courier_addrs;
    }
    
    // ["test", "test", "test"], "hello", 0xDEADBEEF
    function register_restaurant(Location calldata location, string calldata phone_number, bytes memory public_key) public {
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
    
    function show_restaurant(address rest_addr) public view returns(address, uint256, string memory, string memory ,string memory, string memory, bytes memory) {
        Restaurant storage rest = restaurants[rest_addr];
        return (rest.addr, rest.funds, rest.location.name, rest.location.street_and_number, rest.location.zip, rest.phone_number, rest.public_key);
    }
    
    function show_restaurant_addresses() public view returns (address[] memory) {
        return restaurant_addrs;
    }
    
    
    // "Some data, hopefully encrypted", 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    function open_order(string calldata customer_data, address restaurant) public returns (uint256)  {
        Order storage order = orders[order_count];
        order.customer_data = customer_data;
        order.number = order_count;
        order_count++;
        order.restaurant = restaurant;
        order.customer = msg.sender;
        return order.number;
    }

    //function restaurant_pledge_courier(Pledge memory c_pledge) public {
    function restaurant_pledge_courier(uint256 nonce, address restaurant_address, uint256 max_time_till_arrival, uint256 max_deposit, address courier_address, bytes calldata signature) public {
        Courier memory p_courier = couriers[courier_address];
        bytes32 message;
        
        message = prefixed(keccak256(abi.encodePacked(nonce, msg.sender, max_time_till_arrival, max_deposit, courier_address, this)));
        require(recoverSigner(message, signature) == courier_address);
        //require(p_courier.available == true);
        
        ///require(c_pledge.nonce >= c_pledge.courier.min_pledge_nonce);
        p_courier.available = false;
        p_courier.pledged_by = msg.sender;

        couriers[courier_address] = p_courier;

    }
    
    /* Just for testing */ 
    function unpledge_courier(address cour_addr) public{
        Courier memory p_courier = couriers[cour_addr];
        
        p_courier.pledged_by = address(0);
        p_courier.available = true;
        couriers[cour_addr] = p_courier;
    }
    
    /* just for testing */
    function pledge_without_sig(uint256 nonce, address restaurant_address, uint256 max_time_till_arrival, uint256 max_deposit, address courier_address) public{
        Courier memory p_courier = couriers[courier_address];
        
        require(p_courier.available == true);
        require(nonce >= p_courier.min_pledge_nonce);
        
        p_courier.available = false;
        p_courier.pledged_by = msg.sender;
        
        couriers[courier_address] = p_courier;
    }

    constructor () payable{  
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

    function splitSignature(bytes memory sig)
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

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function kill() public {
        require(msg.sender == owner, "Only the contract owner can kill the contract, sorry.");
        selfdestruct(owner);
    }
}