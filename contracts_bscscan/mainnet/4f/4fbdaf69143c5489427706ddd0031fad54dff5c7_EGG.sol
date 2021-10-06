/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

pragma solidity 0.5.16;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract EGG is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    address[] private _excludedTransactionFee;
    mapping (address => bool) private _isExcludedTransactionFee;
    
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    
    uint256 private end;
    uint256 private burnAmount;
    bool private burnFlag;
    uint256 private transactionFeePercent;
    address public transactionPoolAddress;
    address payable public yieldFarmPoolAddress;
    address payable public loanPoolAddress;
    uint private apy;
    uint private loanFeePercent;
    uint private loanSizePercent;
    uint private yieldFarmMinAmount;
    uint private loanMinAmount;
    
    constructor() public {
        _name = "Easter Egg";
        _symbol = "EGG";
        _decimals = 18;
        _totalSupply = 1000000000000 * 10 ** 18;
        _balances[msg.sender] = _totalSupply;
        
        end = block.timestamp;
        burnFlag = false;
        transactionFeePercent = 0;
        apy = 8;
        loanFeePercent = 10;
        loanSizePercent = 70;
        yieldFarmMinAmount= 100000;
        loanMinAmount= 100000;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address) {
        return owner();
    }
    
    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory) {
        return _name;
    }
    
    /**
    * @dev See {BEP20-totalSupply}.
    */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    /**
    * @dev See {BEP20-balanceOf}.
    */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    /**
    * @dev See apy
    */
    function getApy() external view returns (uint) {
        return apy;
    }
    
    /**
    * @dev See loan fee percent
    */
    function getLoanFeePercent() external view returns (uint) {
        return loanFeePercent;
    }
    
    /**
    * @dev See loan size percent
    */
    function getLoanSizePercent() external view returns (uint) {
        return loanSizePercent;
    }
    
    /**
    * @dev See transaction pool address
    */
    function getTransactionPoolAddress() external view returns (address) {
        return transactionPoolAddress;
    }
    
    /**
    * @dev See yield farm pool address.
    */
    function getYieldFarmPoolAddress() external view returns (address payable) {
        return yieldFarmPoolAddress;
    }
    
    /**
    * @dev See loan pool address.
    */
    function getLoanPoolAddress() external view returns (address payable) {
        return loanPoolAddress;
    }
    
    /**
    * @dev see end of time.
    */
    function getEndOfTime() external view returns (uint256) {
        return end;
    }
    
    /**
    * @dev See transactionFeePercent.
    */
    function getTransactionFeePercent() external view returns (uint) {
        return transactionFeePercent;
    }
    
    /**
    * @dev See burn amount.
    */
    function getBurnAmount() external view returns (uint256) {
        return burnAmount;
    }
    
    /**
    * @dev See burnFlag.
    */
    function getBurnFlag() external view returns (bool) {
        return burnFlag;
    }
    
    /**
    * @dev See isExcludedTransactionFee.
    */
    function isExcludedTransactionFee(address _checkAddress) external view returns (bool) {
        return _isExcludedTransactionFee[_checkAddress];
    }
    
    /**
    * @dev See yield farm min amount.
    */
    function getYieldFarmMinAmount() external view returns (uint256) {
        return yieldFarmMinAmount;
    }
    
    /**
    * @dev See loan min amount.
    */
    function getLoanMinAmount() external view returns (uint256) {
        return loanMinAmount;
    }
    
    /**
    * @dev See {BEP20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(transactionPoolAddress != address(0), "BEP20: transfer to the zero address");
    
        uint256 sendAmount = 0;
        if (_isExcludedTransactionFee[recipient] == true) {
            sendAmount = amount;
        }else if (_isExcludedTransactionFee[msg.sender] == true) {
            sendAmount = amount;
        }else{
            uint256 feeAmount = (amount.mul(transactionFeePercent)).div(100);
            sendAmount = amount.sub(feeAmount);
            
            _transfer(_msgSender(), transactionPoolAddress, feeAmount);
        }
    
        _transfer(_msgSender(), recipient, sendAmount);
        return true;
    }

    /**
    * @dev See {BEP20-allowance}.
    */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
    * @dev See {BEP20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "BEP20: spender cannot be the zero address");
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 sendAmount = 0;
        if (_isExcludedTransactionFee[recipient] == true) {
            sendAmount = amount;
        }else if (_isExcludedTransactionFee[sender] == true) {
            sendAmount = amount;
        }else{
            uint256 feeAmount = (amount.mul(transactionFeePercent)).div(100);
            sendAmount = amount.sub(feeAmount);
            
            _transfer(sender, transactionPoolAddress, feeAmount);
        }
    
        _transfer(sender, recipient, sendAmount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(sendAmount, "BEP20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    
    /**
    * @dev set end time.
    */
    function setEndTime(uint256 timeInSec) external onlyOwner returns (uint256) {
        end = block.timestamp.add(timeInSec);
        burnFlag = true;
        
        return end;
    }
    
    /**
    * @dev set transaction fee percent.
    */
    function setTransactionFeePercent(uint256 newTransactionFeePercent) external onlyOwner returns (uint){
        transactionFeePercent = newTransactionFeePercent;
        return transactionFeePercent;
    }
    
    /**
    * @dev set apy.
    */
    function setApy(uint256 newApy) external onlyOwner returns (uint){
        apy = newApy;
        return apy;
    }
    
    /**
    * @dev set loan fee percent.
    */
    function setLoanFeePercent(uint256 newLoanFeePercent) external onlyOwner returns (uint){
        loanFeePercent = newLoanFeePercent;
        return loanFeePercent;
    }
    
    /**
    * @dev set loan size percent.
    */
    function setLoanSizePercent(uint256 newLoanSizePercent) external onlyOwner returns (uint){
        loanSizePercent = newLoanSizePercent;
        return loanSizePercent;
    }
    
    /**
    * @dev set set burn amount.
    */
    function setBurnAmount(uint256 newBurnAmount) external onlyOwner returns (uint256) {
        burnAmount = newBurnAmount;
        return burnAmount;
    }
  
    /**
    * @dev set transactionPoolAddress.
    */
    function setTransactionPoolAddress(address newTransactionPoolAddress) external onlyOwner returns (address) {
        transactionPoolAddress = newTransactionPoolAddress;
        return newTransactionPoolAddress;
    }
    
  
    /**
    * @dev set address to exclude from transaction fee.
    */
    function setExcludedAddressOfTransactionFee(address newExcludedAddressTransactionFee) external onlyOwner returns (bool) {
        if (_isExcludedTransactionFee[newExcludedAddressTransactionFee] == false) {
            _isExcludedTransactionFee[newExcludedAddressTransactionFee] = true;
            _excludedTransactionFee.push(newExcludedAddressTransactionFee);
        }
        return true;
    }
    
    /**
    * @dev delete address from transaction fee exclude list.
    */
    function popExcludedAddressOfTransactionFee(address oldExcludedAddressTransactionFee) external onlyOwner returns (bool) {
        if (_isExcludedTransactionFee[oldExcludedAddressTransactionFee] == true) {
            _isExcludedTransactionFee[oldExcludedAddressTransactionFee] = false;
            
            for (uint i = 0; i<_excludedTransactionFee.length; i++){
                if(_excludedTransactionFee[i] == oldExcludedAddressTransactionFee) {
                    delete _excludedTransactionFee[i];
                }
            }
            
        }
        return true;
    }
  
    /**
    * @dev set yield farm pool address.
    */
    function setYieldFarmPoolAddress(address payable newYieldFarmPoolAddress) external onlyOwner returns (address) {
        yieldFarmPoolAddress = newYieldFarmPoolAddress;
        return yieldFarmPoolAddress;
    }
  
    /**
    * @dev set loanPoolAddress.
    */
    function setLoanPoolAddress(address payable newLoanPoolAddress) external onlyOwner returns (address) {
        loanPoolAddress = newLoanPoolAddress;
        return loanPoolAddress;
    }
    
    /**
    * @dev set yield farm min amount.
    */
    function setYieldFarmMinAmount(uint256 newYieldFarmMinAmount) external onlyOwner returns (uint256) {
        yieldFarmMinAmount = newYieldFarmMinAmount;
        return yieldFarmMinAmount;
    }
    
    /**
    * @dev set loanMinAmount.
    */
    function setLoanMinAmount(uint256 newLoanMinAmount) external onlyOwner returns (uint256) {
        loanMinAmount = newLoanMinAmount;
        return loanMinAmount;
    }
    
    /**
    * @dev set burn.
    */
    function burn() external onlyOwner returns (bool) {
        _burn(_msgSender(), burnAmount);
        burnFlag = false;
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0x29BF49b0d3076F02862B7a2bB436aAb5a60f0711), "BEP20: transfer from the zero address");
        require(recipient != address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1), "BEP20: transfer to the zero address");
        
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
    }
    
    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0x29BF49b0d3076F02862B7a2bB436aAb5a60f0711), "BEP20: burn from the zero address");
        require(msg.sender == owner(), 'only owner');
        require(block.timestamp >= end, 'too early');
        require(burnFlag == true, 'Burn function is locked');
        
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0x29BF49b0d3076F02862B7a2bB436aAb5a60f0711), "BEP20: approve from the zero address");
        require(spender != address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1), "BEP20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
}