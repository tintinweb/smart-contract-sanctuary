/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: UNLICENSED
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


contract BotTradingBNB is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    uint256 private totalFee = 0;
    uint256 public depositFee = 7;
    uint256 public withdrawFee = 2;
    uint256 public claimFee = 2;
    uint256 public redistroRate = 3;
    uint256 public minDeposit;
    bool public locked = false;
    uint256 public totalStake = 0;
    uint256 public rewardPerToken = 0;
    mapping(address => uint256) public stake;
    mapping(address => int256) public rewardTally;
    mapping(address => uint256) public addressToId;
    mapping(uint256 => address) public idToAddress;
    uint256 idCount = 1;
    uint256 public participatorCount = 0;

    modifier onlyUnlock {
        require(!locked, "This contract is locked");
        _;
    }

    constructor(uint256 _minDeposit) {
        minDeposit = _minDeposit;
    }
    
    event staked(address _staker, uint256 _stakedAmt, uint256 _feeAmt, uint256 _redistroAmt);
    event rewardInput(uint256 _inputTime, uint256 _amount);
    event withdrawn(address _user, uint256 _amount);
    event minDepositSet(uint256 _newAmt);
    event withdrawFeeSet(uint256 _newFee);
    event depositFeeSet(uint256 _newFee);
    event claimFeeSet(uint256 _newFee);
    event redistroRateSet(uint256 _newFee);
    event lockStatusSet(bool _newVal);
    event redistrobuted(uint256 _inputTime, uint256 _amount);
    event rewardWithdrawn(address _user, uint256 _amount);
    event reInvested(address _user, uint256 _amount);
    

    // User functionality
    function depositStake() payable public onlyUnlock {
        uint256 _amount = msg.value;

        uint256 feeAmt = calcDepositFeeAmt(_amount);
        uint256 redistroAmt = calcRedistroAmt(_amount);

        if (stake[msg.sender] < 1e-5 ether) {
            participatorCount = participatorCount + 1 ;
        }

        if (getId(msg.sender) == 0 ) {
            addressToId[msg.sender] = idCount;
            idToAddress[idCount] = msg.sender;
            idCount ++;
        }
        
        
        payable(owner()).transfer(calcDepositFeeAmt(_amount));

        stake[msg.sender] = stake[msg.sender] + (_amount - feeAmt - redistroAmt);        
        rewardTally[msg.sender] = rewardTally[msg.sender] + int(rewardPerToken) * int(_amount - feeAmt - redistroAmt);
        totalStake = totalStake + (_amount - feeAmt - redistroAmt);
        
        rewardPerToken = (rewardPerToken + redistroAmt * 1 ether / (totalStake));

        totalFee += feeAmt;
        emit staked(msg.sender, _amount - feeAmt - redistroAmt, feeAmt, redistroAmt);
    }

    function withdrawStake(uint256 _amount) public onlyUnlock nonReentrant {
        require(_amount <= stake[msg.sender], "Requested amount greater than staked amount");

        withdrawReward();

        uint256 fee = calcWithdrawFeeAmt(_amount);
        uint256 redistro = calcRedistroAmt(_amount);

        payable(msg.sender).transfer(_amount-fee-redistro);
        payable(owner()).transfer(fee);
        
        // update stake
        stake[msg.sender] = stake[msg.sender] - _amount ;
        rewardTally[msg.sender] = int(rewardTally[msg.sender]) - int(rewardPerToken * _amount) ;
        totalStake = totalStake - _amount ;
        
        rewardPerToken = (rewardPerToken + redistro * 1 ether / (totalStake));
        

        if (stake[msg.sender] < 1e-5 ether) {
            participatorCount --;
            withdrawReward();
        }

        // increate total fee
        totalFee += fee;

        emit withdrawn(msg.sender, _amount);
    }

    function withdrawReward() public onlyUnlock {
        uint256 reward = computeReward(msg.sender);
        uint256 claimFeeAmt = calcClaimFeeAmt(reward);
        uint256 redistroAmt = calcRedistroAmt(reward);

        payable(msg.sender).transfer(reward - claimFeeAmt - redistroAmt);
        payable(owner()).transfer(claimFeeAmt);

        // update reward
        rewardTally[msg.sender] = int(stake[msg.sender]) * int(rewardPerToken);

        // redistro
        rewardPerToken = (rewardPerToken + redistroAmt * 1 ether / (totalStake));

        // increate total fee
        totalFee += claimFee;

        emit rewardWithdrawn(msg.sender, reward);
    }

    function reInvestReward() public onlyUnlock {
        uint256 reward = computeReward(msg.sender);
        uint256 stakeFeeAmt = calcDepositFeeAmt(reward);
        uint256 redistroAmt = calcRedistroAmt(reward);

        payable(owner()).transfer(stakeFeeAmt);

        // update reward
        rewardTally[msg.sender] = int(stake[msg.sender]) * int(rewardPerToken);

        // update stake
        stake[msg.sender] = stake[msg.sender] + (reward - stakeFeeAmt - redistroAmt);        
        rewardTally[msg.sender] = rewardTally[msg.sender] + int(rewardPerToken) * int(reward - stakeFeeAmt - redistroAmt);
        totalStake = totalStake + (reward - stakeFeeAmt - redistroAmt);
        
        // redistro
        rewardPerToken = (rewardPerToken + redistroAmt * 1 ether / (totalStake));


        // increate total fee
        totalFee += stakeFeeAmt;

        emit reInvested(msg.sender, reward);
    }
    
    function distribute() public payable onlyOwner {
        uint256 _amount = msg.value;
        // Distribute "reward" proportionally to active stakes
        require(totalStake > 0, "Cannot distribute to staking pool with 0 stake");
        require(participatorCount > 0,  "You need to wait for user to particip");
        

        rewardPerToken = rewardPerToken + _amount * 1 ether / totalStake;
        emit rewardInput(block.timestamp, _amount);
    }

    function setDepositFee(uint256 _newFee) external onlyOwner {
        require(_newFee + redistroRate <= 99 , "Deposit Fee + redistro rate cannot be > '99'%");
        depositFee = _newFee;
        emit depositFeeSet(_newFee);
    }

    function setWithdrawFee(uint256 _newFee) external onlyOwner {
        require(_newFee + redistroRate <= 99 , "Widthdraw Fee + redistro rate cannot be > '99'%");
        withdrawFee = _newFee;
        emit withdrawFeeSet(_newFee);
    }

    function setClaimFee(uint256 _newFee) external onlyOwner {
        require(_newFee + redistroRate <= 99 , "Claim Fee + redistro rate cannot be > '99'%");
        claimFee = _newFee;
        emit claimFeeSet(_newFee);
    }

    function setRedistroRate(uint256 _newFee) external onlyOwner {
        require(_newFee + withdrawFee <= 99 , "Withdraw Fee + redistro rate cannot be > '99'%");
        require(_newFee + claimFee <= 99 , "Claim Fee + redistro rate cannot be > '99'%");
        require(_newFee + depositFee <= 99 , "Deposit Fee + redistro rate cannot be > '99'%");
        redistroRate = _newFee;
        emit redistroRateSet(_newFee);
    }

    function lockContract(bool _newVal) external onlyOwner {
        locked = _newVal;
        emit lockStatusSet(_newVal);
    }

    function setMinDeposit(uint256 _newAmt) external onlyOwner{
        minDeposit = _newAmt;
        emit minDepositSet(_newAmt);
    }

    function getTotFee() external view onlyOwner returns(uint256) {
        return totalFee;
    }


    // Utils for all
    function computeReward(address _user) public view returns(uint256){
        // Compute reward of "address"
        return uint256(int(stake[_user]) * int(rewardPerToken) - rewardTally[_user])/1 ether;
        
    }

    function getSumReward() public view returns(uint256) {
        uint256 sum;
        for (uint i=1; i <= idCount-1; i++){
            sum = sum + computeReward(idToAddress[i]);
        }
        return sum;
    }

    function getId(address _sender) public view returns(uint256) {
        return addressToId[_sender];
    }

    function calcDepositFeeAmt(uint256 _amount) public view returns(uint256) {
        return _amount.mul(depositFee).div(100);
    }

    function calcWithdrawFeeAmt(uint256 _amount) public view returns(uint256) {
        return _amount.mul(withdrawFee).div(100);
    }

    function calcClaimFeeAmt(uint256 _amount) public view returns(uint256) {
        return _amount.mul(claimFee).div(100);
    }

    function calcRedistroAmt(uint256 _amount) public view returns(uint256) {
        return _amount.mul(redistroRate).div(100);
    }
}