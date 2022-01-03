/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

// CHECKED

/**
 *  ADDRESS:
 *  CONSTRUCTOR:
 *      1. treasury:
 *      2. token:
 *      3. epochLength:
 *      4. nextEpochBlock:
 *      5. staking:
 *      6. sToken:
 *
 *  CONTRACT DEPENDENCIES:
 *      - Treasury
 *      - Token
 *      - Staking
 *      - sToken
 */

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

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
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
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrrt(uint256 a) internal pure returns (uint256 c) {
    if (a > 3) {
      c = a;
      uint256 b = add(div(a, 2), 1);
      while (b < c) {
        c = b;
        b = div(add(div(a, b), b), 2);
      }
    } else if (a != 0) {
      c = 1;
    }
  }

  function percentageAmount(uint256 total_, uint8 percentage_)
    internal
    pure
    returns (uint256 percentAmount_)
  {
    return div(mul(total_, percentage_), 1000);
  }

  function substractPercentage(uint256 total_, uint8 percentageToSub_)
    internal
    pure
    returns (uint256 result_)
  {
    return sub(total_, div(mul(total_, percentageToSub_), 1000));
  }

  function percentageOfTotal(uint256 part_, uint256 total_)
    internal
    pure
    returns (uint256 percent_)
  {
    return div(mul(part_, 100), total_);
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function quadraticPricing(uint256 payment_, uint256 multiplier_)
    internal
    pure
    returns (uint256)
  {
    return sqrrt(mul(multiplier_, payment_));
  }

  function bondingCurve(uint256 supply_, uint256 multiplier_)
    internal
    pure
    returns (uint256)
  {
    return mul(multiplier_, supply_);
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
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
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(
      data
    );
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

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
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
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function addressToString(address _address)
    internal
    pure
    returns (string memory)
  {
    bytes32 _bytes = bytes32(uint256(_address));
    bytes memory HEX = "0123456789abcdef";
    bytes memory _addr = new bytes(42);

    _addr[0] = "0";
    _addr[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
      _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
      _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }

    return string(_addr);
  }
}

interface IPolicy {
  function policy() external view returns (address);

  function renouncePolicy() external;

  function pushPolicy(address newPolicy_) external;

  function pullPolicy() external;
}

contract Policy is IPolicy {
  address internal _policy;
  address internal _newPolicy;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _policy = msg.sender;
    emit OwnershipTransferred(address(0), _policy);
  }

  function policy() public view override returns (address) {
    return _policy;
  }

  modifier onlyPolicy() {
    require(_policy == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renouncePolicy() public virtual override onlyPolicy {
    emit OwnershipTransferred(_policy, address(0));
    _policy = address(0);
  }

  function pushPolicy(address newPolicy_) public virtual override onlyPolicy {
    require(newPolicy_ != address(0), "Ownable: new owner is the zero address");
    _newPolicy = newPolicy_;
  }

  function pullPolicy() public virtual override {
    require(msg.sender == _newPolicy);
    emit OwnershipTransferred(_policy, _newPolicy);
    _policy = _newPolicy;
  }
}

interface ITreasury {
  function mintRewards(address _recipient, uint256 _amount) external;
}

interface ISTOKEN {
  function circulatingSupply() external view returns (uint256);
}

contract Distributor is Policy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ====== VARIABLES ====== */

  address public immutable Token;
  address public immutable treasury;

  uint256 public immutable epochLength;
  uint256 public nextEpochBlock;

  address public staking;
  address public sToken;

  uint256 public rate; //5900=0.59%
  uint256 public favouriteForNew; //1000=0.1%

  struct Adjust {
    bool add;
    uint256 rate;
    uint256 target;
  }

  Adjust public adjustment;

  /* ====== CONSTRUCTOR ====== */

  constructor(
    address _treasury,
    address _token,
    uint256 _epochLength,
    uint256 _nextEpochBlock,
    address _staking,
    address _sToken
  ) {
    require(_treasury != address(0));
    treasury = _treasury;
    require(_token != address(0));
    Token = _token;
    require(_staking != address(0));
    staking = _staking;
    require(_sToken != address(0));
    sToken = _sToken;
    epochLength = _epochLength;
    nextEpochBlock = _nextEpochBlock;
    favouriteForNew = 0;
  }

  /* ====== PUBLIC FUNCTIONS ====== */

  /**
        @notice send epoch reward to staking contract
     */
  function distribute() external returns (bool) {
    if (nextEpochBlock <= block.number) {
      nextEpochBlock = nextEpochBlock.add(epochLength); // set next epoch block

      if (rate == 0) return false;
      uint256 reward = nextRewardAt(rate);
      ITreasury(treasury).mintRewards(staking, reward);
      adjust();
      return true;
    } else {
      return false;
    }
  }

  /* ====== INTERNAL FUNCTIONS ====== */

  /**
        @notice increment reward rate for collector
     */
  function adjust() internal {
    if (adjustment.rate != 0) {
      if (adjustment.add) {
        // if rate should increase
        rate = rate.add(adjustment.rate); // raise rate
        if (rate >= adjustment.target) {
          // if target met
          adjustment.rate = 0; // turn off adjustment
        }
      } else {
        // if rate should decrease
        rate = rate.sub(adjustment.rate); // lower rate
        if (rate <= adjustment.target) {
          // if target met
          adjustment.rate = 0; // turn off adjustment
        }
      }
    }
  }

  /* ====== VIEW FUNCTIONS ====== */

  function split(
    uint256 reward,
    uint256 supply1,
    uint256 supply2,
    uint256 favouriteFor2
  ) public pure returns (uint256 _reward1) {
    if (reward == 0) {
      return 0;
    } else {
      uint256 total = supply1.add(supply2);
      uint256 percent1 = supply1.mul(1000000).div(total);
      if (favouriteFor2 < percent1) percent1 = percent1.sub(favouriteFor2);
      else percent1 = 0;
      uint256 reward1 = reward.mul(percent1).div(1000000);
      //if(supply1>0&&reward1<1)reward1=1;
      //uint reward1=reward.mul(supply1).div(total);
      return reward1;
    }
  }

  /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
  function nextRewardAt(uint256 _rate) public view returns (uint256) {
    return IERC20(Token).totalSupply().mul(_rate).div(1000000);
  }

  /* ====== POLICY FUNCTIONS ====== */
  function setRate(uint256 _rewardRate) external onlyPolicy {
    rate = _rewardRate;
  }

  function setFavouriteForNew(uint256 _favouriteForNew) external onlyPolicy {
    require(
      _favouriteForNew <= 50000,
      "the addtional absolute percentage of reward for new staking can't >5%"
    );
    favouriteForNew = _favouriteForNew;
  }

  function setNewStaking(address _newStaking, address _sTokenNew)
    external
    onlyPolicy
  {
    require(_newStaking != address(0));
    staking = _newStaking;
    require(_sTokenNew != address(0));
    sToken = _sTokenNew;
  }

  /**
        @notice set adjustment info for a collector's reward rate
        @param _add bool
        @param _rate uint
        @param _target uint
     */

  function setAdjustment(
    bool _add,
    uint256 _rate,
    uint256 _target
  ) external onlyPolicy {
    adjustment = Adjust({ add: _add, rate: _rate, target: _target });
  }
}