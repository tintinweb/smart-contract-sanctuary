/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
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
    constructor() public {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
   
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

 
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface rStrategy {

    function deposit(uint256[4] calldata) external;
    function withdraw(uint256[4] calldata,uint[4] calldata) external;
    function withdrawAll()  external returns(uint256[4] memory);
    function withdrawOneCoin(uint256 amount,int128 index) external;
    
}

interface ControlledToken is IERC20 {
  
    function controllerMint(address _user, uint256 _amount) external;

    function controllerBurn(address _user, uint256 _amount) external;

    function controllerBurnFrom(address _operator, address _user, uint256 _amount) external;
}

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;
    address[] public adminList;

    event AddAuthorized(address indexed _address);
    event RemoveAuthorized(address indexed _address, uint index);

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender,"Authorizable: caller is not the SuperAdmin or Admin");
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0),"Authorizable: _toAdd isn't vaild address");
        authorized[_toAdd] = true;
        adminList.push(_toAdd);
        emit AddAuthorized(_toAdd);
    }

    function removeAuthorized(address _toRemove,uint _index) onlyOwner public {
        require(_toRemove != address(0),"Authorizable: _toRemove isn't vaild address");
        require(adminList[_index] == _toRemove,"Authorizable: _index isn't valid index");
        authorized[_toRemove] = false;
        delete adminList[_index];
        emit RemoveAuthorized(_toRemove,_index);
    }

    function getAdminList() public view returns(address[] memory ){
        return adminList;
    }

}

interface LotteryPrizePool {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(address _address,uint256 amount) external;

    function withdraw(address _address,uint256 amount) external;

    function getReward(address _address) external view returns (uint256,uint256);

    function exit() external;
}

contract MembershipPool is ReentrancyGuard,Authorizable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant public N_COINS = 4; // DAI / USDC / USDT / BUSD
    uint256 public poolPart = 2000; // 20% remain in pool
    
    LotteryPrizePool public prizePool;
    uint256 public constant DENOMINATOR = 10000;

    IERC20[N_COINS] public tokens;
    ControlledToken public controlledToken; //Ticket Token

    rStrategy public strategy;
    
    uint256 public lock_period = 7 days;
    
    uint public constant PRECISION = 10**18;

    uint public miniBronzeLevelAmount = 25*PRECISION;

    uint256 public withdrawFees = 700;
    uint256[N_COINS] public withdrawAmount;
    uint256[N_COINS] public reserveAmount;
    
    uint public YieldPoolBalance;
    address public sportBettingAddress; 

    struct Member{
        uint[N_COINS] tokensAmount;
        uint totalAmount;
    }

    mapping(address => Member) public members;

    mapping(address => uint256[N_COINS]) public requestedTime;
    mapping(address => uint256[N_COINS]) public amountWithdraw;
    
    uint256[N_COINS] public storedFees;
    uint256 public withdrawBettingAmount;
    uint256 public selfBalance;

    // EVENTS 
    event userSupplied(address user,uint amount,uint index);
    event ImmediatelyWithdraw(address user,uint amount,int128 index);
    event RequestWithdraw(address user,uint amount,uint index);
    event WithdrawalRequestedAmount(address user,uint amount,uint index);
    event feesTransfered(address user,uint amount,uint index);
    event CancelWithdrawRequest(address user,uint amount ,uint index);
    event WithdrawBettingFund(address sportBettingAddress,uint amount,uint index);
    event DepositBettingFund(address owner,uint amount,uint index);
    event ClaimRewards(address user,uint amount,uint index);
   

    constructor(address[N_COINS] memory _tokens,address _sportBettingAddress,address _controlledToken,address _strategy) public  {
        for(uint8 i=0; i<N_COINS; i++) {
            tokens[i] = IERC20(_tokens[i]);
        }
        sportBettingAddress = _sportBettingAddress;
        controlledToken = ControlledToken(_controlledToken);
        strategy = rStrategy(_strategy);
    }
    
    
    modifier validAmount(uint amount){
      require(amount > 0 , "NV");
      _;
    }
    
    modifier onlyPrizeStrategy() {
        require(msg.sender == address(prizePool), "PrizePool/only-prizeStrategy");
        _;
    }
    
    
    /* INTERNAL FUNCTIONS */
   
    //For checking whether array contains any non zero elements or not.
    function checkValidArray(uint256[N_COINS] memory amounts)internal pure returns(bool){
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i]>0){
                return true;
            }
        }
        return false;
    }
    
    // This function deposits the liquidity to yield generation pool using yield Strategy contract
    function _deposit(uint256[N_COINS] memory amounts) internal {
        strategy.deposit(amounts);
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i] > 0){
                YieldPoolBalance = YieldPoolBalance.add(amounts[i]);
            }
        }
    }
    
    // this will withdraw Liquidity from yield genaration pool using yield Strategy
    function _withdraw(uint256[N_COINS] memory amounts) internal {
        uint256[N_COINS] memory _amounts;
        for(uint8 i=0;i<N_COINS;i++){
            _amounts[i] = amounts[i].add(amounts[i].mul(100).div(DENOMINATOR));
            YieldPoolBalance =YieldPoolBalance.sub(amounts[i]);
        }
        strategy.withdraw(amounts,_amounts);
    }

    // this will withdraw Liquidity from yield genaration pool using yield Strategy
    function _withdrawOneToken(uint256 amount,int128 index) internal {
        strategy.withdrawOneCoin(amount,index);
        YieldPoolBalance =YieldPoolBalance.sub(amount);
    }
    

    function checkTerminat(address _add,uint _amount) internal view returns(bool) {
        uint availableAmount = members[_add].totalAmount.sub(_amount);
        if(availableAmount <= miniBronzeLevelAmount){
            return true;
        }
        return false;
    }
    
    // this will add unfulfilled withdraw requests to the withdrawl queue
    function _takeBackQ(uint256 amount,uint256 _index) internal {
        amountWithdraw[msg.sender][_index] = amountWithdraw[msg.sender][_index].add(amount);
        requestedTime[msg.sender][_index] = block.timestamp;
        withdrawAmount[_index] = withdrawAmount[_index].add(amount);
    }

    function isClaimable(address _add) internal view returns(bool) {
        for(uint8 i=0; i < N_COINS; i++) {
            if(block.timestamp > requestedTime[_add][i].add(lock_period) && amountWithdraw[_add][i] > 0) {
                return true;
            }
        }
        return false;  
    } 
    
    function getBalances(uint _index) public view returns(uint256) {
        return tokens[_index].balanceOf(address(this)).sub(storedFees[_index].add(reserveAmount[_index]));
    }


    function totalAvailableAmount() public view returns(uint256){
        uint256 _total;
        for(uint8 i=0; i < N_COINS; i++) {
            _total = _total.add(getBalances(i));   
        }
        return _total;
    }

    function currentBettingAmount() public view returns(uint256) {
        return selfBalance.mul(poolPart).div(DENOMINATOR).sub(withdrawBettingAmount);
    }

    function withdrawAmountsFromPool(uint256[N_COINS] memory amounts) internal view returns(uint256[N_COINS] memory){
        uint256[N_COINS] memory _amounts;
        for(uint i ;i<N_COINS;i++ ){
            _amounts[i] = withdrawAmountFromPool(amounts[i]); 
        }
        return _amounts;
    }
    
    function withdrawAmountFromPool(uint256 amount) internal view returns(uint256){
        return amount.mul(DENOMINATOR.sub(poolPart)).div(DENOMINATOR); 
    }
    function updateWithdrawQueue() internal{
        for(uint8 i=0;i<N_COINS;i++){
            reserveAmount[i]=reserveAmount[i].add(withdrawAmount[i]);
            withdrawAmount[i]=0;
        }
    }

    /* USER FUNCTIONS (exposed to frontend) */
   
    //For depositing liquidity to the pool.
    
    //_index will be 0/1/2    0-DAI , 1-USDC , 2-USDT
    
    function userDeposit(uint256 amount,uint256 _index) public nonReentrant() validAmount(amount){
        uint[N_COINS] memory _amounts;
        require(_index >= 0 && _index < N_COINS,"use valid tokens index");
        if(members[msg.sender].totalAmount == 0){
            require(amount > miniBronzeLevelAmount ,"not valid amount for membership");
        }
        members[msg.sender].tokensAmount[_index] += amount;
        members[msg.sender].totalAmount += amount;
        uint256 temp = amount.mul(poolPart).div(DENOMINATOR);
        _amounts[_index] = amount.sub(temp);
        tokens[_index].safeTransferFrom(msg.sender, address(strategy), _amounts[_index]);
        tokens[_index].safeTransferFrom(msg.sender, address(this),temp);
        _deposit(_amounts);
        ControlledToken(controlledToken).controllerMint(msg.sender, amount);
        prizePool.stake(msg.sender,amount);
        selfBalance=selfBalance.add(amount);
        emit userSupplied(msg.sender,amount,_index);
    }

    // request for token withdraw by users 
    
    function immediatelyWithdraw(uint256 amount,int128 _index) public nonReentrant() validAmount(amount){
        require(_index >= 0 && _index < 4,"NA");
        require (members[msg.sender].tokensAmount[uint256(_index)] >= amount,"token amount less");
        uint256[N_COINS] memory _tokens;
        bool terminate = checkTerminat(msg.sender,amount);
        uint256 _total;
        if(terminate){
            uint256[N_COINS] memory _withdrawAmountsFromPool;
            _tokens = members[msg.sender].tokensAmount;
            _withdrawAmountsFromPool = withdrawAmountsFromPool(_tokens);
            _withdraw(_withdrawAmountsFromPool);
            for(uint8 i=0; i<N_COINS; i++){
                if(_tokens[i] > 0){
                    uint256 temp = _tokens[i].mul(withdrawFees).div(DENOMINATOR);
                    storedFees[i] += temp; 
                    tokens[i].safeTransfer(msg.sender, _tokens[i].sub(temp));
                    members[msg.sender].tokensAmount[i] = 0;
                    _total += _tokens[i];
                    emit ImmediatelyWithdraw(msg.sender,_tokens[i],i);
                }
            }
            members[msg.sender].totalAmount = 0;
        }
        else{
            uint256 _withdrawAmountFromPool = withdrawAmountFromPool(amount);
            _withdrawOneToken(_withdrawAmountFromPool,_index);
            uint256 temp = amount.mul(withdrawFees).div(DENOMINATOR);
            storedFees[uint256(_index)] = temp; 
            tokens[uint256(_index)].safeTransfer(msg.sender,amount.sub(temp));
            members[msg.sender].totalAmount -= amount;
            members[msg.sender].tokensAmount[uint256(_index)] -= amount;
            _total += amount;
            emit ImmediatelyWithdraw(msg.sender,amount,_index);
        }
        ControlledToken(controlledToken).controllerBurn(msg.sender, _total);
        prizePool.withdraw(msg.sender,_total);
        selfBalance = selfBalance.sub(_total); 
    }
    
    
    function requestWithdraw(uint256 amount,uint128 _index) external nonReentrant() validAmount(amount){

        require(_index >= 0 && _index < 4,"NA");
        require(amount <= members[msg.sender].totalAmount,"high amount");
        require (members[msg.sender].tokensAmount[_index] >= amount,"high amount");
        uint256[N_COINS] memory _tokens;
        bool terminate = checkTerminat(msg.sender,amount);
        uint256 _total;
        if(terminate){
            _tokens = members[msg.sender].tokensAmount;
            for(uint8 i=0; i<N_COINS; i++){
                if(_tokens[i] > 0){
                    _takeBackQ(_tokens[i],i);
                    members[msg.sender].tokensAmount[i] = 0;
                    _total += _tokens[i];
                    emit RequestWithdraw(msg.sender,_tokens[i],i);
                }
            }
            members[msg.sender].totalAmount = 0;
        }
        else{
            _takeBackQ(amount,_index);
            _total += amount;
            members[msg.sender].totalAmount -= amount;
            members[msg.sender].tokensAmount[_index] -= amount;
            emit RequestWithdraw(msg.sender,amount,_index);
        }
        ControlledToken(controlledToken).controllerBurn(msg.sender, _total);
        prizePool.withdraw(msg.sender,_total);
    }
    
    //For claiming withdrawal after cool period off
    function withdrawalRequestedAmount() external nonReentrant{
        require(isClaimable(msg.sender),"unable to claim");
        uint256 _total;
        for(uint8 i=0; i<N_COINS; i++) {
            if(block.timestamp > requestedTime[msg.sender][i].add(lock_period) && amountWithdraw[msg.sender][i] > 0) {
                if(amountWithdraw[msg.sender][i] > reserveAmount[i]){
                    uint256 _withdrawAmountFromPool = withdrawAmountFromPool(amountWithdraw[msg.sender][i]);
                    _withdrawOneToken(_withdrawAmountFromPool,i);
                }
                else {
                    reserveAmount[i] = reserveAmount[i].sub(amountWithdraw[msg.sender][i]);
                }
                tokens[i].safeTransfer(msg.sender,amountWithdraw[msg.sender][i]); 
                _total = _total.add(amountWithdraw[msg.sender][i]);
                requestedTime[msg.sender][i] = 0;
                amountWithdraw[msg.sender][i] = 0;
                emit WithdrawalRequestedAmount(msg.sender,amountWithdraw[msg.sender][i],i);
            }
        }
        selfBalance = selfBalance.sub(_total);
    }

    function cancelWithdrawRequest() external nonReentrant() { 
        uint _total;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amountWithdraw[msg.sender][i] > 0) {
                members[msg.sender].tokensAmount[i] += amountWithdraw[msg.sender][i];
                _total += amountWithdraw[msg.sender][i];
                amountWithdraw[msg.sender][i] = 0;
                requestedTime[msg.sender][i] = 0;
                emit CancelWithdrawRequest(msg.sender,amountWithdraw[msg.sender][i],i);
            }
        }
        members[msg.sender].totalAmount += _total;
        prizePool.stake(msg.sender,_total);
        ControlledToken(controlledToken).controllerMint(msg.sender, _total);
        
    }
    
    /* CORE FUNCTIONS (called by owner only) */
    //Transfer token z`1   o rStrategy by maintaining pool ratio.

    function depositBettingFund(uint256[N_COINS] memory amounts) public onlyAuthorized(){
        require(checkValidArray(amounts),"amount can't be zero");
        uint _total;
        for(uint8 i=0;i<N_COINS;i++){
            _total = _total.add(amounts[i]);
        }
        require(withdrawBettingAmount >= _total,"withdraw amount less");
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                withdrawBettingAmount = withdrawBettingAmount.sub(amounts[i]);
                tokens[i].safeTransferFrom(msg.sender,address(this),amounts[i]);
                emit DepositBettingFund(msg.sender,amounts[i],i);
            }
        }
    }

    function deposit(uint256[N_COINS] memory amounts) onlyAuthorized() external  {
        uint _total;
        for(uint8 i=0;i<N_COINS;i++){
            _total = _total.add(amounts[i]);
        }
        require((totalAvailableAmount().sub(currentBettingAmount())) >= _total,"amounts not available" );
        for(uint8 i=0;i<N_COINS;i++){
            require(amounts[i] <=  getBalances(i),"pool balance is low");
            tokens[i].safeTransfer(address(strategy),amounts[i]);
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
    }

    function depositMoreFund(uint256[N_COINS] memory amounts) onlyAuthorized() external {
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i] > 0){
                tokens[i].safeTransferFrom(msg.sender,address(strategy),amounts[i]);
            }
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
    }

    //Withdraw from Yield genaration pool.
    function withdraw() onlyAuthorized() external  {
        require(checkValidArray(withdrawAmount), "queue empty");
        _withdraw(withdrawAmount);
        updateWithdrawQueue();
    }
    
    //Withdraw total liquidity from yield generation pool
    function withdrawAll() external onlyAuthorized() {
        uint[N_COINS] memory amounts;
        amounts = strategy.withdrawAll();
        selfBalance=0;
        for(uint8 i=0;i<N_COINS;i++){
            selfBalance=selfBalance.add(tokens[i].balanceOf(address(this)));
        }
        YieldPoolBalance=0;
        updateWithdrawQueue();
    }
    
    //For changing yield Strategy
    function changeStrategy(address _strategy) onlyAuthorized() external  {
        for(uint8 i=0;i<N_COINS;i++){
            require(YieldPoolBalance==0, "Call withdrawAll function first");
        } 
        strategy=rStrategy(_strategy);
        
    }
    
    //for changing pool ratio
    function changePoolPart(uint128 _newPoolPart) external onlyAuthorized()  {
        poolPart = _newPoolPart;
        
    }
    
    function setPrizePool(address _address) public onlyAuthorized(){
        prizePool = LotteryPrizePool(_address);
    }

    function claimFees() external nonReentrant onlyAuthorized(){
        for(uint i=0;i<N_COINS;i++){
            if(storedFees[i] > 0){
                tokens[i].safeTransfer(owner(),storedFees[i]);
                emit feesTransfered(owner(),storedFees[i],i);
                storedFees[i]=0;
            }
        }
    }

    function withdrawBettingFund(uint256[N_COINS] memory amounts) public onlyAuthorized(){
        require(checkValidArray(amounts),"Membership Pool: amount can not zero");
        uint total;
        for(uint i=0;i<N_COINS;i++){ 
           total = total.add(amounts[i]);
        }
        require(total <= currentBettingAmount(),"Membership Pool: Not enough balance to withdrawal");
        withdrawBettingAmount = withdrawBettingAmount.add(total);
        for(uint8 i=0; i<N_COINS; i++) {
            require(amounts[i] <= getBalances(i),"Membership Pool: token amount not avialable in pool" );
            if(amounts[i] > 0) {
                tokens[i].safeTransfer(sportBettingAddress, amounts[i]);
                emit WithdrawBettingFund(sportBettingAddress,amounts[i],i);
            }
        }
    }

    function setControlToken(address _controlledToken) public onlyAuthorized(){
        controlledToken = ControlledToken(_controlledToken);
    }
    
    // external
    function userTotalBalance(address _address) public view returns(uint256){
        return members[_address].totalAmount;
    }
    
    function userBalance(address _address,uint _index) public view returns(uint256){
        return members[_address].tokensAmount[_index];
    } 
}