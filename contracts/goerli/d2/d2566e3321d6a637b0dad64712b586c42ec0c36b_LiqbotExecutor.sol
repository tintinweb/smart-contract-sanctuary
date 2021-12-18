// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20.sol";

contract LiqbotExecutor {
    uint256 private constant ONE = 1e18;

    address payable private immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function execute(
        address to,
        bytes calldata data,
        uint256 minerCutRate,
        IERC20[] calldata sweepTokens
    )
        external
        onlyOwner
    {
        (bool success, ) = to.call(data);
        require(success);

        for (uint256 i = 0; i < sweepTokens.length; ++i) {
            require(sweepTokens[i].transfer(owner, sweepTokens[i].balanceOf(address(this))));
        }

        block.coinbase.transfer(address(this).balance * minerCutRate / ONE);
        owner.transfer(address(this).balance);
    }
}