// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Ownable.sol';

contract WooOracleOld is Ownable {

    address public immutable feed;
    uint256 public immutable baseDecimals;
    uint256 public immutable quoteDecimals;
    bool    public enabled;

    constructor (address feed_) {
        feed = feed_;
        baseDecimals = IERC20(IWooOracleOld(feed_)._BASE_TOKEN_()).decimals();
        quoteDecimals = IERC20(IWooOracleOld(feed_)._QUOTE_TOKEN_()).decimals();
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
        require(enabled, 'WooOracleOld: oracle disabled');
        return IWooOracleOld(feed)._I_() * (10**baseDecimals) / (10**quoteDecimals);
    }

}

interface IWooOracleOld {
    function _BASE_TOKEN_() external view returns (address);
    function _QUOTE_TOKEN_() external view returns (address);
    function _I_() external view returns (uint256);
}

interface IERC20 {
    function decimals() external view returns (uint8);
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
        emit ChangeController(_controller, _newController);
        _controller = _newController;
        delete _newController;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOwnable {

    event ChangeController(address oldController, address newController);

    function controller() external view returns (address);

    function setNewController(address newController) external;

    function claimNewController() external;

}

