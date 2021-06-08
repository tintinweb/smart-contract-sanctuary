/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: MockGasPrice.sol

/**
 * Used for testing purpose only.
 */
contract MockGasPrice {

    event Sum(uint, uint, uint);
    event Price(uint);
    event Used(uint);

    uint256 public total;

    function doOp() external {
        uint256 total = gasleft();
        complexOp();
        emit Used(total - gasleft());
    }

    function doOp2() external calcGasUsed {
        complexOp();
    }

    function getGasPrice() external {
        emit Price(tx.gasprice);
    }

    function complexOp() public {
        uint256 a = 10;
        uint256 b = 20;
        uint256 sum = a + b;
        emit Sum(a, b, sum);
    }

    modifier calcGasUsed() {
        total = gasleft();
        _;
        emit Used(total - gasleft());
    }

}