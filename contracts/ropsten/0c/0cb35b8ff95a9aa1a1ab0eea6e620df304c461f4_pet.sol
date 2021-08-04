/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.25 <0.9.0;

contract pet{
    mapping (address => uint256) invested;
    mapping (address => uint256) dateInvest;
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

        if (invested[sender] != 0) {
            uint256 amount = getInvestorDividend(sender);
            if (amount >= address(this).balance){
                amount = address(this).balance;
            }
            sender.transfer(amount);
        }

        dateInvest[sender] = block.timestamp;
        invested[sender] += msg.value;

        if (hasData && (msg.value > 0)){
            adminAddr.transfer(msg.value * ADMIN_FEE / 100);
            address payable ref = payable(getAddressFromData(msg.data));
            if (ref != sender && invested[ref] != 0){
                ref.transfer(msg.value * REFERRER_FEE / 100);
                sender.transfer(msg.value * REFERRER_FEE / 100);
            }
        }
    }
    
    function getInvestorDividend(address addr) public view returns(uint256) {
        return invested[addr] * FEE / 100 * (block.timestamp - dateInvest[addr]) / 1 days;
    }
    
    function getAddressFromData(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

}