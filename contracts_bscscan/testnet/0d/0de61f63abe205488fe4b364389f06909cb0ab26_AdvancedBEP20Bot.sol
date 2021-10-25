/**
 *Submitted for verification at BscScan.com on 2021-10-25
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

contract AdvancedBEP20Bot is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint public currentRound = 1;
    uint public participants = 0;
    uint public maxFee = 2000;
    uint public cumulativeRefundedAmt;
    uint public cumulativeProfitAmt;    

    mapping(uint => uint) public totalContributeInRound;
    mapping(uint => uint) public totalParticipantInRound;
    mapping(uint => uint) public totalProfitInRound;

    mapping(address => uint) public userAddrToId;
    mapping(uint => address) public userIdToAddr;

    mapping(address => mapping(uint => bool)) public userIsParticipatedInRound;
    mapping(address => mapping(uint => uint)) public userContributesInRound;
    mapping(address => mapping(uint => bool)) public userWithdrawnInRound;
    mapping(address => uint) public userWithdrawnRewardAmt;
    mapping(address => uint) public userWithdrawnFundAmt;

    uint public feeWalletCount = 0;
    mapping(address => uint) public feeWalletId;
    mapping(uint => address) public feeWalletIdToAddr;
    mapping(address => string) public feeWalletName;
    mapping(address => uint) public feeWalletFee;
    mapping (address => bool) public feeWalletIsEnabled;

    address public teamWallet;

    
    uint public teamWalletFee = 1500; // 15%
    uint public referralFee = 200; // referral fee is a portion of teamwalletFee. (referralFee < teamWallet) 2%
    mapping(address => uint) public referrerEarn;
    uint public minDeposit = 1e17;

    uint public currentRoundEndsAt;
    uint public nextRoundStartsAt;
    bool public isLocked = false;

    modifier onlyUnlocked {
        require(!isLocked);
        _;
    }
    modifier onlyLocked {
        require(isLocked);
        _;
    }

    event deposited(address _user, uint _amt, uint _timestamp);
    event withdrawn(address _user, uint _amt, uint _timestamp);
    event newFeeWalletAdded(address _newVal, uint _fee, string _name);
    event feeWalletSet(address _wallet, bool _isEnabled, uint _newFee, string _newName);
    event fundWithdrawn(uint _amt, uint _timestamp);
    event refunded(uint _round, uint _amt, uint _timestamp);
    event claimed(address _user, uint _round, uint _fund, uint _profit, uint _fee);
    event teamFeeSet(uint _newVal, uint _timestamp);
    event referralFeeSet(uint _newVal, uint _timestamp);
    event currentRoundEndsAtSet(uint _newVal, uint _timestamp);
    event nextRoundStartsAtSet(uint _newVal, uint _timestamp);
    event teamWalletSet(address _newVal, uint _timestamp);
    event minDepositSet(uint _newVal, uint _timestamp);

    constructor(address _teamWallet, address _token) {
        teamWallet = _teamWallet;
        token = IERC20(_token);
    }    

    /******************* 
    ** User Functions **
    *******************/

    function deposit(uint _amt) external onlyUnlocked {
        require(_amt >= minDeposit, "Deposit value needs to be greater than min deposit amount");
        if (!userIsParticipatedInRound[msg.sender][currentRound]) {
            if (userAddrToId[msg.sender] == 0) {
                participants = participants.add(1);
            }
            userAddrToId[msg.sender] = participants;
            userIdToAddr[participants] = msg.sender;
            totalParticipantInRound[currentRound] = totalParticipantInRound[currentRound].add(1);
            userIsParticipatedInRound[msg.sender][currentRound] = true;
        }

        totalContributeInRound[currentRound] = totalContributeInRound[currentRound].add(_amt);
        userContributesInRound[msg.sender][currentRound] = userContributesInRound[msg.sender][currentRound].add(_amt);
        // TODO: Add BEP20 transfer
        token.transferFrom(msg.sender, address(this), _amt);
        emit deposited(msg.sender, _amt, block.timestamp);
    }

    function withdraw(uint _amt) external onlyUnlocked nonReentrant {
        require(userIsParticipatedInRound[msg.sender][currentRound], "User is not participating in current round");
        require(userContributesInRound[msg.sender][currentRound] >= _amt, "User does not have enough fund in pool to withdraw.");

        userContributesInRound[msg.sender][currentRound] = userContributesInRound[msg.sender][currentRound].sub(_amt);
        totalContributeInRound[currentRound] = totalContributeInRound[currentRound].sub(_amt);

        // If the user's deposit amount < 0.000001 BEP20, then he/she will be no longer a participant
        if (userContributesInRound[msg.sender][currentRound] < 1e13) {
            userIsParticipatedInRound[msg.sender][currentRound] = false;
            totalParticipantInRound[currentRound] = totalParticipantInRound[currentRound].sub(1);
        }
        // payable(msg.sender).transfer(_amt);
        // TODO: BEP20 transfer
        token.transfer( msg.sender, _amt);
        emit withdrawn(msg.sender, _amt, block.timestamp);
    }

    function claimInRound(uint _round, address _referrer) external nonReentrant {
        require(_round < currentRound, "Use withdraw function with withdraw current round");
        require(userIsParticipatedInRound[msg.sender][_round] && userContributesInRound[msg.sender][_round]>0 && !userWithdrawnInRound[msg.sender][_round], "Error with claim fund, you might 1) have already withdrawn, 2) have not participate in the round");
        uint profit = totalProfitInRound[_round].mul(userContributesInRound[msg.sender][_round]).div(totalContributeInRound[_round]);
        uint totalFee;
        // pay fee for feeWallets
        for(uint i = 1; i <= feeWalletCount; i++){
            address feeWalletAddress = feeWalletIdToAddr[i];
            if (feeWalletIsEnabled[feeWalletAddress]){
                uint fee = profit.mul(feeWalletFee[feeWalletAddress]).div(10000);
                // payable(feeWalletAddress).transfer(fee);
                // TODO: BEP20 transfer
                token.transfer(feeWalletAddress, fee);
                totalFee += fee;
            }
        }

        uint feeForFeeWallets = profit.mul(calcTotalWalletFee()).div(10000);

        // If _referrer is valid pay fee to team + referrer, else only pay team fee. The rest goes to msg.sender
        if (_referrer != address(0) && _referrer.balance != 0 && _referrer != tx.origin) {
            uint feeForTeam = profit.mul(teamWalletFee - referralFee).div(10000);
            uint feeForReferrer = profit.mul(referralFee).div(10000); 
            // payable(teamWallet).transfer(feeForTeam);
            // TODO: BEP20 transfer
            token.transfer(teamWallet, feeForTeam);
            // payable(_referrer).transfer(feeForReferrer);
            token.transfer(_referrer, feeForReferrer);
            
            // payable(msg.sender).transfer(profit.sub(feeForTeam).sub(feeForReferrer).sub(feeForFeeWallets).add(userContributesInRound[msg.sender][_round]));
            token.transfer(msg.sender, profit.sub(feeForTeam).sub(feeForReferrer).sub(feeForFeeWallets).add(userContributesInRound[msg.sender][_round]));

            referrerEarn[_referrer] = referrerEarn[_referrer].add(feeForReferrer);
            totalFee += (feeForTeam + feeForReferrer);
        } else {
            uint feeForTeam = profit.mul(teamWalletFee).div(10000);
            // TODO: BEP20 transfer
            // payable(teamWallet).transfer(feeForTeam);
            token.transfer(teamWallet, feeForTeam);
            
            // payable(msg.sender).transfer(profit.sub(feeForTeam).sub(feeForFeeWallets).add(userContributesInRound[msg.sender][_round]));
            token.transfer(msg.sender,profit.sub(feeForTeam).sub(feeForFeeWallets).add(userContributesInRound[msg.sender][_round]));
            
            totalFee += feeForTeam;
        }

        cumulativeRefundedAmt = cumulativeRefundedAmt.sub(userContributesInRound[msg.sender][_round]);
        cumulativeProfitAmt = cumulativeProfitAmt.sub(profit);
        userWithdrawnInRound[msg.sender][_round] = true;

        userWithdrawnFundAmt[msg.sender] = userWithdrawnFundAmt[msg.sender].add(userContributesInRound[msg.sender][_round]);
        userWithdrawnRewardAmt[msg.sender] = userWithdrawnRewardAmt[msg.sender].add(profit);
        emit claimed(msg.sender, _round, userContributesInRound[msg.sender][_round], profit, totalFee);
    }

    /********************
    ** Admin Functions **
    ********************/

    function addFeeWallet(address _newVal, string memory _name, uint _fee) external onlyOwner {
        require(feeWalletId[_newVal] == 0, "This wallet is already exist");
        require(calcTotalWalletFee() + _fee + teamWalletFee <= maxFee, "Total fee cannot be set > maxFee");
        feeWalletCount = feeWalletCount.add(1);
        feeWalletId[_newVal] = feeWalletCount;
        feeWalletIdToAddr[feeWalletCount] = _newVal;
        feeWalletIsEnabled[_newVal] = true;
        feeWalletName[_newVal] = _name;
        feeWalletFee[_newVal] = _fee;
        emit newFeeWalletAdded(_newVal, _fee, _name);
    }

    function setFeeWallet(address _wallet, bool _isEnabled, uint _newFee, string memory _newName) external onlyOwner {
        require(feeWalletId[_wallet] != 0, "This wallet is not exist");
        int originalFee = int(calcTotalWalletFee());
        int diff = int(_newFee) - int(feeWalletFee[_wallet]);
        require(originalFee + diff + int(teamWalletFee) <= int(maxFee), "Accumulated fee cannot be over maxFee");

        feeWalletIsEnabled[_wallet] = _isEnabled;
        feeWalletFee[_wallet] = _newFee;
        feeWalletName[_wallet] = _newName;
        emit feeWalletSet(_wallet, _isEnabled, _newFee, _newName);
    }

    function withDrawFund() external onlyOwner onlyUnlocked nonReentrant{
        // uint fund = address(this).balance.sub(cumulativeRefundedAmt).sub(cumulativeProfitAmt); 
        // TODO: calc BEP20 withrawable fund amount
        uint fund = token.balanceOf(address(this)).sub(cumulativeRefundedAmt).sub(cumulativeProfitAmt); 
        require( fund > 0, "Cannot withdrawFund if there no participant");
        isLocked = true;
        // payable(owner()).transfer(fund); 
        // TODO: BEP20 transfer  
        token.transfer(owner(), fund);     
        emit fundWithdrawn(fund, block.timestamp);
    }

    function refund(uint _amt) external onlyOwner onlyLocked {
        
        require(_amt >= totalContributeInRound[currentRound], "Make sure input amount is larger than total contribute"); 
        
        totalProfitInRound[currentRound] = _amt.sub(totalContributeInRound[currentRound]);
        cumulativeRefundedAmt = cumulativeRefundedAmt.add(totalContributeInRound[currentRound]);
        cumulativeProfitAmt = cumulativeProfitAmt.add(totalProfitInRound[currentRound]);
        token.transferFrom(msg.sender, address(this), _amt);
        
        currentRound ++;
        isLocked = false;
        emit refunded(currentRound.sub(1), _amt, block.timestamp);
    }

    function setTeamFee(uint _newVal) external onlyOwner {
        require(calcTotalWalletFee()+_newVal <= maxFee, "You set the fee larger than upper limit");
        require(_newVal >= referralFee, "Team fee must be > referralFee");
        teamWalletFee = _newVal;
        emit teamFeeSet(_newVal, block.timestamp);
    }

    function setReferralFee(uint _newVal) external onlyOwner {
        require(_newVal <= teamWalletFee, "Referral fee must be less then teamWalletFee");
        referralFee = _newVal;
        emit referralFeeSet(_newVal, block.timestamp);
    }

    function setCurrentRoundEndsAt(uint _newVal) external onlyOwner {
        require(_newVal > block.timestamp, "The end time of current round must be > current time");
        require(_newVal < nextRoundStartsAt, "The end time of current round must be < nextRoundStartsAt");
        currentRoundEndsAt = _newVal;
        emit currentRoundEndsAtSet(_newVal, block.timestamp);
    }

    function setNextRoundStartsAt(uint _newVal) external onlyOwner {
        require(_newVal > block.timestamp, "The start time of next round must be > current time");
        require(_newVal > currentRoundEndsAt, "The start time of next round must be > currentRoundEndsAt time");
        nextRoundStartsAt = _newVal;
        emit nextRoundStartsAtSet(_newVal, block.timestamp);
    }

    function setTeamWallet(address _newVal) external onlyOwner {
        teamWallet = _newVal;
        emit teamWalletSet(_newVal, block.timestamp);
    }

    function setMinDeposit(uint _newVal) external onlyOwner {
        require(_newVal > 0, "MinDeposit must be > 0");
        minDeposit = _newVal;
        emit minDepositSet(_newVal, block.timestamp);
    }

    

    /*******************
    ** External utils **
    *******************/

    function calcTotalWalletFee() public view returns(uint) {
        uint totalWalletFee = 0;
        for (uint i=1; i <= feeWalletCount; i++) {
            if (feeWalletIsEnabled[feeWalletIdToAddr[i]]){
                uint fee = feeWalletFee[feeWalletIdToAddr[i]];
            totalWalletFee = totalWalletFee.add(fee);
            }
        }
        return totalWalletFee;
    }

    function getUserNextWithdrawableRounds(address _user) public view returns(uint) {
        for (uint i = 1; i < currentRound; i++) {
            if (userIsParticipatedInRound[_user][i] && userContributesInRound[_user][i]>0 && !userWithdrawnInRound[_user][i]) {
                return i;
            }
        }
        return 0;
    }

    function getUserWithdrawableRoundAfterRound(address _user, uint _round) public view returns(uint){
        for (uint i = _round+1; i < currentRound; i++) {
            if (userIsParticipatedInRound[_user][i] && userContributesInRound[_user][i]>0 && !userWithdrawnInRound[_user][i]) {
                return i;
            }
        }
        return 0;
    }

    function getUserUnwithdrawnFund(address _user) public view returns(uint) {
        uint nextRound = getUserNextWithdrawableRounds(_user);
        uint unwithdrawnFund;
        while (nextRound > 0) {
            unwithdrawnFund += userContributesInRound[_user][nextRound];
            nextRound = getUserWithdrawableRoundAfterRound(_user, nextRound);
        }
        return unwithdrawnFund;
    }

    function getUserUnwithdrawnProfit(address _user) public view returns(uint) {
        uint nextRound = getUserNextWithdrawableRounds(_user);
        uint unwithdrawnProfit;
        while (nextRound > 0) {
            uint profit = totalProfitInRound[nextRound].mul(userContributesInRound[_user][nextRound]).div(totalContributeInRound[nextRound]);
            unwithdrawnProfit += profit;
            nextRound = getUserWithdrawableRoundAfterRound(_user, nextRound);
        }
        return unwithdrawnProfit;
    }

}