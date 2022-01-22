// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC20/SafeERC20.sol";
import "./math/SafeMath.sol";
import "./interfaces/IStaking.sol";
import "./utils/Pausable.sol";
import "./utils/ReentrancyGuard.sol";
import "./RewardsAdministrator.sol";


contract TestStaking is IStaking, RewardsAdministrator, ReentrancyGuard, Pausable {
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event UpdateRewardsDuration(uint256 newDuration);

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardsToken;
    uint256 public periodFinish = 0;
    uint256 public rate = 0;
    uint256 public rewardsDuration = 1 hours;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenGlobal;
    
    mapping(address => uint256) public rewardPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalStakes;
    mapping(address => uint256) private _usersVault;

    constructor(
        address _rewardsAdministrator,
        address _rewardsVault,
        address _rewardsToken,
        address _stakingToken
    ) {
        rewardsAdministrator = _rewardsAdministrator;
        rewardsVault = _rewardsVault;
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
    }

    modifier updateReward(address account) {
        rewardPerTokenGlobal = rewardPerToken();
        lastUpdateTime = lastUpdated();
        if (account != address(0)) {
            rewards[account] = earned(account);
            rewardPaid[account] = rewardPerTokenGlobal;
        }
        _;
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_totalStakes == 0) {
            return rewardPerTokenGlobal;
        }
        return rewardPerTokenGlobal.add(lastUpdated().sub(lastUpdateTime).mul(rate).mul(1e18).div(_totalStakes));
    }

    function totalStakes() external view override returns (uint256) {
        return _totalStakes;
    }

    function stakedAmountOf(address account) external view override returns (uint256) {
        return _usersVault[account];
    }

    function lastUpdated() public view override returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function earned(address account) public view override returns (uint256) {
        return _usersVault[account].mul(rewardPerToken().sub(rewardPaid[account])).div(1e18).add(rewards[account]);
    }

    function currentTotalRewards() external view override returns (uint256) {
        return rate.mul(rewardsDuration);
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) override {
        require(amount > 0, "Cannot stake 0");
        _totalStakes = _totalStakes.add(amount);
        _usersVault[msg.sender] = _usersVault[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public nonReentrant updateReward(msg.sender) override {
        require(amount > 0, "Cannot withdraw 0");
        _totalStakes = _totalStakes.sub(amount);
        _usersVault[msg.sender] = _usersVault[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
    }

    function claimReward() public nonReentrant updateReward(msg.sender) override {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransferFrom(rewardsVault, msg.sender, reward);
            emit ClaimReward(msg.sender, reward);
        }
    }

    function exit() external override {
        unstake(_usersVault[msg.sender]);
        claimReward();
    }

    function addRewards(uint256 reward) external onlyRewardsAdministrator updateReward(address(0)) override {
        if (block.timestamp >= periodFinish) {
            rate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rate);
            rate = reward.add(leftover).div(rewardsDuration);
        }

        uint balance = rewardsToken.balanceOf(rewardsVault);
        require(rate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit UpdateRewardsDuration(rewardsDuration);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IStaking {
    function totalStakes() external view returns (uint256);

    function stakedAmountOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function lastUpdated() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function currentTotalRewards() external view returns (uint256);

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function claimReward() external;

    function exit() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;


    constructor () {
        _paused = false;
    }


    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// Inheritance
import "./access/Ownable.sol";

abstract contract RewardsAdministrator is Ownable {
    event RewardsVaultUpdated(address indexed vault);

    address public rewardsAdministrator;
    address public rewardsVault;

    function addRewards(uint256 reward) external virtual;

    modifier onlyRewardsAdministrator() {
        require(msg.sender == rewardsAdministrator, "Caller is not Rewards Administrator");
        _;
    }

    function setRewardsAdministrator(address _rewardsAdministrator) external virtual onlyOwner {
        rewardsAdministrator = _rewardsAdministrator;
    }

    function setRewardsValut(address _rewardsVault) external virtual onlyRewardsAdministrator {
        require(_rewardsVault != address(0), "Cannot be address 0");
        rewardsVault = _rewardsVault;
        emit RewardsVaultUpdated(rewardsVault);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}