pragma solidity ^0.4.21;

// File: contracts\zeppelin-solidity\contracts\ownership\Ownable.sol

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

// File: contracts\zeppelin-solidity\contracts\lifecycle\Pausable.sol

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

// File: contracts\zeppelin-solidity\contracts\math\SafeMath.sol

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

// File: contracts\zeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

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

// File: contracts\zeppelin-solidity\contracts\token\ERC20\BasicToken.sol

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

// File: contracts\zeppelin-solidity\contracts\token\ERC20\BurnableToken.sol

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
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

// File: contracts\zeppelin-solidity\contracts\token\ERC20\ERC20.sol

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

// File: contracts\zeppelin-solidity\contracts\token\ERC20\StandardToken.sol

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

// File: contracts\zeppelin-solidity\contracts\token\ERC20\MintableToken.sol

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

// File: contracts\RECORDToken.sol

/**
 *   RECORD token contract
 */
contract RECORDToken is MintableToken, BurnableToken, Pausable {
    using SafeMath for uint256;
    string public name = "RECORD";
    string public symbol = "RCD";
    uint256 public decimals = 18;

    mapping (address => bool) public lockedAddresses;

    function isAddressLocked(address _adr) internal returns (bool) {
        if (lockedAddresses[_adr] == true) {
            return true;
        } else {
            return false;
        }
    }
    function lockAddress(address _adr) onlyOwner public {
        lockedAddresses[_adr] = true;
    }
    function unlockAddress(address _adr) onlyOwner public {
        delete lockedAddresses[_adr];
    }
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        lockAddress(_to);
        return super.mint(_to, _amount);
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(isAddressLocked(_to) == false);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(isAddressLocked(_from) == false);
        require(isAddressLocked(_to) == false);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(isAddressLocked(_spender) == false);
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        require(isAddressLocked(_spender) == false);
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        require(isAddressLocked(_spender) == false);
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

// File: contracts\RECORDICO.sol

/**
*  takes funds from users and issues tokens
*/
contract RECORDICO {
    // RCD - RECORD token contract
    RECORDToken public RCD = new RECORDToken();
    using SafeMath for uint256;

    // Token price parameters
    // These parametes can be changed only by manager of contract
    uint256 public Rate_Eth = 690; // Rate USD per ETH

    // Crowdfunding parameters
    uint256 public currentInitPart = 0;
    uint256 public constant RECORDPart = 18; // 18% of TotalSupply for Record Team
    uint256 public constant EcosystemPart = 15; // 15% of TotalSupply for Ecosystem
    uint256 public constant InvestorPart = 5; // 5% of TotalSupply for Investors
    uint256 public constant AdvisorPart = 8; // 8% of TotalSupply for Advisors & Ambassadors
    uint256 public constant BountyPart = 4; // 4% of TotalSupply for Bounty
    uint256 public constant icoPart = 50; // 50% of TotalSupply for PublicICO and PrivateOffer
    uint256 public constant PreSaleHardCap = 15000000 * 1e18;
    uint256 public constant RoundAHardCap = 45000000 * 1e18;
    uint256 public constant RoundBHardCap = 45000000 * 1e18;
    uint256 public constant RoundCHardCap = 45000000 * 1e18;
    uint256 public constant totalAmountOnICO = 300000000 * 1e18;

    uint256 public PreSaleSold = 0;
    uint256 public RoundASold = 0;
    uint256 public RoundBSold = 0;
    uint256 public RoundCSold = 0;
    uint256 public EthGet = 0;
    uint256 public RcdGet = 0;

    // Output ethereum addresses
    address Company;
    address Manager; // Manager controls contract

    uint256 public PreSaleStartTime;
    uint256 public PreSaleCloseTime;
    uint256 public IcoStartTime;
    uint256 public IcoCloseTime;

    // Allows execution by the contract manager only
    modifier managerOnly {
        require(msg.sender == Manager);
        _;
    }

    /**
     *   @dev Contract constructor function
     */
    function RECORDICO(
        address _Company,
        address _Manager,
        uint256 _PreSaleStartTime,
        uint256 _PreSaleCloseTime,
        uint256 _IcoStartTime,
        uint256 _IcoCloseTime
    )
    public {
        Company = _Company;
        Manager = _Manager;
        PreSaleStartTime = _PreSaleStartTime;
        PreSaleCloseTime = _PreSaleCloseTime;
        IcoStartTime = _IcoStartTime;
        IcoCloseTime = _IcoCloseTime;
        RCD.pause(); // ICO중에는 token transfer가 되어서는 안된다.
    }

    function getMinMaxInvest() public returns(uint256, uint256) {
        uint256 _min = 0;
        uint256 _max = 0;
        uint256 stage = getStage();
        if (stage == 1) {
            _min = 5000 * 1e18;
            _max = 10000000 * 1e18;
        } else if (stage == 3 || stage == 4 || stage == 5) {
            _min = 5000 * 1e18;
            _max = 50000000 * 1e18;
        }
        return (_min, _max);
    }
    function getRcdExchange(uint256 _ethValue) public returns(uint256, bool) {
        uint256 stage = getStage();
        uint256 _rcdValue = 0;
        uint256 _usdValue = _ethValue.mul(Rate_Eth);
        uint256 _rcdValue_Numerator = _usdValue.mul(1000);
        bool exchangeSuccess = false;
        if (stage == 1 || stage == 3 || stage == 4 || stage == 5 || stage == 6) {
            if (stage == 1) {
                _rcdValue = _rcdValue_Numerator.div(80);
            } else if (stage == 3) {
                _rcdValue = _rcdValue_Numerator.div(90);
            } else if (stage == 4) {
                _rcdValue = _rcdValue_Numerator.div(95);
            } else if (stage == 5) {
                _rcdValue = _rcdValue_Numerator.div(100);
            } else {
                _rcdValue = 0;
            }
        }
        if (_rcdValue > 0) {
            exchangeSuccess = true;
        }
        return (_rcdValue, exchangeSuccess);
    }
    function getStage() public returns(uint256) {
        // 0: 프리세일 전
        // 1: 프리세일 중
        // 2: 프리세일 끝 / ICO 전
        // 3: RoundA
        // 4: RoundB
        // 5: RoundC
        // 6: Finish
        // 0. 프리세일 기간 전
        if (now < PreSaleStartTime) {
            return 0;
        }
        // 1. 프리세일 기간 중
        if (PreSaleStartTime <= now && now <= PreSaleCloseTime) {
            if (PreSaleSold < PreSaleHardCap) {
                return 1;
            } else {
                return 2;
            }
        }
        // 2. 프리세일 기간 끝
        if (PreSaleCloseTime <= now && now <= IcoStartTime) {
            return 2;
        }
        // ICO 기간 중
        if (IcoStartTime <= now && now <= IcoCloseTime) {
            // 3. RoundA
            if (RoundASold < RoundAHardCap) {
                return 3;
            }
            // 4. RoundB
            else if (RoundAHardCap <= RoundASold && RoundBSold < RoundBHardCap) {
                return 4;
            }
            // 5. RoundC
            else if (RoundBHardCap <= RoundBSold && RoundCSold < RoundCHardCap) {
                return 5;
            }
            // 6. Finish
            else {
                return 6;
            }
        }
        // 6. ICO기간 끝
        if (IcoCloseTime < now) {
            return 6;
        }
        return 10;
    }

    /**
     *   @dev Set rate of ETH and update token price
     *   @param _RateEth       current ETH rate
     */
    function setRate(uint256 _RateEth) external managerOnly {
        Rate_Eth = _RateEth;
    }
    function setIcoCloseTime(uint256 _IcoCloseTime) external managerOnly {
        IcoCloseTime = _IcoCloseTime;
    }

    function lockAddress(address _adr) managerOnly external {
        RCD.lockAddress(_adr);
    }

    function unlockAddress(address _adr) managerOnly external {
        RCD.unlockAddress(_adr);
    }

    /**
     *   @dev Enable token transfers
     */
    function unfreeze() external managerOnly {
        RCD.unpause();
    }

    /**
     *   @dev Disable token transfers
     */
    function freeze() external managerOnly {
        RCD.pause();
    }

    /**
     *   @dev Fallback function calls buyTokens() function to buy tokens
     *        when investor sends ETH to address of ICO contract
     */
    function() external payable {
        buyTokens(msg.sender, msg.value);
    }
    /**
     *   @dev Issue tokens for investors who paid in ether
     *   @param _investor     address which the tokens will be issued to
     *   @param _ethValue     number of Ether
     */
    function buyTokens(address _investor, uint256 _ethValue) internal {
        uint256 _rcdValue;
        bool _rcdExchangeSuccess;
        uint256 _min;
        uint256 _max;

        (_rcdValue, _rcdExchangeSuccess) = getRcdExchange(_ethValue);
        (_min, _max) = getMinMaxInvest();
        require (
            _rcdExchangeSuccess == true &&
            _min <= _rcdValue &&
            _rcdValue <= _max
        );
        mintICOTokens(_investor, _rcdValue, _ethValue);
    }
    function mintICOTokens(address _investor, uint256 _rcdValue, uint256 _ethValue) internal{
        uint256 stage = getStage();
        require (
            stage == 1 ||
            stage == 3 ||
            stage == 4 ||
            stage == 5
        );
        if (stage == 1) {
            require(PreSaleSold.add(_rcdValue) <= PreSaleHardCap);
            PreSaleSold = PreSaleSold.add(_rcdValue);
        }
        if (stage == 3) {
            if (RoundASold.add(_rcdValue) <= RoundAHardCap) {
                RoundASold = RoundASold.add(_rcdValue);
            } else {
                RoundBSold = RoundASold.add(_rcdValue) - RoundAHardCap;
                RoundASold = RoundAHardCap;
            }
        }
        if (stage == 4) {
            if (RoundBSold.add(_rcdValue) <= RoundBHardCap) {
                RoundBSold = RoundBSold.add(_rcdValue);
            } else {
                RoundCSold = RoundBSold.add(_rcdValue) - RoundBHardCap;
                RoundBSold = RoundBHardCap;
            }
        }
        if (stage == 5) {
            require(RoundCSold.add(_rcdValue) <= RoundCHardCap);
            RoundCSold = RoundCSold.add(_rcdValue);
        }
        RCD.mint(_investor, _rcdValue);
        RcdGet = RcdGet.add(_rcdValue);
        EthGet = EthGet.add(_ethValue);
    }

    function mintICOTokensFromExternal(address _investor, uint256 _rcdValue) external managerOnly{
        mintICOTokens(_investor, _rcdValue, 0);
    }

    /*
     *   @dev Allows Company withdraw investments when round is over
    */
    function withdrawEther() external managerOnly{
        Company.transfer(address(this).balance);
    }

    function mintInitialTokens(address _adr, uint256 rate) external managerOnly {
        require (currentInitPart.add(rate) <= 50);
        RCD.mint(_adr, rate.mul(totalAmountOnICO).div(100));
        currentInitPart = currentInitPart.add(rate);
    }

    function transferOwnership(address newOwner) external managerOnly{
        RCD.transferOwnership(newOwner);
    }
}