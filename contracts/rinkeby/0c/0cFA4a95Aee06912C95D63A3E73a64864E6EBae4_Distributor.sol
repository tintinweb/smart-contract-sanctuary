/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/interfaces/IOwnable.sol

pragma solidity ^0.7.6;

interface IOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;

  function pushManagement(address newOwner_) external;

  function pullManagement() external;
}


// File contracts/common/Ownable.sol

pragma solidity ^0.7.6;

contract Ownable is IOwnable {
  address internal _owner;
  address internal _newOwner;

  event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
  event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = msg.sender;
    emit OwnershipPushed(address(0), _owner);
  }

  function manager() public view override returns (address) {
    return _owner;
  }

  modifier onlyManager() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceManagement() public virtual override onlyManager {
    emit OwnershipPushed(_owner, address(0));
    _owner = address(0);
  }

  function pushManagement(address newOwner_) public virtual override onlyManager {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipPushed(_owner, newOwner_);
    _newOwner = newOwner_;
  }

  function pullManagement() public virtual override {
    require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
    emit OwnershipPulled(_owner, _newOwner);
    _owner = _newOwner;
  }
}


// File contracts/interfaces/ITreasury.sol

pragma solidity ^0.7.6;

interface ITreasury {
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _profit
  ) external returns (bool);

  function valueOf(address _token, uint256 _amount) external view returns (uint256 value_);

  function mintRewards(address _recipient, uint256 _amount) external;
}


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.7.6;

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

  function sqrt(uint256 a) internal pure returns (uint256 c) {
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
}


// File contracts/libraries/Address.sol

pragma solidity ^0.7.6;

library Address {
  function isContract(address account) internal view returns (bool) {
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
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
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
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
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

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
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

  function addressToString(address _address) internal pure returns (string memory) {
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


// File contracts/interfaces/IERC20.sol

pragma solidity ^0.7.6;

interface IERC20 {
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/SafeERC20.sol

pragma solidity ^0.7.6;



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
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}


// File contracts/Distributor.sol

pragma solidity ^0.7.6;




contract Distributor is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ====== VARIABLES ====== */

  address public immutable SATO;
  address public immutable treasury;

  uint256 public immutable epochLength;
  uint256 public nextEpochBlock;

  mapping(uint256 => Adjust) public adjustments;

  /* ====== STRUCTS ====== */

  struct Info {
    uint256 rate; // in ten-thousandths ( 5000 = 0.5% )
    address recipient;
  }
  Info[] public info;

  struct Adjust {
    bool add;
    uint256 rate;
    uint256 target;
  }

  /* ====== CONSTRUCTOR ====== */

  constructor(
    address _treasury,
    address _sato,
    uint256 _epochLength,
    uint256 _nextEpochBlock
  ) {
    require(_treasury != address(0));
    treasury = _treasury;
    require(_sato != address(0));
    SATO = _sato;
    epochLength = _epochLength;
    nextEpochBlock = _nextEpochBlock;
  }

  /* ====== PUBLIC FUNCTIONS ====== */

  /**
        @notice send epoch reward to staking contract
     */
  function distribute() external returns (bool) {
    if (nextEpochBlock <= block.number) {
      nextEpochBlock = nextEpochBlock.add(epochLength); // set next epoch block

      // distribute rewards to each recipient
      for (uint256 i = 0; i < info.length; i++) {
        if (info[i].rate > 0) {
          ITreasury(treasury).mintRewards(info[i].recipient, nextRewardAt(info[i].rate)); // mint and send from treasury
          adjust(i); // check for adjustment
        }
      }
      return true;
    } else {
      return false;
    }
  }

  /* ====== INTERNAL FUNCTIONS ====== */

  /**
        @notice increment reward rate for collector
     */
  function adjust(uint256 _index) internal {
    Adjust memory adjustment = adjustments[_index];
    if (adjustment.rate != 0) {
      if (adjustment.add) {
        // if rate should increase
        info[_index].rate = info[_index].rate.add(adjustment.rate); // raise rate
        if (info[_index].rate >= adjustment.target) {
          // if target met
          adjustments[_index].rate = 0; // turn off adjustment
        }
      } else {
        // if rate should decrease
        info[_index].rate = info[_index].rate.sub(adjustment.rate); // lower rate
        if (info[_index].rate <= adjustment.target) {
          // if target met
          adjustments[_index].rate = 0; // turn off adjustment
        }
      }
    }
  }

  /* ====== VIEW FUNCTIONS ====== */

  /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
  function nextRewardAt(uint256 _rate) public view returns (uint256) {
    return IERC20(SATO).totalSupply().mul(_rate).div(1000000);
  }

  /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint
     */
  function nextRewardFor(address _recipient) public view returns (uint256) {
    uint256 reward;
    for (uint256 i = 0; i < info.length; i++) {
      if (info[i].recipient == _recipient) {
        reward = nextRewardAt(info[i].rate);
      }
    }
    return reward;
  }

  /* ====== POLICY FUNCTIONS ====== */

  /**
        @notice adds recipient for distributions
        @param _recipient address
        @param _rewardRate uint
     */
  function addRecipient(address _recipient, uint256 _rewardRate) external onlyManager {
    require(_recipient != address(0));
    info.push(Info({ recipient: _recipient, rate: _rewardRate }));
  }

  /**
        @notice removes recipient for distributions
        @param _index uint
        @param _recipient address
     */
  function removeRecipient(uint256 _index, address _recipient) external onlyManager {
    require(_recipient == info[_index].recipient);
    info[_index].recipient = address(0);
    info[_index].rate = 0;
  }

  /**
        @notice set adjustment info for a collector's reward rate
        @param _index uint
        @param _add bool
        @param _rate uint
        @param _target uint
     */
  function setAdjustment(
    uint256 _index,
    bool _add,
    uint256 _rate,
    uint256 _target
  ) external onlyManager {
    adjustments[_index] = Adjust({ add: _add, rate: _rate, target: _target });
  }
}