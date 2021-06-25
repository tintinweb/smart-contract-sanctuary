/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.8.1;
//import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./2_Owner.sol";

contract Escrow is Owner {
    uint public claimTime;
    uint public price; // wei ethers
    uint public stock;
    address public vendor;
    
    struct Transaction {
        uint value;
        uint timestamp;
        bool claimBuyer;
        bool claimVendor;
        bool paid;
    }
    mapping(address => Transaction[]) public soldCakes;

    event BuyCake(address, uint, uint, uint8, uint);
    event ClaimBuyer(address, uint);
    
    function init(uint _claimTime, uint _price, uint _stock, address _vendor) isOwner public {
        claimTime = _claimTime;
        price = _price;
        stock = _stock;
        vendor = _vendor;
        //uint pa = price * _stock;
        //require(pa / _stock == price);
    }
    
    function add(uint _quantitySuppl) isOwner public {
        stock += _quantitySuppl;
    }

    function buy(uint8 _quantity) public payable returns (uint) {
        uint value = price * _quantity;
        require(value / _quantity == price);
        require(_quantity <= stock, "stock insuffisant");
        require(msg.value >= price * uint(_quantity), "Pay required amount");
       
        soldCakes[msg.sender].push(Transaction(value, block.timestamp, false, false, false));
        uint txId = soldCakes[msg.sender].length - 1;
        stock -= _quantity;

        emit BuyCake(msg.sender, txId, price, _quantity, block.timestamp);
        
        return txId;
    }


    function claimBuyer(uint txId) public {
        require(block.timestamp < claimTime + soldCakes[msg.sender][txId].timestamp, "Claim time out");
        soldCakes[msg.sender][txId].claimBuyer = true;
        
        emit ClaimBuyer(msg.sender, txId);
    }

    function claimVendor(address buyer, uint txId) public {
        require(msg.sender == vendor, "Only vendor can call this claim");
        require(block.timestamp <= claimTime + soldCakes[buyer][txId].timestamp, "Claim time out");
        soldCakes[buyer][txId].claimVendor = true;
    }
    
    function getFundsVendor(address buyer, uint txId) public {
        require(msg.sender == vendor, "Only vendor can call this claim");
        require(block.timestamp > claimTime + soldCakes[buyer][txId].timestamp, "Claim time not expired");
        require(!soldCakes[buyer][txId].claimBuyer && !soldCakes[buyer][txId].claimVendor
                && !soldCakes[buyer][txId].paid);
        soldCakes[buyer][txId].paid = true;
        payable(vendor).transfer(soldCakes[buyer][txId].value);
    }

    function getRefundBuyer(uint txId) public {
        require(block.timestamp > claimTime + soldCakes[msg.sender][txId].timestamp, "Claim time not expired");
        require(soldCakes[msg.sender][txId].claimBuyer && !soldCakes[msg.sender][txId].claimVendor
                && !soldCakes[msg.sender][txId].paid);
        soldCakes[msg.sender][txId].paid = true;
        payable(msg.sender).transfer(soldCakes[msg.sender][txId].value);
    }

    function vendorRefundBuyer(address buyer, uint txId) public {    
        require(msg.sender == vendor, "Only vendor can call this claim");
        //require(block.timestamp > claimTime + soldCakes[buyer][txId].timestamp, "Claim time not expired");
        require(soldCakes[buyer][txId].claimBuyer 
                && !soldCakes[buyer][txId].paid);
        soldCakes[buyer][txId].paid = true;
        payable(buyer).transfer(soldCakes[buyer][txId].value);
    }

    function split(address buyer, uint txId) public {
        require(block.timestamp > claimTime + soldCakes[buyer][txId].timestamp, "Claim time not expired");
        require(soldCakes[buyer][txId].claimBuyer && soldCakes[buyer][txId].claimVendor
                && !soldCakes[buyer][txId].paid);
        soldCakes[buyer][txId].paid = true;
        uint demivalue = soldCakes[buyer][txId].value/2;
        payable(buyer).send(demivalue); // send(), not transfer() : if throw in transfer() value would not be sent to vendor
        payable(vendor).send(soldCakes[buyer][txId].value - demivalue);
    }
}