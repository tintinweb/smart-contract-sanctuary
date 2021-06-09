/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;


contract SimplePledging {

    address payable public owner; 
    struct Courier {
        address payable addr;
        uint256 funds;
        uint256 min_pledge_nonce;
        bool available; 
        address pledged_by;
    }
    
    struct Pledge {
        uint256 nonce;
        address restaurant;
        uint256 max_time_till_arrival;
        uint256 max_deposit;
        address courier;
        bytes signature;
    }
    mapping(address => Courier) public couriers;

    function register_courier() public {
        couriers[msg.sender] = Courier(msg.sender, 0, 0, false, address(0));
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
}