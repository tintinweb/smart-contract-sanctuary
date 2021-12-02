/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity ^0.8.6;

contract Agreement {

    bool isPaid = false;
    bool isWorkDone = false;

    address public dao;
    address payable public contributor;
    uint256 amountToPay;
    function balance() public view returns(uint256){
        return address(this).balance;
    }

    constructor() public {
      dao = msg.sender;   
    }

    function initiateAgreement(uint256 amount, address payable ethaddress) external payable{
        require(amount <= balance(), "not enough balance");
        contributor = ethaddress;
        amountToPay = amount;
    }

    function submitWork() external {
        isWorkDone = true;
    }

    function initiatePayment() external {
        require(isWorkDone == true, "Work is not completed");
        require(msg.sender == dao, "Dao should be the initiator");
        contributor.transfer(amountToPay);
        payable(msg.sender).transfer(balance());
    }
}