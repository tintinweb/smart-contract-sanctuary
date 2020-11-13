// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




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

// File: contracts/crowdsale/crowdsale.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;


interface ERCMintable {
    //function crowdSaleMint(address to, uint256 amount) external returns(bool);
    function mint(address to, uint256 amount) external;
}

/**
* @title IPM Token CrowdSale
* @dev  CrowdSale contract for IPM Token:
*
*       Tokens for Sale: 9M IPM
*       Minted on demand up to the hard cap per round. 
*       Unsold supply won't be minted and will result in a
*       lower circulating supply after the sale. Unsold tokens of each round
*       don't transfer to the next round
*
*       PRIVATE ROUND:
*       - whitelisted
*       - garuanteed allocation, overminted gets reduced from last round
*       - duration of 2 days (10.09.2020 - 12.09.2020)
*       - Min-Max allocation per address 2 ETH - 50 ETH
*       - 1M flexible Cap (ETH price on launch could result in more)
*       - 1 IPM = ~0.15 USD
*
*       ROUND 1:
*       - duration of 2 days (14.09.2020 - 16.09.2020)
*       - 1 IPM = ~0.2 USD
*       - 1M IPM Hard Cap
*
*       ROUND 2:
*       - duration of 2 days (18.09.2020 - 20.09.2020)
*       - 1 IPM = 0.3 USD
*       - 2M IPM Hard Cap
*
*       ROUND 3:
*       - duration of 6 days (22.09.2020 - 28.09.2020)
*       - 1 IPM = 0.4 USD
*       - 5M IPM Hard Cap (possible less, based on private round)
*
*       After CrowdSale:
*       Cooldown phase of 5 days begins
*       and will unpause all tokens.
*
* More at https://timers.network/
*
* @author @KTimersnetwork
*/
contract IPMCrowdSale {
    using SafeMath for uint256;


    //////////////////////////////////////
    // Contract configuration           //
    //////////////////////////////////////
    // owner
    address owner;

    // allow pausing of contract to halt everything beside
    // administrative functions
    bool public paused    =   true;

    // min payment for private round
    uint256 public constant PRIVATE_PAYMENT_MIN =   2 ether;

    // min payment for other rounds
    uint256 public constant PUBLIC_PAYMENT_MIN  =   0.1 ether;

    // max payment is always equal
    uint256 public constant PAYMENT_MAX =   50 ether;


    // crowdsale can mint 9m IPM at maximum for all rounds
    uint256 public constant MAXIMUM_MINTABLE_TOKENS =   9000000000000000000000000;

    // start of private round 09/10/2020 @ 12:00pm UTC
    uint256 public constant PRIVATE_ROUND_START     =   1599739200;
    // end of private round 09/12/2020 @ 12:00pm UTC
    uint256 public constant PRIVATE_ROUND_END       =   1599912000;
    // private sale limit 1m 
    uint256 public constant PRIVATE_ROUND_CAP       =   1000000 * (10**18);

    // start of round 1 09/14/2020 @ 12:00pm UTC
    uint256 public constant ROUND_1_START           =   1600084800;
    // end of round 1 09/16/2020 @ 12:00pm UTC
    uint256 public constant ROUND_1_END             =   1600257600;
    // round 1 sale limit 1m
    uint256 public constant ROUND_1_CAP             =   1000000 * (10**18);

    // start of round 2 09/18/2020 @ 12:00pm UTC
    uint256 public constant ROUND_2_START           =   1600430400;
    // end of round 2 09/20/2020 @ 12:00pm UTC
    uint256 public constant ROUND_2_END             =   1600603200;
    // round 2 sale limit 2m
    uint256 public constant ROUND_2_CAP             =   2000000 * (10**18);

    // start of round 3 09/22/2020 @ 12:00pm UTC
    uint256 public constant ROUND_3_START           =   1600776000;
    // end of round 3 09/28/2020 @ 12:00pm UTC
    uint256 public constant ROUND_3_END             =   1601294400;
    // round 3 sale limit 5m
    uint256 public constant ROUND_3_CAP             =   5000000 * (10**18);

    // sold tokens private round
    uint256 public privateRoundSold;
    // sold tokens round 1
    uint256 public round1Sold;
    // sold tokens round 2
    uint256 public round2Sold;
    // sold tokens round 3
    uint256 public round3Sold;

    // private round white list 
    mapping(address => uint256) public whitelist;
    // contributors
    mapping(address => uint256) public contributors;

    // current rate
    uint256 public ipmPerETH;

    // IPM token references
    address public ipmTokenAddress;

    // withdrawal
    address public foundation1Address;
    address public foundation2Address;

    //////////////////////////////////////
    // Control functions / modifiers    //
    //////////////////////////////////////
    function isPrivateRoundActive() public view returns(bool) {
        return (now >= PRIVATE_ROUND_START && now < PRIVATE_ROUND_END);
    }
    function isRound1Active() public view returns(bool) {
        return (now >= ROUND_1_START && now < ROUND_1_END);
    }

    function isRound2Active() public view returns(bool) {
        return (now >= ROUND_2_START && now < ROUND_2_END);
    }

    function isRound3Active() public view returns(bool) {
        return (now >= ROUND_3_START && now < ROUND_3_END);
    }

    function hasStarted() public view returns(bool) {
        return (now > PRIVATE_ROUND_START);
    }

    function hasEnded() public view returns(bool) {
        return (now > ROUND_3_END);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ifPaused() {
        require(paused == true);
        _;
    }

    modifier ifNotPaused() {
        require(paused == false);
        _;
    }

    modifier saleActive() {
        require(hasStarted() == true, "Error: Sale has not started");
        require(hasEnded() == false, "Error: Sale has already ended");
        require(isPrivateRoundActive() || isRound1Active() || isRound2Active() || isRound3Active(), "Error: No round active at the moment");
        _;
    }

    //////////////////////////////////////
    // Events                           //
    //////////////////////////////////////
    event IPMPurchase(
        address indexed beneficiary,
        uint256 tokensPurchased,
        uint256 weiUsed
    );

    //////////////////////////////////////
    // Implementation                   //
    //////////////////////////////////////

    constructor() public {        
        paused  =   true;
        owner   =   msg.sender;
    }

    function getCurrentIPMRatio() external view returns(uint256) {
        return ipmPerETH;
    }

    function getCurrentRound() external view returns(string memory) {
        if(hasEnded()) {
            return "Finished";
        }
        if(isRound1Active()) {
            return "Pre-Sale Round 1";
        } else if(isRound2Active()) {
            return "Pre-Sale Round 2";
        } else if(isRound3Active()) {
            return "Pre-Sale Round 3";
        }
        return "Private Sale";
    }

    function getCurrentCap() public view returns (uint256) {
        if(hasEnded()) {
            return 0;
        }
        if(isRound1Active()) {
            return ROUND_1_CAP;
        } else if(isRound2Active()) {
            return ROUND_2_CAP;
        } else if(isRound3Active()) {
            return ROUND_3_CAP;
        }
        return PRIVATE_ROUND_CAP;
    }


    /**
     * @dev Used to update the current eth price of 1 IPM
     *      Function is needed to set the final price ahead
     *      of each round and for possible big price changes
     *      of eth itself to keep somewhat stable usd prices
     */
    function updateIPMPerETH(uint256 _tokens) external onlyOwner {
        require(hasEnded() == false, "Error: CrowdSale has ended, no need to update ratio");
        require(_tokens > 0, "Error: IPM per ETH can't be 0");
        require(_tokens != ipmPerETH, "Error: Prices are identical, no changes needed");
        require(_tokens < 100000, "Error: Amount of tokens per ETH seems unrealistically high. Input error?");

        ipmPerETH  =   _tokens;
    }

    function unpause() external onlyOwner ifPaused {
        paused = false;
    }   
    function pause() external onlyOwner ifNotPaused {
        paused = true;
    }


    function getTokenAddress() external view returns(address) {
        return ipmTokenAddress;
    }

    function setIPMTokenContract(address _token) external onlyOwner ifPaused {
        ipmTokenAddress =   _token;
    }

    function setWhitelist(address[] calldata _beneficiaries, uint256[] calldata _weiAmounts) external onlyOwner {
        require(_beneficiaries.length > 0, "Error: Beneficiaries are empty");
        require(_weiAmounts.length > 0, "Error: Investments are empty");
        require(_beneficiaries.length == _weiAmounts.length, "Error: Addresses length is not equal investments");
        
        for(uint256 i=0;i<_beneficiaries.length;i++) {
            whitelist[_beneficiaries[i]]    =   _weiAmounts[i];
        }
    }

    function addOrUpdateWhitelistEntry(address _beneficiary, uint256 _weiAmount) external onlyOwner {
        require(_weiAmount >= PRIVATE_PAYMENT_MIN, "Error: Investment is below private sell minimum");
        require(_weiAmount <= PAYMENT_MAX, "Error: Investment is above maximum sell amount");

        whitelist[_beneficiary]   =   _weiAmount;
    }

    function removeWhitelistEntry(address _beneficiary) external onlyOwner {
        require(whitelist[_beneficiary] > 0, "Error: Address is not whitelisted");
        whitelist[_beneficiary] =   0;
        delete whitelist[_beneficiary];

    }

    function isWhitelisted(address _beneficiary) public view returns(bool) {
        require(_beneficiary != address(0), 'Error: Address cannot be empty');
        return (whitelist[_beneficiary] > 0) ? true:false;
    }

    function setFoundation1Address(address _foundationAddress) external onlyOwner {
        require(_foundationAddress != address(0), 'Error: Address cannot be empty');
        foundation1Address = _foundationAddress;
    }

    function setFoundation2Address(address _foundationAddress) external onlyOwner {
        require(_foundationAddress != address(0), 'Error: Address cannot be empty');
        foundation2Address = _foundationAddress;
    }

    function withdrawFunds() external onlyOwner {
        require(hasStarted() == true, "Error: No reason to withdraw funds before sale has started");
        require(
            isPrivateRoundActive() == false &&
            isRound1Active() == false &&
            isRound2Active() == false &&
            isRound3Active() == false,
            "Error: Withdrawal during active rounds is not allowed"
        );
        require(foundation1Address != address(0), 'Error: No foundation1 wallet set');
        require(foundation2Address != address(0), 'Error: No foundation2 wallet set');

        uint256 fundsAvailable              =   address(this).balance;
        require(fundsAvailable > 0, "Error: No funds available to withdraw");

        uint256 amountForFoundation1Wallet  =   fundsAvailable.div(100).mul(70); 
        uint256 amountForFoundation2Wallet  =   fundsAvailable.sub(amountForFoundation1Wallet);
        require(amountForFoundation1Wallet.add(amountForFoundation2Wallet) == fundsAvailable, "Error: Amount to be sent is not equal the funds");

        payable(foundation1Address).transfer(amountForFoundation1Wallet);
        payable(foundation2Address).transfer(amountForFoundation2Wallet);  
    }

    /**
    * @dev Default fallback function that will also allow
    *      the contract owner to deposit additional ETH,
    *      without triggering the IPM purchase functionality.
    */
    receive() external payable {
        require(msg.value > 0, "Error: No ether received. Msg.value is empty");
        // no need for owner to buy
        if(msg.sender != owner) {
            // let others buy tokens
            _buyTokens(msg.sender, msg.value);
        }
    }

    function _buyTokens(address _beneficiary, uint256 _amountPayedInWei) internal saleActive {
        require(_beneficiary != address(0), "Error: Burn/Mint address cant purchase tokens");
        require(_hasAllowance(_beneficiary), "Error: Address is not allowed to purchase");
        
        require(_amountPayedInWei <= PAYMENT_MAX, "Error: Paymed exceeds maximum single purchase");
        
        uint256 tokensForPayment    =   _calculateTokensForPayment(_amountPayedInWei);
        uint256 tokensLeft          =   _getCurrentRemainingIPM();

        require(tokensForPayment > 0, "Error: payment too low. no tokens for this wei amount");
        require(tokensLeft > 0, "Error: No tokens left for this round");
        require(tokensLeft >= tokensForPayment, "Error: Purchase exceeds remaining tokens for this round");

        if(isPrivateRoundActive()) {
            uint256 alreadyPurchased    =   contributors[_beneficiary];
            uint256 allowedToPurchase   =   whitelist[_beneficiary];

            if(alreadyPurchased == 0) {
                require(_amountPayedInWei >= PRIVATE_PAYMENT_MIN, "Error: Payment smaller than minimum payment");
            }

            uint256 combinedPurchase    =   alreadyPurchased.add(_amountPayedInWei);

            require(combinedPurchase <= allowedToPurchase, "Error: This purchase exceeds the whitelisted limited");
        } 
        
        require(_amountPayedInWei >= PUBLIC_PAYMENT_MIN, "Error: Payment smaller than minimum payment");
        
        ERCMintable(ipmTokenAddress).mint(_beneficiary, tokensForPayment);
        
        if(isRound1Active()) {
            round1Sold = round1Sold.add(tokensForPayment);
        } else if(isRound2Active()) {
            round2Sold = round2Sold.add(tokensForPayment);
        } else if(isRound3Active()) {
            round3Sold = round3Sold.add(tokensForPayment);
        } else {
            privateRoundSold = privateRoundSold.add(tokensForPayment);
        }
        contributors[_beneficiary] =    contributors[_beneficiary].add(_amountPayedInWei);

        emit IPMPurchase(
            _beneficiary,
            tokensForPayment,
            _amountPayedInWei
        ); 
    }

    function _calculateTokensForPayment(uint256 payedWei) internal view returns(uint256) {
        require(payedWei > 0, "Error: Invalid wei amount");

        return payedWei.mul(ipmPerETH);
    }

    function _hasAllowance(address _beneficiary) internal view returns(bool) {
        if(isPrivateRoundActive()) {
            return (whitelist[_beneficiary] > 0);
        }
        return true;
    }

    function _getCurrentRemainingIPM() internal view returns(uint256) {
        if(isRound1Active()) {
            return ROUND_1_CAP.sub(round1Sold);
        } else if(isRound2Active()) {
            return ROUND_2_CAP.sub(round2Sold);
        } else if(isRound3Active()) {
            return ROUND_3_CAP.sub(round3Sold.add(_getPrivateRoundOverhead()));
        }
        return PRIVATE_ROUND_CAP.add(ROUND_3_CAP).sub(privateRoundSold);
    }

    function _getPrivateRoundOverhead() internal view returns(uint256) {
        if(privateRoundSold > PRIVATE_ROUND_CAP) {
            return privateRoundSold.sub(PRIVATE_ROUND_CAP);
        }

        return 0;
    }

}