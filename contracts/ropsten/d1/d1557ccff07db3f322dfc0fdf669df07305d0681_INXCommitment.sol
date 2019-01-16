pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
  constructor() public {
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
    emit OwnershipRenounced(owner);
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
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/inx/INXCommitment.sol

/**
* Minimal interface definition for an INX Crowdsale
*/
interface ICrowdsale {
    function kyc(address _address) external returns (bool);
    function wallet() external returns (address);
    function minContribution() external returns (uint256);
    function getCurrentRate() external returns (uint256);
}

/**
* Minimal interface definition for an INX Token
*/
interface IToken {
    function mint(address _to, uint256 _amount) external returns (bool);
}

/**
 * @title INXCommitment used to capture commitments to the INX token sale from an individual address.
 * Once KYC approved can redeem to INX Tokens.
 */
contract INXCommitment is Pausable {
    using SafeMath for uint256;

    address internal sender;

    uint256 internal tokenBalance;

    bool internal refunding = false;

    ICrowdsale internal crowdsale;
    IToken internal token;

    /**
     * Event for token commitment logging
     * @param sender who paid for the tokens
     * @param value weis paid for purchase
     * @param rate of INX to wei
     * @param amount amount of tokens purchased
     */
    event Commit(
        address indexed sender,
        uint256 value,
        uint256 rate,
        uint256 amount
    );

    /**
     * Event for refund of a commitment
     * @param sender who paid for the tokens
     * @param value weis refunded
     */
    event Refund(
        address indexed sender,
        uint256 value
    );

    /**
     * Event for refund toggle
     */
    event RefundToggle(
        bool newValue
    );

    /**
     * Event for successful redemption of a commitment
     * @param sender who paid for the tokens
     * @param value weis refunded
     * @param amount amount of token balance removed
     */
    event Redeem(
        address indexed sender,
        uint256 value,
        uint256 amount
    );

    constructor(address _sender, ICrowdsale _crowdsale, IToken _token) public  {
        sender = _sender;
        crowdsale = _crowdsale;
        token = _token;
    }

    /**
     * @dev fallback function
     */
    function() external payable {
        commit();
    }

    /**
    * @dev Sends a full refund of wei and reset committed tokens to zero
    */
    function refund() external whenNotPaused returns (bool) {
        require(refunding, "Must be in refunding state");

        require(tokenBalance > 0, "Token balance must be positive");

        tokenBalance = 0;

        uint256 refundWeiBalance = address(this).balance;
        sender.transfer(refundWeiBalance);

        emit Refund(
            sender,
            refundWeiBalance
        );

        return true;
    }

    /**
    * @dev if the _sender has a balance and has been KYC then credits the account with balance
    */
    function redeem() external whenNotPaused returns (bool) {
        require(!refunding, "Must not be in refunding state");

        require(tokenBalance > 0, "Token balance must be positive");

        bool kyc = crowdsale.kyc(sender);
        require(kyc, "Sender must have passed KYC");

        uint256 redeemTokenBalance = tokenBalance;
        tokenBalance = 0;

        uint256 redeemWeiBalance = address(this).balance;

        address wallet = crowdsale.wallet();
        wallet.transfer(redeemWeiBalance);

        require(token.mint(sender, redeemTokenBalance), "Unable to mint INX tokens");

        emit Redeem(
            sender,
            redeemWeiBalance,
            redeemTokenBalance
        );

        return true;
    }

    /**
     * @dev captures a commitment to buy tokens at the current rate.
     */
    function commit() public payable whenNotPaused returns (bool) {
        require(!refunding, "Must not be in refunding state");
        require(sender == msg.sender, "Can only commit from the predefined sender address");

        uint256 weiAmount = msg.value;
        uint256 minContribution = crowdsale.minContribution();

        require(weiAmount >= minContribution, "Commitment value below minimum");

        // pull the current rate from the crowdsale
        uint256 rate = crowdsale.getCurrentRate();

        // calculate token amount to be committed
        uint256 tokens = weiAmount.mul(rate);
        tokenBalance = tokenBalance.add(tokens);

        emit Commit(
            sender,
            weiAmount,
            rate,
            tokens
        );

        return true;
    }

    /**
     * @dev token balance of the associated sender
     */
    function senderTokenBalance() public view returns (uint256) {
        return tokenBalance;
    }

    /**
     * @dev wei balance of the associated sender
     */
    function senderWeiBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev associated sender of this contract
     */
    function senderAddress() public view returns (address) {
        return sender;
    }

    /**
     * @dev associated INXCrowdsale
     */
    function inxCrowdsale() public view returns (address) {
        return crowdsale;
    }


    /**
     * @dev associated INXToken
     */
    function inxToken() public view returns (address) {
        return token;
    }


    /**
     * @dev current state of refunding
     */
    function isRefunding() public view returns (bool) {
        return refunding;
    }

    /**
     * @dev Owner can toggle refunding state. Once in refunding anyone can trigger a refund of wei.
     */
    function toggleRefunding() external onlyOwner {
        refunding = !refunding;

        emit RefundToggle(refunding);
    }
}