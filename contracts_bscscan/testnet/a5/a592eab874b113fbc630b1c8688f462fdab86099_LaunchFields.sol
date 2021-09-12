/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// Dependency file: @openzeppelin/contracts/utils/Address.sol

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
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
}

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

   
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Dependency file: @openzeppelin/upgrades/contracts/Initializable.sol

// pragma solidity >=0.4.24 <0.7.0;

contract Initializable {

 
  bool private initialized;
  bool private initializing;
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
   
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// Dependency file: contracts/StakePool.sol

contract LaunchPool is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public depositToken;
    address public feeTo;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function initialize(address _token, address _feeTo) public initializer {
        depositToken = IERC20(_token);
        feeTo = address(_feeTo);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _withdraw(uint256 amount) internal {
        if (msg.sender != address(feeTo)) {
            // Deduct 5% of withdrawal amount for Mining Pool Fee
            uint256 feeamount = amount.div(20); // 5%
            uint256 finalamount = (amount - feeamount);

            // Send funds without the Pool Fee
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            depositToken.safeTransfer(msg.sender, finalamount);
            depositToken.safeTransfer(feeTo, feeamount);
        } else {
            // Deduct full amount for feeTo account
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            depositToken.safeTransfer(msg.sender, amount);
        }
    }

    function _withdrawFeeOnly(uint256 amount) internal {
        // Deduct 5% of deposited tokens for fee
        uint256 feeamount = amount.div(20);
        _totalSupply = _totalSupply.sub(feeamount);
        _balances[msg.sender] = _balances[msg.sender].sub(feeamount);
        depositToken.safeTransfer(feeTo, feeamount);
    }

    // Update feeTo address by the previous feeTo.
    function feeToUpdate(address _feeTo) public {
        require(msg.sender == feeTo, "feeTo: wut?");
        feeTo = _feeTo;
    }
}

// Dependency file: @openzeppelin/contracts/math/Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
   
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


 contract LaunchFields is LaunchPool {
     // Yield Token as a reward for stakers
     IERC20 public rewardToken;

     // Halving period in seconds, should be defined as 2 weeks
     uint256 public halvingPeriod = 1209600;
     // Total reward in 18 decimal
     uint256 public totalreward;
     // Starting timestamp for LaunchField
     uint256 public starttime;
     // The timestamp when stakers should be allowed to withdraw
     uint256 public stakingtime;
     uint256 public eraPeriod = 0;
     uint256 public rewardRate = 0;
     uint256 public lastUpdateTime;
     uint256 public rewardPerTokenStored;
     uint256 public totalRewards = 0;

     mapping(address => uint256) public userRewardPerTokenPaid;
     mapping(address => uint256) public rewards;

     event RewardAdded(uint256 reward);
     event Staked(address indexed user, uint256 amount);
     event Withdrawn(address indexed user, uint256 amount);
     event RewardPaid(address indexed user, uint256 reward);

     modifier updateReward(address account) {
         rewardPerTokenStored = rewardPerToken();
         lastUpdateTime = lastTimeRewardApplicable();
         if (account != address(0)) {
             rewards[account] = earned(account);
             userRewardPerTokenPaid[account] = rewardPerTokenStored;
         }
         _;
     }

     constructor(address _depositToken, address _rewardToken, uint256 _totalreward, uint256 _starttime, uint256 _stakingtime) public {
         super.initialize(_depositToken, msg.sender);
         rewardToken = IERC20(_rewardToken);

         starttime = _starttime;
         stakingtime = _stakingtime;
         notifyRewardAmount(_totalreward.mul(50).div(100));
     }

     function lastTimeRewardApplicable() public view returns (uint256) {
         return Math.min(block.timestamp, eraPeriod);
     }

     function rewardPerToken() public view returns (uint256) {
         if (totalSupply() == 0) {
             return rewardPerTokenStored;
         }
         return
             rewardPerTokenStored.add(
                 lastTimeRewardApplicable()
                     .sub(lastUpdateTime)
                     .mul(rewardRate)
                     .mul(1e18)
                     .div(totalSupply())
             );
     }

     function earned(address account) public view returns (uint256) {
         return
             balanceOf(account)
                 .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                 .div(1e18)
                 .add(rewards[account]);
     }

     function stake(uint256 amount) public updateReward(msg.sender) checkhalve checkStart{
         require(amount > 0, "ERROR: Cannot stake 0 Token");
         super._stake(amount);
         emit Staked(msg.sender, amount);
     }

     function withdraw(uint256 amount) public updateReward(msg.sender) checkhalve checkStart stakingTime{
        require(amount > 0, "ERROR: Cannot withdraw 0");
        super._withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external stakingTime{
        withdraw(balanceOf(msg.sender));
        _getRewardInternal();
    }

     function getReward() public updateReward(msg.sender) checkhalve checkStart stakingTime{
         uint256 reward = earned(msg.sender);
         uint256 bal = balanceOf(msg.sender);
         if (reward > 0) {
             rewards[msg.sender] = 0;
             if (bal > 0) {
               super._withdrawFeeOnly(bal);
             }
             rewardToken.safeTransfer(msg.sender, reward);
             emit RewardPaid(msg.sender, reward);
             totalRewards = totalRewards.add(reward);
         }
     }

     function _getRewardInternal() internal updateReward(msg.sender) checkhalve checkStart{
         uint256 reward = earned(msg.sender);
         if (reward > 0) {
             rewards[msg.sender] = 0;
             rewardToken.safeTransfer(msg.sender, reward);
             emit RewardPaid(msg.sender, reward);
             totalRewards = totalRewards.add(reward);
         }
     }

     modifier checkhalve(){
         if (block.timestamp >= eraPeriod) {
             totalreward = totalreward.mul(50).div(100);

             rewardRate = totalreward.div(halvingPeriod);
             eraPeriod = block.timestamp.add(halvingPeriod);
             emit RewardAdded(totalreward);
         }
         _;
     }

     modifier checkStart(){
         require(block.timestamp > starttime,"ERROR: Not start");
         _;
     }

     modifier stakingTime(){
         require(block.timestamp >= stakingtime,"ERROR: Withdrawals not allowed yet");
         _;
     }

     function notifyRewardAmount(uint256 reward)
         internal
         updateReward(address(0))
     {
         if (block.timestamp >= eraPeriod) {
             rewardRate = reward.div(halvingPeriod);
         } else {
             uint256 remaining = eraPeriod.sub(block.timestamp);
             uint256 leftover = remaining.mul(rewardRate);
             rewardRate = reward.add(leftover).div(halvingPeriod);
         }
         totalreward = reward;
         lastUpdateTime = block.timestamp;
         eraPeriod = block.timestamp.add(halvingPeriod);
         emit RewardAdded(reward);
     }
 }