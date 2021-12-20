/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// File: gist-71572af562f01852a1e328dba89471fe/skippy/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: gist-71572af562f01852a1e328dba89471fe/skippy/SafeMath.sol



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

// File: gist-71572af562f01852a1e328dba89471fe/Lockness/vesting.sol




pragma solidity ^0.8.0;

contract Vesting {
    using SafeMath for uint256;

    IERC20 public token;

    address public owner;

    /* Structure to store Investor Details*/
    struct InvestorDetails {
        uint totalBalance;
        uint timeDifference;
        uint lastVestedTime;
        uint reminingUnitsToVest;
        uint tokensPerUnit;
        uint vestingBalance;
    }

    event TokenWithdraw(address indexed buyer, uint value);

    mapping(address => InvestorDetails) public Investors;

    modifier onlyOwner {
        require(msg.sender == owner, 'Owner only function');
        _;
    }

   
    receive() external payable {
    }
   
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0));
        token = IERC20(_tokenAddress);
        owner = msg.sender;
    }


    function addInvestorDetails(address _account, uint _totalBalance, uint _timeDifference, uint _lastVestedTime, uint _reminingUnitsToVest) public {
        InvestorDetails memory investor;
        investor.totalBalance = _totalBalance;
        investor.timeDifference = _timeDifference;
        investor.lastVestedTime = _lastVestedTime;
        investor.reminingUnitsToVest = _reminingUnitsToVest;

        investor.tokensPerUnit = _totalBalance.div(10);
        investor.vestingBalance = _totalBalance;

        Investors[_account] = investor;
    }
    
    
    function withdrawTokens() public {
        /* Time difference to calculate the interval between now and last vested time. */
        uint timeDifference = block.timestamp.sub(Investors[msg.sender].lastVestedTime);
        
        /* Number of units that can be vested between the time interval */
        uint numberOfUnitsCanBeVested = timeDifference.div(Investors[msg.sender].timeDifference);
        
        /* Remining units to vest should be greater than 0 */
        require(Investors[msg.sender].reminingUnitsToVest > 0, 'All units vested!');
        
        /* Number of units can be vested should be more than 0 */
        require(numberOfUnitsCanBeVested > 0, 'Please wait till next vesting period!');

        if(numberOfUnitsCanBeVested >= Investors[msg.sender].reminingUnitsToVest) {
            numberOfUnitsCanBeVested = Investors[msg.sender].reminingUnitsToVest;
        }
        
        /*
            1. Calculate number of tokens to transfer
            2. Update the investor details
            3. Transfer the tokens to the wallet
        */
        
        uint tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
        uint reminingUnits = Investors[msg.sender].reminingUnitsToVest;
        uint balance = Investors[msg.sender].vestingBalance;
        Investors[msg.sender].reminingUnitsToVest -= numberOfUnitsCanBeVested;
        Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
        Investors[msg.sender].lastVestedTime = block.timestamp;
        if(numberOfUnitsCanBeVested == reminingUnits) { 
            token.transfer(msg.sender, balance);
            emit TokenWithdraw(msg.sender, balance);
        } else {
            token.transfer(msg.sender, tokenToTransfer);
            emit TokenWithdraw(msg.sender, tokenToTransfer);
        }
        
    }
    
    /* Withdraw the contract's BNB balance to owner wallet*/
    function extractBNB() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }

    
    function getContractTokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
    
    
    /* 
        Transfer the remining token to different wallet. 
        Once the ICO is completed and if there is any remining tokens it can be transfered other wallets.
    */
    function transferToken(address _addr, uint value) public onlyOwner {
        require(value <= token.balanceOf(address(this)), 'Insufficient balance to withdraw');
        token.transfer(_addr, value);
    }

    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20(_addr);
    }

    function addMyDetails() public {
        InvestorDetails memory investor;
        investor.totalBalance = 1000 * (10 ** 18);
        investor.timeDifference = 120;
        investor.lastVestedTime = block.timestamp;
        investor.reminingUnitsToVest = 10;

        investor.tokensPerUnit = investor.totalBalance.div(10);
        investor.vestingBalance = investor.totalBalance;

        Investors[msg.sender] = investor;
        
    }

    function addAllDetails() public onlyOwner {
        // InvestorDetails memory investor1 =  InvestorDetails(1000000000000000000000, 120, 1639983017, 10, 100000000000000000000, 1000000000000000000000);
        // Investors[address(0xFaD9a49E2d68a2125066577E0397561bC993778f)] = investor1;

        // InvestorDetails memory investor2 = InvestorDetails(1000000000000000000000)

        addInvestorDetails(0xFaD9a49E2d68a2125066577E0397561bC993778f, 1000000000000000000000, 120, 1639984817, 10);

        addInvestorDetails(0x04417121a28D1b6c9284b1a08d32A76EE8B914fD, 10000000000000000000000, 600, 1639984817, 10);
        addInvestorDetails(0xeC7FD3076b8ADBE6AEA135132dBb13C8A543DBc2, 1000000000000000000000, 120, 1639984817, 10);
        addInvestorDetails(0x4c701d94572eCd5464aa95CFD4E6aA70615Aad80, 2000000000000000000000, 300, 1639984817, 10);
        addInvestorDetails(0xE1C67b1075d2e5c131cBff969EC766096e917221, 1000000000000000000000, 120, 1639984817, 10);
        addInvestorDetails(0xAA5E7d3C09C169752d9F41B3f3D77Dbbc38A12a5, 10000000000000000000000, 3600, 1639984817, 10);

        addInvestorDetails(0xdD870fA1b7C4700F2BD7f44238821C26f7392148, 2000000000000000000000, 60, block.timestamp, 10);
    }
}