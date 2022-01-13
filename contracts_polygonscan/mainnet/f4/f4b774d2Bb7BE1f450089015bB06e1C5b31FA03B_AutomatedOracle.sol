// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./interfaces/IOracleId.sol";

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

interface IPool {
    function derivative() external view returns (Derivative memory);
}

contract AutomatedOracle {
    IPool private immutable _pool;
    IOracleId private immutable _oracleId;

    bytes4 private constant _SELECTOR = bytes4(keccak256("triggerOracle(uint256)"));

    constructor(IPool pool_) {
        _pool = pool_;
        _oracleId = IOracleId(pool_.derivative().oracleId);
    }

    function triggerOracle(uint256 _endTime) public {
        _oracleId._callback(_endTime);
    }

    function getPool() external view returns (address) {
        return address(_pool);
    }

    function getOracleId() external view returns (address) {
        return address(_oracleId);
    }

    function getEndTime() public view returns (uint256) {
        return _pool.derivative().endTime;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        uint256 endTime = getEndTime();
        canExec = endTime < block.timestamp;
        execPayload = abi.encodeWithSelector(_SELECTOR, endTime);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IOracleId {
    function _callback(uint256 endTime) external;
    function getResult() external view returns(uint256);
    function oracleAggregator() external view returns(address);
}