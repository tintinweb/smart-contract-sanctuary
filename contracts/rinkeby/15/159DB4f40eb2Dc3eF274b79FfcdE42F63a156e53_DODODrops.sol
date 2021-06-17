/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// File: contracts/intf/IERC20.sol

// This is a file copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeMath.sol



/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/SafeERC20.sol


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/SmartRoute/lib/UniversalERC20.sol



library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address payable to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function universalApproveMax(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        uint256 allowance = token.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, uint256(-1));
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function tokenBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        return token.balanceOf(who);
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return token == ETH_ADDRESS;
    }
}

// File: contracts/external/utils/Address.sol

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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

// File: contracts/lib/ReentrancyGuard.sol


/**
 * @title ReentrancyGuard
 * @author DODO Breeder
 *
 * @notice Protect functions from Reentrancy Attack
 */
contract ReentrancyGuard {
    // https://solidity.readthedocs.io/en/latest/control-structures.html?highlight=zero-state#scoping-and-declarations
    // zero-state of _ENTERED_ is false
    bool private _ENTERED_;

    modifier preventReentrant() {
        require(!_ENTERED_, "REENTRANT");
        _ENTERED_ = true;
        _;
        _ENTERED_ = false;
    }
}

// File: contracts/lib/RandomGenerator.sol

interface IRandomGenerator {
    function random(uint256 seed) external view returns (uint256);
}

interface IDODOMidPrice {
    function getMidPrice() external view returns (uint256 midPrice);
}

contract RandomGenerator is IRandomGenerator{
    address[] public pools;

    constructor(address[] memory _pools) public {
        for (uint256 i = 0; i < _pools.length; i++) {
            pools.push(_pools[i]);
        }
    }

    function random(uint256 seed) external override view returns (uint256) {
        uint256 priceSum;
        for (uint256 i = 0; i < pools.length; i++) {
            priceSum += IDODOMidPrice(pools[i]).getMidPrice();
        }
        return uint256(keccak256(abi.encodePacked(blockhash(block.number-1), priceSum, seed)));
    }
}

// File: contracts/lib/InitializableOwnable.sol


/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/external/ERC20/InitializableMintableERC20.sol


contract InitializableMintableERC20 is InitializableOwnable {
    using SafeMath for uint256;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Mint(address indexed user, uint256 value);
    event Burn(address indexed user, uint256 value);

    function init(
        address _creator,
        uint256 _initSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        initOwner(_creator);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initSupply;
        balances[_creator] = _initSupply;
        emit Transfer(address(0), _creator, _initSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint(address user, uint256 value) external onlyOwner {
        _mint(user, value);
    }

    function burn(address user, uint256 value) external onlyOwner {
        _burn(user, value);
    }

    function _mint(address user, uint256 value) internal {
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

    function _burn(address user, uint256 value) internal {
        balances[user] = balances[user].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }
}

// File: contracts/DODODrops/DODODropsV2/DODODrops.sol


interface IDropsFeeModel {
    function getPayAmount(address dodoDrops, address user, uint256 originalPrice, uint256 ticketAmount) external view returns (uint256, uint256);
}

interface IDropsNft {
    function mint(address to, uint256 tokenId) external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

contract DODODrops is InitializableMintableERC20, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using UniversalERC20 for IERC20;

    // ============ Storage ============
    address constant _BASE_COIN_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    address public _BUY_TOKEN_;
    uint256 public _BUY_TOKEN_RESERVE_;
    address public _FEE_MODEL_;
    address payable public _MAINTAINER_;
    address public _NFT_TOKEN_;

    uint256 public _TICKET_UNIT_ = 1; // ticket consumed in a single lottery
    
    uint256 [] public _SELLING_TIME_INTERVAL_;
    uint256 [] public _SELLING_PRICE_SET_;
    uint256 [] public _SELLING_AMOUNT_SET_;
    uint256 public _REDEEM_ALLOWED_TIME_;

    uint256[] public _PROB_INTERVAL_; // index => Interval probability (Only For ProbMode)  
    uint256[][] public _TOKEN_ID_MAP_; // Interval index => tokenIds (Only For ProbMode)
    
    uint256[] public _TOKEN_ID_LIST_; //index => tokenId (Only For FixedAmount mode)

    bool public _IS_PROB_MODE_; // false = FixedAmount mode,  true = ProbMode
    bool public _IS_REVEAL_MODE_;
    uint256 public _REVEAL_RN_ = 0; 
    address public _RNG_;

    fallback() external payable {}

    receive() external payable {}

    // ============ Modifiers ============

    modifier notStart() {
        require(block.timestamp < _SELLING_TIME_INTERVAL_[0] || _SELLING_TIME_INTERVAL_[0]  == 0, "ALREADY_START");
        _;
    }

    // ============ Event =============
    event BuyTicket(address account, uint256 payAmount, uint256 feeAmount, uint256 ticketAmount);
    event RedeemPrize(address account, uint256 tokenId, address referer);

    event ChangeRNG(address rng);
    event ChangeRedeemTime(uint256 redeemTime);
    event ChangeTicketUnit(uint256 newTicketUnit);
    event Withdraw(address account, uint256 amount);
    event SetReveal();

    event SetSellingInfo();
    event SetProbInfo(); // only for ProbMode
    event SetTokenIdMapByIndex(uint256 index); // only for ProbMode
    event SetFixedAmountInfo(); // only for FixedAmount mode


    function init(
        address[] memory addrList, //0 owner, 1 buyToken, 2 feeModel, 3 defaultMaintainer 4 rng 5 nftToken
        uint256[] memory sellingTimeInterval,
        uint256[] memory sellingPrice,
        uint256[] memory sellingAmount,
        uint256 redeemAllowedTime,
        bool isRevealMode,
        bool isProbMode
    ) public {
        _BUY_TOKEN_ = addrList[1];
        _FEE_MODEL_ = addrList[2];
        _MAINTAINER_ = payable(addrList[3]);
        _RNG_ = addrList[4];
        _NFT_TOKEN_ = addrList[5];

        _IS_REVEAL_MODE_ = isRevealMode;
        _IS_PROB_MODE_ = isProbMode;
        _REDEEM_ALLOWED_TIME_ = redeemAllowedTime;

        if(sellingTimeInterval.length > 0) _setSellingInfo(sellingTimeInterval, sellingPrice, sellingAmount);
        
        string memory prefix = "DROPS_";
        name = string(abi.encodePacked(prefix, addressToShortString(address(this))));
        symbol = name;
        decimals = 0;

        //init Owner
        super.init(addrList[0], 0, name, symbol, decimals);
    }

    function buyTickets(address ticketTo, uint256 ticketAmount) payable external preventReentrant {
        (uint256 curPrice, uint256 sellAmount, uint256 index) = getSellingInfo();
        require(curPrice > 0 && sellAmount > 0, "CAN_NOT_BUY");
        require(ticketAmount <= sellAmount, "TICKETS_NOT_ENOUGH");
        (uint256 payAmount, uint256 feeAmount) = IDropsFeeModel(_FEE_MODEL_).getPayAmount(address(this), ticketTo, curPrice, ticketAmount);
        require(payAmount > 0, "UnQualified");

        uint256 baseBalance = IERC20(_BUY_TOKEN_).universalBalanceOf(address(this));
        uint256 buyInput = baseBalance.sub(_BUY_TOKEN_RESERVE_);

        require(payAmount <= buyInput, "PAY_AMOUNT_NOT_ENOUGH");

        _SELLING_AMOUNT_SET_[index] = sellAmount.sub(ticketAmount);
        _BUY_TOKEN_RESERVE_ = baseBalance.sub(feeAmount);

        IERC20(_BUY_TOKEN_).universalTransfer(_MAINTAINER_,feeAmount);
        _mint(ticketTo, ticketAmount);
        emit BuyTicket(ticketTo, payAmount, feeAmount, ticketAmount);
    }

    function redeemTicket(uint256 ticketNum, address referer) external {
        require(!address(msg.sender).isContract(), "ONLY_ALLOW_EOA");
        require(ticketNum >= 1 && ticketNum <= balanceOf(msg.sender), "TICKET_NUM_INVALID");
        _burn(msg.sender,ticketNum);
        for (uint256 i = 0; i < ticketNum; i++) {
            _redeemSinglePrize(msg.sender, i, referer);
        }
    }

    // ============ Internal  ============

    function _redeemSinglePrize(address to, uint256 curNo, address referer) internal {
        require(block.timestamp >= _REDEEM_ALLOWED_TIME_ && _REDEEM_ALLOWED_TIME_ != 0, "REDEEM_CLOSE");
        uint256 range;
        if(_IS_PROB_MODE_) {
            range = _PROB_INTERVAL_[_PROB_INTERVAL_.length - 1];
        }else {
            range = _TOKEN_ID_LIST_.length;
        }
        uint256 random;
        if(_IS_REVEAL_MODE_) {
            require(_REVEAL_RN_ != 0, "REVEAL_NOT_SET");
            random = uint256(keccak256(abi.encodePacked(_REVEAL_RN_, msg.sender, balanceOf(msg.sender).add(curNo + 1)))) % range;
        }else {
            random = IRandomGenerator(_RNG_).random(gasleft() + block.number) % range; 
        }
        uint256 tokenId;
        if(_IS_PROB_MODE_) {
            uint256 i;
            for (i = 0; i < _PROB_INTERVAL_.length; i++) {
                if (random <= _PROB_INTERVAL_[i]) {
                    break;
                }
            }
            require(_TOKEN_ID_MAP_[i].length > 0, "EMPTY_TOKEN_ID_MAP");
            tokenId = _TOKEN_ID_MAP_[i][random % _TOKEN_ID_MAP_[i].length];
            IDropsNft(_NFT_TOKEN_).mint(to, tokenId, 1, "");
        } else {
            tokenId = _TOKEN_ID_LIST_[random];
            if(random != range - 1) {
                _TOKEN_ID_LIST_[random] = _TOKEN_ID_LIST_[range - 1];
            }
            _TOKEN_ID_LIST_.pop();
            IDropsNft(_NFT_TOKEN_).mint(to, tokenId);  
        }
        emit RedeemPrize(to, tokenId, referer);
    }


    function _setSellingInfo(uint256[] memory sellingTimeIntervals, uint256[] memory sellingPrice, uint256[] memory sellingAmount) internal {
        require(sellingTimeIntervals.length > 0, "PARAM_NOT_INVALID");
        require(sellingTimeIntervals.length == sellingPrice.length && sellingPrice.length == sellingAmount.length, "PARAM_NOT_INVALID");
        for (uint256 i = 0; i < sellingTimeIntervals.length - 1; i++) {
            require(sellingTimeIntervals[i] < sellingTimeIntervals[i + 1], "INTERVAL_INVALID");
            require(sellingPrice[i] != 0, "PRICE_INVALID");
        }
        _SELLING_TIME_INTERVAL_ = sellingTimeIntervals;
        _SELLING_PRICE_SET_ = sellingPrice;
        _SELLING_AMOUNT_SET_ = sellingAmount;
        emit SetSellingInfo();
    }


    function _setProbInfo(uint256[] memory probIntervals,uint256[][] memory tokenIdMap) internal {
        require(_IS_PROB_MODE_, "ONLY_ALLOW_PROB_MODE");
        require(probIntervals.length > 0, "PARAM_NOT_INVALID");
        require(tokenIdMap.length == probIntervals.length, "PARAM_NOT_INVALID");

        require(tokenIdMap[0].length > 0, "INVALID");
        for (uint256 i = 1; i < probIntervals.length; i++) {
            require(probIntervals[i] > probIntervals[i - 1], "INTERVAL_INVALID");
            require(tokenIdMap[i].length > 0, "INVALID");
        }
        _PROB_INTERVAL_ = probIntervals;
        _TOKEN_ID_MAP_ = tokenIdMap;
        emit SetProbInfo();
    }

    function _setFixedAmountInfo(uint256[] memory tokenIdList) internal {
        require(!_IS_PROB_MODE_, "ONLY_ALLOW_FIXED_AMOUNT_MODE");
        require(tokenIdList.length > 0, "PARAM_NOT_INVALID");
        _TOKEN_ID_LIST_ = tokenIdList;
        emit SetFixedAmountInfo();
    }

    // ================= Owner ===================

    function withdraw() external onlyOwner {
        uint256 amount = IERC20(_BUY_TOKEN_).universalBalanceOf(address(this));
        IERC20(_BUY_TOKEN_).universalTransfer(msg.sender ,amount);
        emit Withdraw(msg.sender, amount);
    }

    function setRevealRn() external onlyOwner {
        require(_REVEAL_RN_ == 0, "ALREADY_SET");
        _REVEAL_RN_ = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))));
        emit SetReveal();
    }
    
    function setSellingInfo(uint256[] memory sellingTimeIntervals, uint256[] memory prices, uint256[] memory amounts) external notStart() onlyOwner {
        _setSellingInfo(sellingTimeIntervals, prices, amounts);
    }

    function setProbInfo(uint256[] memory probIntervals,uint256[][] memory tokenIdMaps) external notStart() onlyOwner {
        _setProbInfo(probIntervals, tokenIdMaps);
    }

    function setFixedAmountInfo(uint256[] memory tokenIdList) external notStart() onlyOwner {
        _setFixedAmountInfo(tokenIdList);
    }

    function addFixedAmountInfo(uint256[] memory addTokenIdList) external notStart() onlyOwner {
        for (uint256 i = 0; i < addTokenIdList.length; i++) {
            _TOKEN_ID_LIST_.push(addTokenIdList[i]);
        }
        emit SetFixedAmountInfo();
    }

    function setTokenIdMapByIndex(uint256 index, uint256[] memory tokenIds) external notStart() onlyOwner {
        require(_IS_PROB_MODE_, "ONLY_ALLOW_PROB_MODE");
        require(tokenIds.length > 0 && index < _TOKEN_ID_MAP_.length,"PARAM_NOT_INVALID");
        _TOKEN_ID_MAP_[index] = tokenIds;
        emit SetTokenIdMapByIndex(index);
    }
    
    function updateRNG(address newRNG) external onlyOwner {
        require(newRNG != address(0));
        _RNG_ = newRNG;
        emit ChangeRNG(newRNG);
    }

    function updateTicketUnit(uint256 newTicketUnit) external onlyOwner {
        require(newTicketUnit != 0);
        _TICKET_UNIT_ = newTicketUnit;
        emit ChangeTicketUnit(newTicketUnit);
    }

    function updateRedeemTime(uint256 newRedeemTime) external onlyOwner {
        require(newRedeemTime > block.timestamp || newRedeemTime == 0, "PARAM_NOT_INVALID");
        _REDEEM_ALLOWED_TIME_ = newRedeemTime;
        emit ChangeRedeemTime(newRedeemTime);
    }

    // ================= View ===================

    function getSellingStage() public view returns (uint256 stageLen) {
        stageLen = _SELLING_TIME_INTERVAL_.length;
    }

    function getSellingInfo() public view returns (uint256 curPrice, uint256 sellAmount, uint256 index) {
        uint256 curBlockTime = block.timestamp;
        if(curBlockTime >= _SELLING_TIME_INTERVAL_[0] && _SELLING_TIME_INTERVAL_[0] != 0) {
            uint256 i;
            for (i = 1; i < _SELLING_TIME_INTERVAL_.length; i++) {
                if (curBlockTime <= _SELLING_TIME_INTERVAL_[i]) {
                    break;
                }
            }
            curPrice = _SELLING_PRICE_SET_[i-1];
            sellAmount = _SELLING_AMOUNT_SET_[i-1];
            index = i - 1;
        }
    }

    function addressToShortString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(8);
        for (uint256 i = 0; i < 4; i++) {
            str[i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}