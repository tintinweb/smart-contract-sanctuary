pragma solidity ^0.4.19;

// if u read this u r gay
contract Faucet {

    // give out ether to mikey
    function withdraw(uint withdraw_amount) public {

        // limit how much eth mikey can take
        require(withdraw_amount <= 100000000000000000);

        // send that eth to mikey
        msg.sender.transfer(withdraw_amount);
    }

    // Accept any incoming amount (hopefully from mike or rob)
    function () public payable {}

}