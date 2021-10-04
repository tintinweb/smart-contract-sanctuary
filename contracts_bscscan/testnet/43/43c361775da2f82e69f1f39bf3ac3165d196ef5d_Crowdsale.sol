/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;



// Part: Address

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// Part: IERC20

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// Part: Ownable

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipRenounced(address indexed previousOwner);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  function getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }


  //Locks the contract for owner
  function lock() public onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    emit OwnershipRenounced(_owner);

  }

  function unlock() public {
    require(_previousOwner == msg.sender, "You don’t have permission to unlock");
    require(now > _lockTime , "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// Part: SafeMath

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// Part: SafeERC20

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: Crowdsale.sol

/**
* @title Crowdsale
* @dev Crowdsale is a base contract for managing a token crowdsale,
* allowing investors to purchase tokens with ether. This contract implements
* such functionality in its most fundamental form and can be extended to provide additional
* functionality and/or custom behavior.
* The external interface represents the basic interface for purchasing tokens, and conform
* the base architecture for crowdsales. They are *not* intended to be modified / overriden.
* The internal interface conforms the extensible and modifiable surface of crowdsales. Override
* the methods to add functionality. Consider using 'super' where appropiate to concatenate
* behavior.
*/
contract Crowdsale is Ownable {
 using SafeMath for uint256;
 using SafeERC20 for IERC20;

 // The token being sold
 IERC20 public token;

 // Address where funds are collected
 address payable public wallet;

 // Address where funds are collected
 address payable public marketingWallet;

 // How many token units buyer initially gets
 uint256 public initial_rate;

 // Final AntiG-BNB rate
 uint256 public finalRate;

 // Current rate
 uint256 public rate;

 // Amount of wei raised
 uint256 public weiRaised;

 //Pre-sale tokens remaining
 uint256 public preSaleTokensRemaining;

 //Initial Pre-sale tokens
 uint256 public initialPreSaleSupply;

 uint256 public openingTime;
 uint256 public closingTime;

 // Amount of wei available
 uint256 public weiAvailable;

 // Gradient of VWAP;
 uint256 public m;


 /**
  * Event for token purchase logging
  * @param purchaser who paid for the tokens
  * @param beneficiary who got the tokens
  * @param value weis paid for purchase
  * @param amount amount of tokens purchased
  */
 event TokenPurchase(
   address indexed purchaser,
   address indexed beneficiary,
   uint256 value,
   uint256 amount
 );

 /**
 * @dev Reverts if not in crowdsale time range.
 */
modifier onlyWhileOpen {
  // solium-disable-next-line security/no-block-members
  require(block.timestamp >= openingTime && block.timestamp <= closingTime);
  _;
}

 /**
  * @param _initial_rate Initial number of of token units a buyer gets per wei
  * @param _wallet Address where collected funds will be forwarded to
  * @param _token Address of the token being sold
  */
 constructor(uint256 _initial_rate, uint256 _final_rate, address payable _wallet, address payable _marketingWallet, IERC20 _token, uint256 _openingTime,
 uint256 _closingTime, uint256 _initialPreSaleSupply, uint256 _weiAvailable) public {
   require(_initial_rate > 0);
   require(_wallet != address(0));
   require(address(_token) != address(0));
   require(_openingTime >= block.timestamp);
   require(_closingTime >= _openingTime);

   initial_rate = _initial_rate;
   rate = _initial_rate.mul(10 ** 28);
   wallet = _wallet;
   marketingWallet =_marketingWallet;
   token = _token;
   initialPreSaleSupply = _initialPreSaleSupply;
   preSaleTokensRemaining = _initialPreSaleSupply;
   weiAvailable = _weiAvailable;

   openingTime = _openingTime;
   closingTime = _closingTime;

   finalRate = _final_rate.mul(10 ** 28);

   m = ((initial_rate.mul(10 ** 28)).sub(finalRate)).div(weiAvailable);

 }

 // -----------------------------------------
 // Crowdsale external interface
 // -----------------------------------------

 /**
  * @dev fallback function ***DO NOT OVERRIDE***
  */
 function () external payable {
   buyTokens(msg.sender);
 }

 /**
  * @dev low level token purchase ***DO NOT OVERRIDE***
  * @param _beneficiary Address performing the token purchase
  */
 function buyTokens(address _beneficiary) public payable {

   uint256 weiAmount = msg.value;

   // calculate token amount to be created
   uint256 tokens = _getTokenAmount(weiAmount);

   _preValidatePurchase(_beneficiary, weiAmount, tokens);

   // update state
   weiRaised = weiRaised.add(weiAmount);
   weiAvailable = weiAvailable.sub(weiAmount);

   _processPurchase(_beneficiary, tokens);
   emit TokenPurchase(
     msg.sender,
     _beneficiary,
     weiAmount,
     tokens
   );

   _updatePurchasingState();

   _forwardFunds();
   _postValidatePurchase(_beneficiary, weiAmount);
 }

 function refundTokensAfterClose() public {
   require(hasClosed());
   token.transfer(owner(), preSaleTokensRemaining);
 }



 // -----------------------------------------
 // Internal interface (extensible)
 // -----------------------------------------

 /**
  * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
  * @param _beneficiary Address performing the token purchase
  * @param _weiAmount Value in wei involved in the purchase
  */
 function _preValidatePurchase(
   address _beneficiary,
   uint256 _weiAmount,
   uint256 tokens ) internal view onlyWhileOpen
 {
   require(_beneficiary != address(0));
   require(_weiAmount != 0);
   require(_weiAmount <= 20 * 10 ** 18);
   require(token.balanceOf(address(this)) >= tokens);
   require(weiAvailable.sub(_weiAmount) >= 0);
 }

 /**
  * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
  * @param _beneficiary Address performing the token purchase
  * @param _weiAmount Value in wei involved in the purchase
  */
 function _postValidatePurchase(
   address _beneficiary,
   uint256 _weiAmount
 )
   internal
 {
   // optional override
 }

 /**
  * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
  * @param _beneficiary Address performing the token purchase
  * @param _tokenAmount Number of tokens to be emitted
  */
 function _deliverTokens(
   address _beneficiary,
   uint256 _tokenAmount
 )
   internal
 {
   /*token.approve(msg.sender, _tokenAmount);*/
   token.transfer(_beneficiary, _tokenAmount);
 }

 /**
  * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
  * @param _beneficiary Address receiving the tokens
  * @param _tokenAmount Number of tokens to be purchased
  */
 function _processPurchase(
   address _beneficiary,
   uint256 _tokenAmount
 )
   internal
 {
   _deliverTokens(_beneficiary, _tokenAmount);
 }

 /**
  * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
  */
 function _updatePurchasingState()
 internal
 {
      preSaleTokensRemaining = token.balanceOf(address(this));
 }

 /**
  * @dev Override to extend the way in which ether is converted to tokens.
  * @param _weiAmount Value in wei to be converted into tokens
  * @return Number of tokens that can be purchased with the specified _weiAmount
  */
 function _getTokenAmount(uint256 _weiAmount)
   internal returns (uint256)
 {

   rate = m.mul((weiAvailable.mul(2)).sub(_weiAmount)).div(2).add(finalRate);

   return _weiAmount.mul(rate).div(10 ** 28).div(10 ** 9);
 }

 /**
  * @dev Determines how ETH is stored/forwarded on purchases.
  */
 function _forwardFunds() internal {
   uint256 weiAmount = msg.value;

   uint256 lpFunds = weiAmount.mul(9019).div(10000);
   uint256 marketingFunds = weiAmount.mul(981).div(10000);

   wallet.transfer(lpFunds);
   marketingWallet.transfer(marketingFunds);
 }
 /**
 * @dev Checks whether the period in which the crowdsale is open has already elapsed.
 * @return Whether crowdsale period has elapsed
 */

function hasClosed() public view returns (bool) {
  // solium-disable-next-line security/no-block-members
  return block.timestamp > closingTime;
}

}