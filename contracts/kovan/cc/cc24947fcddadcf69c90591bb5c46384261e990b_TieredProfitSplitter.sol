/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity ^0.5.0;

// lvl 2: tiered split
contract TieredProfitSplitter {
    address payable employee_one; // ceo 0x83B1033F054CC6a74bCDdfa8f8236f454f3e4c21
    address payable employee_two; // cto 0x454552775676cf37827F71470FA6D0f976572733
    address payable employee_three; // bob 0xd9486d2DF8a35feC8029356f10d2B5c99587e3e1

    constructor(address payable _one, address payable _two, address payable _three) public {
        employee_one = _one;
        employee_two = _two;
        employee_three = _three;
    }

    // Should always return 0! Use this to test your `deposit` function's logic
    function balance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        uint points = msg.value / 100; // Calculates rudimentary percentage by dividing msg.value into 100 units
        uint total;
        uint[] memory amount = new uint[](3);
        
        amount[0] = points * 60;
        amount[1] = points * 25;
        amount[2] = points * 15;
        
        employee_one.transfer(amount[0]);
        employee_two.transfer(amount[1]);
        employee_three.transfer(amount[2]);
        
        total += amount[0] + amount[1] + amount[2];

        // @TODO: Calculate and transfer the distribution percentage
        // Step 1: Set amount to equal `points` * the number of percentage points for this employee
        // Step 2: Add the `amount` to `total` to keep a running total
        // Step 3: Transfer the `amount` to the employee

        // @TODO: Repeat the previous steps for `employee_two` and `employee_three`
        // Your code here!

        employee_one.transfer(msg.value - total); // ceo gets the remaining wei
    }

    function() external payable {
        deposit();
    }
}