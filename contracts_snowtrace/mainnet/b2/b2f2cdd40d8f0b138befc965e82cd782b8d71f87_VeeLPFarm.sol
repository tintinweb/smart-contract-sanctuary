/**
 *Submitted for verification at snowtrace.io on 2022-01-20
*/

pragma solidity ^0.8.0;


abstract contract Initializable {
    
    bool private _initialized;

    
    bool private _initializing;

    
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}





            


pragma solidity ^0.8.0;



abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}





            


pragma solidity ^0.8.0;


library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
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
        return functionCallWithValue(target, data, 0, errorMessage);
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
}





            


pragma solidity ^0.8.0;


interface IERC20 {
    
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





            

pragma solidity ^0.8.0;

interface IMiniChefV2 {
    event Deposit( address indexed user,uint256 indexed pid,uint256 amount,address indexed to ) ;
    event EmergencyWithdraw( address indexed user,uint256 indexed pid,uint256 amount,address indexed to ) ;
    event FunderAdded( address funder ) ;
    event FunderRemoved( address funder ) ;
    event Harvest( address indexed user,uint256 indexed pid,uint256 amount ) ;
    event LogRewardPerSecond( uint256 rewardPerSecond ) ;
    event LogRewardsExpiration( uint256 rewardsExpiration ) ;
    event Migrate( uint256 pid ) ;
    event MigratorDisabled(  ) ;
    event MigratorSet( address migrator ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event PoolAdded( uint256 indexed pid,uint256 allocPoint,address indexed lpToken,address indexed rewarder ) ;
    event PoolSet( uint256 indexed pid,uint256 allocPoint,address indexed rewarder,bool overwrite ) ;
    event PoolUpdate( uint256 indexed pid,uint64 lastRewardTime,uint256 lpSupply,uint256 accRewardPerShare ) ;
    event Withdraw( address indexed user,uint256 indexed pid,uint256 amount,address indexed to ) ;
    function REWARD(  ) external view returns (address ) ;
    function addFunder( address _funder ) external   ;
    function addPool( uint256 _allocPoint,address _lpToken,address _rewarder ) external   ;
    function addPools( uint256[] memory _allocPoints,address[] memory _lpTokens,address[] memory _rewarders ) external   ;
    function addedTokens( address  ) external view returns (bool ) ;
    function deposit( uint256 pid,uint256 amount,address to ) external   ;
    function depositWithPermit( uint256 pid,uint256 amount,address to,uint256 deadline,uint8 v,bytes32 r,bytes32 s ) external   ;
    function disableMigrator(  ) external   ;
    function emergencyWithdraw( uint256 pid,address to ) external   ;
    function extendRewardsViaDuration( uint256 extension,uint256 maxFunding ) external   ;
    function extendRewardsViaFunding( uint256 funding,uint256 minExtension ) external   ;
    function fundRewards( uint256 funding,uint256 duration ) external   ;
    function harvest( uint256 pid,address to ) external   ;
    function isFunder( address _funder ) external view returns (bool allowed) ;
    function lpToken( uint256  ) external view returns (address ) ;
    function lpTokens(  ) external view returns (address[] memory ) ;
    function massUpdateAllPools(  ) external   ;
    function massUpdatePools( uint256[] memory pids ) external   ;
    function migrate( uint256 _pid ) external   ;
    function migrationDisabled(  ) external view returns (bool ) ;
    function migrator(  ) external view returns (address ) ;
    function owner(  ) external view returns (address ) ;
    function pendingReward( uint256 _pid,address _user ) external view returns (uint256 pending) ;
    function poolInfo( uint256  ) external view returns (uint128 accRewardPerShare, uint64 lastRewardTime, uint64 allocPoint) ;
    function poolLength(  ) external view returns (uint256 pools) ;
    function removeFunder( address _funder ) external   ;
    function renounceOwnership(  ) external   ;
    function resetRewardsDuration( uint256 duration ) external   ;
    function rewardPerSecond(  ) external view returns (uint256 ) ;
    function rewarder( uint256  ) external view returns (address ) ;
    function rewardsExpiration(  ) external view returns (uint256 ) ;
    function setMigrator( address _migrator ) external   ;
    function setPool( uint256 _pid,uint256 _allocPoint,address _rewarder,bool overwrite ) external   ;
    function setPools( uint256[] memory pids,uint256[] memory allocPoints,address[] memory rewarders,bool[] memory overwrites ) external   ;
    function totalAllocPoint(  ) external view returns (uint256 ) ;
    function transferOwnership( address newOwner ) external   ;
    function userInfo( uint256 ,address  ) external view returns (uint256 amount, int256 rewardDebt) ;
    function withdraw( uint256 pid,uint256 amount,address to ) external   ;
    function withdrawAndHarvest( uint256 pid,uint256 amount,address to ) external   ;
}




            
pragma solidity >= 0.8.0;

interface IVeeHub {
    event Deposit( address indexed payer,address indexed user,uint256 amount ) ;
    event DepositLPToken( address indexed payer,address indexed user,address indexed lpToken,uint256 amount ) ;
    event EnterUnlocking( address account,uint256 amount,uint256 remainBalance ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event SwapLPForTokens( address LPToken,uint256 liquidity,address tokenA,address tokenB,uint256 amountA,uint256 amountB ) ;
    event SwapTokensForLP( address tokenA,address tokenB,uint256 amountA,uint256 amountB,address LPToken,uint256 liquidity ) ;
    event TokenWhitelistChange( address token,bool isWhite,bool oldStatus ) ;
    function addLiquidity( address tokenB,uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin ) external  returns (uint256 amountA, uint256 amountB, uint256 liquidity) ;
    function addLiquidityAVAX( uint256 amountADesired,uint256 amountAMin,uint256 amountAVAXMin ) external payable returns (uint256 amountA, uint256 amountAVAX, uint256 liquidity) ;
    function addLiquidityAVAXFarm( uint256 amountADesired,uint256 amountAMin,uint256 amountAVAXMin,uint256 pid ) external payable  ;
    function addLiquidityFarm( address tokenB,uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin,uint256 pid ) external   ;
    function deposit( address account,uint256 amount ) external   ;
    function depositLPToken( address account,address lpToken,uint256 amount ) external   ;
    function dexRouter(  ) external view returns (address ) ;
    function enterFarm( uint256 pid,uint256 amount ) external   ;
    function enterUnlocking( uint256 amount ) external   ;
    function farmPool(  ) external view returns (address ) ;
    function initialize( address _vee,address _dexRouter,address _farmPool,address _vestingPool,address[] memory _tokenWhitelist ) external   ;
    function lockingRate(  ) external view returns (uint256 ) ;
    function lpBalances( address ,address  ) external view returns (uint256 ) ;
    function owner(  ) external view returns (address ) ;
    function removeLiquidity( address tokenB,uint256 liquidity,uint256 amountAMin,uint256 amountBMin ) external  returns (uint256 amountA, uint256 amountB) ;
    function removeLiquidityAVAX( uint256 liquidity,uint256 amountAMin,uint256 amountAVAXMin ) external  returns (uint256 amountA, uint256 amountAVAX) ;
    function renounceOwnership(  ) external   ;
    function setTokenWhitelist( address token,bool isWhite ) external   ;
    function tokenWhitelist( address  ) external view returns (bool ) ;
    function transferOwnership( address newOwner ) external   ;
    function vee(  ) external view returns (address ) ;
    function veeBalances( address  ) external view returns (uint256 ) ;
    function vestingPool(  ) external view returns (address ) ;
}




            
pragma solidity >=0.8.0;
interface IVeeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}




            
pragma solidity >=0.8.0;
interface IPangolinERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}




            


pragma solidity ^0.8.0;





abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}





            


pragma solidity ^0.8.0;


library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a & b) + (a ^ b) / 2;
    }

    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return a / b + (a % b == 0 ? 0 : 1);
    }
}





            


pragma solidity ^0.8.0;





library SafeERC20 {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        
        

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}





pragma solidity >=0.8.0;











interface IStakingRewards {
    function balanceOf( address account ) external view returns (uint256 ) ;
    function earned( address account ) external view returns (uint256 ) ;
    function exit(  ) external   ;
    function getReward(  ) external   ;
    function getRewardForDuration(  ) external view returns (uint256 ) ;
    function lastTimeRewardApplicable(  ) external view returns (uint256 ) ;
    function lastUpdateTime(  ) external view returns (uint256 ) ;
    function notifyRewardAmount( uint256 reward ) external   ;
    function owner(  ) external view returns (address ) ;
    function rewardPerToken(  ) external view returns (uint256 ) ;
    function rewardPerTokenStored(  ) external view returns (uint256 ) ;
    function rewardRate(  ) external view returns (uint256 ) ;
    function rewards( address  ) external view returns (uint256 ) ;
    function rewardsDuration(  ) external view returns (uint256 ) ;
    function rewardsToken(  ) external view returns (address ) ;
    function stake( uint256 amount ) external   ;
    function stakingToken(  ) external view returns (address ) ;
    function totalSupply(  ) external view returns (uint256 ) ;
    function transferOwnership( address newOwner ) external   ;
    function userRewardPerTokenPaid( address  ) external view returns (uint256 ) ;
    function withdraw( uint256 amount ) external   ;
}

contract VeeLPFarm is Initializable, OwnableUpgradeable{
    using SafeERC20 for IERC20;
    using Math for uint256;
    bool internal _notEntered;

    
    struct UserInfo {
        uint amount;     
        uint lockingAmount;     
        uint unlockedAmount;     
        uint rewardDebt; 
        bool inBlackList;
    }

    
    struct PoolInfo {
        address lpToken;           
        uint allocPoint;       
        uint lastRewardBlock;  
        uint accRewardsPerShare; 
    }

    address public vee;
    address payable public veeHub;

    
    uint public rewardsPerBlock;
    
    uint public BONUS_MULTIPLIER;

    
    PoolInfo[] public poolInfo;
    
    mapping (uint => mapping (address => UserInfo)) public userInfo;
    
    uint public totalAllocPoint;
    
    uint public startBlock;
    uint public endBlock;
    mapping (address => bool) tokenAddedList;
    mapping (address => uint) public lpTokenTotal;
    mapping (address => uint) public rewardBalances;

    event Deposit(address indexed payer, address indexed user, uint indexed pid, uint amountInternal, uint amountExternal);
    event Withdraw(address indexed user, uint indexed pid, uint amountInternal, uint amountExternal);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount, uint unlockedAmount, uint lockingAmount);
    event ClaimVee(address indexed user,uint256 indexed pid,uint256 veeReward);
    event NewVeeHub(address newVeeHub, address oldVeeHub);
    event NewRewardsPerBlock(uint newRewardsPerBlock, uint oldRewardsPerBlock);

    modifier nonReentrant() {
        require(_notEntered, "re-entered!");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    function initialize(
        address _vee,
        uint _rewardsPerBlock,
        uint _startBlock,
        uint _endBlock
    ) public initializer {
        vee = _vee;
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        totalAllocPoint = 0;
        BONUS_MULTIPLIER = 1;
        _notEntered = true;
        __Ownable_init();
    }

    function updateMultiplier(uint multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    
    function add(uint _allocPoint, address _lpToken, bool _withUpdate) public onlyOwner {
        require(!tokenAddedList[_lpToken], "token exists");
        if (_withUpdate) {
            _updateAllPools();
        }
        uint lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardsPerShare: 0
        }));
        tokenAddedList[_lpToken] = true;
        updateStakingPool();
    }

    
    function set(uint _pid, uint _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            _updateAllPools();
        }
        uint prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint length = poolInfo.length;
        uint points = 0;
        for (uint pid = 0; pid < length; ++pid) {
            points = points + poolInfo[pid].allocPoint;
        }
        totalAllocPoint = points;
    }

    
    function getMultiplier(uint _from, uint _to) internal view returns (uint) {
        
        if (_to <= endBlock) {
            return (_to - _from) * BONUS_MULTIPLIER;
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return (endBlock - _from) * BONUS_MULTIPLIER;
        }
    }

    
    function pendingRewards(uint _pid, address _user) external view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint accRewardsPerShare = pool.accRewardsPerShare;
        uint lpSupply = lpTokenTotal[pool.lpToken];
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint rewardsReward = multiplier * rewardsPerBlock * pool.allocPoint / totalAllocPoint;
            accRewardsPerShare = accRewardsPerShare + rewardsReward * 1e12 / lpSupply;
        }
        return user.amount * accRewardsPerShare / 1e12 - user.rewardDebt;
    }

    function updateAllPools() external {
        _updateAllPools();
    }

    function _updateAllPools() internal {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint lpSupply = lpTokenTotal[pool.lpToken];
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint veeReward = multiplier * rewardsPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accRewardsPerShare = pool.accRewardsPerShare + veeReward * 1e12 / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    
    function deposit(uint _pid, uint _amount) external {

        

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint pending = user.amount * pool.accRewardsPerShare / 1e12 - user.rewardDebt;
            if(pending > 0) {
                safeRewardsTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            IERC20(pool.lpToken).safeTransferFrom(msg.sender, address(this), _amount);
            user.amount += _amount;
            user.unlockedAmount += _amount;
        }
        _stakeToDex(pool.lpToken, _amount);
        lpTokenTotal[pool.lpToken] += _amount;
        user.rewardDebt = user.amount * pool.accRewardsPerShare / 1e12;
        emit Deposit(msg.sender, msg.sender, _pid, 0, _amount);
    }

    function claimVee(address _account) external nonReentrant {
        uint pending;
        for(uint256 i = 0; i < poolInfo.length; i++){ 
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_account];
            updatePool(i);
            if (user.amount > 0) {
                uint256 reward = user.amount * pool.accRewardsPerShare / 1e12 - user.rewardDebt;
                pending += reward;
                emit ClaimVee(_account, i, reward);
            }
            user.rewardDebt = user.amount * pool.accRewardsPerShare / 1e12;
        }
        uint256 balance = IERC20(vee).balanceOf(address(this));
        if(pending > 0 && pending <= balance) {
            safeRewardsTransfer(_account, pending);
        }
    }
    function depositBehalf(address _account, uint _pid, uint _amount) external {

        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        updatePool(_pid);
        if (user.amount > 0) {
            uint pending = user.amount * pool.accRewardsPerShare / 1e12 - user.rewardDebt;
            if(pending > 0) {
                safeRewardsTransfer(_account, pending);
            }
        }
        if (_amount > 0) {
            IERC20(pool.lpToken).safeTransferFrom(msg.sender, address(this), _amount);
            user.amount += _amount;
            user.lockingAmount += _amount;
        }
        _stakeToDex(pool.lpToken, _amount);
        lpTokenTotal[pool.lpToken] += _amount;
        user.rewardDebt = user.amount * pool.accRewardsPerShare / 1e12;
        emit Deposit(msg.sender, _account, _pid, _amount, 0);
    }

    
    function withdraw(uint _pid, uint _amountInternal) external {

        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockingAmount >= _amountInternal, "lpTokenIn insufficient");

        updatePool(_pid);
        uint pending = user.amount * pool.accRewardsPerShare / 1e12 - user.rewardDebt;
        _withdrawFromDex(pool.lpToken, _amountInternal);
        if(_amountInternal > 0) {
            user.amount -= _amountInternal;
            user.lockingAmount -= _amountInternal;
            lpTokenTotal[pool.lpToken] -= _amountInternal;
            IERC20(pool.lpToken).safeApprove(veeHub, _amountInternal);
            IVeeHub(veeHub).depositLPToken(msg.sender, pool.lpToken, _amountInternal);
        }
        if(pending > 0) {
            safeRewardsTransfer(msg.sender, pending);
        }
        user.rewardDebt = user.amount * pool.accRewardsPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _amountInternal, 0);
    }

    function withdrawDuplex(uint _pid, uint _amountInternal, uint _amountExternal) external {

        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockingAmount >= _amountInternal, "lpTokenIn insufficient");
        require(user.unlockedAmount >= _amountExternal, "lpTokenEx insufficient");

        updatePool(_pid);
        uint pending = user.amount * pool.accRewardsPerShare / 1e12 - user.rewardDebt;
        _withdrawFromDex(pool.lpToken, _amountInternal + _amountExternal);
        if(_amountInternal > 0) {
            user.amount -= _amountInternal;
            user.lockingAmount -= _amountInternal;
            lpTokenTotal[pool.lpToken] -= _amountInternal;
            IERC20(pool.lpToken).safeApprove(veeHub, _amountInternal);
            IVeeHub(veeHub).depositLPToken(msg.sender, pool.lpToken, _amountInternal);
        }
        if(_amountExternal > 0) {
            user.amount -= _amountExternal;
            user.unlockedAmount -= _amountExternal;
            lpTokenTotal[pool.lpToken] -= _amountExternal;
            IERC20(pool.lpToken).safeTransfer(msg.sender, _amountExternal);
        }
        if(pending > 0) {
            safeRewardsTransfer(msg.sender, pending);
        }
        user.rewardDebt = user.amount * pool.accRewardsPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _amountInternal, _amountExternal);
    }

    
    function emergencyWithdraw(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint unlockedAmount = user.unlockedAmount;
        uint lockingAmount = user.lockingAmount;
        user.unlockedAmount = 0;
        user.lockingAmount = 0;
        lpTokenTotal[pool.lpToken] -= user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        if (unlockedAmount > 0) {
            IERC20(pool.lpToken).safeTransfer(msg.sender, unlockedAmount);
        }
        if (lockingAmount > 0) {
            IERC20(pool.lpToken).safeApprove(veeHub, lockingAmount);
            IVeeHub(veeHub).depositLPToken(msg.sender, pool.lpToken, lockingAmount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount, unlockedAmount, lockingAmount);
    }

    
    function safeRewardsTransfer(address to, uint amount) internal {
        IERC20(vee).safeApprove(veeHub, amount);
        IVeeHub(veeHub).deposit(to, amount);
    }

    function getPoolSize() external view returns(uint) {
        return poolInfo.length;
    }

    function setVeeHub(address _veeHub) external onlyOwner {
        address oldVeeHub = veeHub;
        veeHub = payable(_veeHub);
        emit NewVeeHub(veeHub, oldVeeHub);
    }

    function setRewardsPerBlock(uint _rewardsPerBlock) external onlyOwner {
        uint oldRewardsPerBlock = rewardsPerBlock;
        rewardsPerBlock = _rewardsPerBlock;
        emit NewRewardsPerBlock(rewardsPerBlock, oldRewardsPerBlock);
    }

    function _stakeToDex(address lpToken, uint amount) internal {
        if (lpToken == address(0xd69De4d5FF6778b59Ff504d7d09327B73344Ff10)) {
            IMiniChefV2 iMiniChefV2 = IMiniChefV2(address(0x1f806f7C8dED893fd3caE279191ad7Aa3798E928));
            IERC20(lpToken).safeApprove(address(iMiniChefV2), amount);
            iMiniChefV2.deposit(31, amount, address(this));
        }
    }

    function _withdrawFromDex(address lpToken, uint amount) internal {
        if (lpToken == address(0xd69De4d5FF6778b59Ff504d7d09327B73344Ff10)) {
            IMiniChefV2 iMiniChefV2 = IMiniChefV2(address(0x1f806f7C8dED893fd3caE279191ad7Aa3798E928));
            IERC20 rewardToken = IERC20(address(0x60781C2586D68229fde47564546784ab3fACA982));
            uint balanceBefore = rewardToken.balanceOf(address(this));
            iMiniChefV2.withdrawAndHarvest(31, amount, address(this));
            
            
            uint balanceAfter = rewardToken.balanceOf(address(this));
            uint rewards = (rewardBalances[address(0xd69De4d5FF6778b59Ff504d7d09327B73344Ff10)] + balanceAfter - balanceBefore) * amount / lpTokenTotal[lpToken];
            rewardToken.safeTransfer(msg.sender, rewards);
            rewardBalances[address(0xd69De4d5FF6778b59Ff504d7d09327B73344Ff10)] -= rewards;
        }
    }

    function upgradePatch() external onlyOwner {
        address lpAddress = address(0xd69De4d5FF6778b59Ff504d7d09327B73344Ff10);
        IERC20 lpToken = IERC20(lpAddress);
        IStakingRewards stakingRewards = IStakingRewards(address(0xDa959F3464FE2375f0B1f8A872404181931978B2));
        stakingRewards.exit();
        IERC20 rewardToken = IERC20(address(0x60781C2586D68229fde47564546784ab3fACA982));
        uint rewardBalance = rewardToken.balanceOf(address(this));
        rewardBalances[lpAddress] = rewardBalance;
        uint lpTokenTotalReal = lpToken.balanceOf(address(this));
        lpToken.approve(address(0x1f806f7C8dED893fd3caE279191ad7Aa3798E928), lpTokenTotalReal);
        IMiniChefV2(address(0x1f806f7C8dED893fd3caE279191ad7Aa3798E928)).deposit(31, lpTokenTotalReal, address(this));
    }
}