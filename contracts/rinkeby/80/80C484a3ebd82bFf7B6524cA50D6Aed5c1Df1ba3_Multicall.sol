// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import './libraries/Strings.sol';
import './libraries/TransferHelper.sol';
import './libraries/LowGasSafeMath.sol';
import './interfaces/IMulticall.sol';
import './MulticallView.sol';

contract Multicall is IMulticall, MulticallView {
  using Strings for uint256;
  using LowGasSafeMath for uint256;

  function tryAggregate(bool requireSuccess, Call[] memory calls) public override returns (Result[] memory returnData) {
    returnData = new Result[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
      if (requireSuccess) {
        require(success, 'Multicall aggregate: call failed');
      }
      returnData[i] = Result(success, ret);
    }
  }

  function tryAggregateETH(bool requireSuccess, CallETH[] memory calls)
    public
    payable
    override
    returns (Result[] memory returnData)
  {
    uint256 initValue = getEthBalance(address(this)).sub(msg.value);

    returnData = new Result[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, bytes memory ret) = calls[i].target.call{value: calls[i].value}(calls[i].callData);
      if (requireSuccess) {
        require(success, 'Multicall aggregate: call failed');
      }
      returnData[i] = Result(success, ret);
    }

    uint256 currentValue = getEthBalance(address(this));

    if (currentValue > initValue) {
      TransferHelper.safeTransferETH(msg.sender, currentValue.sub(initValue));
    }
  }

  function tryBlockAndAggregate(bool requireSuccess, Call[] memory calls)
    public
    override
    returns (
      uint256 blockNumber,
      bytes32 blockHash,
      Result[] memory returnData
    )
  {
    blockNumber = getBlockNumber();
    blockHash = getBlockHash(blockNumber);
    returnData = tryAggregate(requireSuccess, calls);
  }

  function aggregate(Call[] memory calls) public override returns (Result[] memory returnData) {
    (returnData) = tryAggregate(true, calls);
  }

  function aggregateETH(CallETH[] memory calls) public payable override returns (Result[] memory returnData) {
    (returnData) = tryAggregateETH(true, calls);
  }

  function blockAndAggregate(Call[] memory calls)
    public
    override
    returns (
      uint256 blockNumber,
      bytes32 blockHash,
      Result[] memory returnData
    )
  {
    (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @dev String operations.
 */
library Strings {
  /**
   * @dev Converts a `uint256` to its ASCII `string` representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    uint256 index = digits - 1;
    temp = value;
    while (temp != 0) {
      buffer[index--] = bytes1(uint8(48 + (temp % 10)));
      temp /= 10;
    }
    return string(buffer);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import '../interfaces/IERC20.sol';

library TransferHelper {
  /// @notice Transfers tokens from the targeted address to the given destination
  /// @notice Errors with 'STF' if transfer fails
  /// @param token The contract address of the token to be transferred
  /// @param from The originating address from which the tokens will be transferred
  /// @param to The destination address of the transfer
  /// @param value The amount to be transferred
  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
  }

  /// @notice Transfers tokens from msg.sender to a recipient
  /// @dev Errors with ST if transfer fails
  /// @param token The contract address of the token which will be transferred
  /// @param to The recipient of the transfer
  /// @param value The value of the transfer
  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
  }

  /// @notice Approves the stipulated contract to spend the given allowance in the given token
  /// @dev Errors with 'SA' if transfer fails
  /// @param token The contract address of the token to be approved
  /// @param to The target of the approval
  /// @param value The amount of the given token the target will be allowed to spend
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
  }

  /// @notice Transfers ETH to the recipient address
  /// @dev Fails with `STE`
  /// @param to The destination of the transfer
  /// @param value The value to be transferred
  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'STE');
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(x == 0 || (z = x * y) / x == y);
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x + y) >= x == (y >= 0));
  }

  /// @notice Returns x - y, reverts if overflows or underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x - y) <= x == (y >= 0));
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import './IMulticallView.sol';

interface IMulticall is IMulticallView {
  struct CallETH {
    address target;
    uint256 value;
    bytes callData;
  }
  struct Call {
    address target;
    bytes callData;
  }
  struct Result {
    bool success;
    bytes returnData;
  }

  function tryAggregate(bool requireSuccess, Call[] memory calls) external returns (Result[] memory returnData);

  function tryAggregateETH(bool requireSuccess, CallETH[] memory calls)
    external
    payable
    returns (Result[] memory returnData);

  function tryBlockAndAggregate(bool requireSuccess, Call[] memory calls)
    external
    returns (
      uint256 blockNumber,
      bytes32 blockHash,
      Result[] memory returnData
    );

  function aggregate(Call[] memory calls) external returns (Result[] memory returnData);

  function aggregateETH(CallETH[] memory calls) external payable returns (Result[] memory returnData);

  function blockAndAggregate(Call[] memory calls)
    external
    returns (
      uint256 blockNumber,
      bytes32 blockHash,
      Result[] memory returnData
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import './interfaces/IMulticallView.sol';

contract MulticallView is IMulticallView {
  function getBlockHash(uint256 blockNumber) public view override returns (bytes32 blockHash) {
    blockHash = blockhash(blockNumber);
  }

  function getBlockNumber() public view override returns (uint256 blockNumber) {
    blockNumber = block.number;
  }

  function getCurrentBlockCoinbase() public view override returns (address coinbase) {
    coinbase = block.coinbase;
  }

  function getCurrentBlockDifficulty() public view override returns (uint256 difficulty) {
    difficulty = block.difficulty;
  }

  function getCurrentBlockGasLimit() public view override returns (uint256 gaslimit) {
    gaslimit = block.gaslimit;
  }

  function getCurrentBlockTimestamp() public view override returns (uint256 timestamp) {
    timestamp = block.timestamp;
  }

  function getEthBalance(address addr) public view override returns (uint256 balance) {
    balance = addr.balance;
  }

  function getLastBlockHash() public view override returns (bytes32 blockHash) {
    blockHash = getBlockHash(getBlockNumber() - 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
  /// @param _owner The address from which the balance will be retrieved
  /// @return balance the balance
  function balanceOf(address _owner) external view returns (uint256 balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return success Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) external returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return success Whether the transfer was successful or not
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return success Whether the approval was successful or not
  function approve(address _spender, uint256 _value) external returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return remaining Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IMulticallView {
  function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

  function getBlockNumber() external view returns (uint256 blockNumber);

  function getCurrentBlockCoinbase() external view returns (address coinbase);

  function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

  function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

  function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

  function getEthBalance(address addr) external view returns (uint256 balance);

  function getLastBlockHash() external view returns (bytes32 blockHash);
}

