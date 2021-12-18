// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

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

interface IveFXS {
  struct LockedBalance {
    int128 amount;
    uint256 end;
  }

  function commit_transfer_ownership(address addr) external;

  function apply_transfer_ownership() external;

  function commit_smart_wallet_checker(address addr) external;

  function apply_smart_wallet_checker() external;

  function toggleEmergencyUnlock() external;

  function recoverERC20(address token_addr, uint256 amount) external;

  function get_last_user_slope(address addr) external view returns (int128);

  function user_point_history__ts(address _addr, uint256 _idx)
    external
    view
    returns (uint256);

  function locked__end(address _addr) external view returns (uint256);

  function checkpoint() external;

  function deposit_for(address _addr, uint256 _value) external;

  function create_lock(uint256 _value, uint256 _unlock_time) external;

  function increase_amount(uint256 _value) external;

  function increase_unlock_time(uint256 _unlock_time) external;

  function withdraw() external;

  function balanceOf(address addr) external view returns (uint256);

  function balanceOf(address addr, uint256 _t) external view returns (uint256);

  function balanceOfAt(address addr, uint256 _block)
    external
    view
    returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalSupply(uint256 t) external view returns (uint256);

  function totalSupplyAt(uint256 _block) external view returns (uint256);

  function totalFXSSupply() external view returns (uint256);

  function totalFXSSupplyAt(uint256 _block) external view returns (uint256);

  function changeController(address _newController) external;

  function token() external view returns (address);

  function supply() external view returns (uint256);

  function locked(address addr) external view returns (LockedBalance memory);

  function epoch() external view returns (uint256);

  function point_history(uint256 arg0)
    external
    view
    returns (
      int128 bias,
      int128 slope,
      uint256 ts,
      uint256 blk,
      uint256 fxs_amt
    );

  function user_point_history(address arg0, uint256 arg1)
    external
    view
    returns (
      int128 bias,
      int128 slope,
      uint256 ts,
      uint256 blk,
      uint256 fxs_amt
    );

  function user_point_epoch(address arg0) external view returns (uint256);

  function slope_changes(uint256 arg0) external view returns (int128);

  function controller() external view returns (address);

  function transfersEnabled() external view returns (bool);

  function emergencyUnlockActive() external view returns (bool);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function version() external view returns (string memory);

  function decimals() external view returns (uint256);

  function future_smart_wallet_checker() external view returns (address);

  function smart_wallet_checker() external view returns (address);

  function admin() external view returns (address);

  function future_admin() external view returns (address);
}

interface IYieldDistributor {
  function getYield() external returns (uint256);

  function checkpoint() external;
}

interface IFraxGaugeController {
  function vote_for_gauge_weights(address, uint256) external;
}

interface IDelegateRegistry {
  function setDelegate(bytes32 id, address delegate) external;

  function clearDelegate(bytes32 id) external;
}

interface ITreasury {
  function manage(address _token, uint256 _amount) external;

  function updateReserve(address _token, uint256 _amount) external;
}

contract FxsAllocator {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public policy;
  address public treasury;

  address public constant fxs =
    address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

  address public constant veFXS =
    address(0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0);

  address public yieldDistributor =
    address(0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872);

  address public gaugeController =
    address(0x44ade9AA409B0C29463fF7fcf07c9d3c939166ce);

  address public snapshotDelegationRegistry =
    address(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);

  constructor(address _treasury) public {
    policy = msg.sender;
    treasury = _treasury;
  }

  modifier onlyPolicy() {
    require(msg.sender == policy, "!policy");
    _;
  }

  function deposit(uint256 _amount) external onlyPolicy {
    ITreasury(treasury).manage(fxs, _amount);
    increaseAmount(_amount);
  }

  function withdraw() external onlyPolicy {
    IYieldDistributor(yieldDistributor).getYield();
    IveFXS(veFXS).withdraw();

    uint256 amount = IERC20(fxs).balanceOf(address(this));
    IERC20(fxs).safeTransfer(treasury, amount);
  }

  function createLock(uint256 _value, uint256 _unlockTime) external onlyPolicy {
    IERC20(fxs).approve(veFXS, 0);
    IERC20(fxs).approve(veFXS, _value);
    IveFXS(veFXS).create_lock(_value, _unlockTime);
    IYieldDistributor(yieldDistributor).checkpoint();
  }

  function increaseAmount(uint256 _value) internal {
    IERC20(fxs).approve(veFXS, 0);
    IERC20(fxs).approve(veFXS, _value);
    IveFXS(veFXS).increase_amount(_value);
    IYieldDistributor(yieldDistributor).checkpoint();
  }

  function increaseUnlockTime(uint256 _unlockTime) external onlyPolicy {
    IveFXS(veFXS).increase_unlock_time(_unlockTime);
    IYieldDistributor(yieldDistributor).checkpoint();
  }

  function claimRewards() external onlyPolicy {
    IYieldDistributor(yieldDistributor).getYield();
    increaseAmount(IERC20(fxs).balanceOf(address(this)));
  }

  function voteGaugeWeight(address _gauge, uint256 _weight)
    external
    onlyPolicy
  {
    IFraxGaugeController(gaugeController).vote_for_gauge_weights(
      _gauge,
      _weight
    );
  }

  function setDelegateSnapshotVoting(bytes32 _id, address _delegate)
    external
    onlyPolicy
  {
    IDelegateRegistry(snapshotDelegationRegistry).setDelegate(_id, _delegate);
  }

  function clearDelegateSnapshotVoting(bytes32 _id) external onlyPolicy {
    IDelegateRegistry(snapshotDelegationRegistry).clearDelegate(_id);
  }

  function setGovernance(address _policy) external onlyPolicy {
    policy = _policy;
  }

  function setTreasury(address _treasury) external onlyPolicy {
    treasury = _treasury;
  }

  function setYieldDistributor(address _newYieldDistributor)
    external
    onlyPolicy
  {
    yieldDistributor = _newYieldDistributor;
  }

  function setGaugeController(address _gaugeController) external onlyPolicy {
    gaugeController = _gaugeController;
  }

  function execute(
    address to,
    uint256 value,
    bytes calldata data
  ) external onlyPolicy returns (bool, bytes memory) {
    (bool success, bytes memory result) = to.call{value: value}(data);
    return (success, result);
  }
}