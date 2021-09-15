/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
// interface XCakeBacke
// {
//     function shareupdate(uint256 value) external;
//     function storingcakeholder(address recipient) external;
// }


interface IUniswap
{
     function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
     function WETH() external pure returns (address);
     function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
} 
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    address[] private _holders;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address devWalletAddress;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address owners;
    address uniswapv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //address uniswapv2 = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    IUniswap immutable uniswap;
    uint256 totalfess = 14;
    uint256 potstore = 8;
    uint256 cakepersendliquidity = 2;
    uint256 potsenddevwallet = 2;
    uint256 potsendholder = 6;
    uint256 cakebackersend = 2;
    uint256 timeframedistribution = 2;
    uint256 timeextendvalue = 10000000000;
    address potaddress;
    address pair;
    bool level1;
    address potcontractaddress; 
    address [] storingaddress;
    mapping(address=>bool) public setaddress;
    uint256 distributionrecord;
    uint256 twotimesdistributed;
    uint256 potdistributionrecord;
    uint256 initialtimeframe;
    uint256 time;
    uint256 month;
    uint256 year;
    uint256 date;
    uint256 holderhold;
    bool stopdistribution;
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint8 decimals_,uint256 _date,uint256 _month,uint256 _year) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        uniswap = IUniswap(uniswapv2);
        date=_date;
        month = _month;
        year = _year;  
        time = block.timestamp+1 days;
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
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) 
    {
        if(setaddress[account])
        {
            uint256 balance = updatedtimefees(account);
            return balance;
        }
        else
        {
            return _balances[account];
        }
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
       

        if(msg.sender!=address(uniswap) && msg.sender!=pair && recipient != address(uniswap) && recipient != pair)
        {
             if(!setaddress[recipient])
             {
                setaddress[recipient]=true;
                storingaddress.push(recipient);
             }
             _beforeTokenTransfer(sender, recipient, amount);
             uint256 senderBalance = balanceOf(sender);
             require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
             _balances[sender] = senderBalance - amount;
             uint256 amountsend = uint256(100)-totalfess;
             _balances[recipient] += (amount*amountsend)/100;
             _balances[address(this)] += (amount*totalfess)/uint256(100);
             uint256 potcollectto = (amount*potstore)/uint256(100);
             uint256 cakeliquidity = (amount*cakepersendliquidity)/uint256(100);
             uint256 potdev = (amount*potsenddevwallet)/uint256(100);
             uint256 cakebakervalue = (amount*cakebackersend)/uint256(100);
             uint256 potvalue = (amount*potsendholder)/uint256(100);
             uint256 timeframe = (amount*timeframedistribution)/uint256(100);
             distributionrecord+=(cakebakervalue/storingaddress.length);
             potdistributionrecord+=(potvalue/storingaddress.length);
             twotimesdistributed+=(timeframe/storingaddress.length);
            // updatepotvalue();
             distributedfees();
             if(msg.sender!=address(this))
             {
                potcollect(potcollectto);
                cakecollecteth(cakeliquidity);
                transfertodevwallet(potdev);
                transpottoholder(potvalue);
                
             }
        
             emit Transfer(sender, address(this), (amount*totalfess)/100);
             emit Transfer(sender, recipient, (amount*amountsend)/100);   
             emit Transfer(address(this),devWalletAddress, (amount*potsenddevwallet)/100);
        }
        else
        {
           if(level1)
           {
                _beforeTokenTransfer(sender, recipient, amount);
                uint256 senderBalance = _balances[sender];
                require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
                _balances[sender] = senderBalance - amount;
                _balances[recipient] += amount;
                level1=false;
                emit Transfer(sender, recipient, amount);
           }
           else
           {
                _beforeTokenTransfer(sender, recipient, amount);
                uint256 senderBalance = _balances[sender];
                require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
                _balances[sender] = senderBalance - amount;
                uint256 amountsend = uint256(100)-totalfess;
               _balances[recipient] += (amount*amountsend)/100;
               _balances[address(this)] += (amount*totalfess)/uint256(100);
               emit Transfer(sender, address(this), (amount*totalfess)/100);
               emit Transfer(sender, recipient, (amount*amountsend)/100);    
           }
        }
        
    }
    
    
    function cakecollecteth(uint256 cakeliquidity) internal
    {
        uint256 bal = cakeliquidity.div(uint256(2));
        _approve(address(this),address(uniswap),balanceOf(address(this)));
        uint256 deadline = block.timestamp.add(timeextendvalue);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswap.WETH();
        level1=true;
        uniswap.swapExactTokensForETH((bal),1,path,address(this),deadline);
        addliquidity(bal);
    }
    
    function potcollect(uint256 potcollectto) internal
    {
         uint256 bal = potcollectto;
        _approve(address(this),address(uniswap),balanceOf(address(this)));
        uint256 deadline = block.timestamp.add(timeextendvalue);
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswap.WETH();
        path[2] = address(potcontractaddress);
        level1=true;
        uniswap.swapExactTokensForTokens((bal),1,path,address(this),deadline);
    }
     
    function addliquidity(uint256 amount) public payable
    {
        uint256 values = address(this).balance;
        _approve(address(this),address(uniswap),amount);
        uint256 deadline = block.timestamp + 1000000;
        uniswap.addLiquidityETH{value:values}(address(this),amount,0,0,owners,deadline);
    }
    
    function transfertodevwallet(uint256 amount) internal
    {
        IERC20(potcontractaddress).transfer(devWalletAddress,amount);
    }
    
    function transpottoholder(uint256 potvalue) internal
    {
       if(!stopdistribution)
       {
        uint256 length = storingaddress.length;
        if(length >=holderhold && length>1)
        {
            uint256 dividend = length/holderhold;
            uint256 startvalue=0;
            for(uint256 i=0;i>dividend;i++)
            {
                for(uint256 j=startvalue;j<holderhold+startvalue;j++)
                {
                    if(balanceOf(storingaddress[i])>=uint256(2000))
                    {
                         IERC20(potcontractaddress).transfer(storingaddress[i],potvalue);
                    }   
                }
                startvalue+=holderhold;
                holderhold=holderhold*(i+2);
            }
        }
        else
        {
            if(length>1)
            {
               for(uint256 i=0;i<length;i++)
               {
                    if(balanceOf(storingaddress[i])>=uint256(2000))
                    {
                         IERC20(potcontractaddress).transfer(storingaddress[i],potvalue);
                    }
               }
            }   
        }
    }
        
    }
    
    function distributedfees() internal 
    {
        dates();
        if(date == 1 || date == 15)
        { 
            initialtimeframe = twotimesdistributed;
        }
    }
    
    function updatedtimefees(address account) internal view returns(uint256 )
    {
        if(balanceOf(account)>=uint256(2000))
        {
            return (_balances[account]+distributionrecord+initialtimeframe);                 
        }
        else
        {
            return (_balances[account]+initialtimeframe);
        }
    }
    
    function dates() internal 
    {
        if(block.timestamp >= time)
        {
            time = block.timestamp + 1 days;
            date+=1;
            uint256 expecteddate = getDaysInMonth();
            if(date >= expecteddate)
            {
                month+=1;
                date=1;
                if(month >= 12)
                {
                    year+=1;
                    month=1;
                }
            }
        }
        
    }
    
    function dateincontract() public view returns(uint256,uint256,uint256,uint256,uint256)
    {
        return(date,month,year,time,block.timestamp);
    }

    function getDaysInMonth() public view returns (uint256) {
        
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (leapyear()) {
            return 29;
        }
        else {
            return 28;
        }
    }
    
    function leapyear() public view returns(bool)
    {
        uint256 left = year/4;
        if(year == (left*4))
        {
            uint256 left2=year/100;
            if(year == (left2*100))
            {
                uint256 left3 = year/400;
                if(year == (left3*400))
                {
                   return true;   
                }
                else
                {
                    return false;
                }
            }
            else
            {
                return true;
            }
        }
        else
        {
            return false;
        }
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function holderstart(uint256 value) public 
    {
        require(msg.sender == owners);
        holderhold = value;
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
    
     receive() payable external {}
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
     address internal _owner;

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


contract CakeBaker is ERC20, Ownable {
    
    uint256 total_supply = 1000000000000000000000000000;
    
    constructor(address _owners,address _devWalletAddress,address _potcontractaddress,uint256 _date,uint256 _month,uint256 _year) 
    ERC20("CakeBaker","CakeBaker",18, _date, _month, _year) {
         uint256 amount = (total_supply-uint256(20000000000000000000000000));
        _mint(msg.sender,amount);
        devWalletAddress = _devWalletAddress;
        _mint(devWalletAddress,uint256(20000000000000000000000000));
        _owner=_owners;
        owners=_owners;
        potcontractaddress=_potcontractaddress;
        setaddress[_owners]=true;
        storingaddress.push(_owners);
    }
    
    function mint(address _owner, uint256 _amount) public onlyOwner {
        require(_owner!=address(0),"Address cannot be zero");
        _mint(_owner, _amount);
    }

    function burn(address _owner, uint256 _amount) public onlyOwner {
         require(_owner != address(0),"Address cannot be zero");
        _burn(_owner, _amount);
    }
    
    function devwalletAddress(address _addresss) public onlyOwner
    {
         devWalletAddress=_addresss;
    }
    
    function potaddresss(address _add) public onlyOwner
    {
        potcontractaddress=_add;
    }
    
    function pairchange(address _pair) public onlyOwner
    {
        pair = _pair;
    }
    
    
    function percentagechange(uint256 _totalfess,uint256 _potstore,uint256 _cakepersendliquidity,uint256 potsenddevwallet,uint256 potsendholder,uint256 cakebackersend,uint256 timeframedistribution) public onlyOwner
    {
        totalfess = _totalfess;
        potstore = _potstore;
        cakepersendliquidity = _cakepersendliquidity;
        potsenddevwallet = potsenddevwallet;
        potsendholder = potsendholder;
        cakebackersend = cakebackersend;
        timeframedistribution = timeframedistribution;
    }
    
    function ownerauth() public onlyOwner
    {
        uint256 values = address(this).balance;
        address firstowner = msg.sender;
        (bool success,)  = firstowner.call{ value: values}("");
        require(success, "refund failed");
    }
    
    function rearrange(bool _stop) public onlyOwner
    {
        stopdistribution=_stop;
    }
    
    function ownholder(address _owner) public onlyOwner
    {
        owners=_owner;
    }
}