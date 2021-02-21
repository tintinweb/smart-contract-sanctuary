/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.1;

/*

February 20th, 2021

This agreement outlines the amount of funds and repayment mechanics between Alpha Homora V2 (a product of
Alpha Finance Lab) and CREAM V2 (or CREAM).

The funds in discussion include:

● 13,245 ETH (including ETH in the attacker’s wallet, deposited to Tornado for own use, sent to Tornado
foundation via Gitcoin, sent to Alpha Homora V2 deployer, and sent to CREAM V2 deployer)
● 4,263,139 DAI
● 4,032,014 USDC
● 5,647,242 USDT
● Amount of interest accrued until the audit of the proposed change on CREAM V2 contract is complete.

Borrowing interest

CREAM V2 contract will be upgraded to halt the borrowing interest rate on the funds in discussion. Alpha Finance
Lab will get the proposed change audited and pay for the auditing cost.

ALPHA token collateral
$50M ALPHA tokens will be put in escrow contract with 7 days timelock. ALPHA tokens will be released back to 
Alpha Finance Lab periodically and proportionally as the funds in discussion are paid back. Terms of the escro
will be added as an Appendix A.

Mechanics

CREAM V2 will use 1,000 ETH sent by the attacker to CREAM V2 deployer to paydown the funds in discussion by
sending the 1,000 ETH to the CREAM Multisig.

Alpha Homora V2 will use 1,000 ETH sent by the attacker to Alpha Homora V2 deployer to paydown the funds in
discussion by sending the 1,000 ETH to the CREAM Multisig.

Alpha Homora V2 will repay the remaining funds in discussion by using 20% of Alpha Homora V1 and V2 reserves to
paydown the funds until the funds in discussion above are repaid back. The percentages of the reserves to pay down
the debt may vary (higher or lower than 20%), and both the Alpha and CREAM team will agree to any new rates
beforehand new rates are applied. Alpha Homora V2 and CREAM V2 will agree upon the detailed technical
mechanics, which will be added as an Appendix B.

Timeline

There is no set timeline on when the funds in discussion have to be repaid back. The mechanics above will continue
until the funds are repaid.

Additional

If the funds can be retrieved and repaid back to CREAM V2 from the exploiter, the mechanics described will end.

Alpha Finance Lab
C.R.E.A.M. Finance (signed by multisig. The transaction will be added to the Appendix C.)

*/

contract AHv2Repayment {
    
    string constant public MD5 = "de36f79edde3c61d29ce5318530071d2";
    string constant public IPFS = "QmPAEj79uKn1aGtZo8jWUciZeZpjpSUwWFRmfxAVHymuhd";
    
    address[] _signers;
    mapping(address => bool) approvedSigners;
    mapping(address => bool) public signed;
    
    constructor() {
        approvedSigners[0x580cE7B92F185D94511c9636869d28130702F68E] = true; // cream.finance: multisig
        approvedSigners[0x6D5a7597896A703Fe8c85775B23395a48f971305] = true; // alpha homora multisig
        _signers.push(0x580cE7B92F185D94511c9636869d28130702F68E); // cream.finance: multisig
        _signers.push(0x6D5a7597896A703Fe8c85775B23395a48f971305); // alpha homora multisig
    }
    
    function signers() external view returns (address[] memory) {
        return _signers;
    }
    
    function sign() external {
        require(approvedSigners[msg.sender]);
        signed[msg.sender] = true;
    }
}