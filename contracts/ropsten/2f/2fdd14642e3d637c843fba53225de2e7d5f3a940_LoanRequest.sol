// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Loan.sol";

contract LoanRequest {

    string public constant name = "DevLab Loan Request 01";

    address public borrower = msg.sender;
    IERC20 public token;
    uint256 public collateralAmount;
    uint256 public loanAmount;
    uint256 public payoffAmount;
    uint256 public loanDuration;

    constructor (
        IERC20 _token,
        uint256 _collateralAmount,
        uint256 _loanAmount,
        uint256 _payoffAmount,
        uint256 _loanDuration)
    {
        token = _token;
        collateralAmount = _collateralAmount;
        loanAmount = _loanAmount;
        payoffAmount = _payoffAmount;
        loanDuration = _loanDuration;

        require(token.approve(address(this), collateralAmount));
    }

    Loan public loan;

    event LoanRequestAccepted(address loanAddress);

    function lendEther() public payable {
        require(msg.value == loanAmount);
        loan = new Loan(
            msg.sender,
            borrower,
            token,
            collateralAmount,
            payoffAmount,
            loanDuration
        );
        require(token.transferFrom(borrower, loan.loanAddress(), collateralAmount));
        payable(borrower).transfer(loanAmount);
        emit LoanRequestAccepted(loan.loanAddress());
    }
}