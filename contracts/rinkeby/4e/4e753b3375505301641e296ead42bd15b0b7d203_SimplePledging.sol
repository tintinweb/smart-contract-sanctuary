/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;


contract SimplePledging {

    address payable public owner; 
    struct Courier {
        address payable addr;
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
        address payable addr;
        uint256 funds;
        Location location;
        string phone_number;
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
        Item[] items;
        Location location;
        uint256 number; 
        address restaurant;
        address customer;
        address courier;
    }
    mapping(address => Courier) public couriers;
    mapping(address => Restaurant) public restaurants;
    mapping(uint256 => Order) public orders;
    //Order[] orders;
    
    uint256 order_count;
    
    function register_courier() public {
        couriers[msg.sender] = Courier(msg.sender, 0, 0, false, address(0));
    }
    
    // ["test", "test", "test"], "hello"
    function register_restaurant(Location calldata location, string calldata phone_number) public {
        Restaurant storage rest = restaurants[msg.sender];
        rest.addr = msg.sender;
        rest.funds = 0;
        rest.location = location;
        rest.phone_number = phone_number;
    }
    // [[0,0]], ["test","test","test"], 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    function open_order(Item[] calldata items, Location calldata location, address restaurant) public {
        Order storage order = orders[order_count];
        for (uint i = 0; i < items.length; i++){
            order.items.push(Item(items[i].id, items[i].quantity));
        }
        order.location = location;
        order.number = order_count;
        order_count++;
        order.restaurant = restaurant;
        order.customer = msg.sender;
    }

    //function restaurant_pledge_courier(Pledge memory c_pledge) public {
    function restaurant_pledge_courier(uint256 nonce, address restaurant_address, uint256 max_time_till_arrival, uint256 max_deposit, address courier_address, bytes calldata signature) public {
        Courier memory p_courier = couriers[courier_address];
        bytes32 message;
        
        message = prefixed(keccak256(abi.encodePacked(nonce, msg.sender, max_time_till_arrival, max_deposit, courier_address, this)));
        require(recoverSigner(message, signature) == courier_address);
        require(p_courier.available == true);
        
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
    


    constructor () {  
        owner = payable(msg.sender);
        order_count = 0;
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