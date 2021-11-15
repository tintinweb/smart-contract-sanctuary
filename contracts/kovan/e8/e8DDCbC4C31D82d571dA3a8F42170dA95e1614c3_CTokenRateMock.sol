// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "./SourceMock.sol";


contract CTokenRateMock is SourceMock {
    uint public borrowIndex;

    function set(uint rate) external override {
        borrowIndex = rate;          // I'm assuming Compound uses 18 decimals for the borrowing rate
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface SourceMock {
    function set(uint) external;
}

