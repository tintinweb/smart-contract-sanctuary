/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma experimental ABIEncoderV2;

pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address _who) public virtual view returns (uint256);
  function transfer(address _to, uint256 _value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public virtual view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public virtual returns (bool);

  function approve(address _spender, uint256 _value) public virtual returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File @OpenZeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File @openzeppelin/contracts/utils/Address.sol

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File @openzeppelin/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/ETHHelper.sol

contract ETHHelper is Ownable, Pausable{
    constructor() public {
        IsPayble = false;
    }

    event TransferInETH(uint256 Amount, address From);

    modifier ReceivETH(uint256 msgValue, address msgSender, uint256 _MinETHInvest) {
        require(msgValue >= _MinETHInvest, "Send ETH to invest");
        emit TransferInETH(msgValue, msgSender);
        _;
    }

    //@dev not/allow contract to receive funds
    receive() external payable {
        if (!IsPayble) revert();
    }


    bool public IsPayble;

    function SwitchIsPayble() public onlyOwner {
        IsPayble = !IsPayble;
    }

}

// File: contracts/Manageable.sol

contract Manageable is ETHHelper {
    constructor() public {
        MaxDuration = 60 * 60 * 24 * 30 * 6; // half year
        MinETHInvest = 10000000;     // eth per wallet
        MaxETHInvest = 10 * 10**18; // 10 eth per wallet
        MinERCInvest = 10 * 10**18;  //. 10 BUSD
        MaxERCInvest = 500 * 10**18; // 500 BUSD 
    }

    //@dev for percent use uint16
    uint256 public MinDuration; //the minimum duration of a pool, in seconds
    uint256 public MaxDuration; //the maximum duration of a pool from the creation, in seconds
    // uint256 public PoolPrice;
    uint256 public MinETHInvest;
    uint256 public MaxETHInvest;
    uint256 public MinERCInvest;
    uint256 public MaxERCInvest;

    function SetMinMaxETHInvest(uint256 _MinETHInvest, uint256 _MaxETHInvest)
        public
        onlyOwner
    {
        MinETHInvest = _MinETHInvest;
        MaxETHInvest = _MaxETHInvest;
    }

    function SetMinMaxERCInvest(uint256 _MinERCInvest, uint256 _MaxERCInvest)
        public
        onlyOwner
    {
        MinERCInvest = _MinERCInvest;
        MaxERCInvest = _MaxERCInvest;
    }

    function SetMinMaxDuration(uint256 _minDuration, uint256 _maxDuration)
        public
        onlyOwner
    {
        MinDuration = _minDuration;
        MaxDuration = _maxDuration;
    }

}

// File: contracts/GainPoolStaking.sol

contract GainPoolStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        address user;
        uint256 id;
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 nextWithdrawUntil; // When can the user withdraw again.
    }

    struct PoolInfo {
        IERC20 stake;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 harvestInterval;  // Harvest interval in seconds 
        uint256 withdrawInterval;  // Withdraw interval in seconds 
    }

    IERC20 public rewardToken;
    uint256 public rewardPerBlock = uint256(964506173000);

    PoolInfo public pool;
    
    UserInfo[] public users;
    
    mapping(address => bool) public staked;
    mapping(address => UserInfo) public userInfo;
    
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    function setTokens(address _rewardToken, address _nativeToken) external onlyOwner {
        require(address(rewardToken) == address(0) && address(pool.stake) == address(0), 'Tokens already set!');
        rewardToken = IERC20(_rewardToken);
        IERC20 _stake = IERC20(_nativeToken);
        pool =
            PoolInfo({
                stake: _stake,
                lastRewardBlock: 0,
                accTokenPerShare: 0,
                harvestInterval:0,
                withdrawInterval:0
        });
    }
    
    function startPool(uint256 startBlock , uint256 _harvestInterval, uint256 _withdrawInterval) external onlyOwner {
        require(pool.lastRewardBlock == 0, 'Pool already started');
        require(address(rewardToken) != address(0) , "Reward Token not set");
        pool.lastRewardBlock = startBlock;
        pool.harvestInterval = _harvestInterval;
        pool.withdrawInterval = _withdrawInterval;
    }

    function pendingRewards(address _user) external view returns (uint256) {
        require(pool.lastRewardBlock > 0 && block.number >= pool.lastRewardBlock, 'Pool not yet started');
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 stakeSupply = pool.stake.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && stakeSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            uint256 tokenReward = multiplier.mul(rewardPerBlock);
            accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e24).div(stakeSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e24).sub(user.rewardDebt).add(user.pendingRewards);
    }

    function updatePool() internal {
        require(pool.lastRewardBlock > 0 && block.number >= pool.lastRewardBlock, 'Pool not yet started');
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 stakeSupply = pool.stake.balanceOf(address(this));
        if (stakeSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 tokenReward = multiplier.mul(rewardPerBlock);
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e24).div(stakeSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        user.user = msg.sender ;

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        if (user.nextWithdrawUntil == 0) {
            user.nextWithdrawUntil = block.timestamp.add(pool.withdrawInterval);
        }

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e24).sub(user.rewardDebt);
            if (pending > 0) {
                user.pendingRewards = user.pendingRewards.add(pending);
            }
        }
        
        if (amount > 0) {
            pool.stake.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amount = user.amount.add(amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e24);

        if (staked[user.user] == false) {
            user.id = users.length;
            users.push(user);
            staked[user.user] = true;
        } else {
            users[user.id] = user;
        }
        
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Withdrawing more than you have!");
        require(canWithdraw(msg.sender), "Not enough withdraw time");
        updatePool();
        
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e24).sub(user.rewardDebt);
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards.add(pending);
        }
        if (amount > 0) {
            user.amount = user.amount.sub(amount);
            pool.stake.safeTransfer(address(msg.sender), amount);
            user.nextWithdrawUntil = block.timestamp.add(pool.withdrawInterval);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e24);
        users[user.id] = user;
        emit Withdraw(msg.sender, amount);
    }

    function claim() external {
        require(canHarvest(msg.sender), "Not enough claim time");
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e24).sub(user.rewardDebt);

        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards.add(pending);
            uint256 claimedAmount = safeTokenTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, claimedAmount);
            user.pendingRewards = user.pendingRewards.sub(claimedAmount);
            if (claimedAmount > 0) {
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
            }
        }

        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e24);
        users[user.id] = user;
    }

    function safeTokenTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 tokenBalance = rewardToken.balanceOf(address(this));
        if (amount > tokenBalance) {
            rewardToken.safeTransfer(to, tokenBalance);
            return tokenBalance;
        } else {
            rewardToken.safeTransfer(to, amount);
            return amount;
        }
    }
    
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_rewardPerBlock > 0, "Reward per block should be greater than 0!");
        rewardPerBlock = _rewardPerBlock;
    }
    
    function usersLength() public view returns (uint256){
       return users.length;
    }

    function canHarvest(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    function updateHarvestInterval(uint256 _harvestInterval) external onlyOwner {
        pool.harvestInterval = _harvestInterval;
    }

    function canWithdraw(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return block.timestamp >= user.nextWithdrawUntil;
    }

    function updateWithdrawInterval(uint256 _withdrawInterval) external onlyOwner {
        pool.withdrawInterval = _withdrawInterval;
    }
  
    // function destroy() external onlyOwner {
    //     selfdestruct(address(this));
    // }
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/Pools.sol

contract Pools is Manageable {

    event NewPool(uint256 id);
    event FinishPool(uint256 id);
    event PoolUpdate(uint256 id);

    constructor() public {
        //  poolsCount = 0; //Start with 0
    }

    uint256 public poolsCount; // the ids of the pool
    mapping(uint256 => Pool) public pools; //the id of the pool with the data
    mapping(address => uint256[]) public poolsMap; //the address and all of the pools id's

    mapping(address => bool) public whitelistedAddresses; // addresses eligible for pool creation

    struct Pool {
        string Description;   
        string Name;
        string Chain;
        uint256 StartTime;      // the time the pool open //TODO Maybe Delete this?
        uint256 FinishTime;     //Until what time the pool is active
        uint256 HardCapInWei;        //The maximum investment for sale
        uint256 TotalCollectedToken;
        uint256 TotalPoolInvestors;
        string iconURL;
    }
    
    mapping(uint256 => address[]) public PoolInvestors;

    modifier whitelistedAddressOnly() {
        require(
            whitelistedAddresses[msg.sender],
            "Address not whitelisted"
        );
        _;
    }

    function addwhitelistedAddresses(address[] memory _whitelistedAddresses)
    public
    onlyOwner
    {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function removeWhitelistedAddresses(address[] memory _whitelistedAddresses)
    public
    onlyOwner
    {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = false;
        }
    }

    //create a new pool
    function CreatePool(
        string memory  _Description, 
        string memory _Name,
        string memory _Chain,
        uint256 _StartTime, //Start Time - can be 0 to not change current flow
        uint256 _FinishTime, //Until what time the pool will work
        uint256 _HardCap, //Total amount investment amount in the pool
        string memory _iconURL
    ) public onlyOwner whenNotPaused {
        // require(msg.value >= PoolPrice, "Need to pay for the pool");
        require(_FinishTime  < SafeMath.add(MaxDuration, now), "Pool duration can't be that long");
        if (_StartTime < now) _StartTime = now;
        require(
            SafeMath.add(now, MinDuration) <= _FinishTime,
            "Need more then MinDuration"
        ); // check if the time is OK
        
        //register the pool
        pools[poolsCount] = Pool(
                _Description,
                _Name,
                _Chain,
                _StartTime,
                _FinishTime,
                _HardCap,
                0,
                0,
                _iconURL
            );
        poolsMap[msg.sender].push(poolsCount);
        emit NewPool(poolsCount);
        poolsCount = SafeMath.add(poolsCount, 1); //joke - overflowfrom 0 on int256 = 1.16E77
    }
}

// File: contracts/PoolsData.sol

contract PoolsData is Pools {
    enum PoolStatus {Open, PreMade, Close} //the status of the pools

    modifier PoolId(uint256 _id) {
        require(_id < poolsCount, "Wrong pool id, Can't get Status");
        _;
    }

    function GetMyPoolsId() public view returns (uint256[] memory ) {
        return poolsMap[msg.sender];
    }

    function GetPoolBaseData(uint256 _Id)
        public
        view
        PoolId(_Id)
        returns (
            string memory,
            string memory,
            string memory,
            uint256,
            string memory
        )
    {
        return (
            pools[_Id].Description,
            pools[_Id].Name,
            pools[_Id].Chain,
            pools[_Id].FinishTime,
            pools[_Id].iconURL
        );
    }

    function GetPoolMoreData(uint256 _Id)
        public
        view
        PoolId(_Id)
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            pools[_Id].HardCapInWei,
            pools[_Id].StartTime,
            pools[_Id].TotalCollectedToken,
            pools[_Id].TotalPoolInvestors
        );
    }

    //calculate the status of a pool
    function GetPoolStatus(uint256 _id)
        public
        view
        PoolId(_id)
        returns (PoolStatus)
    {
        //Don't like the logic here - ToDo Boolean checks (truth table)
        if (now < pools[_id].StartTime) return PoolStatus.PreMade;

        if (
            now > pools[_id].StartTime && now < pools[_id].FinishTime
        ) {
            //got tokens + all investors
            return (PoolStatus.Open);
        }
        if (
            now > pools[_id].FinishTime
        ) //no tokens on direct pool
        {
            return (PoolStatus.Close);
        }
 
    }
}

// File: contracts/Invest.sol

contract Invest is PoolsData {
    event NewInvestorEvent(uint256 Investor_ID, address Investor_Address);
    GainPoolStaking public stakingContract;

    uint256 public gainStakerInvestTime = 7200;
    IERC20 public BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);        // mainnet
    // IERC20 public BUSD = IERC20(0x21783C0Ce32e1859F6bccC6e575Ae6019765e443);        // testnet 

    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);       // mainnet
    // AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);       // testnet

    modifier CheckTime(uint256 _Time) {
        require(now >= _Time, "Pool not open yet");
        _;
    }

    //using SafeMath for uint256;
    constructor() public {
        //TotalInvestors = 0;
    }

    //Investorsr Data
    uint256 internal TotalInvestors;
    mapping(uint256 => mapping(address => uint256)) public InvestorAmount;
    mapping(address => uint256[]) InvestorsMap;

    uint256 private minStaked1 = 1000000000000000000000;
    uint256 private minStaked2 = 3000000000000000000000;
    uint256 private minStaked3 = 9000000000000000000000;
    uint256 private minStaked4 = 27000000000000000000000;
    uint256 private minStaked5 = 81000000000000000000000;

    uint256 private maxInvestUser1 = 1000000000000000000;
    uint256 private maxInvestUser2 = 2000000000000000000;
    uint256 private maxInvestUser3 = 3000000000000000000;
    uint256 private maxInvestUser4 = 4000000000000000000;
    uint256 private maxInvestUser5 = 5000000000000000000;


    function SetGainStakerTime(uint256 _gainStakerInvestTime)
        public
        onlyOwner
    {
        gainStakerInvestTime = _gainStakerInvestTime;
    }
    
    function setStakingContract(address _stakingContract) external onlyOwner returns (bool) {
        stakingContract = GainPoolStaking(_stakingContract);
        return true;
    }

    function setBUSDToken(address _BUSDToken) external onlyOwner returns (bool) {
        BUSD = IERC20(_BUSDToken);
        return true;
    }

    function setAggregatorContract(address _aggregatorContract) external onlyOwner returns (bool) {
        priceFeed = AggregatorV3Interface(_aggregatorContract);
        return true;
    }

    function setMinStakeAmount(uint256 _minStaked1, uint256 _minStaked2, uint256 _minStaked3, uint256 _minStaked4, uint256 _minStaked5) external onlyOwner {
        minStaked1 = _minStaked1;
        minStaked2 = _minStaked2;
        minStaked3 = _minStaked3;
        minStaked4 = _minStaked4;
        minStaked5 = _minStaked5;
    }

    function setMaxInvest(uint256 _maxInvestUser1, uint256 _maxInvestUser2, uint256 _maxInvestUser3, uint256 _maxInvestUser4, uint256 _maxInvestUser5) external onlyOwner {
        maxInvestUser1 = _maxInvestUser1;
        maxInvestUser2 = _maxInvestUser2;
        maxInvestUser3 = _maxInvestUser3;
        maxInvestUser4 = _maxInvestUser4;
        maxInvestUser5 = _maxInvestUser5;
    }
    
    function getMinStakeAmount() public view returns(uint256, uint256, uint256, uint256, uint256) {
       return (minStaked1, minStaked2, minStaked3, minStaked4, minStaked5);
    }

    function getMaxInvest() public view returns(uint256, uint256, uint256, uint256, uint256) {
       return (maxInvestUser1, maxInvestUser2, maxInvestUser3, maxInvestUser4, maxInvestUser5);
    }

    function getMaxInvestmentUserETH(address account) public view returns(uint256) {
        (uint256 m1, uint256 m2, uint256 m3, uint256 m4, uint256 m5) = getMinStakeAmount();
        (uint256 i1, uint256 i2, uint256 i3, uint256 i4, uint256 i5) = getMaxInvest();
        
        (, , uint256 amount, , , , ) =  stakingContract.userInfo(account);

        if(amount >= m5)
            return i5;
        else if(amount >= m4)
            return i4;
        else if(amount >= m3)
            return i3;
        else if(amount >= m2)
            return i2;
        else if(amount >= m1)
            return i1;
    }

    function getMaxInvestmentUserERC(address account) public view returns(uint256) {
        (uint256 m1, uint256 m2, uint256 m3, uint256 m4, uint256 m5) = getMinStakeAmount();
        (uint256 i1, uint256 i2, uint256 i3, uint256 i4, uint256 i5) = getMaxInvest();
        
        (, , uint256 amount, , , , ) =  stakingContract.userInfo(account);

        if(amount >= m5)
            return SafeMath.mul(i5, uint(getLatestPrice()));
        else if(amount >= m4)
            return SafeMath.mul(i4, uint(getLatestPrice()));
        else if(amount >= m3)
            return SafeMath.mul(i3, uint(getLatestPrice()));
        else if(amount >= m2)
            return SafeMath.mul(i2, uint(getLatestPrice()));
        else if(amount >= m1)
            return SafeMath.mul(i1, uint(getLatestPrice()));
    }

    function getTotalInvestor() external view returns(uint256){
        return TotalInvestors;
    }

    function getLatestPrice() public view returns (int) {
        (
            , // uint80 roundID
            int price, 
            , // uint startedAt
            , // uint timeStamp
              // uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price / 10**8;
    }

    //@dev Send in wei
    function InvestETH(uint256 _PoolId)
        external
        payable
        ReceivETH(msg.value, msg.sender, MinETHInvest)
        whenNotPaused
        CheckTime(pools[_PoolId].StartTime)
    {
        (, , uint256 amount, , , , ) =  stakingContract.userInfo(msg.sender);

        uint256 maxInvest = getMaxInvestmentUserETH(msg.sender);

        require(_PoolId < poolsCount, "Wrong pool id, InvestETH fail");
        if(block.timestamp < SafeMath.add(pools[_PoolId].StartTime, gainStakerInvestTime))
        {
            require(amount > 0, "Not Staked enough tokens");
            require(
                msg.value >= MinETHInvest && msg.value <= maxInvest,
                "Investment amount not valid"
            );
        }
        if(block.timestamp >= SafeMath.add(pools[_PoolId].StartTime, gainStakerInvestTime))
        {
            require(whitelistedAddresses[msg.sender], "Address not whitelisted");
            require(
                msg.value >= MinETHInvest && msg.value <= MaxETHInvest,
                "Investment amount not valid"
            );
        }

        require(
            msg.sender == tx.origin && !isContract(msg.sender),
            "Some thing wrong with the msgSender"
        );
        require(pools[_PoolId].TotalCollectedToken < pools[_PoolId].HardCapInWei, "Hard cap reached");
        
        uint256 finalAmount = SafeMath.mul(msg.value, uint256(getLatestPrice()));
        require(SafeMath.add(pools[_PoolId].TotalCollectedToken, finalAmount) <= pools[_PoolId].HardCapInWei, "Investment not valid, Hard cap reached");
        
        if(InvestorAmount[_PoolId][msg.sender] == 0){
            pools[_PoolId].TotalPoolInvestors = SafeMath.add(pools[_PoolId].TotalPoolInvestors, 1);
            PoolInvestors[_PoolId].push(msg.sender);
        }
            
        InvestorAmount[_PoolId][msg.sender] = SafeMath.add(InvestorAmount[_PoolId][msg.sender], finalAmount);

        InvestorsMap[msg.sender].push(TotalInvestors);
        TotalInvestors = SafeMath.add(TotalInvestors, 1);
        emit NewInvestorEvent(TotalInvestors, msg.sender);

        pools[_PoolId].TotalCollectedToken = SafeMath.add(pools[_PoolId].TotalCollectedToken, finalAmount);
    
    }

    function InvestERC20(uint256 _PoolId, uint256 _Amount)
        external
        whenNotPaused
        CheckTime(pools[_PoolId].StartTime)
    {
        (, , uint256 amount, , , , ) =  stakingContract.userInfo(msg.sender);

        uint256 maxInvest = getMaxInvestmentUserERC(msg.sender);

        require(_PoolId < poolsCount, "Wrong pool id, InvestERC20 fail");
        if(block.timestamp < SafeMath.add(pools[_PoolId].StartTime, gainStakerInvestTime))
        {
            require(amount > 0, "Not Staked enough tokens");
            require(
                _Amount >= MinERCInvest && _Amount <= maxInvest,
                "Investment amount not valid"
            );
        }
        if(block.timestamp >= SafeMath.add(pools[_PoolId].StartTime, gainStakerInvestTime))
        {
            require(whitelistedAddresses[msg.sender], "Address not whitelisted");
            require(
                _Amount >= MinERCInvest && _Amount <= MaxERCInvest,
                "Investment amount not valid"
            );
        }
        require(
            msg.sender == tx.origin && !isContract(msg.sender),
            "Some thing wrong with the msgSender"
        );
        require(pools[_PoolId].TotalCollectedToken < pools[_PoolId].HardCapInWei, "Hard cap reached");
        require(SafeMath.add(pools[_PoolId].TotalCollectedToken, _Amount) <= pools[_PoolId].HardCapInWei, "Investment not valid, Hard cap reached");
        
        
        if(InvestorAmount[_PoolId][msg.sender] == 0){
            pools[_PoolId].TotalPoolInvestors = SafeMath.add(pools[_PoolId].TotalPoolInvestors, 1);
            PoolInvestors[_PoolId].push(msg.sender);
        }

        InvestorAmount[_PoolId][msg.sender] = SafeMath.add(InvestorAmount[_PoolId][msg.sender], _Amount);

        InvestorsMap[msg.sender].push(TotalInvestors);
        TotalInvestors = SafeMath.add(TotalInvestors, 1);
        emit NewInvestorEvent(TotalInvestors, msg.sender);

        IERC20(BUSD).transferFrom(msg.sender, address(this), _Amount);   // send money to smart contract
        pools[_PoolId].TotalCollectedToken = SafeMath.add(pools[_PoolId].TotalCollectedToken, _Amount);
    }

    //@dev use it with  require(msg.sender == tx.origin)
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

// File: contracts/InvestorData.sol

contract InvestorData is Invest {

    //Give all the id's of the investment  by sender address
    function GetMyInvestmentIds() public view returns (uint256[] memory) {
        return InvestorsMap[msg.sender];
    }

}

// File: contracts/ThePoolz.sol

contract ThePoolz is InvestorData {
    constructor() public {    }

    function WithdrawETH(uint256 _PoolId, address _to) public onlyOwner {
        require(block.timestamp >= pools[_PoolId].FinishTime, "Pool has not finished yet");
        payable(_to).transfer(address(this).balance);
    }

    function WithdrawERC20(uint256 _PoolId, address _Token, address _to) public onlyOwner {
        require(block.timestamp >= pools[_PoolId].FinishTime, "Pool has not finished yet");
        uint256 temp = IERC20(_Token).balanceOf(address(this));
        IERC20(_Token).transfer(_to, temp);
    }
}