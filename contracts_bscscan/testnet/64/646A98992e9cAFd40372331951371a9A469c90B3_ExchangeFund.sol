// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import {Governed} from "./Governance.sol";

contract ExchangeFund is Governed {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor {
        require(msg.sender == governor, "CoinsSafe: only governor allowed to call");
        _;
    }

    constructor() {
        emit PendingGovernanceTransition(address(0), governor);
        governor = msg.sender;
        emit GovernanceTransited(address(0), governor);
    }

    function transitGovernance(address newGovernor) external {
        require(newGovernor != address(0), "CoinsSafe: new governor can't be the zero address");
        require(newGovernor != address(this), "CoinsSafe: contract can't govern itself");

        pendingGovernor = newGovernor;
        emit PendingGovernanceTransition(governor, newGovernor);
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernor, "CoinsSafe: only pending governor allowed to take governance");

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }
}