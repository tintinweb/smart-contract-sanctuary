/**
 *Submitted for verification at BscScan.com on 2021-12-17
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

interface MedalNFT{
    function mint(address _to,uint256 _id,uint256 _quantity) external ;    
}

contract MembershipPool is ReentrancyGuard,Authorizable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    uint256 constant public N_COINS = 4; // DAI / BUSD/ USDC /USDT
    uint256 public poolPart = 2000; // 20% remain in pool
    
    uint256 public constant DENOMINATOR = 10000;

    IERC20[N_COINS] public tokens;
    ControlledToken public controlledToken; //Ticket Token

    rStrategy public strategy;
    
    uint256 public lock_period = 7 days;
    uint public constant PRECISION = 10**18;

    uint256 public withdrawFees = 700;
    uint256[N_COINS] public withdrawAmount;
    uint256[N_COINS] public reserveAmount;
    
    uint public YieldPoolBalance;
    address public sportBettingAddress; 
    address public  insuranceWallet;
    address payable public treasurerAddress;

    struct Member{
        uint[N_COINS] tokensAmount;
        uint totalAmount;
        uint userPool;
    }

    mapping(address => Member) public members;
    mapping(address => uint256[N_COINS]) public requestedTime;
    mapping(address => uint256[N_COINS]) public amountWithdraw;

    uint256[N_COINS] public moreDepositFund;
    uint256 public withdrawBettingAmount;
    uint256 public selfBalance;

    MedalNFT public medalContract;

    uint256 public greenLevelLimit; 
    uint256 public sliverLevelLimit;
    uint256 public goldLevelLimit;
    uint256 public viplevelLimit;

    uint public constant POOLS_INDEX = 5;

    IERC20 public rewardToken;

    uint256 public periodFinish = 0;
    uint256[POOLS_INDEX] public rewardRate ;
    uint256 public rewardsDuration = 7 days;
    uint256 public medalDistributeAt;
    uint256 public lastUpdateTime;
    uint256[POOLS_INDEX] public rewardPerPoolTokenStored;
    
    mapping(address => uint256[POOLS_INDEX]) public userRewardPerPoolTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastTimeMedalGet;
    mapping(address => uint256[POOLS_INDEX]) public userRewardMedal;

    uint256 public rewardTokenAmount;
    uint256[POOLS_INDEX] public poolSize;


    /* ========== CONSTRUCTOR ========== */
    constructor(
        address[N_COINS] memory _tokens,
        address _rewardToken,
        address _sportBettingAddress,
        address _medalContract,
        address _controlledToken,
        address _insuranceWallet, 
        address _strategy,
        address payable _treasurerAddress,
        uint256 _medalDistributeAt
        ) public  {

        for(uint8 i=0; i<N_COINS; i++) {
            tokens[i] = IERC20(_tokens[i]);
        }
        sportBettingAddress = _sportBettingAddress;
        controlledToken = ControlledToken(_controlledToken);
        insuranceWallet = _insuranceWallet;
        strategy = rStrategy(_strategy);
        rewardToken = IERC20(_rewardToken);
        medalContract = MedalNFT(_medalContract);
        treasurerAddress = _treasurerAddress;

        medalDistributeAt = _medalDistributeAt;

        greenLevelLimit = 25*PRECISION; 
        sliverLevelLimit = 250*PRECISION;
        goldLevelLimit = 1500*PRECISION;
        viplevelLimit = 10000*PRECISION;
    }

    function changeLimit(uint256 _greenLevelLimit,uint256 _sliverLevelLimit,uint256 _goldLevelLimit,uint256 _viplevelLimit) public onlyOwner(){
        greenLevelLimit = _greenLevelLimit;
        sliverLevelLimit = _sliverLevelLimit;
        goldLevelLimit = _goldLevelLimit;
        viplevelLimit = _viplevelLimit;
    }

    function changeMedalContract(address _medalContract) public onlyOwner(){
        require(_medalContract != address(0) && _medalContract != address(medalContract),"Membership Pool: address is not valid ");
        medalContract = MedalNFT(_medalContract);
    }
    
    function changeBettingAddress(address _sportBettingAddress) public onlyOwner() {
        require(_sportBettingAddress != address(0) && _sportBettingAddress != address(sportBettingAddress),"Membership Pool: address is not valid ");
        sportBettingAddress = _sportBettingAddress;
    }

    function changeInsuranceAddress(address _insuranceWallet) public onlyOwner() {
        require(_insuranceWallet != address(0) && _insuranceWallet != address(insuranceWallet),"Membership Pool: address is not valid ");
        insuranceWallet = _insuranceWallet;
    }

    function setTreasurerAddress(address payable _treasurerAddress) public onlyOwner(){
        require(_treasurerAddress != address(0),"Purchase: _treasurerAddress not be zero address");
        treasurerAddress = _treasurerAddress ;
    }

    /* ========== VIEWS ========== */


    function balanceOf(address account) external view returns (uint256) {
        return members[account].totalAmount;
    }

    function userBalance(address _address,uint _index) external view returns(uint256){
        return members[_address].tokensAmount[_index];
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);  
    }

    function rewardPerPoolToken() public view returns (uint256[POOLS_INDEX] memory) {
        uint256[POOLS_INDEX] memory _rewardPerPoolTokenStored;
        if (selfBalance == 0) {
               return _rewardPerPoolTokenStored;
        }
        else{
            for(uint i=1; i< POOLS_INDEX;i++){
                if(poolSize[i] > 0){
                    _rewardPerPoolTokenStored[i] = rewardPerPoolTokenStored[i].add(
                    lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate[i]).mul(1e18).div(poolSize[i])
                    );
                }
                if(poolSize[i] == 0){
                    _rewardPerPoolTokenStored[i] = rewardPerPoolTokenStored[i];
                }
            }
        }
        return _rewardPerPoolTokenStored;
    }
    
    function rewardPerToken(uint pool) public view returns (uint256) {
        if(pool == 0){
            return 0;
        }
        if (poolSize[pool] == 0) {
            return rewardPerPoolTokenStored[pool];
        }
        return rewardPerPoolTokenStored[pool].add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate[pool]).mul(1e18).div(poolSize[pool])
            );
    }
    
    function earned(address account,uint256 pool) public view returns (uint256) {
        return members[account].totalAmount.mul(rewardPerToken(pool).sub(userRewardPerPoolTokenPaid[account][pool])).div(1e18).add(rewards[account]);  
    }

    function getRewardForDuration(uint256 pool) external view returns (uint256) {
        return rewardRate[pool].mul(rewardsDuration);
    }

    function getBalances(uint _index) public view returns(uint256) {
        if(address(tokens[_index]) == address(rewardToken)){
            return tokens[_index].balanceOf(address(this)).sub(reserveAmount[_index].add(rewardTokenAmount));
        }
        return tokens[_index].balanceOf(address(this)).sub(reserveAmount[_index]);
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

    function getPool(address _address) public view returns(uint256){
        if(members[_address].totalAmount >= viplevelLimit){
            return 4;
        }
        else if(members[_address].totalAmount >= goldLevelLimit){
            return 3;
        }
        else if(members[_address].totalAmount >= sliverLevelLimit){
            return 2;
        }
        else if(members[_address].totalAmount >= greenLevelLimit){
            return 1;
        }
        else{
            return 0;
        }
    }
    
    /* INTERNAL FUNCTIONS */
   
    //For checking whether array contains any non zero elements or not.
    function checkValidArray(uint256[N_COINS] memory amounts) internal pure returns(bool){
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
    

    function checkTerminat(address _add,uint _amount) public view returns(bool) {
        uint availableAmount = members[_add].totalAmount.sub(_amount);
        if(availableAmount < greenLevelLimit){
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

    function isClaimable(address _add) public view returns(bool) {
        for(uint8 i=0; i < N_COINS; i++) {
            if(block.timestamp > requestedTime[_add][i].add(lock_period) && amountWithdraw[_add][i] > 0) {
                return true;
            }
        }
        return false;  
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
    function updateWithdrawQueue() internal {
        for(uint8 i=0;i<N_COINS;i++){
            reserveAmount[i]=reserveAmount[i].add(withdrawAmount[i]);
            withdrawAmount[i]=0;
        }
    }


    /* ========== INTERNAL ========== */
    
    function updatePool(uint256 _pool,address _address,uint256 _amount,bool _status) internal {
        if(_status){
            if(members[_address].userPool == 0){
                members[_address].userPool = _pool;
            }

            if(_pool == members[_address].userPool){
                poolSize[_pool] = poolSize[_pool].add(_amount) ; 
            }
            else{
                poolSize[members[_address].userPool] = poolSize[members[_address].userPool].sub((members[_address].totalAmount.sub(_amount)));
                poolSize[_pool] = poolSize[_pool].add(members[_address].totalAmount);
                members[_address].userPool = _pool;
            }
        }
        else{
            if(_pool == members[_address].userPool){
                poolSize[_pool] = poolSize[_pool].sub(_amount); 
            }
            else{
                poolSize[members[_address].userPool] = poolSize[members[_address].userPool].sub((members[_address].totalAmount.add(_amount)));
                poolSize[_pool] = poolSize[_pool].add(members[_address].totalAmount);
                members[_address].userPool = _pool;
            }
        } 
    }
    
    function updateRewardNFT(address _address) internal {
        if(lastTimeMedalGet[_address] == 0){
            lastTimeMedalGet[_address] = medalDistributeAt;
        }
        if(lastTimeMedalGet[_address].add(rewardsDuration) < block.timestamp){
            uint256 _index = getPool(_address);
            if(_index != 0){
                userRewardMedal[_address][_index] += block.timestamp.sub(lastTimeMedalGet[_address]).div(rewardsDuration);
                lastTimeMedalGet[_address] = medalDistributeAt;
            }
            else{
                lastTimeMedalGet[_address] = 0;
            }
        }
    }

    function stake(address _address,uint256 amount) internal   {
        uint256 pool = getPool(_address);
        updatePool(pool,_address,amount,true);
    }                                                  

    function withdraw(address _address,uint256 amount) internal  {
        require(amount > 0, "Membership Pool: Cannot withdraw zero amount");
        uint256 pool = getPool(_address);
        updatePool(pool,_address,amount,false);
    }

    function getReward(address _address) internal updateReward(_address) {
        uint256 reward = rewards[_address];
        require(reward <= rewardTokenAmount,"MembershipPool: reward amount is not available");
        if(reward > 0){
            rewards[_address] = 0;
            rewardToken.safeTransfer(_address, reward);
        }
        rewardTokenAmount = rewardTokenAmount.sub(reward);
        emit RewardPaid(_address, reward);
    }

    function exit(address _address,uint _amount) internal {
        withdraw(_address,_amount);
        getReward(_address);
    }


    /* USER FUNCTIONS (exposed to frontend) */
   
    //For depositing liquidity to the pool.
    
    //_index will be 0/1/2    0-DAI  , 1-BUSD , 2-USDC,3-USDT
    
    function userDeposit(uint256 amount,uint256 _index) public nonReentrant() updateReward(msg.sender) validAmount(amount){
        uint[N_COINS] memory _amounts;
        require(_index >= 0 && _index < N_COINS,"MembershipPool: use valid tokens index");
        if(members[msg.sender].totalAmount == 0){
            require(amount >= greenLevelLimit ,"MembershipPool: amount is less for membership");
        }
        members[msg.sender].tokensAmount[_index] = members[msg.sender].tokensAmount[_index].add(amount);
        members[msg.sender].totalAmount = members[msg.sender].totalAmount.add(amount);
        uint256 temp = amount.mul(poolPart).div(DENOMINATOR);
        _amounts[_index] = amount.sub(temp);
        tokens[_index].safeTransferFrom(msg.sender, address(strategy), _amounts[_index]);
        tokens[_index].safeTransferFrom(msg.sender, address(this),temp);
        _deposit(_amounts);
        ControlledToken(controlledToken).controllerMint(msg.sender, amount);
        stake(msg.sender,amount);
        selfBalance=selfBalance.add(amount);
        emit userSupplied(msg.sender,amount,_index);
    }

    // request for token withdraw by users 
    
    function immediatelyWithdraw(uint256 amount,int128 _index) external nonReentrant() updateReward(msg.sender) validAmount(amount){
        require(_index >= 0 && _index < 4,"MembershipPool: use valid tokens index");
        require (members[msg.sender].tokensAmount[uint256(_index)] >= amount,"MembershipPool: member balance is low");
        bool terminate = checkTerminat(msg.sender,amount);
        uint256 _total;
        if(terminate){
            require(terminate,"MembershipPool: user amount fall from minimum level");
        }
        else{
            uint256 _withdrawAmountFromPool = withdrawAmountFromPool(amount);
            _withdrawOneToken(_withdrawAmountFromPool,_index);
            uint256 temp = amount.mul(withdrawFees).div(DENOMINATOR);
            tokens[uint256(_index)].safeTransfer(treasurerAddress,temp);
            tokens[uint256(_index)].safeTransfer(msg.sender,amount.sub(temp));
            members[msg.sender].totalAmount = members[msg.sender].totalAmount.sub(amount);
            members[msg.sender].tokensAmount[uint256(_index)] = members[msg.sender].tokensAmount[uint256(_index)].sub(amount);
            _total = _total.add(amount);
            emit ImmediatelyWithdraw(msg.sender,amount,_index);
        }
        ControlledToken(controlledToken).controllerBurn(msg.sender, _total);
        withdraw(msg.sender,_total);
        selfBalance = selfBalance.sub(_total); 
    }
    
    function requestWithdraw(uint256 amount,uint128 _index) external nonReentrant() updateReward(msg.sender) validAmount(amount){
        require(_index >= 0 && _index < 4,"MembershipPool: use valid tokens index");
        require (members[msg.sender].tokensAmount[_index] >= amount,"MembershipPool: member balance is low");
        bool terminate = checkTerminat(msg.sender,amount);
        uint256 _total;
        if(terminate){
            require(terminate,"MembershipPool: user amount fall from minimum level");
        }
        else{
            _takeBackQ(amount,_index);
            _total = _total.add(amount);
            members[msg.sender].totalAmount = members[msg.sender].totalAmount.sub(amount);
            members[msg.sender].tokensAmount[_index] = members[msg.sender].tokensAmount[_index].sub(amount);
            emit RequestWithdraw(msg.sender,amount,_index);
        }
        ControlledToken(controlledToken).controllerBurn(msg.sender, _total);
        withdraw(msg.sender,_total);
    }

    function terminateMembership(bool _payFee) public nonReentrant() updateReward(msg.sender){
        uint256[N_COINS] memory _amounts;
        uint _total;
        _amounts = members[msg.sender].tokensAmount;
        require(checkValidArray(_amounts),"Membership Pool: user amount is zero");
        if(_payFee){
            uint256[N_COINS] memory _withdrawAmountsFromPool;
            _withdrawAmountsFromPool = withdrawAmountsFromPool(_amounts);
            _withdraw(_withdrawAmountsFromPool);
            for(uint8 i=0; i<N_COINS; i++){
                if(_amounts[i] > 0){
                    uint256 temp = _amounts[i].mul(withdrawFees).div(DENOMINATOR);
                    tokens[i].safeTransfer(treasurerAddress,temp); 
                    tokens[i].safeTransfer(msg.sender, _amounts[i].sub(temp));
                    members[msg.sender].tokensAmount[i] = 0;
                    _total = _total.add(_amounts[i]);
                    emit ImmediatelyWithdraw(msg.sender,_amounts[i].sub(temp),i);
                }
            }
            selfBalance = selfBalance.sub(_total); 
        }
        else{
            for(uint8 i=0; i<N_COINS; i++){
                if(_amounts[i] > 0){
                    _takeBackQ(_amounts[i],i);
                    members[msg.sender].tokensAmount[i] = 0;
                    _total += _amounts[i];
                    emit RequestWithdraw(msg.sender,_amounts[i],i);
                }
            }
        }
        members[msg.sender].totalAmount = 0;
        ControlledToken(controlledToken).controllerBurn(msg.sender, _total);
        exit(msg.sender,_total); 
    } 
    
    //For claiming withdrawal after cool period off
    function withdrawalRequestedAmount() external nonReentrant() updateReward(msg.sender){
        require(isClaimable(msg.sender),"MembershipPool: unable to claim");
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
                emit WithdrawalRequestedAmount(msg.sender,amountWithdraw[msg.sender][i],i);
                requestedTime[msg.sender][i] = 0;
                amountWithdraw[msg.sender][i] = 0;
            }
        }
        selfBalance = selfBalance.sub(_total);
    }

    function cancelWithdrawRequest() external nonReentrant() updateReward(msg.sender){ 
        uint _total;
        uint256[N_COINS] memory _amounts;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amountWithdraw[msg.sender][i] > 0) {
                members[msg.sender].tokensAmount[i] = members[msg.sender].tokensAmount[i].add(amountWithdraw[msg.sender][i]);
                _total = _total.add(amountWithdraw[msg.sender][i]);
                if(reserveAmount[i] > amountWithdraw[msg.sender][i]){
                    _amounts[i] = amountWithdraw[msg.sender][i];
                    reserveAmount[i] = reserveAmount[i].sub(amountWithdraw[msg.sender][i]);
                }
                else{
                    withdrawAmount[i] = withdrawAmount[i].sub(amountWithdraw[msg.sender][i]); 
                }
                emit CancelWithdrawRequest(msg.sender,amountWithdraw[msg.sender][i],i);
                amountWithdraw[msg.sender][i] = 0;
                requestedTime[msg.sender][i] = 0;
            }
        }
        if(checkValidArray(_amounts)){
            _deposit(_amounts);
        }
        members[msg.sender].totalAmount = members[msg.sender].totalAmount.add(_total);
        stake(msg.sender,_total);
        ControlledToken(controlledToken).controllerMint(msg.sender, _total);
    }

    function getReward() public nonReentrant() {
        getReward(msg.sender);
    }

    function claimMedal() external nonReentrant updateReward(msg.sender) {
        for (uint i = 1; i<POOLS_INDEX;i++){
            uint nftAmount = userRewardMedal[msg.sender][i];
            if(nftAmount > 0 ){
                medalContract.mint(msg.sender,i,nftAmount);
                userRewardMedal[msg.sender][i] = 0 ;
                emit ClaimMedal(msg.sender,i,nftAmount);
            } 
        }
    }
    
    /* CORE FUNCTIONS (called by owner only) */
    //Transfer token z`1   o rStrategy by maintaining pool ratio.

    function depositBettingFund(uint256[N_COINS] memory amounts) public onlyAuthorized(){
        require(checkValidArray(amounts),"MembershipPool: amount can't be zero");
        uint _total;
        for(uint8 i=0;i<N_COINS;i++){
            _total = _total.add(amounts[i]);
        }
        require(withdrawBettingAmount >= _total,"MembershipPool: deposit amount must be less than withdrawBettingAmount");
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
        require((totalAvailableAmount().sub(currentBettingAmount())) >= _total,"MembershipPool: amounts not available" );
        for(uint8 i=0;i<N_COINS;i++){
            require(amounts[i] <=  getBalances(i),"MembershipPool: pool balance is low ");
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
                moreDepositFund[i] = moreDepositFund[i].add(amounts[i]);
            }
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
        emit DepositMoreFund(msg.sender,amounts);
    }

    function withdrawalExtaFund(address _address,uint256[N_COINS] memory amounts) onlyAuthorized() external {
        for(uint8 i=0;i<N_COINS;i++){
            require(moreDepositFund[i] >= amounts[i],"MembershipPool: only deposit can withdraw");
        }
        if(checkValidArray(amounts)){
            _withdraw(amounts);
        }
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i] > 0){
                tokens[i].safeTransfer(_address,amounts[i]);
                moreDepositFund[i] = moreDepositFund[i].sub(amounts[i]);
            }
        }
        emit WithdrawalExtaFund(msg.sender,_address,amounts);
    }

    //Withdraw from Yield genaration pool.
    function withdraw() onlyAuthorized() external  {
        require(checkValidArray(withdrawAmount), "MembershipPool: amount can't be zero");
        _withdraw(withdrawAmount);
        updateWithdrawQueue();
    }
    
    //Withdraw total liquidity from yield generation pool
    function withdrawAll() external onlyAuthorized() {
        uint[N_COINS] memory amounts;
        amounts = strategy.withdrawAll();
        YieldPoolBalance=0;
        updateWithdrawQueue();
    }
    
    //For changing yield Strategy
    function changeStrategy(address _strategy) onlyAuthorized() external  {
        for(uint8 i=0;i<N_COINS;i++){
            require(YieldPoolBalance==0, "MembershipPool: Call withdrawAll function first");
        } 
        strategy=rStrategy(_strategy);
        
    }
    
    //for changing pool ratio
    function changePoolPart(uint128 _newPoolPart) external onlyAuthorized()  {
        require(_newPoolPart != poolPart,"MembershipPool : pool part is same");
        poolPart = _newPoolPart;
    }

    // _wallet is true then sportBettingAddress 
    function withdrawBettingFund(uint256[N_COINS] memory amounts,bool _wallet) public onlyAuthorized(){
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
                if(_wallet){
                    tokens[i].safeTransfer(sportBettingAddress, amounts[i]);
                }
                else{
                    tokens[i].safeTransfer(insuranceWallet, amounts[i]);
                }
                emit WithdrawBettingFund(sportBettingAddress,amounts[i],i);
            }
        }
    }

    function setControlToken(address _controlledToken) public onlyAuthorized(){
        require(_controlledToken != address(0),"Membership Pool: not a valid address");
        require(address(controlledToken) != _controlledToken,"Membership Pool: address is same");
        controlledToken = ControlledToken(_controlledToken);
    }

    function _notifyRewardAmount(uint256 reward,uint256[POOLS_INDEX] memory poolShare) internal {
        uint256[POOLS_INDEX] memory _reward;
        uint256 _total;
        for(uint i=1 ; i< POOLS_INDEX ; i++){
            _total = _total.add(poolShare[i]);
        }
        require(_total == DENOMINATOR,"Membership Pool: not valid pool share");
        for(uint i=1 ; i< POOLS_INDEX ; i++){
            _reward[i] = reward.mul(poolShare[i]).div(DENOMINATOR);
            if(_reward[i] > 0){
                if (block.timestamp >= periodFinish) {
                    rewardRate[i] = _reward[i].div(rewardsDuration);
                } else {
                    uint256 remaining = periodFinish.sub(block.timestamp);
                    uint256 leftover = remaining.mul(rewardRate[i]);
                    rewardRate[i] = _reward[i].add(leftover).div(rewardsDuration);
                }
                // Ensure the provided reward amount is not more than the balance in the contract.
                // This keeps the reward rate in the right range, preventing overflows due to
                // very high values of rewardRate in the earned and rewardsPerToken functions;
                // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
                uint balance = poolSize[i];
                require(rewardRate[i] <= balance.div(rewardsDuration), "Membership Pool: Provided reward too high");
            }
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
    }

    function notifyRewardAmount(uint256 reward,uint256[POOLS_INDEX] memory poolShare) external onlyAuthorized() updateReward(address(0)) {
        require(reward > 0, "No reward");
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), reward);
        _notifyRewardAmount(reward, poolShare);
        rewardTokenAmount = rewardTokenAmount.add(reward);
        emit RewardAdded(reward);
    }

    function notifyMedalReward(uint256 _medalDistributeAt) public onlyAuthorized(){
        require(_medalDistributeAt > medalDistributeAt,"Membership Pool: disribution musat be greater then privous one");
        medalDistributeAt = _medalDistributeAt;
    }
    
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner() {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Membership Pool: Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
 
    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerPoolTokenStored = rewardPerPoolToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if(medalDistributeAt.add(rewardsDuration) < block.timestamp){
            uint timeRatio = (block.timestamp.sub(medalDistributeAt)).div(rewardsDuration);
            medalDistributeAt = medalDistributeAt.add(timeRatio.mul(rewardsDuration));
        }

        if (account != address(0)) {
            uint _pool = getPool(account);
            rewards[account] = earned(account,_pool);
            userRewardPerPoolTokenPaid[account][_pool] = rewardPerPoolTokenStored[_pool];
            updateRewardNFT(account);
        }
        _;
    }

    modifier validAmount(uint amount){
      require(amount > 0 , "MembershipPool: amount must be greater then zero");
      _;
    }
    
    /* ========== EVENTS ========== */

    event userSupplied(address user,uint amount,uint index);
    event ImmediatelyWithdraw(address user,uint amount,int128 index);
    event RequestWithdraw(address user,uint amount,uint index);
    event WithdrawalRequestedAmount(address user,uint amount,uint index);
    event feesTransfered(address user,uint amount,uint index);
    event CancelWithdrawRequest(address user,uint amount ,uint index);
    event WithdrawBettingFund(address sportBettingAddress,uint amount,uint index);
    event DepositBettingFund(address owner,uint amount,uint index);
    event ClaimRewards(address user,uint amount);
    event DepositMoreFund(address onwer,uint[N_COINS] _amounts);
    event WithdrawalExtaFund(address owner,address _address,uint[N_COINS] _amounts);
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event ClaimMedal(address user,uint id,uint amount);
}