pragma solidity 0.4.20;

/*
* Team AppX presents...
* https://powtf.com/
* https://discord.gg/Ne2PTnS
*
* /======== A Community Marketing Fund Project for PoWTF ========/
*
* -> WTF is this!?
* In short, this is a contract to accept PoWTF token / ETH donations from community members
* as a way of gathering funds for regular marketing and contests.
* [✓] Hands of Stainless Steel! This contract never sells, it can&#39;t and just simply don&#39;t know how to sell!
* [✓] Community Goods: All dividends will be used for promotional fee / contest prizes, when the accumulated dividends reached certain amount, we&#39;ll create some campaign.
* [✓] Transparency: How to use the dividends will be regularly updated in website and discord announcement.
* [✓] Security: You need to trust me (@AppX Matthew) not taking the dividends and go away :)
* 
* -> Quotes
* "Real, sustainable community change requires the initiative and engagement of community members." - Helene D. Gayle
* "Every successful individual knows that his or her achievement depends on a community of persons working together." - Paul Ryan
* "Empathy is the starting point for creating a community and taking action. It&#39;s the impetus for creating change." - Max Carver
* "WTF Moon!" - AppX Matthew 
*
* =================================================*
*                                                  *
* __________      __      ________________________ *
* \______   \____/  \    /  \__    ___/\_   _____/ *
*  |     ___/  _ \   \/\/   / |    |    |    __)   *
*  |    |  (  <_> )        /  |    |    |     \    *
*  |____|   \____/ \__/\  /   |____|    \___  /    *
*                       \/                  \/     *
*                                                  *
* =================================================*
*
*/

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
    
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
   * @dev withdraw accumulated balance, called by payee.
   */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
   * @dev Called by the payer to store the sent amount as credit to be pulled.
   * @param dest The destination address of the funds.
   * @param amount The amount to transfer.
   */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
  
}

/// @dev Interface to the PoWTF contract.
contract PoWTFInterface {


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    /// @dev Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
    function buy(address _referredBy) public payable returns (uint256);

    /// @dev Converts all of caller&#39;s dividends to tokens.
    function reinvest() public;

    /// @dev Alias of sell() and withdraw().
    function exit() public;

    /// @dev Withdraws all of the callers earnings.
    function withdraw() public;

    /// @dev Liquifies tokens to ethereum.
    function sell(uint256 _amountOfTokens) public;

    /**
     * @dev Transfer tokens from the caller to a new holder.
     *  Remember, there&#39;s a 15% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) public returns (bool);


    /*=====================================
    =      HELPERS AND CALCULATORS        =
    =====================================*/

    /**
     * @dev Method to view the current Ethereum stored in the contract
     *  Example: totalEthereumBalance()
     */
    function totalEthereumBalance() public view returns (uint256);

    /// @dev Retrieve the total token supply.
    function totalSupply() public view returns (uint256);

    /// @dev Retrieve the tokens owned by the caller.
    function myTokens() public view returns (uint256);

    /**
     * @dev Retrieve the dividends owned by the caller.
     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     *  But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus) public view returns (uint256);

    /// @dev Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint256);

    /// @dev Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress) public view returns (uint256);

    /// @dev Return the sell price of 1 individual token.
    function sellPrice() public view returns (uint256);

    /// @dev Return the buy price of 1 individual token.
    function buyPrice() public view returns (uint256);

    /// @dev Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256);

    /// @dev Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256);


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    /// @dev Internal function to actually purchase the tokens.
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256);

    /**
     * @dev Calculate Token price based on an amount of incoming ethereum
     *  It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256);

    /**
     * @dev Calculate token sell value.
     *  It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256);

    /// @dev This is where all your gas goes.
    function sqrt(uint256 x) internal pure returns (uint256 y);


}

/// @dev Core Contract
contract PoWTFCommunityFund is Ownable, PullPayment {


    /*=================================
    =            CONTRACTS            =
    =================================*/

    /// @dev The address of the EtherDungeonCore contract.
    PoWTFInterface public poWtfContract = PoWTFInterface(0x702392282255f8c0993dBBBb148D80D2ef6795b1);


    /*==============================
    =            EVENTS            =
    ==============================*/

    event LogDonateETH(
        address indexed donarAddress,
        uint256 amount,
        uint256 timestamp
    );


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/
    
    /// @dev Besides donating PoWTF tokens, you can also donate ETH as well.
    function donateETH() public payable {
        // When you make an ETH donation, it will use your address as referrer / masternode.
        poWtfContract.buy.value(msg.value)(msg.sender);
        
        // Emit LogDonateETH event.
        LogDonateETH(msg.sender, msg.value, now);
    }

    /// @dev Converts ETH dividends to PoWTF tokens.
    function reinvestDividend() onlyOwner public {
        poWtfContract.reinvest();
    }

    /// @dev Withdraw ETH dividends and put it to this contract.
    function withdrawDividend() onlyOwner public {
        poWtfContract.withdraw();
    }

    /// @dev Assign who can get how much of the dividends.
    function assignFundReceiver(address _fundReceiver, uint _amount) onlyOwner public {
        // Ensure there are sufficient available balance.
        require(_amount <= this.balance - totalPayments);

        // Using the asyncSend function of PullPayment, fund receiver can withdraw it anytime.
        asyncSend(_fundReceiver, _amount);
    }

    /// @dev Fallback function to allow receiving funds from PoWTF contract.
    function() public payable {}

    /*=======================================
    =           SETTER FUNCTIONS            =
    =======================================*/

    function setPoWtfContract(address _newPoWtfContractAddress) onlyOwner external {
        poWtfContract = PoWTFInterface(_newPoWtfContractAddress);
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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