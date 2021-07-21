/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;


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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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


contract Presale is ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  // Maps user to the number of tokens owned
  mapping (address => uint256) public tokensOwned;
  // The block when the user claimed tokens prevously
  mapping (address => uint256) public lastTokensClaimed;
  // The number of times the user has claimed tokens;
  mapping (address => uint256) public numClaims;
  // The number of unclaimed tokens the user has
  mapping (address => uint256) public tokensUnclaimed;

  // Olymp token
  IBEP20 olymp;
  // Sale ended
  bool isSaleActive;
  // Starting timestamp normal
  uint256 startingTimeStamp;
  uint256 totalTokensSold = 0;
  uint256 tokensPerBNB = 75;
  uint256 bnbReceived = 0;
  
  event TokenBuy(address user, uint256 tokens);
  event TokenClaim(address user, uint256 tokens);

  constructor (address _olympAddress, uint256 _startingTimestamp) public {
    olymp = IBEP20(_olympAddress);
    isSaleActive = true;
    startingTimeStamp = _startingTimestamp;
  }

  receive() external payable {
    buy (msg.sender);
  }
  
  function buy (address beneficiary) public payable nonReentrant {
    require(isSaleActive, "Sale is not active yet");
      
    address _buyer = beneficiary;
    uint256 _bnbSent = msg.value;
    uint256 tokens = _bnbSent.mul(tokensPerBNB);
    
    require (_bnbSent >= 0.2 ether, "BNB is lesser than min value");
    require (_bnbSent <= 7 ether, "BNB is greater than max value");
    require (bnbReceived <= 800 ether, "Hardcap reached");
    require (block.timestamp >= startingTimeStamp, "Presale has not started");
    
    tokensOwned[_buyer] = tokensOwned[_buyer].add(tokens);
    
    // Already owns 525 tokens which is max
    // Changed to prevent botting of presale
    require(tokensOwned[_buyer] <= 525 ether, "Can't buy more than 7 BNB worth of tokens");
    
    tokensUnclaimed[_buyer] = tokensUnclaimed[_buyer].add(tokens);
    totalTokensSold = totalTokensSold.add(tokens);
    bnbReceived = bnbReceived.add(msg.value);
    emit TokenBuy(beneficiary, tokens);
  }
  
  function setSaleActive(bool _isSaleActive) external onlyOwner {
      isSaleActive = _isSaleActive;
  }

  function getTokensOwned () external view returns (uint256) {
    return tokensOwned[msg.sender];
  }

  function getTokensUnclaimed () external view returns (uint256) {
    return tokensUnclaimed[msg.sender];
  }

  function getLastTokensClaimed () external view returns (uint256) {
    return lastTokensClaimed[msg.sender];
  }

  function getOlympTokensLeft () external view returns (uint256) {
    return olymp.balanceOf(address(this));
  }
  
  function getNumClaims () external view returns (uint256) {
    return numClaims[msg.sender];
  }
  
  function claimTokens () external {
    require (isSaleActive == false, "Sale is still active");
    require (tokensOwned[msg.sender] > 0, "User should own some olymp tokens");
    require (tokensUnclaimed[msg.sender] > 0, "User should have unclaimed olymp tokens");
    require (olymp.balanceOf(address(this)) >= tokensOwned[msg.sender], "There are not enough olymp tokens to transfer");
    require (block.number.sub(lastTokensClaimed[msg.sender]) >= 28800, "Hasn't been 28,800 blocks since last claim"); 
    require (numClaims[msg.sender] < 10, "Only 10 claims can be made to the smart contract");

    tokensUnclaimed[msg.sender] = tokensUnclaimed[msg.sender].sub(tokensOwned[msg.sender].div(5));
    lastTokensClaimed[msg.sender] = block.number;
    numClaims[msg.sender] = numClaims[msg.sender].add(1);
    
    olymp.transfer(msg.sender, tokensOwned[msg.sender].div(10));
    emit TokenClaim(msg.sender, tokensOwned[msg.sender].div(10));
  }

  function withdrawFunds () external onlyOwner {
    (msg.sender).transfer(address(this).balance);
  }
  
  function withdrawUnsoldOlymp() external onlyOwner {
    olymp.transfer(msg.sender, olymp.balanceOf(address(this)));
  }
}

contract PresaleFix is ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  Presale presale;
  IBEP20 olymp;
  
  // Maps user to the number of tokens owned
  mapping (address => uint256) public tokensOwned;
  // The block when the user claimed tokens prevously
  mapping (address => uint256) public lastTokensClaimed;
  // The number of times the user has claimed tokens;
  mapping (address => uint256) public numClaims;
  
  mapping (address => bool) public firstFixClaimDone;

  event TokenClaim(address user, uint256 tokens);

  constructor(address _olympAddress, address payable _presaleAddress) public {
    presale = Presale(_presaleAddress);
    olymp = IBEP20(_olympAddress);
  }

  function claimTokens () external {
    if (firstFixClaimDone[msg.sender] == false) {
        tokensOwned[msg.sender] = presale.tokensOwned(msg.sender);
        lastTokensClaimed[msg.sender] = presale.lastTokensClaimed(msg.sender);
        numClaims[msg.sender] = presale.numClaims(msg.sender);
    
        firstFixClaimDone[msg.sender] = true;        
    } 
      
    require (tokensOwned[msg.sender] > 0, 
    "User should own some olymp tokens");
    require (olymp.balanceOf(address(this)) >= tokensOwned[msg.sender], 
    "There are not enough olymp tokens to transfer");
    require (block.number.sub(lastTokensClaimed[msg.sender]) >= 28800, 
    "Hasn't been 28,800 blocks since last claim"); 
    require (numClaims[msg.sender] < 10, 
    "Only 10 claims can be made to the smart contract");

    lastTokensClaimed[msg.sender] = block.number;
    numClaims[msg.sender] = numClaims[msg.sender].add(1);
    
    olymp.transfer(msg.sender, tokensOwned[msg.sender].div(10));
    emit TokenClaim(msg.sender, tokensOwned[msg.sender].div(10));
  }

  function withdrawUnsoldOlymp() external onlyOwner {
    olymp.transfer(msg.sender, olymp.balanceOf(address(this)));
  }
}