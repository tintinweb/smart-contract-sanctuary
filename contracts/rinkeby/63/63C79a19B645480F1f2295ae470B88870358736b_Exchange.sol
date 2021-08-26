// SPDX-License-Identifier: AGPL-3.0-or-later

/// Exchange.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.7.6;
import "../interfaces/IERC20.sol";
import "../utils/SafeMath.sol";
import "../utils/SafeERC20.sol";

contract Exchange {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public feeBeneficiaryAddress;
  mapping(address => bool) public WHITELISTED_CALLERS;
  uint8 public fee;
  uint256 public constant feeBase = 10000;

  constructor(
    address authorisedCaller,
    address feeBeneficiary,
    uint8 _fee
  ) {
    WHITELISTED_CALLERS[authorisedCaller] = true;
    feeBeneficiaryAddress = feeBeneficiary;
    WHITELISTED_CALLERS[feeBeneficiary] = true;
    fee = _fee;
  }

  event AssetSwap(
    address indexed assetIn,
    address indexed assetOut,
    uint256 amountIn,
    uint256 amountOut
  );
  event FeePaid(address indexed beneficiary, uint256 amount);
  event SlippageSaved(uint256 minimumPossible, uint256 actualAmount);

  modifier onlyAuthorized() {
    require(WHITELISTED_CALLERS[msg.sender], "Exchange / Unauthorized Caller.");
    _;
  }

  function setFee(uint8 _fee) public onlyAuthorized {
    fee = _fee;
  }

  function _transferIn(
    address from,
    address asset,
    uint256 amount
  ) internal {
    require(
      IERC20(asset).allowance(from, address(this)) >= amount,
      "Exchange / Not enough allowance"
    );
    IERC20(asset).safeTransferFrom(from, address(this), amount);
  }

  function _swap(
    address fromAsset,
    address toAsset,
    uint256 amount,
    uint256 receiveAtLeast,
    address callee,
    bytes calldata withData
  ) internal returns (uint256) {
    IERC20(fromAsset).safeApprove(callee, amount);
    (bool success, ) = callee.call(withData);
    require(success, "Exchange / Could not swap");
    uint256 balance = IERC20(toAsset).balanceOf(address(this));
    emit SlippageSaved(receiveAtLeast, balance);
    require(balance >= receiveAtLeast, "Exchange / Received less");
    emit AssetSwap(fromAsset, toAsset, amount, balance);
    return balance;
  }

  function _collectFee(address asset, uint256 fromAmount) internal returns (uint256) {
    uint256 feeToTransfer = (fromAmount.mul(fee)).div(feeBase);
    IERC20(asset).safeTransfer(feeBeneficiaryAddress, feeToTransfer);
    emit FeePaid(feeBeneficiaryAddress, feeToTransfer);
    return fromAmount.sub(feeToTransfer);
  }

  function _transferOut(
    address asset,
    address to,
    uint256 amount
  ) internal {
    IERC20(asset).safeTransfer(to, amount);
  }

  function swapDaiForToken(
    address asset,
    uint256 amount,
    uint256 receiveAtLeast,
    address callee,
    bytes calldata withData
  ) public {
    _transferIn(msg.sender, DAI_ADDRESS, amount);

    uint256 _amount = _collectFee(DAI_ADDRESS, amount);
    uint256 balance = _swap(DAI_ADDRESS, asset, _amount, receiveAtLeast, callee, withData);

    uint256 daiBalance = IERC20(DAI_ADDRESS).balanceOf(address(this));

    if (daiBalance > 0) {
      _transferOut(DAI_ADDRESS, msg.sender, daiBalance);
    }

    _transferOut(asset, msg.sender, balance);
  }

  function swapTokenForDai(
    address asset,
    uint256 amount,
    uint256 receiveAtLeast,
    address callee,
    bytes calldata withData
  ) public  {
    _transferIn(msg.sender, asset, amount);

    uint256 balance = _swap(asset, DAI_ADDRESS, amount, receiveAtLeast, callee, withData);
    uint256 _balance = _collectFee(DAI_ADDRESS, balance);

    uint256 assetBalance = IERC20(asset).balanceOf(address(this));

    if (assetBalance > 0) {
      _transferOut(asset, msg.sender, assetBalance);
    }

    _transferOut(DAI_ADDRESS, msg.sender, _balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint256 supply);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  function decimals() external view returns (uint256 digits);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

import '../interfaces/IERC20.sol';
import './Address.sol';
import './SafeMath.sol';

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {ERC20-approve}, and its usage is discouraged.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      'SafeERC20: decreased allowance below zero'
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

library Address {
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'Address: low-level call failed');
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), 'Address: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
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