/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MU_Membership is Ownable{
    // gold card owner : {address: owner, uint: price}
    // // if price == 0, owner is not going to sell 
    // // if price != 0, owner is going to sell
    receive() payable external {
    }

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
    uint constant gold_price = 15e18;
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


    //////////////////////////////////////////////
    //////////        gold            ////////////
    //////////////////////////////////////////////

    // gold card buy (MU -> user)
    function gold_buy() public payable {
        // require : original card is remaining.
        require( gold_owner_count < gold_max );
        // require : ETH is greater than gold card price
        require( msg.value == gold_price );
        // register new gold owner
        gold_list[gold_owner_count] = Gold(msg.sender, 0, false);
        gold_owner_count++;
        emit GoldPurchased(msg.sender, 0, false);
    }
    // are going to sell gold card
    // check if the function caller is gold card owner 
    function gold_sell(uint card_id, uint _price) public payable returns(bool) {
        // require : there is gold card with `card_id`
        require(card_id < gold_owner_count, "Card ID can not be exceed current card owners amount");
        // require : can not card price as zero or negative 
        require(_price > 0, "Card price need to be set greater than zero.");
        gold_list[card_id].price = _price;
        emit GoldSell(msg.sender, gold_list[card_id].price, gold_list[card_id].sell_approve);
        return true;
    }
    // approve gold card buy request
    function gold_approve (uint card_id) public returns(bool) {
        // require : card_id need to be less than card owners amount
        require(card_id < gold_owner_count, "Card id has to be less than card owner amount");
        // require : only card owner can approve the card selling
        require(msg.sender == gold_list[card_id].owner, "Only card owner can approve the card selling");
        gold_list[card_id].sell_approve = true;
        emit GoldApprove(msg.sender, gold_list[card_id].price, gold_list[card_id].sell_approve);
        return true;
    }
    // gold card buy (user -> user)
    function gold_request_buy (uint card_id) public payable {
        // require: card is placed on the sell list
        require( gold_list[card_id].price > 0 );
        // require: request buy is greater than minimum price
        require( msg.value == gold_list[card_id].price );
        // require : check if card owner approves the request
        require( gold_list[card_id].sell_approve == true );
        // transfer ETH from new owner to old owner
        gold_list[card_id].owner.transfer(msg.value);
        // move the card ownership from old owner to new owner
        gold_list[card_id].owner = msg.sender;
        gold_list[card_id].sell_approve = false;
        gold_list[card_id].price = 0;
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
        require( msg.value == silver_price );
        // register new silver owner
        silver_list[silver_owner_count] = Silver(msg.sender, 0, false);
        silver_owner_count++;
        emit SilverPurchased(msg.sender, 0, false);
    }
    // are going to sell silver card
    // check if the function caller is silver card owner 
    function silver_sell(uint card_id, uint _price) public payable returns(bool) {
        // require : there is silver card with `card_id`
        require(card_id < silver_owner_count, "Card ID can not be exceed current card owners amount");
        // require : can not card price as zero or negative 
        require(_price > 0, "Card price need to be set greater than zero.");
        silver_list[card_id].price = _price;
        emit SilverSell(msg.sender, silver_list[card_id].price, silver_list[card_id].sell_approve);
        return true;
    }
    // approve silver card buy request
    function silver_approve (uint card_id) public returns(bool) {
        // require : card_id need to be less than card owners amount
        require(card_id < silver_owner_count, "Card id has to be less than card owner amount");
        // require : only card owner can approve the card selling
        require(msg.sender == silver_list[card_id].owner, "Only card owner can approve the card selling");
        silver_list[card_id].sell_approve = true;
        emit SilverApprove(msg.sender, silver_list[card_id].price, silver_list[card_id].sell_approve);
        return true;
    }
    // silver card buy (user -> user)
    function silver_request_buy (uint card_id) public payable {
        // require: card is placed on the sell list
        require( silver_list[card_id].price > 0 );
        // require: request buy is greater than minimum price
        require( msg.value == silver_list[card_id].price );
        // require : check if card owner approves the request
        require( silver_list[card_id].sell_approve == true );
        // transfer ETH from new owner to old owner
        silver_list[card_id].owner.transfer(msg.value);
        // move the card ownership from old owner to new owner
        silver_list[card_id].owner = msg.sender;
        silver_list[card_id].sell_approve = false;
        silver_list[card_id].price = 0;
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
        require( msg.value == bronze_price );
        // register new bronze owner
        bronze_list[bronze_owner_count] = Bronze(msg.sender, 0, false);
        bronze_owner_count++;
        emit BronzePurchased(msg.sender, 0, false);
    }
    // are going to sell bronze card
    // check if the function caller is bronze card owner 
    function bronze_sell(uint card_id, uint _price) public payable returns(bool) {
        // require : there is bronze card with `card_id`
        require(card_id < bronze_owner_count, "Card ID can not be exceed current card owners amount");
        // require : can not card price as zero or negative 
        require(_price > 0, "Card price need to be set greater than zero.");
        bronze_list[card_id].price = _price;
        emit BronzeSell(msg.sender, bronze_list[card_id].price, bronze_list[card_id].sell_approve);
        return true;
    }
    // approve bronze card buy request
    function bronze_approve (uint card_id) public returns(bool) {
        // require : card_id need to be less than card owners amount
        require(card_id < bronze_owner_count, "Card id has to be less than card owner amount");
        // require : only card owner can approve the card selling
        require(msg.sender == bronze_list[card_id].owner, "Only card owner can approve the card selling");
        bronze_list[card_id].sell_approve = true;
        emit BronzeApprove(msg.sender, bronze_list[card_id].price, bronze_list[card_id].sell_approve);
        return true;
    }
    // bronze card buy (user -> user)
    function bronze_request_buy (uint card_id) public payable {
        // require: card is placed on the sell list
        require( bronze_list[card_id].price > 0 );
        // require: request buy is greater than minimum price
        require( msg.value == bronze_list[card_id].price );
        // require : check if card owner approves the request
        require( bronze_list[card_id].sell_approve == true );
        // transfer ETH from new owner to old owner
        bronze_list[card_id].owner.transfer(msg.value);
        // move the card ownership from old owner to new owner
        bronze_list[card_id].owner = msg.sender;
        bronze_list[card_id].sell_approve = false;
        bronze_list[card_id].price = 0;
        emit BronzeBought(msg.sender, bronze_list[card_id].price, bronze_list[card_id].sell_approve);
    }    

    function reclaimETH() external onlyOwner{
        msg.sender.transfer(address(this).balance);
    }
}