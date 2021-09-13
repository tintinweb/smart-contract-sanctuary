/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// File:  (3)/remixbackup/contracts/Address.sol



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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
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

// File:  (3)/remixbackup/contracts/SafeBEP20.sol



pragma solidity ^0.6.0;




/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// File:  (3)/remixbackup/contracts/IVRF.sol

pragma solidity ^0.6.0;

interface IVRF {
    function getRandomNumber() external;
    
    function returnRandomness() external view returns(uint256);
    
    function expand(uint256 randomValue, uint256 n) external view returns(uint[] memory);
}
// File:  (3)/remixbackup/contracts/SafeMath.sol



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

// File:  (3)/remixbackup/contracts/IBEP20.sol



pragma solidity ^0.6.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    
    function deposit() external payable;
    
    function withdraw(uint wad) external;

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

// File:  (3)/remixbackup/contracts/Context.sol



pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File:  (3)/remixbackup/contracts/Ownable.sol



pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// File:  (3)/remixbackup/contracts/Pre_Lottery.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;






contract PresaleLottery is Ownable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    
    //Interfaces 
    IVRF internal VRF; // Random Number Generator
    IBEP20 internal RBX; // Rubix Token
    IBEP20 internal wBNB; // wBNB Interace
    address payable private immutable wBNBaddress;
    address private LiqInjector;
    
    uint256 constant GOAL = 2000;
    uint256 constant RBX_PER_TICKET = 32 * 10**18;
    
    uint256 constant MIN_REWARD = 4.6 * 10**18;
    
    uint256 private _TICKETS_PURCHASED;
    
    uint256 private TICKET_FEE = 0.0112 * 10**18;
    
    uint256 internal PresaleStart = 1632506400; // 2021, September 25, 00:00 AM 
    
    uint256 private deadline = PresaleStart.add(432000); // 5 days
    
    uint internal OldRandomNumber;
    
    uint256[] private winners;
    
    bool private success;
    
    bool private numbersDrawn;
    
    mapping(uint256 => NUMBERS) private WINNING_NUMBERS;
        struct NUMBERS {
            uint256[20] _NUMBERS;
        }
        
    mapping(address => uint256) private balanceReward;
    
    mapping(address => uint256) private balanceRbx;
    
    mapping(address => bool) private REFUNDED;
    
    mapping(address => uint256) private TotalTickets;

    mapping(uint256 => TICKET) private TICKETS;
        struct TICKET {
        address payable pAddress;
        uint256 TICKETS_PURCHASED;
        uint isWINNER;
    }
    
    event ContributeToPresale(address indexed Contributor, uint256 Amount, uint _fromNumber, uint toNumber);
    event DrawWinners(address indexed Callee, uint256 TimeStamp);
    event ClaimRBX(address indexed Claimer, uint256 Amount);
    event ClaimReward(address indexed Claimer, uint256 Amount);
    
    // Stores data about every player
    address[] private _PLAYERS;
        

    receive() external payable {
        require(msg.sender == wBNBaddress, "wBNB ONLY!");
    }
    
    constructor(
        IBEP20 _wBNB,
        address payable _wBNBAddress,
        address LiquidityInjectorAddress,
        IBEP20 _RBX,
        IVRF _VRF
        
    ) public {
        wBNBaddress = _wBNBAddress;
        wBNB = _wBNB;
        LiqInjector = LiquidityInjectorAddress;
        RBX = _RBX;
        VRF = _VRF; //ChainLink Random Number Generator
    }
    
    /* CONTRIBUTE FUNCTION */
    
    function Contribute(uint256 TICKETS_QTY) public payable {
        require(PresaleStart <= now, "RBX: Lottery is not started yet!");
        require(TICKETS_QTY < 100, "RBX: Maximum limit reached");
        require(_TICKETS_PURCHASED.add(TICKETS_QTY) <= 31250, "RBX: Please select another number");
        require(now < deadline, "Lottery has been concluded");
        if(msg.value > 0) {
            require(msg.value >= TICKET_FEE.mul(TICKETS_QTY), "RBX: Incorrect Value");
            wrapBNB();
        }
        
        if(msg.value == 0) {
            wBNB.safeTransferFrom(msg.sender, address(this), TICKET_FEE.mul(TICKETS_QTY));
        }
        for (uint256 i = _TICKETS_PURCHASED; i <= _TICKETS_PURCHASED.add(TICKETS_QTY - 1); i++) {
            
            TICKETS[i] = TICKET(
                _msgSender(),
                TICKETS_QTY,
                0
            );
        }
       TotalTickets[msg.sender] = TotalTickets[msg.sender].add(TICKETS_QTY);
       balanceRbx[msg.sender] = balanceRbx[msg.sender].add(TICKETS_QTY.mul(RBX_PER_TICKET));    
       _TICKETS_PURCHASED = _TICKETS_PURCHASED.add(TICKETS_QTY);
       
       emit ContributeToPresale(msg.sender, TICKETS_QTY.mul(RBX_PER_TICKET), _TICKETS_PURCHASED.sub(TICKETS_QTY), _TICKETS_PURCHASED - 1);
        
    }

    /* END CONTRIBUTE FUNCTION */
    
 

     /* DRAW FUNCTION */
    
    function draw() public {
        require(deadline < now && _TICKETS_PURCHASED >= GOAL || _TICKETS_PURCHASED == 31250, "RBX: Lottery is not concluded");
        require(VRF.returnRandomness() > 0, "RBX: Randomness is not generated!");
        require(VRF.returnRandomness() != OldRandomNumber);
        require(LiqInjector != address(0), "RBX: Cannot send to zero address");
        
        uint256[] memory _Random = expand(VRF.returnRandomness(), 20);
        uint256 FinalMinReward;
        if(_TICKETS_PURCHASED <= 320) {
          FinalMinReward  = MIN_REWARD; 
        } else {
        uint256 A = MIN_REWARD;
        
        uint256 B = _TICKETS_PURCHASED.div(320);
        uint256 C =  A.mul(B);
        
        FinalMinReward = C; 
        }
        sendLiquidity(); 
        
        for(uint i = 0; i < 20; i++) {
            uint x = _Random[i] % _TICKETS_PURCHASED;
            WINNING_NUMBERS[0]._NUMBERS[i] = x;
            TICKETS[x].isWINNER = i;
            balanceReward[TICKETS[x].pAddress] = balanceReward[TICKETS[x].pAddress].add(FinalMinReward.mul(i + 1));
        }
        
        numbersDrawn = true;
            emit DrawWinners(msg.sender, now);
    }
    
    function sendLiquidity() internal onlyOwner {
        wBNB.safeTransfer(LiqInjector, wBNB.balanceOf(address(this)));
    }
    
    
    
    
    function refund() public {
        require(deadline < now && _TICKETS_PURCHASED < GOAL, "RBX: Fail");
        require(REFUNDED[msg.sender] != true, "Already refunded");
        wBNB.safeTransfer(msg.sender, TICKET_FEE.mul(TotalTickets[msg.sender]));
        _TICKETS_PURCHASED = _TICKETS_PURCHASED.sub(TotalTickets[msg.sender]);
        TotalTickets[msg.sender] = 0;
        REFUNDED[msg.sender] = true;
    }
    
    /* DRAW FUNCTION */
    
    function calc() public view returns(uint totalRBX, uint _MIN_REWARD) {
        uint result;
        uint256 FinalMinReward;
        if(_TICKETS_PURCHASED <= 300) {
          FinalMinReward  = MIN_REWARD; 
        } else {
        uint256 A = MIN_REWARD;
        uint256 B = _TICKETS_PURCHASED.div(300);
        uint256 C =  A.mul(B); 
        FinalMinReward = C;
        }
        
        for(uint i = 0; i < 20; i++) {
              result = result.add(FinalMinReward.mul(i + 1));  
            }
        return (result, FinalMinReward);
        
    }
    
    function getLiqInjector() public view returns(address) {
        return LiqInjector;
    }
    
    

    /* CLAIM FUNCTIONS */
    function claim() public returns(bool){
        require(deadline < now && _TICKETS_PURCHASED >= GOAL || _TICKETS_PURCHASED == 31250, "RBX: Lottery is not concluded");
        require(balanceRbx[msg.sender] > 0);
        
        uint256 amount = balanceRbx[msg.sender];
        
        RBX.safeTransfer(msg.sender, balanceRbx[msg.sender]);
        
        balanceRbx[msg.sender] = 0;
        emit ClaimReward(msg.sender, amount);
        return(true);
    }
    
    function claimReward() public returns(bool){
        require(deadline < now && _TICKETS_PURCHASED >= GOAL || _TICKETS_PURCHASED == 31250, "RBX: Lottery is not concluded");
        require(numbersDrawn != false, "RBX: Numbers are not drawn yet!");
        require(balanceReward[msg.sender] > 0);
        uint256 amount = balanceReward[msg.sender];
        
        RBX.safeTransfer(msg.sender, balanceReward[msg.sender]);
        balanceReward[msg.sender] = 0;
        emit ClaimRBX(msg.sender, amount);
        return true;
    }
    
    

    /* END CLAIM FUNCTIONS */

 

    /* RANDOM NUMBERS */
    function requestRandomNumber() public onlyOwner {
        OldRandomNumber = VRF.returnRandomness();
        VRF.getRandomNumber();
    }
    
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }
    /* END RANDOM NUMBERS */


 

    function wrapBNB() public payable {
        require(msg.value > 0);
        IBEP20(wBNBaddress).deposit{value: msg.value}();
        IBEP20(wBNBaddress).transfer(
            address(this),
            msg.value
        );
    }

    /* VIEW FUNCTIONS */
    
    function getCurrentRewardPool() public view returns(uint) {
        uint result;
        uint256 FinalMinReward;
        if(_TICKETS_PURCHASED <= 300) {
          FinalMinReward  = MIN_REWARD; 
        } else {
        uint256 A = MIN_REWARD;
        uint256 B = _TICKETS_PURCHASED.div(300);
        uint256 C =  A.mul(B); 
        FinalMinReward = C;
        }
        
        for(uint i = 0; i < 20; i++) {
              result = result.add(FinalMinReward.mul(i + 1));  
            }
        return (result);
        
    }
    
    function getWinningNumbers() public view returns(uint[20] memory) {
        uint[20] memory x = WINNING_NUMBERS[0]._NUMBERS;
        
        return x;
    }
    
    function getLotteryData() public view returns(uint256 TicketsSold, uint256 Start, uint256 End, uint256 MinGoal) {
        return(
            _TICKETS_PURCHASED,
            PresaleStart,
            deadline,
            GOAL
            );
    }
    
    function getUserBalances(address _address) public view returns(uint256 _RBX, uint256 prize) {
        return(balanceRbx[_address], balanceReward[_address]);
    }
    
    function getTicketData(uint256 ticketID) public view returns(uint _TicketsQty, address _user, uint _isWinner) {
        return(
            TotalTickets[msg.sender], TICKETS[ticketID].pAddress, TICKETS[ticketID].isWINNER
            );
    }
    /* END VIEW FUNCTION */
    
    /* Management Functions */
    
    function withdrawUnsold() public onlyOwner {
        require(deadline < now, "RBX: Lottery is not concluded");
        if(_TICKETS_PURCHASED < GOAL) {
            RBX.safeTransfer(msg.sender, RBX.balanceOf(address(this)));
        } else {
            uint256 A = RBX.balanceOf(address(this));
            uint256 B = _TICKETS_PURCHASED.mul(RBX_PER_TICKET);
            uint256 C = getCurrentRewardPool().add(B);
            uint256 res = A.sub(C);
            
            RBX.safeTransfer(msg.sender, res);
        }
        
    }
    
    function extendTime(uint256 newDeadline) public onlyOwner {
        deadline = newDeadline;
    }


}