// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./interfaces/IERC20.sol";
import './interfaces/IRewardToken.sol';
import './libraries/SafeMath.sol';
import './modules/Configable.sol';
import "./modules/ReentrancyGuard.sol";
import './modules/Pausable.sol';
import './modules/Initializable.sol';


// Have fun reading it. Hopefully it's bug-free. God bless.
contract SwitchPool is Pausable, Configable, ReentrancyGuard, Initializable {
    using SafeMath for uint;

    // Info of each user.
    struct UserInfo {
        uint amount;         // How many tokens the user has provided.
        uint rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of RewardTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address depositToken;           // Address of LP token contract.
        uint allocPoint;       // How many allocation points assigned to this pool. RewardTokens to distribute per block.
        uint lastBlock;  // Last block number that RewardTokens distribution occurs.
        uint accRewardPerShare;   // Accumulated RewardTokens per share, times 1e18. See below.
        uint depositTokenSupply;
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint16 tokenType;
        bool paused;
    }

    uint public constant version = 1;

    // The reward TOKEN!
    address public rewardToken;
    
    // Dev address.
    address public team;
    // reward tokens created per block.
    uint public mintPerBlock;
    // Bonus muliplier for early rewardToken makers.
    uint public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint public totalAllocPoint;
    // The block number when reward token mining starts.
    uint public startBlock;

    event Deposit(address indexed user, address indexed to, uint indexed pid, uint amount, uint fee);
    event Withdraw(address indexed user, address indexed to, uint indexed pid, uint amount);
    event EmergencyWithdraw(address indexed user, address indexed to, uint indexed pid, uint amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint mintPerBlock);

    function initialize(
        address _rewardToken,
        address _team,
        address _feeAddress,
        uint _mintPerBlock,
        uint _startBlock
    ) external initializer {
        owner = msg.sender;
        rewardToken = _rewardToken;
        team = _team;
        feeAddress = _feeAddress;
        mintPerBlock = _mintPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    mapping(address => bool) public poolExistence;
    
    modifier nonDuplicated(address _depositToken) {
        require(poolExistence[_depositToken] == false, "nonDuplicated: duplicated");
        _;
    }

    modifier validatePoolByPid(uint _pid) {
        require (_pid < poolInfo.length , "Pool does not exist");
        _;
    }

    function pause() public onlyManager whenNotPaused {
        _pause();
    }

    function unpause() public onlyManager whenPaused {
        _unpause();
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(bool _withUpdate, uint _allocPoint, address _depositToken, uint16 _depositFeeBP, uint16 _tokenType) public onlyDev nonDuplicated(_depositToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }

        uint lastBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_depositToken] = true;
        poolInfo.push(PoolInfo({
            depositToken : _depositToken,
            allocPoint : _allocPoint,
            lastBlock : lastBlock,
            accRewardPerShare : 0,
            depositTokenSupply: 0,
            depositFeeBP : _depositFeeBP,
            tokenType: _tokenType,
            paused: false
        }));
    }

    function batchAdd(bool _withUpdate, uint[] memory _allocPoints, address[] memory _depositTokens, uint16[] memory _depositFeeBPs, uint16[] memory _tokenTypes) external onlyDev {
        require(_allocPoints.length == _depositTokens.length && _depositTokens.length == _depositFeeBPs.length, 'invalid params');
        if (_withUpdate) {
            massUpdatePools();
        }
        for(uint i; i<_allocPoints.length; i++) {
            add(false, _allocPoints[i], _depositTokens[i], _depositFeeBPs[i], _tokenTypes[i]);
        }
    }

    function set(bool _withUpdate, uint _pid, uint _allocPoint, uint16 _depositFeeBP, uint16 _tokenType, bool _paused) external validatePoolByPid(_pid) onlyManager {
        require(_depositFeeBP <= 10000, "depositFeeBP should be <=10000!");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].tokenType = _tokenType;
        poolInfo[_pid].paused = _paused;  
    }

    function batchSetAllocPoint(uint[] memory _pids, uint[] memory _allocPoints) external onlyManager {
        require(_pids.length == _allocPoints.length, 'invalid params');
        massUpdatePools();
        for (uint i; i<_pids.length; i++) {
            totalAllocPoint = totalAllocPoint.sub(poolInfo[_pids[i]].allocPoint).add(_allocPoints[i]);
            poolInfo[_pids[i]].allocPoint = _allocPoints[i];
        }
    }

    function batchSetDepositFeeBP(uint[] memory _pids, uint16[] memory _depositFeeBPs) external onlyManager {
        require(_pids.length == _depositFeeBPs.length, 'invalid params');
        for (uint i; i<_pids.length; i++) {
            require(_depositFeeBPs[i] <= 10000, 'depositFeeBP should be <=10000!');
            poolInfo[_pids[i]].depositFeeBP = _depositFeeBPs[i];
        }
    }

    function batchSetPaused(uint[] memory _pids, bool[] memory _pauseds) external onlyManager {
        require(_pids.length == _pauseds.length, 'invalid params');
        for (uint i; i<_pids.length; i++) {
            poolInfo[_pids[i]].paused = _pauseds[i];
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint _from, uint _to) public view returns (uint) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function getToBlock() public view returns (uint) {
        return block.number;
    }

    function pendingRewardInfo(uint _pid) public view validatePoolByPid(_pid) returns (uint, uint) {
        PoolInfo storage pool = poolInfo[_pid];
        if (rewardToken != address(0) && getToBlock() > pool.lastBlock && totalAllocPoint > 0) {
            uint multiplier = getMultiplier(pool.lastBlock, getToBlock());
            uint reward = multiplier.mul(mintPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            return (reward, block.number);
        }
        return (0, block.number);
    }

    // View function to see pending RewardTokens on frontend.
    function pendingReward(uint _pid, address _user) external view validatePoolByPid(_pid) returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint accRewardPerShare = pool.accRewardPerShare;
        if (block.number > pool.lastBlock && pool.depositTokenSupply != 0) {
            uint multiplier = getMultiplier(pool.lastBlock, block.number);
            uint reward = multiplier.mul(mintPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e18).div(pool.depositTokenSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e18).sub(user.rewardDebt);
    }
    
    function _mintRewardToken(uint _pid) internal view returns (uint, uint) {
        if(rewardToken == address(0)) {
            return (0, block.number);
        }
        (uint reward,) = pendingRewardInfo(_pid);
        return (reward, block.number);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint toBlock = getToBlock();
        if (toBlock <= pool.lastBlock) {
            return;
        }
        if (pool.depositTokenSupply == 0 || pool.allocPoint == 0) {
            pool.lastBlock = toBlock;
            return;
        }
        
        (uint reward,) = _mintRewardToken(_pid);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e18).div(pool.depositTokenSupply));

        pool.lastBlock = toBlock;
    }

    // Deposit tokens to SwitchFarm for reward allocation.
    function deposit(uint _pid, uint _amount, address _to) external validatePoolByPid(_pid) whenNotPaused nonReentrant returns(uint, uint) {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.paused == false, "pool is paused");
        UserInfo storage user = userInfo[_pid][_to];
        updatePool(_pid);
        uint depositFee;

        if (_amount > 0) {
            IERC20(pool.depositToken).transferFrom(address(msg.sender), address(this), _amount);
            
            if (pool.depositFeeBP > 0) {
                depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                safeTransfer(pool.depositToken, feeAddress, depositFee);
                _amount = _amount.sub(depositFee);
                user.amount = user.amount.add(_amount);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        pool.depositTokenSupply  = pool.depositTokenSupply.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Deposit(msg.sender, _to, _pid, _amount, depositFee);
        return (_amount, depositFee);
    }

    // Withdraw tokens from SwitchFarm.
    function withdraw(uint _pid, uint _amount, address _to) external validatePoolByPid(_pid) whenNotPaused nonReentrant returns(uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.paused == false, "pool is paused");
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        _harvestRewardToken(_pid, _to);
       
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.depositTokenSupply = pool.depositTokenSupply.sub(_amount);
            safeTransfer(pool.depositToken, _to, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Withdraw(msg.sender, _to, _pid, _amount);
        return _amount;
    }

    function _harvestRewardToken(uint _pid, address _to) internal returns(uint amount) {
        if(rewardToken == address(0)) {
            return 0;
        }
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        amount = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(user.rewardDebt);
        uint take = IRewardToken(rewardToken).take();
        if(amount > take) {
            amount = take;
        }
        IRewardToken(rewardToken).mint(_to, amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        return amount;
    }

    function harvest(uint _pid, address _to) external validatePoolByPid(_pid) whenNotPaused nonReentrant  returns (uint reward) {
        PoolInfo memory pool = poolInfo[_pid];
        require(pool.paused == false, "pool is paused");
        updatePool(_pid);
        reward = _harvestRewardToken(_pid, _to);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid, address _to) external validatePoolByPid(_pid) nonReentrant returns(uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        require(amount > 0, 'no balance');
        user.amount = 0;
        user.rewardDebt = 0;
        pool.depositTokenSupply = pool.depositTokenSupply.sub(amount);
        safeTransfer(pool.depositToken, _to, amount);
        emit EmergencyWithdraw(msg.sender, _to, _pid, amount);
        return amount;
    }

    // Safe Token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeTokenTransfer(address _token, address _to, uint _amount) internal returns(uint) {
        uint tokenBal = IERC20(_token).balanceOf(address(this));
        if(_amount >0) {
            if(tokenBal == 0) {
                return 0;
            }
            if (_amount > tokenBal) {
                _amount = tokenBal;
            }
            safeTransfer(_token, _to, _amount);
        }
        return _amount;
    }

    function safeTransfer(address _token, address _to, uint _amount) internal returns(uint) {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'safeTransfer: TRANSFER_FAILED');
        return _amount;
    }

    function setTeamAddress(address _team) external onlyDev {
        require(_team != address(0), 'zero address');
        team = _team;
        emit SetDevAddress(msg.sender, _team);
    }

    function setFeeAddress(address _feeAddress) external onlyDev {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //reward has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint _mintPerBlock) external onlyDev {
        massUpdatePools();
        mintPerBlock = _mintPerBlock;
        emit UpdateEmissionRate(msg.sender, _mintPerBlock);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IRewardToken {
    function balanceOf(address owner) external view returns (uint);
    function take() external view returns (uint);
    function funds(address user) external view returns (uint);
    function mint(address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IConfig {
    function dev() external view returns (address);
    function admin() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event ConfigChanged(address indexed _user, address indexed _old, address indexed _new);
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
 
    function setupConfig(address _config) external onlyOwner {
        emit ConfigChanged(msg.sender, config, _config);
        config = _config;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }

    function admin() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).admin();
        }
        return owner;
    }

    function dev() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).dev();
        }
        return owner;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Owner: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev() || msg.sender == owner, 'dev FORBIDDEN');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin(), 'admin FORBIDDEN');
        _;
    }
  
    modifier onlyManager() {
        require(msg.sender == dev() || msg.sender == admin() || msg.sender == owner, 'manager FORBIDDEN');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused();

    bool private _paused;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() virtual {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
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
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "metadata": {
    "bytecodeHash": "none"
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}