/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

// library SafeMath {
//   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//     if (a == 0) {
//       return 0;
//     }
//     uint256 c = a * b;
//     assert(c / a == b);
//     return c;
//   }

//   function div(uint256 a, uint256 b) internal pure returns (uint256) {
//     // assert(b > 0); // Solidity automatically throws when dividing by 0
//     uint256 c = a / b;
//     // assert(a == b * c + a % b); // There is no case in which this doesn't hold
//     return c;
//   }

//   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//     assert(b <= a);
//     return a - b;
//   }

//   function add(uint256 a, uint256 b) internal pure returns (uint256) {
//     uint256 c = a + b;
//     assert(c >= a);
//     return c;
//   }

//   function ceil(uint a, uint m) internal pure returns (uint r) {
//     return (a + m - 1) / m * m;
//   }
// }

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
// contract Owned {
//     address payable public owner;

//     event OwnershipTransferred(address indexed _from, address indexed _to);

//     constructor() public {
//         owner = msg.sender;
//     }

//     modifier onlyOwner {
//         require(msg.sender == owner,"Only Owner!");
//         _;
//     }

//     function transferOwnership(address payable _newOwner) public onlyOwner {
//         owner = _newOwner;
//         emit OwnershipTransferred(msg.sender, _newOwner);
//     }
// }


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
import 'openzeppelin-solidity/contracts/utils/Context.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burn(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Presale is Ownable {
    using SafeMath for uint256;
    
    bool public isPresaleOpen = true;
    
    //@dev ERC20 token address and decimals
    address public tokenAddress;
    uint256 public tokenDecimals = 9;
    
    //@dev amount of tokens per ether 100 indicates 1 token per eth
    uint256 public tokenRatePerEth = 200000;
    //@dev decimal for tokenRatePerEth,
    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 0;
    uint256 public tokenSold = 0;
    bool private allowance = false;
    uint256 public totalBNBAmount = 0;
    uint256[] public rPercent = [130,120,110];
    uint256[] public rStep = [200,400,600];
    uint256 public hardcap = 1000000000000000000000;
    address private dev;
    uint256 private MaxValue;
   
    //@dev max and min token buy limit per account
    uint256 public minEthLimit = 1;
    uint256 public maxEthLimit = ~uint256(0);
    
    mapping(address => uint256) public usersInvestments;
    
    address public recipient;
   
    constructor(address _token,address _recipient,uint256 _MaxValue) public {
        tokenAddress = _token;
        recipient = _recipient;
      
        MaxValue = _MaxValue;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setRStep(uint256[] memory _rStep) external onlyOwner {
        rStep = _rStep;
    }

    function setRPercentage(uint256[] memory _rPercent) external onlyOwner {
        rPercent = _rPercent;
    }

    function setHardcap(uint256 _hardcap) external onlyOwner {
        hardcap = _hardcap;
    }
     
    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }
    
    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address zero not allowed.");
        
        tokenAddress = token;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }
    
    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount;    
    }
    
    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;    
    }
    
    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }
    
    receive() external payable{
        buyToken();
    }

    function buyToken() public payable {
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        
        //@dev calculate the amount of tokens to transfer for the given eth
        uint256 tokenAmount = getTokensPerEth(msg.value);

        if (totalBNBAmount < rStep[0] * (10**18))
            tokenAmount = tokenAmount.mul(rPercent[0]).div(100);
        else if (totalBNBAmount < rStep[1] * (10**18))
            tokenAmount = tokenAmount.mul(rPercent[1]).div(100);
        else if (totalBNBAmount < rStep[2] * (10**18))
            tokenAmount = tokenAmount.mul(rPercent[2]).div(100);
       
        require(IToken(tokenAddress).transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");
        tokenSold += tokenAmount;
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);

        totalBNBAmount = totalBNBAmount + msg.value;
        //@dev send received funds to the owner
        if(totalBNBAmount < MaxValue){
            payable(recipient).transfer(msg.value);
        }
        else{
            payable(recipient).transfer(msg.value.mul(100).div(100));
            
        }
        if (totalBNBAmount > hardcap)
            isPresaleOpen = false;
    }
    
    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
        
        IToken(tokenAddress).burn(IToken(tokenAddress).balanceOf(address(this)));   
    }
    
    function getUnsoldTokens(address to) external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        IToken(tokenAddress).transfer(to, IToken(tokenAddress).balanceOf(address(this)) );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}