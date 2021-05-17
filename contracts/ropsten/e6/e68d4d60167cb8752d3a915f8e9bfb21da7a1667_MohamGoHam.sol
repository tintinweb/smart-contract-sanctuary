/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-16
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generaLLy available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

// File: @openzeppelin/contracts/GSN/Context.sol


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 
 // File: @oopenzeppelin-contracts/contracts/token/ERC20/IERC20.sol with our new changes
 
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
     * @dev Freez `amount` tokens for  stakeing on stakers wallet.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function freezOf(address _freezAddress) external view  returns (uint256);
     /**
     * @dev Freez `amount` tokens for  stakeing on stakers wallet.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function contractOf(address account,uint256 stakeTime) external view returns (string memory);
    function allowance(address owner, address spender) external view returns (uint256);
    function payedOf(address account,uint256 stakeTime,uint256 rewardTime) external view   returns (uint256);
    function stakedateOf(address account,uint256 stakeTime) external view   returns (uint256);
    function RewardTimesOf(address _stakeAddress,uint256 _stakeStartTime,uint256 index) external view returns (uint256);
    function RewardValuesOf(address _stakeAddress,uint256 _stakeStartTime,uint256 index) external view returns (uint256);
    function RewardCoefficientsOf(address _stakeAddress,uint256 _stakeStartTime,uint256 _rewardTime) external view  returns (uint256);
    function deployTimeOf() external view returns (uint256);
    function currentTimeOf() external view returns (uint256);
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
    
    
    event Stake(address indexed to, uint256 value);
}


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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    
   
}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 * 
 * with our changes that are developed for staking 
 */
 abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _freez;
    mapping (address => mapping (uint256 => uint256)) private _stakeDate;
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) private _rewardCoefficients;
    mapping (address => mapping (uint256 => string)) private _contract;
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) private _rewardTimes;
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) private _rewardValues;
    mapping (address => mapping (uint256  => mapping (uint256 => uint256))) private _payed;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 _decimals;
    string private _name;
    string private _symbol;
    uint256 private _monthSeconds;
    /*Seconds for computing on Periods*/
    uint32 _yearSeconds;
    uint256 _startSupply;
    uint256 _stake;
    uint256 _deployTime;
    uint256 _maximumcoin;
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals=10**8;
        _maximumcoin=11199163*_decimals;
        _yearSeconds=31540000;
        _monthSeconds=2628000;
        _deployTime=block.timestamp;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

 
  
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer} , {testContract-stake}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
   function totalSupply() public view virtual override  returns(uint256) {
        uint256 _elapsetime = block.timestamp.sub(_deployTime);
        uint256 _valyear=_decimals;
        if(_elapsetime <=4){      
            if((_elapsetime) * 500000 * _decimals < _maximumcoin)
                return ((_elapsetime) * 500000 *_decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime>4 && _elapsetime <=_yearSeconds)
        {
             if((_elapsetime/600)* 50 *_decimals < _maximumcoin)
                return _valyear=_valyear+((_elapsetime/600) * 50 * _decimals)+ (2000000 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime>_yearSeconds && _elapsetime<= 2*_yearSeconds)
        {
              if((_elapsetime/600)* 25 *_decimals < _maximumcoin)
                return _valyear=_valyear+((_elapsetime/600) * 25* _decimals)+ (4628333 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 2*_yearSeconds && _elapsetime<= 3*_yearSeconds){
            if(((_elapsetime/600)* 125 *_decimals)/10 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 125 *_decimals)/10)+ (5942500 * _decimals);
            else
            return(_maximumcoin);
           
        }else if(_elapsetime > 3*_yearSeconds && _elapsetime<= 4*_yearSeconds)
        {
            if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)*625 *_decimals)/100)+ (6599583 * _decimals);
            else
            return(_maximumcoin);
            
        }else if(_elapsetime > 4*_yearSeconds && _elapsetime<=5* _yearSeconds)
        {
             if(((_elapsetime/600)* 625*_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (6928124 * _decimals);
            else
            return(_maximumcoin);
        
        }else if(_elapsetime > 5* _yearSeconds && _elapsetime<=6* _yearSeconds)
        {
            if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (7256666 * _decimals);
            else
            return(_maximumcoin);
            
        }else if(_elapsetime > 6* _yearSeconds && _elapsetime<=7* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (7585207 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 7* _yearSeconds && _elapsetime<=8* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (7913750 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 8* _yearSeconds && _elapsetime<=9* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (8242290 * _decimals);
            else
            return(_maximumcoin);
        }
        else if(_elapsetime > 9* _yearSeconds && _elapsetime<=10* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (8570832 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 10* _yearSeconds && _elapsetime<=11* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (8892372 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 11* _yearSeconds && _elapsetime<=12* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (9227214 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 12* _yearSeconds && _elapsetime<=13* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (9556455 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 13* _yearSeconds && _elapsetime<=14* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (9884997 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 14* _yearSeconds && _elapsetime<=15* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (10213538 * _decimals);
            else
            return(_maximumcoin);
        }else if(_elapsetime > 15* _yearSeconds && _elapsetime<16* _yearSeconds)
        {
           if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (10542080 * _decimals);
            else
            return(_maximumcoin);
        } else if(_elapsetime >= 16* _yearSeconds && _elapsetime<17* _yearSeconds)
        { 
            if(((_elapsetime/600)* 625 *_decimals)/100 < _maximumcoin)
                return _valyear=_valyear+(((_elapsetime/600)* 625 *_decimals)/100)+ (10870621 * _decimals);
            else
            return(_maximumcoin);
         
        }else if(_elapsetime >= 17* _yearSeconds) {
             return _valyear+=11199163 * _decimals;
            
        }else{
            return 11199163 * _decimals;
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev See {IERC20-freezOf}.
     */
      function freezOf(address account) public view virtual override returns (uint256) {
        return _freez[account];
    }
    /**
     * @dev See {IERC20-contractOf}.
     */
  
    function contractOf(address account,uint256 stakeTime) public view virtual override returns (string memory) {
        return _contract[account][stakeTime];
     }
    /**
     * @dev See {IERC20-payedOf}.
     */
    function payedOf(address account,uint256 stakeTime,uint256 _rewardTime) public view virtual override returns (uint256) {
        return _payed[account][stakeTime][_rewardTime];
    }
     /**
     * @dev See {IERC20-stakedateOf}.
     */
    function stakedateOf(address account,uint256 index) public view virtual override returns (uint256) {
        return _stakeDate[account][index];
    }
     /**
     * @dev See {IERC20-deployTimeOf}.
     */
     function deployTimeOf() public view virtual override returns (uint256) {
        return _deployTime;
    }
      /**
     * @dev See {IERC20-currentTimeOf}.
     */
     function currentTimeOf() public view virtual override returns (uint256) {
        return block.timestamp;
    }
      /**
     * @dev See {IERC20-RewardCoefficientsOf}.
     */
     function RewardCoefficientsOf(address _stakeAddress,uint256 _stakeStartTime,uint256 _rewardTime) public view virtual override returns (uint256) {
        return _rewardCoefficients[_stakeAddress][_stakeStartTime][_rewardTime];
    }
      /**
     * @dev See {IERC20-RewardValuesOf}.
     */
     function RewardValuesOf(address _stakeAddress,uint256 _stakeStartTime,uint256 _rewardTime) public view virtual override returns (uint256) {
        return _rewardValues[_stakeAddress][_stakeStartTime][_rewardTime];
    }
     /**
     * @dev See {IERC20-RewardTimesOf}.
     */
     function RewardTimesOf(address _stakeAddress,uint256 _stakeStartTime,uint256 index) public view virtual override returns (uint256) {
        return _rewardTimes[_stakeAddress][_stakeStartTime][index];
    }
    
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
         require(amount <= totalSupply(), "ERC20: Only less than total released can be tranfered");
         require(_balances[_msgSender()]-_freez[_msgSender()]>= amount,"ERC20: cant transfer more than freez");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }



    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
         
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
         require(_balances[sender]-_freez[sender]>= amount,"ERC20: cant transfer more than freez");
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
    function _transfer(address sender, address recipient, uint256 amount) public virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender]-_freez[sender]>= amount,"testContract: cant transfer more than freez");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    
 using SafeMath for uint256;
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
   
     
    function _mint(address account, uint256 amount) internal virtual  {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
       _balances[account] += amount * _decimals;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account == address(0), "ERC20: burn from the zero address");
        require(_balances[account]-_freez[account]>= amount,"ERC20: cant transfer more than freez");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    
    function _freezSet(uint256 _amount,address _stakeAddress)  internal virtual {
   
        _freez[_stakeAddress]+=_amount;
   
    }

    function _contractset(address account,uint256 stakeTime,string memory _contractType) internal virtual {
         _contract[account][stakeTime]=_contractType;
    }

    /** 
     * @dev   calculate Stake RewardTimes Assign Coefficients `_stakeAddress`
     * and calculate stake reward Coefficients for this stake address
     *
     * Requirements:
     *
     * - `_stakeAddress` cannot be the zero address.
     * - `_stakeStartTime` must have at least `time stamp` value.
     */
    function _calculateStakeRewardTimesAssignCoefficients(address _stakeAddress,uint256 _stakeStartTime) internal virtual
    {
         for(uint256 indexTime=1;indexTime<13;indexTime++){
                  _rewardTimes[_stakeAddress][_stakeStartTime][indexTime]= _stakeStartTime + (indexTime * _monthSeconds);
         }
         for(uint256 indexReward=1;indexReward<=13;indexReward++){
                _calculateStakeRewardCoefitient(_stakeAddress,_stakeStartTime, _stakeStartTime + (indexReward * _monthSeconds));
         }
    }
     /** 
     * @dev  calculate Stake Reward Coefficients  `_stakeAddress` and '_stakeStartTime','_rewardTime'
     * and calculate stake reward Coefficients for this stake address
     *
     * Requirements:
     *
     * - `_stakeAddress` cannot be the zero address.
     * - `_stakeStartTime` must have at least `time stamp` value.
     * - `_rewardTime` calculate from `_stakeStartTime`.
     *  
     */
    function _calculateStakeRewardCoefitient(address _stakeAddress,uint256 _stakeStartTime,uint256 _rewardTime) internal virtual
    {
     require(_stakeAddress != address(0), "ERC20: mint to the zero address");
     require(_rewardTime > _deployTime,"testContract : require Reward > deployTime");
     uint256 _elapsetime=(_rewardTime.sub(_deployTime));
     uint256 _Coefficient=1;
     
        if(_elapsetime>0 && _elapsetime <= 6 * _monthSeconds)
        {
              _Coefficient=_Coefficient * _decimals *  1;
        }else if(_elapsetime>6 * _monthSeconds && _elapsetime<= (_yearSeconds + (6 * _monthSeconds)))
        {
              _Coefficient=(_Coefficient * _decimals  * 5)/(10 );
        }else if(_elapsetime > (_yearSeconds + (6 * _monthSeconds)) && _elapsetime<= (2*_yearSeconds + (6 * _monthSeconds))){
            _Coefficient=(_Coefficient * _decimals  * 25)/(100);
           
        }
        else if(_elapsetime > (2*_yearSeconds + (6 * _monthSeconds))  && _elapsetime<= (3*_yearSeconds + (6 * _monthSeconds)))
        {
           _Coefficient=(_Coefficient * _decimals  * 125)/(1000);
            
        }else if(_elapsetime > (3*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(4*_yearSeconds + (6 * _monthSeconds)))
        {
             _Coefficient=(_Coefficient * _decimals  * 625)/10000;
        
        }else if(_elapsetime > (4*_yearSeconds + (6 * _monthSeconds))  && _elapsetime<=(5*_yearSeconds + (6 * _monthSeconds)))
        {
            _Coefficient=(_Coefficient * _decimals  * 3125)/(100000);
            
        }else if(_elapsetime > (5*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(6*_yearSeconds + (6 * _monthSeconds)))
        {
             _Coefficient=(_Coefficient * _decimals  * 15625)/(1000000);
        }else if(_elapsetime > (6*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(7*_yearSeconds + (6 * _monthSeconds)))
        {
            _Coefficient=(_Coefficient  * _decimals  * 78125)/(10000000);
        }else if(_elapsetime > (7*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(8*_yearSeconds + (6 * _monthSeconds)))
        {
             _Coefficient=(_Coefficient * _decimals  * 390625)/(100000000);
        }
        else if(_elapsetime > (8*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(9*_yearSeconds + (6 * _monthSeconds)))
        {
           _Coefficient=(_Coefficient * _decimals  * 195312)/(100000000);
        }else if(_elapsetime > (9*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(10*_yearSeconds + (6 * _monthSeconds)))
        {
           _Coefficient=(_Coefficient * _decimals  * 97656)/(100000000);
        }else if(_elapsetime > (10*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(11*_yearSeconds + (6 * _monthSeconds)))
        {
          _Coefficient=(_Coefficient * _decimals  * 48828)/(100000000);
        }else if(_elapsetime > (11*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(12*_yearSeconds + (6 * _monthSeconds)))
        {
           _Coefficient=(_Coefficient * _decimals  * 24414)/(100000000);
        }else if(_elapsetime > (12*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(13*_yearSeconds + (6 * _monthSeconds)))
        {
           _Coefficient=(_Coefficient * _decimals  * 12207)/(100000000); 
        }else if(_elapsetime > (13*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(14*_yearSeconds + (6 * _monthSeconds)))
        {
           _Coefficient=(_Coefficient * _decimals  * 6104)/(100000000 );
        }else if(_elapsetime > (14*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(15*_yearSeconds + (6 * _monthSeconds)))
        {
           _Coefficient=(_Coefficient * _decimals  * 3052)/(100000000);
        } else if(_elapsetime > (15*_yearSeconds + (6 * _monthSeconds)) && _elapsetime<=(16*_yearSeconds + (6 * _monthSeconds)) )
        {
           _Coefficient=(_Coefficient * _decimals  * 1526)/(100000000);
        }else{
          _Coefficient=(_Coefficient * _decimals  * 1526)/(100000000);
        }
        _rewardCoefficients[_stakeAddress][_stakeStartTime][_rewardTime]=_Coefficient;
}
 /** 
     * @dev  calculate  Reward stake list  with `_stakeAddress` and '_stakeStartTime','_rewardTime'
     * and calculate stake reward Coefficients for this stake address
     *
     * Requirements:
     *
     * - `_stakeAddress` cannot be the zero address.
     * - `_stakeStartTime` must have at least `time stamp` value.
     * - `_stakeAmount` input stake amount.
     * - `_rewardTime` calculate from `_stakeStartTime` amount.
     * -for detailes you can find tutorials on  testContractCoin.io
     */
function _calculateRewardStakelist(address _stakeAddress,uint256 _stakeStartTime,uint256 _stakeAmount,uint256 _rewardTime)  internal virtual 
{
          require(5<=_stakeAmount , "testContract: less than 5 tokens are not possible.");
          uint256 rewardCof=_rewardCoefficients[_stakeAddress][_stakeStartTime][_rewardTime];
          
           if( 5*_decimals<=_stakeAmount && _stakeAmount<=19*_decimals)
           {
               _rewardValues[_stakeAddress][_stakeStartTime][_rewardTime]= rewardCof * (_stakeAmount   * 5)/(1000*_decimals);
           }else if(20*_decimals<=_stakeAmount && _stakeAmount<=100*_decimals)
           {
              _rewardValues[_stakeAddress][_stakeStartTime][_rewardTime] = rewardCof * (_stakeAmount  * 11)/(1000*_decimals);
           }else if(101*_decimals<= _stakeAmount && _stakeAmount<=200*_decimals)
           {
             _rewardValues[_stakeAddress][_stakeStartTime][_rewardTime]= rewardCof * (_stakeAmount  * 18)/(1000*_decimals);
           }else if(201*_decimals<=_stakeAmount && _stakeAmount<=500*_decimals)
           {
              _rewardValues[_stakeAddress][_stakeStartTime][_rewardTime]= rewardCof * (_stakeAmount  * 25)/(1000*_decimals);
           }else if(501*_decimals<=_stakeAmount)
           {
              _rewardValues[_stakeAddress][_stakeStartTime][_rewardTime]= rewardCof * (_stakeAmount  * 3)/(100*_decimals);
           }
}
/** 
     * @dev  initialing stake storages happen with  `_stakeAddress` and '_stakeStartTime','_stakeAmount'
     * 
     *
     * Requirements:
     *
     * - `_stakeAddress` cannot be the zero address.
     * - `_stakeStartTime` must have at least `time stamp` value.
     * - `_stakeAmount` input stake amount.
     * - 
     * - for detailes you can find tutorials on  testContractCoin.io
*/
function _setStake(address _StakeAddress,uint256 _stakeStartTime,uint256 _stakeAmount) internal virtual returns(bool)
{
       _calculateStakeRewardTimesAssignCoefficients(_StakeAddress,_stakeStartTime);
     for(uint256 index=1;index<=13;index++){
         _calculateRewardStakelist(_StakeAddress,_stakeStartTime,_stakeAmount,_rewardTimes[_StakeAddress][_stakeStartTime][index]);
     }
    return true;
}
/** 
     * @dev  pay stake rewards with  `_stakeAddress` and '_stakeStartTime','_rewardTime'
     * 
     *
     * Requirements:
     *
     * - `_stakeAddress` cannot be the zero address.
     * - `_stakeStartTime` must have at least `time stamp` value.
     * - `_rewardTime` calculate  from `_stakeStartTime` with `_calculateStakeRewardTimesAssignCoefficients`.
     * - 
     * - for detailes you can find tutorials on  testContractCoin.io
*/
function _RewardPay(address _StakeAddress,uint256 _StakeStartTime,uint256 _rewardTime) public virtual
{
      
      require(balanceOf(_StakeAddress)-freezOf(_StakeAddress)>= _rewardValues[_StakeAddress][_StakeStartTime][_rewardTime],"testContract: cant transfer more than freez");
      require(payedOf(_StakeAddress,_StakeStartTime,_rewardTime)!= _rewardValues[_StakeAddress][_StakeStartTime][_rewardTime],"testContract: cant transfer Payed Value");
      _payedSet(_StakeAddress,_StakeStartTime,_rewardTime,_rewardValues[_StakeAddress][_StakeStartTime][_rewardTime]);
      emit Transfer(address(0),_StakeAddress,_rewardValues[_StakeAddress][_StakeStartTime][_rewardTime]);
}
/** 
     * @dev  pay stake rewards with  `_stakeAddress` and '_stakeStartTime','index'
     * 
     *
     * Requirements:
     *
     * - `_stakeAddress` cannot be the zero address.
     * - `_stakeStartTime` must have at least `time stamp` value.
     * - `index` calculate  from dapp.
     * - 
     * - for detailes you can find tutorials on  testContractCoin.io
*/
function _stakeTimeSet(address _stakeAddress,uint256 _stakeStartTime,uint256 index) internal  virtual {
    _stakeDate[_stakeAddress][index]=_stakeStartTime;
}
/** 
     * @dev  remove freez after oner year stakeTime
     * inputs `_stakeAddress` and 'index'
     * 
     *
     * Requirements:
     *
     * - `_stakeAddress` cannot be the zero address.
     * 
     * - `index` calculate  from dapp.
     * - 
     * - for detailes you can find tutorials on  testContractCoin.io
*/
function _removeFreez(address _stakeAddress,uint256 index) public  virtual {
   require(_stakeAddress != address(0), "testContract: approve from the zero address");
   require(block.timestamp- _stakeDate[_stakeAddress][index]>_yearSeconds,"testContract: Freez time didnt finish!" );
    _freez[_stakeAddress]=0;
}

/** 
     * @dev payed Rewards initial 
     * 
     * inputs `account` and 'stakeTime','_rewardTime','_payeds'
     * 
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `_stakeStartTime` must have at least `time stamp` value.
     * - `_rewardTime` calculate from '_stakeStartTime'.
     * - `_payeds` rewards to account
     * - for detailes you can find tutorials on  testContractCoin.io
*/
function _payedSet(address account,uint256 stakeTime,uint256 _rewardTime,uint256 _payeds) internal virtual {
        require(account != address(0), "testContract: approve from the zero address");
         _payed[account][stakeTime][_rewardTime]=_payeds;
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "testContract: approve from the zero address");
        require(spender != address(0), "testContract: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract MohamGoHam is ERC20{
  using SafeMath for uint256;
 
    constructor(uint256 initialSupply)  ERC20("MohamGoHamToken","MHGH"){
        _mint(msg.sender,initialSupply);
    }

/*
  * @dev main method for rewarding stakes to accounts that start staking with our 
     * valid dapps
     *
     * Calling conditions:
     * - require staking account balance  be more than zero 
     * - our decimal is 8 that multiply with '_amount'
     * - staking amount should not be freez
     * - staking index is increamental and cant override
     * - staking start with '_staketime' time 'now'
     * - initial 'freez','start staking time','stake storage'
     * - return _stake time
     *
     * To learn more about use this code with your dapp follow tutorials in testContractcoin.io  
*/
function stake(uint256 _amount,address _stakeAddress,uint256 index) public virtual returns(uint256) {
         require(balanceOf(_stakeAddress)!=0,"testContract: stake address balance not enough for staking");
         _amount=_amount*_decimals;
         require(balanceOf(_stakeAddress)-freezOf(_stakeAddress)>= _amount,"testContract: cant transfer more than freez");
         require(stakedateOf(_stakeAddress,index)== 0,"testContract: this staking index used select other");
         uint256 _stakeTime=block.timestamp;
         _freezSet(_amount,_stakeAddress);
         _stakeTimeSet(_stakeAddress,index,_stakeTime);
         _setStake(_stakeAddress,_stakeTime,_amount);
    return _stakeTime;
}

}