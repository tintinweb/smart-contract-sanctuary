//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
 

contract ERC20 is IERC20 {
    
   
    using SafeMath for uint256;   
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalBurnAmount;  

    uint256 private MAX_STOP_FEE_TOTAL; 

    mapping(address => bool) private fromWhiteList ;

    mapping(address => bool) private toWhiteList ;

    address private superAdmin;

    mapping(address => bool) private pairsAddress ;

    mapping(address => address) private admin;
 
    modifier onlySuper {
        require(msg.sender == superAdmin,'require onwer');
        _;
    }

    
  
    function totalBurn() public view returns (uint256) {
        return _totalBurnAmount;
    }

    function getAmount( uint256 _amount ) public pure returns (uint256) {
        return _amount.div(1000000000000000000);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {

        if(recipient==address(0)){  
            _balances[sender] = _balances[sender].sub(amount);  
            _balances[recipient] = _balances[recipient].add(amount);
            _totalSupply = _totalSupply.sub(amount);           
            _totalBurnAmount = _totalBurnAmount.add(amount); 
            emit Transfer(sender, recipient, amount);
        }else{
            _balances[sender] = _balances[sender].sub(amount);
           
            if(_totalSupply>=MAX_STOP_FEE_TOTAL){

                if(gussPairsAddress(sender)){
                    _balances[recipient] = _balances[recipient].add(amount);
                    emit Transfer(sender, recipient, amount);
                }

                if(gussPairsAddress(recipient)){
                     uint256 burnCount=amount.div(100).mul(15);
                    _balances[recipient] = _balances[recipient].add(amount.sub(burnCount));
                    emit Transfer(sender, address(0), burnCount);
                    _totalSupply = _totalSupply.sub(burnCount);           
                    _totalBurnAmount = _totalBurnAmount.add(burnCount); 
                    emit Transfer(sender, recipient, amount.sub(burnCount));
                }
                if(!gussPairsAddress(sender)&&!gussPairsAddress(recipient)){
                    if(gussFromWhite(sender)||gussToWhite(recipient)){ 
                        _balances[recipient] = _balances[recipient].add(amount);
                        emit Transfer(sender, recipient, amount);
                    }else{
                        uint256 burnCount=amount.div(100).mul(15);
                        _balances[recipient] = _balances[recipient].add(amount.sub(burnCount));
                        emit Transfer(sender, address(0), burnCount);
                        _totalSupply = _totalSupply.sub(burnCount);           
                        _totalBurnAmount = _totalBurnAmount.add(burnCount); 
                        emit Transfer(sender, recipient, amount.sub(burnCount));
                     }
                }
                
            }else{
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
            }
            
        }
    }
    function approveFromWhite(address _whiteAddress ) public onlySuper returns (bool success) {
        fromWhiteList[_whiteAddress] = true;
        return true;
    }


    function cancelFromWhite(address _whiteAddress ) public onlySuper returns (bool success) {
        fromWhiteList[_whiteAddress] = false;
        return true;
    }

    function gussFromWhite(address _whiteAddress ) public onlySuper returns (bool success) {
        if(fromWhiteList[_whiteAddress]){
            return true;
        }else{
            return false;
        }
    
    }

    function approveToWhite(address _whiteAddress ) public onlySuper returns (bool success) {
        toWhiteList[_whiteAddress] = true;
        return true;
    }

    function setPairsAddress(address _pairsAddress ) public onlySuper returns (bool success) {
        pairsAddress[_pairsAddress] = true;
        return true;
    }

    function gussPairsAddress(address _pairsAddress ) public onlySuper returns (bool success) {
        if(pairsAddress[_pairsAddress]){
            return true;
        }else{
            return false;
        }
    
    }
    function setPairsAddress() public onlySuper returns (address pairsAddress) {
        return pairsAddress;
    }
    function cancelToWhite(address _whiteAddress ) public onlySuper returns (bool success) {
        toWhiteList[_whiteAddress] = false;
        return true;
    }

    function gussToWhite(address _whiteAddress ) public onlySuper returns (bool success) {
        if(toWhiteList[_whiteAddress]){
            return true;
        }else{
            return false;
        }
    
    }
    function setMaxStopFeeTotal(uint256 total) public onlySuper returns (bool success) {
        MAX_STOP_FEE_TOTAL = total;
        return true;
    }

    function getMaxStopFeeTotal() public view returns (uint256) {
        return MAX_STOP_FEE_TOTAL;
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        superAdmin = account;  
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
 
   
    IERC20 usdt;
    
    function initContract( IERC20 _addr  ) public onlySuper returns (bool) {
        usdt = _addr ;
        return true;
    }
    
    function transferContract(address recipient, uint256 amount) public onlySuper returns (bool) {
        usdt.transfer(recipient, amount);
        return true;
    }
    
    
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

 
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


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: TESTBBB.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract TESTBBB is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("TESTBBB", "TESTBBB", 18) {
        _mint(msg.sender, 10000 * 10000 * 1000000000000000000 );
    }
}