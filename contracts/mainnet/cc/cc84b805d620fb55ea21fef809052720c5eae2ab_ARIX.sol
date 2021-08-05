/**
 *Submitted for verification at Etherscan.io on 2020-05-16
*/

pragma solidity >= 0.6.0;

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
    // constructor () internal { }
    // // solhint-disable-previous-line no-empty-blocks

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

contract ERC20 is Context{
    using SafeMath for uint256;

    mapping (address => uint256) _balances;
    
    mapping (address => uint256) _intactbal;
    
    mapping (address => uint256) _depositTime;
    
    uint256 _maximumcoin;
    uint256 _decimals ;
    
    uint256  _firstyearminbal ;
    uint256  _secondyearminbal ;
    uint256  _thirdyearminbal ;

    uint256  private _currentsupply;
    
    uint256 deployTime = block.timestamp;

    uint256  _1year ;
    uint256  _3month ;
    uint256 _1month ;
    uint256  _3min ;
    
    address  admin = msg.sender;
    uint256 _totaltransfered = 0;
    
    event OwnershipTransferred(address _oldAdmin, address _newAdmin);
    event MinimumBalanceforinterestchanged(uint256 _oldminyear1, uint256 _oldminyear2, uint256 _oldminyear3, uint256 _newminyear1, uint256 _newminyear2, uint256 _newminyear3 );
   
     /**
     * @dev See {IERC20-balanceOf}.
     **/

    function balanceOf(address account) public view returns (uint256) {
        return (_balances[account]);
    }
    
    function transferOwnership(address _newAdmin) public {
        require(msg.sender == admin, "Not an admin");
        admin = _newAdmin;
        emit OwnershipTransferred(msg.sender, admin);
    }
    
    function changeMinimumBalanceforinterest(uint256 y1, uint256 y2, uint256 y3) public {
        require(msg.sender == admin, "Not an admin");
        _firstyearminbal = y1;
        _secondyearminbal = y2;
        _thirdyearminbal = y3;
        
        emit MinimumBalanceforinterestchanged(y1, y2, y3, _firstyearminbal, _secondyearminbal, _thirdyearminbal);
    }

    function viewMinimumBalanceforinterest() public view returns (uint256, uint256, uint256){
        return (_firstyearminbal,_secondyearminbal,_thirdyearminbal );
    }
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer( uint256 amount, address recipient) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        if(_depositTime[recipient] == 0)
        _depositTime[recipient] = block.timestamp;
        emit Transfer (sender, recipient, amount);
    }

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed frm, address indexed to, uint256 value);

    event InterestTransfer(address indexed to, uint256 value, uint256 transferTime);

}


contract Interest is Context, ERC20 {
    
    using SafeMath for uint256;
    
    //cron this function daily after 3 months of deployment of contract upto 3 years
    
     function multiInterestUpdate(address[] memory _contributors)public  returns (bool) { 
         require(msg.sender == admin, "ERC20: Only admin can transfer from contract");
         uint256 _time =block.timestamp.sub(deployTime);
         require(_time >= _3month.add(_1month), "ERC20: Only after 4 months of deployment of contract" );
    
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
        
                address  user = _contributors[i];
                 uint256 _deposittime =block.timestamp.sub(_depositTime[user]);
                 
                 if(_time <= _1year){           //less than 1 year
                 
                     if((_balances[ user] >= _firstyearminbal) && (_deposittime > _3month) && (_intactbal[user] == 0))
                     _intactbal[user] = _intactbal[user].add((_balances[user]*3)/(100));
                
                 }
                 else if(_time <= (_1year*2)){  //less than 2 year
                        
                     if(_balances[ user] >= _secondyearminbal && (_deposittime > _1month*2) && (_intactbal[user] == 0))
                      _intactbal[user] = _intactbal[user].add((_balances[ user]*15)/(1000));
                 }
                 else if(_time <= (_1year*3)){  //less than 3 year
                 
                     if(_balances[user] >= _thirdyearminbal  && (_deposittime > _1month) && (_intactbal[user] == 0))
                     _intactbal[user] = _intactbal[user].add((_balances[ user])/(100));
                 }
         
            }
         

    return (true);
    }
    
    
    //cron this function monthly after 4 months of deployment of contract upto 3 years
    
     function multiInterestCredit( address[] memory _contributors) public returns(uint256) {
       require(msg.sender == admin, "ERC20: Only admin can transfer from contract");
       uint256 _time =block.timestamp.sub(deployTime);
         require(_time >= _3month.add(_1month), "ERC20: Only after 4 months of deployment of contract" );
       
            uint256 monthtotal = 0;
            
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                _transfer(address(this), _contributors[i], _intactbal[_contributors[i]]);
                 emit InterestTransfer (_contributors[i], _intactbal[_contributors[i]], block.timestamp);
                _totaltransfered = _totaltransfered.add(_intactbal[_contributors[i]]);
                _intactbal[_contributors[i]] = 0;
                monthtotal += _intactbal[_contributors[i]];
                
            }
            
        return (monthtotal);
    }
    
}


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint256 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint256 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint256) {
        return _decimals;
    }
}

contract ARIX is ERC20, ERC20Detailed, Interest{
    
        constructor(
        uint256   maximumcoin,
        uint32 secondsforoneyear,
        uint32 secondsforthreemonths,
        uint32 secondsforonemonth,
        uint32 secondsforthreeminute ,
        uint256 minimumbalanceforfirstyearinterest,
        uint256 minimumbalanceforsecondyearinterest,
        uint256 minimumbalanceforthirdyearinterest,
        string memory name, 
        string memory symbol, 
        uint256 decimals 
        )public ERC20Detailed(name, symbol, decimals) {

            _balances[address(this)] = maximumcoin;
            _maximumcoin = maximumcoin;
            _decimals = 10**decimals;
            _1year = secondsforoneyear;
            _3month = secondsforthreemonths;
            _1month = secondsforonemonth;
            _3min = secondsforthreeminute;
            _firstyearminbal = minimumbalanceforfirstyearinterest;
            _secondyearminbal = minimumbalanceforsecondyearinterest;
            _thirdyearminbal = minimumbalanceforthirdyearinterest;
   }
   using SafeMath for uint256;
   
    function totalSupply() public view returns (uint256) {
         
        uint256 _1yearcoin = (_1year/_3min)*100*_decimals;
        uint256 _2yearcoin = _1yearcoin.add((_1year/_3min)*50*_decimals);
        uint256 _3yearcoin = _2yearcoin.add((_1year/_3min)*25*_decimals);
        uint256 _4yearcoin = _3yearcoin.add(((_1year/_3min)*125*_decimals)/10);
        uint256 _5yearcoin = _4yearcoin.add(((_1year/_3min)*625*_decimals)/100);
        
        uint256 _elapsetime = block.timestamp.sub(deployTime);

        if(_elapsetime <=_1year){      
            if((_elapsetime/_3min)*100*_decimals < _maximumcoin)
                return ((_elapsetime/_3min)*100*_decimals);
            else
            return(_maximumcoin);
        
        
        }else if(_elapsetime <=(_1year*2)){
            if(_1yearcoin.add(((_elapsetime.sub(_1year))/_3min)*50*_decimals) < _maximumcoin)
                return (_1yearcoin.add(((_elapsetime.sub(_1year))/_3min)*50*_decimals));
            else
            return(_maximumcoin);
        
        
        }else if(_elapsetime <=(_1year*3)){
            if(_2yearcoin.add(((_elapsetime.sub(_1year*2))/_3min)*25*_decimals) < _maximumcoin)
                return (_2yearcoin.add(((_elapsetime.sub(_1year*2))/_3min)*25*_decimals));
            else
            return(_maximumcoin);
        
        
        }else if(_elapsetime <=(_1year*4)){
            if(_3yearcoin.add((((_elapsetime.sub(_1year*3))/_3min)*125*_decimals)/10) < _maximumcoin)
                return (_3yearcoin.add((((_elapsetime.sub(_1year*3))/_3min)*125*_decimals)/10));
            else
            return(_maximumcoin);
        
        
        }else if(_elapsetime <=(_1year*5)){
            if(_4yearcoin.add((((_elapsetime.sub(_1year*4))/_3min)*625*_decimals)/100) < _maximumcoin)
                return (_4yearcoin.add((((_elapsetime.sub(_1year*4))/_3min)*625*_decimals)/100));
            else
            return(_maximumcoin);
     
        
        }else if(_elapsetime > (_1year*5)){
            if(_5yearcoin.add((((_elapsetime.sub(_1year*5))/_3min)*3125*_decimals)/1000) < _maximumcoin)
                return (_5yearcoin.add((((_elapsetime.sub(_1year*5))/_3min)*3125*_decimals)/1000));
            else
            return(_maximumcoin);
        }
       
    }
   
   
   function admintransfer(uint256 amount, address recipient) public returns (uint256) {
           require(msg.sender == admin, "ERC20: Only admin can transfer from contract");
           require(amount <= totalSupply(), "ERC20: Only less than total released can be tranfered");
           require(amount <= totalSupply().sub(_totaltransfered), "Only less than total suppliable coin");
           
        _transfer(address(this), recipient, amount);
        _totaltransfered = _totaltransfered.add(amount);
        return(_balances[recipient]);
    }
   
}