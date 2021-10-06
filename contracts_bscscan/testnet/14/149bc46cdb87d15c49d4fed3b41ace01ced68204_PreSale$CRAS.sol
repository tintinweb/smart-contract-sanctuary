/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-23
*/

pragma solidity ^0.6.12;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

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


contract Context {
  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), _msgSender());
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _owner = newOwner;
    emit OwnershipTransferred(_owner, newOwner);
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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract PreSale$CRAS is Context, Ownable {
    
    IBEP20 public token;
    using SafeMath for uint256;
    
    uint256 public tokenPrice;
    uint256 public minDepositBNBAmount;
    uint256 public maxDepositBNBAmount;
    uint public saleDateStart;
    uint public saleDateEnd;
    
    uint public nextClaimTime;
    uint256 public claimPercent;
    uint256 public claimCycle;
    uint256 public amountRaised;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public activePercentAmount;
    mapping(address => uint256) public claimCount;
    
    event BuyToken(address _user, uint256 _amount);
    event ClaimToken(address _user, uint256 _amount);
    
    constructor(IBEP20 _token) public {
        token = _token;
        claimPercent = 5;
        claimCycle = 0;
        nextClaimTime = block.timestamp;
    }
    
    function startSale(uint256 _tokenPrice, uint256 _minDepositBNBAmount, uint256 _maxDepositBNBAmount, uint _saleDateStart, uint _saleDateEnd) public onlyOwner() {
        tokenPrice = _tokenPrice;
        minDepositBNBAmount = _minDepositBNBAmount;
        maxDepositBNBAmount = _maxDepositBNBAmount;
        saleDateStart = _saleDateStart;
        saleDateEnd = _saleDateEnd;
    }
    
    function viewSale() public view returns (uint256 SalePrice, uint256 MinimumDeposit, uint256 MaximumDeposit, uint SaleStart, uint SaleEnd) {
        return(tokenPrice, minDepositBNBAmount, maxDepositBNBAmount, saleDateStart, saleDateEnd);
    }
    
    // to buy token during preSale time
    function buyToken() payable public {
        require(block.timestamp >= saleDateStart && block.timestamp <= saleDateEnd, 'Deposit rejected, presale has either not yet started or not yet overed');
        require(msg.value >= minDepositBNBAmount, 'Deposit rejected, it is lesser than minimum amount');
        require(msg.value <= maxDepositBNBAmount, 'Deposit rejected, exceeds the maximum amount');
        uint256 numberOfTokens = bnbToToken(msg.value);
        
        balances[msg.sender] = balances[msg.sender].add(numberOfTokens);
        token.transferFrom(owner(), address(this), numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        emit BuyToken(msg.sender, balances[msg.sender]);
    }
    
    // to claim token after launch
    function claim() public {
        
        require(block.timestamp >= nextClaimTime && claimCount[msg.sender] < claimCycle ,"BEP20: Wait for next claim date");
        require(balances[msg.sender] > 0,"BEP20: Do not have any tokens to claim");
        
        uint256 multiplier = claimCycle.sub(claimCount[msg.sender]);
        uint256 transferAmount = calculateClaimAmount(msg.sender, multiplier);
        
        token.transfer(msg.sender, transferAmount);
        balances[msg.sender] = balances[msg.sender].sub(transferAmount);
            
        claimCount[msg.sender] ++;
        emit ClaimToken(msg.sender, transferAmount);
    }
    
    // to check number of token for given BNB
    function bnbToToken(uint256 _amount) public view returns(uint256) {
        uint256 _eth = _amount;
        uint256 _tkns;
        _tkns = _eth / tokenPrice;
        _tkns = _tkns * 10**18;
        return _tkns;
    }
    
    function calculateClaimAmount(address _user, uint256 multiplier) private view returns (uint256) {
        uint256 remainingBalance = balances[_user];
        uint256 totalBalance = remainingBalance.mul(claimPercent * multiplier).div(10**2);
        return totalBalance;
    }
    
    function setNextClaim(uint _nextClaimDateStart) public onlyOwner {
        require(_nextClaimDateStart > nextClaimTime, 'setNextClaim rejected');
        nextClaimTime = _nextClaimDateStart;
        claimCycle ++;
    }
    
    // to draw funds for liquidity
    function migrateFunds(uint256 _value) external onlyOwner{
        address payable _owner = msg.sender;
        _owner.transfer(_value);
    }
    
    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return token.balanceOf(address(this));
    }
  
}