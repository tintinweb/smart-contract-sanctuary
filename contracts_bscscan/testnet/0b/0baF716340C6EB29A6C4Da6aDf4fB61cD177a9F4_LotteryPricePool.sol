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
    constructor() public {
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

interface IERC20{
    function approve( address, uint256)  external returns(bool);
    function allowance(address, address) external view returns (uint256);
    function balanceOf(address)  external view returns(uint256);

    function decimals()  external view returns(uint8);

    function totalSupply() external  view returns(uint256);

    function transferFrom(address,address,uint256) external  returns(bool);
    function transfer(address,uint256) external  returns(bool);
    function mint(address , uint256 ) external ;
    function burn(address , uint256 ) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface TicketInterface{
    
    function draw(uint256 randomNumber) external view returns (address) ;
    
}

interface MedalNFT{
    function mint(address _to,uint256 _id,uint256 _quantity) external ;    
}

contract LotteryPricePool is ReentrancyGuard,Ownable,Pausable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    
    MedalNFT public medalContract;

    uint256 public constant DENOMINATOR = 10000;
  
    address public membershipPool;
    TicketInterface public ticket;

    uint256 public prizePeriodSeconds;
    uint256 public prizePeriodStartedAt;
    
    string private _clientSeeds;
    string public serverSeeds;
    uint256 nonce;
    
    uint256 public winnerAmount;
    uint256 public factionAmount;

    uint public constant POOLS = 5;
    IERC20 public rewardToken;
    
    uint256 public periodFinish = 0;
    uint256[POOLS] public rewardRate ;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;
    uint256[POOLS] public rewardPerPoolTokenStored;
    
    mapping(address => uint256[POOLS]) public userRewardPerPoolTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastTimeMedalGet;
    mapping(address => uint256[POOLS]) public userRewardMedal;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public userPool;
    
    uint256[POOLS] public poolSize;
    
    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _prizePeriodStart,
        TicketInterface _ticket,
        address _rewardToken,
        address _medalContract,
        address _membershipPool
    ) public {
        rewardToken = IERC20(_rewardToken);
        prizePeriodSeconds = 7 days;
        prizePeriodStartedAt = _prizePeriodStart;
        ticket = _ticket;
        medalContract = MedalNFT(_medalContract);
        membershipPool = _membershipPool;
    }


    function setMembershipPool(address _membershipPool) public onlyOwner(){
        require(_membershipPool != address(0));
        membershipPool = _membershipPool;
    }

    function changePrizePeriod(uint _prizePeriodSeconds) public onlyOwner(){
        require(_prizePeriodSeconds > 0,"_prizePeriodSeconds must be greater than zero");
        prizePeriodSeconds = _prizePeriodSeconds;
    }
    

    /* ========== VIEWS ========== */

    function totalSupply() external view  returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerPoolToken() public view returns (uint256[POOLS] memory) {
        uint256[POOLS] memory _rewardPerPoolTokenStored;
        if (_totalSupply == 0) {
               return _rewardPerPoolTokenStored;
        }
        else{
            for(uint i=1; i< POOLS;i++){
                if(poolSize[i] > 0){
                    _rewardPerPoolTokenStored[i] = rewardPerPoolTokenStored[i].add(
                    lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate[i]).mul(1e18).div(poolSize[i])
                    );
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
        return _balances[account].mul(rewardPerToken(pool).sub(userRewardPerPoolTokenPaid[account][pool])).div(1e18).add(rewards[account]);  
    }

    function getRewardForDuration(uint256 pool) external view returns (uint256) {
        return rewardRate[pool].mul(rewardsDuration);
    }

    function clientSeeds() public view returns(bytes32){
        return keccak256(abi.encode(_clientSeeds));
    }
    
    
    /* ========== INTERNAL ========== */
    
    
    function getPool(address _address) internal view returns(uint256){
        if(_balances[_address] > 10000*10**18){
            return 4;
        }
        else if(_balances[_address] > 1500*10**18){
            return 3;
        }
        else if(_balances[_address] > 250*10**18){
            return 2;
        }
        else if(_balances[_address] > 25*10**18){
            return 1;
        }
        else{
            return 0;
        }
    }
    
    function updatePool(uint256 _pool,address _address,uint256 _amount,bool _status) internal {
        if(_status){
            if(userPool[_address] == 0){
                userPool[_address] = _pool;
            }

            if(_pool == userPool[_address]){
                poolSize[_pool] += _amount; 
            }
            else{
                poolSize[userPool[_address]] -= (_balances[_address].sub(_amount));
                poolSize[_pool] += _balances[_address];
                userPool[_address] = _pool;
            }
        }
        else{
            if(_pool == userPool[_address]){
                poolSize[_pool] -= _amount; 
            }
            else{
                poolSize[userPool[_address]] -= (_balances[_address].add(_amount));
                poolSize[_pool] += _balances[_address];
                userPool[_address] = _pool;
            }
        } 
    }
    
    function updateRewardNFT(address _address) internal {
        if(lastTimeMedalGet[_address] == 0){
            lastTimeMedalGet[_address] = block.timestamp;
        }
        if(lastTimeMedalGet[_address].add(rewardsDuration) > block.timestamp){
            uint256 _index = getPool(_address);
            if(_index != 0){
                userRewardMedal[_address][_index] += block.timestamp.sub(lastTimeMedalGet[_address]).div(rewardsDuration);
                lastTimeMedalGet[_address] = block.timestamp;
            }
        }
    }

    function _isPrizePeriodOver() internal view returns(bool){
      if(prizePeriodStartedAt.add(prizePeriodSeconds) < block.timestamp){
        return true;
      }
      return false;
    }

    function _calculateNextPrizePeriodStartTime(uint256 currentTime) internal view returns (uint256) {
      uint256 elapsedPeriods = currentTime.sub(prizePeriodStartedAt).div(prizePeriodSeconds);
      return prizePeriodStartedAt.add(elapsedPeriods.mul(prizePeriodSeconds));
    }


    function _distribute(uint256 randomNumber) internal  {
        require(winnerAmount != 0,"Winner Amount is Zero");
        require(IERC20(address(ticket)).totalSupply()!= 0,"total supply of ticket is low");
        address winner = ticket.draw(randomNumber);
        _awardWinner(winner, winnerAmount);
        winnerAmount = 0;
        emit LotteryPrizeDistribute(winner,winnerAmount,randomNumber);
    }

    function _awardWinner(address user, uint256 amount) internal {
        rewardToken.safeTransfer(user,amount);
    }
    

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(address _address,uint256 amount) external nonReentrant() updateReward(_address) onlyMembershipPool() {
        _totalSupply = _totalSupply.add(amount);
        _balances[_address] = _balances[_address].add(amount);
        uint256 pool = getPool(_address);
        updatePool(pool,_address,amount,true);
        emit Staked(_address, amount);
    }                                                  

    function withdraw(address _address,uint256 amount) public nonReentrant() updateReward(_address) onlyMembershipPool() {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= _balances[_address],"Not a valid amount");
        _balances[_address] = _balances[_address].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        uint256 pool = getPool(_address);
        updatePool(pool,_address,amount,false);
        emit Withdrawn(_address, amount);
    }
    

    function getReward() public updateReward(msg.sender) nonReentrant() returns(uint256) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        return (reward);
    }

    function exit()  external {
        address _address = msg.sender;
        withdraw(_address,_balances[_address]);
        getReward();
    }

    function claimMedal() public nonReentrant updateReward(msg.sender) {
        require(getPool(msg.sender) != 0,"not a valid Member");
        for (uint i = 1; i<POOLS;i++){
            uint nftAmount = userRewardMedal[msg.sender][i];
            medalContract.mint(msg.sender,i,nftAmount);
            userRewardMedal[msg.sender][i] = 0 ;
            emit ClaimMedal(msg.sender,i,nftAmount);
        }
    }

    function changeClientSeeds(string memory _seed) public {
        require(prizePeriodStartedAt.add(prizePeriodSeconds) > block.timestamp,"before lottey distribution start");
        _clientSeeds = _seed;
        emit ChangeClientSeeds(msg.sender,_seed);
    }
    
    function setNewLotteryServerSeed(string memory _seed) public onlyOwner() {
        require(prizePeriodStartedAt.add(prizePeriodSeconds) > block.timestamp,"before lottey distribution start");
        serverSeeds = _seed;
        emit SetNewLotteryServerSeed(_seed);
    }

    function completeLotteryWinnerAward(string memory _serverSeeds) public onlyOwner() requireCanStartAward() whenNotPaused() {
        nonce++;
        uint256 randomNumber = uint256(keccak256(abi.encode(_serverSeeds,_clientSeeds,nonce)));
        emit RandomNumberCall(randomNumber,_serverSeeds,_clientSeeds);
        _distribute(randomNumber);
        prizePeriodStartedAt = _calculateNextPrizePeriodStartTime(block.timestamp);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _notifyRewardAmount(uint256 reward,uint256[POOLS] memory poolShare) internal {
        
        uint256[POOLS] memory _reward;
        uint256 _total;
        for(uint i=1 ; i< POOLS ; i++){
            _total = _total.add(poolShare[i]);
        }
        require(_total == DENOMINATOR,"not valid pool share");
        winnerAmount += reward.mul(poolShare[0]).div(DENOMINATOR);
        reward = reward.sub(winnerAmount);
        for(uint i=1 ; i< POOLS ; i++){
            _reward[i] = reward.mul(poolShare[i]).div(DENOMINATOR);
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
            require(rewardRate[i] <= balance.div(rewardsDuration), "Provided reward too high");
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }


    function notifyRewardAmount(uint256 reward,uint256[POOLS] memory poolShare) external onlyOwner() updateReward(address(0)) {
        require(reward > 0, "No reward");
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), reward);
        _notifyRewardAmount(reward,poolShare);
    }

    function notifyMedalReward(address[] memory addresses) public onlyOwner(){
        for(uint256 i=0;i< addresses.length;i++){
           if(_balances[addresses[i]] > 0 ){
                updateRewardNFT(addresses[i]);
           } 
        }
    }

    // Added to support recovering LP Rewards from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external  {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(rewardToken),
            "Cannot withdraw the staking or rewards tokens"
        );
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external  {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function pause() public onlyOwner(){
        _pause();
    }
    
    function unpause() public onlyOwner(){
        _unpause();
    }
 
    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerPoolTokenStored = rewardPerPoolToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            uint _pool = getPool(account);
            rewards[account] = earned(account,_pool);
            userRewardPerPoolTokenPaid[account][_pool] = rewardPerPoolTokenStored[_pool];
            updateRewardNFT(account);
        }
        _;
    }

    modifier requireCanStartAward() {
      require(_isPrizePeriodOver(), "PeriodicPrizeStrategy/prize-period-not-over");
      _;
    }

    modifier onlyMembershipPool() { 
      require (address(membershipPool) == msg.sender ,"only call by membership Pool"); 
      _; 
    }
    

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event ClaimMedal(address user,uint id,uint amount);
    event ChangeClientSeeds(address user,string _seed);
    event SetNewLotteryServerSeed(string _seed);
    event RandomNumberCall(uint256 randomNumber,string _serverSeeds,string _clientSeeds);
    event LotteryPrizeDistribute(address winner,uint256 winnerAmount,uint ticket);
}