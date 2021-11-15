// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IPremiaBondingCurveUpgrade} from "./interface/IPremiaBondingCurveUpgrade.sol";
import {IERC20} from "@solidstate/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

contract PremiaBondingCurveDeprecation is IPremiaBondingCurveUpgrade {
    using SafeERC20 for IERC20;

    address internal immutable PREMIA;
    address internal immutable TIMELOCK;
    address internal immutable TREASURY;

    constructor(
        address _premia,
        address _timelock,
        address _treasury
    ) {
        PREMIA = _premia;
        TIMELOCK = _timelock;
        TREASURY = _treasury;
    }

    function initialize(
        uint256 _premiaBalance,
        uint256,
        uint256
    ) external payable override {
        // Send PREMIA to timelocked contract
        IERC20(PREMIA).safeTransfer(TIMELOCK, _premiaBalance);

        if (msg.value > 0) {
            // Send with data to avoid multisig contract to reject transfer
            (bool sent, ) = payable(TREASURY).call{value: msg.value}("0x1");
            require(sent, "ETH transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPremiaBondingCurveUpgrade {
    function initialize(
        uint256 _premiaBalance,
        uint256 _ethBalance,
        uint256 _soldAmount
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Internal} from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
  /**
   * @notice query the total minted token supply
   * @return token supply
   */
  function totalSupply () external view returns (uint256);

  /**
   * @notice query the token balance of given account
   * @param account address to query
   * @return token balance
   */
  function balanceOf (
    address account
  ) external view returns (uint256);

  /**
   * @notice query the allowance granted from given holder to given spender
   * @param holder approver of allowance
   * @param spender recipient of allowance
   * @return token allowance
   */
  function allowance (
    address holder,
    address spender
  ) external view returns (uint256);

  /**
   * @notice grant approval to spender to spend tokens
   * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
   * @param spender recipient of allowance
   * @param amount quantity of tokens approved for spending
   * @return success status (always true; otherwise function should revert)
   */
  function approve (
    address spender,
    uint256 amount
  ) external returns (bool);

  /**
   * @notice transfer tokens to given recipient
   * @param recipient beneficiary of token transfer
   * @param amount quantity of tokens to transfer
   * @return success status (always true; otherwise function should revert)
   */
  function transfer (
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @notice transfer tokens to given recipient on behalf of given holder
   * @param holder holder of tokens prior to transfer
   * @param recipient beneficiary of token transfer
   * @param amount quantity of tokens to transfer
   * @return success status (always true; otherwise function should revert)
   */
  function transferFrom (
    address holder,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '../token/ERC20/IERC20.sol';
import {AddressUtils} from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
  function toString (address account) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(account)));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory chars = new bytes(42);

    chars[0] = '0';
    chars[1] = 'x';

    for (uint256 i = 0; i < 20; i++) {
      chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }

    return string(chars);
  }

  function isContract (address account) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function sendValue (address payable account, uint amount) internal {
    (bool success, ) = account.call{ value: amount }('');
    require(success, 'AddressUtils: failed to send value');
  }

  function functionCall (address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'AddressUtils: failed low-level call');
  }

  function functionCall (address target, bytes memory data, string memory error) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, error);
  }

  function functionCallWithValue (address target, bytes memory data, uint value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'AddressUtils: failed low-level call with value');
  }

  function functionCallWithValue (address target, bytes memory data, uint value, string memory error) internal returns (bytes memory) {
    require(address(this).balance >= value, 'AddressUtils: insufficient balance for call');
    return _functionCallWithValue(target, data, value, error);
  }

  function _functionCallWithValue (address target, bytes memory data, uint value, string memory error) private returns (bytes memory) {
    require(isContract(target), 'AddressUtils: function call to non-contract');

    (bool success, bytes memory returnData) = target.call{ value: value }(data);

    if (success) {
      return returnData;
    } else if (returnData.length > 0) {
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert(error);
    }
  }
}

