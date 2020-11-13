// Keep4r Jobs V1 Beta 🚀
// This fork of keep3r decouples the coin from the protocol, 
// disables governance bypassing, and has configurable bonding times.
// 
// More information @ 
// - https://docs.kp4r.network/Jobs.html
// Find a list of featured jobs @
// - https://kp4r.network/#/jobs

pragma solidity ^0.6.6;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
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
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract ReentrancyGuard {
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: reverted");
    }
}

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: < 0");
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
        require(address(token).isContract(), "SafeERC20: !contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: !succeed");
        }
    }
}


interface IKeep3rV1Helper {
    function getQuoteLimit(uint gasUsed) external view returns (uint);
}


contract KeeperV1Jobs is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /// @notice Keep3r Helper to set max prices for the ecosystem
    IKeep3rV1Helper public KPRH;

    IERC20 public kp4r;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");
    bytes32 public immutable DOMAINSEPARATOR;

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint nonce,uint expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /// @notice Submit a job
    event SubmitJob(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Apply credit to a job
    event ApplyCredit(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Remove credit for a job
    event RemoveJob(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Unbond credit for a job
    event UnbondJob(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Added a Job
    event JobAdded(address indexed job, uint block, address governance);

    /// @notice Removed a job
    event JobRemoved(address indexed job, uint block, address governance);

    /// @notice Worked a job
    event KeeperWorked(address indexed credit, address indexed job, address indexed keeper, uint block);

    /// @notice Keeper bonding
    event KeeperBonding(address indexed keeper, uint block, uint active, uint bond);

    /// @notice Keeper bonded
    event KeeperBonded(address indexed keeper, uint block, uint activated, uint bond);

    /// @notice Keeper unbonding
    event KeeperUnbonding(address indexed keeper, uint block, uint deactive, uint bond);

    /// @notice Keeper unbound
    event KeeperUnbound(address indexed keeper, uint block, uint deactivated, uint bond);

    /// @notice Keeper slashed
    event KeeperSlashed(address indexed keeper, address indexed slasher, uint block, uint slash);

    /// @notice Keeper disputed
    event KeeperDispute(address indexed keeper, uint block);

    /// @notice Keeper resolved
    event KeeperResolved(address indexed keeper, uint block);

    event AddCredit(address indexed credit, address indexed job, address indexed creditor, uint block, uint amount);

    /// @notice 1 day to bond to become a keeper
    uint public BOND = 1 days;
    /// @notice 14 days to unbond to remove funds from being a keeper
    uint public UNBOND = 14 days;

    /// @notice direct liquidity fee 0.3%
    uint public FEE = 30;
    uint public BASE = 10000;

    /// @notice address used for ETH transfers
    address constant public ETH = address(0xE);

    /// @notice tracks all current bondings (time)
    mapping(address => mapping(address => uint)) public bondings;
    /// @notice tracks all current unbondings (time)
    mapping(address => mapping(address => uint)) public unbondings;
    /// @notice allows for partial unbonding
    mapping(address => mapping(address => uint)) public partialUnbonding;
    /// @notice tracks all current pending bonds (amount)
    mapping(address => mapping(address => uint)) public pendingbonds;
    /// @notice tracks how much a keeper has bonded
    mapping(address => mapping(address => uint)) public bonds;
    /// @notice tracks underlying votes (that don't have bond)
    mapping(address => uint) public votes;

    /// @notice total bonded (totalSupply for bonds)
    uint public totalBonded = 0;
    /// @notice tracks when a keeper was first registered
    mapping(address => uint) public firstSeen;

    /// @notice tracks if a keeper has a pending dispute
    mapping(address => bool) public disputes;

    /// @notice tracks last job performed for a keeper
    mapping(address => uint) public lastJob;
    /// @notice tracks the total job executions for a keeper
    mapping(address => uint) public workCompleted;
    /// @notice list of all jobs registered for the keeper system
    mapping(address => bool) public jobs;
    /// @notice the current credit available for a job
    mapping(address => mapping(address => uint)) public credits;

    /// @notice the balances for the liquidity providers
    mapping(address => mapping(address => mapping(address => uint))) public liquidityProvided;
    /// @notice liquidity unbonding days
    mapping(address => mapping(address => mapping(address => uint))) public liquidityUnbonding;
    /// @notice liquidity unbonding amounts
    mapping(address => mapping(address => mapping(address => uint))) public liquidityAmountsUnbonding;
    /// @notice job proposal delay
    mapping(address => uint) public jobProposalDelay;
    /// @notice liquidity apply date
    mapping(address => mapping(address => mapping(address => uint))) public liquidityApplied;
    /// @notice liquidity amount to apply
    mapping(address => mapping(address => mapping(address => uint))) public liquidityAmount;

    /// @notice list of all current keepers
    mapping(address => bool) public keepers;
    /// @notice blacklist of keepers not allowed to participate
    mapping(address => bool) public blacklist;

    /// @notice traversable array of keepers to make external management easier
    address[] public keeperList;
    /// @notice traversable array of jobs to make external management easier
    address[] public jobList;

    /// @notice governance address for the governance contract
    address public governance;
    address public pendingGovernance;

    /// @notice the liquidity token supplied by users paying for jobs
    mapping(address => bool) public liquidityAccepted;

    address[] public liquidityPairs;

    uint internal _gasUsed;

    constructor(address _kp4r) public {
        // Set governance for this token
        kp4r = IERC20(_kp4r);
        governance = msg.sender;
        DOMAINSEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("Keep4r")), _getChainId(), address(this)));
    }

    /**
     * @notice Add ETH credit to a job to be paid out for work
     * @param job the job being credited
     */
    function addCreditETH(address job) external payable {
        require(jobs[job], "addCreditETH: !job");
        uint _fee = msg.value.mul(FEE).div(BASE);
        credits[job][ETH] = credits[job][ETH].add(msg.value.sub(_fee));
        payable(governance).transfer(_fee);

        emit AddCredit(ETH, job, msg.sender, block.number, msg.value);
    }

    /**
     * @notice Add credit to a job to be paid out for work
     * @param credit the credit being assigned to the job
     * @param job the job being credited
     * @param amount the amount of credit being added to the job
     */
    function addCredit(address credit, address job, uint amount) external nonReentrant {
        require(jobs[job], "addCreditETH: !job");

        uint _before = IERC20(credit).balanceOf(address(this));
        IERC20(credit).safeTransferFrom(msg.sender, address(this), amount);
        uint _received = IERC20(credit).balanceOf(address(this)).sub(_before);
        uint _fee = _received.mul(FEE).div(BASE);
        credits[job][credit] = credits[job][credit].add(_received.sub(_fee));
        IERC20(credit).safeTransfer(governance, _fee);

        emit AddCredit(credit, job, msg.sender, block.number, _received);
    }

    /**
     * @notice Displays all accepted liquidity pairs
     */
    function pairs() external view returns (address[] memory) {
        return liquidityPairs;
    }

    /**
     * @notice Implemented by jobs to show that a keeper performed work
     * @param keeper address of the keeper that performed the work
     */
    function worked(address keeper) external {
        workReceipt(keeper, KPRH.getQuoteLimit(_gasUsed.sub(gasleft())));
    }

    /**
     * @notice Implemented by jobs to show that a keeper performed work
     * @param keeper address of the keeper that performed the work
     * @param amount the reward that should be allocated
     */
    function workReceipt(address keeper, uint amount) public {
        require(jobs[msg.sender], "workReceipt: !job");
        require(amount <= KPRH.getQuoteLimit(_gasUsed.sub(gasleft())), "workReceipt: max limit");
        credits[msg.sender][address(this)] = credits[msg.sender][address(this)].sub(amount, "workReceipt: insuffient funds");
        lastJob[keeper] = now;
        _bond(address(this), keeper, amount);
        workCompleted[keeper] = workCompleted[keeper].add(amount);
        emit KeeperWorked(address(this), msg.sender, keeper, block.number);
    }

    /**
     * @notice Implemented by jobs to show that a keeper performed work
     * @param credit the asset being awarded to the keeper
     * @param keeper address of the keeper that performed the work
     * @param amount the reward that should be allocated
     */
    function receipt(address credit, address keeper, uint amount) external {
        require(jobs[msg.sender], "receipt: !job");
        credits[msg.sender][credit] = credits[msg.sender][credit].sub(amount, "workReceipt: insuffient funds");
        lastJob[keeper] = now;
        IERC20(credit).safeTransfer(keeper, amount);
        emit KeeperWorked(credit, msg.sender, keeper, block.number);
    }

    /**
     * @notice Implemented by jobs to show that a keeper performed work
     * @param keeper address of the keeper that performed the work
     * @param amount the amount of ETH sent to the keeper
     */
    function receiptETH(address keeper, uint amount) external {
        require(jobs[msg.sender], "receipt: !job");
        credits[msg.sender][ETH] = credits[msg.sender][ETH].sub(amount, "workReceipt: insuffient funds");
        lastJob[keeper] = now;
        payable(keeper).transfer(amount);
        emit KeeperWorked(ETH, msg.sender, keeper, block.number);
    }

    function _bond(address bonding, address _from, uint _amount) internal {
        bonds[_from][bonding] = bonds[_from][bonding].add(_amount);
        if (bonding == address(this)) {
            totalBonded = totalBonded.add(_amount);
            // _moveDelegates(address(0), delegates[_from], _amount);
        }
    }

    function _unbond(address bonding, address _from, uint _amount) internal {
        bonds[_from][bonding] = bonds[_from][bonding].sub(_amount);
        if (bonding == address(this)) {
            totalBonded = totalBonded.sub(_amount);
            // _moveDelegates(delegates[_from], address(0), _amount);
        }

    }

    /**
     * @notice Allows governance to add new job systems
     * @param job address of the contract for which work should be performed
     */
    function addJob(address job) external {
        require(msg.sender == governance, "addJob: !gov");
        require(!jobs[job], "addJob: job known");
        jobs[job] = true;
        jobList.push(job);
        emit JobAdded(job, block.number, msg.sender);
    }

    /**
     * @notice Full listing of all jobs ever added
     * @return array blob
     */
    function getJobs() external view returns (address[] memory) {
        return jobList;
    }

    /**
     * @notice Allows governance to remove a job from the systems
     * @param job address of the contract for which work should be performed
     */
    function removeJob(address job) external {
        require(msg.sender == governance, "removeJob: !gov");
        jobs[job] = false;
        emit JobRemoved(job, block.number, msg.sender);
    }

    /**
     * @notice Allows governance to change the Keep3rHelper for max spend
     * @param _kprh new helper address to set
     */
    function setKeep3rHelper(address _kprh) external {
        require(msg.sender == governance, "setKeep3rHelper: !gov");
       
        KPRH = IKeep3rV1Helper(_kprh);
    }

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: !gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "acceptGovernance: !pendingGov");
        governance = pendingGovernance;
    }

    /**
     * @notice confirms if the current keeper is registered, can be used for general (non critical) functions
     * @param keeper the keeper being investigated
     * @return true/false if the address is a keeper
     */
    function isKeeper(address keeper) external returns (bool) {
        _gasUsed = gasleft();
        return keepers[keeper];
    }

    /**
     * @notice confirms if the current keeper is registered and has a minimum bond, should be used for protected functions
     * @param keeper the keeper being investigated
     * @param minBond the minimum requirement for the asset provided in bond
     * @param earned the total funds earned in the keepers lifetime
     * @param age the age of the keeper in the system
     * @return true/false if the address is a keeper and has more than the bond
     */
    function isMinKeeper(address keeper, uint minBond, uint earned, uint age) external returns (bool) {
        _gasUsed = gasleft();
        return keepers[keeper]
                && bonds[keeper][address(this)].add(votes[keeper]) >= minBond
                && workCompleted[keeper] >= earned
                && now.sub(firstSeen[keeper]) >= age;
    }

    /**
     * @notice confirms if the current keeper is registered and has a minimum bond, should be used for protected functions
     * @param keeper the keeper being investigated
     * @param bond the bound asset being evaluated
     * @param minBond the minimum requirement for the asset provided in bond
     * @param earned the total funds earned in the keepers lifetime
     * @param age the age of the keeper in the system
     * @return true/false if the address is a keeper and has more than the bond
     */
    function isBondedKeeper(address keeper, address bond, uint minBond, uint earned, uint age) external returns (bool) {
        _gasUsed = gasleft();
        return keepers[keeper]
                && bonds[keeper][bond] >= minBond
                && workCompleted[keeper] >= earned
                && now.sub(firstSeen[keeper]) >= age;
    }

    /**
     * @notice begin the bonding process for a new keeper
     * @param bonding the asset being bound
     * @param amount the amount of bonding asset being bound
     */
    function bond(address bonding, uint amount) external nonReentrant {
        require(!blacklist[msg.sender], "bond: blacklisted");
        require(bonding != address(this), "cannot bond this");
        bondings[msg.sender][bonding] = now.add(BOND);
       
        uint _before = IERC20(bonding).balanceOf(address(this));
        IERC20(bonding).safeTransferFrom(msg.sender, address(this), amount);
        amount = IERC20(bonding).balanceOf(address(this)).sub(_before);
        
        pendingbonds[msg.sender][bonding] = pendingbonds[msg.sender][bonding].add(amount);
        emit KeeperBonding(msg.sender, block.number, bondings[msg.sender][bonding], amount);
    }

    /**
     * @notice get full list of keepers in the system
     */
    function getKeepers() external view returns (address[] memory) {
        return keeperList;
    }

    /**
     * @notice allows a keeper to activate/register themselves after bonding
     * @param bonding the asset being activated as bond collateral
     */
    function activate(address bonding) external {
        require(!blacklist[msg.sender], "activate: blacklisted");
        require(bondings[msg.sender][bonding] != 0 && bondings[msg.sender][bonding] < now, "connect yet activate bonding");
        if (firstSeen[msg.sender] == 0) {
          firstSeen[msg.sender] = now;
          keeperList.push(msg.sender);
          lastJob[msg.sender] = now;
        }
        keepers[msg.sender] = true;
        _bond(bonding, msg.sender, pendingbonds[msg.sender][bonding]);
        pendingbonds[msg.sender][bonding] = 0;
        emit KeeperBonded(msg.sender, block.number, block.timestamp, bonds[msg.sender][bonding]);
    }

    /**
     * @notice begin the unbonding process to stop being a keeper
     * @param bonding the asset being unbound
     * @param amount allows for partial unbonding
     */
    function unbond(address bonding, uint amount) external {
        unbondings[msg.sender][bonding] = now.add(UNBOND);
        _unbond(bonding, msg.sender, amount);
        partialUnbonding[msg.sender][bonding] = partialUnbonding[msg.sender][bonding].add(amount);
        emit KeeperUnbonding(msg.sender, block.number, unbondings[msg.sender][bonding], amount);
    }

    /**
     * @notice withdraw funds after unbonding has finished
     * @param bonding the asset to withdraw from the bonding pool
     */
    function withdraw(address bonding) external nonReentrant {
        require(unbondings[msg.sender][bonding] != 0 && unbondings[msg.sender][bonding] < now, "withdraw: unbonding");
        require(!disputes[msg.sender], "withdraw: disputes");

        IERC20(bonding).safeTransfer(msg.sender, partialUnbonding[msg.sender][bonding]);
        emit KeeperUnbound(msg.sender, block.number, block.timestamp, partialUnbonding[msg.sender][bonding]);
        partialUnbonding[msg.sender][bonding] = 0;
    }

    /**
     * @notice allows governance to create a dispute for a given keeper
     * @param keeper the address in dispute
     */
    function dispute(address keeper) external {
        require(msg.sender == governance, "dispute: !gov");
        disputes[keeper] = true;
        emit KeeperDispute(keeper, block.number);
    }

    /**
     * @notice allows governance to slash a keeper based on a dispute
     * @param bonded the asset being slashed
     * @param keeper the address being slashed
     * @param amount the amount being slashed
     */
    function slash(address bonded, address keeper, uint amount) public nonReentrant {
        require(msg.sender == governance, "slash: !gov");
        IERC20(bonded).safeTransfer(governance, amount);
        _unbond(bonded, keeper, amount);
        disputes[keeper] = false;
        emit KeeperSlashed(keeper, msg.sender, block.number, amount);
    }

    /**
     * @notice blacklists a keeper from participating in the network
     * @param keeper the address being slashed
     */
    function revoke(address keeper) external {
        require(msg.sender == governance, "slash: !gov");
        keepers[keeper] = false;
        blacklist[keeper] = true;
        slash(address(this), keeper, bonds[keeper][address(this)]);
    }

    /**
     * @notice allows governance to resolve a dispute on a keeper
     * @param keeper the address cleared
     */
    function resolve(address keeper) external {
        require(msg.sender == governance, "resolve: !gov");
        disputes[keeper] = false;
        emit KeeperResolved(keeper, block.number);
    }
    
    function setBondingTimes(uint256 _BOND, uint256 _UNBOND) public {
         require(msg.sender == governance, "setBondingTimes: !gov");
         require(_UNBOND < 21 days, "unbond time too long");
         UNBOND = _UNBOND;
         BOND = _BOND;
    }
    
    function setFees(uint256 _FEE) public {
        require(msg.sender == governance, "setFee: !gov");
        require(_FEE < 500, "fee to big");
        FEE = _FEE;
    }



    function _getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}