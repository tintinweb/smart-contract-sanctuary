/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// ***** DOTASERIES of FOMODOTA ******//

/*
- FomoDOTA was founded in 2021 in the purpose of building FOMO MOBA Ecosystem 
    for all e-sports gamers to achieve more influence of gaming on blockchain.
- Website: https://fomodota.org
- Telegram: https://t.me/Fomodota_BSC_EN
- 中文电报：https://t.me/FomoDOTA_BSC_CN
- Twitter: https://twitter.com/FomoDOTA_BSC
- Documents: https://fomodota.gitbook.io/fomodota/
- NFT Whitepaper: https://developerhhh.gitbook.io/dota-series-nft/
*/


// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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


// File @openzeppelin/contracts/math/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;



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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
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


interface NFT {
    function getTokenIdInfo(uint256 _tokenId) external view returns(
        uint16 _name,
        uint16 _gameId,
        bool _canRaiseBirth,
        uint256 _star,
        uint256 _genes,
        uint256 _strength,
        uint256 _intelligence,
        uint256 _agility,
        uint256 _maxStar,
        uint256 _originalCombat,
        uint256 _currentCombat
        );
    
    function createHeroNFT(address account,uint16 itemName,uint16 gameId,bytes memory data, bool flag) external returns(uint256);
    function createEquipmentNFT(address account,uint16 itemName,uint16 gameId,bytes memory data) external returns(uint256);
    function levelUpItem(address account, uint256 _tokenId1, uint256 _tokenId2, uint256 probability) external returns(bool,int256);
    function upgradeStar(address account, uint256 _tokenId1, uint256 _tokenId2, uint16 choice) external returns(bool);
    function giveBirth(address account, uint256 _tokenId, bytes memory data) external returns(uint256);
    
    function getStakeStatus(uint256 id) external returns(bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function getRarity(uint256 _tokenId) external view returns(uint256);
    function burn(address _address, uint256 _tokenId, uint256 amount) external;
    function getStar(uint256 id) external view returns (uint256);
}

interface MiningPower{
    function getMiningPower(uint256 _tokenId) external view returns (uint256);
    function setBasePower(uint256 _tokenId) external;
    function addPowerByUpgradingStars(uint256 _tokenId1, uint256 _tokenId2) external;
}

contract NFTInteractions is Ownable{
    using SafeMath for uint256;
    using Address for address;
    
    NFT nft;
    MiningPower miningPower;
    IERC20 private platformToken = IERC20(0x2D81ed6edee72d454a5baF51e40704e8c377DB2A);
    IERC20 private gameToken = IERC20(0xA5B4914d2fCf8551B962846AC0815CE6319bd846);
    uint256 public summonHeroAmount;
    uint256 public summonEquipmentAmount;
    uint256 public giveBirthAmount;
    uint256 public rebuildAmount;
    uint256 public upgradeStarAmount;
    uint256 public advancedSummonAmount;
    uint256 public summonBatchFee;
    uint256 public advanceSummonBatchFee;
    uint256 public taxFee;
    uint256 public heroNumber = 64;
    uint256 public probability = 5;
    uint256 private dnaModulus = 10 ** 64;
    mapping(address => uint256) public airdropAddress;

    constructor(address nft_, address miningPower_) public {
      nft = NFT(nft_);
      miningPower = MiningPower(miningPower_);
    }
    
    event SummonCard(address creater, string ways, uint256 tokenId);
    event SummonBatch(address creater, uint256 tokenId1, uint256 tokenId2, uint256 tokenId3);
    event RefactorSuccess(address creater, string ways, bool isSuccess); 
    event FailReason(uint256 failCode, uint256 factor);
    
    function setProbability(uint256 _probability) onlyOwner external{
        probability = _probability;
    }
    
    function setPlatformToken(IERC20 _token) external onlyOwner {
        platformToken = _token;
    }
    function setGameToken(IERC20 _token) external onlyOwner {
        gameToken = _token;
    }
    function setAmount(uint256 _summonHeroAmount, uint256 _summonEquipmentAmount, 
        uint256 _giveBirthAmount, uint256 _rebuildAmount, 
        uint256 _upgradeStarAmount, uint256 _advancedSummonAmount,
        uint256 _taxFee, uint256 _summonBatchFee, uint256 _advanceSummonBatchFee) onlyOwner external{
        summonHeroAmount = _summonHeroAmount;
        summonEquipmentAmount = _summonEquipmentAmount;
        giveBirthAmount = _giveBirthAmount;
        rebuildAmount = _rebuildAmount;
        upgradeStarAmount = _upgradeStarAmount;
        advancedSummonAmount = _advancedSummonAmount;
        taxFee = _taxFee;
        summonBatchFee = _summonBatchFee;
        advanceSummonBatchFee = _advanceSummonBatchFee;
    }
    function setNumber(uint256 _heroNumber) onlyOwner external{
        heroNumber = _heroNumber;
    }
    function getSummonHeroAmount() public view returns(uint256) {
        return summonHeroAmount;
    }
    function getAdvancedSummonAmount() public view returns(uint256) {
        return advancedSummonAmount;
    }
    function getSummonEquipmentAmount() public view returns(uint256) {
        return summonEquipmentAmount;
    }
    function getGiveBirthAmount() public view returns(uint256) {
        return giveBirthAmount;
    }
    function getRebuildAmount() public view returns(uint256) {
        return rebuildAmount;
    }
    function getUpgradeStarAmount() public view returns(uint256) {
        return upgradeStarAmount;
    }
    
    function _generateRandomData(uint256 _itemType) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_itemType,block.timestamp,block.number)));
        return rand % dnaModulus;
    }
    
    function getRandomHeroNumber(uint256 number) internal view returns(uint16) {
        return uint16(_generateRandomData(number) % heroNumber);
    }
    
    function getPlatformToken() public view returns(IERC20) {
        return platformToken;
    }
    function getGameToken() public view returns(IERC20) {
        return gameToken;
    }
    
    function setNft(address nft_) onlyOwner external{
        nft = NFT(nft_);
    }
    
    function setMiningPower(address miningPower_) onlyOwner external {
        miningPower = MiningPower(miningPower_);
    }
    
    function addBatchAirdropAmount(address[] memory list, uint256 amount) external onlyOwner {
        uint256 i = 0;
        while (i < list.length) {
            airdropAddress[list[i]] = getAirdropAmount(list[i]).add(amount);
            i++;
        }
    }
    
    function getAirdropAmount(address account) public view returns(uint256){
        return airdropAddress[account];
    }
    
    function addAirdropAmount(address account, uint256 amount) external onlyOwner {
        airdropAddress[account] = getAirdropAmount(account).add(amount);
    }
    
    function airdropSummon(uint16 _gameid, bytes memory _data) external {
        require(airdropAddress[msg.sender] > 0, "you are out of airdrop");
        uint256 tokenId = nft.createHeroNFT(msg.sender,getRandomHeroNumber(1),_gameid,_data, false);
        miningPower.setBasePower(tokenId);
        airdropAddress[msg.sender] = getAirdropAmount(msg.sender).sub(1);
        emit SummonCard(msg.sender, "airdropSummon", tokenId);
    }
    
    function summonHero(uint16 _gameid, bytes memory _data) external{
        require(platformToken.transferFrom(msg.sender, address(this), summonHeroAmount),
        "you need pay fee to summon a hero");
        uint256 tokenId = nft.createHeroNFT(msg.sender,getRandomHeroNumber(1),_gameid,_data, true);
        miningPower.setBasePower(tokenId);
        emit SummonCard(msg.sender, "summonHero", tokenId);
    }
    
    function summonBatch(uint16 _gameid, bytes memory _data, bool isAdvance) external {
        uint256 fee = summonBatchFee;
        if (isAdvance) {
            fee = advanceSummonBatchFee;
        }
        require(platformToken.transferFrom(msg.sender, address(this), fee),
        "you need pay fee to summon a hero");
        uint256 tokenId1 = nft.createHeroNFT(msg.sender,getRandomHeroNumber(1),_gameid,_data, isAdvance);
        uint256 tokenId2 = nft.createHeroNFT(msg.sender,getRandomHeroNumber(2),_gameid,_data, isAdvance);
        uint256 tokenId3 = nft.createHeroNFT(msg.sender,getRandomHeroNumber(3),_gameid,_data, isAdvance);
        miningPower.setBasePower(tokenId1);
        miningPower.setBasePower(tokenId2);
        miningPower.setBasePower(tokenId3);
        emit SummonBatch(msg.sender, tokenId1, tokenId2, tokenId3);
    }
    
    function advancedSummonHero(uint16 _gameid, bytes memory _data) external{
        require(platformToken.transferFrom(msg.sender, address(this), advancedSummonAmount),
        "you need pay fee to summon a hero");
        uint256 tokenId = nft.createHeroNFT(msg.sender,getRandomHeroNumber(1),_gameid,_data, false);
        miningPower.setBasePower(tokenId);
        emit SummonCard(msg.sender, "advancedSummonHero", tokenId);
    }
    
    function summonByDestroy(uint256 _tokenId1, uint256 _tokenId2, 
        uint16 _gameid, bytes memory _data) external {
        require(nft.balanceOf(_msgSender(),_tokenId1) == 1 && 
            nft.balanceOf(msg.sender,_tokenId2) == 1,"You must have these item");
        require(_tokenId1 != _tokenId2);
        require(platformToken.transferFrom(msg.sender, owner(), taxFee), "not pay the tax fee");
        
        nft.burn(msg.sender,_tokenId1,1);
        nft.burn(msg.sender,_tokenId2,1);
        uint256 tokenId = nft.createHeroNFT(msg.sender,getRandomHeroNumber(1),_gameid,_data, false);
        miningPower.setBasePower(tokenId);
        emit SummonCard(msg.sender, "summonByDestroy", tokenId);
    }
    
    function isSuccessfulAction(uint256 tokenId, uint256 factor) internal view returns(bool) {
        uint256 left = _generateRandomData(tokenId) % factor;
        if (factor - left > 1) {
            return true;
        }
        return false;
    }
    
    function rebuild(uint256 _tokenId1, uint256 _tokenId2) external{
        require(gameToken.transferFrom(msg.sender, address(this), rebuildAmount),
        "you need pay fee to rebuild a hero");
        require(_tokenId1 != _tokenId2);
        (,,,,,,,,,uint256 oldCombat,) = nft.getTokenIdInfo(_tokenId1);
        
        bool flag = isSuccessfulAction(_tokenId1, probability);
        if (flag == true) {
            emit FailReason(0, probability);
            nft.burn(msg.sender, _tokenId2, 1);
            emit RefactorSuccess(msg.sender, "rebuild", false);
            return;
        }

        (bool success, int256 id) = nft.levelUpItem(msg.sender, _tokenId1, _tokenId2, probability);
        
        if (success) {
            (,,,,,,,,,uint256 newCombat,) = nft.getTokenIdInfo(uint256(id));
            if (newCombat <= oldCombat) {
                emit FailReason(1, probability);
                success = false;
            }
            miningPower.setBasePower(uint256(id));
            emit SummonCard(msg.sender, "rebuild", uint256(id));
        }
        emit RefactorSuccess(msg.sender, "rebuild", success);
    }
    
    function upgrade(uint256 _tokenId1, uint256 _tokenId2, uint16 choice) external {
        require(gameToken.transferFrom(msg.sender, address(this), upgradeStarAmount),
        "you need pay fee to upgrade a hero");
        require(_tokenId1 != _tokenId2);
        bool success = nft.upgradeStar(msg.sender,_tokenId1,_tokenId2,choice);
        if (success) {
            miningPower.addPowerByUpgradingStars(_tokenId1, _tokenId2);
        }
        emit RefactorSuccess(msg.sender, "upgrade", success); 
    }  
    
    function birth(uint256 _tokenId, bytes memory data) external {
        require(gameToken.transferFrom(msg.sender, address(this), giveBirthAmount),
        "you need pay fee to birth a hero card");
        uint256 tokenId = nft.giveBirth(msg.sender,_tokenId,data);
        miningPower.setBasePower(tokenId);
        emit SummonCard(msg.sender, "birth", tokenId);
    }
    
    function emergencyTransferSourceToken(IERC20 tokenAddress, address to) onlyOwner external {
        uint256 amount = tokenAddress.balanceOf(address(this));
        SafeERC20.safeTransfer(tokenAddress, to, amount);
    }

    function emergencyTransferETH(address to) onlyOwner external {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            payable(to).transfer(amount);
        }
    }
}