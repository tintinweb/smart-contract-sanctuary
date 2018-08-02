pragma solidity ^0.4.11;

contract Storage {
    
    struct BorrowAgreement {
        address lender;
        address borrower;
        uint256 tokenAmount;
        uint256 collateralAmount;
        uint32 collateralRatio;  // Extra collateral, in integer percent.
        uint expiration;
    }
    address constant public x = 0x11111111;
    address constant public y = 0x22222222;
    
    BorrowAgreement[] public agreements;
    
    
    function set(uint256 _amount, uint256 _expiration) public {
        BorrowAgreement agreement;
        agreement.lender = msg.sender;
        agreement.borrower = 0;
        agreement.tokenAmount = _amount;
        agreement.expiration = _expiration;
        agreements.push(agreement);
    }
}