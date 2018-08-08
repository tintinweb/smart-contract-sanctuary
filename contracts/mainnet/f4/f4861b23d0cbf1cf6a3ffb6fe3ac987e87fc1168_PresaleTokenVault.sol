//File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol
pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

//File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol
pragma solidity ^0.4.18;




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//File: node_modules/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol
pragma solidity ^0.4.18;





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

//File: node_modules/zeppelin-solidity/contracts/math/SafeMath.sol
pragma solidity ^0.4.18;


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

//File: node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol
pragma solidity ^0.4.18;


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

//File: node_modules/zeppelin-solidity/contracts/token/ERC20/TokenVesting.sol
pragma solidity ^0.4.18;







/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

//File: node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol
pragma solidity ^0.4.18;





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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

//File: node_modules/zeppelin-solidity/contracts/ownership/CanReclaimToken.sol
pragma solidity ^0.4.18;






/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

//File: src/contracts/ico/KYCBase.sol
pragma solidity ^0.4.19;




// Abstract base contract
contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    function KYCBase(address [] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

    // Must be implemented in descending contract to assign tokens to the buyers. Called after the KYC verification is passed
    function releaseTokensTo(address buyer) internal returns(bool);

    // This method can be overridden to enable some sender to buy token for a different address
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
        // check the signature
        bytes32 hash = sha256("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount);
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
        return true;
    }

    // No payable fallback function, the tokens must be buyed using the functions buyTokens and buyTokensFor
    function () public {
        revert();
    }
}
//File: src/contracts/ico/ICOEngineInterface.sol
pragma solidity ^0.4.19;


contract ICOEngineInterface {

    // false if the ico is not started, true if the ico is started and running, true if the ico is completed
    function started() public view returns(bool);

    // false if the ico is not started, false if the ico is started and running, true if the ico is completed
    function ended() public view returns(bool);

    // time stamp of the starting time of the ico, must return 0 if it depends on the block number
    function startTime() public view returns(uint);

    // time stamp of the ending time of the ico, must retrun 0 if it depends on the block number
    function endTime() public view returns(uint);

    // Optional function, can be implemented in place of startTime
    // Returns the starting block number of the ico, must return 0 if it depends on the time stamp
    // function startBlock() public view returns(uint);

    // Optional function, can be implemented in place of endTime
    // Returns theending block number of the ico, must retrun 0 if it depends on the time stamp
    // function endBlock() public view returns(uint);

    // returns the total number of the tokens available for the sale, must not change when the ico is started
    function totalTokens() public view returns(uint);

    // returns the number of the tokens available for the ico. At the moment that the ico starts it must be equal to totalTokens(),
    // then it will decrease. It is used to calculate the percentage of sold tokens as remainingTokens() / totalTokens()
    function remainingTokens() public view returns(uint);

    // return the price as number of tokens released for each ether
    function price() public view returns(uint);
}
//File: src/contracts/ico/CrowdsaleBase.sol
/**
 * @title CrowdsaleBase
 * @dev Base crowdsale contract to be inherited by the UacCrowdsale and Reservation contracts.
 *
 * @version 1.0
 * @author Validity Labs AG <<span class="__cf_email__" data-cfemail="0e676068614e786f62676a677a77626f6c7d20617c69">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.19;







contract CrowdsaleBase is Pausable, CanReclaimToken, ICOEngineInterface, KYCBase {

    /*** CONSTANTS ***/
    uint256 public constant USD_PER_TOKEN = 2;                        //
    uint256 public constant USD_PER_ETHER = 795;                      //

    uint256 public start;                                             // ICOEngineInterface
    uint256 public end;                                               // ICOEngineInterface
    uint256 public cap;                                               // ICOEngineInterface
    address public wallet;
    uint256 public tokenPerEth;
    uint256 public availableTokens;                                   // ICOEngineInterface
    address[] public kycSigners;                                      // KYCBase
    bool public capReached;
    uint256 public weiRaised;
    uint256 public tokensSold;

    /**
     * @dev Constructor.
     * @param _start The start time of the sale.
     * @param _end The end time of the sale.
     * @param _cap The maximum amount of tokens to be sold during the sale.
     * @param _wallet The address where funds should be transferred.
     * @param _kycSigners Array of the signers addresses required by the KYCBase constructor, provided by Eidoo.
     * See https://github.com/eidoo/icoengine
     */
    function CrowdsaleBase(
        uint256 _start,
        uint256 _end,
        uint256 _cap,
        address _wallet,
        address[] _kycSigners
    )
        public
        KYCBase(_kycSigners)
    {
        require(_end >= _start);
        require(_cap > 0);

        start = _start;
        end = _end;
        cap = _cap;
        wallet = _wallet;
        tokenPerEth = USD_PER_ETHER.div(USD_PER_TOKEN);
        availableTokens = _cap;
        kycSigners = _kycSigners;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return False if the ico is not started, true if the ico is started and running, true if the ico is completed.
     */
    function started() public view returns(bool) {
        if (block.timestamp >= start) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return False if the ico is not started, false if the ico is started and running, true if the ico is completed.
     */
    function ended() public view returns(bool) {
        if (block.timestamp >= end) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return Timestamp of the ico start time.
     */
    function startTime() public view returns(uint) {
        return start;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return Timestamp of the ico end time.
     */
    function endTime() public view returns(uint) {
        return end;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return The total number of the tokens available for the sale, must not change when the ico is started.
     */
    function totalTokens() public view returns(uint) {
        return cap;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return The number of the tokens available for the ico. At the moment the ico starts it must be equal to totalTokens(),
     * then it will decrease.
     */
    function remainingTokens() public view returns(uint) {
        return availableTokens;
    }

    /**
     * @dev Implements the KYCBase senderAllowedFor function to enable a sender to buy tokens for a different address.
     * @return true.
     */
    function senderAllowedFor(address buyer) internal view returns(bool) {
        require(buyer != address(0));

        return true;
    }

    /**
     * @dev Implements the KYCBase releaseTokensTo function to mint tokens for an investor. Called after the KYC process has passed.
     * @return A bollean that indicates if the operation was successful.
     */
    function releaseTokensTo(address buyer) internal returns(bool) {
        require(validPurchase());

        uint256 overflowTokens;
        uint256 refundWeiAmount;

        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.mul(price());

        if (tokenAmount >= availableTokens) {
            capReached = true;
            overflowTokens = tokenAmount.sub(availableTokens);
            tokenAmount = tokenAmount.sub(overflowTokens);
            refundWeiAmount = overflowTokens.div(price());
            weiAmount = weiAmount.sub(refundWeiAmount);
            buyer.transfer(refundWeiAmount);
        }

        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
        availableTokens = availableTokens.sub(tokenAmount);
        mintTokens(buyer, tokenAmount);
        forwardFunds(weiAmount);

        return true;
    }

    /**
     * @dev Fired by the releaseTokensTo function after minting tokens, to forward the raised wei to the address that collects funds.
     * @param _weiAmount Amount of wei send by the investor.
     */
    function forwardFunds(uint256 _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }

    /**
     * @dev Validates an incoming purchase. Required statements revert state when conditions are not met.
     * @return true If the transaction can buy tokens.
     */
    function validPurchase() internal view returns (bool) {
        require(!paused && !capReached);
        require(block.timestamp >= start && block.timestamp <= end);

        return true;
    }

    /**
    * @dev Abstract function to mint tokens, to be implemented in the Crowdsale and Reservation contracts.
    * @param to The address that will receive the minted tokens.
    * @param amount The amount of tokens to mint.
    */
    function mintTokens(address to, uint256 amount) private;
}





//File: src/contracts/ico/Reservation.sol
/**
 * @title Reservation
 *
 * @version 1.0
 * @author Validity Labs AG <<span class="__cf_email__" data-cfemail="573e3931381721363b3e333e232e3b36352479382530">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.19;




contract Reservation is CrowdsaleBase {

    /*** CONSTANTS ***/
    uint256 public constant START_TIME = 1525683600;                     // 7 May 2018 09:00:00 GMT
    uint256 public constant END_TIME = 1525856400;                       // 9 May 2018 09:00:00 GMT
    uint256 public constant RESERVATION_CAP = 7.5e6 * 1e18;
    uint256 public constant BONUS = 110;                                 // 10% bonus

    UacCrowdsale public crowdsale;

    /**
     * @dev Constructor.
     * @notice Unsold tokens should add up to the crowdsale hard cap.
     * @param _wallet The address where funds should be transferred.
     * @param _kycSigners Array of the signers addresses required by the KYCBase constructor, provided by Eidoo.
     * See https://github.com/eidoo/icoengine
     */
    function Reservation(
        address _wallet,
        address[] _kycSigners
    )
        public
        CrowdsaleBase(START_TIME, END_TIME, RESERVATION_CAP, _wallet, _kycSigners)
    {
    }

    function setCrowdsale(address _crowdsale) public {
        require(crowdsale == address(0));
        crowdsale = UacCrowdsale(_crowdsale);
    }

    /**
     * @dev Implements the price function from EidooEngineInterface.
     * @notice Calculates the price as tokens/ether based on the corresponding bonus.
     * @return Price as tokens/ether.
     */
    function price() public view returns (uint256) {
        return tokenPerEth.mul(BONUS).div(1e2);
    }

    /**
     * @dev Fires the mintReservationTokens function on the crowdsale contract to mint the tokens being sold during the reservation phase.
     * This function is called by the releaseTokensTo function, as part of the KYCBase implementation.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mintTokens(address to, uint256 amount) private {
        crowdsale.mintReservationTokens(to, amount);
    }
}
//File: node_modules/zeppelin-solidity/contracts/token/ERC20/BasicToken.sol
pragma solidity ^0.4.18;






/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

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

//File: node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol
pragma solidity ^0.4.18;





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
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
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

//File: node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol
pragma solidity ^0.4.18;





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

//File: node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol
pragma solidity ^0.4.18;





/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

//File: src/contracts/ico/UacToken.sol
/**
 * @title Ubiatar Coin token
 *
 * @version 1.0
 * @author Validity Labs AG <<span class="__cf_email__" data-cfemail="30595e565f7046515c59545944495c5152431e5f4257">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.19;





contract UacToken is CanReclaimToken, MintableToken, PausableToken {
    string public constant name = "Ubiatar Coin";
    string public constant symbol = "UAC";
    uint8 public constant decimals = 18;

    /**
     * @dev Constructor of UacToken that instantiates a new Mintable Pausable Token
     */
    function UacToken() public {
        // token should not be transferrable until after all tokens have been issued
        paused = true;
    }
}

//File: src/contracts/ico/UbiatarPlayVault.sol
/**
 * @title UbiatarPlayVault
 * @dev A token holder contract that allows the release of tokens to the UbiatarPlay Wallet.
 *
 * @version 1.0
 * @author Validity Labs AG <<span class="__cf_email__" data-cfemail="442d2a222b043225282d202d303d282526376a2b3623">[email&#160;protected]</span>>
 */

pragma solidity ^0.4.19;







contract UbiatarPlayVault {
    using SafeMath for uint256;
    using SafeERC20 for UacToken;

    uint256[6] public vesting_offsets = [
        90 days,
        180 days,
        270 days,
        360 days,
        540 days,
        720 days
    ];

    uint256[6] public vesting_amounts = [
        2e6 * 1e18,
        4e6 * 1e18,
        6e6 * 1e18,
        8e6 * 1e18,
        10e6 * 1e18,
        20.5e6 * 1e18
    ];

    address public ubiatarPlayWallet;
    UacToken public token;
    uint256 public start;
    uint256 public released;

    /**
     * @dev Constructor.
     * @param _ubiatarPlayWallet The address that will receive the vested tokens.
     * @param _token The UAC Token, which is being vested.
     * @param _start The start time from which each release time will be calculated.
     */
    function UbiatarPlayVault(
        address _ubiatarPlayWallet,
        address _token,
        uint256 _start
    )
        public
    {
        ubiatarPlayWallet = _ubiatarPlayWallet;
        token = UacToken(_token);
        start = _start;
    }

    /**
     * @dev Transfers vested tokens to ubiatarPlayWallet.
     */
    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);

        released = released.add(unreleased);

        token.safeTransfer(ubiatarPlayWallet, unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 vested = 0;

        for (uint256 i = 0; i < vesting_offsets.length; i = i.add(1)) {
            if (block.timestamp > start.add(vesting_offsets[i])) {
                vested = vested.add(vesting_amounts[i]);
            }
        }

        return vested;
    }
}



//File: src/contracts/ico/UacCrowdsale.sol
/**
 * @title UacCrowdsale
 *
 * @version 1.0
 * @author Validity Labs AG <<span class="__cf_email__" data-cfemail="2e474048416e584f42474a475a57424f4c5d00415c49">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.19;









contract UacCrowdsale is CrowdsaleBase {

    /*** CONSTANTS ***/
    uint256 public constant START_TIME = 1525856400;                     // 9 May 2018 09:00:00 GMT
    uint256 public constant END_TIME = 1528448400;                       // 8 June 2018 09:00:00 GMT
    uint256 public constant PRESALE_VAULT_START = END_TIME + 7 days;
    uint256 public constant PRESALE_CAP = 17584778551358900100698693;
    uint256 public constant TOTAL_MAX_CAP = 15e6 * 1e18;                // Reservation plus main sale tokens
    uint256 public constant CROWDSALE_CAP = 7.5e6 * 1e18;
    uint256 public constant FOUNDERS_CAP = 12e6 * 1e18;
    uint256 public constant UBIATARPLAY_CAP = 50.5e6 * 1e18;
    uint256 public constant ADVISORS_CAP = 4915221448641099899301307;

    // Eidoo interface requires price as tokens/ether, therefore the discounts are presented as bonus tokens.
    uint256 public constant BONUS_TIER1 = 108;                           // 8% during first 3 hours
    uint256 public constant BONUS_TIER2 = 106;                           // 6% during next 9 hours
    uint256 public constant BONUS_TIER3 = 104;                           // 4% during next 30 hours
    uint256 public constant BONUS_DURATION_1 = 3 hours;
    uint256 public constant BONUS_DURATION_2 = 12 hours;
    uint256 public constant BONUS_DURATION_3 = 42 hours;

    uint256 public constant FOUNDERS_VESTING_CLIFF = 1 years;
    uint256 public constant FOUNDERS_VESTING_DURATION = 2 years;

    Reservation public reservation;

    // Vesting contracts.
    PresaleTokenVault public presaleTokenVault;
    TokenVesting public foundersVault;
    UbiatarPlayVault public ubiatarPlayVault;

    // Vesting wallets.
    address public foundersWallet;
    address public advisorsWallet;
    address public ubiatarPlayWallet;

    address public wallet;

    UacToken public token;

    // Lets owner manually end crowdsale.
    bool public didOwnerEndCrowdsale;

    /**
     * @dev Constructor.
     * @param _foundersWallet address Wallet holding founders tokens.
     * @param _advisorsWallet address Wallet holding advisors tokens.
     * @param _ubiatarPlayWallet address Wallet holding ubiatarPlay tokens.
     * @param _wallet The address where funds should be transferred.
     * @param _kycSigners Array of the signers addresses required by the KYCBase constructor, provided by Eidoo.
     * See https://github.com/eidoo/icoengine
     */
    function UacCrowdsale(
        address _token,
        address _reservation,
        address _presaleTokenVault,
        address _foundersWallet,
        address _advisorsWallet,
        address _ubiatarPlayWallet,
        address _wallet,
        address[] _kycSigners
    )
        public
        CrowdsaleBase(START_TIME, END_TIME, TOTAL_MAX_CAP, _wallet, _kycSigners)
    {
        token = UacToken(_token);
        reservation = Reservation(_reservation);
        presaleTokenVault = PresaleTokenVault(_presaleTokenVault);
        foundersWallet = _foundersWallet;
        advisorsWallet = _advisorsWallet;
        ubiatarPlayWallet = _ubiatarPlayWallet;
        wallet = _wallet;
        // Create founders vault contract
        foundersVault = new TokenVesting(foundersWallet, END_TIME, FOUNDERS_VESTING_CLIFF, FOUNDERS_VESTING_DURATION, false);

        // Create Ubiatar Play vault contract
        ubiatarPlayVault = new UbiatarPlayVault(ubiatarPlayWallet, address(token), END_TIME);
    }

    function mintPreAllocatedTokens() public onlyOwner {
        mintTokens(address(foundersVault), FOUNDERS_CAP);
        mintTokens(advisorsWallet, ADVISORS_CAP);
        mintTokens(address(ubiatarPlayVault), UBIATARPLAY_CAP);
    }

    /**
     * @dev Creates the presale vault contract.
     * @param beneficiaries Array of the presale investors addresses to whom vested tokens are transferred.
     * @param balances Array of token amount per beneficiary.
     */
    function initPresaleTokenVault(address[] beneficiaries, uint256[] balances) public onlyOwner {
        require(beneficiaries.length == balances.length);

        presaleTokenVault.init(beneficiaries, balances, PRESALE_VAULT_START, token);

        uint256 totalPresaleBalance = 0;
        uint256 balancesLength = balances.length;
        for(uint256 i = 0; i < balancesLength; i++) {
            totalPresaleBalance = totalPresaleBalance.add(balances[i]);
        }

        mintTokens(presaleTokenVault, totalPresaleBalance);
    }

    /**
     * @dev Implements the price function from EidooEngineInterface.
     * @notice Calculates the price as tokens/ether based on the corresponding bonus bracket.
     * @return Price as tokens/ether.
     */
    function price() public view returns (uint256 _price) {
        if (block.timestamp <= start.add(BONUS_DURATION_1)) {
            return tokenPerEth.mul(BONUS_TIER1).div(1e2);
        } else if (block.timestamp <= start.add(BONUS_DURATION_2)) {
            return tokenPerEth.mul(BONUS_TIER2).div(1e2);
        } else if (block.timestamp <= start.add(BONUS_DURATION_3)) {
            return tokenPerEth.mul(BONUS_TIER3).div(1e2);
        }
        return tokenPerEth;
    }

    /**
     * @dev Mints tokens being sold during the reservation phase, as part of the implementation of the releaseTokensTo function
     * from the KYCBase contract.
     * Also, updates tokensSold and availableTokens in the crowdsale contract.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mintReservationTokens(address to, uint256 amount) public {
        require(msg.sender == address(reservation));
        tokensSold = tokensSold.add(amount);
        availableTokens = availableTokens.sub(amount);
        mintTokens(to, amount);
    }

    /**
     * @dev Mints tokens being sold during the crowdsale phase as part of the implementation of releaseTokensTo function
     * from the KYCBase contract.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mintTokens(address to, uint256 amount) private {
        token.mint(to, amount);
    }

    /**
     * @dev Allows the owner to close the crowdsale manually before the end time.
     */
    function closeCrowdsale() public onlyOwner {
        require(block.timestamp >= START_TIME && block.timestamp < END_TIME);
        didOwnerEndCrowdsale = true;
    }

    /**
     * @dev Allows the owner to unpause tokens, stop minting and transfer ownership of the token contract.
     */
    function finalise() public onlyOwner {
        require(didOwnerEndCrowdsale || block.timestamp > end || capReached);
        token.finishMinting();
        token.unpause();

        // Token contract extends CanReclaimToken so the owner can recover any ERC20 token received in this contract by mistake.
        // So far, the owner of the token contract is the crowdsale contract.
        // We transfer the ownership so the owner of the crowdsale is also the owner of the token.
        token.transferOwnership(owner);
    }
}


//File: src/contracts/ico/PresaleTokenVault.sol
/**
 * @title PresaleTokenVault
 * @dev A token holder contract that allows multiple beneficiaries to extract their tokens after a given release time.
 *
 * @version 1.0
 * @author Validity Labs AG <<span class="__cf_email__" data-cfemail="abc2c5cdc4ebddcac7c2cfc2dfd2c7cac9d885c4d9cc">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.17;







contract PresaleTokenVault {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    /*** CONSTANTS ***/
    uint256 public constant VESTING_OFFSET = 90 days;                   // starting of vesting
    uint256 public constant VESTING_DURATION = 180 days;                // duration of vesting

    uint256 public start;
    uint256 public cliff;
    uint256 public end;

    ERC20Basic public token;

    struct Investment {
        address beneficiary;
        uint256 totalBalance;
        uint256 released;
    }

    Investment[] public investments;

    // key: investor address; value: index in investments array.
    mapping(address => uint256) public investorLUT;

    function init(address[] beneficiaries, uint256[] balances, uint256 startTime, address _token) public {
        // makes sure this function is only called once
        require(token == address(0));
        require(beneficiaries.length == balances.length);

        start = startTime;
        cliff = start.add(VESTING_OFFSET);
        end = cliff.add(VESTING_DURATION);

        token = ERC20Basic(_token);

        for (uint256 i = 0; i < beneficiaries.length; i = i.add(1)) {
            investorLUT[beneficiaries[i]] = investments.length;
            investments.push(Investment(beneficiaries[i], balances[i], 0));
        }
    }

    /**
     * @dev Allows a sender to transfer vested tokens to the beneficiary&#39;s address.
     * @param beneficiary The address that will receive the vested tokens.
     */
    function release(address beneficiary) public {
        uint256 unreleased = releasableAmount(beneficiary);
        require(unreleased > 0);

        uint256 investmentIndex = investorLUT[beneficiary];
        investments[investmentIndex].released = investments[investmentIndex].released.add(unreleased);
        token.safeTransfer(beneficiary, unreleased);
    }

    /**
     * @dev Transfers vested tokens to the sender&#39;s address.
     */
    function release() public {
        release(msg.sender);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     * @param beneficiary The address that will receive the vested tokens.
     */
    function releasableAmount(address beneficiary) public view returns (uint256) {
        uint256 investmentIndex = investorLUT[beneficiary];

        return vestedAmount(beneficiary).sub(investments[investmentIndex].released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param beneficiary The address that will receive the vested tokens.
     */
    function vestedAmount(address beneficiary) public view returns (uint256) {

        uint256 investmentIndex = investorLUT[beneficiary];

        uint256 vested = 0;

        if (block.timestamp >= start) {
            // after start -> 1/3 released (fixed)
            vested = investments[investmentIndex].totalBalance.div(3);
        }
        if (block.timestamp >= cliff && block.timestamp < end) {
            // after cliff -> linear vesting over time
            uint256 p1 = investments[investmentIndex].totalBalance.div(3);
            uint256 p2 = investments[investmentIndex].totalBalance;

            /*
              released amount:  r
              1/3:              p1
              all:              p2
              current time:     t
              cliff:            c
              end:              e

              r = p1 +  / d_time * time
                = p1 + (p2-p1) / (e-c) * (t-c)
            */
            uint256 d_token = p2.sub(p1);
            uint256 time = block.timestamp.sub(cliff);
            uint256 d_time = end.sub(cliff);

            vested = vested.add(d_token.mul(time).div(d_time));
        }
        if (block.timestamp >= end) {
            // after end -> all vested
            vested = investments[investmentIndex].totalBalance;
        }
        return vested;
    }
}