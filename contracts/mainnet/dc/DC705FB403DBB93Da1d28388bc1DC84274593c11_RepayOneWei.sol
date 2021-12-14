// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IController {
    function repayFYDai(bytes32 collateral, uint256 maturity, address from, address to, uint256 fyDaiAmount) external returns (uint256);
}

contract RepayOneWei {
    IController constant public controller = IController(0xB94199866Fe06B535d019C11247D3f921460b91A);
    bytes32 constant public collateral = "ETH-A";
    uint256 constant public amount = 1;

    constructor() {

    }

    /// @dev Repay one wei of the given maturity
    function repay(uint256 maturity, address vault) external
    {
        controller.repayFYDai(collateral, maturity, address(this), vault, amount);
    }
}