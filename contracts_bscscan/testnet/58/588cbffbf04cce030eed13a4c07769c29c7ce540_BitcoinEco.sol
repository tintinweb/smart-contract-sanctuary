/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-01
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

contract BitcoinEco is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    // For users
    struct Reward {
        uint256 total;
        uint256 lTxTime;
        bool blocked; // blocked from rewards
    }
    // Reward Settings
    struct Rewards {
        uint256 reward;
        uint256 interval;
    }
    
    // Constants
    uint256 private constant TOTAL_SUPPLY = 21000000 * 10**18;
    uint256 private DEPLOYMENT_TIME;
    address[2] private SWAP;
    uint8 private constant DECIMALS = 18;
    string private constant SYMBOL = "BTB";
    string private constant NAME = "Bit";
    
    // Controlled variables
    bool private mineTokens = true; // enable/disable mining
    bool private burnTokens = false; // enable/disable burning
    bool private taxEnabled = true;
    bool private tradingEnabled = false;
    uint256 private taxFees = 15; // 1.5% fee
    uint256 private burnFees = 10;
    uint256 private maxTxAmount = 3000 * 10**18;
    address private cw = address(0);
    address private dw = address(0);
    
    // Rewards Settings
    Rewards private daily;
    Rewards private weekly;
    Rewards private monthly;
    uint256[4] private mr;
    bool stopHalving = false;
    uint256 private cSupply = 1148000 * 10**18;
    
    // Mappings
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedAccounts; // exluded from fees
    mapping (address => Reward) private _userRewards;
    
    event HalvingInterval (uint256 oldReward, uint256 newReward, uint256 newInterval, uint256 rewardType);
    event MiningCompleted (uint256 circulatingSupply, uint256 time);
    event RewardTransferred (address account, uint256 amount);
    event Mining (uint256 time, uint256 Type, bool enabled);
    event Burn (uint256 time, uint256 Type, bool enabled, uint256 amountBurned);
    
    constructor() public {
        init();
        
        _balances[_msgSender()] = cSupply;
        _userRewards[_msgSender()].lTxTime = block.timestamp;
        _initHalving(365 days, 1460 days, 2555 days, 3650 days);
        
        emit Transfer(address(0), _msgSender(), cSupply);
    }
    
    function calReward (address account) private view returns (uint256) {
        uint256 result = 0;
        if (!_userRewards[account].blocked && mineTokens) {
            uint256 dReward = (block.timestamp-_userRewards[account].lTxTime)/daily.interval;
            uint256 wReward = (block.timestamp-_userRewards[account].lTxTime)/weekly.interval;
            uint256 mReward = (block.timestamp-_userRewards[account].lTxTime)/monthly.interval;
            
            // uint256 ub = _balances[account]+_userRewards[account].total;
            
            if (
                // daily.total >= 0 &&
                block.timestamp >= _userRewards[account].lTxTime + daily.interval
            ) {
                result = daily.reward.mul(_balances[account]).div(TOTAL_SUPPLY).mul(dReward)*21; // Daily
            }
            
            if (
                // weekly.total >= 0 &&
                block.timestamp >= _userRewards[account].lTxTime + weekly.interval
            ) {
                result += weekly.reward.mul(_balances[account]).div(TOTAL_SUPPLY).mul(wReward)*21; // Weekly
            }
            
            if (
                // monthly.total >= 0 &&
                block.timestamp >= _userRewards[account].lTxTime + monthly.interval
            ) {
                result += monthly.reward.mul(_balances[account]).div(TOTAL_SUPPLY).mul(mReward)*21; // Monthly
            }
        }
        
        return result;
    }
    
    function _transfer (address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(tradingEnabled, "Trading has not been enabled yet!");
        if(from != owner() && to != owner() && from != SWAP[0] && from != SWAP[1])
            require(amount <= maxTxAmount, "Transfer amount exceeds the max amount.");
        
        halving();
        
        if (balanceOf(to) == 0) _userRewards[to].lTxTime = block.timestamp;
        _userRewards[from].total = calReward (from);
        _userRewards[to].total = calReward (to);
        
        _userRewards[from].lTxTime = block.timestamp;
        _userRewards[to].lTxTime = block.timestamp;
        
        if (_excludedAccounts[from] || _excludedAccounts[to]) {
            _transferNoFee (from, to, amount, 0);
        }else {
            _transferFee (from, to, amount);
        }
    }
    
    function _transferNoFee (address from, address to, uint256 amount, uint256 tax) private {
        require (amount <= _balances[from]+_userRewards[from].total, "Amount greater then balance!");
        
        if (amount >= _userRewards[from].total) {
            uint256 ta = amount.sub(_userRewards[from].total, "Error");
            _userRewards[from].total = 0;
            _balances[from] = _balances[from].sub(ta, "BEP20: transfer amount exceeds balance");
            _balances[to] = _balances[to].add(amount-tax);
        }else {
            _userRewards[from].total = _userRewards[from].total.sub(amount, "Error");
            _balances[to] = _balances[to].add(amount-tax);
        }
        
    }
    
    function _transferFee (address from, address to, uint256 amount) private {
        uint256 tax = 0;
        uint256 bTax = 0;
        
        if (taxEnabled) {
            tax = amount.mul(taxFees).div(1000);
            _balances[cw] = _balances[cw].add(tax);
        }
            
        if (burnTokens) {
            bTax = amount.mul(burnFees).div(100);
            _balances[dw] = _balances[dw].add(bTax);
        }
        
        _transferNoFee (from, to, amount, tax+bTax);
    }
    
    function halving () private {
        if (stopHalving) return;
        uint256 ct = block.timestamp;
        if (
            ct >= mr[0] + DEPLOYMENT_TIME &&
            ct < mr[1] + DEPLOYMENT_TIME
        ) {
            daily.reward = 1800 * 10**18;
            weekly.reward = 15000 * 10**18;
            monthly.reward = 25000 * 10**18;
        }else if (
            ct >= mr[1] + DEPLOYMENT_TIME &&
            ct < mr[2] + DEPLOYMENT_TIME
        ) {
            daily.reward = 1600 * 10**18;
            weekly.reward = 10000 * 10**18;
            monthly.reward = 15000 * 10**18;
        }else if (
            ct >= mr[2] + DEPLOYMENT_TIME &&
            ct < mr[3] + DEPLOYMENT_TIME
        ) {
            daily.reward = 1400 * 10**18;
            weekly.reward = 5000 * 10**18;
            monthly.reward = 10000 * 10**18;
            stopHalving = true;
        }
    }
    
    function init () private {
        daily.reward = 2000 * 10**18;
        daily.interval = 12 hours;

        weekly.reward = 20000 * 10**18;
        weekly.interval = 7 days;

        monthly.reward = 30000 * 10**18;
        monthly.interval = 30 days;

        DEPLOYMENT_TIME = block.timestamp;
    }
    function initHalving (uint256 i1, uint256 i2, uint256 i3, uint256 i4) external onlyOwner {
        _initHalving(i1, i2, i3, i4);
    }
    function _initHalving (uint256 i1, uint256 i2, uint256 i3, uint256 i4) private {
        mr[0] = i1;
        mr[1] = i2;
        mr[2] = i3;
        mr[3] = i4;
    }
    function initReward (uint256 r1, uint256 r2, uint256 r3) external onlyOwner {
        daily.reward = r1 * 10**18;
        weekly.reward = r2 * 10**18;
        monthly.reward = r3 * 10**18;
    }
    function initInterval (uint256 r1, uint256 r2, uint256 r3) external onlyOwner {
        daily.interval = r1;
        weekly.interval = r2;
        monthly.interval = r3;
    }
    
    /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
    
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
   * @dev Returns the bep token owner.
   */
    function getOwner() public view returns (address) {
        return owner();
    }

    /**
   * @dev Returns the token decimals.
   */
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    /**
   * @dev Returns the token symbol.
   */
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    /**
  * @dev Returns the token name.
  */
    function name() public pure returns (string memory) {
        return NAME;
    }

    /**
   * @dev See {BEP20-totalSupply}.
   */
    function totalSupply() public view override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /**
   * @dev See {BEP20-balanceOf}.
   */
    function balanceOf(address account) public view override returns (uint256) {
        if (!_userRewards[account].blocked)
            return _balances[account]+calReward(account)+_userRewards[account].total;
        // check last transaction time and return the balance according to that
        return _balances[account];
    }

    /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
   * @dev See {BEP20-allowance}.
   */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    
    /**
    * Getters & Setters
    */
    function isMiningEnabled () public view returns (bool) {
        return mineTokens;
    }
    function isBurningEnabled () public view returns (bool) {
        return burnTokens;
    }
    function istaxEnabled () public view returns (bool) {
        return taxEnabled;
    }
    function getFees () public view returns (uint256) {
        return taxFees/10;
    }
    function getBurnFees () public view returns (uint256) {
        return burnFees;
    }
    function getCW () public view returns (address) {
        return cw;
    }
    function getDW () public view returns (address) {
        return dw;
    }
    function getSwap (uint256 i) public view returns (address) {
        return SWAP[i];
    }
    
    function setMiningEnabled (bool value) external onlyOwner {
        mineTokens = value;
    }
    function settaxEnabled (bool value) external onlyOwner {
        taxEnabled = value;
    }
    function setBurningEnabled (bool value) external onlyOwner {
        burnTokens = value;
    }
    function setFees (uint256 value) external onlyOwner {
        taxFees = value;
    }
    function setBurnFees (uint256 value) external onlyOwner {
        burnFees = value;
    }
    function setCW (address value) external onlyOwner {
        cw = value;
        _userRewards[cw].lTxTime = block.timestamp;
    }
    function setDW (address value) external onlyOwner {
        dw = value;
    }
    function setSwap (address addr, uint256 i) external onlyOwner {
        SWAP[i] = addr;
    }
    function enableTrading (bool value) external onlyOwner {
        tradingEnabled = value;
    }
    
    function getStopHalving () public view returns (bool) {
        return stopHalving;
    }
    function setStopHalving (bool value) external onlyOwner {
        stopHalving = value;
    }
    
    // function isExcludedFromFees (address account) public view returns (bool) {
    //     return _excludedAccounts[account];
    // }
    function excludedFromFees (address account) external onlyOwner {
        _excludedAccounts[account] = true;
    }
    function includedFromFees (address account) external onlyOwner {
        _excludedAccounts[account] = false;
    }
    
    function blockFromRewards (address account) external onlyOwner {
        _userRewards[account].blocked = true;
    }
    function includeInRewards (address account) external onlyOwner {
        _userRewards[account].blocked = false;
    }
    function isBlockedFromRewards (address account) public view returns(bool) {
        return _userRewards[account].blocked;
    }
    
    // For Structs
    function getUserDetails (address account) external onlyOwner view returns (uint256, uint256, bool) {
        return (_userRewards[account].total, _userRewards[account].lTxTime, _userRewards[account].blocked);
    }
    function getDRewards (address account) external onlyOwner view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 dReward = _userRewards[account].lTxTime/daily.interval;
        uint256 wReward = _userRewards[account].lTxTime/weekly.interval;
        uint256 mReward = _userRewards[account].lTxTime/monthly.interval;
        
        return (dReward, wReward, mReward, block.timestamp, _userRewards[account].lTxTime, 2 minutes);
    }
    function getBalance (address account) external onlyOwner view returns (uint256) {
        return balanceOf(address(account));
    }
}