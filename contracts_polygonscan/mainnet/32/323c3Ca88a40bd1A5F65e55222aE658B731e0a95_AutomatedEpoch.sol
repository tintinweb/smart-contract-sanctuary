// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/// @notice LibDerivative.Derivative without `uint256[] params` array;
struct Derivative {
    // Margin parameter for syntheticId
    uint256 margin;
    // Maturity of derivative
    uint256 endTime;
    // oracleId of derivative
    address oracleId;
    // Margin token address of derivative
    address token;
    // syntheticId of derivative
    address syntheticId;
}

struct DerivativeWithParams {
    // Margin parameter for syntheticId
    uint256 margin;
    // Maturity of derivative
    uint256 endTime;
    // Additional parameters for syntheticId
    uint256[] params;
    // oracleId of derivative
    address oracleId;
    // Margin token address of derivative
    address token;
    // syntheticId of derivative
    address syntheticId;
}

interface IPool {
    function derivative() external view returns (Derivative memory);
    function getDerivativeParams() external view returns (uint256[] memory);
    function longPositionWrapper() external view returns (IOpiumERC20Position);
    function initializeEpoch() external;
}

interface IOpiumERC20Position {
    function execute(DerivativeWithParams calldata _derivative) external;
}

contract AutomatedEpoch {
    IPool private immutable _pool;

    bytes4 private constant _SELECTOR = bytes4(keccak256("trigger()"));

    constructor(IPool pool_) {
        _pool = pool_;
    }

    function trigger() public {
        Derivative memory derivative = _pool.derivative();
        uint256[] memory params = _pool.getDerivativeParams();
        IOpiumERC20Position longPositionWrapper = _pool.longPositionWrapper();

        // Execute LONG positions
        DerivativeWithParams memory derivativeWithParams = DerivativeWithParams({
            margin: derivative.margin,
            endTime: derivative.endTime,
            params: params,
            oracleId: derivative.oracleId,
            token: derivative.token,
            syntheticId: derivative.syntheticId
        });

        longPositionWrapper.execute(derivativeWithParams);

        // Initialize epoch
        _pool.initializeEpoch();
    }

    function getPool() external view returns (address) {
        return address(_pool);
    }

    function getEndTime() public view returns (uint256) {
        return _pool.derivative().endTime;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        uint256 endTime = getEndTime();
        canExec = endTime < block.timestamp;
        execPayload = abi.encodeWithSelector(_SELECTOR);
    }
}