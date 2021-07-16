/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-10
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File contracts/additional/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


// File contracts/additional/TransferHelper.sol


// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}


// File contracts/additional/IERC20.sol


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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


// File contracts/additional/Context.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/additional/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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


// File contracts/GFI_Farm.sol

contract Farm_Contract is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;     // LP tokens provided.
        uint256 rewardDebt; // Reward debt.
    }
    
    struct FarmInfo {
        IERC20 lpToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 blockReward;
        uint256 bonusEndBlock;
        uint256 bonus;
        uint256 endBlock;
        uint256 lastRewardBlock;  // Last block number that reward distribution occurs.
        uint256 accRewardPerShare; // rewards per share, times 1e12
        uint256 farmableSupply; // total amount of tokens farmable
        uint256 numFarmers; // total amount of farmers
    }

    FarmInfo public farmInfo;
    
    mapping (address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    
    /**
     * @dev initialize farming contract, should be called only once
     * @param _rewardToken token to be rewarded to the user (GFI)
     * @param _amount amount of tokens to be farmed in total
     * @param _lpToken ERC20 compatible (lp) token used for farming
     * @param _blockReward token rewards per blockReward
     * @param _startBlock blocknumber to start farming
     * @param _endBlock blocknumber to stop farming
     * @param _bonusEndBlock blocknumber to stop the bonus period
     * @param _bonus bonus amount
     */
    function init (IERC20 _rewardToken, uint256 _amount, IERC20 _lpToken, uint256 _blockReward, uint256 _startBlock, uint256 _endBlock, uint256 _bonusEndBlock, uint256 _bonus) public onlyOwner {
        TransferHelper.safeTransferFrom(address(_rewardToken), msg.sender, address(this), _amount);
        farmInfo.rewardToken = _rewardToken;
        
        farmInfo.startBlock = _startBlock;
        farmInfo.blockReward = _blockReward;
        farmInfo.bonusEndBlock = _bonusEndBlock;
        farmInfo.bonus = _bonus;
        
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        farmInfo.lpToken = _lpToken;
        farmInfo.lastRewardBlock = lastRewardBlock;
        farmInfo.accRewardPerShare = 0;
        
        farmInfo.endBlock = _endBlock;
        farmInfo.farmableSupply = _amount;
    }

    /**
     * @dev Gets the reward multiplier over the given _from_block until _to block
     * @param _from_block the start of the period to measure rewards for
     * @param _to the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(uint256 _from_block, uint256 _to) public view returns (uint256) {
        uint256 _from = _from_block >= farmInfo.startBlock ? _from_block : farmInfo.startBlock;
        uint256 to = farmInfo.endBlock > _to ? _to : farmInfo.endBlock;
        if (to <= farmInfo.bonusEndBlock) {
            return to.sub(_from).mul(farmInfo.bonus);
        } else if (_from >= farmInfo.bonusEndBlock) {
            return to.sub(_from);
        } else {
            return farmInfo.bonusEndBlock.sub(_from).mul(farmInfo.bonus).add(
                to.sub(farmInfo.bonusEndBlock)
            );
        }
    }

    /**
     * @dev get pending reward token for address
     * @param _user the user for whom unclaimed tokens will be shown
     * @return total amount of withdrawable reward tokens
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = farmInfo.accRewardPerShare;
        uint256 lpSupply = farmInfo.lpToken.balanceOf(address(this));
        if (block.number > farmInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(farmInfo.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(farmInfo.blockReward);
            accRewardPerShare = accRewardPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev updates pool information to be up to date to the current block
     */
    function updatePool() public {
        if (block.number <= farmInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = farmInfo.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            farmInfo.lastRewardBlock = block.number < farmInfo.endBlock ? block.number : farmInfo.endBlock;
            return;
        }
        uint256 multiplier = getMultiplier(farmInfo.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(farmInfo.blockReward);
        farmInfo.accRewardPerShare = farmInfo.accRewardPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        farmInfo.lastRewardBlock = block.number < farmInfo.endBlock ? block.number : farmInfo.endBlock;
    }
    
    /**
     * @dev deposit LP token function for msg.sender
     * @param _amount the total deposit amount
     */
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) { //first pay out pending rewards if already farming
            uint256 pending = user.amount.mul(farmInfo.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            safeRewardTransfer(msg.sender, pending);
        }
        if (user.amount == 0 && _amount > 0) { //not farming already -> add farmer to total amount
            farmInfo.numFarmers = farmInfo.numFarmers.add(1);
        }
        farmInfo.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(farmInfo.accRewardPerShare).div(1e12); //already rewarded tokens
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev withdraw LP token function for msg.sender
     * @param _amount the total withdrawable amount
     */
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Withdrawal request amount exceeds user farming amount");
        updatePool();
        if (user.amount == _amount && _amount > 0) { //withdraw everything -> less farmers
            farmInfo.numFarmers = farmInfo.numFarmers.sub(1);
        }
        uint256 pending = user.amount.mul(farmInfo.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        safeRewardTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(farmInfo.accRewardPerShare).div(1e12);
        farmInfo.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev function to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
     */
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        farmInfo.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        if (user.amount > 0) {
            farmInfo.numFarmers = farmInfo.numFarmers.sub(1);
        }
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /**
     * @dev Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
     * @param _to the user address to transfer tokens to
     * @param _amount the total amount of tokens to transfer
     */
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = farmInfo.rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            farmInfo.rewardToken.transfer(_to, rewardBal);
        } else {
            farmInfo.rewardToken.transfer(_to, _amount);
        }
    }
    
    /**
     * @dev Emergency withdraw reward tokens to owner in case of vulnerability or 
     * @param amount amount of tokens to be sent
     */
    function withdrawRewards(uint256 amount) public onlyOwner {
        farmInfo.rewardToken.transfer(msg.sender, amount) ;
    }
}