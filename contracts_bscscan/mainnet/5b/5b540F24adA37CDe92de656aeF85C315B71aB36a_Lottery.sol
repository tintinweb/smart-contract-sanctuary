/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// File: contracts/StakingInterface.sol


pragma solidity ^0.6.0;

interface ISTAKE {
    function topUp(uint256 value1, uint256 value2) external;
}
// File: contracts/IVRF.sol

pragma solidity ^0.6.0;

interface IVRF {
    function getRandomNumber() external;
    
    function returnRandomness() external view returns(uint256);
    
    function expand(uint256 randomValue, uint256 n) external view returns(uint[] memory);
}
// File: contracts/Address.sol

  

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
     * of certain opcodes, possibly making contracts go over the 2100 gas limit
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

// File: contracts/SafeBEP20.sol

  

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

// File: contracts/SafeMath.sol

  

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

// File: contracts/IBEP20.sol

  

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

// File: contracts/Context.sol

  

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

// File: contracts/Ownable.sol

  

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

// File: contracts/rubix-staking.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;







contract Lottery is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    event BuyTicketsWithDiscount(address indexed player, uint _fromNumber, uint _toNmber, uint roundID);
    event BuyTicketsWithoutDiscount(address indexed player, uint _fromNumber, uint _toNmber, uint roundID);
    event Claim(address indexed);
    event RandomNumberGenerator();
    event DrawLuckyNumbers(uint roundID);
    event FeeChanged(uint newRBXFee, uint neBNBFee);
    event newStakingAddress(address _NewStakingAddress);

    receive() external payable {
        require(msg.sender == wBNBaddress, "wBNB ONLY!");
    }

    //Constants
    uint256 internal constant DEVS_SHARE = 10;
    uint256 internal constant COMMUNITY_SHARE = 10;
    uint256 constant SECONDS_IN_DAY = 86400;

    //Interfaces
    IVRF internal VRF; // Random Number Generator
    IBEP20 internal RBX; // Rubix Token
    IBEP20 internal wBNB; // wBNB Interace
    ISTAKE internal STAKING;
    address payable public immutable wBNBaddress;

    // Dev and staking addresses
    address private STAKINGADDRESS;
    address private DEVADDRESS;

    mapping(address => Balances) private balanceToClaim;

    struct Balances {
        uint256 RBX;
        uint256 wBNB;
    }

    /* Stores data about every ticket bought during draws. */
    mapping(uint256 => TICKETDATA) private _TICKETDATA;

    struct TICKETDATA {
        address payable PLAYER_ADDRESS;
        uint256 ROUND_JOINED;
        uint256 TICKETS_BOUGHT;
        uint256[4] LUCKY_NUMBERS;
        uint256 One;
        uint256 Two;
        uint256 Three;
        uint256 Jackpot;
        uint8 MATCHED;
    }

    /* Stores data about winners and lottery rounds */
    mapping(uint256 => ROUND) private ROUNDS;

    struct ROUND {
        uint256 TICKETS_SOLD;
        uint256[4] WINNING_NUMBERS;
        uint8 WINNERS_PICKED; // 0 - Winners not Picked, 1 Winners Picked
        uint256 ROUND_START_TIMESTAMP;
        uint256 ROUND_END_TIMESTAMP;
        uint256 FIRST_POT_RBX;
        uint256 SECOND_POT_RBX;
        uint256 THIRD_POT_RBX;
        uint256 FIRST_POT_wBNB;
        uint256 SECOND_POT_wBNB;
        uint256 THIRD_POT_wBNB;
    }

    mapping(uint256 => POOL) private POOLS;

    struct POOL {
        uint256 REGULAR_PRIZE_RBX;
        uint256 REGULAR_PRIZE_wBNB;
        uint16 MATCHED_1_NUMBER;
        uint16 MATCHED_2_NUMBERS;
        uint16 MATCHED_3_NUMBERS;
        uint16 MATCHED_4_NUMBERS;
    }

    // Stores data about every player
    address[] private PLAYERS;

    //Lottery related stuff
    uint256 constant GAME_LENGTH = SECONDS_IN_DAY;
    uint256 internal RANDOM_NUMBER;
    uint256 internal TICKET_FEE_wBNB = 0.0059 * 10**18; // 0.0059 BNB
    uint256 internal TICKET_FEE_RBX = 8 * 10**18; // 5 RBX

    uint256 private JACKPOT_PRIZE_wBNB;
    uint256 private JACKPOT_PRIZE_RBX;
    uint256 internal ACTIVE_POOL;
    uint256 private TICKETS_PURCHASED = 0;
    uint256 private TOTAL_TICKETS_SOLD;

    constructor(
        address payable _wBNBAddress,
        IVRF _VRF,
        IBEP20 _RBX,
        IBEP20 _wBNB,
        address _DEV,
        address _STAKING,
        ISTAKE _STAKING2
    ) public {
        VRF = _VRF;
        wBNBaddress = _wBNBAddress;
        RBX = _RBX;
        wBNB = _wBNB;
        DEVADDRESS = _DEV;
        STAKINGADDRESS = _STAKING;
        STAKING = _STAKING2;
    }

    function isPlayer(uint256 id, address _address) public view returns (bool) {
        if (PLAYERS[id] == _address) {
            return true;
        } else {
            return false;
        }
    }
    
    function updateStakingAddress(ISTAKE _newAddress, address _newStakingAddress) public onlyOwner {
        STAKING = _newAddress;
        STAKINGADDRESS = _newStakingAddress;
        emit newStakingAddress(_newStakingAddress);
    }
    
    function newFee(uint256 _RBX, uint256 _BNB) public onlyOwner {
        TICKET_FEE_RBX = _RBX;
        TICKET_FEE_wBNB = _BNB;
        emit FeeChanged(_RBX, _BNB);
    }

    /* @dev Lottery buy functions */
    function buyWithoutDiscount(uint256 QTY)
        external
        payable
        returns (uint8 success)
    {
        require(QTY <= 50, "RBX LOTTERY: MAX 50 IS ALLOWED");
        require(QTY > 0, "RBX LOTTERY: INCORRECT VALUE");

        updatePool();
        uint256 FINAL_DUE = TICKET_FEE_wBNB.mul(QTY);

        if (msg.value > 0) {
            require(msg.value >= FINAL_DUE, "RBX LOTTERY: Wrong value");
            wrapBNB();
        }

        if (msg.value == 0) {
            wBNB.safeTransferFrom(msg.sender, address(this), FINAL_DUE);
        }

        sendShares(QTY, 1);

        PLAYERS.push(msg.sender);

        uint256[2] memory _JACKPOT_TREASURY = calcJackpot(QTY, 1);
        JACKPOT_PRIZE_wBNB = JACKPOT_PRIZE_wBNB.add(_JACKPOT_TREASURY[0]);

        uint256[2] memory _REGULAR_POT = calcRegularPot(QTY, 1);
        POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_wBNB
        .add(_REGULAR_POT[0]);
        ROUNDS[ACTIVE_POOL].TICKETS_SOLD = ROUNDS[ACTIVE_POOL].TICKETS_SOLD.add(
            QTY
        );

        if (QTY == 1) {
            uint[] memory R = expand(now, 4);
            _TICKETDATA[TICKETS_PURCHASED] = TICKETDATA(
                _msgSender(),
                ACTIVE_POOL,
                QTY,
                [
                    (RandomNumber(R[0]) % 18),
                    (RandomNumber(R[1]) % 18),
                    (RandomNumber(R[2]) % 18),
                    (RandomNumber(R[3]) % 10)
                ],
                0,
                0,
                0,
                0,
                0
            );
        } else {
            for (
                uint256 i = TICKETS_PURCHASED;
                i <= TICKETS_PURCHASED.add(QTY - 1);
                i++
            ) {
                uint[] memory R = expand(i, 4);
                _TICKETDATA[i] = TICKETDATA(
                    _msgSender(),
                    ACTIVE_POOL,
                    QTY,
                    [
                        (RandomNumber(R[0]) % 18),
                        (RandomNumber(R[1]) % 18),
                        (RandomNumber(R[2]) % 18),
                        (RandomNumber(R[3]) % 10)
                    ],
                    0,
                    0,
                    0,
                    0,
                    0
                );
            }
        }
        TICKETS_PURCHASED = TICKETS_PURCHASED.add(QTY);
        emit BuyTicketsWithoutDiscount(msg.sender, TICKETS_PURCHASED.sub(QTY), TICKETS_PURCHASED - 1, ACTIVE_POOL);
        return 1;
    }

    function buyWithDiscount(uint256 QTY)
        external
        returns (uint8 success)
    {
        require(QTY <= 50, "RBX LOTTERY: MAX 50 IS ALLOWED");
        require(QTY > 0, "RBX LOTTERY: INCORRECT VALUE");

        updatePool();

        uint256 FINAL_DUE_RBX = TICKET_FEE_RBX.mul(QTY);

        RBX.safeTransferFrom(msg.sender, address(this), FINAL_DUE_RBX);

        sendShares(QTY, 0);
        PLAYERS.push(msg.sender);

        uint256[2] memory _JACKPOT_TREASURY = calcJackpot(QTY, 0);
        JACKPOT_PRIZE_RBX = JACKPOT_PRIZE_RBX.add(_JACKPOT_TREASURY[1]);

        uint256[2] memory _REGULAR_POT = calcRegularPot(QTY, 0);
        POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX = POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_RBX
        .add(_REGULAR_POT[1]);

        ROUNDS[ACTIVE_POOL].TICKETS_SOLD = ROUNDS[ACTIVE_POOL].TICKETS_SOLD.add(
            QTY
        );

        if (QTY == 1) {
            uint256[] memory R = expand(now, 4);
            _TICKETDATA[TICKETS_PURCHASED] = TICKETDATA(
                _msgSender(),
                ACTIVE_POOL,
                QTY,
                [
                    (RandomNumber(R[0]) % 18),
                    (RandomNumber(R[1]) % 18),
                    (RandomNumber(R[2]) % 18),
                    (RandomNumber(R[3]) % 10)
                ],
                0,
                0,
                0,
                0,
                0
            );
        } else {
            for (
                uint256 i = TICKETS_PURCHASED;
                i <= TICKETS_PURCHASED.add(QTY - 1);
                i++
            ) {
                uint[] memory R = expand(i, 4); // Random number generator
                _TICKETDATA[i] = TICKETDATA(
                    _msgSender(),
                    ACTIVE_POOL,
                    QTY,
                    [
                        (RandomNumber(R[0]) % 18),
                        (RandomNumber(R[1]) % 18),
                        (RandomNumber(R[2]) % 18),
                        (RandomNumber(R[3]) % 10)
                    ],
                    0,
                    0,
                    0,
                    0,
                    0
                );
            }
        }
        TICKETS_PURCHASED = TICKETS_PURCHASED.add(QTY);
        emit BuyTicketsWithDiscount(msg.sender, TICKETS_PURCHASED.sub(QTY), TICKETS_PURCHASED - 1, ACTIVE_POOL);
        return 1;
    }

    /* Claim functions */
    function claim() public returns (bool success) {
        require(
            balanceToClaim[msg.sender].RBX > 0 ||
                balanceToClaim[msg.sender].wBNB > 0,
            "RBX Lottery: No reward to claim"
        );
        uint256 RBXToClaim = balanceToClaim[msg.sender].RBX;
        uint256 wBNBToClaim = balanceToClaim[msg.sender].wBNB;

        RBX.safeTransfer(msg.sender, RBXToClaim);
        wBNB.safeTransfer(msg.sender, wBNBToClaim);

        balanceToClaim[msg.sender].RBX = 0;
        balanceToClaim[msg.sender].wBNB = 0;
        emit Claim (msg.sender);
        return true;
    }

    /* @dev Lottery related functions */

    function updatePool() private {
        if (ROUNDS[ACTIVE_POOL].ROUND_END_TIMESTAMP == 0) {
            ROUNDS[ACTIVE_POOL].ROUND_START_TIMESTAMP = now;
            ROUNDS[ACTIVE_POOL].ROUND_END_TIMESTAMP = now.add(GAME_LENGTH);
        }
        if (ROUNDS[ACTIVE_POOL].ROUND_END_TIMESTAMP <= now) {
            if (ROUNDS[ACTIVE_POOL].TICKETS_SOLD <= 100) {
                ROUNDS[ACTIVE_POOL].ROUND_END_TIMESTAMP = now.add(GAME_LENGTH);
            }
            if (ROUNDS[ACTIVE_POOL].TICKETS_SOLD >= 100) {
                require(
                    ROUNDS[ACTIVE_POOL].WINNERS_PICKED == 1,
                    "RBX: Winners needs to picked first!"
                );
                ACTIVE_POOL++;
                ROUNDS[ACTIVE_POOL].ROUND_START_TIMESTAMP = now;
                ROUNDS[ACTIVE_POOL].ROUND_END_TIMESTAMP = now.add(GAME_LENGTH);
            }
        }
    }

    function updatePots() internal {
        POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX = POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX.add(550 * 10**18); //Inject 550 RBX
        
        ROUNDS[ACTIVE_POOL].FIRST_POT_RBX = ROUNDS[ACTIVE_POOL].FIRST_POT_RBX.add(POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_RBX
        .mul(20)
        .div(100));
        ROUNDS[ACTIVE_POOL].SECOND_POT_RBX = ROUNDS[ACTIVE_POOL].SECOND_POT_RBX.add(POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_RBX
        .mul(30)
        .div(100));
        ROUNDS[ACTIVE_POOL].THIRD_POT_RBX = ROUNDS[ACTIVE_POOL].THIRD_POT_RBX.add(POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_RBX
        .mul(50)
        .div(100));

        ROUNDS[ACTIVE_POOL].FIRST_POT_wBNB = ROUNDS[ACTIVE_POOL].FIRST_POT_wBNB.add(POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_wBNB
        .mul(20)
        .div(100));
        ROUNDS[ACTIVE_POOL].SECOND_POT_wBNB = ROUNDS[ACTIVE_POOL].SECOND_POT_wBNB.add(POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_wBNB
        .mul(30)
        .div(100));
        ROUNDS[ACTIVE_POOL].THIRD_POT_wBNB = ROUNDS[ACTIVE_POOL].THIRD_POT_wBNB.add(POOLS[ACTIVE_POOL]
        .REGULAR_PRIZE_wBNB
        .mul(50)
        .div(100));
    }

    function drawLuckyNumbers() public returns (bool) {
        require(
            now >= ROUNDS[ACTIVE_POOL].ROUND_END_TIMESTAMP,
            "RBX: Lottery in progress!"
        );
        require(
            VRF.returnRandomness() > 0,
            "RBX:Random numbers not generated yet"
        );
        require(
            VRF.returnRandomness() != RANDOM_NUMBER,
            "RBX:Random numbers not generated yet"
        );
        require(ROUNDS[ACTIVE_POOL].TICKETS_SOLD >= 100);
        uint256[] memory _RandomNumber = expand(VRF.returnRandomness(), 4);
        ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[0] = (_RandomNumber[0] % 18);
        ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[1] = (_RandomNumber[1] % 18);
        ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[2] = (_RandomNumber[2] % 18);
        ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[3] = (_RandomNumber[3] % 10);
        updatePots();
        countWinners();
        moveUnspent();
        updateWinnerBalances();
        updatePool();
        RANDOM_NUMBER = VRF.returnRandomness();
        emit DrawLuckyNumbers(ACTIVE_POOL);
        return true;
    }

    //Wrap BNB
    function wrapBNB() public payable {
        require(msg.value > 0);
        IBEP20(wBNBaddress).deposit{value: msg.value}();
        IBEP20(wBNBaddress).transfer(address(this), msg.value);
    }

    function countWinners() internal {
        for (uint256 i = TICKETS_PURCHASED.sub(ROUNDS[ACTIVE_POOL].TICKETS_SOLD); i < TICKETS_PURCHASED - 1; i++) {
            if (_TICKETDATA[i].MATCHED == 0) {
                if (
                    _TICKETDATA[i].LUCKY_NUMBERS[0] ==
                    ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[0] &&
                    _TICKETDATA[i].LUCKY_NUMBERS[1] ==
                    ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[1] &&
                    _TICKETDATA[i].LUCKY_NUMBERS[2] ==
                    ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[2] &&
                    _TICKETDATA[i].LUCKY_NUMBERS[3] ==
                    ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[3] &&
                    _TICKETDATA[i].MATCHED != 1
                ) {
                    _TICKETDATA[i].MATCHED = 1;
                    _TICKETDATA[i].Jackpot = _TICKETDATA[i].Jackpot.add(1);
                }
                POOLS[ACTIVE_POOL].MATCHED_4_NUMBERS + 1;
            }
            if (
                _TICKETDATA[i].LUCKY_NUMBERS[0] ==
                ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[0] &&
                _TICKETDATA[i].LUCKY_NUMBERS[1] ==
                ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[1] &&
                _TICKETDATA[i].LUCKY_NUMBERS[2] ==
                ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[2] &&
                _TICKETDATA[i].MATCHED != 1
            ) {
                _TICKETDATA[i].Three = _TICKETDATA[i].Three.add(1);
                POOLS[ACTIVE_POOL].MATCHED_3_NUMBERS =
                    POOLS[ACTIVE_POOL].MATCHED_3_NUMBERS +
                    1;
                _TICKETDATA[i].MATCHED = 1;
            }
            if (
                _TICKETDATA[i].LUCKY_NUMBERS[0] ==
                ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[0] &&
                _TICKETDATA[i].LUCKY_NUMBERS[1] ==
                ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[1] &&
                _TICKETDATA[i].MATCHED != 1
            ) {
                _TICKETDATA[i].MATCHED = 1;
                _TICKETDATA[i].Two = _TICKETDATA[i].Two.add(1);

                POOLS[ACTIVE_POOL].MATCHED_2_NUMBERS =
                    POOLS[ACTIVE_POOL].MATCHED_2_NUMBERS +
                    1;
            }
            if (
                _TICKETDATA[i].LUCKY_NUMBERS[0] ==
                ROUNDS[ACTIVE_POOL].WINNING_NUMBERS[0] &&
                _TICKETDATA[i].MATCHED != 1
            ) {
                _TICKETDATA[i].MATCHED = 1;
                _TICKETDATA[i].One = _TICKETDATA[i].One.add(1);
                POOLS[ACTIVE_POOL].MATCHED_1_NUMBER =
                    POOLS[ACTIVE_POOL].MATCHED_1_NUMBER +
                    1;
            }
        }
    }

    function moveUnspent() internal {
        if (POOLS[ACTIVE_POOL].MATCHED_1_NUMBER == 0) {
            POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_RBX = POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_RBX.add(ROUNDS[ACTIVE_POOL].FIRST_POT_RBX);
            
            POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_wBNB.add(ROUNDS[ACTIVE_POOL].FIRST_POT_wBNB);

            ROUNDS[ACTIVE_POOL].FIRST_POT_RBX = 0;
            ROUNDS[ACTIVE_POOL].FIRST_POT_wBNB = 0;
        }
        if (POOLS[ACTIVE_POOL].MATCHED_2_NUMBERS == 0) {
            POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_RBX = POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_RBX.add(ROUNDS[ACTIVE_POOL].SECOND_POT_RBX);

            POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_wBNB.add(ROUNDS[ACTIVE_POOL].SECOND_POT_wBNB);

            ROUNDS[ACTIVE_POOL].SECOND_POT_RBX = 0;
            ROUNDS[ACTIVE_POOL].SECOND_POT_wBNB = 0;
        }

        if (POOLS[ACTIVE_POOL].MATCHED_3_NUMBERS == 0) {
            POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_RBX = POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_RBX.add(ROUNDS[ACTIVE_POOL].THIRD_POT_RBX);
            
            POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL.add(1)].REGULAR_PRIZE_wBNB.add(ROUNDS[ACTIVE_POOL].THIRD_POT_wBNB);

            ROUNDS[ACTIVE_POOL].THIRD_POT_RBX = 0;
            ROUNDS[ACTIVE_POOL].THIRD_POT_wBNB = 0;
        }
        ROUNDS[ACTIVE_POOL].WINNERS_PICKED = 1;
    }
    

    function updateWinnerBalances() internal {
        for (uint256 i = TICKETS_PURCHASED.sub(ROUNDS[ACTIVE_POOL].TICKETS_SOLD); i < TICKETS_PURCHASED - 1; i++) {
            if (_TICKETDATA[i].Jackpot > 0) {
                uint256 JackPotPerTicketwBNB = JACKPOT_PRIZE_wBNB.div(
                    POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_4_NUMBERS
                );
                uint256 JackPotPerTicketRBX = JACKPOT_PRIZE_RBX.div(
                    POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_4_NUMBERS
                );
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS]
                .wBNB = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].wBNB.add(
                    JackPotPerTicketwBNB
                );
                
                JackPotPerTicketwBNB.sub(JackPotPerTicketRBX);
                
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS]
                .RBX = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].RBX.add(
                    JackPotPerTicketRBX
                );
                
                JACKPOT_PRIZE_RBX.sub(JackPotPerTicketRBX);
            }

            if (_TICKETDATA[i].Three > 0) {
                uint256 PrizePerTicketwBNB = ROUNDS[_TICKETDATA[i].ROUND_JOINED]
                .THIRD_POT_wBNB
                .div(POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_3_NUMBERS);
                uint256 PrizePerTicketRBX = ROUNDS[_TICKETDATA[i].ROUND_JOINED]
                .THIRD_POT_RBX
                .div(POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_3_NUMBERS);
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS]
                .wBNB = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].wBNB.add(
                    PrizePerTicketwBNB
                );
                
                
                
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].RBX = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].RBX.add(PrizePerTicketRBX);
                
                
            }

            if (_TICKETDATA[i].Two > 0) {
                uint256 PrizePerTicketwBNB = ROUNDS[_TICKETDATA[i].ROUND_JOINED]
                .SECOND_POT_wBNB
                .div(POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_2_NUMBERS);
                uint256 PrizePerTicketRBX = ROUNDS[_TICKETDATA[i].ROUND_JOINED]
                .SECOND_POT_RBX
                .div(POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_2_NUMBERS);
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS]
                .wBNB = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].wBNB.add(
                    PrizePerTicketwBNB
                );
                
                
                
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS]
                .RBX = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].RBX.add(
                    PrizePerTicketRBX
                );
                
                
            }

            if (_TICKETDATA[i].One > 0) {
                uint256 PrizePerTicketwBNB = ROUNDS[_TICKETDATA[i].ROUND_JOINED]
                .FIRST_POT_wBNB
                .div(POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_1_NUMBER);
                uint256 PrizePerTicketRBX = ROUNDS[_TICKETDATA[i].ROUND_JOINED]
                .FIRST_POT_RBX
                .div(POOLS[_TICKETDATA[i].ROUND_JOINED].MATCHED_1_NUMBER);
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS]
                .wBNB = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].wBNB.add(
                    PrizePerTicketwBNB
                );
                
                
                
                balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS]
                .RBX = balanceToClaim[_TICKETDATA[i].PLAYER_ADDRESS].RBX.add(
                    PrizePerTicketRBX
                );
                
            }
        }
    }

    function sendShares(uint256 QTY, uint16 condition) internal {
        uint256 FEE_wBNB = QTY.mul(TICKET_FEE_wBNB);
        uint256 FEE_RBX = QTY.mul(TICKET_FEE_RBX);

        uint256 Devs_RBX_Share = FEE_RBX.mul(DEVS_SHARE) / 100;
        uint256 Community_RBX_Share = FEE_RBX.mul(COMMUNITY_SHARE) / 100;

        uint256 Devs_wBNB_Share = FEE_wBNB.mul(DEVS_SHARE) / 100;

        uint256 Community_wBNB_Share = FEE_wBNB.mul(COMMUNITY_SHARE) / 100;

        if (condition == 1) {
            wBNB.safeTransfer(STAKINGADDRESS, Community_wBNB_Share);
            wBNB.safeTransfer(DEVADDRESS, Devs_wBNB_Share);
            STAKING.topUp(Community_wBNB_Share, 0);
        }

        if (condition == 0) {
            RBX.safeTransfer(STAKINGADDRESS, Community_RBX_Share);
            RBX.safeTransfer(DEVADDRESS, Devs_RBX_Share);
            STAKING.topUp(0, Community_RBX_Share);
        }
    }
    
    function addFundsToPool(uint256 _RBX, uint256 _BNB) public payable {
        if(_RBX > 0 && _BNB > 0) {
            if(msg.value != 0 ) {
                require(msg.value >= _BNB);
                wrapBNB();
                POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB.add(_BNB.div(2));
                JACKPOT_PRIZE_wBNB = JACKPOT_PRIZE_wBNB.add(_BNB.div(2));
            } if(msg.value == 0) {
                wBNB.safeTransferFrom(msg.sender, address(this), _BNB);
                POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB.add(_BNB.div(2));
                JACKPOT_PRIZE_wBNB = JACKPOT_PRIZE_wBNB.add(_BNB.div(2));
            }
            RBX.safeTransferFrom(msg.sender, address(this), _RBX);
            POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX = POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX.add(_RBX.div(2));
            JACKPOT_PRIZE_RBX = JACKPOT_PRIZE_RBX.add(_RBX.div(2));
        } if(_RBX > 0 && _BNB == 0) {
            RBX.safeTransferFrom(msg.sender, address(this), _RBX);
            POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX = POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX.add(_RBX.div(2));
            JACKPOT_PRIZE_RBX = JACKPOT_PRIZE_RBX.add(_RBX.div(2));
        } else {
            if(msg.value != 0 ) {
                wrapBNB();
                POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB.add(_BNB.div(2));
                JACKPOT_PRIZE_wBNB = JACKPOT_PRIZE_wBNB.add(_BNB.div(2));
            } if(msg.value == 0) {
                wBNB.safeTransferFrom(msg.sender, address(this), _BNB);
                POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB = POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB.add(_BNB.div(2));
                JACKPOT_PRIZE_wBNB = JACKPOT_PRIZE_wBNB.add(_BNB.div(2));
            }
            
        }
        
    }

    /* Random Number Generator */

    function getNewRandomNumber() public onlyOwner {
        VRF.getRandomNumber();
    }

    function RandomNumber(uint256 ONE) internal view returns (uint256) {
        uint256 RANDOM = uint256(
            keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    TICKETS_PURCHASED,
                    ONE
                )
            )
        );
        return RANDOM;
    }

    function expand(uint256 randomValue, uint256 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /* VIEW FUNCTIONS */

    function getWinningNumbers(uint256 ROUND_NUMBER)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 a = ROUNDS[ROUND_NUMBER].WINNING_NUMBERS[0];
        uint256 b = ROUNDS[ROUND_NUMBER].WINNING_NUMBERS[1];
        uint256 c = ROUNDS[ROUND_NUMBER].WINNING_NUMBERS[2];
        uint256 d = ROUNDS[ROUND_NUMBER].WINNING_NUMBERS[3];
        return (a, b, c, d);
    }

    function getTicketData(uint256 ticketID)
        public
        view
        returns (
            address player,
            uint256 ticketsPurchased,
            uint256[4] memory LuckyNumbers,
            uint256 Round
        )
    {
        return (
            _TICKETDATA[ticketID].PLAYER_ADDRESS,
            _TICKETDATA[ticketID].TICKETS_BOUGHT,
            _TICKETDATA[ticketID].LUCKY_NUMBERS,
            _TICKETDATA[ticketID].ROUND_JOINED

        );
    }
    
    
    function isWinner(uint256 ticketID) public view returns(
        uint256 OneNumberPlayed,
        uint256 TwoNumberPlayed,
        uint256 ThreeNumberPlayed,
        uint256 FourNumberPlayed) {
        
        return(
            _TICKETDATA[ticketID].One,
            _TICKETDATA[ticketID].Two,
            _TICKETDATA[ticketID].Three,
            _TICKETDATA[ticketID].Jackpot);
    }
    
    function _balanceOf(address _address) public view returns(uint _RBX, uint BNB) {
        return(balanceToClaim[_address].RBX, balanceToClaim[_address].wBNB);
    }
    
    function getlotteryInfo(uint256 ROUND_ID) public view returns(uint _TICKETS_SOLD, uint JackPotRBX, uint JackpotBNB, uint regularPotRBX, uint regularBNB, uint256 totalTickets, uint256 deadLine) {
        return(ROUNDS[ROUND_ID].TICKETS_SOLD, JACKPOT_PRIZE_RBX, JACKPOT_PRIZE_wBNB, POOLS[ROUND_ID].REGULAR_PRIZE_RBX.add(550 * 10**18), POOLS[ROUND_ID].REGULAR_PRIZE_wBNB, TICKETS_PURCHASED, ROUNDS[ACTIVE_POOL].ROUND_END_TIMESTAMP);
    }
    
    function getFullPot() public view returns(uint256 _RBX, uint256 BNB) {
        return(JACKPOT_PRIZE_RBX.add(POOLS[ACTIVE_POOL].REGULAR_PRIZE_RBX.add(550 * 10**18)), JACKPOT_PRIZE_wBNB.add(POOLS[ACTIVE_POOL].REGULAR_PRIZE_wBNB));
    }
    
    function getActivePool() public view returns(uint) {
        return ACTIVE_POOL;
    }
    
        function getlotteryInfo2(uint256 ROUND_ID) public view returns(uint oneNumberMatched, uint twoNumbersMatched, uint threeNumbersMatched, uint fourNumbersMatched) {
        return(POOLS[ROUND_ID].MATCHED_1_NUMBER, POOLS[ROUND_ID].MATCHED_2_NUMBERS, POOLS[ROUND_ID].MATCHED_3_NUMBERS, POOLS[ROUND_ID].MATCHED_4_NUMBERS);
    }
            function getlotteryInfo3(uint256 ROUND_ID) public view returns(uint[2] memory FIRST_POT, uint[2] memory SECOND_POT, uint[2] memory THIRD_POT) {
        return([ROUNDS[ROUND_ID].FIRST_POT_RBX, ROUNDS[ROUND_ID].FIRST_POT_wBNB], [ROUNDS[ROUND_ID].SECOND_POT_RBX, ROUNDS[ROUND_ID].SECOND_POT_wBNB], [ROUNDS[ROUND_ID].THIRD_POT_RBX, ROUNDS[ROUND_ID].THIRD_POT_wBNB]);
    }
    
    

    /* PRIVATE VIEW FUNCTIONS */
    function calcJackpot(uint256 TICKET_QTY, uint8 CONDITION)
        internal
        view
        returns (uint256[2] memory)
    {
        uint256 TOTAL_FEE = TICKET_FEE_wBNB.mul(TICKET_QTY);
        uint256 TOTAL_FEE_RBX = TICKET_FEE_RBX.mul(TICKET_QTY);

        uint256 TOTAL_FEE_AFTER_DIST_wBNB = TOTAL_FEE.mul(80).div(100);
        uint256 TOTAL_FEE_AFTER_DIST_RBX = TOTAL_FEE_RBX.mul(80).div(100);

        uint256 JACKPOT_TREASURY_wBNB = TOTAL_FEE_AFTER_DIST_wBNB.mul(45).div(
            100
        );
        uint256 JACKPOT_TREASURY_RBX = TOTAL_FEE_AFTER_DIST_RBX.mul(45).div(
            100
        );

        if (CONDITION == 0) {
            return ([0, JACKPOT_TREASURY_RBX]);
        } else {
            return ([JACKPOT_TREASURY_wBNB, 0]);
        }
    }

    function calcRegularPot(uint256 TICKET_QTY, uint8 CONDITION)
        internal
        view
        returns (uint256[2] memory)
    {
        uint256 TOTAL_FEE_wBNB = TICKET_FEE_wBNB.mul(TICKET_QTY);
        uint256 TOTAL_FEE_RBX = TICKET_FEE_RBX.mul(TICKET_QTY);

        uint256 TOTAL_FEE_AFTER_DIST_wBNB = TOTAL_FEE_wBNB.mul(80).div(100);
        uint256 TOTAL_FEE_AFTER_DIST_RBX = TOTAL_FEE_RBX.mul(80).div(100);

        uint256 _REGULAR_PRIZE_wBNB = TOTAL_FEE_AFTER_DIST_wBNB.mul(55).div(
            100
        );
        uint256 _REGULAR_PRIZE_RBX = TOTAL_FEE_AFTER_DIST_RBX.mul(55).div(100);

        if (CONDITION == 0) {
            return ([0, _REGULAR_PRIZE_RBX]);
        } else {
            return ([_REGULAR_PRIZE_wBNB, 0]);
        }
    }
}