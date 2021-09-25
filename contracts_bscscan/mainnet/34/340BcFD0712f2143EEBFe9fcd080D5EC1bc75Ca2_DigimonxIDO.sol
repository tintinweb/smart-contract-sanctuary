/**
 *Submitted for verification at BscScan.com on 2021-09-25
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


contract DigimonxIDO {
    
    using SafeMath for uint256;



    IERC20 public token;


    address payable public walletAddress;
    
    address public owner;

    uint256 public alreadyBnbIdoAmount = 0 ;
    

    
    uint256 public minAmount = 2e16;
    uint256 public roundOneMaxAmount = 2e18;
    uint256 public roundTwoMaxAmount= 3e18;
    
    
    uint256 public roundOneStartTime = 1632668400;
    uint256 public whiteListFinishTime = 1632668700;
    uint256 public roundOnePrice = 50000000;
    
    uint256 public roundTwoStartTime = 1632669000;
    uint256 public roundTwoPrice = 45000000;
    
    uint256 public totalBnbIdoMaxAmount = 200*1e18;
    uint256 public withdrawTime = 1633100400;
    
    mapping(address => bool) public whiteAddress;
    
    mapping(address => uint256) public userBnbIdoAmount;
    


    mapping(address => uint256) public userTokenIdoAmount;
    

    constructor(IERC20 _token, address payable _walletAddress) public {
        
        owner = msg.sender;
        token = _token;
        walletAddress = _walletAddress;
    }


    function setToken(IERC20 _token) public {
        require(msg.sender == owner, "Caller is not the owner");
        token = _token;
    }
    
    function setWhiteAddress(address[] memory  addrs) public {
        require(msg.sender == owner, "Caller is not the owner");
        
        uint256 i = 0;
        while (i < addrs.length) {
          
          whiteAddress[addrs[i]] = true;
          
          i += 1;
        }
    }

    function setWhiteAddress(address addrs) public {
        require(msg.sender == owner, "Caller is not the owner");
          
        whiteAddress[addrs] = true;
          
    }

    function setWalletAddress( address payable _walletAddress) public {
        require(msg.sender == owner, "Caller is not the owner");
        walletAddress = _walletAddress;
    }
     
    function setOwner(address _owner) public {
        require(msg.sender == owner, "Caller is not the owner");
        owner = _owner;
    }
    
    
    function setMinAmount(uint256 _minAmount) public {
        require(msg.sender == owner, "Caller is not the owner");
        minAmount = _minAmount;
    }
    
    
    function setTime(uint256 _roundOneStartTime, uint256 _whiteListFinishTime, uint256 _roundTwoStartTime, uint256 _withdrawTime) public {
        require(msg.sender == owner, "Caller is not the owner");
        
        roundOneStartTime = _roundOneStartTime;
    
        whiteListFinishTime = _whiteListFinishTime;
    
        roundTwoStartTime = _roundTwoStartTime;
        
        withdrawTime = _withdrawTime;
    
    }
    
    function getRound() public view returns (uint256) {
        
        uint256 round = 0;
        
        if(block.timestamp >= roundOneStartTime && block.timestamp < roundTwoStartTime) {
            round = 1;
        } else if(block.timestamp >= roundTwoStartTime) {
            round = 2;
        }
        
        return round;
    }
    
     
    function swap() public payable {
        
        uint256 bnbAmount = msg.value ;

        require(block.timestamp >= roundOneStartTime, "swap : ido dont begin");

        require(userBnbIdoAmount[msg.sender] +bnbAmount >= minAmount, "swap : contributed bnbAmount must greater Or Equal To MinAmount");
        
        require(userBnbIdoAmount[msg.sender] + bnbAmount <= roundTwoMaxAmount, "swap : contributed bnbAmount must Less than or equal to roundTwoMaxAmount");
        
        if(block.timestamp >= roundOneStartTime && block.timestamp < roundTwoStartTime) {
            
           require(alreadyBnbIdoAmount <= totalBnbIdoMaxAmount, "swap : exceeded the totalBnbIdoMaxAmount");
            
           require(userBnbIdoAmount[msg.sender] + bnbAmount <= roundOneMaxAmount, "swap : contributed bnbAmount must Less than or equal to maxAmountRoundOne");
           

           
           if(block.timestamp >= roundOneStartTime && block.timestamp < whiteListFinishTime) {
                require(whiteAddress[msg.sender], "swap : not whitelist address");
           } 
           
            alreadyBnbIdoAmount = alreadyBnbIdoAmount.add(bnbAmount);
    
            uint256 tokenAmount = bnbAmount.mul(roundOnePrice).div(1e9);
            
            walletAddress.transfer(bnbAmount);
            
            userBnbIdoAmount[msg.sender] += bnbAmount;
            userTokenIdoAmount[msg.sender] += tokenAmount;
                
        } else if(block.timestamp >= roundTwoStartTime) {
            require(alreadyBnbIdoAmount + bnbAmount <= totalBnbIdoMaxAmount, "swap : exceeded the totalBnbIdoMaxAmount");
            
            alreadyBnbIdoAmount += bnbAmount;
    
            uint256 tokenAmount = bnbAmount.mul(roundTwoPrice).div(1e9);
            
            walletAddress.transfer(bnbAmount);
            
            userBnbIdoAmount[msg.sender] += bnbAmount;
            userTokenIdoAmount[msg.sender] += tokenAmount;
        }
        
    }


    function withdraw() public {
       require(block.timestamp >= withdrawTime, "withdraw : withdraw dont start");
       require(userTokenIdoAmount[msg.sender] > 0, "withdraw : userTokenIdoAmount is zero");
       token.transfer(msg.sender, userTokenIdoAmount[msg.sender]) ;
       userTokenIdoAmount[msg.sender] = 0;
    }
    
    


    function withdrawAll() public {
        require(msg.sender == owner, "withdrawAll : caller is not the owner");
        
        uint256 balance = token.balanceOf(address(this)) ;
        if(balance > 0 ){
            token.transfer(msg.sender, balance) ;
        }
    }

}