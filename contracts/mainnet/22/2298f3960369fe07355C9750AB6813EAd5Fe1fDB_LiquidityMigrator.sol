/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
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
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

interface IERC20 {
  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
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

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

interface IUniswapV2Router {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);
}

interface ITreasury {
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _profit
  ) external returns (uint256);

  function withdraw(uint256 _amount, address _token) external;

  function tokenValue(address _token, uint256 _amount)
    external
    view
    returns (uint256 value_);

  function mint(address _recipient, uint256 _amount) external;

  function manage(address _token, uint256 _amount) external;

  function incurDebt(uint256 amount_, address token_) external;

  function repayDebtWithReserve(uint256 amount_, address token_) external;

  function excessReserves() external view returns (uint256);

  function baseSupply() external view returns (uint256);
}

interface IMigrator {
  enum TYPE {
    UNSTAKED,
    STAKED,
    WRAPPED
  }

  // migrate OHMv1, sOHMv1, or wsOHM for OHMv2, sOHMv2, or gOHM
  function migrate(
    uint256 _amount,
    TYPE _from,
    TYPE _to
  ) external;
}

contract LiquidityMigrator {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public policy;
  address public leftoverRecipient;

  ITreasury internal immutable treasury =
    ITreasury(0x873ad91fA4F2aA0d557C0919eC3F6c9D240cDd05);

  IERC20 internal immutable oldOHM =
    IERC20(0x383518188C0C6d7730D91b2c03a03C837814a899);

  IERC20 internal immutable newOHM =
    IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5);

  IMigrator internal immutable migrator =
    IMigrator(0x184f3FAd8618a6F458C16bae63F70C426fE784B3);

  constructor(address _leftoverRecipient) public {
    policy = msg.sender;
    leftoverRecipient = _leftoverRecipient;
  }

  modifier onlyPolicy() {
    require(msg.sender == policy, "!policy");
    _;
  }

  /**
   * @notice Migrate LP and pair with new OHM
   */
  function migrateLP(
    address pair,
    IUniswapV2Router routerFrom,
    IUniswapV2Router routerTo,
    address token,
    uint256 _minA,
    uint256 _minB,
    uint256 _deadline
  ) external onlyPolicy {
    // Since we are adding liquidity, any existing balance should be excluded
    uint256 initialNewOHMBalance = newOHM.balanceOf(address(this));
    // Fetch the treasury balance of the given liquidity pair
    uint256 oldLPAmount = IERC20(pair).balanceOf(address(treasury));
    treasury.manage(pair, oldLPAmount);

    // Remove the V1 liquidity
    IERC20(pair).approve(address(routerFrom), oldLPAmount);

    (uint256 amountToken, uint256 amountOHM) = routerFrom.removeLiquidity(
      token,
      address(oldOHM),
      oldLPAmount,
      _minA,
      _minB,
      address(this),
      _deadline
    );

    // Migrate the V1 OHM to V2 OHM
    oldOHM.approve(address(migrator), amountOHM);
    migrator.migrate(
      amountOHM,
      IMigrator.TYPE.UNSTAKED,
      IMigrator.TYPE.UNSTAKED
    );
    uint256 amountNewOHM = newOHM.balanceOf(address(this)).sub(
      initialNewOHMBalance
    ); // # V1 out != # V2 in

    // Add the V2 liquidity
    IERC20(token).approve(address(routerTo), amountToken);
    newOHM.approve(address(routerTo), amountNewOHM);

    routerTo.addLiquidity(
      token,
      address(newOHM),
      amountToken,
      amountNewOHM,
      amountToken,
      amountNewOHM,
      address(treasury),
      _deadline
    );

    // Send any leftover balance to the governor
    newOHM.safeTransfer(leftoverRecipient, newOHM.balanceOf(address(this)));
    oldOHM.safeTransfer(leftoverRecipient, oldOHM.balanceOf(address(this)));

    IERC20(token).safeTransfer(
      leftoverRecipient,
      IERC20(token).balanceOf(address(this))
    );
  }
}