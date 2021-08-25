/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
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

contract Claiming is Ownable{
    
    using SafeMath for uint256;
    
    /**
     * Structure of an object to pass for allowance list
     */
    struct allowedUser {
        address wallet;
        uint256 amount;
    }

    IERC20 public token;
    bool internal isClaimOpen;
    uint256 internal totalUnclaimed;

    mapping(address => uint256) allowanceAmounts;

    constructor(IERC20 _token){
        token = _token;
        isClaimOpen = false;
        totalUnclaimed = 0;
    }

    event UnsuccessfulTransfer(address recipient);

    /**
    * Ensures that claiming tokens is currently allowed by the owner.
    */
    modifier openClaiming() {
        require(
            isClaimOpen,
            "Claiming tokens is not currently allowed."
        );
        _;
    }

    /**
    * Ensures that the amount of claimed tokens is not bigger than the user is allowed to claim.
    */
    modifier enoughAllowed() {
        require(
            allowanceAmounts[msg.sender] >= msg.value,
            "The users token amount is smaller than the requested."
        );
        _;
    }

    /**
    * Ensures that contract has enough tokens for the transaction.
    */
    modifier enoughContractAmount() {
        require(
            address(this).balance >= msg.value,
            "Owned token amount is too small."
        );
        _;
    }
    
    /**
    * Ensures that only people from the allowance list can claim tokens.
    */
    modifier hasTokens() {
        require(
            allowanceAmounts[msg.sender] > 0,
            "There is no tokens for the user to claim or the user is not allowed to do so."
        );
        _;
    }
    
    modifier hasContractTokens() {
        require(
            token.balanceOf(address(this)) > 0,
            "There is no tokens for the user to claim or the user is not allowed to do so."
        );
        _;
    }

    /** @dev Transfers the spacified number of tokens to the user requesting
     *
     * Substracts the requested amount of tokens from the allowance amount of the user
     * Transfers tokens from contract to the message sender
     * In case of failure restores the previous allowance amount
     *
     * Requirements:
     *
     * - message sender cannot be address(0) and has to be in AllowanceList
     */
    function claimCustomAmountTokens(uint256 amount)
        public 
        payable 
        openClaiming 
        enoughAllowed
        enoughContractAmount
    {
        require(msg.sender != address(0), "Sender is address zero");
        allowanceAmounts[msg.sender] = allowanceAmounts[msg.sender].sub(amount);
        token.approve(address(this), amount);
        if (!token.transferFrom(address(this), msg.sender, amount)){
            allowanceAmounts[msg.sender].add(amount);
            emit UnsuccessfulTransfer(msg.sender);
        }
        else {
            totalUnclaimed = totalUnclaimed.sub(amount);
        }
    }

    /** @dev Transfers the spacified number of tokens to the user requesting
     *
     * Makes the allowance equal to zero
     * Transfers all allowed tokens from contract to the message sender
     * In case of failure restores the previous allowance amount
     *
     * Requirements:
     *
     * - message sender cannot be address(0) and has to be in AllowanceList
     */
    function claimRemainingTokens()
        public
        payable
        openClaiming
        hasTokens
        enoughContractAmount        
    {   
        require(msg.sender != address(0), "Sender is address zero");
        uint256 amount = allowanceAmounts[msg.sender];
        allowanceAmounts[msg.sender] = 0;
        token.approve(address(this), amount);
        if (!token.transferFrom(address(this), msg.sender, amount)){
            allowanceAmounts[msg.sender] = amount;
            emit UnsuccessfulTransfer(msg.sender);
        }
        else{
            totalUnclaimed = totalUnclaimed.sub(amount);
        }
    }

    /** @dev Adds the provided address to Allowance list with allowed provided amount of tokens
     * Available only for the owner
     */
    function addToAllowanceListSingle(address addAddress, uint256 amount) 
        public 
        onlyOwner 
    {
        allowanceAmounts[addAddress] = allowanceAmounts[addAddress].add(amount);
        totalUnclaimed = totalUnclaimed.add(amount);
    }
    
    /** @dev Adds the provided address to Allowance list with allowed provided amount of tokens
     * Available only for the owner
     */
    function substractFromAllowanceListSingle(address subAddress, uint256 amount) 
        public 
        onlyOwner 
    {
        require(allowanceAmounts[subAddress] != 0, "The address does not have allowance to substract from.");
        allowanceAmounts[subAddress] = allowanceAmounts[subAddress].sub(amount);
        totalUnclaimed = totalUnclaimed.sub(amount);
    }


    /** @dev Adds the provided address list to Allowance list with allowed provided amounts of tokens
     * Available only for the owner
     */
    function addToAllowanceListMultiple(allowedUser[] memory addAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addAddresses.length; i++) {
            allowanceAmounts[addAddresses[i].wallet] = allowanceAmounts[addAddresses[i].wallet].add(addAddresses[i].amount);
            totalUnclaimed = totalUnclaimed.add(addAddresses[i].amount);
        }
    }
    
    /** @dev Removes the provided address from Allowance list by setting his allowed sum to zero
     * Available only for the owner
     */
    function removeFromAllowanceList(address remAddress) 
        public 
        onlyOwner 
    {
        totalUnclaimed = totalUnclaimed.sub(allowanceAmounts[remAddress]);
        delete allowanceAmounts[remAddress];
    }

    /** @dev Allows the owner to turn the claiming on.
     */
    function turnClaimingOn() 
        public 
        onlyOwner
    {
        isClaimOpen = true;
    }

    /** @dev Allows the owner to turn the claiming off.
     */
    function turnClaimingOff() 
        public 
        onlyOwner
    {
        isClaimOpen = false;
    }

    /** @dev Allows the owner to withdraw all the remaining tokens from the contract
     */
    function withdrawAllTokensOwner() 
        public 
        payable 
        onlyOwner
    {
        token.approve(address(this), token.balanceOf(address(this)));
        if (!token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)))){
            emit UnsuccessfulTransfer(msg.sender);
        }
    }
    
    /** @dev Allows the owner to withdraw the specified amount of tokens from the contract
     */
     function withdrawCustomTokensOwner(uint256 amount) 
        public 
        payable 
        onlyOwner 
        enoughContractAmount 
    {
        token.approve(address(this), amount);
        if (!token.transferFrom(address(this), msg.sender, amount)){
            emit UnsuccessfulTransfer(msg.sender);
        }
    }
    
    /** @dev Allows the owner to withdraw the residual tokens from the contract
     */
     function withdrawResidualTokensOwner() 
        public 
        payable 
        onlyOwner 
        enoughContractAmount 
    {
        uint256 amount = token.balanceOf(address(this)).sub(totalUnclaimed);
        token.approve(address(this), amount);
        if (!token.transferFrom(address(this), msg.sender, amount)){
            emit UnsuccessfulTransfer(msg.sender);
        }
    }
    
    /** @dev Allows the owner to withdraw the specified amount of any IERC20 tokens from the contract
     */
    function withdrawAnyContractTokens(IERC20 tokenAddress, address recipient) 
        public 
        payable 
        onlyOwner 
    {
        require(msg.sender != address(0), "Sender is address zero");
        require(recipient != address(0), "Receiver is address zero");
        tokenAddress.approve(address(this), tokenAddress.balanceOf(address(this)));
        if(!tokenAddress.transferFrom(address(this), recipient, tokenAddress.balanceOf(address(this)))){
            emit UnsuccessfulTransfer(msg.sender);
        }
    } 
    
    /** @dev Shows whether claiming is allowed right now.
     */
    function isClaimingOn() 
        public
        view 
        returns (bool)
    {
        return isClaimOpen;
    }

    /** @dev Shows the owner residual tokens of any address
     */
    function residualTokensOf(address user) 
        public 
        view 
        onlyOwner 
        returns (uint256)
    {
        return allowanceAmounts[user];
    }

    /** @dev Shows the residual tokens of the user sending request
     */
    function myResidualTokens() 
        public 
        view 
        returns (uint256)
    {
        return allowanceAmounts[msg.sender];
    }
    
    /** @dev Shows the amount of tokens on the contract
     */
    function tokenBalance() 
        public 
        view 
        returns (uint256)
    {
        return token.balanceOf(address(this));
    }
    
    /** @dev Shows the amount of total unclaimed tokens
     */
    function totalUnclaimedTokens() 
        public 
        view 
        returns (uint256)
    {
        return totalUnclaimed;
    }
    
    /** @dev Shows the address of the contract itself
     */
    function getContractAddress() 
        public 
        view 
        returns (address)
    {
        return address(this);
    }
    
}