// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
    function add(uint256 a, uint256 b) public pure returns (uint256) {
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
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) public pure returns (uint256) {
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
    function mul(uint256 a, uint256 b) public pure returns (uint256) {
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
    function div(uint256 a, uint256 b) public pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) public pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) public pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) public pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SavixSupply.sol";

contract Savix is IERC20
{
    using SafeMath for uint256;

    address private _owner;
    string private constant NAME = "Savix";
    string private constant SYMBOL = "SVX";
    uint private constant DECIMALS = 9;
    uint private _constGradient = 0;
    address private constant BURNADDR = 0x000000000000000000000000000000000000dEaD; // global burn address

    bool private _stakingActive = false;
    uint256 private _stakingSince = 0;

    uint256 private constant MAX_UINT256 = 2**256 - 1;
    uint256 private constant INITIAL_TOKEN_SUPPLY = 10**5 * 10**DECIMALS;

    // TOTAL_FRAGMENTS is a multiple of INITIAL_TOKEN_SUPPLY so that _fragmentsPerToken is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_FRAGMENTS = MAX_UINT256 - (MAX_UINT256 % INITIAL_TOKEN_SUPPLY);

    uint256 private _totalSupply = INITIAL_TOKEN_SUPPLY;
    uint256 private _lastTotalSupply = INITIAL_TOKEN_SUPPLY;
    // ** added: new variable _adjustTime
    uint256 private _adjustTime = 0;
    uint256 private _lastAdjustTime = 0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _burnAmount;
    uint256[2][] private _supplyMap;

    constructor() public
    {
        _owner = msg.sender;
        
         _totalSupply = INITIAL_TOKEN_SUPPLY;
        _balances[_owner] = TOTAL_FRAGMENTS;

        _supplyMap.push([0, 100000 * 10**DECIMALS]);
        _supplyMap.push([7 * SavixSupply.SECPERDAY, 115000 * 10**DECIMALS]);
        _supplyMap.push([30 * SavixSupply.SECPERDAY, 130000 * 10**DECIMALS]);
        _supplyMap.push([6 * 30 * SavixSupply.SECPERDAY, 160000 * 10**DECIMALS]);
        _supplyMap.push([12 * 30 * SavixSupply.SECPERDAY, 185000 * 10**DECIMALS]);
        _supplyMap.push([18 * 30 * SavixSupply.SECPERDAY, 215000 * 10**DECIMALS]);
        _supplyMap.push([24 * 30 * SavixSupply.SECPERDAY, 240000 * 10**DECIMALS]);
        _supplyMap.push([48 * 30 * SavixSupply.SECPERDAY, 300000 * 10**DECIMALS]);
        // ** changed: gradient changed for slightly higher interest in far future 
        // _constGradient = SafeMath.div(INITIAL_TOKEN_SUPPLY * CONSTINTEREST, 360 * SavixSupply.SECPERDAY * 100); ** old version
        _constGradient = 8 * 10**(DECIMALS - 4);
    }
    
    modifier validRecipient(address to)
    {
        require(to != address(0) && to != address(this), "Invalid Recipient");
        _;
    }
    
    modifier onlyOwner 
    {
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    function supplyMap() external view returns (uint256[2][] memory) 
    {
        return _supplyMap;
    }

    function initialSupply() external pure returns (uint256) 
    {
        return INITIAL_TOKEN_SUPPLY;
    }

    function finalGradient() external view returns (uint) 
    {
        return _constGradient;
    }

    function lastAdjustTime() external view returns (uint) 
    {
        return _lastAdjustTime;
    }

    function lastTotalSupply() external view returns (uint) 
    {
        return _lastTotalSupply;
    }

    function startStaking() 
      external 
      onlyOwner
    {
        _stakingActive = true;
        _stakingSince = block.timestamp;
        _totalSupply = _supplyMap[0][1];
        _lastTotalSupply = _totalSupply;
        _lastAdjustTime = 0;
        // ** added: new variable _adjustTime
        _adjustTime = 0;
    }

    function name() external pure returns (string memory) 
    {
        return NAME;
    }

    function symbol() external pure returns (string memory)
    {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8)
    {
        return uint8(DECIMALS);
    }

    function stakingActive() external view returns (bool)
    {
        return _stakingActive;
    }

    function stakingSince() external view returns (uint256)
    {
        return _stakingSince;
    }

    function stakingFrequence() external pure returns (uint)
    {
        return SavixSupply.MINTIMEWIN;
    }

    
    function totalSupply() override external view returns (uint256)
    {
        // since we cannot directly decrease total supply without affecting all balances, we
        // track burned tokens and substract them here
        // we also substact burned tokens from the global burn address
        return _totalSupply - _burnAmount.div(TOTAL_FRAGMENTS.div(_totalSupply)) - balanceOf(BURNADDR);
    }

    // dailyInterest rate is given in percent with 2 decimals => result has to be divede by 10**9 to get correct number with precision 2
    function dailyInterest() external view returns (uint)
    {
            return SavixSupply.getDailyInterest(block.timestamp - _stakingSince, _lastAdjustTime, _totalSupply, _lastTotalSupply); 
    }

    // ** new method
    // yearlyInterest rate is given in percent with 2 decimals => result has to be divede by 10**9 to get correct number with precision 2
    function yearlyInterest() external view returns (uint)
    {
            return SavixSupply.getYearlyInterest(block.timestamp - _stakingSince, _lastAdjustTime, _totalSupply, _lastTotalSupply); 
    }

    function balanceOf(address account) override public view returns (uint256)
    {
        return _balances[account].div(TOTAL_FRAGMENTS.div(_totalSupply));
    }

    function _calculateFragments(uint256 value) internal returns (uint256)
    {
        if(_stakingActive && (block.timestamp - _stakingSince) - _lastAdjustTime >= SavixSupply.MINTIMEWIN)
        {
            uint256 newSupply = SavixSupply.getAdjustedSupply(_supplyMap, (block.timestamp - _stakingSince), _constGradient);
            if (_totalSupply != newSupply)
            {
              // ** changed: assignment order
              // ** added: new variable _adjustTime
              _lastAdjustTime = _adjustTime;
              _adjustTime = block.timestamp - _stakingSince;
              _lastTotalSupply = _totalSupply;
              _totalSupply = newSupply;
            }
        }
        // return value.mul(TOTAL_FRAGMENTS.div(_totalSupply));  ** old version
        // return TOTAL_FRAGMENTS.mul(value).div(_totalSupply);  ** this would be appropriate in order to multiply before division
        // But => leads to multiplication overflow due to extremly high numbers in which supply fragments are held 
        return TOTAL_FRAGMENTS.div(_totalSupply).mul(value);
    }

    function burn(uint256 value)
      external
      returns (bool)
    {
        uint256 rAmount = _calculateFragments(value);
        _balances[msg.sender] = _balances[msg.sender].sub(rAmount,"burn amount exceeds balance");
        // cannot modify totalsupply directly, otherwise all balances would decrease
        // we keep track of the burn amount and use it in the totalSupply() function to correctly
        // compute the totalsupply
        // also, burned tokens have to be stored as fragments (percentage) of the total supply
        // This means they gets affected by staking: the burned amount will automatically increase accordingly
        _burnAmount += rAmount;
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function getBurnAmount() external view returns (uint256)
    {
        return _burnAmount.div(TOTAL_FRAGMENTS.div(_totalSupply)) + balanceOf(BURNADDR);
    }

    function transfer(address to, uint256 value) override
        external
        validRecipient(to)
        returns (bool)
    {
        uint256 rAmount = _calculateFragments(value);
        _balances[msg.sender] = _balances[msg.sender].sub(rAmount,"ERC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(rAmount);
        emit Transfer(msg.sender, to, value);       
        return true;
    }

    /**
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
    function transferFrom(address sender, address recipient, uint256 value) 
        override
        external
        returns (bool)
    {
        _allowances[sender][recipient] = _allowances[sender][recipient].sub(value,"ERC20: transfer amount exceeds allowance");
        uint256 rAmount = _calculateFragments(value);
        _balances[sender] = _balances[sender].sub(rAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(rAmount);
        emit Transfer(sender, recipient, value);
        return true;
    }

    function allowance(address owner, address spender) override external view returns (uint256)
    {
        return _allowances[owner][spender];
    }

    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool)
    {
        uint256 newValue = _allowances[msg.sender][spender].add(addedValue);
        _allowances[msg.sender][spender] = 0;
        _approve(msg.sender, spender, newValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool)
    {
        uint256 newValue = _allowances[msg.sender][spender].sub(subtractedValue,"ERC20: decreased allowance below zero");
        _allowances[msg.sender][spender] = 0;
        _approve(msg.sender, spender, newValue);
        return true;
    }

    
    function approve(address spender, uint256 value) override external returns (bool) 
    {
        _allowances[msg.sender][spender] = 0;
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        // In order to exclude front-running attacks:
        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((value == 0 || _allowances[owner][spender] == 0), "possible front-running attack");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // use same logic to adjust balances as in function transfer
    // only distribute from owner wallet (ecosystem fund)
    // gas friendly way to do airdrops or giveaways
    function distributeTokens(address[] memory addresses, uint256 value)
        external
        onlyOwner
    {
        uint256 rAmount = _calculateFragments(value);
        _balances[_owner] = _balances[_owner].sub(rAmount * addresses.length,"ERC20: distribution total amount exceeds balance");
        
        uint256 addressesLength = addresses.length;
        for (uint i = 0; i < addressesLength; i++)
        {
            _balances[addresses[i]] = _balances[addresses[i]].add(rAmount);
            emit Transfer(_owner, addresses[i], value);       
        }
    }

    // use same logic to adjust balances as in function transfer
    // only distribute from owner wallet (ecosystem fund)
    // gas friendly way to do airdrops or giveaways
    function distributeTokensFlexSum(address[] memory addresses, uint256[] memory values)
        external
        onlyOwner
    {
        // there has to be exacly 1 value per address
        require(addresses.length == values.length, "there has to be exacly 1 value per address"); // Overflow check

        uint256 valuesum = 0;
        uint256 valueLength = values.length;
        for (uint i = 0; i < valueLength; i++)
            valuesum += values[i];

        _balances[_owner] = _balances[_owner].sub( _calculateFragments(valuesum),"ERC20: distribution total amount exceeds balance");

        uint256 addressesLength = addresses.length;
        for (uint i = 0; i < addressesLength; i++)
        {
            _balances[addresses[i]] = _balances[addresses[i]].add(_calculateFragments(values[i]));
            emit Transfer(_owner, addresses[i], values[i]);       
        }
    }
    
    function getOwner() 
      external
      view 
    returns(address)
    {
        return _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./SafeMath.sol";

/**
 * @dev savix interest and supply calculations.
 *
*/
 library SavixSupply {
     
    uint256 public constant MAX_UINT256 = 2**256 - 1;
    uint256 public constant MAX_UINT128 = 2**128 - 1;
    uint public constant MINTIMEWIN = 7200; // 2 hours
    uint public constant SECPERDAY = 3600 * 24;
    uint public constant DECIMALS = 9;

    struct SupplyWinBoundary 
    {
        uint256 x1;
        uint256 x2;
        uint256 y1;
        uint256 y2;
    }

    function getSupplyWindow(uint256[2][] memory map, uint256 calcTime) internal pure returns (SupplyWinBoundary memory)
    {
        SupplyWinBoundary memory winBound;
        
        winBound.x1 = 0;
        winBound.x2 = 0;

        winBound.y1 = map[0][1];
        winBound.y2 = 0;

        for (uint i=0; i < map.length; i++)
        {
            if (map[i][0] == 0) 
              continue;

            if (calcTime < map[i][0])
            {
                winBound.x2 = map[i][0];
                winBound.y2 = map[i][1];
                break;
            }
            else
            {
                winBound.x1 = map[i][0];
                winBound.y1 = map[i][1];
            }
        }
        if (winBound.x2 == 0) winBound.x2 = MAX_UINT128;
        if (winBound.y2 == 0) winBound.y2 = MAX_UINT128;
        return winBound;
    }

    // function to calculate new Supply with SafeMath for divisions only, shortest (cheapest) form
    function getAdjustedSupply(uint256[2][] memory map, uint256 transactionTime, uint constGradient) internal pure returns (uint256)
    {
        if (transactionTime >= map[map.length-1][0])
        {
            // return (map[map.length-1][1] + constGradient * (SafeMath.sub(transactionTime, map[map.length-1][0])));  ** old version
            return (map[map.length-1][1] + SafeMath.mul(constGradient, SafeMath.sub(transactionTime, map[map.length-1][0])));
        }
        
        SupplyWinBoundary memory winBound = getSupplyWindow(map, transactionTime);
        // return (winBound.y1 + SafeMath.div(winBound.y2 - winBound.y1, winBound.x2 - winBound.x1) * (transactionTime - winBound.x1));  ** old version
        return (winBound.y1 + SafeMath.div(SafeMath.mul(SafeMath.sub(winBound.y2, winBound.y1), SafeMath.sub(transactionTime, winBound.x1)), SafeMath.sub(winBound.x2, winBound.x1)));
    }

    function getDailyInterest(uint256 currentTime, uint256 lastAdjustTime, uint256 currentSupply, uint256 lastSupply) internal pure returns (uint)
    {
        if (currentTime <= lastAdjustTime)
        {
           return uint128(0);
        }

        // ** old version                
        // uint256 InterestSinceLastAdjust = SafeMath.div((currentSupply - lastSupply) * 100, lastSupply);
        // return (SafeMath.div(InterestSinceLastAdjust * SECPERDAY, currentTime - lastAdjustTime));
        return (SafeMath.div(SafeMath.sub(currentSupply, lastSupply) * 100 * 10**DECIMALS * SECPERDAY, SafeMath.mul(SafeMath.sub(currentTime, lastAdjustTime), lastSupply)));
    }
 
    // ** new method
    // yearlyInterest rate is given in percent with 2 decimals => result has to be divede by 10**9 to get correct number with precision 2
    function getYearlyInterest(uint256 currentTime, uint256 lastAdjustTime, uint256 currentSupply, uint256 lastSupply) internal pure returns (uint)
    {
        if (currentTime <= lastAdjustTime)
        {
           return uint128(0);
        }
        return (SafeMath.div(SafeMath.sub(currentSupply, lastSupply) * 100 * 10**DECIMALS * SECPERDAY * 360, SafeMath.mul(SafeMath.sub(currentTime, lastAdjustTime), lastSupply)));
    }
}