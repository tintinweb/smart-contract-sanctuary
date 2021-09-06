/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

//SPDX-License-Identifier: MIT
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


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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


contract TestUNK {
    using SafeERC20 for IERC20;

    struct User {
        uint256 id;
        address[] workingPoolReferrals;
        address[] autoPoolReferrals;
        mapping(address => U1Matrix) workingPool;
        mapping(address => U2Matrix) autoPool;
        mapping(address => GlobalPool) matrixPool;
    }
    struct U1Matrix {
        address referrer;
        uint8 currentSlot;
        uint256 earning;
        uint reinvestCount;
    }
    struct U2Matrix {
        address referrer;
        uint8 currentSlot; 
        uint256 earning; 
        uint reinvestCount;
    }
    
    struct GlobalPool {
        uint8 level;
        uint256 poolIncome;
        mapping(uint8 => Matrix) globalMatrix;
    }
    
    struct Matrix {
        uint256 matrixId;
        address referrer;
        address[] referrals;
        uint256 poolEarning;
    }
    
    struct Slot {
        uint256 price;
        uint256 limit;
    }

    struct Bonus {
        uint256 uone;
        uint256 utwo;
    }
    
    address public owner;
    address public creator;
    uint256 public lastId;
    IERC20 public tokenAddress;
    
    mapping(uint8 => Bonus) public levelEarning;
    mapping(uint8 => Slot) public slots;
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    
    mapping(uint8 => mapping(uint256 => address)) public matrixIdToAddress;
    mapping(uint8 => uint256) public matrixHeads;
    mapping(uint8 => uint256) public matrixIds;
    mapping (uint8 => uint256) public levels;
    mapping (uint8 => uint256) public pools;
    
    event Registration(address indexed user, address referrer, uint256 userId);
    event Purchase(address indexed user, uint8 slot, uint8 matrix);
    event EarnedProfit(address indexed user, address referral, uint8 matrix, uint8 slot, uint8 level, uint256 amount);
    event LostProfit(address indexed user, address referral, uint8 matrix, uint8 slot, uint8 level, uint256 amount);
    event ReferralPlaced(address indexed referral, address u1Referrer, address u2Referrer);
    event GlobalReferralPlaced(address indexed referral, address referrer, uint8 pool);
    
    modifier isOwner(address _account) {
        require(creator == _account, "Restricted Access!");
        _;
    }
    
    constructor(address _owner, IERC20 _BUSDTokenAddress ) public {
        slots[1] = Slot(4e18,  20e18);
        slots[2] = Slot(10e18, 50e18);
        slots[3] = Slot(15e18, 75e18);
        slots[4] = Slot(25e18, 125e18);
        slots[5] = Slot(35e18, 175e18);
        slots[6] = Slot(50e18, 250e18);
        slots[7] = Slot(75e18, 375e18);
        slots[8] = Slot(100e18, 500e18);
        slots[9] = Slot(150e18, 750e18);
        slots[10] = Slot(200e18, 1000e18);
        
        pools[1]  = 2e18;
        pools[2]  = 10e18;
        pools[3]  = 15e18;
        pools[4]  = 20e18;
        pools[5]  = 30e18;
        pools[6]  = 40e18;
        pools[7]  = 50e18;
        pools[8]  = 80e18;
        pools[9]  = 100e18;
        pools[10] = 125e18;
        pools[11] = 150e18;
        pools[12] = 180e18;
        pools[13] = 200e18;
        pools[14] = 250e18;
        pools[15] = 300e18;
        pools[16] = 350e18;
        pools[17] = 400e18;
        pools[18] = 450e18;
        pools[19] = 550e18;
        pools[20] = 650e18;
        pools[21] = 800e18;
        pools[22] = 900e18;
        pools[23] = 1000e18;
        pools[24] = 1100e18;
        pools[25] = 1400e18;
        pools[26] = 1500e18;
        pools[27] = 1800e18;
        pools[28] = 2000e18;
        pools[29] = 2200e18;
        pools[30] = 2500e18;
        pools[31] = 2800e18;
        pools[32] = 3000e18;
        pools[33] = 3300e18;
        pools[34] = 3500e18;
        pools[35] = 3800e18;
        pools[36] = 4000e18;
        pools[37] = 4300e18;
        pools[38] = 4500e18;
        pools[39] = 4800e18;
        pools[40] = 5000e18;
        
        levelEarning[1]  = Bonus(50, 10);
        levelEarning[2]  = Bonus(10, 8);
        levelEarning[3]  = Bonus(8, 5);
        levelEarning[4]  = Bonus(6, 5);
        levelEarning[5]  = Bonus(5, 4);
        levelEarning[6]  = Bonus(4, 3);
        levelEarning[7]  = Bonus(3, 2);
        levelEarning[8]  = Bonus(2, 1);
        levelEarning[9]  = Bonus(1, 1);
        levelEarning[10] = Bonus(1, 1);
        
        owner = _owner;
        creator = msg.sender;
        tokenAddress = _BUSDTokenAddress;

        lastId++;
        User memory account = User({
            id: lastId,
            workingPoolReferrals: new address[](0),
            autoPoolReferrals: new address[](0)
        });
        users[owner] = account;
        idToAddress[lastId] = _owner;

        users[owner].workingPool[owner].referrer = address(0);
        users[owner].workingPoolReferrals = new address[](0);
        users[owner].autoPool[owner].referrer = address(0);
        users[owner].autoPoolReferrals = new address[](0);
        users[owner].workingPool[owner].currentSlot = 10;
        users[owner].autoPool[owner].currentSlot = 10;
        
        users[owner].matrixPool[owner].level = 40;
        for (uint8 i = 1; i <= 40; i++) {
            matrixHeads[i] = lastId;
            matrixIds[i] = lastId;
            matrixIdToAddress[i][lastId] = owner;
            users[owner].matrixPool[owner].globalMatrix[i].matrixId = lastId; 
            users[owner].matrixPool[owner].globalMatrix[i].referrer = address(0);
            users[owner].matrixPool[owner].globalMatrix[i].referrals = new address[](0);
        }
    }
    
    fallback() external {
        if(msg.data.length == 0) {
            return _createAccount(msg.sender, owner);
        }
        _createAccount(msg.sender, bytesToAddress(msg.data));
    }
    
    function registration(address _addr, address _referrer) external {
        require(!isUserExists(_addr), "User registered");
        require(isUserExists(_referrer), "Invalid referrer");
        tokenAddress.safeTransferFrom(msg.sender, address(this), 10e18);
        _createAccount(_addr, _referrer);
    }
    
    function purchase(uint8 _matrix, uint8 _slotId) external {
        require(isUserExists(msg.sender), "User not registered!");
        require((_matrix == 1 || _matrix == 2), "Invalid matrix");
        uint8 currentSlot;
        if (_matrix == 1) {
            currentSlot = users[msg.sender].workingPool[msg.sender].currentSlot;
            require(_slotId == currentSlot+1, "Invalid Slot");
        }
        else {
            currentSlot = users[msg.sender].autoPool[msg.sender].currentSlot;
            require(_slotId == currentSlot+1, "Invalid Slot");
        }
        tokenAddress.safeTransferFrom(msg.sender, address(this), slots[_slotId].price);
        _activateSlots(msg.sender, _slotId, _matrix);
        emit Purchase(msg.sender, _slotId, _matrix);
    }
    
    function purchaseMatrix(uint8 _pool) external {
        require(isUserExists(msg.sender), "User not registered!");
        require(_pool >= 1 && _pool <= 40, "Invalid Matrix");
        require(_pool == users[msg.sender].matrixPool[msg.sender].level + 1, "Invalid Pool");
        tokenAddress.safeTransferFrom(msg.sender, address(this), pools[_pool]);
        _activateMatrix(_pool, pools[_pool]);
    }
    
    function _createAccount(address _addr, address _referrer) internal {
        
        address _referrerU2;
        _referrerU2 = findFreeReferrer(_referrer);
        
        lastId++;
        User memory account = User({
            id: lastId,
            workingPoolReferrals: new address[](0),
            autoPoolReferrals: new address[](0)
        });
        users[_addr] = account;
        idToAddress[lastId] = _addr;

        users[_addr].workingPool[_addr].referrer = _referrer;
        users[_referrer].workingPoolReferrals.push(_addr);
        users[_addr].autoPool[_addr].referrer = _referrerU2;
        users[_referrerU2].autoPoolReferrals.push(_addr);
        emit ReferralPlaced(_addr, _referrer, _referrerU2);
        _activateSlots(_addr, 1, 1);
        _activateSlots(_addr, 1, 2);
        _activateMatrix(1, pools[1]);
        emit Registration(_addr, _referrer, lastId);
    }

   function _activateSlots(address _addr, uint8 _slotId, uint8 _matrix) internal {
        if (_matrix == 1) {
            users[_addr].workingPool[_addr].currentSlot = _slotId;
        }
        else {
            users[_addr].autoPool[_addr].currentSlot = _slotId;
        }
        (uint256 _flush, uint256 _fee) = _sendDividends(_addr, _slotId, _matrix);
        tokenAddress.safeTransfer(address(owner), (_fee + _flush));
    }



    function _activateMatrix(uint8 _pool, uint256 _amount) internal {
        
        matrixIds[_pool]++;
        users[msg.sender].matrixPool[msg.sender].level = _pool;
        users[msg.sender].matrixPool[msg.sender].globalMatrix[_pool].matrixId = matrixIds[_pool];
        matrixIdToAddress[_pool][matrixIds[_pool]] = msg.sender;
        address _referrer = _findGlobalReferrer(matrixHeads[_pool], _pool);
        users[msg.sender].matrixPool[msg.sender].globalMatrix[_pool].referrer = _referrer;
        users[_referrer].matrixPool[_referrer].globalMatrix[_pool].referrals.push(msg.sender);
        emit GlobalReferralPlaced(msg.sender, _referrer, _pool);
    
        address[3] memory _payaddresses; 
        uint256[3] memory _payamount;
        _payaddresses[0] = _referrer;
        _payaddresses[1] = getReferrrers(1, msg.sender, 1);
        _payaddresses[2] = owner;
        _payamount[0] = _amount * 80 / 100;
        _payamount[1] = _amount * 10 / 100;
        _payamount[2] = _amount * 10 / 100;

        for (uint8 i; i < _payaddresses.length; i++) {
            tokenAddress.safeTransfer(_payaddresses[i], _payamount[i]);
        }
        
        users[_referrer].matrixPool[_referrer].poolIncome += _amount;
        users[_referrer].matrixPool[_referrer].globalMatrix[_pool].poolEarning += _amount;
        emit EarnedProfit(_referrer, msg.sender, 3, 0, _pool, _amount);
        emit Purchase(msg.sender, _pool, 3);
    }


    function getReferrrers(uint8 height, address _addr, uint8 _matrix) public view returns (address) {
        if (height <= 0 || _addr == address(0)) {
            return _addr;
        }
        if (_matrix == 1) {
            return getReferrrers(height - 1, users[_addr].workingPool[_addr].referrer, _matrix);    
        }
        else {
            return getReferrrers(height - 1, users[_addr].autoPool[_addr].referrer, _matrix);
        }
    }
    
    
    function _findGlobalReferrer(uint256 _head, uint8 _pool) internal returns(address) {
        address _top = matrixIdToAddress[_pool][_head];
        if (users[_top].matrixPool[_top].globalMatrix[_pool].referrals.length < 2) {
            matrixHeads[_pool] = users[_top].matrixPool[_top].globalMatrix[_pool].matrixId;
            return _top;
        }
		return _findGlobalReferrer(matrixHeads[_pool] + 1, _pool);
    }


    function findFreeReferrer(address _addr) public view returns(address) {
        if (users[_addr].autoPoolReferrals.length < 2) {
            return _addr;
        }
        bool noReferrer = true;
        address referrer;
        address[] memory referrals = new address[](510);
        referrals[0] = users[_addr].autoPoolReferrals[0];
        referrals[1] = users[_addr].autoPoolReferrals[1];

        for(uint i = 0; i < 2046; i++) {
            if(users[referrals[i]].autoPoolReferrals.length == 2) {
                if( i < 1022) {
                    referrals[(i+1)*2] = users[referrals[i]].autoPoolReferrals[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].autoPoolReferrals[1];
                }
            } 
            else {
                noReferrer = false;
                referrer = referrals[i];
                break;
            }
        }
        require(!noReferrer, "No Free Referrer");
        return referrer;
    }

    function _sendDividends(address _addr, uint8 _slotId, uint8 _matrix) internal returns (uint, uint) {
        uint256 _slotLimit = slots[_slotId].price * 90 / 100;
        uint256 _fee = slots[_slotId].price * 10 / 100;
        _slotLimit = _slotLimit - _sendLevelCommission(_addr, _matrix, _slotId);
        
        if (_slotId > 1) {
            for (uint8 _level = 1; _level <= 10; _level++) {
                address _referrer = getReferrrers(_level, _addr, _matrix);
                if (_referrer == address(0)) {
                    break;
                }
                (uint _earning, uint _maxLimit, uint _bonus) = _getLevelDistribution(_referrer, _slotId, _matrix, _level);
                if ((_earning + _bonus) < _maxLimit) {
                    if (_matrix == 1) {
                        users[_referrer].workingPool[_referrer].earning += _bonus;    
                    }
                    else {
                        users[_referrer].autoPool[_referrer].earning += _bonus; 
                    }
                    _processPayout(_referrer, _bonus);
                    _slotLimit = _slotLimit -  _bonus;
                    emit EarnedProfit(_referrer, _addr, _matrix, _slotId, _level, _bonus);
                }
                else {
                    if (((_earning + _bonus) - _maxLimit) > 0 && _earning < _maxLimit) {
                        if (_matrix == 1) {
                            users[_referrer].workingPool[_referrer].earning += (_maxLimit - _earning);    
                        }
                        else {
                            users[_referrer].autoPool[_referrer].earning += (_maxLimit - _earning); 
                        }
                        _processPayout(_referrer, (_maxLimit - _earning));
                        _slotLimit = _slotLimit - (_maxLimit - _earning);
                        emit EarnedProfit(_referrer, _addr, _matrix, _slotId, _level, (_maxLimit - _earning));
                        emit LostProfit(_referrer, _addr, _matrix, _slotId, _level, _bonus - (_maxLimit - _earning));
                    }
                    else {
                        emit LostProfit(_referrer, _addr, _matrix, _slotId, _level, _bonus);
                    }
                }
            }
        }
        
        return(_slotLimit, _fee);
    }
    
    function _sendLevelCommission(address _addr, uint8 _matrix, uint8 _slotId) internal returns (uint256) {
        uint256 profit;
        uint256 commission;
        
        address _referrer = getReferrrers(1, _addr, 1);
        if (_referrer != address(0)) {
            (uint _earning, uint _maxLimit,) = _getLevelDistribution(_referrer, _slotId, _matrix, 1);
            
            if (_slotId == 1) {
                commission = (slots[_slotId].price * 90) / 100;
            }
            else {
                commission = (slots[_slotId].price * 50) / 100;
            }
            
            if ((commission + _earning) < _maxLimit) {
                _processPayout(_referrer, commission);
                profit = commission;
                users[_referrer].autoPool[_referrer].earning += profit; 
                emit EarnedProfit(_referrer, _addr, _matrix, _slotId, 0, profit);
            }
            else {
                if (((commission + _earning) - _maxLimit) > 0 && _earning < _maxLimit) {
                    profit = _maxLimit - _earning;
                    users[_referrer].autoPool[_referrer].earning += profit;
                    _processPayout(_referrer, profit);
                    emit EarnedProfit(_referrer, _addr, 2, _slotId, 0, profit);
                    emit LostProfit(_referrer, _addr, _matrix, _slotId, 0, (commission - profit));
                }
                else {
                    emit LostProfit(_referrer, _addr, _matrix, _slotId, 0, commission);
                }
            }
        }
        return profit;
    }

    function _getLevelDistribution(address _referrer, uint8 _slotId, uint8 _matrix, uint8 _level) internal view returns(uint256, uint256, uint256) {
        uint256 earning;
        uint256 maxLimit;
        uint256 bonus;
        if (_matrix == 1) {
            bonus = (slots[_slotId].price * levelEarning[_level].uone) / 100;
            earning = users[_referrer].workingPool[_referrer].earning;
            for (uint8 i = 1; i <= users[_referrer].workingPool[_referrer].currentSlot; i++) {
                maxLimit += slots[i].limit;
            }
        }
        else {
            bonus = (slots[_slotId].price * levelEarning[_level].utwo) / 100;
            earning = users[_referrer].autoPool[_referrer].earning;
            for (uint8 i = 1; i <= users[_referrer].autoPool[_referrer].currentSlot; i++) {
                maxLimit += slots[i].limit;
            }
        }
        return(
            earning,
            maxLimit,
            bonus
        );
    }

    function isUserExists(address _addr) public view returns (bool) {
        return (users[_addr].id != 0);
    }
    
    
    function getUserDetails(address _addr) public view returns (uint256, uint8[3] memory, uint256[3] memory, address[2] memory, address[] memory, address[] memory) {
        User storage account = users[_addr];
        U1Matrix storage uone = users[_addr].workingPool[_addr];
        U2Matrix storage utwo = users[_addr].autoPool[_addr];
        GlobalPool storage matrix = users[_addr].matrixPool[_addr];

        return(
            account.id,
            [uone.currentSlot, utwo.currentSlot, matrix.level],
            [uone.earning, utwo.earning, matrix.poolIncome],
            [uone.referrer, utwo.referrer],
            account.workingPoolReferrals,
            account.autoPoolReferrals
        );
    }
    
    function _processPayout(address _addr, uint _amount) private {
        tokenAddress.safeTransfer(_addr, _amount);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function failSafe(address _tokenAddress, address payable _addr) external isOwner(msg.sender) {
        if (_tokenAddress == address(0)) {
            (_addr).transfer(address(this).balance);
        }
        else {
            require(_tokenAddress != address(tokenAddress), "cannot withdraw");
            IERC20(tokenAddress).transfer(_addr, IERC20(tokenAddress).balanceOf(address(this)));
        }

    }
}