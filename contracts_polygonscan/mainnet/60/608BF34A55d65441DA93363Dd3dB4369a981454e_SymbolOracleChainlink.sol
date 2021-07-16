// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './Ownable.sol';

contract SymbolOracleChainlink is Ownable {

    address public immutable oracle;
    uint256 public immutable decimals;
    bool    public enabled;

    constructor (address oracle_) {
        oracle = oracle_;
        decimals = IChainlinkOracle(oracle_).decimals();
        enabled = true;
        _controller = msg.sender;
    }

    function enable() external _controller_ {
        enabled = true;
    }

    function disable() external _controller_ {
        enabled = false;
    }

    function getPrice() external view returns (uint256) {
        require(enabled, 'SymbolOracleChainlink: oracle disabled');
        (, int256 price, , , ) = IChainlinkOracle(oracle).latestRoundData();
        return uint256(price) * 10**18 / 10**decimals;
    }

}

interface IChainlinkOracle {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IOwnable.sol';

abstract contract Ownable is IOwnable {

    address _controller;

    address _newController;

    modifier _controller_() {
        require(msg.sender == _controller, 'Ownable: only controller');
        _;
    }

    function controller() public override view returns (address) {
        return _controller;
    }

    function setNewController(address newController) public override _controller_ {
        _newController = newController;
    }

    // a claim step is needed to prevent set controller to a wrong address and forever lost control
    function claimNewController() public override {
        require(msg.sender == _newController, 'Ownable: not allowed');
        _controller = _newController;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOwnable {

    function controller() external view returns (address);

    function setNewController(address newController) external;

    function claimNewController() external;

}