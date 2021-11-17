// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract MockService {
    address public immutable gelato;

    event LogMock();

    constructor(address _gelato) {
        gelato = _gelato;
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}

    function mockFunc() external {
        emit LogMock();
    }

    function mockFuncWithPayment(uint256 txCost) external {
        emit LogMock();

        if (txCost > address(this).balance)
            revert("MockService.mockFuncWithPayment: txCost > balance");

        payable(gelato).transfer(txCost);
    }
}