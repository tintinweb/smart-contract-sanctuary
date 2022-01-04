pragma solidity ^0.5.16;

interface IAnEth {
    function repayBorrowBehalf(address borrower) external payable;
    function borrowBalanceCurrent(address account) external returns (uint);
}

contract EthRepayAllHelper {

    IAnEth public anEth;

    constructor(IAnEth _anEth) public {
        anEth = _anEth;
    }

    function repayAll() public payable {
        uint debt = anEth.borrowBalanceCurrent(msg.sender);
        require(debt > 0 && debt <= msg.value, "Debt checks failure");
        anEth.repayBorrowBehalf.value(debt)(msg.sender);
        uint remainder = address(this).balance;
        if(remainder > 0) {
            msg.sender.transfer(remainder);
        }
    }

}