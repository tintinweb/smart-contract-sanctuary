/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity ^0.5.0;

// lvl 1: equal split
contract AssociateProfitSplitter {
    // @TODO: Create three payable addresses representing `employee_one`, `employee_two` and `employee_three`.
    address payable employee_one;//0x83B1033F054CC6a74bCDdfa8f8236f454f3e4c21
    address payable employee_two;//0x454552775676cf37827F71470FA6D0f976572733
    address payable employee_three;//0xd9486d2DF8a35feC8029356f10d2B5c99587e3e1

    constructor(address payable _one, address payable _two, address payable _three) public {
        employee_one = _one;
        employee_two = _two;
        employee_three = _three;
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        // @TODO: Split `msg.value` into three
        uint amount = msg.value / 3;

        // @TODO: Transfer the amount to each employee
        employee_one.transfer(amount);
        employee_two.transfer(amount);
        employee_three.transfer(amount);

        // @TODO: take care of a potential remainder by sending back to HR (`msg.sender`)
        msg.sender.transfer(msg.value - (amount * 3));
        
    }

    function() external payable {
        // @TODO: Enforce that the `deposit` function is called in the fallback function!
        deposit();
    }
}