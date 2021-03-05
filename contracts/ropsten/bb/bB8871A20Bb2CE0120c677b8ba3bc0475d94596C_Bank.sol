/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

pragma solidity >= 0.4.25 < 0.6;
pragma experimental ABIEncoderV2;

contract Bank {
    struct Customer {
        uint age;
    }

    Customer[][] customers;

    function foo() public {
        if (customers.length > 0) {
            Customer[] storage northBranch = customers[0];
            if (northBranch.length > 1) {
                Customer storage customer = northBranch[1];
                customer.age = 23;
            }
        } else {
            Customer memory bob;
            bob.age = 34;
            customers.length += 1;
            customers[0].push(bob);
        }
    }

    function get() external view returns (Customer[][] memory) {
        return (customers);
    }
}