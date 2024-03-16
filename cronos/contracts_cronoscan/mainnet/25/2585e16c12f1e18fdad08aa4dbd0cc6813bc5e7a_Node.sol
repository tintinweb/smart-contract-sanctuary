/**
 *Submitted for verification at cronoscan.com on 2022-06-09
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-old/token/ERC20/[email protected]

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts-old/math/[email protected]

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts-old/utils/[email protected]

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File @openzeppelin/contracts-old/token/ERC20/[email protected]

pragma solidity ^0.6.0;



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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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


// File contracts/distribution/Node.sol

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

contract Node {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public constant TOKEN = IERC20(0xEfA1FABC2AB6219174aD1c912F56f7de53cDc1E1);
    uint256[] public tierAllocPoints = [1 ether, 1 ether, 1 ether];
    uint256[] public tierAmounts = [50 ether, 500 ether, 5000 ether];
    struct User {
        uint256 total_deposits;
        uint256 total_claims;
        uint256 last_distPoints;
    }

    event CreateNode(uint256 timestamp, address account, uint256 num);

    address private dev;
    
    mapping(address => User) public users;
    mapping(address => mapping(uint256 => uint256)) public nodes;
    mapping(uint256 => uint256) public totalNodes;
    address[] public userIndices;

    uint256 public total_deposited;
    uint256 public total_claimed;
    uint256 public total_rewards;
    uint256 public treasury_rewards;
    uint256 public treasuryFeePercent;
    uint256 public totalDistributeRewards;
    uint256 public totalDistributePoints;
    uint256 public maxReturnPercent;
    uint256 public dripRate;
    uint256 public lastDripTime;
    uint256 public startTime;
    bool public enabled;
    uint256 public constant MULTIPLIER = 10e18;


    constructor(uint256 _startTime) public {
        maxReturnPercent = 500; 
        dripRate = 2400000; 
        treasuryFeePercent = 20; 

        lastDripTime = _startTime > block.timestamp ? _startTime : block.timestamp;
        startTime = _startTime;
        enabled = true;
        dev = msg.sender;
    }

    receive() external payable {
        revert("Do not send AVAX.");
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }

    function changeDev(address payable newDev) external onlyDev {
        require(newDev != address(0), "Zero address");
        dev = newDev;
    }

    function claimTreasuryRewards() external {
        if (treasury_rewards > 0) {
            TOKEN.safeTransfer(dev, treasury_rewards);
            treasury_rewards = 0;
        }   
    }

    function setStartTime(uint256 _startTime) external onlyDev {
        startTime = _startTime;
    }
    
    function setEnabled(bool _enabled) external onlyDev {
        enabled = _enabled;
    }

    function setTreasuryFeePercent(uint256 percent) external onlyDev {
        treasuryFeePercent = percent;
    }

    function setDripRate(uint256 rate) external onlyDev {
        dripRate = rate;
    }
    
    function setLastDripTime(uint256 timestamp) external onlyDev {
        lastDripTime = timestamp;
    }

    function setMaxReturnPercent(uint256 percent) external onlyDev {
        maxReturnPercent = percent;
    }

    function setTierValues(uint256[] memory _tierAllocPoints, uint256[] memory _tierAmounts) external onlyDev {
        require(_tierAllocPoints.length == _tierAmounts.length, "Length mismatch");
        tierAllocPoints = _tierAllocPoints;
        tierAmounts = _tierAmounts;
    }

    function setUser(address _addr, User memory _user) external onlyDev {
        total_deposited = total_deposited.sub(users[_addr].total_deposits).add(_user.total_deposits);
        total_claimed = total_claimed.sub(users[_addr].total_claims).add(_user.total_claims);
        users[_addr].total_deposits = _user.total_deposits;
        users[_addr].total_claims = _user.total_claims;
    }

    function setNodes(address _user, uint256[] memory _nodes) external onlyDev {
        for(uint256 i = 0; i < _nodes.length; i++) {
            totalNodes[i] = totalNodes[i].sub(nodes[_user][i]).add( _nodes[i]);
            nodes[_user][i] = _nodes[i];
        }
    }

    function totalAllocPoints() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            total = total.add(tierAllocPoints[i].mul(totalNodes[i]));
        }
        return total;
    }

    function allocPoints(address account) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            total = total.add(tierAllocPoints[i].mul(nodes[account][i]));
        }
        return total;
    }

    function getDistributionRewards(address account) public view returns (uint256) {
        if (isMaxPayout(account)) return 0;

        uint256 newDividendPoints = totalDistributePoints.sub(users[account].last_distPoints);
        uint256 distribute = allocPoints(account).mul(newDividendPoints).div(MULTIPLIER);
        return distribute > total_rewards ? total_rewards : distribute;
    }
    
    function getTotalRewards(address _sender) public view returns (uint256) {
        if (users[_sender].total_deposits == 0) 
            return 0;
        
        uint256 rewards = getDistributionRewards(_sender).add(getRewardDrip().mul(allocPoints(_sender)).div(totalAllocPoints()));
        uint256 totalClaims = users[_sender].total_claims;
        uint256 maxPay = maxPayout(_sender);

        // Payout remaining if exceeds max payout
        return totalClaims.add(rewards) > maxPay ? maxPay.sub(totalClaims) : rewards;
    }


    function create(uint256 nodeTier, uint256 numNodes) external {
        address _sender = msg.sender;
        require(enabled && block.timestamp >= startTime, "Disabled");
        require(nodeTier < tierAllocPoints.length && nodeTier < tierAmounts.length, "Invalid nodeTier");

        if (users[_sender].total_deposits == 0) {
            userIndices.push(_sender); // New user
            users[_sender].last_distPoints = totalDistributePoints;
        } 
        if (users[_sender].total_deposits != 0 && isMaxPayout(_sender)) {
            users[_sender].last_distPoints = totalDistributePoints;
        }

        uint256 tierPrice = tierAmounts[nodeTier].mul(numNodes);
        
        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice);
        
        total_deposited = total_deposited.add(tierPrice);
        treasury_rewards = treasury_rewards.add(
            tierPrice.mul(treasuryFeePercent).div(100)
        );
        
        nodes[_sender][nodeTier] = nodes[_sender][nodeTier].add(numNodes);
        totalNodes[nodeTier] = totalNodes[nodeTier].add(numNodes);

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function claim() public {
        dripRewards();

        address _sender = msg.sender;
        uint256 _rewards = getDistributionRewards(_sender);
        
        if (_rewards > 0) {
            
            total_rewards = total_rewards.sub(_rewards);
            uint256 totalClaims = users[_sender].total_claims;
            uint256 maxPay = maxPayout(_sender);

            // Payout remaining if exceeds max payout
            if(totalClaims.add(_rewards) > maxPay) {
                _rewards = maxPay.sub(totalClaims);
            }

            users[_sender].total_claims = users[_sender].total_claims.add(_rewards);
            total_claimed = total_claimed.add(_rewards);

            IERC20(TOKEN).safeTransfer(_sender, _rewards);
            
            users[_sender].last_distPoints = totalDistributePoints;
        }
    }

       function _compound(uint256 nodeTier, uint256 numNodes) internal {
        address _sender = msg.sender;
        require(enabled && block.timestamp >= startTime, "Disabled");
        require(nodeTier < tierAllocPoints.length && nodeTier < tierAmounts.length, "Invalid nodeTier");

        if (users[_sender].total_deposits == 0) {
            userIndices.push(_sender); // New user
            users[_sender].last_distPoints = totalDistributePoints;
        } 
        if (users[_sender].total_deposits != 0 && isMaxPayout(_sender)) {
            users[_sender].last_distPoints = totalDistributePoints;
        }

        uint256 tierPrice = tierAmounts[nodeTier].mul(numNodes);
        
        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice);
        
        total_deposited = total_deposited.add(tierPrice);
        treasury_rewards = treasury_rewards.add(
            tierPrice.mul(treasuryFeePercent).div(100)
        );
        
        nodes[_sender][nodeTier] = nodes[_sender][nodeTier].add(numNodes);
        totalNodes[nodeTier] = totalNodes[nodeTier].add(numNodes);

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function compound() public {
      uint256 rewardsPending = getTotalRewards(msg.sender);  
      require(rewardsPending >= tierAmounts[0], "Not enough to compound");  
      uint256 numPossible = rewardsPending.div(tierAmounts[0]);
      claim();
      _compound(0, numPossible);
    }


    function maxPayout(address _sender) public view returns (uint256) {
        return users[_sender].total_deposits.mul(maxReturnPercent).div(100);
    }

    function isMaxPayout(address _sender) public view returns (bool) {
        return users[_sender].total_claims >= maxPayout(_sender);
    }

    function _disperse(uint256 amount) internal {
        if (amount > 0 ) {
            totalDistributePoints = totalDistributePoints.add(amount.mul(MULTIPLIER).div(totalAllocPoints()));
            totalDistributeRewards = totalDistributeRewards.add(amount);
            total_rewards = total_rewards.add(amount);
        }
    }

    function dripRewards() public {
        uint256 drip = getRewardDrip();

        if (drip > 0) {
            _disperse(drip);
            lastDripTime = block.timestamp;
        }
    }

    function getRewardDrip() public view returns (uint256) {
        if (lastDripTime < block.timestamp) {
            uint256 poolBalance = getBalancePool();
            uint256 secondsPassed = block.timestamp.sub(lastDripTime);
            uint256 drip = secondsPassed.mul(poolBalance).div(dripRate);

            if (drip > poolBalance) {
                drip = poolBalance;
            }

            return drip;
        }
        return 0;
    }

    function getDayDripEstimate(address _user) external view returns (uint256) {
        return
            allocPoints(_user) > 0 && !isMaxPayout(_user)
                ? getBalancePool()
                    .mul(86400)
                    .mul(allocPoints(_user))
                    .div(totalAllocPoints())
                    .div(dripRate)
                : 0;
    }

    function total_users() external view returns (uint256) {
        return userIndices.length;
    }

    function numNodes(address _sender, uint256 _nodeId) external view returns (uint256) {
        return nodes[_sender][_nodeId];
    }

    function getNodes(address _sender) external view returns (uint256[] memory) {
        uint256[] memory userNodes = new uint256[](tierAllocPoints.length);
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            userNodes[i] = userNodes[i].add(nodes[_sender][i]);
        }
        return userNodes;
    }
    
    function getTotalNodes() external view returns (uint256[] memory) {
        uint256[] memory totals = new uint256[](tierAllocPoints.length);
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            totals[i] = totals[i].add(totalNodes[i]);
        }
        return totals;
    }

    function getBalance() public view returns (uint256) {
        return IERC20(TOKEN).balanceOf(address(this));
    }

     function getBalancePool() public view returns (uint256) {
        return getBalance().sub(total_rewards).sub(treasury_rewards);
    }

    function emergencyWithdraw(IERC20 token, uint256 amnt) external onlyDev {
        token.safeTransfer(dev, amnt);
    }
}