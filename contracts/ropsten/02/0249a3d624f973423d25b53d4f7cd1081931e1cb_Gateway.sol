pragma solidity ^0.4.25;
contract Wallet {
    function payment() public payable returns(bool);
}
contract Gateway {
    address owner;
    constructor() public {
        owner = 0xF768D0e15f59824ed6c86A8c733650A923C34a4A;
    }
    function() public payable {
        require(msg.value > 0);
        if (!Wallet(owner).payment.value(msg.value)())
        owner.transfer(msg.value);
    }
}