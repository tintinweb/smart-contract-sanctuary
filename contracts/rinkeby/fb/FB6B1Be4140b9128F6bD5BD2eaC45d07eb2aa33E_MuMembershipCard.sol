/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address payable public owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address payable newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}



contract MuMembershipCard is Owner {
    
    // define gold card
    uint constant gold_max = 15;
    address[] public gold_owners;
    uint public constant gold_price = 15e18;

    // define silver card
    uint constant silver_max = 150;
    address[] public silver_owners;
    uint public constant silver_price = 1e18;

    // define bronze card
    uint constant bronze_max = 1500;
    address[] public bronze_owners;
    uint public constant bronze_price = 25e16;
    
    // smart contract balance
    uint public total_balance = address(this).balance;

    event CardPurchased(address indexed userAdd, string cardType, uint256 date);

    
    // function purchase original gold card
    function purchase_gold() public payable {
        uint sold_gold = gold_owners.length;
        uint remaining_gold = gold_max - sold_gold;
        // require gold card is available to purchase
        require(remaining_gold > 0);
        // require transaction has enough balance
        require(msg.value == gold_price);
        // // register purchaseOwner into the gold owner list
        gold_owners.push(msg.sender);
        owner.transfer(msg.value);
        emit CardPurchased(msg.sender,"Gold",block.timestamp);
        
    }
 
    // function get sold gold card amount
    function get_gold_owner_count() public view returns(uint) {
        return gold_owners.length;
    }

    // function purchase original silver card
    function purchase_silver() public payable{
        uint sold_silver = silver_owners.length;
        uint remaining_silver = silver_max - sold_silver;
        // require silver card is available to purchase
        require(remaining_silver > 0);
        // require transaction has enough balance
        require(msg.value == silver_price);
        // register purchaseOwner into the silver owner list
        silver_owners.push(msg.sender);
        owner.transfer(msg.value);
        emit CardPurchased(msg.sender,"Silver",block.timestamp);
        
    }

    // function get sold silver card amount
    function get_silver_owner_count() public view returns(uint) {
        return silver_owners.length;
    }

    // function purchase original bronze card
    function purchase_bronze() public payable{
        uint sold_bronze = bronze_owners.length;
        uint remaining_bronze = bronze_max - sold_bronze;
        // require bronze card is available to purchase
        require(remaining_bronze > 0);
        // require transaction has enough balance
        require(msg.value == bronze_price);
        // register purchaseOwner into the bronze owner list
        bronze_owners.push(msg.sender);
        owner.transfer(msg.value);
        emit CardPurchased(msg.sender,"Bronze",block.timestamp);
        
    }
   
    // function get sold bronze card amount
    function get_bronze_owner_count() public view returns(uint) {
        return bronze_owners.length;
    }
    
    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }
    
    // Withdraws Crypto in the Contract only by Owner
    function withdrawCrypto(address payable beneficiary) public isOwner {
        beneficiary.transfer(address(this).balance);
    }
}