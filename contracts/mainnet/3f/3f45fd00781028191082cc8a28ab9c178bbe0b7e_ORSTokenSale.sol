pragma solidity 0.4.23;

// File: eidoo-icoengine/contracts/ICOEngineInterface.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/KYCBase.sol

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
    function releaseTokensTo(address buyer, address signer) internal returns(bool);

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
            return releaseTokensTo(buyerAddress, signer);
        }
    }

    // No payable fallback function, the tokens must be buyed using the functions buyTokens and buyTokensFor
    function () public {
        revert();
    }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

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
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/PausableToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol

/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

// File: contracts/ORSToken.sol

/// @title ORSToken
/// @author Sicos et al.
contract ORSToken is CappedToken, StandardBurnableToken, PausableToken {

    string public name = "ORS Token";
    string public symbol = "ORS";
    uint8 public decimals = 18;

    /// @dev Constructor
    /// @param _cap Maximum number of integral token units; total supply must never exceed this limit
    constructor(uint _cap) public CappedToken(_cap) {
        pause();  // Disable token trade
    }

}

// File: contracts/ORSTokenSale.sol

/// @title ORSTokenSale
/// @author Sicos et al.
contract ORSTokenSale is KYCBase, ICOEngineInterface, Ownable {

    using SafeMath for uint;

    // Maximum token amounts of each pool
    // Note: There were 218054209 token sold in PreSale
    // Note: 4193635 Bonus token will be issued to preSale investors
    // Note: PRESALE_CAP = 218054209 PreSale token + 4193635 PreSale Bonus token
    uint constant public PRESALE_CAP = 222247844e18;          // 222,247,844 e18
    uint constant public MAINSALE_CAP = 281945791e18;         // 281,945,791 e18
    // Note: BONUS_CAP should be at least 5% of MAINSALE_CAP
    // Note: BONUS_CAP = 64460000 BONUS token  - 4193635 PreSale Bonus token
    uint constant public BONUS_CAP = 60266365e18;             //  60,266,365 e18

    // Granted token shares that will be minted upon finalization
    uint constant public COMPANY_SHARE = 127206667e18;        // 127,206,667 e18
    uint constant public TEAM_SHARE = 83333333e18;            //  83,333,333 e18
    uint constant public ADVISORS_SHARE = 58333333e18;        //  58,333,333 e18

    // Remaining token amounts of each pool
    uint public presaleRemaining = PRESALE_CAP;
    uint public mainsaleRemaining = MAINSALE_CAP;
    uint public bonusRemaining = BONUS_CAP;

    // Beneficiaries of granted token shares
    address public companyWallet;
    address public advisorsWallet;
    address public bountyWallet;

    ORSToken public token;

    // Integral token units (10^-18 tokens) per wei
    uint public rate;

    // Mainsale period
    uint public openingTime;
    uint public closingTime;

    // Ethereum address where invested funds will be transferred to
    address public wallet;

    // Purchases signed via Eidoo&#39;s platform will receive bonus tokens
    address public eidooSigner;

    bool public isFinalized = false;

    /// @dev Log entry on rate changed
    /// @param newRate New rate in integral token units per wei
    event RateChanged(uint newRate);

    /// @dev Log entry on token purchased
    /// @param buyer Ethereum address of token purchaser
    /// @param value Worth in wei of purchased token amount
    /// @param tokens Number of integral token units
    event TokenPurchased(address indexed buyer, uint value, uint tokens);

    /// @dev Log entry on buyer refunded upon token purchase
    /// @param buyer Ethereum address of token purchaser
    /// @param value Worth of refund of wei
    event BuyerRefunded(address indexed buyer, uint value);

    /// @dev Log entry on finalized
    event Finalized();

    /// @dev Constructor
    /// @param _token An ORSToken
    /// @param _rate Rate in integral token units per wei
    /// @param _openingTime Block (Unix) timestamp of mainsale start time
    /// @param _closingTime Block (Unix) timestamp of mainsale latest end time
    /// @param _wallet Ethereum account who will receive sent ether upon token purchase during mainsale
    /// @param _companyWallet Ethereum account of company who will receive company share upon finalization
    /// @param _advisorsWallet Ethereum account of advisors who will receive advisors share upon finalization
    /// @param _bountyWallet Ethereum account of a wallet that will receive remaining bonus upon finalization
    /// @param _kycSigners List of KYC signers&#39; Ethereum addresses
    constructor(
        ORSToken _token,
        uint _rate,
        uint _openingTime,
        uint _closingTime,
        address _wallet,
        address _companyWallet,
        address _advisorsWallet,
        address _bountyWallet,
        address[] _kycSigners
    )
        public
        KYCBase(_kycSigners)
    {
        require(_token != address(0x0));
        require(_token.cap() == PRESALE_CAP + MAINSALE_CAP + BONUS_CAP + COMPANY_SHARE + TEAM_SHARE + ADVISORS_SHARE);
        require(_rate > 0);
        require(_openingTime > now && _closingTime > _openingTime);
        require(_wallet != address(0x0));
        require(_companyWallet != address(0x0) && _advisorsWallet != address(0x0) && _bountyWallet != address(0x0));
        require(_kycSigners.length >= 2);

        token = _token;
        rate = _rate;
        openingTime = _openingTime;
        closingTime = _closingTime;
        wallet = _wallet;
        companyWallet = _companyWallet;
        advisorsWallet = _advisorsWallet;
        bountyWallet = _bountyWallet;

        eidooSigner = _kycSigners[0];
    }

    /// @dev Set rate, i.e. adjust to changes of fiat/ether exchange rates
    /// @param newRate Rate in integral token units per wei
    function setRate(uint newRate) public onlyOwner {
        require(newRate > 0);

        if (newRate != rate) {
            rate = newRate;

            emit RateChanged(newRate);
        }
    }

    /// @dev Distribute presold tokens and bonus tokens to investors
    /// @param investors List of investors&#39; Ethereum addresses
    /// @param tokens List of integral token amounts each investors will receive
    function distributePresale(address[] investors, uint[] tokens) public onlyOwner {
        require(!isFinalized);
        require(tokens.length == investors.length);

        for (uint i = 0; i < investors.length; ++i) {
            presaleRemaining = presaleRemaining.sub(tokens[i]);

            token.mint(investors[i], tokens[i]);
        }
    }

    /// @dev Finalize, i.e. end token minting phase and enable token trading
    function finalize() public onlyOwner {
        require(ended() && !isFinalized);
        require(presaleRemaining == 0);

        // Distribute granted token shares
        token.mint(companyWallet, COMPANY_SHARE + TEAM_SHARE);
        token.mint(advisorsWallet, ADVISORS_SHARE);

        // There shouldn&#39;t be any remaining presale tokens
        // Remaining mainsale tokens will be lost (i.e. not minted)
        // Remaining bonus tokens will be minted for the benefit of bounty wallet
        if (bonusRemaining > 0) {
            token.mint(bountyWallet, bonusRemaining);
            bonusRemaining = 0;
        }

        // Enable token trade
        token.finishMinting();
        token.unpause();

        isFinalized = true;

        emit Finalized();
    }

    // false if the ico is not started, true if the ico is started and running, true if the ico is completed
    /// @dev Started (as required by Eidoo&#39;s ICOEngineInterface)
    /// @return True iff mainsale start has passed
    function started() public view returns (bool) {
        return now >= openingTime;
    }

    // false if the ico is not started, false if the ico is started and running, true if the ico is completed
    /// @dev Ended (as required by Eidoo&#39;s ICOEngineInterface)
    /// @return True iff mainsale is finished
    function ended() public view returns (bool) {
        // Note: Even though we allow token holders to burn their tokens immediately after purchase, this won&#39;t
        //       affect the early end via "sold out" as mainsaleRemaining is independent of token.totalSupply.
        return now > closingTime || mainsaleRemaining == 0;
    }

    // time stamp of the starting time of the ico, must return 0 if it depends on the block number
    /// @dev Start time (as required by Eidoo&#39;s ICOEngineInterface)
    /// @return Block (Unix) timestamp of mainsale start time
    function startTime() public view returns (uint) {
        return openingTime;
    }

    // time stamp of the ending time of the ico, must retrun 0 if it depends on the block number
    /// @dev End time (as required by Eidoo&#39;s ICOEngineInterface)
    /// @return Block (Unix) timestamp of mainsale latest end time
    function endTime() public view returns (uint) {
        return closingTime;
    }

    // returns the total number of the tokens available for the sale, must not change when the ico is started
    /// @dev Total amount of tokens initially available for purchase during mainsale (excluding bonus tokens)
    /// @return Integral token units
    function totalTokens() public view returns (uint) {
        return MAINSALE_CAP;
    }

    // returns the number of the tokens available for the ico. At the moment that the ico starts it must be
    // equal to totalTokens(), then it will decrease. It is used to calculate the percentage of sold tokens as
    // remainingTokens() / totalTokens()
    /// @dev Remaining amount of tokens available for purchase during mainsale (excluding bonus tokens)
    /// @return Integral token units
    function remainingTokens() public view returns (uint) {
        return mainsaleRemaining;
    }

    // return the price as number of tokens released for each ether
    /// @dev Price (as required by Eidoo&#39;s ICOEngineInterface); actually the inverse of a "price"
    /// @return Rate in integral token units per wei
    function price() public view returns (uint) {
        return rate;
    }

    /// @dev Release purchased tokens to buyers during mainsale (as required by Eidoo&#39;s ICOEngineInterface)
    /// @param buyer Ethereum address of purchaser
    /// @param signer Ethereum address of signer
    /// @return Always true, failures will be indicated by transaction reversal
    function releaseTokensTo(address buyer, address signer) internal returns (bool) {
        require(started() && !ended());

        uint value = msg.value;
        uint refund = 0;

        uint tokens = value.mul(rate);
        uint bonus = 0;

        // (Last) buyer whose purchase would exceed available mainsale tokens will be partially refunded
        if (tokens > mainsaleRemaining) {
            uint valueOfRemaining = mainsaleRemaining.div(rate);

            refund = value.sub(valueOfRemaining);
            value = valueOfRemaining;
            tokens = mainsaleRemaining;
            // Note:
            // To be 100% accurate the buyer should receive only a token amount that corresponds to valueOfRemaining,
            // i.e. tokens = valueOfRemaining.mul(rate), because of mainsaleRemaining may not be a multiple of rate
            // (due to regular adaption to the ether/fiat exchange rate).
            // Nevertheless, we deliver all mainsaleRemaining tokens as the worth of these additional tokens at time
            // of purchase is less than a wei and the gas costs of a correct solution, i.e. calculate value * rate
            // again, would exceed this by several orders of magnitude.
        }

        // Purchases signed via Eidoo&#39;s platform will receive additional 5% bonus tokens
        if (signer == eidooSigner) {
            bonus = tokens.div(20);
        }

        mainsaleRemaining = mainsaleRemaining.sub(tokens);
        bonusRemaining = bonusRemaining.sub(bonus);

        token.mint(buyer, tokens.add(bonus));
        wallet.transfer(value);
        if (refund > 0) {
            buyer.transfer(refund);

            emit BuyerRefunded(buyer, refund);
        }

        emit TokenPurchased(buyer, value, tokens.add(bonus));

        return true;
    }

}