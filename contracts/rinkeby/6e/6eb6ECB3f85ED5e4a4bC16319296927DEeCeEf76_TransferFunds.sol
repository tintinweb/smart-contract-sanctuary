pragma solidity ^0.8.0;

contract TransferFunds{
    address public admin;
    address public transferee;

    constructor(address _transferee) {
        admin = msg.sender;
        transferee = _transferee;
    }

    modifier onlyAdmin{
        require(msg.sender == admin, "Only admin can transfer funds into the contract!");
        _;
    }

    modifier onlyTransferee{
        require(msg.sender == transferee,"Only the given transferee can withdraw funds");
        _;
    }

    function transfer() onlyAdmin public payable{}

    function withdraw() onlyTransferee public payable{
        payable(transferee).transfer(address(this).balance);
    }
}