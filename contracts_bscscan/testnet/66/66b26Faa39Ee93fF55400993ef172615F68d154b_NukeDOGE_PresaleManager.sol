/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    constructor() internal {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

interface IERC20 {

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


abstract contract PresalableToken is Ownable, IERC20 {
    
    address private _presaleManager;
    bool public _presaleStarted = false;
    bool public _presaleOver = false;
    bool private _presaleManagerTokensSent = false;

    event PresaleStarted(uint256 timestamp);
    event PresaleEnded(uint256 timestamp);

    /**
     * @dev Returns the address of the current presaleManager.
     */
    function presaleManager() external view returns (address) {
        return _presaleManager;
    }

    function setPresaleManager(address presaleManagerAddress) external virtual onlyOwner {
        _presaleManager = presaleManagerAddress;
    }

    /**
     * @dev Throws if called by any account/contract other than the chosen presale manager.
     */
    modifier onlyPresaleManager() {
        require(_presaleManager == _msgSender(), "PresalableToken: caller is not the presale manager");
        _;
    }
    
    function startPresale() external virtual onlyPresaleManager {
        _presaleStarted = true;
        emit PresaleStarted(block.timestamp);
    }
    
    function endPresale() external virtual onlyPresaleManager {
        require(_presaleStarted, "PresalableToken: the presale has not even started");
        _presaleOver = true;
        emit PresaleEnded(block.timestamp);
    }
    
    /**
     * @dev Throws if the presale is not complete.
     */
    modifier presaleIsComplete() {
        require(_presaleStarted, "PresalableToken: the presale has not started");
        require(_presaleOver, "PresalableToken: the presale is not over");
        _;
    }
    
    /**
     * @dev Throws if the presale is not started.
     */
    modifier presaleIsStarted() {
        require(_presaleStarted, "PresalableToken: the presale has not started");
        _;
    }
    
    function isPresaleStarted() view external returns (bool) {
        return _presaleStarted;
    }
    
    function isPresaleComplete() view external returns (bool) {
        return _presaleStarted && _presaleOver;
    }
    
    function sendTokensToPresaleBuyer(address recipient, uint256 amount) external onlyPresaleManager presaleIsComplete {
        _sendTokensToPresaleBuyer(recipient, amount);
    }
    function _sendTokensToPresaleBuyer(address recipient, uint256 amount) virtual internal;
    
    function retrieveRequiredPresaleTokens(uint256 tAmount) external onlyPresaleManager {
        require(_presaleStarted && !_presaleOver, "PresalableToken: presale must be active");
        require(!_presaleManagerTokensSent, "PresalableToken: presale manager already claimed its tokens");
        
        _presaleManagerTokensSent = true;
        _retrieveRequiredPresaleTokens(tAmount);
    }
    function _retrieveRequiredPresaleTokens(uint256 tAmount) virtual internal;
}

abstract contract PresaleManager is Context, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) private _whitelistings;
    mapping (address => uint256) private _tokensPurchased;
    
    uint256 public _presaleRate = 50000;
    uint256 public _maxBuyInTenths = 20;
    uint256 public _minBuyInTenths = 1;
    
    uint256 public _hardCap = 100;
    uint256 private _ethPresold = 0;
    
    function _presalableToken() virtual internal returns (PresalableToken);
    function _tokenDecimalMultiplier() virtual internal returns (uint256);

    function setPresaleRate(uint256 tokensPerEth) external onlyOwner {
        require(!_presalableToken().isPresaleStarted(), "PresaleManager: cannot modify the rate once the presale has begun.");
        _presaleRate = tokensPerEth;
    }
    
    function setHardCap(uint ethHardCap) external onlyOwner {
        require(!_presalableToken().isPresaleStarted(), "PresaleManager: cannot modify the hard cap once the presale has begun.");
        _hardCap = ethHardCap;
    }
    
    function setMaxBuyInTenths(uint256 maxBuyInTenths) external onlyOwner {
        _maxBuyInTenths = maxBuyInTenths;
    }
    
    function setMinBuyInTenths(uint256 minBuyInTenths) external onlyOwner {
        _minBuyInTenths = minBuyInTenths;
    }


    // Presale Logic
    //
    receive() external payable {
        uint256 eth = msg.value;
        address sender = _msgSender();
        _presellTokens(sender, eth);
    }
    
    function _presellTokens(address buyer, uint256 eth) internal {
        if (_whitelistings[buyer]) {
            _validatePurchaseAmount(buyer, eth);
            _tokensPurchased[buyer] = _tokensPurchased[buyer].add(eth);
            _ethPresold = _ethPresold.add(eth);
            require(_hardCap * 1 ether > _ethPresold, "Presale Manager: purchase exceeds the hardcap.");
        }
    }
    
    function _validatePurchaseAmount(address buyer, uint256 eth) view internal {
        uint256 amountPurchasedByUser = _tokensPurchased[buyer].add(eth);
        
        uint256 lowerLimit = _minBuyInTenths.mul(1 ether).div(10);
        require(amountPurchasedByUser >= lowerLimit, "Presale Manager: Purchase does not meet minimum amount for presale.");
        
        uint256 upperLimit = _maxBuyInTenths.mul(1 ether).div(10);
        require(amountPurchasedByUser <= upperLimit, "Presale Manager: Purchase exceeds max tokens for presale.");
    }
    
    /**
     * @dev Call this to claim your tokens once the presale has concluded.
     */
    function claimTokens() external {
        address sender = _msgSender();
        require(_whitelistings[sender], "PresaleManager: you are not on the whitelist");

        uint256 ethSent = _tokensPurchased[sender];
        require(ethSent > 0, "PresaleManager: you did not buy any tokens during the presale");
        
        uint256 tokenAmount = ethSent.mul(_presaleRate).div(1 ether).mul(_tokenDecimalMultiplier());
        _presalableToken().sendTokensToPresaleBuyer(sender, tokenAmount);
    }
    
    /**
     * @dev Owner calls this to retrieve the funds raised from the presale.
     * The call will automatically fail until the presale is finalized and users can claim their tokens.
     */
    function claimEth() external onlyOwner {
        require(_presalableToken().isPresaleComplete(), "PresaleManager: owner cannot claim eth until presale is finalized");
        address payable receiver = payable(owner());
        
        uint256 eth = address(this).balance;
        receiver.transfer(eth);
    }
    
    // Presale State
    //
    function startPresale() external onlyOwner {
        _presalableToken().startPresale();
        
        uint256 requiredTokens = _presaleRate.mul(_hardCap).mul(_tokenDecimalMultiplier());
        _presalableToken().retrieveRequiredPresaleTokens(requiredTokens);
        
        require(_presalableToken().balanceOf(address(this)) >= requiredTokens, "PresaleManager: The presalable token failed to send the required number of tokens to fulfill the hard cap");
    }
    
    function endPresale() external onlyOwner {
        _presalableToken().endPresale();
    }
    
    // White Listing
    //
    function whiteListAddress(address wallet) external onlyOwner {
        _whitelistings[wallet] = true;
    }
    
    function whiteListAddresses(address wallet1, address wallet2, address wallet3, address wallet4, address wallet5) external onlyOwner {
        _whitelistings[wallet1] = true;
        _whitelistings[wallet2] = true;
        _whitelistings[wallet3] = true;
        _whitelistings[wallet4] = true;
        _whitelistings[wallet5] = true;
    }
    
    function whiteListAddresses(address wallet1, address wallet2, address wallet3, address wallet4, address wallet5, address wallet6, address wallet7, address wallet8, address wallet9, address wallet10) external onlyOwner {
        _whitelistings[wallet1] = true;
        _whitelistings[wallet2] = true;
        _whitelistings[wallet3] = true;
        _whitelistings[wallet4] = true;
        _whitelistings[wallet5] = true;
        _whitelistings[wallet6] = true;
        _whitelistings[wallet7] = true;
        _whitelistings[wallet8] = true;
        _whitelistings[wallet9] = true;
        _whitelistings[wallet10] = true;
    }
}

contract NukeDOGE_PresaleManager is PresaleManager {
    PresalableToken public _nukeDOGE;
    uint256 private _nukeDOGEDecimalMult = 10**9;
    
    constructor() public {
        _nukeDOGE = PresalableToken(0xB4F38E10A2764AA679eAB42417d2C6a7dF815397);
    }
    
    function _presalableToken() override internal returns (PresalableToken) {
        return _nukeDOGE;
    } 
    
    function _tokenDecimalMultiplier() override internal returns (uint256) {
        return _nukeDOGEDecimalMult;
    }
}