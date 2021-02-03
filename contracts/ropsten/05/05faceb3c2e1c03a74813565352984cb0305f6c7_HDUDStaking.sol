/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract HDUDStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public hdudPoolAddr;
    IHDUDPool hdudPool;
    
    uint constant REWARD_ACC = 1e10;
    uint constant dynamicRewardLimit = 6 ether;
    
    constructor () public {
        hdudPoolAddr = address(0x08aF2c6b94FAF3342fF359BAC5074B499856103B);
        hdudPool = IHDUDPool(hdudPoolAddr);
    }
    
    function deposit(uint _poolIndex, uint _amount, address _referrer) public {
        (address lpToken, uint startTime, uint endTime,,,uint curTotalStaking,,) = hdudPool.poolInfoes(_poolIndex);
        require(block.timestamp > startTime, "staking no start");
        require(block.timestamp < endTime, "staking end");
        
        IERC20 token = IERC20(lpToken);
        token.safeTransferFrom(msg.sender, hdudPoolAddr, _amount);
        
        updatePool(_poolIndex);
        hdudPool.setUser(msg.sender, _referrer, 0, 0, 0);
        hdudPool.setDeposit(_poolIndex, msg.sender, _amount);
        hdudPool.setPool(_poolIndex, 0, curTotalStaking.add(_amount));
    }

    function viewStakingAmount(uint _poolIndex, address _player) view public returns (uint) {
        uint pid = _poolIndex;
        address player = _player;
        uint depoCount = hdudPool.depositCounts(pid, player);
        uint stakingAmount;
        for (uint i = 1; i <= depoCount; i++) {
           (uint amount,,,) = hdudPool.depositInfoes(pid, player, depoCount);
           stakingAmount = stakingAmount.add(amount);
        }
        return stakingAmount;
        
    }

    function viewReward(uint _poolIndex, address _player) view public returns (uint, uint) {
        uint pid = _poolIndex;
        address player = _player;
    
        (,uint startTime, uint endTime,uint lastRewardTime,uint curReward,uint curTotalStaking,,uint amountPerSec) = hdudPool.poolInfoes(pid);
        uint rewardTime = block.timestamp < endTime ? block.timestamp : endTime;
        if (lastRewardTime == 0) {
            lastRewardTime = startTime;
        }
        if (curTotalStaking > 0) {
            curReward = curReward.add(rewardTime.sub(lastRewardTime).mul(amountPerSec.mul(REWARD_ACC)).div(curTotalStaking));
        }
        uint depoCount = hdudPool.depositCounts(pid, player);
        uint rewardHDUD;
        for (uint i = 1; i <= depoCount; i++) {
           (uint amount, uint rewardDebt,,) = hdudPool.depositInfoes(pid, player, depoCount);
           uint reward = curReward.sub(rewardDebt);
           rewardHDUD = rewardHDUD.add(reward.mul(amount).div(REWARD_ACC));
        }
        rewardHDUD = rewardHDUD.mul(85).div(100);
        
        // dynamic reward:
        (, uint dynamicReward,, uint dynamicWd,) = hdudPool.userInfoes(player);
        return (rewardHDUD, dynamicReward.sub(dynamicWd));
    }
    
    function getReward(uint _poolIndex) public {
        address player = msg.sender;
        updatePool(_poolIndex);
        // static reward:
        (, uint startTime,,,uint curReward,,,) = hdudPool.poolInfoes(_poolIndex);
        require(block.timestamp > startTime, "staking no start");

        uint depoCount = hdudPool.depositCounts(_poolIndex, player);
        uint rewardHDUD;
        for (uint i = 1; i <= depoCount; i++) {
           (uint amount, uint rewardDebt,,) = hdudPool.depositInfoes(_poolIndex, player, depoCount);
           uint reward = curReward.sub(rewardDebt);
           hdudPool.updateDeposit(_poolIndex, player, depoCount, reward);
           rewardHDUD = rewardHDUD.add(reward.mul(amount).div(REWARD_ACC));
        }
        feedback(player, 1, rewardHDUD, 5);
        uint recieve = rewardHDUD.mul(85).div(100);
        
        // dynamic reward:
        (, uint dynamicReward,, uint dynamicWd,) = hdudPool.userInfoes(player);
        recieve = recieve.add(dynamicReward.sub(dynamicWd));
        hdudPool.setUser(player, address(0), 0, rewardHDUD.mul(85).div(100), dynamicReward.sub(dynamicWd));
    
        hdudPool.mintHDUD(player, recieve);
    }

    function withdrawAndGetReward(uint _poolIndex) public {
        address player = msg.sender;
        updatePool(_poolIndex);
        // static reward:
        (, uint startTime,,,uint curReward, uint curTotalStaking,,) = hdudPool.poolInfoes(_poolIndex);
        require(block.timestamp > startTime, "staking no start");
        
        uint depoCount = hdudPool.depositCounts(_poolIndex, player);
        uint rewardHDUD;
        uint subETHTotal;
        uint wdAmount;
        for (uint i = 1; i <= depoCount; i++) {
           (uint amount, uint rewardDebt,,uint amountETH) = hdudPool.depositInfoes(_poolIndex, player, depoCount);
           uint reward = curReward.sub(rewardDebt);
           rewardHDUD = rewardHDUD.add(reward.mul(amount).div(REWARD_ACC));
           subETHTotal = subETHTotal.add(amountETH);
           wdAmount = wdAmount.add(amount);
        }
        feedback(player, 1, rewardHDUD, 5);
        uint recieve = rewardHDUD.mul(85).div(100);
        hdudPool.deleteDeposit(_poolIndex, player, subETHTotal);
        
        // dynamic reward:
        (, uint dynamicReward,, uint dynamicWd,) = hdudPool.userInfoes(player);
        recieve = recieve.add(dynamicReward.sub(dynamicWd));
        hdudPool.setUser(player, address(0), 0, rewardHDUD.mul(85).div(100), dynamicReward.sub(dynamicWd));
        
        hdudPool.mintHDUD(player, recieve);
        hdudPool.setPool(_poolIndex, 0, curTotalStaking.sub(wdAmount));
        hdudPool.withdrawLp(_poolIndex, player, wdAmount);
    }

    function feedback(address _player, uint _gene, uint _amount, uint _rate) private {
        if (_gene > 5) {
            return;
        }
        (address referrer,,,,) = hdudPool.userInfoes(_player);
        (,,,, uint amountETHTotal) = hdudPool.userInfoes(referrer);
        if (amountETHTotal >= dynamicRewardLimit){
            hdudPool.setUser(referrer, address(0), _amount.mul(_rate).div(100), 0, 0);
        }
        uint nextGene = _gene + 1;
        feedback(referrer, nextGene, _amount, 6 - nextGene);
    }

    function updatePool(uint _poolIndex) private {
        (,uint startTime, uint endTime,uint lastRewardTime,,uint curTotalStaking,,uint amountPerSec) = hdudPool.poolInfoes(_poolIndex);
        uint rewardTime = block.timestamp < endTime ? block.timestamp : endTime;
        if (lastRewardTime == 0) {
            lastRewardTime = startTime;
        }
        if (curTotalStaking > 0) {
            uint newReward = rewardTime.sub(lastRewardTime).mul(amountPerSec.mul(REWARD_ACC)).div(curTotalStaking);
            hdudPool.setPool(_poolIndex, newReward, curTotalStaking);
        }else {
            hdudPool.setPool(_poolIndex, 0, curTotalStaking);
        }
    }
}

interface IHDUDPool{
    function userInfoes(address _user) external view returns(
        address referrer,
        uint dynamicReward,
        uint staticWd,        
        uint dynamicWd,
        uint amountETHTotal
    );
    function poolInfoes(uint _pid) external view returns(
        address lpToken,
        uint startTime,
        uint endTime,
        uint lastRewardTime,
        uint curReward,
        uint curTotalStaking,
        uint amountLimit,
        uint amountPerSec
    );
    function depositInfoes(uint _pid,address _user, uint _index) external view returns(
        uint amount,     // How many LP tokens the user has provided.
        uint rewardDebt, // Reward debt. See explanation below.
        uint stakeTime,
        uint amountETH
    );
    function depositCounts(uint _pid,address _user) external view returns(uint index);
    
    function setPool(uint _pid,uint _reward, uint _curTotalStaking) external;
    function setUser(address _player, address _referrer, uint _addDynamicReward, uint _addStaticWd, uint _addDynamicWd) external;
    function deleteDeposit(uint _pid, address _player, uint subETHTotal) external;
    function setDeposit(uint _pid, address _player, uint _amount) external;
    function updateDeposit(uint _pid, address _player, uint _depoIndex, uint _newDebt) external;
    function mintHDUD(address _player, uint _amount) external;
    function withdrawLp(uint _pid, address _player, uint _amount) external;
}
interface IUniswapPair{
    function getReservers()external view  returns(uint,uint,uint);
    function totalSupply()external view returns(uint);
    function token0()external view returns(address);
    function token1()external view returns(address);
}