/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.6.0;

contract Membership {
    // gold card owner : {address: owner, uint: price}
    // // if price == 0, owner is not going to sell 
    // // if price != 0, owner is going to sell
    struct Gold {
        address payable owner;
        uint price;
        bool sell_approve;
    }
    // gold card owner list
    mapping (uint => Gold) public gold_list;
    // gold card owner account
    uint public gold_owner_count = 0;
    // gold card default price
    uint constant gold_price = 1e19;
    // gold card max amount
    uint constant gold_max = 15;
    event GoldPurchased (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event GoldSell (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event GoldApprove (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event GoldBought (
        address payable owner,
        uint price,
        bool sell_approve
    );

    struct Silver {
        address payable owner;
        uint price;
        bool sell_approve;
    }
    // silver card owner list
    mapping (uint => Silver) public silver_list;
    // silver card owner account
    uint public silver_owner_count = 0;
    // silver card default price
    uint constant silver_price = 1e18;
    // silver card max amount
    uint constant silver_max = 150;
    event SilverPurchased (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event SilverSell (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event SilverApprove (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event SilverBought (
        address payable owner,
        uint price,
        bool sell_approve
    );    

    struct Bronze {
        address payable owner;
        uint price;
        bool sell_approve;
    }
    // bronze card owner list
    mapping (uint => Bronze) public bronze_list;
    // bronze card owner account
    uint public bronze_owner_count = 0;
    // bronze card default price
    uint constant bronze_price = 25e16;
    // bronze card max amount
    uint constant bronze_max = 1500;
    event BronzePurchased (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event BronzeSell (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event BronzeApprove (
        address payable owner,
        uint price,
        bool sell_approve
    );
    event BronzeBought (
        address payable owner,
        uint price,
        bool sell_approve
    );        
    // gold card buy (MU -> user)
    function gold_buy() public payable {
        // require : original card is remaining.
        require( gold_owner_count < gold_max );
        // require : ETH is greater than gold card price
        require( msg.value >= gold_price );
        // register new gold owner
        gold_list[gold_owner_count] = Gold(msg.sender, 0, false);
        gold_owner_count++;
        emit GoldPurchased(msg.sender, 0, false);
    }
    // are going to sell gold card
    // check if the function caller is gold card owner 
    function gold_sell(uint _price) public payable returns(bool) {
        for (uint i = 0 ; i < gold_owner_count ; i++) {
            if (gold_list[i].owner == msg.sender) {
                gold_list[i].price = _price;
                emit GoldSell(msg.sender, gold_list[i].price, gold_list[i].sell_approve);
                return true;
            }
        }
        emit GoldSell(msg.sender, 0, false);
        return false;
    }
    // approve gold card buy request
    function gold_approve () public returns(bool) {
        for (uint i = 0 ; i < gold_owner_count ; i++) {
            if (gold_list[i].owner == msg.sender) {
                gold_list[i].sell_approve = true;
                emit GoldApprove(msg.sender, gold_list[i].price, gold_list[i].sell_approve);
                return true;
            }
        }
        return false;
    }
    // gold card buy (user -> user)
    function gold_request_buy (uint card_id) public payable {
        // require: card is placed on the sell list
        require( gold_list[card_id].price > 0 );
        // require: request buy is greater than minimum price
        require( msg.value >= gold_list[card_id].price );
        // require : check if card owner approves the request
        require( gold_list[card_id].sell_approve == true );
        // transfer ETH from new owner to old owner
        address(gold_list[card_id].owner).transfer(msg.value);
        // move the card ownership from old owner to new owner
        gold_list[card_id].owner = msg.sender;
        gold_list[card_id].sell_approve = false;
        emit GoldBought(msg.sender, gold_list[card_id].price, gold_list[card_id].sell_approve);
    }
    //////////////////////////////////////////////
    //////////        silver          ////////////
    //////////////////////////////////////////////
    // silver card buy (MU -> user)
    function silver_buy() public payable {
        // require : original card is remaining.
        require( silver_owner_count < silver_max );
        // require : ETH is greater than silver card price
        require( msg.value >= silver_price );
        // register new silver owner
        silver_list[silver_owner_count] = Silver(msg.sender, 0, false);
        silver_owner_count++;
        emit SilverPurchased(msg.sender, 0, false);
    }
    // are going to sell silver card
    // check if the function caller is silver card owner 
    function silver_sell(uint _price) public payable returns(bool) {
        for (uint i = 0 ; i < silver_owner_count ; i++) {
            if (silver_list[i].owner == msg.sender) {
                silver_list[i].price = _price;
                emit SilverSell(msg.sender, silver_list[i].price, silver_list[i].sell_approve);
                return true;
            }
        }
        emit SilverSell(msg.sender, 0, false);
        return false;
    }
    // approve silver card buy request
    function silver_approve () public returns(bool) {
        for (uint i = 0 ; i < silver_owner_count ; i++) {
            if (silver_list[i].owner == msg.sender) {
                silver_list[i].sell_approve = true;
                emit SilverApprove(msg.sender, silver_list[i].price, silver_list[i].sell_approve);
                return true;
            }
        }
        return false;
    }
    // silver card buy (user -> user)
    function silver_request_buy (uint card_id) public payable {
        // require: card is placed on the sell list
        require( silver_list[card_id].price > 0 );
        // require: request buy is greater than minimum price
        require( msg.value >= silver_list[card_id].price );
        // require : check if card owner approves the request
        require( silver_list[card_id].sell_approve == true );
        // transfer ETH from new owner to old owner
        address(silver_list[card_id].owner).transfer(msg.value);
        // move the card ownership from old owner to new owner
        silver_list[card_id].owner = msg.sender;
        silver_list[card_id].sell_approve = false;
        emit SilverBought(msg.sender, silver_list[card_id].price, silver_list[card_id].sell_approve);
    }    
    //////////////////////////////////////////////
    //////////        Bronze          ////////////
    //////////////////////////////////////////////
    // bronze card buy (MU -> user)
    function bronze_buy() public payable {
        // require : original card is remaining.
        require( bronze_owner_count < bronze_max );
        // require : ETH is greater than bronze card price
        require( msg.value >= bronze_price );
        // register new bronze owner
        bronze_list[bronze_owner_count] = Bronze(msg.sender, 0, false);
        bronze_owner_count++;
        emit BronzePurchased(msg.sender, 0, false);
    }
    // are going to sell bronze card
    // check if the function caller is bronze card owner 
    function bronze_sell(uint _price) public payable returns(bool) {
        for (uint i = 0 ; i < bronze_owner_count ; i++) {
            if (bronze_list[i].owner == msg.sender) {
                bronze_list[i].price = _price;
                emit BronzeSell(msg.sender, bronze_list[i].price, bronze_list[i].sell_approve);
                return true;
            }
        }
        emit BronzeSell(msg.sender, 0, false);
        return false;
    }
    // approve bronze card buy request
    function bronze_approve () public returns(bool) {
        for (uint i = 0 ; i < bronze_owner_count ; i++) {
            if (bronze_list[i].owner == msg.sender) {
                bronze_list[i].sell_approve = true;
                emit BronzeApprove(msg.sender, bronze_list[i].price, bronze_list[i].sell_approve);
                return true;
            }
        }
        return false;
    }
    // bronze card buy (user -> user)
    function bronze_request_buy (uint card_id) public payable {
        // require: card is placed on the sell list
        require( bronze_list[card_id].price > 0 );
        // require: request buy is greater than minimum price
        require( msg.value >= bronze_list[card_id].price );
        // require : check if card owner approves the request
        require( bronze_list[card_id].sell_approve == true );
        // transfer ETH from new owner to old owner
        address(bronze_list[card_id].owner).transfer(msg.value);
        // move the card ownership from old owner to new owner
        bronze_list[card_id].owner = msg.sender;
        bronze_list[card_id].sell_approve = false;
        emit BronzeBought(msg.sender, bronze_list[card_id].price, bronze_list[card_id].sell_approve);
    }    
}