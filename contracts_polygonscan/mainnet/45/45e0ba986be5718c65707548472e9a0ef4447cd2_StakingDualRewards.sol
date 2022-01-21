/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


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


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
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


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


interface IStakingDualRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerTokenA() external view returns (uint256);
    function rewardPerTokenB() external view returns (uint256);

    function earnedA(address account) external view returns (uint256);

    function earnedB(address account) external view returns (uint256);
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}


// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    function _initiateOwner(address _owner) internal {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// Inheritance


contract DualRewardsDistributionRecipient is Owned {
    address public dualRewardsDistribution;

    function notifyRewardAmount(uint256 rewardA, uint256 rewardB, uint256 rewardsDuration) external;

    modifier onlyDualRewardsDistribution() {
        require(msg.sender == dualRewardsDistribution, "Caller is not DualRewardsDistribution contract");
        _;
    }

    function transferAuthority(address _newAuth) public onlyDualRewardsDistribution {
        dualRewardsDistribution = _newAuth;
    }
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/pausable
contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    // constructor() internal {
    //     // This contract is abstract, and thus cannot be instantiated directly
    //     require(owner != address(0), "Owner must be set");
    //     // Paused will be false, and lastPauseTime will be 0 upon initialisation
    // }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = now;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// swapping protocol interface //

interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// Proxy 

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
            }
    }

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);
}

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.govblocks.proxy.implementation");

    /**
    * @dev Constructor function
    */
    constructor() public {}

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
    * @dev Sets the address of the current implementation
    * @param _newImplementation address representing the new implementation to be set
    */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
        sstore(position, _newImplementation)
        }
    }

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.govblocks.proxy.owner");

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor(address _implementation) public {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
    * @dev Allows the proxy owner to upgrade the current version of the proxy.
    * @param _implementation representing the address of the new implementation to be set.
    */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}



// Inheritance
contract StakingDualRewards is IStakingDualRewards, DualRewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsTokenA;
    IERC20 public rewardsTokenB;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRateA = 0;
    uint256 public rewardRateB = 0;
    uint256 public rewardATotal = 0; 
    uint256 public rewardBTotal = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenAStored;
    uint256 public rewardPerTokenBStored;

    mapping(address => uint256) public userRewardPerTokenAPaid;
    mapping(address => uint256) public userRewardPerTokenBPaid;
    mapping(address => uint256) public rewardsA;
    mapping(address => uint256) public rewardsB;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    mapping(address => uint256) public lastStakedOn;
    uint public unstakeLockPeriod;

    address public nativeCurrencyAddress;
    mapping(address => bool) public allowedTokens;


    IUniswapV2Router public router;

    uint256 public maxStakingPoolCap;

    /* ========== CONSTRUCTOR ========== */

    function initiateParams(
        address _owner,
        address _dualRewardsDistribution,
        address _rewardsTokenA,
        address _rewardsTokenB,
        address _stakingToken,
        uint256 _unstakeLockPeriod,
        address _nativeCurrencyAddress,
        address _router,
        uint256 _maxStakingPoolCap
    ) public {
        OwnedUpgradeabilityProxy proxy = OwnedUpgradeabilityProxy(
            address(uint160(address(this)))
        );
        require(msg.sender == proxy.proxyOwner(), "Sender is not proxy owner.");
        _initiateOwner(_owner);
        require(address(stakingToken) == address(0),"Already initiated");
        require(_rewardsTokenA != _rewardsTokenB, "rewards tokens should be different");
        rewardsTokenA = IERC20(_rewardsTokenA);
        rewardsTokenB = IERC20(_rewardsTokenB);
        stakingToken = IERC20(_stakingToken);
        dualRewardsDistribution = _dualRewardsDistribution;
        unstakeLockPeriod = _unstakeLockPeriod;
        nativeCurrencyAddress = _nativeCurrencyAddress;
        maxStakingPoolCap = _maxStakingPoolCap;
        router = IUniswapV2Router(_router);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Get contract balance of the given token
    * @param _token Address of token to query balance for 
    * @param _isNativeCurrency Falg defining if the balance needed to be fetched for native currency of the network/chain
    */
    function getTokenBalance(address _token, bool _isNativeCurrency) public view returns(uint) {
      if(_isNativeCurrency) {
        return ((address(this)).balance);
      }
      return IERC20(_token).balanceOf(address(this));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerTokenA() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenAStored;
        }
        return
            rewardPerTokenAStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateA).mul(1e18).div(_totalSupply)
            );
    }

    function rewardPerTokenB() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenBStored;
        }

        return
            rewardPerTokenBStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateB).mul(1e18).div(_totalSupply)
            );
    }

    function earnedA(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerTokenA().sub(userRewardPerTokenAPaid[account])).div(1e18).add(rewardsA[account]);
    }

    function earnedB(address account) public view returns (uint256) {
        return
            _balances[account].mul(rewardPerTokenB().sub(userRewardPerTokenBPaid[account])).div(1e18).add(rewardsB[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function swapAndStake(address[] memory _path, uint256 _inputAmount, uint _minOutput, address _stakeFor) 
    public payable
     // Contract should not hold any of input/output tokens provided in transaction
    holdNoFunds(_path){
      uint[] memory _output; 
      uint deadline = now*2;
      require(_path[_path.length-1] == address(stakingToken));
      require(allowedTokens[_path[0]],"Not allowed");
      if((_path[0] == nativeCurrencyAddress && msg.value >0)) {
        require(_inputAmount == msg.value);
        _output = router.swapExactETHForTokens.value(msg.value)(
          _minOutput,
          _path,
          address(this),
          deadline
        );
      } else {
        require(msg.value == 0);
        _transferTokenFrom(_path[0], msg.sender, address(this), _inputAmount);
        _provideApproval(_path[0], address(router), _inputAmount);
        _output = router.swapExactTokensForTokens(
          _inputAmount,
          _minOutput,
          _path,
          address(this),
          deadline
        );
      }
      require(_output[_output.length - 1] >= _minOutput);
      // return _output[_output.length - 1];
      _stake(_stakeFor,_output[_output.length - 1]);
    }

    function stake(uint256 _amount) public {
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        _stake(msg.sender,_amount);
    }

    function _stake(address _user, uint256 amount) internal nonReentrant notPaused updateReward(_user) {
        lastStakedOn[_user] = now;
        require(_totalSupply.add(amount) <= maxStakingPoolCap,"Max cap reached");
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[_user] = _balances[_user].add(amount);
        emit Staked(_user, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(now > lastStakedOn[msg.sender].add(unstakeLockPeriod));
        require(amount > 0, "Cannot withdraw 0");
        _getRewards();
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        _getRewards();
    }

    function _getRewards() internal {
        uint256 rewardAmountA = rewardsA[msg.sender];
        if (rewardAmountA > 0) {
            rewardsA[msg.sender] = 0;
            rewardsTokenA.safeTransfer(msg.sender, rewardAmountA);
            emit RewardPaid(msg.sender, address(rewardsTokenA), rewardAmountA);
        }

        uint256 rewardAmountB = rewardsB[msg.sender];
        if (rewardAmountB > 0) {
            rewardsB[msg.sender] = 0;
            rewardsTokenB.safeTransfer(msg.sender, rewardAmountB);
            emit RewardPaid(msg.sender, address(rewardsTokenB), rewardAmountB);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

     /**
    * @dev Internal function to provide approval to external address from this contract
    * @param _tokenAddress Address of the ERC20 token
    * @param _spender Address, indented to spend the tokens
    * @param _amount Amount of tokens to provide approval for. In Wei
    */
    function _provideApproval(address _tokenAddress, address _spender, uint256 _amount) internal {
        IERC20(_tokenAddress).approve(_spender, _amount);
    }

    /**
    * @dev Internal function to call transferFrom function of a given token
    * @param _token Address of the ERC20 token
    * @param _from Address from which the tokens are to be received
    * @param _to Address to which the tokens are to be transferred
    * @param _amount Amount of tokens to transfer. In Wei
    */
    function _transferTokenFrom(address _token, address _from, address _to, uint256 _amount) internal {
      require(IERC20(_token).transferFrom(_from, _to, _amount));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 rewardA, uint256 rewardB,  uint256 rewardsDurationEndTime) external onlyDualRewardsDistribution updateReward(address(0)) {
        uint rewardsDuration = rewardsDurationEndTime.sub(block.timestamp);
        require(block.timestamp.add(rewardsDuration) >= periodFinish, "Cannot reduce existing period");

        rewardATotal = rewardATotal.add(rewardA);
        rewardBTotal = rewardBTotal.add(rewardB);
        if (block.timestamp >= periodFinish) {
            rewardRateA = rewardA.div(rewardsDuration);
            rewardRateB = rewardB.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);

            uint256 leftoverA = remaining.mul(rewardRateA);
            rewardRateA = rewardA.add(leftoverA).div(rewardsDuration);

            uint256 leftoverB = remaining.mul(rewardRateB);
            rewardRateB = rewardB.add(leftoverB).div(rewardsDuration);
          }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balanceA = rewardsTokenA.balanceOf(address(this));
        require(rewardRateA <= balanceA.div(rewardsDuration), "Provided reward-A too high");

        uint balanceB = rewardsTokenB.balanceOf(address(this));
        require(rewardRateB <= balanceB.div(rewardsDuration), "Provided reward-B too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(rewardA, rewardB, periodFinish);
    }

    // Added to support recovering LP Rewards in case of emergency
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

        /**
     * @dev Allow a token to be used for swap and placing prediction
     * @param _token Address of token contract
     */
    function whitelistTokenForSwap(address _token) external onlyOwner {
      require(_token != address(0));
      require(!allowedTokens[_token]);
      allowedTokens[_token] = true;
    }

    /**
     * @dev Remove a token from whitelist to be used for swap and placing prediction
     * @param _token Address of token contract
     */
    function deWhitelistTokenForSwap(address _token) external onlyOwner {
      require(allowedTokens[_token]);
      allowedTokens[_token] = false;
    }

    function updateUnstakeLockPeriod(uint _val) external onlyOwner {
      unstakeLockPeriod = _val;
    }

    function updateMaxStakingPoolCap(uint256 _val) external onlyOwner {
        require(_totalSupply <= _val);
        maxStakingPoolCap = _val;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {

        rewardPerTokenAStored = rewardPerTokenA();
        rewardPerTokenBStored = rewardPerTokenB();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewardsA[account] = earnedA(account);
            userRewardPerTokenAPaid[account] = rewardPerTokenAStored;
        }

        if (account != address(0)) {
            rewardsB[account] = earnedB(account);
            userRewardPerTokenBPaid[account] = rewardPerTokenBStored;
        }
        _;
    }

    modifier holdNoFunds(address[] memory _path) {
      bool _isNativeToken = (_path[0] == nativeCurrencyAddress && msg.value >0);
      uint _initialFromTokenBalance = getTokenBalance(_path[0], _isNativeToken);
      // uint _initialToTokenBalance = getTokenBalance(_path[_path.length-1], false);
      _;  
      require(_initialFromTokenBalance.sub(msg.value) == getTokenBalance(_path[0], _isNativeToken));
      // require(_initialToTokenBalance == getTokenBalance(_path[_path.length-1], false));
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 rewardA, uint256 rewardB, uint256 periodFinish);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address rewardToken, uint256 reward);
    event Recovered(address token, uint256 amount);
}