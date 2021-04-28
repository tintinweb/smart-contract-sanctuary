// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./WrapNZap.sol";

contract WrapNZapFactory {
    event NewWrapNZap(address zappee, address wrapper, address WrapNZap);

    WrapNZap[] public wrapnzaps;
    uint256 public wrapnzapCount;

    function create(address _zappee, address _wrapper) external {
        require(
            _zappee != address(0) && _wrapper != address(0),
            "not real address"
        );
        WrapNZap wrapnzap = new WrapNZap(_zappee, _wrapper);
        wrapnzaps.push(wrapnzap);
        wrapnzapCount += 1;
        emit NewWrapNZap(_zappee, _wrapper, address(wrapnzap));
    }

    function createAndZap(address _zappee, address _wrapper) external payable {
        require(
            _zappee != address(0) && _wrapper != address(0),
            "not real address"
        );
        require(msg.value > 0, "no value sent");
        WrapNZap wrapnzap = (new WrapNZap){value: msg.value}(_zappee, _wrapper);
        wrapnzaps.push(wrapnzap);
        wrapnzapCount += 1;
        emit NewWrapNZap(_zappee, _wrapper, address(wrapnzap));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./interfaces/IWrappedETH.sol";

contract WrapNZap {
    address public zappee;
    IWrappedETH public wrapper;

    constructor(address _zappee, address _wrapper) payable {
        zappee = _zappee;
        wrapper = IWrappedETH(_wrapper);
        if (msg.value > 0) {
            _zap(msg.value);
        }
    }

    function poke() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "WrapNZap: no balance");

        _zap(balance);
    }

    function _zap(uint256 value) internal {
        // wrap
        wrapper.deposit{value: value}();

        // send to zappee
        require(wrapper.transfer(zappee, value), "WrapNZap: transfer failed");
    }

    receive() external payable {
        _zap(msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IWrappedETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}