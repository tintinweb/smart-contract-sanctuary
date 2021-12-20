pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

import "./IGainBaseBSC.sol";

interface Oracle {
    function latestAnswer() external view returns (int256);
}

contract IGainDelta is IGainBase {

    Oracle public oracle;

    uint256 public openPrice;
    uint256 public closePrice;
    uint256 public leverage; // in 1e18

    function init(address _baseToken, address _oracle, address _treasury, string calldata _batchName, uint256 _leverage, uint256 _duration, uint256 _a, uint256 _b) public {
        _init(_baseToken, _treasury, _batchName, _duration, _a, _b);
        oracle = Oracle(_oracle);
        leverage = _leverage;
        openPrice = uint256(oracle.latestAnswer());
    }

    // 1 - swap fee (numerator, in 1e18 format)
    function fee() public override pure returns (uint256) {
        return 1e18 - minFee;
    }

    // can only call once after closeTime
    // get price from oracle and calculate IL
    function close() external override {
        require(block.timestamp >= closeTime, "Not yet");
        require(canBuy, "Closed");
        canBuy = false;
        closePrice = uint256(oracle.latestAnswer());

        bPrice = calcDelta(leverage, openPrice, closePrice);
    }

    // f(l, a, x) = l(x - a) / (2 * sqrt(a^2 + l^2 * (x - a)^2)) + 0.5
    function calcDelta(uint256 lever, uint256 anchor, uint256 index) public pure returns (uint256 delta) {
        uint256 numerator;
        uint256 denominator;
        if (index > anchor) {
            numerator = (index - anchor) * lever / 1e18;
            denominator = 2 * sqrt(anchor * anchor + numerator * numerator);
            delta = 0.5e18 + numerator * 1e18 / denominator;
        }
        else {
            numerator = (anchor - index) * lever / 1e18;
            denominator = 2 * sqrt(anchor * anchor + numerator * numerator);
            delta = 0.5e18 - numerator * 1e18 / denominator;
        }
    }

}