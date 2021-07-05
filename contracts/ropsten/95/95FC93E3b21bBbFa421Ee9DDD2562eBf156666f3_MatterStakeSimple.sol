/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

//import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
//import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
//import "./Governable.sol";
//import "./interfaces/IMatterAuctionToken.sol";

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


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


contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}


abstract contract MatterStakeSimpleV0 is Initializable {
    using SafeMath for uint256;

    address internal constant DeadAddress = 0x000000000000000000000000000000000000dEaD;

    // team address
    address payable public TeamAddress;     // v1.6.0 deprecated
    // stake token address
    address public StakeToken;              // v1.6.0 deprecated
    // the total seconds the un-staking will last
    uint32 public UnStakeSeconds;           // v1.6.0 deprecated

    // total amount of staking
    uint256 public totalStake;
    // total amount of received reward
    uint256 public totalReward;
    // total amount of claimed reward
    uint256 public totalClaimedReward;

    // deprecated, index => amount of daily staking
    mapping(uint32 => uint256) public dailyStake;
    // deprecated, date index => amount of daily reward
    mapping(uint32 => uint256) public dailyReward;
    // deprecated, date index => amount of daily reward
    mapping(uint32 => uint256) public dailyClaimedReward;

    // account => amount of daily staking
    mapping(address => uint256) public myTotalStake;
    // deprecated, account => date index => if my reward is claimed
    mapping(address => mapping(uint32 => bool)) public myRewardClaimed;

    // account => sequence number => amount of un-staking
    mapping(address => mapping(uint32 => uint256)) public myUnStake;
    // account => sequence number => the end time in seconds of un-staking
    mapping(address => mapping(uint32 => uint32)) public myUnStakeEndAt;
    // address => array of sequence number
    mapping(address => uint32[]) public myUnStakes;
    // address => last time of claim reward
    mapping(address => uint) public lastTimeOf;

    event Staked (address sender, uint256 amount);
    event UnStaked (address sender, uint256 amount);
    event RewardClaimed (address sender, uint256 amount);
    event Withdrawn (address sender, uint256 amount);

    function depositReward() external payable {
        totalReward = totalReward.add(msg.value);
    }

    function staking(uint256 amount) public {
        claimReward();

        address sender = msg.sender;
        require(amount > 0, "amount is zero.");

        IERC20 _stakeToken = IERC20(getStakeToken());
        _stakeToken.transferFrom(sender, address(this), amount);        // transfer amount of staking to contract
        _stakeToken.approve(address(this), 0);                          // reset allowance to 0

        myTotalStake[sender] = myTotalStake[sender].add(amount);        // increasing total amount of stake
        totalStake = totalStake.add(amount);

        emit Staked(sender, amount);
    }

    function unStaking(uint256 amount) public virtual {
        claimReward();

        address sender = msg.sender;
        require(amount > 0, "amount is zero");
        require(totalStake >= amount, "totalStake should larger than or equal to amount");
        require(myTotalStake[sender] >= amount, "my stake should larger than or equal to amount");

        myTotalStake[sender] = myTotalStake[sender].sub(amount);        // decreasing total amount of stake
        totalStake = totalStake.sub(amount);

        IERC20(getStakeToken()).transfer(sender, amount);

        emit UnStaked(sender, amount);
    }

    function withdraw() public {
        revert("function withdraw is deprecated");

        address sender = msg.sender;

        uint32 maxLength = uint32(myUnStakes[sender].length);
        uint32[] memory removeIndexes = new uint32[](maxLength);
        uint32 removeIndexCount = 0;
        uint256 amount = 0;
        for (uint32 i = 0; i < maxLength; i++) {
            uint32 unStakeSN = myUnStakes[sender][i];
            if (myUnStakeEndAt[sender][unStakeSN] <= now) {
                amount = amount.add(myUnStake[sender][unStakeSN]);
                delete myUnStake[sender][unStakeSN];
                delete myUnStakeEndAt[sender][unStakeSN];
                removeIndexes[removeIndexCount] = i;
                removeIndexCount++;
            }
        }
        // remove data
        for (uint32 i = 0; i < removeIndexCount; i++) {
            uint32 removeDateIndex = removeIndexes[i] - i;
            myUnStakes[sender] = removeArray(myUnStakes[sender], removeDateIndex);
        }

        if (amount > 0) {
            IERC20(getStakeToken()).transfer(sender, amount);
        }

        emit Withdrawn(sender, amount);
    }

    function claimReward() public {
        //revert("function claimReward is deprecated");
        
        /*checkMigration();

        address payable sender = msg.sender;
        uint256 reward = calculateReward(sender);
        totalClaimedReward = totalClaimedReward.add(reward);

        if (reward > 0) {
            // burn 1/2 of reward
            uint burned = reward.div(2);
            // actual reward is 1/2 of origin reward
            uint actualReward = reward.sub(burned);
            if (burned > 0) {
                // DO NOT BURN AUCTION
                // swap(DeadAddress, burned);
            }
            if (actualReward > 0) {
                swap(sender, actualReward);
            }
        }

        lastTimeOf[sender] = now;

        emit RewardClaimed(sender, reward);*/
    }

    function swap(address target, uint amount) internal {
        IUniswapV2Router02 usi = IUniswapV2Router02(getUniSwapContract());
        uint amountOutMin = 0;
        address[] memory path = getPath();
        address to = target;
        uint deadline = now.add(20 minutes);
        usi.swapExactETHForTokens{value: amount}(amountOutMin, path, to, deadline);
    }

    uint constant MAX_SPAN = 30 days;

    function calculateReward(address target) public view returns (uint256) {
        uint span = now.sub(lastTimeOf[target]);
        if(span > MAX_SPAN) {
            span = MAX_SPAN;
        }
        if (totalStake == 0) {
            return 0;
        }
        return address(this).balance.mul(myTotalStake[target]).div(totalStake).mul(span).div(MAX_SPAN);
    }

    function calculateWithdraw(address target) public view returns (uint256) {
        uint256 amount = 0;
        for (uint32 i = 0; i < myUnStakes[target].length; i++) {
            uint32 sn = myUnStakes[target][i];
            if (myUnStakeEndAt[target][sn] <= now) {
                amount = amount.add(myUnStake[target][sn]);
            }
        }

        return amount;
    }

    function calculateUnStake(address target) public view returns (uint256) {
        return myTotalStake[target];
    }

    function removeArray(uint32[] storage array, uint32 index) private returns (uint32[] storage) {
        require(index < array.length, "index out of range.");

        if (index < array.length - 1) {
            for (uint32 i = index; i < array.length - 1; i++){
                array[i] = array[i + 1];
            }
        }
        array.pop();

        return array;
    }

    function currentDateIndex() public view returns (uint32) {
        return uint32(now.div(1 days));
    }

    function prevDateIndex() private view returns (uint32) {
        return currentDateIndex() - 1;
    }

    function getPath() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(getUniSwapContract()).WETH();
        path[1] = getStakeToken();

        return path;
    }

    function getStakeToken() public virtual view returns (address);

    function getUniSwapContract() public virtual view returns (address);

   // function checkMigration() internal virtual;
}

abstract contract MatterStakeSimpleV1 is MatterStakeSimpleV0, Configurable {

    bytes32 internal constant StakeTokenAddress =   bytes32("MatterSS::StakeTokenAddress");
    bytes32 internal constant UniSwapContract =     bytes32("MatterSS::UniSwapContract");

    function initialize(address _governor) public override {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;

        // config[StakeTokenAddress] = uint(0xAbF690E2EbC6690c4Fdc303fc3eE0FBFEb1818eD);		// Rinkeby
        config[StakeTokenAddress] = uint(0x6669Ee1e6612E1B43eAC84d4CB9a94Af0A98E740);//uint(0x1C9491865a1DE77C5b6e19d2E6a5F1D7a6F2b25F);//matter //test
        config[UniSwapContract] = uint(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function getStakeToken() public override view returns (address) {
        return address(config[StakeTokenAddress]);
    }

    function getUniSwapContract() public override view returns (address) {
        return address(config[UniSwapContract]);
    }

    function calculateRewardInBot(address target) external view returns (uint) {
        return 0;
        uint amountIn = calculateReward(target);
        if (amountIn == 0) return 0;
        address[] memory path = getPath();
        uint[] memory amounts = IUniswapV2Router02(getUniSwapContract()).getAmountsOut(amountIn, path);

        return amounts[amounts.length - 1];
    }
}


abstract contract MatterStakeSimpleV2 is MatterStakeSimpleV1 {
    bytes32 internal constant _proposeID_					= keccak256(abi.encodePacked("proposeID"));             // 0x99dc3a530220d3acdde2a84b34121cdd471ff2f8dccc3741e66127d6838e963b
    bytes32 internal constant _proposeStatus_				= keccak256(abi.encodePacked("proposeStatus"));         // 0x42d8f19c97ee5a0c020c3140075b07aa4275f3d8da0c4302c6d3f66e75958292
    bytes32 internal constant _thresholdPropose_			= "thresholdPropose";      
    bytes32 internal constant _proposer_                    = keccak256(abi.encodePacked("proposer"));              // 0xae46c42ab0ce10908c1d765cf1591cc57b8ebf9b2bec1a45d8816fbb3e828f4a
    bytes32 internal constant _proposeSubject_				= keccak256(abi.encodePacked("proposeSubject"));        // 0xe34aa96dfaf5d2a69bd46a7ed8b2a479243f1aaafdc6f53d2c650319bd5da927                                
    bytes32 internal constant _proposeContent_				= keccak256(abi.encodePacked("proposeContent"));        // 0xee8e035a9446305db6958894217f8048ddfaa5ce462b8fec38b842a1b16b6f8f
    bytes32 internal constant _spanLo_                      = "spanLo";                
    bytes32 internal constant _spanHi_                      = "spanHi";   
    bytes32 internal constant _spanPropose_                 = keccak256(abi.encodePacked("spanPropose")); 
    bytes32 internal constant _timePropose_					= keccak256(abi.encodePacked("timePropose"));           // 0x639cf8e560160c1c1c5fe1e1f1822f9d5ee2f35a5e60ea9e5fadc1ed5c743ebc                            
    bytes32 internal constant _proposeKey_					= keccak256(abi.encodePacked("proposeKey"));            // 0xd307d342b97f3c6a097998b749e30fe8855996166e3ae2bceab49ebeccf18b4c                            
    bytes32 internal constant _proposeValue_				= keccak256(abi.encodePacked("proposeValue"));          // 0x3f030b1a7eb163da8b1e913ee5e33fb4deef527f176438de9bfdf702ae831e4b                            
    bytes32 internal constant _proposes_					= keccak256(abi.encodePacked("proposes"));              // 0x04cbadf7a77c08e0721858126d70a777c8ba2bc58f9f7f02197176d3a97df210
    bytes32 internal constant _proposesVoting_				= keccak256(abi.encodePacked("proposesVoting"));        // 0x35511cd217b773d22bd13f18a73f20a2e6a35dfa872947fa99526f38d8a5d8a5                             
    bytes32 internal constant _votes_						= keccak256(abi.encodePacked("votes"));                 // 0xf2203813fc6277042a63750c3bf1830873c2d833ed7fc455dac19fa65a26c3dd                             
    bytes32 internal constant _voteResultBase_				= keccak256(abi.encodePacked("voteResultBase"));        // 0x01e1cdf5586eb4173cf6a3260fc5bd4c8a06b085b2d7b0eadf25e6be3655ca45                                  
    bytes32 internal constant _divisorAbsent_				= keccak256(abi.encodePacked("divisorAbsent"));         // 0xcb5c2778adab8fd5772aae3cc1258d3b0ce253009be10d238142630fb95bd6cd

    uint256 internal constant PROPOSE_STATUS_VOTING			= uint256(bytes32("PROPOSE_STATUS_VOTING"));
    uint256 internal constant PROPOSE_STATUS_FAIL			= uint256(bytes32("PROPOSE_STATUS_FAIL"));
    uint256 internal constant PROPOSE_STATUS_PASS			= uint256(bytes32("PROPOSE_STATUS_PASS"));

    bytes32 internal constant VOTE_YES                      = "VOTE_YES";
    bytes32 internal constant VOTE_NO                       = "VOTE_NO";
    bytes32 internal constant VOTE_CANCEL                   = "VOTE_CANCEL";

    mapping (bytes32 => string) internal configString;
    

    mapping(bytes32 => mapping(address =>uint256)) public myVoteValue;
    
    function initialize() public governance virtual {
        config[_thresholdPropose_] = 100000 ether; //0.02 ether;        // 2%
        config[_spanLo_] = 0 days;   //test 3days
        config[_spanHi_] = 7 days;
    }

	event Propose(address indexed _proposer, bytes32 _proposeID, string _subject, string _content, uint _span, bytes32 _key, uint256 _value);
    function propose(bytes32 _proposeID, string memory _subject, string memory _content, uint _span, bytes32 _key, uint256 _value) public virtual {
		address sender = msg.sender;
        require(myTotalStake[sender]  >= getConfig(_thresholdPropose_));	//, "Proponent has not enough Matter!"
        
        myTotalStake[sender]= myTotalStake[sender].sub(100 ether); 
        totalStake = totalStake.sub(100 ether);
        

        _proposeID = keccak256(abi.encodePacked(getConfig(_proposes_, 0x0).add(1)));
        uint256 proposeID = uint256(_proposeID);
        emit Propose(sender, bytes32(proposeID), _subject, _content, _span, _key, _value);

        require(getConfig(_proposeStatus_, proposeID) == 0x0, "Can't propose same proposeID again!");
        _setConfig(_proposeStatus_, proposeID, PROPOSE_STATUS_VOTING);

        _setConfig(_proposer_, proposeID, uint(sender));
        _setConfigString(_proposeSubject_, proposeID, _subject);
        _setConfigString(_proposeContent_, proposeID, _content);

        require(_span >= config[_spanLo_], 'Span is too short');
        require(_span <= config[_spanHi_], 'Span is too long');
        _setConfig(_timePropose_, proposeID, _span.add(now));
        _setConfig(_spanPropose_, proposeID, _span);
        

        _setConfig(_proposeKey_, proposeID, uint(_key));
        _setConfig(_proposeValue_, proposeID, _value);

        _setConfig(_proposes_, proposeID, getConfig(_proposes_, 0x0));					// join proposes list
        _setConfig(_proposes_, 0x0, proposeID);
        _setConfig(_proposesVoting_, proposeID, getConfig(_proposesVoting_, 0x0));
        _setConfig(_proposesVoting_, 0x0, proposeID);

        //vote(_proposeID, VOTE_YES);
    }

    //0xd07ef206
    function voteYes(bytes32 _proposeID) public {
        vote(_proposeID, VOTE_YES);
    }

    //0x7bae981b
    function voteNo(bytes32 _proposeID) public {
        vote(_proposeID, VOTE_NO);
    }

    //0xf6b62166
    function voteCancle(bytes32 _proposeID) public {
        vote(_proposeID, VOTE_CANCEL);
    }

    //0xc7bc95c2
    function getVotes(bytes32 _ID, bytes32 _vote) public view returns(uint256) {
        return getConfig(_votes_, uint256(_ID^_vote));
    }

    event Vote(address indexed _holder, bytes32 indexed _ID, bytes32 _vote, uint256 _votes);
    //0xeeaaf19d
    function vote(bytes32 _ID, bytes32 _vote) public virtual {
        uint256 status = getConfig(_proposeStatus_, uint256(_ID));
        require(status == PROPOSE_STATUS_VOTING, "Propose status is not VOTING");

        address _holder = msg.sender;
        uint256 ID = uint256(_ID);
        if(now <= getConfig(_timePropose_, ID)) {
            uint256 staked = myTotalStake[_holder];
            bytes32 voted = bytes32(getConfig(_votes_, uint(_holder)^uint(ID)));
            uint256 ID_voted = uint256(_ID^voted);
            if((voted == VOTE_YES || voted == VOTE_NO) && _vote == VOTE_CANCEL || voted ^ _vote == VOTE_YES ^ VOTE_NO) {
                _setConfig(_votes_, ID_voted, getConfig(_votes_, ID_voted).sub(staked));
            }
            uint256 ID_vote = uint256(_ID^_vote);
            if((voted == 0x0 || voted == VOTE_CANCEL) && (_vote == VOTE_YES || _vote == VOTE_NO || _vote == VOTE_CANCEL) || voted ^ _vote == VOTE_YES ^ VOTE_NO) {
                _setConfig(_votes_, ID_vote, getConfig(_votes_, ID_vote).add(staked));
            }
            _setConfig(_votes_, uint(_holder)^uint(ID), uint256(_vote));
            emit Vote(_holder, _ID, _vote, staked);
        } else {
            emit Vote(_holder, _ID, _vote, 0);

            uint256 prev = 0;
            uint256 id = 0;
            for(id = getConfig(_proposesVoting_, 0x0); id != ID && id != 0x0; (prev = id, id = getConfig(_proposesVoting_, id))) {
            }
            _setConfig(_proposesVoting_, prev, getConfig(_proposesVoting_, id));

            _setConfig(_voteResultBase_, uint256(_ID), totalStake);

            if(voteResult(_ID))
            setConfig_(_proposeID_, bytes32(getConfig(_proposeKey_, ID)), getConfig(_proposeValue_, ID));
        }
    }
    
    function unVote(bytes32 _ID) public virtual {
        uint256 status = getConfig(_proposeStatus_, uint256(_ID));
        require(status == PROPOSE_STATUS_VOTING, "Propose status is not VOTING");

        address _holder = msg.sender;
        uint256 ID = uint256(_ID);
        if(now <= getConfig(_timePropose_, ID)) {
            uint256 staked = myTotalStake[_holder];
            bytes32 voted = bytes32(getConfig(_votes_, uint(_holder)^uint(ID)));
            uint256 ID_voted = uint256(_ID^voted);
            _setConfig(_votes_, ID_voted, getConfig(_votes_, ID_voted).sub(staked));
            _setConfig(_votes_, uint(_holder)^uint(ID), uint256(0));//0x0
            
        } 
    } 

    event VoteResult(bytes32 indexed _ID, bytes32 indexed _proposeID, bool result, uint256 _yes, uint256 _no, uint256 _base);
    function voteResult(bytes32 _ID) internal returns(bool result) {
        uint256 yes = getVotes(_ID, VOTE_YES);
        uint256 no = getVotes(_ID, VOTE_NO);
        uint256 base = totalStake;
        uint256 divisor = getConfig(_divisorAbsent_);
        if(divisor == 0)
            divisor = 6 ether;
        result = yes * divisor + yes + no > no * divisor + base;		// pass = yes - no - absent/6 > 0
        _setConfig(_proposeStatus_, uint256(_ID), result ? PROPOSE_STATUS_PASS : PROPOSE_STATUS_FAIL);
        bytes32 projectID = bytes32(getConfig(_proposeID_, uint256(_ID)));
        emit VoteResult(_ID, projectID, result, yes, no, base);
    }

    event Config(bytes32 indexed _ID, bytes32 indexed _key, uint256 _value);
    function setConfig_(bytes32 _ID, bytes32 _key, uint256 _value) internal {
        if(_key == 0x0)
            return;
        _setConfig(_key, _value);
        emit Config(_ID, _key, _value);
    }

    function getConfigString(bytes32 key) public view returns (string memory) {
        return configString[key];
    }
    function getConfigString(bytes32 key, uint index) public view returns (string memory) {
        return configString[bytes32(uint(key) ^ index)];
    }
    function _setConfigString(bytes32 key, string memory value) internal {
        configString[key] = value;
    }
    function _setConfigString(bytes32 key, uint index, string memory value) internal {
        _setConfigString(bytes32(uint(key) ^ index), value);
    }
    function setConfigString(bytes32 key, string memory value) external governance {
        _setConfigString(key, value);
    }
    function setConfigString(bytes32 key, uint index, string memory value) external governance {
        _setConfigString(bytes32(uint(key) ^ index), value);
    }
}

contract MatterStakeSimple is MatterStakeSimpleV2 {

    using SafeMath for uint256;

    bytes32 internal constant _govRewardPerDay_             = bytes32("govRewardPerDay");
    bytes32 internal constant _proposeRewardPercent_        = bytes32("proposeRewardPercent");
    bytes32 internal constant _voteRewardPercent_           = bytes32("voteRewardPercent");
    bytes32 internal constant _matter_                      = bytes32("matterAddress");

    uint256 public proposeLastTime;
    uint256 public voteLastTime;
    uint256 public proposeEma;
    uint256 public voteEma;
    
    // account => amount of governance reward
    mapping(address => uint256) public myGovernaceWillReward;
    
    // id=>address=>bool
    mapping(bytes32 => mapping(address =>bool)) public myGovernaceVote;
    mapping(bytes32 => mapping(address =>bool)) public myGovernacePropose;
 
    //address => time
    mapping(address => uint256) public myStakeEndTime;

    bytes32 internal constant _maxGovReward_ = keccak256(abi.encodePacked("maxGovernanceReward"));  //  0x6ab8a731401008225ce8d89a324608b5c6a7aafc985c6a4fc52c933726448dcd

    event GovRewardClaimed (address sender, uint256 amount); 

    function initializeV1(address matter) public governance virtual {
        setConfig(_govRewardPerDay_,address(0),0 ether);       //   0 bot
        setConfig(_proposeRewardPercent_,address(0),uint(2));  //   2%
        setConfig(_voteRewardPercent_,address(0),uint(98));    //   98%  
        setConfig(_matter_,address(0),uint(matter));
        proposeLastTime = now;
        voteLastTime = now;           
        proposeEma = uint256(50000 ether*2/100 ).div(86400);
        voteEma = uint256(50000 ether*98/100).div(86400);
    }

    function initializeV2() public governance {
        _setConfig(_maxGovReward_ ,1 ether / 2);
    }

	function getGovReward() public virtual view returns (uint256){
	   return myGovernaceWillReward[msg.sender];
	}

	function getGovReward(address addr) public view virtual returns (uint256){
	   return myGovernaceWillReward[addr];
	}
	
    function claimGovReward() public {
        revert("function claimGovReward is deprecated");
        address payable sender = msg.sender;
        uint256 reward = myGovernaceWillReward[sender];
        if (reward > 0) {
            uint256 govRewardPerDay = getConfig(_govRewardPerDay_,address(0));
            if (reward > govRewardPerDay){
                reward = govRewardPerDay;
            }
            address matterAddress = address(getConfig(_matter_,0));
            IERC20(getStakeToken()).transferFrom(matterAddress,sender,reward);
            myGovernaceWillReward[msg.sender] = 0;
            emit GovRewardClaimed(sender, reward);
        }

    }


    function vote(bytes32 _ID, bytes32 _vote) public override virtual{
        super.vote(_ID,_vote);
        
       
        myStakeEndTime[msg.sender] = now.add(getConfig(_spanPropose_, uint256(_ID)));
        if(myStakeEndTime[msg.sender] < getConfig(_timePropose_, uint256(_ID))) {
            myStakeEndTime[msg.sender] = getConfig(_timePropose_, uint256(_ID));
        }
        if (myGovernaceVote[_ID][msg.sender])
            return;
        //require(myTotalStake[msg.sender]  > 0,"please stake first" );	
        myGovernaceVote[_ID][msg.sender]=true;
        uint256 staked = myTotalStake[msg.sender];
        uint256 rVoteReward;
        uint256 voteEmaT = calcVoteEma(staked);
        rVoteReward = calcVoteReward(staked);
        if (rVoteReward > 0)
            myGovernaceWillReward[msg.sender] = myGovernaceWillReward[msg.sender].add(rVoteReward);
        if (myGovernaceWillReward[msg.sender]>getConfig(_maxGovReward_))   
            myGovernaceWillReward[msg.sender] = getConfig(_maxGovReward_);
        voteLastTime = now;  
        voteEma = voteEmaT;
    }
    function propose(bytes32 _proposeID, string memory _subject, string memory _content, uint _span, bytes32 _key, uint256 _value) public override{
        super.propose(_proposeID,_subject,_content,_span,_key,_value);
        if(myStakeEndTime[msg.sender] < getConfig(_timePropose_, uint256(_proposeID))) {
            myStakeEndTime[msg.sender] = getConfig(_timePropose_, uint256(_proposeID));
        }
        if (myGovernacePropose[_proposeID][msg.sender])
            return;
        myGovernacePropose[_proposeID][msg.sender] = true;
        uint256 staked = myTotalStake[msg.sender];
        uint256 rProposeReward;
        uint256 proposeEmaT = calcProposeEma(staked);
        rProposeReward = calcProposeReward(staked);
        if (rProposeReward > 0)
           myGovernaceWillReward[msg.sender] = myGovernaceWillReward[msg.sender].add(rProposeReward);
        if (myGovernaceWillReward[msg.sender]>getConfig(_maxGovReward_))   
            myGovernaceWillReward[msg.sender] = getConfig(_maxGovReward_);
        proposeLastTime=now;
        proposeEma = proposeEmaT;
    }
    
    function stakeAndPropose(uint256 stakeValue,bytes32 _proposeID, string memory _subject, string memory _content, uint _span, bytes32 _key, uint256 _value) public {
        require(stakeValue  >= getConfig(_thresholdPropose_));
        staking(stakeValue);
        propose(_proposeID, _subject, _content, _span, _key, _value);
    }
    
    function stakeAndVote(uint256 stakeValue,bytes32 _ID, bytes32 _vote) public {
        //unVote(_ID);
        //if (stakeValue>0)
        require(myVoteValue[_ID][msg.sender]==0,"You have voted already");
        myVoteValue[_ID][msg.sender] = stakeValue;
        staking(stakeValue);
        vote(_ID,_vote);
    }
    

    function calcTimedQuota(uint256 _rest, uint256 _full, uint256 _timespan, uint256 _period) public pure virtual returns (uint256) {
        if(_timespan > _period)
            _timespan = _period;
        return ((_rest.mul(_period.sub(_timespan))).add(_timespan.mul(_full))).div(_period);
    }


    function calcEma(uint256 _emaPre, uint256 _value, uint32 _timeSpan, uint256 _period) public view virtual returns(uint256) {
        if(_timeSpan > 0) {
            return calcTimedQuota(_emaPre, _value.div(_timeSpan), _timeSpan, _period);
        }
        return _emaPre + _value.mul(11574141054252).div(1 ether);   //ln(86400/86399)
        //return _emaPre + (safeMul(_value, ln(_period, _period-1)) >> MAX_PRECISION) / 1 ether;
    }


    function calcVoteEma(uint amount) public view virtual returns (uint256){
        uint32 timeSpan = uint32(now.sub(voteLastTime));
        return calcEma(voteEma,amount,timeSpan,1 days);
    }

    function calcProposeEma(uint amount) public view virtual returns (uint256){
        uint32 timeSpan = uint32(now.sub(proposeLastTime));
    	return calcEma(proposeEma,amount,timeSpan,1 days);
    }


    function calcVoteReward(uint amount) public view virtual returns (uint256){
	    uint32 timeSpan = uint32(now.sub(voteLastTime));
        uint256 rEma = calcEma(voteEma,amount,timeSpan,1 days);
        uint256 govRewardPerDay = uint256(getConfig(_govRewardPerDay_,address(0)));
        uint256 voteRewardPercent = uint256(getConfig(_voteRewardPercent_,address(0)));
        uint256 voteQuotaPerDay = govRewardPerDay.mul(voteRewardPercent).div(100);
        if (amount >= rEma.mul(1 days))
            return voteQuotaPerDay;
        else
           return voteQuotaPerDay.mul(amount).div(rEma.mul(1 days));
    }

    function calcProposeReward(uint amount)  public view virtual returns (uint256){
        uint32 timeSpan = uint32(now.sub(proposeLastTime));
	    uint256 rEma = calcEma(proposeEma,amount,timeSpan,1 days);
        uint256 govRewardPerDay = uint256(getConfig(_govRewardPerDay_,address(0)));
        uint256 proposeRewardPercent = uint256(getConfig(_proposeRewardPercent_,address(0)));
        uint256 proposeQuotaPerDay = govRewardPerDay.mul(proposeRewardPercent).div(100);
        if (amount>=rEma.mul(1 days))
            return  proposeQuotaPerDay;
        else 
            return proposeQuotaPerDay.mul(amount).div(rEma.mul(1 days));
    }
    

    function unStaking(uint256 amount) public override virtual {
        require(now>=myStakeEndTime[msg.sender],"Staking not due");
        super.unStaking(amount);
    }

    function transferFee(address payable to, uint amount) public governance {
        to.transfer(amount);
    }
    
    function transferStakeFee(address payable to, uint amount) public governance {
        IERC20(getStakeToken()).transfer(to, amount);
    }

    
}