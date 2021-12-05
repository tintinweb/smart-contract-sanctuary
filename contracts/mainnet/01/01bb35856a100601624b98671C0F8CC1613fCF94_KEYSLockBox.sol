//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ReentrantGuard.sol";
import "./IKeysStaking.sol";

/**
 *
 * KEYS Token Locking Contract
 * Contract Developed By DeFi Mark (MoonMark)
 *
 */
contract KEYSLockBox is ReentrancyGuard, IERC20, IKeysStaking{

    using SafeMath for uint256;
    using Address for address;
    
    // KEYS Contract
    address constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    // precision factor
    uint256 constant precision = 10**36;
    
    // Total Dividends Per Farm
    uint256 public dividendsPerToken;
 
    // 88 day lock time
    uint256 public lockTime = 633600;
    
    // Locker Structure
    struct StakedUser {
        uint256 tokensLocked;
        uint256 timeLocked;
        uint256 lastClaim;
        uint256 totalExcluded;
    }
    
    // Users -> StakedUser
    mapping ( address => StakedUser ) users;
    
    // total locked across all lockers
    uint256 totalLocked;
    
    // minimum stake amount
    uint256 public minToStake = 100 * 10**9;
    
    // reduced purchase fee
    uint256 public fee = 20;
    
    // fee for unstaking too early
    uint256 public earlyFee = 80;
    
    // multisignature wallet
    address public multisig = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;
    
    // Ownership
    address public owner;
    modifier onlyOwner(){require(owner == msg.sender, 'Only Owner'); _;}
    
    // Events
    event TransferOwnership(address newOwner);
    event UpdateFee(uint256 newFee);
    event UpdateLockTime(uint256 newTime);
    event UpdatedStakingMinimum(uint256 minimumKeys);
    event UpdatedFeeReceiver(address feeReceiver);
    event UpdatedEarlyFee(uint256 newFee);
    
    constructor() {
        owner = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;
    }
    
    function totalSupply() external view override returns (uint256) { return totalLocked; }
    function balanceOf(address account) public view override returns (uint256) { return users[account].tokensLocked; }
    function allowance(address holder, address spender) external view override returns (uint256) { return holder == spender ? balanceOf(holder) : 0; }
    function name() public pure override returns (string memory) {
        return "Locked Keys";
    }
    function symbol() public pure override returns (string memory) {
        return "LOCKEDKEYS";
    }
    function decimals() public pure override returns (uint8) {
        return 9;
    }
    function approve(address spender, uint256 amount) public view override returns (bool) {
        return users[msg.sender].tokensLocked >= amount && spender != msg.sender;
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        // ensure claim requirements
        if (recipient == KEYS) {
            _unlock(msg.sender, msg.sender, amount);
        } else if (recipient == address(this)){
            _reinvestKeys(msg.sender);
        } else {
            _makeClaim(msg.sender);
        }
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (recipient == KEYS) {
            _unlock(msg.sender, msg.sender, amount);
        } else if (recipient == address(this)){
            _reinvestKeys(msg.sender);
        } else {
            _makeClaim(msg.sender);
        }
        return true && sender == recipient;
    }
    
    
    ///////////////////////////////////
    //////    OWNER FUNCTIONS   ///////
    ///////////////////////////////////

    function updateState(address[] calldata oldStakers) external onlyOwner {

        address old = 0xF09504B63a199158312807c5f05DaEcA734855D9;
        for (uint i = 0; i < oldStakers.length; i++) {
            users[oldStakers[i]].tokensLocked = IERC20(old).balanceOf(oldStakers[i]);
            users[oldStakers[i]].timeLocked = block.number - 60000;
        }
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit TransferOwnership(newOwner);
    }
    
    function updateFee(uint256 newFee) external onlyOwner {
        fee = newFee;
        emit UpdateFee(newFee);
    }
    
    function updateFeeReceiver(address newReceiver) external onlyOwner {
        multisig = newReceiver;
        emit UpdatedFeeReceiver(newReceiver);
    }
    
    function setEarlyFee(uint256 newFee) external onlyOwner {
        earlyFee = newFee;
        emit UpdatedEarlyFee(newFee);
    }
    
    function setMinimumToStake(uint256 minimum) external onlyOwner {
        minToStake = minimum;
        emit UpdatedStakingMinimum(minimum);
    }
    
    function setLockTime(uint256 newTime) external onlyOwner {
        require(newTime <= 10**6, 'Lock Time Too Long');
        lockTime = newTime;
        emit UpdateLockTime(newTime);
    }
    
    function withdraw(bool eth, address token, uint256 amount, address recipient) external onlyOwner {
        if (eth) {
            require(address(this).balance >= amount, 'Insufficient Balance');
            (bool s,) = payable(recipient).call{value: amount}("");
            require(s, 'Failure on ETH Withdrawal');
        } else {
            require(token != KEYS, 'Cannot Withdraw Keys');
            IERC20(token).transfer(recipient, amount);
        }
    }
    
    
    ///////////////////////////////////
    //////   PUBLIC FUNCTIONS   ///////
    ///////////////////////////////////

    /** Adds KEYS To The Pending Rewards Of KEYS Stakers */
    function deposit(uint256 amount) external override {
        uint256 received = _transferIn(amount);
        dividendsPerToken += received.mul(precision).div(totalLocked);
    }

    function claimReward() external nonReentrant {
        _makeClaim(msg.sender);      
    }
    
    function claimRewardForUser(address user) external nonReentrant {
        _makeClaim(user);
    }
    
    function unlock(uint256 amount) external nonReentrant {
        _unlock(msg.sender, msg.sender, amount);
    }
    
    function unlockFor(uint256 amount, address keysRecipient) external nonReentrant {
        _unlock(msg.sender, keysRecipient, amount);
    }
    
    function unlockAll() external nonReentrant {
        _unlock(msg.sender, msg.sender, users[msg.sender].tokensLocked);
    }
    
    function stakeKeys(uint256 numKeys) external nonReentrant {
        uint256 received = _transferIn(numKeys);
        require(received >= minToStake, 'Minimum To Stake Not Reached');
        _lock(msg.sender, received);
    }

    function reinvestKeys() external nonReentrant {
        _reinvestKeys(msg.sender);
    }

    function _reinvestKeys(address user) internal {

        uint256 amount = pendingRewards(user);
        require(amount > 0, 'Zero Amount');

        // set locker data
        users[user].tokensLocked += amount;
        users[user].lastClaim = block.number;
        users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        
        // increment total locked
        totalLocked += amount;
        
        // Transfer StakedKeys
        emit Transfer(address(0), user, amount);
    }
    
    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    function _makeClaim(address user) internal {
        // ensure claim requirements
        require(users[user].tokensLocked > 0, 'Zero Tokens Locked');
        require((users[user].lastClaim + 10) < block.number, 'Claim Wait Time Not Reached');
        
        uint256 amount = pendingRewards(user);
        require(amount > 0,'Zero Rewards');
        _claimReward(user);
    }
    
    function _claimReward(address user) internal {
        
        uint256 amount = pendingRewards(user);
        if (amount == 0) return;
        
        // update claim stats 
        users[user].lastClaim = block.number;
        users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        // transfer tokens
        bool s = IERC20(KEYS).transfer(user, amount);
        require(s,'Failure On Token Transfer');
    }
    
    function _transferIn(uint256 amount) internal returns (uint256) {
        
        uint256 before = IERC20(KEYS).balanceOf(address(this));
        bool s = IERC20(KEYS).transferFrom(msg.sender, address(this), amount);
        
        uint256 difference = IERC20(KEYS).balanceOf(address(this)).sub(before);
        require(s && difference <= amount, 'Error On Transfer In');
        return difference;
    }
    
    function _buyKeys() internal returns (uint256) {
        
        uint256 feeAmount = msg.value.mul(fee).div(1000);
        uint256 purchaseAmount = msg.value.sub(feeAmount);
        
        (bool success,) = payable(multisig).call{value: feeAmount}("");
        require(success, 'Failure on Dev Payment');
        
        uint256 before = IERC20(KEYS).balanceOf(address(this));
        (bool s,) = payable(KEYS).call{value: purchaseAmount}("");
        require(s, 'Failure on KEYS Purchase');
        return IERC20(KEYS).balanceOf(address(this)).sub(before);
    }
    
    function _lock(address user, uint256 received) private {
        
        if (users[user].tokensLocked > 0) { // recurring locker
            _claimReward(user);
        } else { // new user
            users[user].lastClaim = block.number;
        }
        
        // add locker data
        users[user].tokensLocked += received;
        users[user].timeLocked = block.number;
        users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        
        // increment total locked
        totalLocked += received;
        
        emit Transfer(address(0), user, received);
    }

    function _unlock(address user, address recipient, uint256 nTokens) private {
        
        // Ensure Lock Requirements
        require(users[user].tokensLocked > 0, 'Zero Tokens Locked');
        require(users[user].tokensLocked >= nTokens && nTokens > 0, 'Insufficient Tokens');
        
        // expiration
        uint256 lockExpiration = users[user].timeLocked + lockTime;
        
        // claim reward 
        _claimReward(user);
        
        // Update Staked Balances
        if (users[user].tokensLocked == nTokens) {
            delete users[user]; // Free Storage
        } else {
            users[user].tokensLocked = users[user].tokensLocked.sub(nTokens, 'Insufficient Lock Amount');
            users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        }
        
        // Update Total Locked
        totalLocked = totalLocked.sub(nTokens, 'Negative Locked');

        // Calculate Tokens To Send Recipient
        uint256 tokensToSend = lockExpiration > block.number ? _calculateAndReflect(nTokens) : nTokens;

        // Transfer KEYS Tokens To User
        bool s = IERC20(KEYS).transfer(recipient, tokensToSend);
        require(s, 'Failure on LP Token Transfer');

        // tell Blockchain
        emit Transfer(user, address(0), nTokens);
    }
    
    function _calculateAndReflect(uint256 nTokens) internal returns (uint256) {
        
        // apply early leave tax
        uint256 tax = nTokens.mul(earlyFee).div(1000);
        
        // Reflect Tax To KEYS Stakers
        dividendsPerToken += tax.mul(precision).div(totalLocked);
        
        // Return Send Amount
        return nTokens.sub(tax);
    }
    
    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////
    
    
    function getTimeUntilUnlock(address user) external view returns (uint256) {
        uint256 endTime = users[user].timeLocked + lockTime;
        return endTime > block.number ? endTime.sub(block.number) : 0;
    }
    
    function currentDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerToken).div(precision);
    }
    
    function pendingRewards(address user) public view returns (uint256) {
        uint256 amount = users[user].tokensLocked;
        if(amount == 0){ return 0; }

        uint256 shareholderTotalDividends = currentDividends(amount);
        uint256 shareholderTotalExcluded = users[user].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    
    function totalPendingRewards() external view returns (uint256) {
        return IERC20(KEYS).balanceOf(address(this)).sub(totalLocked);
    }
    
    function calculateKEYSBalance(address user) external view returns (uint256) {
        return IERC20(KEYS).balanceOf(user);
    }
    
    function calculateKEYSContractBalance() external view returns (uint256) {
        return IERC20(KEYS).balanceOf(address(this));
    }

    receive() external payable {
        uint256 received = _buyKeys();
        require(received >= minToStake, 'Minimum To Stake Not Reached');
        _lock(msg.sender, received);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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
        assembly {
            codehash := extcodehash(account)
        }
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * Exempt Surge Interface
 */
interface IKeysStaking {
    function deposit(uint256 amount) external;
}