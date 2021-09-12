/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

pragma solidity ^0.4.11;

contract Escrow {
    uint balance;
    address public buyer;
    address public seller;
    uint private start;
    bool buyerOk;
    bool sellerOk = true;

function Escrow(address buyer_address, address seller_address) public {
        // this is the constructor function that runs ONCE upon initialization
        buyer = buyer_address;
        seller = seller_address;
        start = now; //now is an alias for block.timestamp, not really "now"
    }

    function () payable external {

    }

    function accept() public {
        if (msg.sender == buyer) {
            buyerOk = true;
        } else if (msg.sender == seller) {
            sellerOk = true;
        }
        if (buyerOk && sellerOk) {
            payBalance();
        } else if (buyerOk && !sellerOk && now > start + 14 days) {
            // Freeze 30 days before release to buyer. The customer has to remember to call this method after freeze period.
            refundBalance();
        }
    }

    function payBalance() private {
        // send seller the balance
        if (seller.send(this.balance)) {
            balance = 0;
            buyerOk = false;
        } else {
            //throw;
        }
    }

    function refundBalance() private {
        // send seller the balance
        if (buyer.send(this.balance)) {
            balance = 0;
            buyerOk = false;
        } else {
            //throw;
        }
    }

    function deposit() public payable {
        if (msg.sender == buyer) {
            balance += msg.value;
        }
    }

    function cancel() public {
        if (msg.sender == buyer) {
            buyerOk = false;
        } else if (msg.sender == seller) {
            sellerOk = false;
        }
        // if both buyer and seller would like to cancel, money is returned to buyer
        if (!buyerOk && !sellerOk) {
            refundBalance();
        }
    }
}