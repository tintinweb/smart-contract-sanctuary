// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v1;

import "./interfaces/InteractiveNotificationReceiver.sol";
import "./interfaces/IWithdrawable.sol";

contract WethUnwrapper is InteractiveNotificationReceiver {
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function notifyFillOrder(
        address /* taker */,
        address /* makerAsset */,
        address takerAsset,
        uint256 /* makingAmount */,
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external override {
        address payable makerAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            makerAddress := shr(96, calldataload(interactiveData.offset))
        }
        IWithdrawable(takerAsset).withdraw(takingAmount);
        makerAddress.transfer(takingAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v1;

/// @title Interface for interactor which acts between `maker => taker` and `taker => maker` transfers.
interface InteractiveNotificationReceiver {
    /// @notice Callback method that gets called after taker transferred funds to maker but before
    /// the opposite transfer happened
    function notifyFillOrder(
        address taker,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes memory interactiveData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v1;

interface IWithdrawable {
    function withdraw(uint wad) external;
}