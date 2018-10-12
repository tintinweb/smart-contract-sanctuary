pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
     OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
     OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}




/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
         OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

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




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
     Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title LimitedTransferToken
 * @dev LimitedTransferToken defines the generic interface and the implementation to limit token
 * transferability for different events. It is intended to be used as a base class for other token
 * contracts.
 * LimitedTransferToken has been designed to allow for different limiting factors,
 * this can be achieved by recursively calling super.transferableTokens() until the base class is
 * hit. For example:
 *     function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
 *       return min256(unlockedTokens, super.transferableTokens(holder, time));
 *     }
 * A working example is VestedToken.sol:
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/VestedToken.sol
 */

contract LimitedTransferToken is ERC20 {

  /**
   * @dev Checks whether it can transfer or otherwise throws.
   */
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(block.timestamp)));
   _;
  }

  /**
   * @dev Checks modifier and allows transfer if tokens are not locked.
   * @param _to The address that will receive the tokens.
   * @param _value The amount of tokens to be transferred.
   */
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

  /**
  * @dev Checks modifier and allows transfer if tokens are not locked.
  * @param _from The address that will send the tokens.
  * @param _to The address that will receive the tokens.
  * @param _value The amount of tokens to be transferred.
  */
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Default transferable tokens function returns all tokens for a holder (no limit).
   * @dev Overwriting transferableTokens(address holder, uint64 time) is the way to provide the
   * specific logic for limiting token transferability for a holder over time.
   */
  function transferableTokens(address holder, uint64 time) public view returns (uint256) {
    return balanceOf(holder);
  }
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;




  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
  )
  public
  view
  returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
     Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
     Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
  public
  returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
     Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
  public
  returns (bool)
  {
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
  public
  returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Claimable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
  public
  hasMintPermission
  canMint
  returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
     Mint(_to, _amount);
     Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
     MintFinished();
    return true;
  }
}

/*
    Smart Token interface
*/
contract ISmartToken {

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    bool public transfersEnabled = false;

    // =================================================================================================================
    //                                      Event
    // =================================================================================================================

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    // =================================================================================================================
    //                                      Functions
    // =================================================================================================================

    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}


/**
    BancorSmartToken
*/
contract LimitedTransferBancorSmartToken is MintableToken, ISmartToken, LimitedTransferToken {

    // =================================================================================================================
    //                                      Modifiers
    // =================================================================================================================

    /**
     * @dev Throws if destroy flag is not enabled.
     */
    modifier canDestroy() {
        require(destroyEnabled);
        _;
    }

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    // We add this flag to avoid users and owner from destroy tokens during crowdsale,
    // This flag is set to false by default and blocks destroy function,
    // We enable destroy option on finalize, so destroy will be possible after the crowdsale.
    bool public destroyEnabled = false;

    // =================================================================================================================
    //                                      Public Functions
    // =================================================================================================================

    function setDestroyEnabled(bool _enable) onlyOwner public {
        destroyEnabled = _enable;
    }

    // =================================================================================================================
    //                                      Impl ISmartToken
    // =================================================================================================================

    //@Override
    function disableTransfers(bool _disable) onlyOwner public {
        transfersEnabled = !_disable;
    }

    //@Override
    function issue(address _to, uint256 _amount) onlyOwner public {
        require(super.mint(_to, _amount));
         Issuance(_amount);
    }

    //@Override
    function destroy(address _from, uint256 _amount) canDestroy public {

        require(msg.sender == _from || msg.sender == owner); // validate input

        balances[_from] = balances[_from].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);

         Destruction(_amount);
         Transfer(_from, 0x0, _amount);
    }

    // =================================================================================================================
    //                                      Impl LimitedTransferToken
    // =================================================================================================================


    // Enable/Disable token transfer
    // Tokens will be locked in their wallets until the end of the Crowdsale.
    // @holder - token`s owner
    // @time - not used (framework unneeded functionality)
    //
    // @Override
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        require(transfersEnabled);
        return super.transferableTokens(holder, time);
    }
}




/**
  A Token which is &#39;Bancor&#39; compatible and can mint new tokens and pause token-transfer functionality
*/
contract BitMEDSmartToken is LimitedTransferBancorSmartToken {

    // =================================================================================================================
    //                                         Members
    // =================================================================================================================

    string public constant name = "BitMED";

    string public constant symbol = "BXM";

    uint8 public constant decimals = 18;

    // =================================================================================================================
    //                                         Constructor
    // =================================================================================================================

    function BitMEDSmartToken() public {
        //Apart of &#39;Bancor&#39; computability - triggered when a smart token is deployed
         NewSmartToken(address(this));
    }
}


/**
 * @title Vault
 * @dev This wallet is used to
 */
contract Vault is Claimable {
    using SafeMath for uint256;

    // =================================================================================================================
    //                                      Enums
    // =================================================================================================================

    enum State { KycPending, KycComplete }

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================
    mapping (address => uint256) public depositedETH;
    mapping (address => uint256) public depositedToken;

    BitMEDSmartToken public token;
    State public state;

    // =================================================================================================================
    //                                      Events
    // =================================================================================================================

    event KycPending();
    event KycComplete();
    event Deposit(address indexed beneficiary, uint256 etherWeiAmount, uint256 tokenWeiAmount);
    event RemoveSupporter(address beneficiary);
    event TokensClaimed(address indexed beneficiary, uint256 weiAmount);
    // =================================================================================================================
    //                                      Modifiers
    // =================================================================================================================

    modifier isKycPending() {
        require(state == State.KycPending);
        _;
    }

    modifier isKycComplete() {
        require(state == State.KycComplete);
        _;
    }


    // =================================================================================================================
    //                                      Ctors
    // =================================================================================================================

    function Vault(BitMEDSmartToken _token) public {
        require(_token != address(0));

        token = _token;
        state = State.KycPending;
         KycPending();
    }

    // =================================================================================================================
    //                                      Public Functions
    // =================================================================================================================

    function deposit(address supporter, uint256 tokensAmount, uint256 value) isKycPending onlyOwner public{

        depositedETH[supporter] = depositedETH[supporter].add(value);
        depositedToken[supporter] = depositedToken[supporter].add(tokensAmount);

         Deposit(supporter, value, tokensAmount);
    }

    function kycComplete() isKycPending onlyOwner public {
        state = State.KycComplete;
         KycComplete();
    }

    //@dev Remove a supporter and refund ether back to the supporter in returns of proportional amount of BXM back to the BitMED`s wallet
    function removeSupporter(address supporter) isKycPending onlyOwner public {
        require(supporter != address(0));
        require(depositedETH[supporter] > 0);
        require(depositedToken[supporter] > 0);

        uint256 depositedTokenValue = depositedToken[supporter];
        uint256 depositedETHValue = depositedETH[supporter];

        //zero out the user
        depositedETH[supporter] = 0;
        depositedToken[supporter] = 0;

        token.destroy(address(this),depositedTokenValue);
        // We will manually refund the money. Checking against OFAC sanction list
        // https://sanctionssearch.ofac.treas.gov/
        //supporter.transfer(depositedETHValue - 21000);

         RemoveSupporter(supporter);
    }

    //@dev Transfer tokens from the vault to the supporter while releasing proportional amount of ether to BitMED`s wallet.
    //Can be triggerd by the supporter only
    function claimTokens(uint256 tokensToClaim) isKycComplete public {
        require(tokensToClaim != 0);

        address supporter = msg.sender;
        require(depositedToken[supporter] > 0);

        uint256 depositedTokenValue = depositedToken[supporter];
        uint256 depositedETHValue = depositedETH[supporter];

        require(tokensToClaim <= depositedTokenValue);

        uint256 claimedETH = tokensToClaim.mul(depositedETHValue).div(depositedTokenValue);

        assert(claimedETH > 0);

        depositedETH[supporter] = depositedETHValue.sub(claimedETH);
        depositedToken[supporter] = depositedTokenValue.sub(tokensToClaim);

        token.transfer(supporter, tokensToClaim);

         TokensClaimed(supporter, tokensToClaim);
    }

    //@dev Transfer tokens from the vault to the supporter
    //Can be triggerd by the owner of the vault
    function claimAllSupporterTokensByOwner(address supporter) isKycComplete onlyOwner public {
        uint256 depositedTokenValue = depositedToken[supporter];
        require(depositedTokenValue > 0);
        token.transfer(supporter, depositedTokenValue);
         TokensClaimed(supporter, depositedTokenValue);
    }

    // @dev supporter can claim tokens by calling the function
    // @param tokenToClaimAmount - amount of the token to claim
    function claimAllTokens() isKycComplete public  {
        uint256 depositedTokenValue = depositedToken[msg.sender];
        claimTokens(depositedTokenValue);
    }


}


/**
 * @title RefundVault
 * @dev This contract is used for storing TOKENS AND ETHER while a crowd sale is in progress for a period of 3 DAYS.
 * Supporter can ask for a full/part refund for his/her ether against token. Once tokens are Claimed by the supporter, they cannot be refunded.
 * After 3 days, all ether will be withdrawn from the vault`s wallet, leaving all tokens to be claimed by the their owners.
 **/
contract RefundVault is Claimable {
    using SafeMath for uint256;

    // =================================================================================================================
    //                                      Enums
    // =================================================================================================================

    enum State { Active, Refunding, Closed }

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    // Refund time frame
    uint256 public constant REFUND_TIME_FRAME = 3 days;

    mapping (address => uint256) public depositedETH;
    mapping (address => uint256) public depositedToken;

    address public etherWallet;
    BitMEDSmartToken public token;
    State public state;
    uint256 public refundStartTime;

    // =================================================================================================================
    //                                      Events
    // =================================================================================================================

    event Active();
    event Closed();
    event Deposit(address indexed beneficiary, uint256 etherWeiAmount, uint256 tokenWeiAmount);
    event RefundsEnabled();
    event RefundedETH(address beneficiary, uint256 weiAmount);
    event TokensClaimed(address indexed beneficiary, uint256 weiAmount);

    // =================================================================================================================
    //                                      Modifiers
    // =================================================================================================================

    modifier isActiveState() {
        require(state == State.Active);
        _;
    }

    modifier isRefundingState() {
        require(state == State.Refunding);
        _;
    }

    modifier isCloseState() {
        require(state == State.Closed);
        _;
    }

    modifier isRefundingOrCloseState() {
        require(state == State.Refunding || state == State.Closed);
        _;
    }

    modifier  isInRefundTimeFrame() {
        require(refundStartTime <= block.timestamp && refundStartTime + REFUND_TIME_FRAME > block.timestamp);
        _;
    }

    modifier isRefundTimeFrameExceeded() {
        require(refundStartTime + REFUND_TIME_FRAME < block.timestamp);
        _;
    }


    // =================================================================================================================
    //                                      Ctors
    // =================================================================================================================

    function RefundVault(address _etherWallet, BitMEDSmartToken _token) public {
        require(_etherWallet != address(0));
        require(_token != address(0));

        etherWallet = _etherWallet;
        token = _token;
        state = State.Active;
         Active();
    }

    // =================================================================================================================
    //                                      Public Functions
    // =================================================================================================================

    function deposit(address supporter, uint256 tokensAmount) isActiveState onlyOwner public payable {

        depositedETH[supporter] = depositedETH[supporter].add(msg.value);
        depositedToken[supporter] = depositedToken[supporter].add(tokensAmount);

         Deposit(supporter, msg.value, tokensAmount);
    }

    function close() isRefundingState onlyOwner isRefundTimeFrameExceeded public {
        state = State.Closed;
         Closed();
        etherWallet.transfer(address(this).balance);
    }

    function enableRefunds() isActiveState onlyOwner public {
        state = State.Refunding;
        refundStartTime = block.timestamp;

         RefundsEnabled();
    }

    //@dev Refund ether back to the supporter in returns of proportional amount of BXM back to the BitMED`s wallet
    function refundETH(uint256 ETHToRefundAmountWei) isInRefundTimeFrame isRefundingState public {
        require(ETHToRefundAmountWei != 0);

        uint256 depositedTokenValue = depositedToken[msg.sender];
        uint256 depositedETHValue = depositedETH[msg.sender];

        require(ETHToRefundAmountWei <= depositedETHValue);

        uint256 refundTokens = ETHToRefundAmountWei.mul(depositedTokenValue).div(depositedETHValue);

        assert(refundTokens > 0);

        depositedETH[msg.sender] = depositedETHValue.sub(ETHToRefundAmountWei);
        depositedToken[msg.sender] = depositedTokenValue.sub(refundTokens);

        token.destroy(address(this),refundTokens);
        msg.sender.transfer(ETHToRefundAmountWei);

         RefundedETH(msg.sender, ETHToRefundAmountWei);
    }

    //@dev Transfer tokens from the vault to the supporter while releasing proportional amount of ether to BitMED`s wallet.
    //Can be triggerd by the supporter only
    function claimTokens(uint256 tokensToClaim) isRefundingOrCloseState public {
        require(tokensToClaim != 0);

        address supporter = msg.sender;
        require(depositedToken[supporter] > 0);

        uint256 depositedTokenValue = depositedToken[supporter];
        uint256 depositedETHValue = depositedETH[supporter];

        require(tokensToClaim <= depositedTokenValue);

        uint256 claimedETH = tokensToClaim.mul(depositedETHValue).div(depositedTokenValue);

        assert(claimedETH > 0);

        depositedETH[supporter] = depositedETHValue.sub(claimedETH);
        depositedToken[supporter] = depositedTokenValue.sub(tokensToClaim);

        token.transfer(supporter, tokensToClaim);
        if(state != State.Closed) {
            etherWallet.transfer(claimedETH);
        }

         TokensClaimed(supporter, tokensToClaim);
    }

    //@dev Transfer tokens from the vault to the supporter while releasing proportional amount of ether to BitMED`s wallet.
    //Can be triggerd by the owner of the vault (in our case - BitMED`s owner after 3 days)
    function claimAllSupporterTokensByOwner(address supporter) isCloseState onlyOwner public {
        uint256 depositedTokenValue = depositedToken[supporter];
        require(depositedTokenValue > 0);


        token.transfer(supporter, depositedTokenValue);

         TokensClaimed(supporter, depositedTokenValue);
    }

    // @dev supporter can claim tokens by calling the function
    // @param tokenToClaimAmount - amount of the token to claim
    function claimAllTokens() isRefundingOrCloseState public  {
        uint256 depositedTokenValue = depositedToken[msg.sender];
        claimTokens(depositedTokenValue);
    }


}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    BitMEDSmartToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;

    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // holding vault for all tokens pending KYC
    Vault public vault;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, BitMEDSmartToken _token, Vault _vault) public {
        require(_startTime >= block.timestamp);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_vault != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        token = _token;
        vault = _vault;
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        require(weiAmount>500000000000000000);

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());

        // update state
        weiRaised = weiRaised.add(weiAmount);

        //send tokens to KYC Vault
        token.issue(address(vault), tokens);

        // Updating arrays in the Vault
        vault.deposit(beneficiary, tokens, msg.value);

         TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        // Transferring funds to wallet
        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

    // @return the crowdsale rate
    function getRate() public view returns (uint256) {
        return rate;
    }
}


/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Claimable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public onlyOwner  {
    require(!isFinalized);
    require(hasEnded());

    finalization();
     Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}



contract BitMEDCrowdsale is FinalizableCrowdsale {

    // =================================================================================================================
    //                                      Constants
    // =================================================================================================================
    // Max amount of known addresses of which will get BXM by &#39;Grant&#39; method.
    //
    // grantees addresses will be BitMED wallets addresses.
    // these wallets will contain BXM tokens that will be used for one purposes only -
    // 1. BXM tokens against raised fiat money
    // we set the value to 10 (and not to 2) because we want to allow some flexibility for cases like fiat money that is raised close
    // to the crowdsale. we limit the value to 10 (and not larger) to limit the run time of the function that process the grantees array.
    uint8 public constant MAX_TOKEN_GRANTEES = 10;

    // BXM to ETH base rate
    uint256 public constant EXCHANGE_RATE = 210;

    // Refund division rate
    uint256 public constant REFUND_DIVISION_RATE = 2;

    // The min BXM tokens that should be minted for the public sale
    uint256 public constant MIN_TOKEN_SALE = 125000000000000000000000000;


    // =================================================================================================================
    //                                      Modifiers
    // =================================================================================================================

    /**
     * @dev Throws if called not during the crowdsale time frame
     */
    modifier onlyWhileSale() {
        require(isActive());
        _;
    }

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    // wallets address for 75% of BXM allocation
    address public walletTeam;      //10% of the total number of BXM tokens will be allocated to the team
    address public walletReserve;   //35% of the total number of BXM tokens will be allocated to BitMED  and as a reserve for the company to be used for future strategic plans for the created ecosystem
    address public walletCommunity; //30% of the total number of BXM tokens will be allocated to Community

    // Funds collected outside the crowdsale in wei
    uint256 public fiatRaisedConvertedToWei;

    //Grantees - used for non-ether and presale bonus token generation
    address[] public presaleGranteesMapKeys;
    mapping (address => uint256) public presaleGranteesMap;  //address=>wei token amount

    // The refund vault
    RefundVault public refundVault;

    // =================================================================================================================
    //                                      Events
    // =================================================================================================================
    event GrantAdded(address indexed _grantee, uint256 _amount);

    event GrantUpdated(address indexed _grantee, uint256 _oldAmount, uint256 _newAmount);

    event GrantDeleted(address indexed _grantee, uint256 _hadAmount);

    event FiatRaisedUpdated(address indexed _address, uint256 _fiatRaised);

    event TokenPurchaseWithGuarantee(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // =================================================================================================================
    //                                      Constructors
    // =================================================================================================================

    function BitMEDCrowdsale(uint256 _startTime,
    uint256 _endTime,
    address _wallet,
    address _walletTeam,
    address _walletCommunity,
    address _walletReserve,
    BitMEDSmartToken _BitMEDSmartToken,
    RefundVault _refundVault,
    Vault _vault)

    public Crowdsale(_startTime, _endTime, EXCHANGE_RATE, _wallet, _BitMEDSmartToken, _vault) {
        require(_walletTeam != address(0));
        require(_walletCommunity != address(0));
        require(_walletReserve != address(0));
        require(_BitMEDSmartToken != address(0));
        require(_refundVault != address(0));
        require(_vault != address(0));

        walletTeam = _walletTeam;
        walletCommunity = _walletCommunity;
        walletReserve = _walletReserve;

        token = _BitMEDSmartToken;
        refundVault  = _refundVault;

        vault = _vault;

    }

    // =================================================================================================================
    //                                      Impl Crowdsale
    // =================================================================================================================

    // @return the rate in BXM per 1 ETH according to the time of the tx and the BXM pricing program.
    // @Override
    function getRate() public view returns (uint256) {
        if (block.timestamp < (startTime.add(24 hours))) {return 700;}
        if (block.timestamp < (startTime.add(3 days))) {return 600;}
        if (block.timestamp < (startTime.add(5 days))) {return 500;}
        if (block.timestamp < (startTime.add(7 days))) {return 400;}
        if (block.timestamp < (startTime.add(10 days))) {return 350;}
        if (block.timestamp < (startTime.add(13 days))) {return 300;}
        if (block.timestamp < (startTime.add(16 days))) {return 285;}
        if (block.timestamp < (startTime.add(19 days))) {return 270;}
        if (block.timestamp < (startTime.add(22 days))) {return 260;}
        if (block.timestamp < (startTime.add(25 days))) {return 250;}
        if (block.timestamp < (startTime.add(28 days))) {return 240;}
        if (block.timestamp < (startTime.add(31 days))) {return 230;}
        if (block.timestamp < (startTime.add(34 days))) {return 225;}
        if (block.timestamp < (startTime.add(37 days))) {return 220;}
        if (block.timestamp < (startTime.add(40 days))) {return 215;}

        return rate;
    }

    // =================================================================================================================
    //                                      Impl FinalizableCrowdsale
    // =================================================================================================================

    //@Override
    function finalization() internal {

        super.finalization();

        // granting bonuses for the pre crowdsale grantees:
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            token.issue(presaleGranteesMapKeys[i], presaleGranteesMap[presaleGranteesMapKeys[i]]);
        }

        //we want to make sure a min of 125M tokens are generated which equals the 25% of the crowdsale
        if(token.totalSupply() <= MIN_TOKEN_SALE){
            uint256 missingTokens = MIN_TOKEN_SALE - token.totalSupply();
            token.issue(walletCommunity, missingTokens);
        }

        // Adding 75% of the total token supply (25% were generated during the crowdsale)
        // 25 * 4 = 100
        uint256 newTotalSupply = token.totalSupply().mul(400).div(100);

        // 10% of the total number of BXM tokens will be allocated to the team
        token.issue(walletTeam, newTotalSupply.mul(10).div(100));

        // 30% of the total number of BXM tokens will be allocated to community
        token.issue(walletCommunity, newTotalSupply.mul(30).div(100));

        // 35% of the total number of BXM tokens will be allocated to BitMED ,
        // and as a reserve for the company to be used for future strategic plans for the created ecosystem
        token.issue(walletReserve, newTotalSupply.mul(35).div(100));

        // Re-enable transfers after the token sale.
        token.disableTransfers(false);

        // Re-enable destroy function after the token sale.
        token.setDestroyEnabled(true);

        // Enable ETH refunds and token claim.
        refundVault.enableRefunds();

        // transfer token ownership to crowdsale owner
        token.transferOwnership(owner);

        // transfer refundVault ownership to crowdsale owner
        refundVault.transferOwnership(owner);

        vault.transferOwnership(owner);

    }

    // =================================================================================================================
    //                                      Public Methods
    // =================================================================================================================
    // @return the total funds collected in wei(ETH and none ETH).
    function getTotalFundsRaised() public view returns (uint256) {
        return fiatRaisedConvertedToWei.add(weiRaised);
    }

    // @return true if the crowdsale is active, hence users can buy tokens
    function isActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp < endTime;
    }

    // =================================================================================================================
    //                                      External Methods
    // =================================================================================================================
    // @dev Adds/Updates address and token allocation for token grants.
    // Granted tokens are allocated to non-ether, presale, buyers.
    // @param _grantee address The address of the token grantee.
    // @param _value uint256 The value of the grant in wei token.
    function addUpdateGrantee(address _grantee, uint256 _value) external onlyOwner onlyWhileSale{
        require(_grantee != address(0));
        require(_value > 0);

        // Adding new key if not present:
        if (presaleGranteesMap[_grantee] == 0) {
            require(presaleGranteesMapKeys.length < MAX_TOKEN_GRANTEES);
            presaleGranteesMapKeys.push(_grantee);
            GrantAdded(_grantee, _value);
        }
        else {
            GrantUpdated(_grantee, presaleGranteesMap[_grantee], _value);
        }

        presaleGranteesMap[_grantee] = _value;
    }

    // @dev deletes entries from the grants list.
    // @param _grantee address The address of the token grantee.
    function deleteGrantee(address _grantee) external onlyOwner onlyWhileSale {
    require(_grantee != address(0));
        require(presaleGranteesMap[_grantee] != 0);

        //delete from the map:
        delete presaleGranteesMap[_grantee];

        //delete from the array (keys):
        uint256 index;
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            if (presaleGranteesMapKeys[i] == _grantee) {
                index = i;
                break;
            }
        }
        presaleGranteesMapKeys[index] = presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        delete presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        presaleGranteesMapKeys.length--;

        GrantDeleted(_grantee, presaleGranteesMap[_grantee]);
    }

    // @dev Set funds collected outside the crowdsale in wei.
    //  note: we not to use accumulator to allow flexibility in case of humane mistakes.
    // funds are converted to wei using the market conversion rate of USD\ETH on the day on the purchase.
    // @param _fiatRaisedConvertedToWei number of none eth raised.
    function setFiatRaisedConvertedToWei(uint256 _fiatRaisedConvertedToWei) external onlyOwner onlyWhileSale {
        fiatRaisedConvertedToWei = _fiatRaisedConvertedToWei;
        FiatRaisedUpdated(msg.sender, fiatRaisedConvertedToWei);
    }

    /// @dev Accepts new ownership on behalf of the BitMEDCrowdsale contract. This can be used, by the token sale
    /// contract itself to claim back ownership of the BitMEDSmartToken contract.
    function claimTokenOwnership() external onlyOwner {
        token.claimOwnership();
    }

    /// @dev Accepts new ownership on behalf of the BitMEDCrowdsale contract. This can be used, by the token sale
    /// contract itself to claim back ownership of the refundVault contract.
    function claimRefundVaultOwnership() external onlyOwner {
        refundVault.claimOwnership();
    }

    /// @dev Accepts new ownership on behalf of the BitMEDCrowdsale contract. This can be used, by the token sale
    /// contract itself to claim back ownership of the refundVault contract.
    function claimVaultOwnership() external onlyOwner {
        vault.claimOwnership();
    }

    // @dev Buy tokes with guarantee
    function buyTokensWithGuarantee() public payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;

        require(weiAmount>500000000000000000);

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());
        tokens = tokens.div(REFUND_DIVISION_RATE);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.issue(address(refundVault), tokens);
        refundVault.deposit.value(msg.value)(msg.sender, tokens);

        TokenPurchaseWithGuarantee(msg.sender, address(refundVault), weiAmount, tokens);
    }
}