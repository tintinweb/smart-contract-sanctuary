/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File contracts/interfaces/IArmorMaster.sol

pragma solidity ^0.6.0;

interface IArmorMaster {
    function registerModule(bytes32 _key, address _module) external;
    function getModule(bytes32 _key) external view returns(address);
    function keep() external;
}


// File contracts/general/Ownable.sol

pragma solidity ^0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev Completely default OpenZeppelin.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private __gap;
}


// File contracts/general/Bytes32.sol

pragma solidity ^0.6.6;
library Bytes32 {
    function toString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}


// File contracts/general/ArmorModule.sol

pragma solidity ^0.6.0;

/**
 * @dev Each arCore contract is a module to enable simple communication and interoperability. ArmorMaster.sol is master.
**/
contract ArmorModule {
    IArmorMaster internal _master;

    using Bytes32 for bytes32;

    modifier onlyOwner() {
        require(msg.sender == Ownable(address(_master)).owner(), "only owner can call this function");
        _;
    }

    modifier doKeep() {
        _master.keep();
        _;
    }

    modifier onlyModule(bytes32 _module) {
        string memory message = string(abi.encodePacked("only module ", _module.toString()," can call this function"));
        require(msg.sender == getModule(_module), message);
        _;
    }

    /**
     * @dev Used when multiple can call.
    **/
    modifier onlyModules(bytes32 _moduleOne, bytes32 _moduleTwo) {
        string memory message = string(abi.encodePacked("only module ", _moduleOne.toString()," or ", _moduleTwo.toString()," can call this function"));
        require(msg.sender == getModule(_moduleOne) || msg.sender == getModule(_moduleTwo), message);
        _;
    }

    function initializeModule(address _armorMaster) internal {
        require(address(_master) == address(0), "already initialized");
        require(_armorMaster != address(0), "master cannot be zero address");
        _master = IArmorMaster(_armorMaster);
    }

    function changeMaster(address _newMaster) external onlyOwner {
        _master = IArmorMaster(_newMaster);
    }

    function getModule(bytes32 _key) internal view returns(address) {
        return _master.getModule(_key);
    }
}


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.6.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * 
 * @dev Default OpenZeppelin
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
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
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


// File contracts/general/BalanceWrapper.sol

pragma solidity ^0.6.6;

contract BalanceWrapper {
    using SafeMath for uint256;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _addStake(address user, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
    }

    function _removeStake(address user, uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);
    }
}


// File contracts/libraries/Math.sol

pragma solidity ^0.6.6;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/interfaces/IPlanManager.sol

pragma solidity ^0.6.6;

interface IPlanManager {
  // Mapping = protocol => cover amount
  struct Plan {
      uint64 startTime;
      uint64 endTime;
      uint128 length;
  }
  
  struct ProtocolPlan {
      uint64 protocolId;
      uint192 amount;
  }
    
  // Event to notify frontend of plan update.
  event PlanUpdate(address indexed user, address[] protocols, uint256[] amounts, uint256 endTime);
  function userCoverageLimit(address _user, address _protocol) external view returns(uint256);
  function markup() external view returns(uint256);
  function nftCoverPrice(address _protocol) external view returns(uint256);
  function initialize(address _armorManager) external;
  function changePrice(address _scAddress, uint256 _pricePerAmount) external;
  function updatePlan(address[] calldata _protocols, uint256[] calldata _coverAmounts) external;
  function checkCoverage(address _user, address _protocol, uint256 _hacktime, uint256 _amount) external view returns (uint256, bool);
  function coverageLeft(address _protocol) external view returns(uint256);
  function getCurrentPlan(address _user) external view returns(uint256 idx, uint128 start, uint128 end);
  function updateExpireTime(address _user, uint256 _expiry) external;
  function planRedeemed(address _user, uint256 _planIndex, address _protocol) external;
  function totalUsedCover(address _scAddress) external view returns (uint256);
}


// File contracts/interfaces/IRewardManagerV2.sol

pragma solidity ^0.6.6;

interface IRewardManagerV2 {
    function initialize(address _armorMaster, uint256 _rewardCycleBlocks)
        external;

    function deposit(
        address _user,
        address _protocol,
        uint256 _amount,
        uint256 _nftId
    ) external;

    function withdraw(
        address _user,
        address _protocol,
        uint256 _amount,
        uint256 _nftId
    ) external;

    function updateAllocPoint(address _protocol, uint256 _allocPoint) external;

    function initPool(address _protocol) external;

    function notifyRewardAmount() external payable;
}


// File contracts/core/RewardManagerV2.sol

// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.6;

/**
 * @dev RewardManagerV2 is a updated RewardManager to distribute rewards.
 *      based on total used cover per protocols.
 **/

contract RewardManagerV2 is BalanceWrapper, ArmorModule, IRewardManagerV2 {
    /**
     * @dev Universal requirements:
     *      - Calculate reward per protocol by totalUsedCover.
     *      - onlyGov functions must only ever be able to be accessed by governance.
     *      - Total of refBals must always equal refTotal.
     *      - depositor should always be address(0) if contract is not locked.
     *      - totalTokens must always equal pToken.balanceOf( address(this) ) - (refTotal + sum(feesToLiq) ).
    **/

    event RewardPaid(address indexed user, address indexed protocol, uint256 reward, uint256 timestamp);
    event BalanceAdded(
        address indexed user,
        address indexed protocol,
        uint256 indexed nftId,
        uint256 amount,
        uint256 totalStaked,
        uint256 timestamp
    );
    event BalanceWithdrawn(
        address indexed user,
        address indexed protocol,
        uint256 indexed nftId,
        uint256 amount,
        uint256 totalStaked,
        uint256 timestamp
    );

    struct UserInfo {
        uint256 amount; // How much cover staked
        uint256 rewardDebt; // Reward debt.
    }
    struct PoolInfo {
        address protocol; // Address of protocol contract.
        uint256 totalStaked; // Total staked amount in the pool
        uint256 allocPoint; // Allocation of protocol - same as totalUsedCover.
        uint256 accEthPerShare; // Accumulated ETHs per share, times 1e12.
        uint256 rewardDebt; // Pool Reward debt.
    }

    // Total alloc point - sum of totalUsedCover for initialized pools
    uint256 public totalAllocPoint;
    // Accumlated ETHs per alloc, times 1e12.
    uint256 public accEthPerAlloc;
    // Last reward updated block
    uint256 public lastRewardBlock;
    // Reward per block - updates when reward notified
    uint256 public rewardPerBlock;
    // Time when all reward will be distributed - updates when reward notified
    uint256 public rewardCycleEnd;
    // Currently used reward in cycle - used to calculate remaining reward at the reward notification
    uint256 public usedReward;

    // reward cycle period
    uint256 public rewardCycle;
    // last reward amount
    uint256 public lastReward;

    // Reward info for each protocol
    mapping(address => PoolInfo) public poolInfo;

    // Reward info for user in each protocol
    mapping(address => mapping(address => UserInfo)) public userInfo;

    /**
     * @notice Controller immediately initializes contract with this.
     * @dev - Must set all included variables properly.
     *      - Update last reward block as initialized block.
     * @param _armorMaster Address of ArmorMaster.
     * @param _rewardCycleBlocks Block amounts in one cycle.
    **/
    function initialize(address _armorMaster, uint256 _rewardCycleBlocks)
        external
        override
    {
        initializeModule(_armorMaster);
        require(_rewardCycleBlocks > 0, "Invalid cycle blocks");
        rewardCycle = _rewardCycleBlocks;
        lastRewardBlock = block.number;
    }

    /**
     * @notice Only BalanceManager can call this function to notify reward.
     * @dev - Reward must be greater than 0.
     *      - Must update reward info before notify.
     *      - Must contain remaining reward of previous cycle
     *      - Update reward cycle info
    **/
    function notifyRewardAmount()
        external
        payable
        override
        onlyModule("BALANCE")
    {
        require(msg.value > 0, "Invalid reward");
        updateReward();
        uint256 remainingReward = lastReward > usedReward
            ? lastReward.sub(usedReward)
            : 0;
        lastReward = msg.value.add(remainingReward);
        usedReward = 0;
        rewardCycleEnd = block.number.add(rewardCycle);
        rewardPerBlock = lastReward.div(rewardCycle);
    }

    /**
     * @notice Update RewardManagerV2 reward information.
     * @dev - Skip if already updated.
     *      - Skip if totalAllocPoint is zero or reward not notified yet.
    **/
    function updateReward() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (rewardCycleEnd == 0 || totalAllocPoint == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 reward = Math
            .min(rewardCycleEnd, block.number)
            .sub(lastRewardBlock)
            .mul(rewardPerBlock);
        usedReward = usedReward.add(reward);
        accEthPerAlloc = accEthPerAlloc.add(
            reward.mul(1e12).div(totalAllocPoint)
        );
        lastRewardBlock = block.number;
    }

    /**
     * @notice Only Plan and Stake manager can call this function.
     * @dev - Must update reward info before initialize pool.
     *      - Cannot initlize again.
     *      - Must update pool rewardDebt and totalAllocPoint.
     * @param _protocol Protocol address.
    **/
    function initPool(address _protocol)
        public
        override
        onlyModules("PLAN", "STAKE")
    {
        require(_protocol != address(0), "zero address!");
        PoolInfo storage pool = poolInfo[_protocol];
        require(pool.protocol == address(0), "already initialized");
        updateReward();
        pool.protocol = _protocol;
        pool.allocPoint = IPlanManager(_master.getModule("PLAN"))
            .totalUsedCover(_protocol);
        totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        pool.rewardDebt = pool.allocPoint.mul(accEthPerAlloc).div(1e12);
    }

    /**
     * @notice Update alloc point when totalUsedCover updates.
     * @dev - Only Plan Manager can call this function.
     *      - Init pool if not initialized.
     * @param _protocol Protocol address.
     * @param _allocPoint New allocPoint.
    **/
    function updateAllocPoint(address _protocol, uint256 _allocPoint)
        external
        override
        onlyModule("PLAN")
    {
        PoolInfo storage pool = poolInfo[_protocol];
        if (poolInfo[_protocol].protocol == address(0)) {
            initPool(_protocol);
        } else {
            updatePool(_protocol);
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
            pool.allocPoint = _allocPoint;
            pool.rewardDebt = pool.allocPoint.mul(accEthPerAlloc).div(1e12);
        }
    }

    /**
     * @notice StakeManager call this function to deposit for user.
     * @dev - Must update pool info
     *      - Must give pending reward to user.
     *      - Emit `BalanceAdded` event.
     * @param _user User address.
     * @param _protocol Protocol address.
     * @param _amount Stake amount.
     * @param _nftId NftId.
    **/
    function deposit(
        address _user,
        address _protocol,
        uint256 _amount,
        uint256 _nftId
    ) external override onlyModule("STAKE") {
        PoolInfo storage pool = poolInfo[_protocol];
        UserInfo storage user = userInfo[_protocol][_user];
        if (pool.protocol == address(0)) {
            initPool(_protocol);
        } else {
            updatePool(_protocol);
            if (user.amount > 0) {
                uint256 pending = user
                    .amount
                    .mul(pool.accEthPerShare)
                    .div(1e12)
                    .sub(user.rewardDebt);
                safeRewardTransfer(_user, _protocol, pending);
            }
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accEthPerShare).div(1e12);
        pool.totalStaked = pool.totalStaked.add(_amount);

        emit BalanceAdded(
            _user,
            _protocol,
            _nftId,
            _amount,
            pool.totalStaked,
            block.timestamp
        );
    }

    /**
     * @notice StakeManager call this function to withdraw for user.
     * @dev - Must update pool info
     *      - Must give pending reward to user.
     *      - Emit `BalanceWithdrawn` event.
     * @param _user User address.
     * @param _protocol Protocol address.
     * @param _amount Withdraw amount.
     * @param _nftId NftId.
    **/
    function withdraw(
        address _user,
        address _protocol,
        uint256 _amount,
        uint256 _nftId
    ) public override onlyModule("STAKE") {
        PoolInfo storage pool = poolInfo[_protocol];
        UserInfo storage user = userInfo[_protocol][_user];
        require(user.amount >= _amount, "insufficient to withdraw");
        updatePool(_protocol);
        uint256 pending = user.amount.mul(pool.accEthPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeRewardTransfer(_user, _protocol, pending);
        }
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accEthPerShare).div(1e12);
        pool.totalStaked = pool.totalStaked.sub(_amount);

        emit BalanceWithdrawn(
            _user,
            _protocol,
            _nftId,
            _amount,
            pool.totalStaked,
            block.timestamp
        );
    }

    /**
     * @notice Claim pending reward.
     * @dev - Must update pool info
     *      - Emit `RewardPaid` event.
     * @param _protocol Protocol address.
    **/
    function claimReward(address _protocol) public {
        PoolInfo storage pool = poolInfo[_protocol];
        UserInfo storage user = userInfo[_protocol][msg.sender];

        updatePool(_protocol);
        uint256 pending = user.amount.mul(pool.accEthPerShare).div(1e12).sub(
            user.rewardDebt
        );
        user.rewardDebt = user.amount.mul(pool.accEthPerShare).div(1e12);
        if (pending > 0) {
            safeRewardTransfer(msg.sender, _protocol, pending);
        }
    }

    /**
     * @notice Claim pending reward of several protocols.
     * @dev - Must update pool info of each protocol
     *      - Emit `RewardPaid` event per protocol.
     * @param _protocols Array of protocol addresses.
    **/
    function claimRewardInBatch(address[] calldata _protocols) external {
        for (uint256 i = 0; i < _protocols.length; i += 1) {
            claimReward(_protocols[i]);
        }
    }

    /**
     * @notice Update pool info.
     * @dev - Skip if already updated.
     *      - Skip if totalStaked is zero.
     * @param _protocol Protocol address.
    **/
    function updatePool(address _protocol) public {
        PoolInfo storage pool = poolInfo[_protocol];
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (pool.totalStaked == 0) {
            return;
        }

        updateReward();
        uint256 poolReward = pool.allocPoint.mul(accEthPerAlloc).div(1e12).sub(
            pool.rewardDebt
        );
        pool.accEthPerShare = pool.accEthPerShare.add(
            poolReward.mul(1e12).div(pool.totalStaked)
        );
        pool.rewardDebt = pool.allocPoint.mul(accEthPerAlloc).div(1e12);
    }

    /**
     * @notice Check contract balance to avoid tx failure.
    **/
    function safeRewardTransfer(address _to, address _protocol, uint256 _amount) internal {
        uint256 reward = Math.min(address(this).balance, _amount);
        payable(_to).transfer(reward);

        emit RewardPaid(_to, _protocol, reward, block.timestamp);
    }

    /**
     * @notice Get pending reward amount.
     * @param _user User address.
     * @param _protocol Protocol address.
     * @return pending reward amount
    **/
    function getPendingReward(address _user, address _protocol)
        public
        view
        returns (uint256)
    {
        if (rewardCycleEnd == 0 || totalAllocPoint == 0) {
            return 0;
        }

        uint256 reward = Math
            .min(rewardCycleEnd, block.number)
            .sub(lastRewardBlock)
            .mul(rewardPerBlock);
        uint256 _accEthPerAlloc = accEthPerAlloc.add(
            reward.mul(1e12).div(totalAllocPoint)
        );

        PoolInfo memory pool = poolInfo[_protocol];
        if (pool.protocol == address(0) || pool.totalStaked == 0) {
            return 0;
        }
        uint256 poolReward = pool.allocPoint.mul(_accEthPerAlloc).div(1e12).sub(
            pool.rewardDebt
        );
        uint256 _accEthPerShare = pool.accEthPerShare.add(
            poolReward.mul(1e12).div(pool.totalStaked)
        );
        UserInfo memory user = userInfo[_protocol][_user];
        return user.amount.mul(_accEthPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @notice Get pending total reward amount for several protocols.
     * @param _user User address.
     * @param _protocols Array of protocol addresses.
     * @return pending reward amount
    **/
    function getTotalPendingReward(address _user, address[] memory _protocols)
        external
        view
        returns (uint256)
    {
        uint256 reward;
        for (uint256 i = 0; i < _protocols.length; i += 1) {
            reward = reward.add(getPendingReward(_user, _protocols[i]));
        }
        return reward;
    }
}