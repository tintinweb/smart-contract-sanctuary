//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./AffinityDistributor.sol";
import "./Utils.sol";
import "./Auth.sol";
import "./IDEXRouter.sol";
import "./ReflectionLocker02.sol";
import "./ISafeAffinity.sol";
import "./SafeAffinity.sol";
import "./SafeMaster.sol";


contract SafeStake is Auth, Pausable {
    using SafeMath for uint256;

    IERC20 public rewardsToken;
    SafeMaster safeMaster;

    // TODO APR calc
    uint public aprCount;
    uint public lastDistributed;
    uint public currentAPR;
    mapping (uint => uint[2]) APRs; // APRs[aprCount] = [lastDistributed, currentAPR]
    
    mapping (address => bool) excludeSwapperRole;
    mapping (address => ReflectionLocker02) public lockers;

    ReflectionLocker02[] public lockersArr;
    AffinityDistributor distributor;

    uint public permittedDuration; // in second 
    uint public permissionFee; // 100 = 1%

    struct Share {
        uint256 lastStakeTime;
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }


    SafeAffinity safeAffinity;
    
    IERC20 safeEarn;
    IERC20 safeVault;

    IDEXRouter public router;
    uint public lunchTime;

    struct TokenPool {
        uint totalShares;
        uint totalDividends;
        uint totalDistributed;
        uint dividendsPerShare;
        IERC20 stakingToken;
    }

    TokenPool public tokenPool;

    //Shares by token vault
    mapping ( address => Share) public shares;

    // uint public duration = 14 days;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    constructor (address _router, address _rewardsToken, address _stakingToken, address _safeEarnAddr, address _safeVaultAddr, address _safeMasterAddr, uint256 _permittedDuration, uint256 _permissionFee) Auth (msg.sender) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        rewardsToken = IERC20(_rewardsToken);
        tokenPool.stakingToken = IERC20(_stakingToken);
        safeAffinity = SafeAffinity(payable(_stakingToken));
        lunchTime = block.timestamp;
        distributor = safeAffinity.distributor() ;
        safeEarn = IERC20(_safeEarnAddr);
        safeVault = IERC20(_safeVaultAddr);
        safeMaster = SafeMaster(_safeMasterAddr);
        permittedDuration = _permittedDuration;
        permissionFee = _permissionFee;
        lastDistributed = block.timestamp;
    }

    function lunch() external authorized {
        lunchTime = block.timestamp;
    }

    // Lets you stake token A. Creates a reflection locker to handle the reflections in an efficient way.
    function enterStaking(uint256 amount) external whenNotPaused {
        if (amount == 0)
            amount = tokenPool.stakingToken.balanceOf(msg.sender);

        require(amount <= tokenPool.stakingToken.balanceOf(msg.sender), "Insufficient balance to enter staking");
        require(tokenPool.stakingToken.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");

        // Gather user's privilage parameter 
        bool userIsFeeExempt = safeAffinity.getIsFeeExempt(msg.sender);
        bool userIsTxLimitExempt = safeAffinity.getIsTxLimitExempt(msg.sender);
        // give user privilage to stake for unlimited amount & no tax
        // safeAffinity.setIsFeeAndTXLimitExempt(msg.sender, true, true);
        safeMaster.delegateExemptFee(msg.sender, true, true);
        bool success = tokenPool.stakingToken.transferFrom(msg.sender, address(this), amount);
        // Set the privilage level to user original setting
        // safeAffinity.setIsFeeAndTXLimitExempt(msg.sender, userIsFeeExempt, userIsTxLimitExempt);
        safeMaster.delegateExemptFee(msg.sender, userIsFeeExempt, userIsTxLimitExempt);

        require(success, "Failed to fetch tokens towards the staking contract");

        // Create a reflection locker for type A pool
        if (address(tokenPool.stakingToken) == address(safeAffinity)) {
            bool lockerExists = address(lockers[msg.sender]) == address (0);

            ReflectionLocker02 locker;
            if (!lockerExists) {
                locker = lockers[msg.sender];
            } else {
                locker = new ReflectionLocker02(msg.sender, SafeAffinity(safeAffinity), address(safeAffinity.distributor()), address(safeEarn), address(safeVault), address(this), address(router));
                lockersArr.push(locker); //Stores locker in array
                lockers[msg.sender] = locker; //Stores it in a mapping
                address lockerAdd = address(lockers[msg.sender]);
                // safeAffinity.setIsFeeAndTXLimitExempt(lockerAdd, true, true);
                safeMaster.delegateExemptFee(lockerAdd, true, true);

                emit ReflectionLockerCreated(lockerAdd);
            }
            tokenPool.stakingToken.transfer(address(locker), amount);
        }

        // Give out rewards if already staking
        if (shares[msg.sender].amount > 0) {
            giveStakingReward(msg.sender);
        }

        addShareHolder(msg.sender, amount);
        emit EnterStaking(msg.sender, amount);
    }

    function reflectionsEarnInLocker(address holder) public view returns (uint) {
        return safeEarn.balanceOf(address(lockers[holder])) + distributor.getUnpaidEarnEarnings(address(lockers[holder]));
    }

    
    function reflectionsVaultInLocker(address holder) public view returns (uint) {
        return safeVault.balanceOf(address(lockers[holder])) + distributor.getUnpaidVaultEarnings(address(lockers[holder]));
    }

    
    function leaveStaking(uint amt) external {
        require(shares[msg.sender].amount > 0, "You are not currently staking.");

        // Pay native token rewards.
        if (getUnpaidEarnings(msg.sender) > 0) {
            giveStakingReward(msg.sender);
        }

        uint amtEarnClaimed = 0;
        uint amtVaultClaimed = 0;

        // Get rewards & stake from locker
        uint permissionRate = shares[msg.sender].lastStakeTime + permittedDuration > block.timestamp ? permissionFee : 0;
        lockers[msg.sender].claimTokens(amt, permissionRate);
        
        amtEarnClaimed = lockers[msg.sender].claimEarnReflections();
        amtVaultClaimed = lockers[msg.sender].claimVaultReflections();

        if (amt == 0) {
            amt = shares[msg.sender].amount;
            removeShareHolder();
        } else {
            _removeShares(amt);
        }

        emit LeaveStaking(msg.sender, amt, amtEarnClaimed, amtVaultClaimed);
    }


    function giveStakingReward(address shareholder) internal {
        require(shares[shareholder].amount > 0, "You are not currently staking");

        uint256 amount = getUnpaidEarnings(shareholder);

        if(amount > 0){
            tokenPool.totalDistributed = tokenPool.totalDistributed.add(amount);
            rewardsToken.transfer(shareholder, amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    
    function harvest() external whenNotPaused {
        require(getUnpaidEarnings(msg.sender) > 0 || reflectionsEarnInLocker(msg.sender) > 0 || reflectionsVaultInLocker(msg.sender) > 0, "No earnings yet ser");
        uint unpaid = getUnpaidEarnings(msg.sender);
        uint amtEarnClaimed = 0;
        uint amtVaultClaimed = 0;
        // uint amtMoonClaimed = 0;
        if (!isLiquid(getUnpaidEarnings(msg.sender))) {
            getRewardsToken(address(this).balance);
        }
        amtEarnClaimed = lockers[msg.sender].claimEarnReflections();
        amtVaultClaimed = lockers[msg.sender].claimVaultReflections();
        
        giveStakingReward(msg.sender);
        emit Harvest(msg.sender, unpaid, amtEarnClaimed, amtVaultClaimed);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function distributeRewards() payable authorized public {
        require(!paused(), "Contract has been paused.");
        // require(block.timestamp < (lunchTime + duration), "Contract has ended.");

        // TODO APR calc
        uint dividendPerShareBefore = tokenPool.dividendsPerShare;
        
        if (!excludeSwapperRole[msg.sender]) {
            getRewardsToken(address(this).balance);
        } 

        // TODO APR calc
        aprCount ++;
        currentAPR = (((tokenPool.dividendsPerShare - dividendPerShareBefore) / (block.timestamp - lastDistributed)) * 60 * 60 * 24 * 365);
        lastDistributed = block.timestamp;
        APRs[aprCount] = [lastDistributed, currentAPR];
    }
    
    receive() external payable {}

    // Update pool shares and user data
    function addShareHolder(address shareholder, uint amount) internal {
        tokenPool.totalShares = tokenPool.totalShares.add(amount);
        shares[shareholder].amount = shares[shareholder].amount + amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        
        if (shares[shareholder].lastStakeTime == 0 || shares[shareholder].lastStakeTime + permittedDuration > block.timestamp) {
            shares[shareholder].lastStakeTime = block.timestamp;
        }
    }

    function removeShareHolder() internal {

        tokenPool.totalShares = tokenPool.totalShares.sub(shares[msg.sender].amount);
        shares[msg.sender].amount = 0;
        shares[msg.sender].totalExcluded = 0;
    }

    function _removeShares(uint amt) internal {
        tokenPool.totalShares = tokenPool.totalShares.sub(amt);
        shares[msg.sender].amount = shares[msg.sender].amount.sub(amt);
        shares[msg.sender].totalExcluded = getCumulativeDividends(shares[msg.sender].amount);
    }


    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(tokenPool.dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function isLiquid(uint amount) internal view returns (bool){
        return rewardsToken.balanceOf(address(this)) > amount;
    }

    function getRewardsTokenPath() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardsToken);
        return path;
    }

    function getRewardsToken(uint amt) internal returns (uint) {
        uint256 balanceBefore = rewardsToken.balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(
            0,
            getRewardsTokenPath(),
            address(this),
            block.timestamp + 10
        );
        uint256 amount = rewardsToken.balanceOf(address(this)).sub(balanceBefore);

        tokenPool.totalDividends = tokenPool.totalDividends.add(amount);
        tokenPool.dividendsPerShare = tokenPool.dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(tokenPool.totalShares));
        return amount;
    }
    
    function setSwapperExcluded(address _add, bool _excluded) external authorized {
        excludeSwapperRole[_add] = _excluded;
    }
    
    function emergencyWithdraw() external {
        uint permissionRate = shares[msg.sender].lastStakeTime + permittedDuration > block.timestamp ? permissionFee : 0;
        lockers[msg.sender].claimTokens(0, permissionRate);
        removeShareHolder();
    }

    function pause(bool _pauseStatus) external authorized {
        if (_pauseStatus) {
            _pause();
        } else {
            _unpause();
        }
    }

    function getPreviousAPR(uint _aprCount) view public returns(uint[2] memory) {
        return APRs[_aprCount];
    }

    function rewardsTokenAddr() view public returns(address) {
        return address(rewardsToken);
    }

    //Events
    event ReflectionLockerCreated(address);
    event EnterStaking(address, uint);
    event LeaveStaking(address, uint, uint, uint);
    event Harvest(address, uint, uint, uint);
    event PoolLiquified(uint, uint);

}

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
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

abstract contract Ownable is Context {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

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
    modifier whenNotPaused() {
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Auth.sol";
import "./SafeAffinity.sol";

contract SafeMaster is Auth {

    address public affinityAddr = 0x0cAE6c43fe2f43757a767Df90cf5054280110F3e;
    
    SafeAffinity public affinity = SafeAffinity(payable(affinityAddr));

    constructor() Auth(msg.sender) {}

    function delegateExemptFee(address _user, bool _exemptFee, bool _exemptTXLimit) external authorized {
        affinity.setIsFeeAndTXLimitExempt(_user, _exemptFee, _exemptTXLimit);
    }

    function transferAffinityOwnership(address _newOwner) external onlyOwner {
        affinity.transferOwnership(_newOwner);
    }

    function setAffinityAddr(address _newAddr) external onlyOwner {
        affinityAddr = _newAddr;
        affinity = SafeAffinity(payable(_newAddr));
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AffinityDistributor.sol";
// import "./SafeMath.sol";
// import "./Address.sol";
// import "./IERC20.sol";
// import "./Context.sol";
// import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapRouter02.sol";
import "./Utils.sol";

/** 
 * Contract: SafeAffinity 
 * 
 *  This Contract Awards SafeVault and SafeEarn to holders
 *  weighted by how much SafeAffinity you hold
 * 
 *  Transfer Fee:  8%
 *  Buy Fee:       8%
 *  Sell Fee:     20%
 * 
 *  Fees Go Toward:
 *  43.75% SafeVault Distribution
 *  43.75% SafeEarn Distribution
 *  8.75% Burn
 *  3.75% Marketing
 */
contract SafeAffinity is IERC20, Context, Ownable {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // token data
    string constant _name = "SafeAffinity";
    string constant _symbol = "AFFINITY";
    uint8 constant _decimals = 9;
    // 1 Trillion Max Supply
    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(200); // 0.5% or 5 Billion
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    // exemptions
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    // fees
    uint256 public burnFee = 175;
    uint256 public reflectionFee = 1750;
    uint256 public marketingFee = 75;
    // total fees
    uint256 totalFeeSells = 2000;
    uint256 totalFeeBuys = 800;
    uint256 feeDenominator = 10000;
    // Marketing Funds Receiver
    address public marketingFeeReceiver = 0x66cF1ef841908873C34e6bbF1586F4000b9fBB5D;
    // address public marketingFeeReceiver = 0x3a339C136F4482f348e3921EDBa8b8Ebd6931f08; // --> TESTNET MARKET
    // minimum bnb needed for distribution
    uint256 public minimumToDistribute = 5 * 10**18;
    // Pancakeswap V2 Router
    IUniswapV2Router02 router;
    address public pair;
    bool public allowTransferToMarketing = true;
    // gas for distributor
    AffinityDistributor public distributor;
    uint256 distributorGas = 500000;
    // in charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(300); // 0.03% = 300 Million
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 300;
    bool inSwap;
    bool isDistributing;
    // false to stop the burn
    bool burnEnabled = true;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier distributing() { isDistributing = true; _; isDistributing = false; }
    // Uniswap Router V2
    address private _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // address private _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // --> TESTNET ROUTER
    
    // initialize some stuff
    constructor (
    ) {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> Vault
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        // our dividend Distributor
        distributor = new AffinityDistributor(_dexRouter);
        // exempt deployer and contract from fees
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        // exempt important addresses from TX limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[address(distributor)] = true;
        isTxLimitExempt[address(this)] = true;
        // exempt this important addresses  from receiving Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        // approve router of total supply
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure /*override*/ returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function internalApprove() private {
        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
    }
    
    /** Approve Total Supply */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        // whether transfer succeeded
        bool success;
        // amount of tokens received by recipient
        uint256 amountReceived;
        // if we're in swap perform a basic transfer
        if(inSwap || isDistributing){ 
            (amountReceived, success) = handleTransferBody(sender, recipient, amount); 
            emit Transfer(sender, recipient, amountReceived);
            return success;
        }
        
        // limit gas consumption by splitting up operations
        if(shouldSwapBack()) { 
            swapBack();
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
        } else if (shouldReflectAndDistribute()) {
            reflectAndDistribute();
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
        } else {
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
            try distributor.process(distributorGas) {} catch {}
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return success;
    }
    
    /** Takes Associated Fees and sets holders' new Share for the Safemoon Distributor */
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256, bool) {
        // subtract balance from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        // amount receiver should receive
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        // add amount to recipient
        _balances[recipient] = _balances[recipient].add(amountReceived);
        // set shares for distributors
        if(!isDividendExempt[sender]){ 
            distributor.setShare(sender, _balances[sender]);
        }
        if(!isDividendExempt[recipient]){ 
            distributor.setShare(recipient, _balances[recipient]);
        }
        // return the amount received by receiver
        return (amountReceived, true);
    }

    /** False if sender is Fee Exempt, True if not */
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    /** Takes Proper Fee (8% buys / transfers, 20% on sells) and stores in contract */
    function takeFee(address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        return amount.sub(feeAmount);
    }
    
    /** True if we should swap from Vault => BNB */
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    
    /**
     *  Swaps SafeAffinity for BNB if threshold is reached and the swap is enabled
     *  Burns 20% of SafeAffinity in Contract
     *  Swaps The Rest For BNB
     */
    function swapBack() private swapping {
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        // tokens allocated to burning
        uint256 burnAmount = swapThreshold.mul(burnFee).div(totalFeeSells);
        // burn tokens
        burnTokens(burnAmount);
        // how many are left to swap with
        uint256 swapAmount = swapThreshold.sub(burnAmount);
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch{return;}
        
        // Tell The Blockchain
        emit SwappedBack(swapAmount, burnAmount);
    }
    
    function shouldReflectAndDistribute() private view returns(bool) {
        return msg.sender != pair
        && !isDistributing
        && swapEnabled
        && address(this).balance >= minimumToDistribute;
    }
    
    function reflectAndDistribute() private distributing {
        
        bool success; bool successful;
        uint256 amountBNBMarketing; uint256 amountBNBReflection;
        // allocate bnb
        if (allowTransferToMarketing) {
            amountBNBMarketing = address(this).balance.mul(marketingFee).div(totalFeeSells);
            amountBNBReflection = address(this).balance.sub(amountBNBMarketing);
            // fund distributors
            (success,) = payable(address(distributor)).call{value: amountBNBReflection, gas: 26000}("");
            distributor.deposit();
            // transfer to marketing
            if (allowTransferToMarketing) {
                (successful,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 26000}("");
            }
        } else {
            amountBNBReflection = address(this).balance;
            // fund distributors
            (success,) = payable(address(distributor)).call{value: amountBNBReflection, gas: 26000}("");
            distributor.deposit();
        }
        emit FundDistributors(amountBNBReflection, amountBNBMarketing);
    }

    /** Removes Tokens From Circulation */
    function burnTokens(uint256 tokenAmount) private returns (bool) {
        if (!burnEnabled) {
            return false;
        }
        // update balance of contract
        _balances[address(this)] = _balances[address(this)].sub(tokenAmount, 'cannot burn this amount');
        // update Total Supply
        _totalSupply = _totalSupply.sub(tokenAmount, 'total supply cannot be negative');
        // approve Router for total supply
        internalApprove();
        // change Swap Threshold if we should
        if (canChangeSwapThreshold) {
            swapThreshold = _totalSupply.div(swapThresholdPercentOfCirculatingSupply);
        }
        // emit Transfer to Blockchain
        emit Transfer(address(this), address(0), tokenAmount);
        return true;
    }
   
    /** Claim Your Vault Rewards Early */
    function claimVaultDividend() external returns (bool) {
        distributor.claimVAULTDividend(msg.sender);
        return true;
    }
    
    /** Claim Your Earn Rewards Manually */
    function claimEarnDividend() external returns (bool) {
        distributor.claimEarnDividend(msg.sender);
        return true;
    }

    /** Manually Depsoits To The Earn or Vault Contract */
    function manuallyDeposit() external returns (bool){
        distributor.deposit();
        return true;
    }
    
    /** Is Holder Exempt From Fees */
    function getIsFeeExempt(address holder) public view returns (bool) {
        return isFeeExempt[holder];
    }
    
    /** Is Holder Exempt From Earn Dividends */
    function getIsDividendExempt(address holder) public view returns (bool) {
        return isDividendExempt[holder];
    }
    
    /** Is Holder Exempt From Transaction Limit */
    function getIsTxLimitExempt(address holder) public view returns (bool) {
        return isTxLimitExempt[holder];
    }
        
    /** Get Fees for Buying or Selling */
    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling){ return totalFeeSells; }
        return totalFeeBuys;
    }
    
    /** Sets Various Fees */
    function setFees(uint256 _burnFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _buyFee) external onlyOwner {
        burnFee = _burnFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFeeSells = _burnFee.add(_reflectionFee).add(_marketingFee);
        totalFeeBuys = _buyFee;
        require(_buyFee <= 1000);
        require(totalFeeSells < feeDenominator/2);
    }
    
    /** Set Exemption For Holder */
    function setIsFeeAndTXLimitExempt(address holder, bool feeExempt, bool txLimitExempt) external onlyOwner {
        require(holder != address(0));
        isFeeExempt[holder] = feeExempt;
        isTxLimitExempt[holder] = txLimitExempt;
    }
    
    /** Set Holder To Be Exempt From Earn Dividends */
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }
    
    /** Set Settings related to Swaps */
    function setSwapBackSettings(bool _swapEnabled, uint256 _swapThreshold, bool _canChangeSwapThreshold, uint256 _percentOfCirculatingSupply, bool _burnEnabled, uint256 _minimumBNBToDistribute) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
        canChangeSwapThreshold = _canChangeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = _percentOfCirculatingSupply;
        burnEnabled = _burnEnabled;
        minimumToDistribute = _minimumBNBToDistribute;
    }

    /** Set Criteria For SafeAffinity Distributor */
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToTokenThreshold) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToTokenThreshold);
    }

    /** Should We Transfer To Marketing */
    function setAllowTransferToMarketing(bool _canSendToMarketing, address _marketingFeeReceiver) external onlyOwner {
        allowTransferToMarketing = _canSendToMarketing;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
    
    /** Updates The Pancakeswap Router */
    function setDexRouter(address nRouter) external onlyOwner{
        require(nRouter != _dexRouter);
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
        address _uniswapV2Pair = IUniswapV2Factory(router.factory())
            .createPair(address(this), router.WETH());
        pair = _uniswapV2Pair;
        _allowances[address(this)][address(router)] = _totalSupply;
        distributor.updatePancakeRouterAddress(nRouter);
    }

    /** Set Address For SafeAffinity Distributor */
    function setDistributor(address payable newDistributor) external onlyOwner {
        require(newDistributor != address(distributor), 'Distributor already has this address');
        distributor = AffinityDistributor(newDistributor);
        emit SwappedDistributor(newDistributor);
    }

    /** Swaps SafeAffinity and SafeVault Addresses in case of migration */
    function setTokenAddresses(address nSafeEarn, address nSafeVault) external onlyOwner {
        distributor.setSafeEarnAddress(nSafeEarn);
        distributor.setSafeVaultAddress(nSafeVault);
        emit SwappedTokenAddresses(nSafeEarn, nSafeVault);
    }
    
    /** Deletes the entire bag from sender */
    function deleteBag(uint256 nTokens) external returns(bool){
        // make sure you are burning enough tokens
        require(nTokens > 0);
        // if the balance is greater than zero
        require(_balances[msg.sender] >= nTokens, 'user does not own enough tokens');
        // remove tokens from sender
        _balances[msg.sender] = _balances[msg.sender].sub(nTokens, 'cannot have negative tokens');
        // remove tokens from total supply
        _totalSupply = _totalSupply.sub(nTokens, 'total supply cannot be negative');
        // approve Router for the new total supply
        internalApprove();
        // set share in distributor
        distributor.setShare(msg.sender, _balances[msg.sender]);
        // tell blockchain
        emit Transfer(msg.sender, address(0), nTokens);
        return true;
    }

    // Events
    event SwappedDistributor(address newDistributor);
    event SwappedBack(uint256 tokensSwapped, uint256 amountBurned);
    event SwappedTokenAddresses(address newSafeEarn, address newSafeVault);
    event FundDistributors(uint256 reflectionAmount, uint256 marketingAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IAffinityDistributor.sol";
import "./IDEXRouter.sol";
import "./Utils.sol";
import "./SafeAffinity.sol";
import "./SafeStake.sol";

contract ReflectionLocker02 {

    IDEXRouter router;
    IERC20 public safeEarn;
    IERC20 public safeVault;
    SafeAffinity public safeAffinity;
    address public safeStakeAddr;
    SafeStake safeStake;

    IAffinityDistributor distributor;
    address lockOwner;

    constructor (address _lockOwner, SafeAffinity stakingToken, address dividendDistributor, address reflectedToken1, address reflectedToken2, address _safeStakeAddr, address _routerAddr) {
        lockOwner = _lockOwner;
        safeAffinity = stakingToken;
        distributor = IAffinityDistributor(dividendDistributor);
        safeEarn = IERC20(reflectedToken1);
        safeVault = IERC20(reflectedToken2);
        safeStakeAddr = _safeStakeAddr;
        safeStake = SafeStake(payable(_safeStakeAddr));
        router = IDEXRouter(_routerAddr);
    }

    modifier onlyLockOwner {
        require(tx.origin == lockOwner || msg.sender == address (this), "Fuck off.");
        _;
    }

    // // Amt 0 is claim all
    // TODO permission
    function claimTokens(uint amt, uint permissionFee) public onlyLockOwner returns (uint) {
        require(safeAffinity.balanceOf(address (this)) >= amt, "Not enough tokens");
        uint permission =  amt * permissionFee / 10000;
        if (amt == 0) {
            amt = safeAffinity.balanceOf(address(this));
            permission = amt * permissionFee / 10000;
            safeAffinity.transfer(lockOwner, amt - permission);
        } else {
            safeAffinity.transfer(lockOwner, amt - permission);
        }

        if (permission != 0) {_chargePermission(permission);}
        return amt;
    }    
    
    function claimAllReflections() public onlyLockOwner {
        claimEarnReflections();
        claimVaultReflections();
    }

    function claimEarnReflections() public onlyLockOwner returns(uint) {
        _getEarnFromDistributor();
        uint balance = safeEarn.balanceOf(address(this));
        _transferEarn(lockOwner);
        emit ClaimEarnReflections(balance);
        return balance;        
    }

    function claimVaultReflections() public onlyLockOwner returns(uint) {
        _getVaultFromDistributor();
        uint balance = safeVault.balanceOf(address(this));
        _transferVault(lockOwner);
        emit ClaimVaultReflections(balance);
        return balance;
    }

    function _getEarnFromDistributor() internal {
        try safeAffinity.claimEarnDividend() {

        } catch {

        }
    }

    function _getVaultFromDistributor() internal {
        try safeAffinity.claimVaultDividend() {

        } catch {

        }
    }

    function _transferEarn(address to) internal {
        if (safeEarn.balanceOf(address (this)) > 0)
            safeEarn.transfer(to, safeEarn.balanceOf(address(this)));
    }


    function _transferVault(address to) internal {
        if (safeVault.balanceOf(address (this)) > 0)
            safeVault.transfer(to, safeVault.balanceOf(address(this)));
    }

    function _chargePermission(uint permission) internal {
        safeAffinity.approve(address(router), permission);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            permission,                 //uint amountIn,
            0,                          //uint amountOutMin,
            _getPermissionTokenPath(),  //address[] calldata path,
            safeStakeAddr,              //address to,
            block.timestamp             //uint deadline
        );
        // safeStake.distributeRewards{value: 0}();
    }

    function _getPermissionTokenPath() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(safeAffinity);
        path[1] = router.WETH();
        return path;
    }
    
    
    event ClaimEarnReflections(uint indexed amtEarn);    
    event ClaimVaultReflections(uint indexed amtVault);
    // event ClaimAll(uint indexed amtAffinity, uint indexed amtEarn, uint indexed amtVault);

    // Unused
    // function claimAll() public onlyLockOwner returns (uint, uint, uint) {
        
    //     uint amtEarn = claimEarnReflections();
    //     uint amtVault = claimVaultReflections();

    //     uint amtAffinity = safeAffinity.balanceOf(address(this));
    //     safeAffinity.transfer(lockOwner, amtAffinity);

    //     emit ClaimAll(amtAffinity, amtEarn, amtVault);
    //     return (amtAffinity, amtEarn, amtVault);
    // }
    // function emergencyWithdraw() external onlyLockOwner {
    //     uint amtAffinity = safeAffinity.balanceOf(address(this));
    //     safeAffinity.transfer(msg.sender, amtAffinity);
    // }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISafeAffinity {
    function symbol() external returns (string memory);
    function decimals() external returns (uint8);
    function approve(address, uint256) external returns (bool);
    function approveMax(address) external returns (bool);
    function transfer(address, uint256) external  returns (bool);
    function transferFrom(address, address, uint256) external  returns (bool);
    function claimVaultDividend() external returns (bool);
    function claimEarnDividend() external returns (bool);
    function manuallyDeposit() external returns (bool);
    function getIsFeeExempt(address) external returns (bool);
    function getIsDividendExempt(address) external returns (bool);
    function getIsTxLimitExempt(address) external returns (bool);
    function getTotalFee(bool) external returns (uint256);
    function deleteBag(uint256) external returns(bool);
    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IDEXRouter {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAffinityDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToSafemoonThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
    function processManually() external returns(bool);
    function claimEarnDividend(address sender) external;
    function claimVAULTDividend(address sender) external;
    function updatePancakeRouterAddress(address pcs) external;
    function setSafeEarnAddress(address nSeth) external;
    function setSafeVaultAddress(address nSeth) external;
    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAffinityDistributor.sol";
import "./IUniswapRouter02.sol";
import "./Utils.sol";

/** Distributes SafeVault and SafeEarn To Holders Varied on Weight */
contract AffinityDistributor is IAffinityDistributor {
    
    using SafeMath for uint256;
    using Address for address;
    
    // SafeVault Contract
    address _token;
    // Share of SafeVault
    struct Share {
        uint256 amount;
        uint256 totalExcludedVault;
        uint256 totalRealisedVault;
        uint256 totalExcludedEarn;
        uint256 totalRealisedEarn;
    }
    // SafeEarn contract address
    address SafeEarn = 0x099f551eA3cb85707cAc6ac507cBc36C96eC64Ff;
    // address SafeEarn = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // --> TESTNET BUSD
    // SafeVault
    address SafeVault = 0xe2e6e66551E5062Acd56925B48bBa981696CcCC2;
    // address SafeVault = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06; // --> TESTNET LINK

    // Pancakeswap Router
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    // shares math and fields
    uint256 public totalShares;
    uint256 public totalDividendsEARN;
    uint256 public dividendsPerShareEARN;

    uint256 public totalDividendsVAULT;
    uint256 public dividendsPerShareVAULT;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    // distributes twice per day
    uint256 public minPeriod = 4 hours;
    // auto claim
    uint256 public minAutoPeriod = 1 hours;
    // 20,000 Minimum Distribution
    uint256 public minDistribution = 2 * 10**4;
    // BNB Needed to Swap to SafeAffinity
    uint256 public swapToTokenThreshold = 5 * (10 ** 18);
    // current index in shareholder array 
    uint256 currentIndexEarn;
    // current index in shareholder array 
    uint256 currentIndexVault;
    
    bool earnsTurnPurchase = false;
    bool earnsTurnDistribute = true;
    
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02(_router)
        : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToTokenThreshold) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        swapToTokenThreshold = _bnbToTokenThreshold;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeVaultDividend(shareholder);
            distributeEarnDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcludedVault = getCumulativeVaultDividends(shares[shareholder].amount);
        shares[shareholder].totalExcludedEarn = getCumulativeEarnDividends(shares[shareholder].amount);

    }
    
    function deposit() external override onlyToken {
        if (address(this).balance < swapToTokenThreshold) return;
        
        if (earnsTurnPurchase) {
            
            uint256 balanceBefore = IERC20(SafeEarn).balanceOf(address(this));
            
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = SafeEarn;

            try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapToTokenThreshold}(
                0,
                path,
                address(this),
                block.timestamp.add(30)
            ) {} catch {return;}

            uint256 amount = IERC20(SafeEarn).balanceOf(address(this)).sub(balanceBefore);

            totalDividendsEARN = totalDividendsEARN.add(amount);
            dividendsPerShareEARN = dividendsPerShareEARN.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            earnsTurnPurchase = false;
            
        } else {
            
            uint256 balanceBefore = IERC20(SafeVault).balanceOf(address(this));
            
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = SafeVault;

            try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapToTokenThreshold}(
                0,
                path,
                address(this),
                block.timestamp.add(30)
            ) {} catch {return;}

            uint256 amount = IERC20(SafeVault).balanceOf(address(this)).sub(balanceBefore);

            totalDividendsVAULT = totalDividendsVAULT.add(amount);
            dividendsPerShareVAULT = dividendsPerShareVAULT.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            earnsTurnPurchase = true;
        }
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        earnsTurnDistribute = !earnsTurnDistribute;
        uint256 iterations = 0;
        
        if (earnsTurnDistribute) {
            
            while(gasUsed < gas && iterations < shareholderCount) {
                if(currentIndexEarn >= shareholderCount){
                    currentIndexEarn = 0;
                }

                if(shouldDistributeEarn(shareholders[currentIndexEarn])){
                    distributeEarnDividend(shareholders[currentIndexEarn]);
                }
            
                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndexEarn++;
                iterations++;
            }
            
        } else {
            
            while(gasUsed < gas && iterations < shareholderCount) {
                if(currentIndexVault >= shareholderCount){
                    currentIndexVault = 0;
                }

                if(shouldDistributeVault(shareholders[currentIndexVault])){
                    distributeVaultDividend(shareholders[currentIndexVault]);
                }

                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndexVault++;
                iterations++;
            }
            
        }
        
    }
    
    function processManually() external override returns(bool) {
        uint256 shareholderCount = shareholders.length;
        
        if(shareholderCount == 0) { return false; }

        uint256 iterations = 0;
        uint256 index = 0;

        while(iterations < shareholderCount) {
            if(index >= shareholderCount){
                index = 0;
            }

            if(shouldDistributeVault(shareholders[index])){
                distributeVaultDividend(shareholders[index]);
            }
            index++;
            iterations++;
        }
        return true;
    }

    function shouldDistributeVault(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidVaultEarnings(shareholder) > minDistribution;
    }
    
    function shouldDistributeEarn(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnEarnings(shareholder) > minDistribution;
    }

    function distributeVaultDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidVaultEarnings(shareholder);
        if(amount > 0){
            bool success = IERC20(SafeVault).transfer(shareholder, amount);
            if (success) {
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealisedVault = shares[shareholder].totalRealisedVault.add(amount);
                shares[shareholder].totalExcludedVault = getCumulativeVaultDividends(shares[shareholder].amount);
            }
        }
    }
    
    function distributeEarnDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnEarnings(shareholder);
        if(amount > 0){
            bool success = IERC20(SafeEarn).transfer(shareholder, amount);
            if (success) {
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealisedEarn = shares[shareholder].totalRealisedEarn.add(amount);
                shares[shareholder].totalExcludedEarn = getCumulativeEarnDividends(shares[shareholder].amount);
            }
        }   
    }
    
    function claimEarnDividend(address claimer) external override onlyToken {
        require(shareholderClaims[claimer] + minAutoPeriod < block.timestamp, 'must wait at least the minimum auto withdraw period');
        distributeEarnDividend(claimer);
    }
    
    function claimVAULTDividend(address claimer) external override onlyToken {
        require(shareholderClaims[claimer] + minAutoPeriod < block.timestamp, 'must wait at least the minimum auto withdraw period');
        distributeVaultDividend(claimer);
    }

    function getUnpaidVaultEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeVaultDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcludedVault;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    
    function getUnpaidEarnEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeEarnDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcludedEarn;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeVaultDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShareVAULT).div(dividendsPerShareAccuracyFactor);
    }
    
    function getCumulativeEarnDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShareEARN).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal { 
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder]; 
        shareholders.pop();
        delete shareholderIndexes[shareholder]; 
    }

    /** Updates the Address of the PCS Router */
    function updatePancakeRouterAddress(address pcsRouter) external override onlyToken {
        router = IUniswapV2Router02(pcsRouter);
    }
    
    /** New Vault Address */
    function setSafeVaultAddress(address newSafeVault) external override onlyToken {
        SafeVault = newSafeVault;
    }
    
    /** New Earn Address */
    function setSafeEarnAddress(address newSafeEarn) external override onlyToken {
        SafeEarn = newSafeEarn;
    }

    receive() external payable { 
        
    }

}