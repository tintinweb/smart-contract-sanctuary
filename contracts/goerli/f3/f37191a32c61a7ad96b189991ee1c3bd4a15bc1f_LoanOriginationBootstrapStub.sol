/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.4;


contract LoanOriginationBootstrapStub {

  address owner;

  mapping( address => bool ) isApprovedToken;

  mapping( address => address ) priceOracleForToken;

  modifier onlyApprovedPayment( address paymentToken ) {
    require( isApprovedToken[paymentToken] );
    _;
  }

  modifier onlyOwner() {
    require( msg.sender == owner );
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function approveTokenForLending( address newToken ) external onlyOwner() returns ( bool success ) {
    isApprovedToken[newToken] = true;
    success = true;
  }

  function isApprovedForLending( address tokenQuery ) external view returns ( bool isApproved ) {
    isApproved = isApprovedToken[tokenQuery];
  }
  
  address loanedToken1;
  uint256 amount1;

  function loanLiquidity( address loanedToken, uint256 amount ) external onlyApprovedPayment( loanedToken ) returns ( bool success ) {
      
      loanedToken1 = loanedToken;
      amount1 = amount;

    // Confirm token address sent is approved.

    // 

    // Check price for 

    success = true;
  }

  function _getPriceQuote( address paidToken, uint256 amount ) internal view returns ( uint256 amountOut ) {

  }

  function getOriginalPrinciple( address account ) external pure returns ( uint256 originalDeposit ) {
    account;
    originalDeposit = 1 ether;
  }

  function getInterestDue( address account ) external pure returns ( uint256 interestDue ) {
      account;
    interestDue = 2;
  }

  function getQuoteForToken( address loanedToken, uint256 amount ) external pure returns ( uint256 quoteAmount ) {
      loanedToken;
      amount;
    quoteAmount = 2 ether;  
  }

  function getAPY( address user ) external pure returns ( uint256 apy ) {
      user;
    apy = 320;
  }

  function getLoanInterestRate( address user ) external pure returns ( uint256 loanRate ) {
      user;
    loanRate = 13;
  }

  function getAmountDue( address user ) external pure returns ( uint256 amountDue ) {
      user;
    amountDue = 3;
  }

}