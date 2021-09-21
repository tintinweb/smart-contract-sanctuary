/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20 {
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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



contract ENOStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeMath for uint8;



    struct Stake{
        uint deposit_amount;        //Deposited Amount
        uint stake_creation_time;   //The time when the stake was created
        bool returned;              //Specifies if the funds were withdrawed
        uint alreadyWithdrawedAmount;   //TODO Correct Lint
    }


    struct Account{
        address referral;
        uint referralAlreadyWithdrawed;
    }


    //---------------------------------------------------------------------
    //-------------------------- EVENTS -----------------------------------
    //---------------------------------------------------------------------


    /**
    *   @dev Emitted when the pot value changes
     */
    event PotUpdated(
        uint newPot
    );


    /**
    *   @dev Emitted when a customer tries to withdraw an amount
    *       of token greater than the one in the pot
     */
    event PotExhausted(

    );


    /**
    *   @dev Emitted when a new stake is issued
     */
    event NewStake(
        uint stakeAmount,
        address from
    );

    /**
    *   @dev Emitted when a new stake is withdrawed
     */
    event StakeWithdraw(
        uint stakeID,
        uint amount
    );

    /**
    *   @dev Emitted when a referral reward is sent
     */
    event referralRewardSent(
        address account,
        uint reward
    );

    event rewardWithdrawed(
        address account
    );


    /**
    *   @dev Emitted when the machine is stopped (500.000 tokens)
     */
    event machineStopped(
    );

    /**
    *   @dev Emitted when the subscription is stopped (400.000 tokens)
     */
    event subscriptionStopped(
    );



    //--------------------------------------------------------------------
    //-------------------------- GLOBALS -----------------------------------
    //--------------------------------------------------------------------

    mapping (address => Stake[]) private stake; /// @dev Map that contains account's stakes

    address private tokenAddress;

    ERC20 private ERC20Interface;

    uint private pot;    //The pot where token are taken

    uint256 private amount_supplied;    //Store the remaining token to be supplied

    uint private pauseTime;     //Time when the machine paused
    uint private stopTime;      //Time when the machine stopped




    // @dev Mapping the referrals
    mapping (address => address[]) private referral;    //Store account that used the referral

    mapping (address => Account) private account_referral;  //Store the setted account referral


    address[] private activeAccounts;   //Store both staker and referer address


    uint256 private constant _DECIMALS = 18;

    uint256 private constant _INTEREST_PERIOD = 1 days;    //One Month
    uint256 private constant _INTEREST_VALUE = 333;    //0.333% per day

    uint256 private constant _PENALTY_VALUE = 20;    //20% of the total stake



    uint256 private constant _MIN_STAKE_AMOUNT = 100 * (10**_DECIMALS);

    uint256 private constant _MAX_STAKE_AMOUNT = 100000 * (10**_DECIMALS);

    uint private constant _REFERALL_REWARD = 333; //0.333% per day

    uint256 private constant _MAX_TOKEN_SUPPLY_LIMIT =     50000000 * (10**_DECIMALS);
    uint256 private constant _MIDTERM_TOKEN_SUPPLY_LIMIT = 40000000 * (10**_DECIMALS);


    constructor() {
        pot = 0;
        amount_supplied = _MAX_TOKEN_SUPPLY_LIMIT;    //The total amount of token released
        tokenAddress = address(0);
    }

    //--------------------------------------------------------------------
    //-------------------------- TOKEN ADDRESS -----------------------------------
    //--------------------------------------------------------------------


    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(Address.isContract(_tokenAddress), "The address does not point to a contract");

        tokenAddress = _tokenAddress;
        ERC20Interface = ERC20(tokenAddress);
    }

    function isTokenSet() external view returns (bool) {
        if(tokenAddress == address(0))
            return false;
        return true;
    }

    function getTokenAddress() external view returns (address){
        return tokenAddress;
    }

    //--------------------------------------------------------------------
    //-------------------------- ONLY OWNER -----------------------------------
    //--------------------------------------------------------------------


    function depositPot(uint _amount) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "The Token Contract is not specified");

        pot = pot.add(_amount);

        if(ERC20Interface.transferFrom(msg.sender, address(this), _amount)){
            //Emit the event to update the UI
            emit PotUpdated(pot);
        }else{
            revert("Unable to tranfer funds");
        }

    }


    function returnPot(uint _amount) external onlyOwner nonReentrant{
        require(tokenAddress != address(0), "The Token Contract is not specified");
        require(pot.sub(_amount) >= 0, "Not enough token");

        pot = pot.sub(_amount);

        if(ERC20Interface.transfer(msg.sender, _amount)){
            //Emit the event to update the UI
            emit PotUpdated(pot);
        }else{
            revert("Unable to tranfer funds");
        }

    }


    function finalShutdown() external onlyOwner nonReentrant{

        uint machineAmount = getMachineBalance();

        if(!ERC20Interface.transfer(owner(), machineAmount)){
            revert("Unable to transfer funds");
        }
        //Goodbye
    }

    function getAllAccount() external onlyOwner view returns (address[] memory){
        return activeAccounts;
    }

    /**
    *   @dev Check if the pot has enough balance to satisfy the potential withdraw
     */
    function getPotentialWithdrawAmount() external onlyOwner view returns (uint){
        uint accountNumber = activeAccounts.length;

        uint potentialAmount = 0;

        for(uint i = 0; i<accountNumber; i++){

            address currentAccount = activeAccounts[i];

            potentialAmount = potentialAmount.add(calculateTotalRewardReferral(currentAccount));    //Referral

            potentialAmount = potentialAmount.add(calculateTotalRewardToWithdraw(currentAccount));  //Normal Reward
        }

        return potentialAmount;
    }


    //--------------------------------------------------------------------
    //-------------------------- CLIENTS -----------------------------------
    //--------------------------------------------------------------------

    /**
    *   @dev Stake token verifying all the contraint
    *   @notice Stake tokens
    *   @param _amount Amoun to stake
    *   @param _referralAddress Address of the referer; 0x000...1 if no referer is provided
     */
    function stakeToken(uint _amount, address _referralAddress) external nonReentrant {

        require(tokenAddress != address(0), "No contract set");

        require(_amount >= _MIN_STAKE_AMOUNT, "You must stake at least 100 tokens");
        require(_amount <= _MAX_STAKE_AMOUNT, "You must stake at maximum 100000 tokens");

        require(!isSubscriptionEnded(), "Subscription ended");

        address staker = msg.sender;
        Stake memory newStake;

        newStake.deposit_amount = _amount;
        newStake.returned = false;
        newStake.stake_creation_time = block.timestamp;
        newStake.alreadyWithdrawedAmount = 0;

        stake[staker].push(newStake);

        if(!hasReferral()){
            setReferral(_referralAddress);
        }

        activeAccounts.push(msg.sender);

        if(ERC20Interface.transferFrom(msg.sender, address(this), _amount)){
            emit NewStake(_amount, _referralAddress);
        }else{
            revert("Unable to transfer funds");
        }


    }

    /**
    *   @dev Return the staked tokens, requiring that the stake was
    *        not alreay withdrawed
    *   @notice Return staked token
    *   @param _stakeID The ID of the stake to be returned
     */
    function returnTokens(uint _stakeID) external nonReentrant returns (bool){
        Stake memory selectedStake = stake[msg.sender][_stakeID];

        //Check if the stake were already withdraw
        require(selectedStake.returned == false, "Stake were already returned");

        uint deposited_amount = selectedStake.deposit_amount;
        //Get the net reward
        uint penalty = calculatePenalty(deposited_amount);

        //Sum the net reward to the total reward to withdraw
        uint total_amount = deposited_amount.sub(penalty);


        //Update the supplied amount considering also the penalty
        uint supplied = deposited_amount.sub(total_amount);
        require(updateSuppliedToken(supplied), "Limit reached");

        //Add the penalty to the pot
        pot = pot.add(penalty);


        //Only set the withdraw flag in order to disable further withdraw
        stake[msg.sender][_stakeID].returned = true;

        if(ERC20Interface.transfer(msg.sender, total_amount)){
            emit StakeWithdraw(_stakeID, total_amount);
        }else{
            revert("Unable to transfer funds");
        }


        return true;
    }


    function withdrawReward(uint _stakeID) external nonReentrant returns (bool){
        Stake memory _stake = stake[msg.sender][_stakeID];

        uint rewardToWithdraw = calculateRewardToWithdraw(_stakeID);

        require(updateSuppliedToken(rewardToWithdraw), "Supplied limit reached");

        if(rewardToWithdraw > pot){
            revert("Pot exhausted");
        }

        pot = pot.sub(rewardToWithdraw);

        stake[msg.sender][_stakeID].alreadyWithdrawedAmount = _stake.alreadyWithdrawedAmount.add(rewardToWithdraw);

        if(ERC20Interface.transfer(msg.sender, rewardToWithdraw)){
            emit rewardWithdrawed(msg.sender);
        }else{
            revert("Unable to transfer funds");
        }

        return true;
    }


    function withdrawReferralReward() external nonReentrant returns (bool){
        uint referralCount = referral[msg.sender].length;

        uint totalAmount = 0;

        for(uint i = 0; i<referralCount; i++){
            address currentAccount = referral[msg.sender][i];
            uint currentReward = calculateRewardReferral(currentAccount);

            totalAmount = totalAmount.add(currentReward);

            //Update the alreadyWithdrawed status
            account_referral[currentAccount].referralAlreadyWithdrawed = account_referral[currentAccount].referralAlreadyWithdrawed.add(currentReward);
        }

        require(updateSuppliedToken(totalAmount), "Machine limit reached");

        //require(withdrawFromPot(totalAmount), "Pot exhausted");

        if(totalAmount > pot){
            revert("Pot exhausted");
        }

        pot = pot.sub(totalAmount);


        if(ERC20Interface.transfer(msg.sender, totalAmount)){
            emit referralRewardSent(msg.sender, totalAmount);
        }else{
            revert("Unable to transfer funds");
        }


        return true;
    }

    /**
    *   @dev Check if the provided amount is available in the pot
    *   If yes, it will update the pot value and return true
    *   Otherwise it will emit a PotExhausted event and return false
     */
    function withdrawFromPot(uint _amount) public nonReentrant returns (bool){

        if(_amount > pot){
            emit PotExhausted();
            return false;
        }

        //Update the pot value

        pot = pot.sub(_amount);
        return true;

    }


    //--------------------------------------------------------------------
    //-------------------------- VIEWS -----------------------------------
    //--------------------------------------------------------------------

    /**
    * @dev Return the amount of token in the provided caller's stake
    * @param _stakeID The ID of the stake of the caller
     */
    function getCurrentStakeAmount(uint _stakeID) external view returns (uint256)  {
        require(tokenAddress != address(0), "No contract set");

        return stake[msg.sender][_stakeID].deposit_amount;
    }

    /**
    * @dev Return sum of all the caller's stake amount
    * @return Amount of stake
     */
    function getTotalStakeAmount() external view returns (uint256) {
        require(tokenAddress != address(0), "No contract set");

        Stake[] memory currentStake = stake[msg.sender];
        uint nummberOfStake = stake[msg.sender].length;
        uint totalStake = 0;
        uint tmp;
        for (uint i = 0; i<nummberOfStake; i++){
            tmp = currentStake[i].deposit_amount;
            totalStake = totalStake.add(tmp);
        }

        return totalStake;
    }

    /**
    *   @dev Return all the available stake info
    *   @notice Return stake info
    *   @param _stakeID ID of the stake which info is returned
    *
    *   @return 1) Amount Deposited
    *   @return 2) Bool value that tells if the stake was withdrawed
    *   @return 3) Stake creation time (Unix timestamp)
    *   @return 4) The eventual referAccountess != address(0), "No contract set");
    *   @return 5) The current amount
    *   @return 6) The penalty of withdraw
    */
    function getStakeInfo(uint _stakeID) external view returns(uint, bool, uint, address, uint, uint){

        Stake memory selectedStake = stake[msg.sender][_stakeID];

        uint amountToWithdraw = calculateRewardToWithdraw(_stakeID);

        uint penalty = calculatePenalty(selectedStake.deposit_amount);

        address myReferral = getMyReferral();

        return (
            selectedStake.deposit_amount,
            selectedStake.returned,
            selectedStake.stake_creation_time,
            myReferral,
            amountToWithdraw,
            penalty
        );
    }


    /**
    *  @dev Get the current pot value
    *  @return The amount of token in the current pot
     */
    function getCurrentPot() external view returns (uint){
        return pot;
    }

    /**
    * @dev Get the number of active stake of the caller
    * @return Number of active stake
     */
    function getStakeCount() external view returns (uint){
        return stake[msg.sender].length;
    }


    function getActiveStakeCount() external view returns(uint){
        uint stakeCount = stake[msg.sender].length;

        uint count = 0;

        for(uint i = 0; i<stakeCount; i++){
            if(!stake[msg.sender][i].returned){
                count = count + 1;
            }
        }
        return count;
    }


    function getReferralCount() external view returns (uint) {
        return referral[msg.sender].length;
    }

    function getAccountReferral() external view returns (address[] memory){
        return referral[msg.sender];
    }

    function getAlreadyWithdrawedAmount(uint _stakeID) external view returns (uint){
        return stake[msg.sender][_stakeID].alreadyWithdrawedAmount;
    }


    //--------------------------------------------------------------------
    //-------------------------- REFERRALS -----------------------------------
    //--------------------------------------------------------------------


    function hasReferral() public view returns (bool){

        Account memory myAccount = account_referral[msg.sender];

        if(myAccount.referral == address(0) || myAccount.referral == address(0x0000000000000000000000000000000000000001)){
            //If I have no referral...
            assert(myAccount.referralAlreadyWithdrawed == 0);
            return false;
        }

        return true;
    }


    function getMyReferral() public view returns (address){
        Account memory myAccount = account_referral[msg.sender];

        return myAccount.referral;
    }


    function setReferral(address referer) internal {
        require(referer != address(0), "Invalid address");
        require(!hasReferral(), "Referral already setted");

        if(referer == address(0x0000000000000000000000000000000000000001)){
            return;   //This means no referer
        }

        if(referer == msg.sender){
            revert("Referral is the same as the sender, forbidden");
        }

        referral[referer].push(msg.sender);

        Account memory account;

        account.referral = referer;
        account.referralAlreadyWithdrawed = 0;

        account_referral[msg.sender] = account;

        activeAccounts.push(referer);    //Add to the list of active account for pot calculation
    }


    function getCurrentReferrals() external view returns (address[] memory){
        return referral[msg.sender];
    }


    /**
    *   @dev Calculate the current referral reward of the specified customer
    *   @return The amount of referral reward related to the given customer
     */
    function calculateRewardReferral(address customer) public view returns (uint){

        uint lowestStake;
        uint lowStakeID;
        (lowestStake, lowStakeID) = getLowestStake(customer);

        if(lowestStake == 0 && lowStakeID == 0){
            return 0;
        }

        uint periods = calculateAccountStakePeriods(customer, lowStakeID);

        uint currentReward = lowestStake.mul(_REFERALL_REWARD).mul(periods).div(100000);

        uint alreadyWithdrawed = account_referral[customer].referralAlreadyWithdrawed;


        if(currentReward <= alreadyWithdrawed){
            return 0;   //Already withdrawed all the in the past
        }


        uint availableReward = currentReward.sub(alreadyWithdrawed);

        return availableReward;
    }


    function calculateTotalRewardReferral() external view returns (uint){

        uint referralCount = referral[msg.sender].length;

        uint totalAmount = 0;

        for(uint i = 0; i<referralCount; i++){
            totalAmount = totalAmount.add(calculateRewardReferral(referral[msg.sender][i]));
        }

        return totalAmount;
    }

    function calculateTotalRewardReferral(address _account) public view returns (uint){

        uint referralCount = referral[_account].length;

        uint totalAmount = 0;

        for(uint i = 0; i<referralCount; i++){
            totalAmount = totalAmount.add(calculateRewardReferral(referral[_account][i]));
        }

        return totalAmount;
    }

    /**
     * @dev Returns the lowest stake info of the current account
     * @param customer Customer where the lowest stake is returned
     * @return uint The stake amount
     * @return uint The stake ID
     */
    function getLowestStake(address customer) public view returns (uint, uint){
        uint stakeNumber = stake[customer].length;
        uint min = _MAX_STAKE_AMOUNT;
        uint minID = 0;
        bool foundFlag = false;

        for(uint i = 0; i<stakeNumber; i++){
            if(stake[customer][i].deposit_amount <= min){
                if(stake[customer][i].returned){
                    continue;
                }
                min = stake[customer][i].deposit_amount;
                minID = i;
                foundFlag = true;
            }
        }


        if(!foundFlag){
            return (0, 0);
        }else{
            return (min, minID);
        }

    }



    //--------------------------------------------------------------------
    //-------------------------- INTERNAL -----------------------------------
    //--------------------------------------------------------------------

    /**
     * @dev Calculate the customer reward based on the provided stake
     * param uint _stakeID The stake where the reward should be calculated
     * @return The reward value
     */
    function calculateRewardToWithdraw(uint _stakeID) public view returns (uint){
        Stake memory _stake = stake[msg.sender][_stakeID];

        uint amount_staked = _stake.deposit_amount;
        uint already_withdrawed = _stake.alreadyWithdrawedAmount;

        uint periods = calculatePeriods(_stakeID);  //Periods for interest calculation

        uint interest = amount_staked.mul(_INTEREST_VALUE);

        uint total_interest = interest.mul(periods).div(100000);

        uint reward = total_interest.sub(already_withdrawed); //Subtract the already withdrawed amount

        return reward;
    }

    function calculateRewardToWithdraw(address _account, uint _stakeID) internal view onlyOwner returns (uint){
        Stake memory _stake = stake[_account][_stakeID];

        uint amount_staked = _stake.deposit_amount;
        uint already_withdrawed = _stake.alreadyWithdrawedAmount;

        uint periods = calculateAccountStakePeriods(_account, _stakeID);  //Periods for interest calculation

        uint interest = amount_staked.mul(_INTEREST_VALUE);

        uint total_interest = interest.mul(periods).div(100000);

        uint reward = total_interest.sub(already_withdrawed); //Subtract the already withdrawed amount

        return reward;
    }

    function calculateTotalRewardToWithdraw(address _account) internal view onlyOwner returns (uint){
        Stake[] memory accountStakes = stake[_account];

        uint stakeNumber = accountStakes.length;
        uint amount = 0;

        for( uint i = 0; i<stakeNumber; i++){
            amount = amount.add(calculateRewardToWithdraw(_account, i));
        }

        return amount;
    }

    function calculateCompoundInterest(uint _stakeID) external view returns (uint256){

        Stake memory _stake = stake[msg.sender][_stakeID];

        uint256 periods = calculatePeriods(_stakeID);
        uint256 amount_staked = _stake.deposit_amount;

        uint256 excepted_amount = amount_staked;

        //Calculate reward
        for(uint i = 0; i < periods; i++){

            uint256 period_interest;

            period_interest = excepted_amount.mul(_INTEREST_VALUE).div(100);

            excepted_amount = excepted_amount.add(period_interest);
        }

        assert(excepted_amount >= amount_staked);

        return excepted_amount;
    }

    function calculatePeriods(uint _stakeID) public view returns (uint){
        Stake memory _stake = stake[msg.sender][_stakeID];


        uint creation_time = _stake.stake_creation_time;
        uint current_time = block.timestamp;

        uint total_period = current_time.sub(creation_time);

        uint periods = total_period.div(_INTEREST_PERIOD);

        return periods;
    }

    function calculateAccountStakePeriods(address _account, uint _stakeID) public view returns (uint){
        Stake memory _stake = stake[_account][_stakeID];


        uint creation_time = _stake.stake_creation_time;
        uint current_time = block.timestamp;

        uint total_period = current_time.sub(creation_time);

        uint periods = total_period.div(_INTEREST_PERIOD);

        return periods;
    }

    function calculatePenalty(uint _amountStaked) private pure returns (uint){
        uint tmp_penalty = _amountStaked.mul(_PENALTY_VALUE);   //Take the 10 percent
        return tmp_penalty.div(100);
    }

    function updateSuppliedToken(uint _amount) internal returns (bool){
        
        if(_amount > amount_supplied){
            return false;
        }
        
        amount_supplied = amount_supplied.sub(_amount);
        return true;
    }

    function checkPotBalance(uint _amount) internal view returns (bool){
        if(pot >= _amount){
            return true;
        }
        return false;
    }



    function getMachineBalance() internal view returns (uint){
        return ERC20Interface.balanceOf(address(this));
    }

    function getMachineState() external view returns (uint){
        return amount_supplied;
    }

    function isSubscriptionEnded() public view returns (bool){
        if(amount_supplied >= _MAX_TOKEN_SUPPLY_LIMIT - _MIDTERM_TOKEN_SUPPLY_LIMIT){
            return false;
        }else{
            return true;
        }
    }

    function isMachineStopped() public view returns (bool){
        if(amount_supplied > 0){
            return true;
        }else{
            return false;
        }
    }

    //--------------------------------------------------------------
    //------------------------ DEBUG -------------------------------
    //--------------------------------------------------------------

    function getOwner() external view returns (address){
        return owner();
    }

}