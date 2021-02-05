// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract DummyWithdraw {
    address payable private _owner;

    constructor(
    ) {
        _owner = msg.sender;
    }

    receive() external payable {}


    /// Withdraw a bid that was overbid.
    function withdraw() public {
        uint amount = address(this).balance;
        require(amount > 0, "no money here");
        payable(_owner).send(amount);
    }

    function withdraw2() public {
        uint amount = address(this).balance;
        require(amount > 0, "no money here");
        _owner.transfer(amount);
    }
}