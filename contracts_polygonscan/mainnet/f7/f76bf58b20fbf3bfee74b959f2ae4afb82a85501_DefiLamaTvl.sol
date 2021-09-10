/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

// File: contracts/Math.sol

pragma solidity ^0.5.0;

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

// File: contracts/SafeMath.sol

pragma solidity ^0.5.16;

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

// File: contracts/IERC20.sol

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {

    function decimals() external view returns (uint256);

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

// File: contracts/Ownable.sol

pragma solidity =0.5.16;

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

// File: contracts/Halt.sol

pragma solidity =0.5.16;


contract Halt is Ownable {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        public 
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts/DefiLamaTvl.sol

pragma solidity ^0.5.16;





interface IOptionFactory {
    function getOptionsMangerLength()external view returns (uint256);
    function getOptionsMangerAddress(uint256 index) external view returns (address,address,address,address);
    function vestingPool() external view returns (address);
    function phxOracle() external view returns (address);
}

interface IOptionManager {
    function getCollateralWhiteList() external view returns(address[] memory);
}

interface ILeverageFactory {
    function vestingPool() external view returns (address);
    function phxOracle() external view returns (address);
    function getAllStakePool()external view returns (address payable[] memory);
    function getAllLeveragePool()external view returns (address payable[] memory);
}

interface ILeverSakePool {
    function poolToken()external view returns (address);
}

interface ILeverPool {
    function getLeverageInfo() external view returns (address,address,address,uint256,uint256);
    function getHedgeInfo() external view returns (address,address,address,uint256,uint256);
    function getTotalworths() external view returns(uint256,uint256);
}

interface IOracle {
    function getPrice(address asset) external view returns (uint256);
}

contract DefiLamaTvl {
    using SafeMath for uint256;
    address public leverFactoryAddress;
    address public optionFactoryAddress;
    address public phxAddress;
    uint256 constant TLVMUL = 10**2;

    constructor(address _leverFactoryAddress,
                address _optionFactoryAddress,
                address _phxAddress) public {
        leverFactoryAddress = _leverFactoryAddress;
        optionFactoryAddress = _optionFactoryAddress;
        phxAddress = _phxAddress;
    }

    function getPriceTokenDecimal(address token) internal view returns(uint256){
        uint256 decimal = 10**18;
        if(token!=address(0)) {
            decimal = (10**IERC20(token).decimals());
        }
        return (uint256(10**18).div(decimal).mul(10**8)).mul(decimal).div(TLVMUL);
    }

    function getLeverStakePoolTvl()
        public
        view
        returns (uint256)
    {
        uint256 tvl = 0;
        address phxOracle = ILeverageFactory(leverFactoryAddress).phxOracle();
        address payable[] memory stakepools = ILeverageFactory(leverFactoryAddress).getAllStakePool();

        for(uint256 i=0;i<stakepools.length;i++) {
            address token = ILeverSakePool(stakepools[i]).poolToken();
            uint256 tokenPrice = IOracle(phxOracle).getPrice(token);
            uint256 tokenAmount = stakepools[i].balance;
            if(token!=address(0)) {
                tokenAmount = IERC20(token).balanceOf(stakepools[i]);
            }
            uint256 decimal = getPriceTokenDecimal(token);
            tvl = tvl.add(tokenAmount.mul(tokenPrice).div(decimal));
        }

        return tvl;
    }

    function getLeverPoolTvl()
        public
        view
        returns (uint256,uint256)
    {
        uint256 tvl = 0;
        address payable[] memory leverpools = ILeverageFactory(leverFactoryAddress).getAllLeveragePool();
        address phxOracle = ILeverageFactory(leverFactoryAddress).phxOracle();

        for(uint256 i=0;i<leverpools.length;i++) {
          
            address levertoken;
            address hedgetoken;
            (levertoken,,,,) = ILeverPool(leverpools[i]).getLeverageInfo();
            (hedgetoken,,,,) = ILeverPool(leverpools[i]).getHedgeInfo();

            uint256 leverTvl = IERC20(levertoken).balanceOf(leverpools[i]);
            uint256 price = IOracle(phxOracle).getPrice(levertoken);
            leverTvl = leverTvl.mul(price);
            uint256 leverdecimal = getPriceTokenDecimal(levertoken);
             tvl = tvl.add(leverTvl.div(leverdecimal));
            
            uint256 hedgeTvl = leverpools[i].balance;
            
            if(leverpools[i]!=address(0)) {
               hedgeTvl = IERC20(hedgetoken).balanceOf(leverpools[i]);
            }
           
            price = IOracle(phxOracle).getPrice(hedgetoken);
            hedgeTvl = hedgeTvl.mul(price);
            uint256 hedgedecimal = getPriceTokenDecimal(hedgetoken);
            tvl = tvl.add(hedgeTvl.div(hedgedecimal));
            
        }

        return (tvl,leverpools.length);
    }

    function getPhxVestPoolTvl()
        public
        view
        returns (uint256)
    {
        address phxVestingPool = IOptionFactory(optionFactoryAddress).vestingPool();
        uint256 phxAmount = IERC20(phxAddress).balanceOf(phxVestingPool);
        address phxOracle = IOptionFactory(optionFactoryAddress).phxOracle();
        uint256 phxprice = IOracle(phxOracle).getPrice(phxAddress);
        uint256 decimal = getPriceTokenDecimal(phxAddress);
        return phxAmount.mul(phxprice).div(decimal);
    }

    function getOptionPoolTvl()
        public
        view
        returns (uint256)
    {
        uint256 len = IOptionFactory(optionFactoryAddress).getOptionsMangerLength();
        uint256 coltvl = 0;
        address phxOracle = IOptionFactory(optionFactoryAddress).phxOracle();
        for(uint256 i=0;i<len;i++) {
            address optionsManager;
            address collateral;
            (optionsManager,collateral,,) =  IOptionFactory(optionFactoryAddress).getOptionsMangerAddress(i);

            address[] memory tokens = IOptionManager(optionsManager).getCollateralWhiteList();
            for(uint256 j=0;j<tokens.length;j++) {
                uint256 amount = IERC20(tokens[j]).balanceOf(collateral);
                uint256 tkprice = IOracle(phxOracle).getPrice(tokens[i]);
                uint256 decimal = getPriceTokenDecimal(tokens[i]);
                coltvl=coltvl.add(amount.mul(tkprice).div(decimal));
            }
        }

        return coltvl;
    }

    function getTvl()
        public
        view
        returns (uint256)
    {
        uint256 leverstakepooltvl = getLeverStakePoolTvl();
        uint256 leverpooltvl;
        (leverpooltvl,) = getLeverPoolTvl();
        uint256 phxvestpooltvl = getPhxVestPoolTvl();
        uint256 optioncoltvl = getOptionPoolTvl();
        return leverstakepooltvl.add(leverpooltvl).add(phxvestpooltvl).add(optioncoltvl);
    }

}