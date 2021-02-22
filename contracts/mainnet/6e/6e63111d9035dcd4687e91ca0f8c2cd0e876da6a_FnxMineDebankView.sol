/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

pragma solidity =0.5.16;



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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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

contract Storage {
    
    address public fnxColPool = 0xfDf252995da6D6c54C03FC993e7AA6B593A57B8d; 
    address public usdcColPool = 0x120f18F5B8EdCaA3c083F9464c57C11D81a9E549;
    
    //fnxColPool inclue fnx token
    address public fnxToken = 0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B;
    
    //usdccolpool inclue usdc and usdt
    address public usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    address public cfnxToken = 0x9d7beb4265817a4923FAD9Ca9EF8af138499615d;
    address public fnxOracle = 0x43BD92bF3Bb25EBB3BdC2524CBd6156E3Fdd41F3;
    address public fixedMinePool = 0xf1FF936B72499382983a8fBa9985C41cB80BE17D;

    
    address public temp1 =  address(0x0);
    address public temp2 =  address(0x0);
    address public temp3 =  address(0x0);
    
}


interface IFixedMinePool {
     function getUserCurrentAPY(address account,address mineCoin) external view returns (uint256);
     function getUserFPTBBalance(address account) external view returns (uint256);
     function getUserFPTABalance(address account) external view returns (uint256);
     function getMinerBalance(address account,address mineCoin) external view returns(uint256);
}

interface IFnxOracle {
     function getPrice(address asset) external view returns (uint256);
}

interface ICollateralPool {
     function getTokenNetworth() external view returns (uint256);
     function userInputCollateral(address user,address collateral) external view returns (uint256);
     function getUserPayingUsd(address account) external view returns (uint256);

}

interface IMineConverter {
     function lockedBalanceOf(address account) external view returns (uint256);
}

contract FnxMineDebankView is Storage,Ownable {
    
    using SafeMath for uint256;

    function getMinedUnclaimedBalance(address _user) public view returns (uint256) {
        return IFixedMinePool(fixedMinePool).getMinerBalance(_user,cfnxToken);
    }

    function getConverterLockedBalance(address _user) public view returns (uint256) {
        return IMineConverter(cfnxToken).lockedBalanceOf(_user);
    }

    
    function getApy(address _user) public view returns (uint256) {
            uint256 mineofyear = IFixedMinePool(fixedMinePool).getUserCurrentAPY(_user,cfnxToken);
            
            uint256 FTPA = IFixedMinePool(fixedMinePool).getUserFPTABalance(_user);
            uint256 FTPB = IFixedMinePool(fixedMinePool).getUserFPTBBalance(_user);
            uint256 fnxprice =  IFnxOracle(fnxOracle).getPrice(fnxToken);
            uint256 fptaprice = ICollateralPool(usdcColPool).getTokenNetworth();
            uint256 fptbprice = ICollateralPool(fnxColPool).getTokenNetworth();

            uint256 denominater = (FTPA.mul(fptaprice)).add(FTPB.mul(fptbprice));
            
            if(denominater==0) {
               return 0;
            }
            
            return mineofyear.mul(fnxprice).mul(1000).div(denominater);
    }
    
    
    function getFnxPoolColValue(address _user) public view returns (uint256) {
       return ICollateralPool(fnxColPool).getUserPayingUsd(_user);
    }


    function getUsdcPoolColValue(address _user)  public view returns (uint256) {
        return ICollateralPool(usdcColPool).getUserPayingUsd(_user);
    }
    
    /**
     * @dev Retrieve user's locked balance. 
     * @param _user account.
     * @param _collateral the collateal token address
     * @param _pool the collateal pool     
     */
    function getUserInputCollateral(address _user,address _collateral,address _pool) public view returns (uint256){
      return ICollateralPool(_pool).userInputCollateral(_user,_collateral);   
    }
    
    function getVersion() public pure returns (uint256)  {
        return 1;
    }
    

    function resetTokenAddress( 
                                address _fnxColPool, 
                                address _usdcColPool, 
                                address _fnxToken,   
                                address _usdcToken, 
                                address _usdtToken,
                                address _cfnxToken,
                                address _fnxOracle,
                                address _fixedMinePool
                                
                              )  public onlyOwner {
                                  
        fnxColPool  = _fnxColPool;
        usdcColPool = _usdcColPool;
        fnxToken    = _fnxToken; 
        usdcToken   = _usdcToken;
        usdtToken   = _usdtToken;
        cfnxToken   = _cfnxToken;
        fnxOracle    = _fnxOracle;
        fixedMinePool = _fixedMinePool;
    }
    
    
}