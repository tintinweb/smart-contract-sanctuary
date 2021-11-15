// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Ownable.sol';

contract OracleRouter is Ownable {

    string  public symbol;
    address public oracle;

    constructor (string memory _symbol, address _oracle) {
        symbol = _symbol;
        oracle = _oracle;
        _controller = msg.sender;
    }

    function setOracle(address _oracle) external _controller_ {
        oracle = _oracle;
    }

    function getPrice() external view returns (uint256) {
        return IOracle(oracle).getPrice();
    }

}

interface IOracle {
    function getPrice() external view returns (uint256);
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

