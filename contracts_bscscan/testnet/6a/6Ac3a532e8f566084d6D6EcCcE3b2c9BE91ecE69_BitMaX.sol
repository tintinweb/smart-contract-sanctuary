pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
    constructor () {
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

contract BitMaX is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    // mapping (address => uint256) private _mining;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => uint256) private _lastRewardTime;
    mapping (address => bool) private _isExcluded;
    
    uint256 private _totalSupply = 21000000 * 10**18;
    uint8 private _decimals = 18;
    string private _symbol = "BMAX";
    string private _name = "BitMaX";
    address public deployer;
    
    uint256 public genisisBlock;
    uint256 public genisisBlockNumber;
    uint256 private _lastBlockTime;
    uint256 private _lastBlock;
    
    uint256 private _circulatingSupply = 1000000 * 10**18;
    uint256 private _mining = 0;
    uint256 private _blockReward = 200 * 10**18;
    // uint256 private _halvingInterval = 400;
    uint private _blockTime = 600; // time
    uint256 public maxTxAmount = 50000 * 10**18; // maximum 50000 btcn can be transferred in 1 transaction
    
    uint256 private _totalBlockRewards = 0; 
    uint256 private _totalBlocksMined = 1;
    bool private _enableMine = true;
    
    event blockMined (address _by, uint256 _time, uint256 _blockNumber);

    constructor() {
        genisisBlock = block.timestamp;
        genisisBlockNumber = block.number;
        _lastBlock = genisisBlockNumber;
        _lastBlockTime = genisisBlock;
        _lastRewardTime[_msgSender()] = _totalBlocksMined;
        _balances[_msgSender()] = _circulatingSupply;
        _mining = _circulatingSupply;
        
        emit Transfer(address(0), _msgSender(), _circulatingSupply);
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
    function decimals() public view returns (uint8) {
    return _decimals;
  }

    /**
   * @dev Returns the token symbol.
   */
    function symbol() public view returns (string memory) {
    return _symbol;
  }

    /**
  * @dev Returns the token name.
  */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
   * @dev See {BEP20-totalSupply}.
   */
    function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

    /**
   * @dev See {BEP20-balanceOf}.
   */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account])
            return _balances[account];
        return _balances[account]+_calcReward(account);
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
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        if (sender != owner())
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
        
        /* CONSIDER THIS WITH OTHER FIRS */
        if (_isExcluded[sender]) {
            if (!_isExcluded[recipient]) _mining = _mining + amount;
        }else {
            if (_isExcluded[recipient]) _mining = _mining - amount;
        }
        if (_balances[recipient] <= 0) _lastRewardTime[recipient] = _totalBlocksMined;
        
        // First check if sender claimed reward  already
        if (_lastRewardTime[sender] < _totalBlocksMined && !_isExcluded[sender]) {
            uint256 _reward = _calcReward(sender);
            _balances[sender] = _balances[sender]+_reward;
            _lastRewardTime[sender] = _totalBlocksMined;
        }
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (_lastRewardTime[recipient] < _totalBlocksMined && !_isExcluded[recipient]) {
            uint256 _reward = _calcReward(recipient);
            _balances[recipient] = _balances[recipient]+_reward;
            _lastRewardTime[recipient] = _totalBlocksMined;
        }
        mine(sender);
      
        emit Transfer(sender, recipient, amount);
    }
    
    function _calcReward (address account) private view returns (uint256) {
        if (_lastRewardTime[account] == _totalBlocksMined)
            return 0;
        uint256 _reward = 0;
        uint256 _prevBlockReward = 0;
        uint256 _lastReward = _lastRewardTime[account];
        
        if (_lastReward >= 1 && _lastReward < 17280) {
            _prevBlockReward = 200 * 10**18;
            if (_totalBlocksMined > 17280) {
                _reward = ((17280 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining);
                _lastReward = 17280;
            }else {
                _reward = ((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining);
                _lastReward = _totalBlocksMined;
            }
        }
        if (_lastReward >= 17280 && _lastReward < 103680) {
            _prevBlockReward = 100 * 10**18;
            if (_totalBlocksMined > 103680) {
                _reward = _reward + (((103680 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = 103680;
            }else {
                _reward = _reward +  (((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = _totalBlocksMined;
            }
        }
        if (_lastReward >= 103680 && _lastReward < 276480) {
            _prevBlockReward = 50 * 10**18;
            if (_totalBlocksMined > 276480) {
                _reward = _reward +  (((276480 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = 276480;
            }else {
                _reward = _reward +  (((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = _totalBlocksMined;
            }
        }
        if (_lastReward >= 276480 && _lastReward < 322559) {
            _prevBlockReward = 25 * 10**18;
            if (_totalBlocksMined >= 322559) {
                _reward = _reward +  (((322559 - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = 322559;
            }else {
                _reward = _reward +  (((_totalBlocksMined - _lastReward) * _prevBlockReward).mul(_balances[account]).div(_mining));
                _lastReward = _totalBlocksMined;
            }
        }
        
        return _reward;
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
    
    function mine(address account) private {
        if (!_enableMine) return; // Don't use require as it will fail transfers if mining is not enabled
        if (block.number < _lastBlock+_blockTime) return;
        _totalBlockRewards = _totalBlockRewards+_blockReward;
        _circulatingSupply = _circulatingSupply+_blockReward;
        _mining = _mining+_blockReward;
        _lastBlock = block.number;
        _lastBlockTime = block.timestamp;
        _totalBlocksMined++;
        
        emit blockMined (account, _lastBlockTime, _lastBlock);
        
        // if (_lastBlock < _halvingInterval+genisisBlockNumber) return;
        if (_totalBlocksMined == 17280) {
            _blockTime = 400;
            _blockReward = _blockReward.div(2); // block reward halves
        }else if (_totalBlocksMined == 103680) {
            _blockTime = 300;
            _blockReward = _blockReward.div(2); // block reward halves
        }else if (_totalBlocksMined == 276480) {
            _blockTime = 200;
            _blockReward = _blockReward.div(2); // block reward halves
        }
        
        if (_totalBlocksMined >= 322550-1) _enableMine = false; // end mining
    }
    
    function exlude (address account) external onlyOwner {
         _exclude(account);
    }
    function include (address account) external onlyOwner {
        _include(account);
    }
    
    function _exclude (address account) private {
        _isExcluded[account] = true;
        _mining = _mining - _balances[account];
    }
    function _include (address account) private {
        _isExcluded[account] = false;
        _mining = _mining+ _balances[account];
    }
    
    function isExcluded (address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function circulatingSupply() public view returns (uint256) {
        return _circulatingSupply;
    }
    function totalBlockRewards() public view returns (uint256) {
        return _totalBlockRewards;
    }
    function totalBlocksMined() public view returns (uint256) {
        return _totalBlocksMined;
    }
    function enableMine() public view returns (bool) {
        return _enableMine;
    }
    function lastBlockTime() public view returns (uint256) {
        return _lastBlockTime;
    }
    function lastBlock() public view returns (uint256) {
        return _lastBlock;
    }
    function blockReward() public view returns (uint256) {
        return _blockReward;
    }

    function miningReward() public view returns (uint256) {
        return _mining;
    }
    function blockTime() public view returns (uint) {
        return _blockTime;
    }
}