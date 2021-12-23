/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract FeiApproval {

    address public constant FEI_LENDER = address(0x16585044cde6e2da20EbE8ad9d468b248aC62041);
    address public constant FEI_BORROWER = address(0x72b7448f470D07222Dbf038407cD69CC380683F3);
    uint256 public constant FEI_AMOUNT = 111_000e18;
    IERC20 public constant FEI = IERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);

    bool public canBorrow = true;

    function borrow() public {
        require(msg.sender == FEI_BORROWER, "only borrower");
        require(canBorrow, "can't borrow");
        FEI.transferFrom(FEI_LENDER, FEI_BORROWER, FEI_AMOUNT);
        canBorrow = false;
    }

    function repay() public {
        require(msg.sender == FEI_BORROWER, "only borrower");
        require(!canBorrow, "no need to repay");
        FEI.transferFrom(FEI_BORROWER, FEI_LENDER, FEI_AMOUNT); // send back from borrower
        canBorrow = true;
    }
}