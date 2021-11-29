//SourceUnit: IERC20.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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


//SourceUnit: MIPToken.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract MIPToken is IERC20, ReentrancyGuard
{
    using SafeMath for uint256;
    address _owner;
    address _minerpool;
    uint256 _maxSupply= 1000 * 1e8;

    string constant  _name = 'MIP';
    string constant _symbol = 'MIP';
    uint8 immutable _decimals = 8;
 
    address _pancakeAddress;
    // uint256 _totalsupply;  
    
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private constant RATELIMIT_DELAY = 3;
    mapping(address => uint256) private _ratelimit;
    mapping(address => bool) private _allowTradeUser;
    mapping(address=>bool) _isExcluded;
    address[] private _excluded;
    
    mapping(address=>bool) _minter;
    mapping(address=>bool) _banneduser;
    
    uint256 _maxlimit = 100 * 1e8;
    uint256 _timeslimit = 10  * 1e8;
    bool _takeout = true;
    bool _takebonus = true;
    bool private _hasLaunched = false;
    
    uint256 private constant MAX = ~uint256(0); // 8800000000 * 1e8;
    uint256 private _tTotal = _maxSupply;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
  
    constructor()
    {
        _owner = msg.sender;
        
        _rOwned[_owner] = _rTotal;
        emit Transfer(address(0), _owner, _tTotal);

        addExcluded(_owner);
        addExcluded(address(0));
        
        setAllowTradeUser(_owner, true);
        
    }

    function launch() public {
        require(msg.sender==_owner);
        require(!_hasLaunched, "Already launched.");
        _hasLaunched = true;
    }
    
    function setMinerPool(address minerpool) public
    {
         require(msg.sender==_owner);
         _minerpool = minerpool;
         addExcluded(_minerpool);
    }
    
    function setAllowTradeUser(address account, bool isAllowed) public {
        require(msg.sender==_owner);
        _allowTradeUser[account] = isAllowed;
    }
    
    function isAllowTradeUser(address account) public view returns (bool) {
        return _allowTradeUser[account];
    }
    
    function setLimit(uint256 maxlimit,uint256 timeslimit) public
    {
         require(msg.sender==_owner);
         _maxlimit  = maxlimit;
         _timeslimit= timeslimit;
    }
    
    function setTakeout(bool takeout) public 
    {
        require(msg.sender==_owner);
        _takeout = takeout;
    }

    function bannUser(address user,bool ban) public
    {
         require(msg.sender==_owner);
         _banneduser[user]=ban;
    }
    
    function isBannedUser(address account) public view returns (bool) {
        return _banneduser[account];
    }

    function setPancakeAddress(address pancakeAddress) public
    {
        require(msg.sender==_owner);
        _pancakeAddress=pancakeAddress;
        addExcluded(_pancakeAddress);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        
        if(!_takebonus) {
            return;
        }
        
        if(_rTotal.sub(rFee) < _tTotal) {
            _rOwned[address(0)] = _rOwned[address(0)].add(rFee);
            _tOwned[address(0)] = _tOwned[address(0)].add(tFee);
            return;
        }
        
        uint256 tSupply = _getTCurrentSupply();
        if(tSupply == tFee) {
            _rOwned[address(0)] = _rOwned[address(0)].add(rFee);
            _tOwned[address(0)] = _tOwned[address(0)].add(tFee);
            return;
        }
        
        _rTotal = _rTotal.sub(rFee, "reflect fee");
        
    }
    
    function getRate() public view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]], "sub rSupply");
            tSupply = tSupply.sub(_tOwned[_excluded[i]], "sub tSupply");
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _getTCurrentSupply() private view returns(uint256) {
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        return tSupply;
    }
    
    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return rAmount.div(getRate());
    }

    function name() public  pure returns (string memory) {
        return _name;
    }

    function symbol() public  pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function addExcluded(address account) public 
    {
        require(msg.sender== _owner);
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function takeOutErrorTransfer(address tokenaddress) public
    {
        require(msg.sender==_owner);
        IERC20(tokenaddress).transfer(_owner, IERC20(tokenaddress).balanceOf(address(this)));
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

   function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burnFrom(address sender, uint256 amount) public returns (bool)
    {
         _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _burn(sender, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool)
    {
        _burn(msg.sender,amount);
        return true;
    }
 
    function _burn(address sender,uint256 tAmount) private
    {
         require(sender != address(0), "ERC20: transfer from the zero address");
         require(tAmount > 0, "Transfer amount must be greater than zero");
         
         uint256 currentRate = getRate();
         uint256 rAmount = tAmount.mul(currentRate);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _rOwned[address(0)] = _rOwned[address(0)].add(rAmount); 
         
         if(isExcluded(sender)) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
         }
         if(isExcluded(address(0))) {
            _tOwned[address(0)] = _tOwned[address(0)].add(tAmount); 
         }
        
         emit Transfer(sender, address(0), tAmount);
    }


    function _transfer(address sender, address recipient, uint256 tAmount) private nonReentrant {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_banneduser[sender] == false, "banned");
       
        uint256 currentRate = getRate();
        uint256 tTransferAmount = tAmount;
        uint256 rBonus = 0;
        uint256 tBonus = 0;
        
        if(sender == _pancakeAddress) {
            
            if(!isExcluded(recipient))
            {
                uint256 onepercent = tAmount.mul(1).div(100);
                if(onepercent > 0)
                {
                    uint256 tBurn = onepercent.mul(3);
                    tBonus = onepercent.mul(2);
                    uint256 tBack = onepercent.mul(3);
                    
                    _takeTax(tBurn, 0);
                    
                    emit Transfer(sender, address(0), tBurn);
                    emit Transfer(sender, address(0), tBonus);
                    
                    uint256 tFee = tBurn.add(tBonus).add(tBack);
                    tTransferAmount = tTransferAmount.sub(tFee);
                }
            }
            
        }
        
        if(recipient == _pancakeAddress) {
            
            if(!isAllowTradeUser(sender)) {
                require(tAmount <= _maxlimit, "ERC20: transfer amount unit limit");
                require(tAmount.mod(_timeslimit) == 0, "ERC20: transfer amount times limit");
                require(_takeout, "takeout error");
                
                require(block.number >= _ratelimit[sender], "Too many transactions, try again in a couple of blocks.");
                _ratelimit[sender] = block.number + RATELIMIT_DELAY;
            }
            
            if(!isExcluded(sender))
            {
                uint256 onepercent = tAmount.mul(1).div(100);
                if(onepercent > 0)
                {
                    uint256 tBurn = onepercent.mul(5);
                    uint256 tMinerPool = onepercent.mul(5);

                    _takeTax(tBurn, tMinerPool);
                    

                    emit Transfer(sender, address(0), tBurn);
                    emit Transfer(sender, _minerpool, tMinerPool);

                    uint256 tFee = tBurn.add(tMinerPool);
                    tTransferAmount = tTransferAmount.sub(tFee);
                }
            }
            
        }
        
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        
        _rOwned[sender]= _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        if(_isExcluded[sender]) {
            _tOwned[sender]= _tOwned[sender].sub(tAmount);
        }
        
        if(_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        
        rBonus = tBonus.mul(currentRate);
        _reflectFee(rBonus, tBonus);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTax(uint256 tBurn, uint256 tMinerPool) private {
        
        uint256 currentRate =  getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rMinerPool = tMinerPool.mul(currentRate);
        
        _rOwned[address(0)] = _rOwned[address(0)].add(rBurn);
        if(_isExcluded[address(0)]) {
            _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
        }
        
        _rOwned[_minerpool] = _rOwned[_minerpool].add(rMinerPool);
        if (_isExcluded[_minerpool]) {
            _tOwned[_minerpool] = _tOwned[_minerpool].add(tMinerPool);
        }
        
    }
    
}

//SourceUnit: ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}