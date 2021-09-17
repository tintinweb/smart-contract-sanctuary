/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.5.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}


contract ECOSwap {
    
    using SafeMath for uint256;


    IERC20 public token;


    address payable public idoAddress;
    
    address public contractOwner;

    uint256 public step1AlreadyIDO = 0 ;
    
    uint256 public step2AlreadyIDO = 0 ;
    
    uint256 public minAmount = 1e16;
    
    uint256 public step1StartTime = 1631887200;
    uint256 public whiteFinishTime = 1631888100;
    uint256 public step1Price = 45000000;
    uint256 public step1IDOMaxAmount = 300*1e18;
    
    uint256 public step2StartTime = 1631894400;
    uint256 public step2Price = 35000000;
    uint256 public step2IDOMaxAmount = 500*1e18;
    
    uint256 public withdrawTime = 1631973600;
    
    mapping(address => bool) public whiteAddress;
    
    mapping(address => uint256) public userIDOAmount;
    

    constructor(IERC20 _token, address payable _idoAddress) public {
        
        contractOwner = msg.sender;
        token = _token;
        
        idoAddress = _idoAddress;
    }


    function setToken(IERC20 _token) public {
        require(msg.sender == contractOwner, "Must be owner");
        token = _token;
    }
    
    function setWhiteAddress(address[] memory  addrs) public {
        require(msg.sender == contractOwner, "Must be owner");
        
        uint256 i = 0;
        while (i < addrs.length) {
          
          whiteAddress[addrs[i]] = true;
          
          i += 1;
        }
    }

    function setWhiteAddress(address addrs) public {
        require(msg.sender == contractOwner, "Must be owner");
          
        whiteAddress[addrs] = true;
          
    }

    function setIDOAddress( address payable _idoAddress) public {
        require(msg.sender == contractOwner, "Must be owner");
        idoAddress = _idoAddress;
    }
     
    function setOwner(address _contractOwner) public {
        require(msg.sender == contractOwner, "Must be owner");
        contractOwner = _contractOwner;
    }
    
    
    function setMinAmount(uint256 _minAmount) public {
        require(msg.sender == contractOwner, "Must be owner");
        minAmount = _minAmount;
    }
    
    
    function setTime(uint256 _step1StartTime, uint256 _whiteFinishTime, uint256 _step2StartTime, uint256 _withdrawTime) public {
        require(msg.sender == contractOwner, "Must be owner");
        
        step1StartTime = _step1StartTime;
    
        whiteFinishTime = _whiteFinishTime;
    
        step2StartTime = _step2StartTime;
        
        withdrawTime = _withdrawTime;
    
    }
    
    function getStep() public view returns (uint256) {
        
        uint256 step = 1;
        if(block.timestamp >= step1StartTime && block.timestamp < step2StartTime) {
            step = 1;
        } else if(block.timestamp >= step2StartTime) {
            step = 2;
        }
        
        return step;
    }
    
     
    function swap() public payable {
        
        uint256 amount = msg.value ;

        require(block.timestamp >= step1StartTime, "ido no start");

        require(amount >= minAmount, "must >= minAmount");
        
        if(block.timestamp >= step1StartTime && block.timestamp < step2StartTime) {
           
           require(step1AlreadyIDO <= step1IDOMaxAmount, "step1AlreadyIDO finish");
           
           if(block.timestamp >= step1StartTime && block.timestamp < whiteFinishTime) {
                require(whiteAddress[msg.sender], "no white address");
           } 
           
           step1AlreadyIDO = step1AlreadyIDO.add(amount);
    
            uint256 idoAmount = amount.mul(step1Price).div(1e9);
            
            idoAddress.transfer(amount);
            
            userIDOAmount[msg.sender] += idoAmount;
                
        } else if(block.timestamp >= step2StartTime) {
            require(step2AlreadyIDO <= step2IDOMaxAmount, "step2AlreadyIDO finish");
            
            step2AlreadyIDO += amount;
    
            uint256 idoAmount = amount.mul(step2Price).div(1e9);
            
            idoAddress.transfer(amount);
            
            userIDOAmount[msg.sender] += idoAmount;
        }
        
        
        
    }


    function withdraw() public {
       
       require(userIDOAmount[msg.sender] > 0, "no ido amount");
       
        token.transfer(msg.sender, userIDOAmount[msg.sender]) ;
        
        userIDOAmount[msg.sender] = 0;
        
    }
    

    function withdrawAll() public {
        require(msg.sender == contractOwner, "Must be owner");
        uint256 balance = token.balanceOf(address(this)) ;
        if(balance > 0 ){
            token.transfer(msg.sender, balance) ;
        }
    }

}