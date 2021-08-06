/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.25 <0.9.0;

contract pet{
    mapping (address => uint256) investedValue;
    mapping (address => uint256) lastPaymentTime;
    mapping (address => uint256) paidValue;

    uint constant public FEE = 4;
    uint constant public ADMIN_FEE = 2;
    uint constant public REFERRER_FEE = 2;
    address payable private adminAddr;
    
    constructor() {
        adminAddr = payable(msg.sender);
    }

    // This function is called for all messages sent to
    // this contract, except plain Ether transfers
    // (there is no other function except the receive function).
    // Any call with non-empty calldata to this contract will execute
    // the fallback function (even if Ether is sent along with the call).
    fallback() external payable {
        receivedTransaction(true);
    }

    // This function is called for plain Ether transfers, i.e.
    // for every call with empty calldata.
    receive() external payable {
        receivedTransaction(false);
    }

    function receivedTransaction(bool hasData) private {
        address payable sender = payable(msg.sender);

        if (investedValue[sender] != 0) {
            uint256 amount = getInvestorDividend(sender);
            if (amount >= address(this).balance){
                amount = address(this).balance;
            }

            sender.transfer( amount );
            paidValue[sender] += amount;
        }

        lastPaymentTime[sender] = block.timestamp;
        investedValue[sender] += msg.value;

        if (msg.value > 0){
            adminAddr.transfer( getAdminValueWithFee(msg.value) );
            if (hasData) {
                address payable ref = payable( getAddressFromData(msg.data) );
                if (ref != sender && investedValue[ref] != 0){
                    uint256 valueForPay = getReferrerValueWithFee(msg.value);

                    ref.transfer( valueForPay );
                    paidValue[ref] += valueForPay;

                    sender.transfer( valueForPay );
                    paidValue[sender] += valueForPay;
                }
            }
        }
    }
    
    function getAdminValueWithFee(uint256 value) private pure returns(uint256) {
        return value * ADMIN_FEE / 100;
    }
    
    function getReferrerValueWithFee(uint256 value) private pure returns(uint256) {
        return value * REFERRER_FEE / 100;
    }

    function getInvestorDividend(address addr) private view returns(uint256) {
        return investedValue[addr] * FEE / 100 * (block.timestamp - lastPaymentTime[addr]) / 1 days;
    }

    function getAddressFromData(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function investorInfo(address addr) public view returns(
        uint256 totalInvested,
        uint256 totalInvestedEth,
        uint256 paymentTime,
        uint256 totalPaid,
        uint256 totalPaidEth,
        uint256 calculatedValue,
        uint256 calculatedValueEth

    ) {
        totalInvested = investedValue[addr];
        totalInvestedEth = totalInvested / 1 ether;
        paymentTime = lastPaymentTime[addr];
        totalPaid = paidValue[addr];
        totalPaidEth = totalPaid / 1 ether;
        calculatedValue = getInvestorDividend(addr);
        calculatedValueEth = calculatedValue / 1 ether;
    }

}