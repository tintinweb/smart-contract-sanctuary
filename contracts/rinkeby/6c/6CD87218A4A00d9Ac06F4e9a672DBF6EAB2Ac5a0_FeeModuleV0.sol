// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IFeeModule.sol";

contract FeeModuleV0 is IFeeModule {
    // @dev A pay function that doesn't require payment
    function pay(address, uint256) override external pure returns (bool success) {
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeModule {
    // @dev Make a payment for a reservation
    // @param payer The address to pay for the reservation
    // @param durationToReserve The length of time in seconds to reserve
    // @returns success Whether the payment was sucessful
    function pay(address payer, uint256 durationToReserve) external returns (bool success);
}