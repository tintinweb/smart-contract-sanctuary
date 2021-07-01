// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/TransferHelper.sol";
import "./interfaces/IUniwrapRewardHolder.sol";
import "./interfaces/IUniwrapFactory.sol";

contract UniwrapRewardHolder is IUniwrapRewardHolder {
  address private _wrap;
  address private _factory;

  constructor(address wrap_, address factory_) {
    _wrap = wrap_;
    _factory = factory_;
  }

  function transferReward(address to, uint256 amount) external override returns (bool) {
    require(IUniwrapFactory(_factory).isPool(msg.sender), "UniwrapRewardHolder: transfer reward must call by pool");

    TransferHelper.safeTransfer(_wrap, to, amount);
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniwrapFactory {
  function wrap() external view returns (address);
  function rewardHolder() external view returns (address);
  function getPool(string memory symbol) external view returns (address);
  function getPoolByIndex(uint8 index) external view returns (address);
  function getPoolSize() external view returns (uint8);
  function isPool(address poolAddress) external view returns (bool);

  function create(
    uint256 wrapPerMint,
    string memory name,
    string memory symbol,
    address[] memory tokens,
    uint256[] memory amounts
  ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniwrapRewardHolder {
  function transferReward(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeApprove: approve failed'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeTransfer: transfer failed'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::transferFrom: transferFrom failed'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}