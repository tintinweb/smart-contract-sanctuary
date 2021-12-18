pragma solidity 0.5.13;

contract EthDrop {
    address public owner;
    uint public price;
    mapping (address => uint) balance;

    function AcceptEth() public {
        // set owner as the address of the one who created the contract
        owner = msg.sender;
        // set the price to 2 ether
        price = 2 ether;
    }

    function accept() payable public {
        // Error out if anything other than 2 ether is sent
        require(msg.value == price);

        // Track that calling account deposited ether
        balance[msg.sender] += msg.value;
    }
}