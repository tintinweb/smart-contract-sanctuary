//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Transfer {
    address private dalal = 0xA44e7DA7d9227849b7F932D16649e3413339A1E7;
    uint64 total = 0;
    uint private commission = 10; // percentage
    address owner;
    constructor(uint _commission) {
        owner = msg.sender;
        commission = _commission;
    }

    function dalalKoCommission() public view returns (uint64) {
        return total;
    }

    function setCommission(uint amount) public {
        commission = amount;
        require(msg.sender == owner, "You can't set commission");
    }

    function remitance(address to) public payable {
        uint64 commissionForThisTx = uint64((msg.value * commission) / 100);
        total = total + commissionForThisTx;

        payable(dalal).transfer(commissionForThisTx);
        payable(to).transfer(msg.value - commissionForThisTx);
    }

    function terminate() public {
        require(msg.sender == owner, "You can't terminate this contract");
        selfdestruct(payable(owner));
    }
}