pragma solidity ^0.4.21;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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


contract TraxionWallet is Ownable {
    using SafeMath for uint;

    constructor(){
        transferOwnership(0xC889dFBDc9C1D0FC3E77e46c3b82A3903b2D919c);
    }

    // Address where funds are collected
    address public wallet = 0xbee44A7b93509270dbe90000f7ff31268D8F075e;

    // how much one token is worth
    uint public weiPerToken = 0.0007 ether;

    // should be the same as in the TraxionToken contract
    uint public decimals = 18;

    // Minimum investment in wei
    uint public minInvestment = 0.4 ether;

    // Maximum investment in wei
    uint public investmentUpperBounds = 2000 ether;

    // Hard cap in wei
    uint public hardcap = 45000 ether;

    // Amount of wei raised
    uint public weiRaised = 0;

    event TokenPurchase(address indexed beneficiary, uint value, uint amount);

    /** Whitelist an address and set max investment **/
    mapping (address => bool) public whitelistedAddr;
    mapping (address => uint) public totalInvestment;

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /** @dev whitelist an Address */
    function whitelistAddress(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = true;
        }
    }

    /** @dev black list an address **/
    function blacklistAddr(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = false;
        }
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) public payable {

        uint weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint tokens = _getTokenAmount(weiAmount);

        assert(tokens != 0);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        emit TokenPurchase(msg.sender, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
    }

    // -----------------------------------------
    // Internal interface
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);

        require(_weiAmount >= minInvestment);
        require(whitelistedAddr[_beneficiary]);
        require(totalInvestment[_beneficiary].add(_weiAmount) <= investmentUpperBounds);
        require(weiRaised.add(_weiAmount) <= hardcap);
    }


    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint _weiAmount) internal {
        totalInvestment[_beneficiary] = totalInvestment[_beneficiary].add(_weiAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint _weiAmount) internal view returns (uint) {
        return _weiAmount.mul(10 ** decimals).div(weiPerToken);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}