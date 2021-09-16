/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: Unlicensed

/*  1% autoBurn
    4 % Redistribution
    8 % MarketingFee
    3 % Charity wallet
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender; //0xBf905F61B59139387a561E7545Dd6afE4F6b670C;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract Snowy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // Keeps track of balances for address that are included in receiving reward.
    mapping (address => uint256) private _reflectionBalances;

    // Keeps track of balances for address that are excluded from receiving reward.
    mapping (address => uint256) private _tokenBalances;

    // Keeps track of which address are excluded from fee.
    mapping (address => bool) private _isExcludedFromFee;

    // Keeps track of which address are excluded from reward.
    mapping (address => bool) private _isExcludedFromReward;
    
    // An array of addresses that are excluded from reward.
    address[] private _excludedFromReward;

    // ERC20 Token Standard
    mapping (address => mapping (address => uint256)) private _allowances;

    // Where burnt tokens are sent to. This is an address that no one can have accesses to.
     address private constant burnAccount = 0x000000000000000000000000000000000000dEaD;
     address private constant Marketing = 0xBf905F61B59139387a561E7545Dd6afE4F6b670C;
     address private constant Charity = 0x67e7e46B75c48E20420ae6BEe509FD96f35e18bb;
    
    /*
        Tax rate = (_taxXXX / 10**_tax_XXXDecimals) percent.
        For example: if _taxBurn is 1 and _taxBurnDecimals is 2.
        Tax rate = 0.01%
        If you want tax rate for burn to be 5% for example,
        set _taxBurn to 5 and _taxBurnDecimals to 0.
        5 * (10 ** 0) = 5
    */
    
    // Decimals of taxBurn. Used for have tax less than 1%.
    uint8 private _taxBurnDecimals;

    // Decimals of taxReward. Used for have tax less than 1%.
    uint8 private _taxRewardDecimals;

    // Decimals of taxCharity. Used for have tax less than 1%.
    uint8 private _taxCharityDecimals;
    
    uint8 private _taxMarketingDecimals;

    uint8 private _taxBurn;
    uint8 private _taxReward;
    uint8 private _taxCharity; 
    uint8 private _taxMarketing;

    // ERC20 Token Standard
    uint8 private _decimals;

    // ERC20 Token Standard
    uint256 private  _totalSupply;

    // Current supply:= total supply - burnt tokens
    uint256 private _currentSupply;

    // A number that helps distributing fees to all holders respectively.
    uint256 private _reflectionTotal;

    // Total amount of tokens rewarded / distributing. 
    uint256 public _totalRewarded;

    // Total amount of tokens burnt.
    uint256 private _totalBurnt;

    // ERC20 Token Standard
    string private _name;
    // ERC20 Token Standard
    string private _symbol;

    bool private _charityEnabled;
    bool private _autoBurnEnabled;
    bool private _rewardEnabled;
    bool private _marketingEnabled;
    
    // Return values of _getValues function.
    struct ValuesFromAmount {
        uint256 amount;
        uint256 tBurnFee;
        uint256 tRewardFee;
        uint256 tCharityFee;
        uint256 tTransferAmount;
        uint256 rAmount;
        uint256 rBurnFee;
        uint256 rRewardFee;
        uint256 rCharityFee;
        uint256 rTransferAmount;
        uint256 tMarketingFee;
        uint256 rMarketingFee;
    }

    /*
        Events
    */
    event Burn(address from, uint256 amount);
    event TaxBurnUpdate(uint8 previousTax, uint8 previousDecimals, uint8 currentTax, uint8 currentDecimal);
    event TaxRewardUpdate(uint8 previousTax, uint8 previousDecimals, uint8 currentTax, uint8 currentDecimal);
    event TaxCharityUpdate(uint8 previousTax, uint8 previousDecimals, uint8 currentTax, uint8 currentDecimal);
    event TaxMarketingUpdate(uint8 previousTax, uint8 previousDecimals, uint8 currentTax, uint8 currentDecimal);
    event ExcludeAccountFromReward(address account);
    event IncludeAccountInReward(address account);
    event ExcludeAccountFromFee(address account);
    event IncludeAccountInFee(address account);
    event EnabledAutoBurn();
    event EnabledReward();
    event EnabledMarketing();
    event EnabledCharity();
    event DisabledAutoBurn();
    event DisabledReward();
    event DisabledCharity();
    event DisabledMarketing();
    
/*
constructor () {
        // Sets the values for `name`, `symbol`, `totalSupply`, `currentSupply`, and `rTotal`.
        _name = "SNOWY";
        _decimals = 9;
        _totalSupply = 10000000000000000 * 10 ** 9;
        _currentSupply = _totalSupply;
        _reflectionTotal = (~uint256(0) - (~uint256(0) % _totalSupply));

        // Mint
        _reflectionBalances[_msgSender()] = _reflectionTotal;

        // exclude owner and this contract from fee.
        excludeAccountFromFee(owner());
        excludeAccountFromFee(address(this));

        // exclude owner, burnAccount, and this contract from receiving rewards.
        _excludeAccountFromReward(owner());
        _excludeAccountFromReward(burnAccount);
        _excludeAccountFromReward(address(this));
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

 */ 
 
 
 constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 tokenSupply_) {
        // Sets the values for `name`, `symbol`, `totalSupply`, `currentSupply`, and `rTotal`.
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = tokenSupply_ * (10 ** decimals_);
        _currentSupply = _totalSupply;
        _reflectionTotal = (~uint256(0) - (~uint256(0) % _totalSupply));

        // Mint
        _reflectionBalances[_msgSender()] = _reflectionTotal;

        // exclude owner and this contract from fee.
        excludeAccountFromFee(owner());
        excludeAccountFromFee(address(this));

        // exclude owner, burnAccount, and this contract from receiving rewards.
        _excludeAccountFromReward(owner());
        _excludeAccountFromReward(burnAccount);
        _excludeAccountFromReward(address(this));
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function taxBurn() public view virtual returns (uint8) {
        return _taxBurn;
    }

    /**
     * @dev Returns the current reward tax.
     */
    function taxReward() public view virtual returns (uint8) {
        return _taxReward;
    }

    /**
     * @dev Returns the current charity tax.
     */
    function taxCharity() public view virtual returns (uint8) {
        return _taxCharity;
    }

    /**
     * @dev Returns the current burn tax decimals.
     */
    function taxBurnDecimals() public view virtual returns (uint8) {
        return _taxBurnDecimals;
    }

    /**
     * @dev Returns the current reward tax decimals.
     */
    function taxRewardDecimals() public view virtual returns (uint8) {
        return _taxRewardDecimals;
    }

    /**
     * @dev Returns the current liquify tax decimals.
     */
    function taxCharityDecimals() public view virtual returns (uint8) {
        return _taxCharityDecimals;
    }

     /**
     * @dev Returns true if auto burn feature is enabled.
     */
    function autoBurnEnabled() public view virtual returns (bool) {
        return _autoBurnEnabled;
    }

    /**
     * @dev Returns true if reward feature is enabled.
     */
    function rewardEnabled() public view virtual returns (bool) {
        return _rewardEnabled;
    }
    
     function taxMarketing() public view virtual returns (uint8) {
        return _taxMarketing;
    }

    /**
     * @dev Returns the current liquify tax.
     */
    function taxMarketingDecimals() public view virtual returns (uint8) {
        return _taxMarketingDecimals;
    }
    
    function taxMarketingEnabled() public view virtual returns (bool) {
        return _marketingEnabled;
    }

    /**
     * @dev Returns true if auto swap and liquify feature is enabled.
     */
    function taxCharityEnabled() public view virtual returns (bool) {
        return _charityEnabled;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns current supply of the token. 
     * (currentSupply := totalSupply - totalBurnt)
     */
    function currentSupply() external view virtual returns (uint256) {
        return _currentSupply;
    }

    /**
     * @dev Returns the total number of tokens burnt. 
     */
    function totalBurnt() external view virtual returns (uint256) {
        return _totalBurnt;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tokenBalances[account];
        return tokenFromReflection(_reflectionBalances[account]);
    }

    /**
     * @dev Returns whether an account is excluded from reward. 
     */
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromReward[account];
    }

    /**
     * @dev Returns whether an account is excluded from fee. 
     */
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != burnAccount, "ERC20: burn from the burn address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        uint256 rAmount = _getRAmount(amount);

        // Transfer from account to the burnAccount
        if (_isExcludedFromReward[account]) {
            _tokenBalances[account] -= amount;
        } 
        _reflectionBalances[account] -= rAmount;

        _tokenBalances[burnAccount] += amount;
        _reflectionBalances[burnAccount] += rAmount;

        _currentSupply -= amount;

        _totalBurnt += amount;

        emit Burn(account, amount);
        emit Transfer(account, burnAccount, amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        ValuesFromAmount memory values = _getValues(amount, _isExcludedFromFee[sender]);
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, values);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, values);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, values);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, values);
        } else {
            _transferStandard(sender, recipient, values);
        }

        emit Transfer(sender, recipient, values.tTransferAmount);

        if (!_isExcludedFromFee[sender]) {
            _afterTokenTransfer(values);
        }

    }

    /**
      * @dev Performs all the functionalities that are enabled.
      */
    function _afterTokenTransfer(ValuesFromAmount memory values) internal virtual {
        // Burn
        if (_autoBurnEnabled) {
            _tokenBalances[address(this)] += values.tBurnFee;
            _reflectionBalances[address(this)] += values.rBurnFee;
            _approve(address(this), _msgSender(), values.tBurnFee);
            burnFrom(address(this), values.tBurnFee);
        }
        
        // Marketing
        if (_marketingEnabled) {
            _tokenBalances[Marketing] += values.tMarketingFee;
            _reflectionBalances[Marketing] += values.rMarketingFee;
           
        }
        
        
        // Reflect
        if (_rewardEnabled) {
            _distributeFee(values.rRewardFee, values.tRewardFee);
        }
        
        // Add to Charity Wallet
        if (_charityEnabled) {
            // add charity fee to address.
            _tokenBalances[Charity] += values.tCharityFee;
            _reflectionBalances[Charity] += values.rCharityFee;
        }
    }

    /**
     * @dev Performs transfer between two accounts that are both included in receiving reward.
     */
    function _transferStandard(address sender, address recipient, ValuesFromAmount memory values) private {
        
    
        _reflectionBalances[sender] = _reflectionBalances[sender] - values.rAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + values.rTransferAmount;   

        
    }

    function _transferToExcluded(address sender, address recipient, ValuesFromAmount memory values) private {
        
        _reflectionBalances[sender] = _reflectionBalances[sender] - values.rAmount;
        _tokenBalances[recipient] = _tokenBalances[recipient] + values.tTransferAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + values.rTransferAmount;    

    }

    /**
     * @dev Performs transfer from an excluded account to an included account.
     * (included and excluded from receiving reward.)
     */
    function _transferFromExcluded(address sender, address recipient, ValuesFromAmount memory values) private {
        
        _tokenBalances[sender] = _tokenBalances[sender] - values.amount;
        _reflectionBalances[sender] = _reflectionBalances[sender] - values.rAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + values.rTransferAmount;   

    }

    /**
     * @dev Performs transfer between two accounts that are both excluded in receiving reward.
     */
    function _transferBothExcluded(address sender, address recipient, ValuesFromAmount memory values) private {

        _tokenBalances[sender] = _tokenBalances[sender] - values.amount;
        _reflectionBalances[sender] = _reflectionBalances[sender] - values.rAmount;
        _tokenBalances[recipient] = _tokenBalances[recipient] + values.tTransferAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + values.rTransferAmount;        

    }
    
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
 
    function _excludeAccountFromReward(address account) internal {
        require(!_isExcludedFromReward[account], "Account is already excluded.");

        if(_reflectionBalances[account] > 0) {
            _tokenBalances[account] = tokenFromReflection(_reflectionBalances[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
        
        emit ExcludeAccountFromReward(account);
    }

    function _includeAccountInReward(address account) internal {
        require(_isExcludedFromReward[account], "Account is already included.");

        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tokenBalances[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }

        emit IncludeAccountInReward(account);
    }

    function excludeAccountFromFee(address account) internal {
        require(!_isExcludedFromFee[account], "Account is already excluded.");

        _isExcludedFromFee[account] = true;

        emit ExcludeAccountFromFee(account);
    }


    function includeAccountInFee(address account) internal {
        require(_isExcludedFromFee[account], "Account is already included.");

        _isExcludedFromFee[account] = false;
        
        emit IncludeAccountInFee(account);
    }
    
    function reflectionFromToken(uint256 amount, bool deductTransferFee) internal view returns(uint256) {
        require(amount <= _totalSupply, "Amount must be less than supply");
        ValuesFromAmount memory values = _getValues(amount, deductTransferFee);
        return values.rTransferAmount;
    }

    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    /**
     * @dev Distribute the `tRewardFee` tokens to all holders that are included in receiving reward.
     * amount received is based on how many token one owns.  
     */
    function _distributeFee(uint256 rRewardFee, uint256 tRewardFee) private {
        // This would decrease rate, thus increase amount reward receive based on one's balance.
        _reflectionTotal = _reflectionTotal - rRewardFee;
        _totalRewarded += tRewardFee;
    }
    
    /**
     * @dev Returns fees and transfer amount in both tokens and reflections.
     * tXXXX stands for tokenXXXX
     * rXXXX stands for reflectionXXXX
     * More details can be found at comments for ValuesForAmount Struct.
     */
    function _getValues(uint256 amount, bool deductTransferFee) private view returns (ValuesFromAmount memory) {
        ValuesFromAmount memory values;
        values.amount = amount;
        _getTValues(values, deductTransferFee);
        _getRValues(values, deductTransferFee);
        return values;
    }

    function _getTValues(ValuesFromAmount memory values, bool deductTransferFee) view private {
        
        if (deductTransferFee) {
            values.tTransferAmount = values.amount;
        } else {
            // calculate fee
            values.tBurnFee = _calculateTax(values.amount, _taxBurn, _taxBurnDecimals);
            values.tRewardFee = _calculateTax(values.amount, _taxReward, _taxRewardDecimals);
            values.tCharityFee = _calculateTax(values.amount, _taxCharity, _taxCharityDecimals);
            values.tMarketingFee = _calculateTax(values.amount, _taxMarketing, _taxMarketingDecimals);
            
            // amount after fee
            values.tTransferAmount = values.amount - values.tBurnFee - values.tRewardFee - values.tCharityFee - values.tMarketingFee;
        }
        
    }

    /**
     * @dev Adds fees and transfer amount in reflection to `values`.
     * rXXXX stands for reflectionXXXX
     * More details can be found at comments for ValuesForAmount Struct.
     */
    function _getRValues(ValuesFromAmount memory values, bool deductTransferFee) view private {
        uint256 currentRate = _getRate();

        values.rAmount = values.amount * currentRate;

        if (deductTransferFee) {
            values.rTransferAmount = values.rAmount;
        } else {
            values.rAmount = values.amount * currentRate;
            values.rBurnFee = values.tBurnFee * currentRate;
            values.rRewardFee = values.tRewardFee * currentRate;
            values.rCharityFee = values.tCharityFee * currentRate;
            values.rMarketingFee = values.tMarketingFee * currentRate;
            values.rTransferAmount = values.rAmount - values.rBurnFee - values.rRewardFee - values.rCharityFee - values.rMarketingFee;
        }
        
    }

    /**
     * @dev Returns `amount` in reflection.
     */
    function _getRAmount(uint256 amount) private view returns (uint256) {
        uint256 currentRate = _getRate();
        return amount * currentRate;
    }

    /**
     * @dev Returns the current reflection rate.
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /**
     * @dev Returns the current reflection supply and token supply.
     */
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _reflectionTotal;
        uint256 tSupply = _totalSupply;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_reflectionBalances[_excludedFromReward[i]] > rSupply || _tokenBalances[_excludedFromReward[i]] > tSupply) return (_reflectionTotal, _totalSupply);
            rSupply = rSupply - _reflectionBalances[_excludedFromReward[i]];
            tSupply = tSupply - _tokenBalances[_excludedFromReward[i]];
        }
        if (rSupply < _reflectionTotal / _totalSupply) return (_reflectionTotal, _totalSupply);
        return (rSupply, tSupply);
    }

    /**
     * @dev Returns fee based on `amount` and `taxRate`
     */
    function _calculateTax(uint256 amount, uint8 tax, uint8 taxDecimals_) private pure returns (uint256) {
        return amount * tax / (10 ** taxDecimals_) / (10 ** 2);
    }

    /*
        Owner functions
    */

    /**
     * @dev Enables the auto burn feature.
     * Burn transaction amount * `taxBurn_` amount of tokens each transaction when enabled.
     *
     * Emits a {EnabledAutoBurn} event.
     *
     * Requirements:
     *
     * - auto burn feature mush be disabled.
     * - tax must be greater than 0.
     * - tax decimals + 2 must be less than token decimals. 
     * (because tax rate is in percentage)
     */
    function enableAutoBurn(uint8 taxBurn_, uint8 taxBurnDecimals_) public onlyOwner {
        require(!_autoBurnEnabled, "Auto burn feature is already enabled.");
        require(taxBurn_ > 0, "Tax must be greater than 0.");
        require(taxBurnDecimals_ + 2  <= decimals(), "Tax decimals must be less than token decimals - 2");
        
        _autoBurnEnabled = true;
        setTaxBurn(taxBurn_, taxBurnDecimals_);
        
        emit EnabledAutoBurn();
    }

    /**
     * @dev Enables the reward feature.
     * Distribute transaction amount * `taxReward_` amount of tokens each transaction when enabled.
     *
     * Emits a {EnabledReward} event.
     *
     * Requirements:
     *
     * - reward feature mush be disabled.
     * - tax must be greater than 0.
     * - tax decimals + 2 must be less than token decimals. 
     * (because tax rate is in percentage)
    */
    function enableReward(uint8 taxReward_, uint8 taxRewardDecimals_) public onlyOwner {
        require(!_rewardEnabled, "Reward feature is already enabled.");
        require(taxReward_ > 0, "Tax must be greater than 0.");
        require(taxRewardDecimals_ + 2 <= decimals(), "Tax decimals must be less than token decimals - 2");

        _rewardEnabled = true;
        setTaxReward(taxReward_, taxRewardDecimals_);

        emit EnabledReward();
    }
    
    function enableMarketing(uint8 marketingReward_, uint8 marketingRewardDecimals_) public onlyOwner {
        require(!_marketingEnabled, "Marketing feature is already enabled.");
        require(marketingReward_ > 0, "Tax must be greater than 0.");
        require(marketingRewardDecimals_ + 2  <= decimals(), "Tax decimals must be less than token decimals - 2");

        _marketingEnabled = true;
        setMarketingReward(marketingReward_, marketingRewardDecimals_);

        emit EnabledMarketing();
    }
    
        function enableCharity(uint8 charityReward_, uint8 charityRewardDecimals_) public onlyOwner {
        require(!_charityEnabled, "Charity feature is already enabled.");
        require(charityReward_ > 0, "Tax must be greater than 0.");
        require(charityRewardDecimals_ + 2  <= decimals(), "Tax decimals must be less than token decimals - 2");

        _charityEnabled = true;
        setCharityReward(charityReward_, charityRewardDecimals_);

        emit EnabledCharity();
    }

    function disableAutoBurn() public onlyOwner {
        require(_autoBurnEnabled, "Auto burn feature is already disabled.");

        setTaxBurn(0, 0);
        _autoBurnEnabled = false;
        
        emit DisabledAutoBurn();
    }
    
    

    function disableReward() public onlyOwner {
        require(_rewardEnabled, "Reward feature is already disabled.");

        setTaxReward(0, 0);
        _rewardEnabled = false;
        
        emit DisabledReward();
    }
    
    function disableMarketing() public onlyOwner {
        require(_marketingEnabled, "Matketing feature is already disabled.");

        setTaxReward(0, 0);
        _marketingEnabled = false;
        
        emit DisabledMarketing();
    }
    
    function disableCharity() public onlyOwner {
        require(_charityEnabled, "Charity feature is already disabled.");

        setCharityReward(0, 0);
        _charityEnabled = false;
        
        emit DisabledCharity();
    }

    function setTaxBurn(uint8 taxBurn_, uint8 taxBurnDecimals_) public onlyOwner {
        require(_autoBurnEnabled, "Auto burn feature must be enabled. Try the EnableAutoBurn function.");
        require(taxBurn_ + _taxReward + _taxCharity + _taxMarketing < 100, "Tax fee too high.");

        uint8 previousTax = _taxBurn;
        uint8 previousDecimals = _taxBurnDecimals;
        _taxBurn = taxBurn_;
        _taxBurnDecimals = taxBurnDecimals_;

        emit TaxBurnUpdate(previousTax, previousDecimals, taxBurn_, taxBurnDecimals_);
    }

    function setTaxReward(uint8 taxReward_, uint8 taxRewardDecimals_) public onlyOwner {
        require(_rewardEnabled, "Reward feature must be enabled. Try the EnableReward function.");
        require(_taxBurn + taxReward_ + _taxCharity + _taxMarketing< 100, "Tax fee too high.");

        uint8 previousTax = _taxReward;
        uint8 previousDecimals = _taxRewardDecimals;
        _taxReward = taxReward_;
        _taxBurnDecimals = taxRewardDecimals_;

        emit TaxRewardUpdate(previousTax, previousDecimals, taxReward_, taxRewardDecimals_);
    }

    function setCharityReward(uint8 taxCharity_, uint8 taxCharityDecimals_) public onlyOwner {
        require(_charityEnabled, "Charity feature must be enabled. Try the EnableCharity function.");
        require(_taxBurn + _taxReward + taxCharity_ + _taxMarketing < 100, "Tax fee too high.");

        uint8 previousTax = _taxCharity;
        uint8 previousDecimals = _taxCharityDecimals;
        _taxCharity = taxCharity_;
        _taxCharityDecimals = taxCharityDecimals_;

        emit TaxCharityUpdate(previousTax, previousDecimals, taxCharity_, taxCharityDecimals_);
    }
    
    function setMarketingReward(uint8 taxMarketing_, uint8 taxMarketingDecimals_) public onlyOwner {
        require(_marketingEnabled, "Marketing feature must be enabled. Try the EnableMarket function.");
        require(_taxBurn + _taxReward + _taxCharity + taxMarketing_ < 100, "Tax fee too high.");

        uint8 previousTax = _taxMarketing;
        uint8 previousDecimals = _taxMarketingDecimals;
        _taxMarketing = taxMarketing_;
        _taxMarketingDecimals = taxMarketingDecimals_;
        
        emit TaxMarketingUpdate(previousTax, previousDecimals, taxMarketing_, taxMarketingDecimals_);


    }
    
}