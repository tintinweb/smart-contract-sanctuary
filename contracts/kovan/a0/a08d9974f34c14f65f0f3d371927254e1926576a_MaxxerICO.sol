/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow. 
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
* @title ERC223Interface
* @dev ERC223 Contract Interface
*/
abstract contract ERC223Interface {
    function balanceOf(address who)public view virtual returns (uint);
    function transfer(address to, uint256 value)public virtual returns (bool success);
    function transfer(address to, uint256 value, bytes memory data)public virtual returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

/// @title Interface for the contract that will work with ERC223 tokens.
interface ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction data.
     */
    function tokenFallback(address _from, uint256 _value, bytes calldata _data) external;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes memory) {
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
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
    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MaxxerICO is Ownable,ERC223ReceivingContract{
  using SafeMath for uint256;

  /**
  * Address of MaxxerToken.
  */
  address public maxxerToken;
  
  /**
  * Maxxer Token price in front of ETH.
  */
  uint256 public tokenPrice;

  // Address where funds are collected
  address payable public wallet;

  // Amount of wei raised
  uint256 public weiRaised;
  
  // Ether spending limit
  uint256 public etherCaps;
  
  //White listed address that can contribut Ether
  mapping(address => bool) public whitelist;

  //Contributed addresses for each days
  mapping(address => uint256) public contributions;
    
  uint256 public openingTime;
  uint256 public closingTime;
  
  /**
   * Event for token purchase logging
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

  /**   
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   * @param _tokenPrice price of the maxxerToken 
   * @param _etherCaps Ether contribution limit   
   * @param _openingTime Start time of event
   * @param _closingTime End time of event
   */
  function setAttributes(address payable _wallet, address _token,uint256 _tokenPrice,uint256 _etherCaps,uint256 _openingTime, uint256 _closingTime) external onlyOwner {  
    require(_wallet != address(0));
    require(_token != address(0));    
    wallet = _wallet;
    maxxerToken = _token;
    tokenPrice = _tokenPrice;
	etherCaps=_etherCaps;
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------
 
  /**
  * @dev fallback function ***DO NOT OVERRIDE***
  */
  // function fallback() external payable {
  //     buyTokens();
  // }
  
  receive() external payable {
    buyTokens();
  }

  function tokenFallback(address, uint256 _value, bytes calldata) external view {
    require(msg.sender == maxxerToken);
    require(_value >=1000000000000000000);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   */
  function buyTokens() internal isWhitelisted(){

    // uint256 weiAmount = msg.value;

    _preValidatePurchase(msg.sender, msg.value);

    // calculate token amount to be created
    uint256 tokenAmount = _getTokenAmount(msg.value);

    // update state
    weiRaised = weiRaised.add(msg.value);

    _processPurchase(msg.sender, tokenAmount);
    emit TokenPurchase(msg.sender, msg.value, tokenAmount);

    _updatePurchasingState(msg.sender, msg.value);

    _forwardFunds();
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
    require(openingTime >0 && block.timestamp>=openingTime && block.timestamp<=closingTime); 
    require(_beneficiary != address(0));
    require(_weiAmount >=100000000000000000);
	require(weiRaised.add(_weiAmount) <=etherCaps);
  }
  
  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    ERC223Interface(maxxerToken).transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
		contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
	uint256 amtmultiply= _weiAmount.mul(tokenPrice);
    // return amtmultiply.div(10**18);
    return amtmultiply;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value); 
  }
	
   /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted() {
    require(whitelist[msg.sender],"Only whitelisted address is allowed.");
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;    
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] calldata _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;    
  }
}