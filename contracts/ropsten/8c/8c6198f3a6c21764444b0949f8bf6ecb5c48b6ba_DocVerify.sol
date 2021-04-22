/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-26
 *  Order ID: 103
Owner: testuser
Series: call me kate
Title: as written in backend
Episodes: 5-8
Rarity Level: rare,unique,normal,normal
Print Run: 1000
Copy: 5 of 1000
Date of Transaction: 2021-03-12
Price Paid: 1596 coins
Gas Fee: 0.41$
Cheebes ID: 101,102,103,104
Transaction Page: https://fireclaw.com.ua/
*/

pragma solidity ^0.4.11;

contract DocVerify {
   
    address public creator;
    uint public numDocuments;
    string order_id;
    string owner;
    string series;
    string title;
    string episodes;
    string rarity_level;
    string print_run;
    string copy;
    string date_of_transaction;
    string print_paid;
    string gas_fee;
    string Cheebes_id;
    string transaction_page;
    uint public date;
    function newdocument(string hash,string order_id,string owner,string series,string title,string episodes,string rarity_level,
    string print_run,string copy,string date_of_transaction,string price_paid,string gas_fee,string Cheebes_id,string transaction_page) public  returns (bool success){ 
        if (documentExists(date)) {
            success = false;
        }else {
        order_id = order_id;
        owner = owner;
        series = series;
        title = title;
        episodes = episodes;
        rarity_level = rarity_level;
        print_run = print_run;
        date_of_transaction = date_of_transaction;
        price_paid = price_paid;
        gas_fee = gas_fee;
        Cheebes_id = Cheebes_id;
        transaction_page =transaction_page;
        hash = hash;
        copy = copy;
        date = now;
        numDocuments++;
        success = true;
        }
       return success;
    
    }
    
    function documentExists(uint date) public  returns (bool exists) {
        if (date > 0) {
            exists = true;
        } else {
            exists = false;
        }
        return exists;
    }
    
    function getDocument() public returns (uint date, address owner) {
        date = date;
        owner = owner;
    }
    
     function getNumDocs() public  returns (uint numDocs) {
        return numDocuments;
    }


}