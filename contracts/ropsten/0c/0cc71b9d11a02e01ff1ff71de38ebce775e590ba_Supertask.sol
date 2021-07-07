/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity >=0.7.0 <0.9.0;

contract Supertask {

    address payable[] users;
    uint[] balance;
    address payable constant private admin = payable(0x92Bf51aB8C48B93a96F8dde8dF07A1504aA393fD);
    address payable node;
    address payable seller;
    address payable buyer;
    bool paid;
    bool initiated;
    bool dispatched;
    bool received;
    
    function Initialise(address payable Seller, address payable Buyer) public {
        require(msg.sender == admin, "You are not the admin!");
        require(initiated == false, "The contract has already been initiated.");
        initiated = true;
        node = Seller;
        seller = Seller;
        buyer = Buyer;
    }
    
    function Purchase() public payable {
        require(initiated == true, "The contract have not been initiated yet.");
        require(msg.sender == buyer, "You are not the buyer!");
        if (paid ==  false) {
            users.push(seller);
            balance.push(msg.value);
        } else {
            balance[0] += msg.value;
        }
    }
    
    function Appoint(address payable Proxy) public payable {
        require(initiated == true, "The contract have not been initiated yet.");
        require(msg.sender == node, "You do not have the required authority.");
        require(paid == true, "The buyer have not paid yet.");
        node = Proxy;
        users.push(Proxy);
        balance.push(msg.value);
    }
    
    function Dispatching() public {
        require(initiated == true, "The contract have not been initiated yet.");
        require(msg.sender == seller, "You are not the seller!");
        require(paid == true, "The buyer have not paid yet.");
        require(node != seller, "You have not appointed a proxy yet!");
        dispatched = true;
    }
    
    function Confirmation() public {
        require(initiated == true, "The contract have not been initiated yet.");
        require(node == buyer, "Your item have not arrived yet.");
        for (uint k = 0; k < users.length; k++) {
            users[k].transfer(balance[k]);
        }
        delete users;
        delete balance;
        node = admin;
        seller = admin;
        buyer = admin;
        initiated = false;
        dispatched = false;
        received = false;
    }
}