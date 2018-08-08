pragma solidity ^0.4.21;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}





/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}





/**
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}






/// @title SUC Protocol Token.
contract SUCToken is StandardToken {
    string public constant NAME = "SUPPLYCHAIN";
    string public constant SYMBOL = "SUC";
    uint public constant DECIMALS = 18;

    /// During token sale, we use one consistent price: 50000 SUC/ETH.
    /// We split the entire token sale period into 3 phases, each
    /// phase has a different bonus setting as specified in `bonusPercentages`.
    /// The real price for phase i is `(1 + bonusPercentages[i]/100.0) * BASE_RATE`.
    /// The first phase or early-bird phase has a much higher bonus.
    uint8[10] public bonusPercentages = [
        20,
        10,
        0
    ];

    uint public constant NUM_OF_PHASE = 3;
  
    /// Each phase contains exactly 29000 Ethereum blocks, which is roughly 7 days,
    /// which makes this 3-phase sale period roughly 21 days.
    uint16 public constant BLOCKS_PER_PHASE = 29000;

    /// This is where we hold ETH during this token sale. We will not transfer any Ether
    /// out of this address before we invocate the `close` function to finalize the sale. 
    /// This promise is not guanranteed by smart contract by can be verified with public
    /// Ethereum transactions data available on several blockchain browsers.
    /// This is the only address from which `start` and `close` can be invocated.
    /// Note: this will be initialized during the contract deployment.
    address public target;

    /// `firstblock` specifies from which block our token sale starts.
    /// This can only be modified once by the owner of `target` address.
    uint public firstblock = 0;

    /// Indicates whether unsold token have been issued. This part of SUC token
    /// is managed by the project team and is issued directly to `target`.
    bool public unsoldTokenIssued = false;

    /// Minimum amount of funds to be raised for the sale to succeed. 
    uint256 public constant GOAL = 5000 ether;

    /// Maximum amount of fund to be raised, the sale ends on reaching this amount.
    uint256 public constant HARD_CAP = 10000 ether;

    /// Base exchange rate is set to 1 ETH = 50000 SUC.
    uint256 public constant BASE_RATE = 50000;

    /// A simple stat for emitting events.
    uint public totalEthReceived = 0;

    /// Issue event index starting from 0.
    uint public issueIndex = 0;

    /* 
     * EVENTS
     */

    /// Emitted only once after token sale starts.
    event SaleStarted();

    /// Emitted only once after token sale ended (all token issued).
    event SaleEnded();

    /// Emitted when a function is invocated by unauthorized addresses.
    event InvalidCaller(address caller);

    /// Emitted when a function is invocated without the specified preconditions.
    /// This event will not come alone with an exception.
    event InvalidState(bytes msg);

    /// Emitted for each sucuessful token purchase.
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

    /// Emitted if the token sale succeeded.
    event SaleSucceeded();

    /// Emitted if the token sale failed.
    /// When token sale failed, all Ether will be return to the original purchasing
    /// address with a minor deduction of transaction fee（gas)
    event SaleFailed();

    /*
     * MODIFIERS
     */

    modifier onlyOwner {
        if (target == msg.sender) {
            _;
        } else {
            InvalidCaller(msg.sender);
            throw;
        }
    }

    modifier beforeStart {
        if (!saleStarted()) {
            _;
        } else {
            InvalidState("Sale has not started yet");
            throw;
        }
    }

    modifier inProgress {
        if (saleStarted() && !saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not in progress");
            throw;
        }
    }

    modifier afterEnd {
        if (saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not ended yet");
            throw;
        }
    }

    /**
     * CONSTRUCTOR 
     * 
     * @dev Initialize the SUC Token
     * @param _target The escrow account address
     */
    function SUCToken(address _target) {
        target = _target;
        totalSupply = 10 ** 27;
        balances[target] = totalSupply;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev Start the token sale.
    /// @param _firstblock The block from which the sale will start.
    function start(uint _firstblock) public onlyOwner beforeStart {
        if (_firstblock <= block.number) {
            // Must specify a block in the future.
            throw;
        }

        firstblock = _firstblock;
        SaleStarted();
    }

    /// @dev Triggers unsold tokens to be issued to `target` address.
    function close() public onlyOwner afterEnd {
        if (totalEthReceived < GOAL) {
            SaleFailed();
        } else {
            SaleSucceeded();
        }
    }

    /// @dev Returns the current price.
    function price() public constant returns (uint tokens) {
        return computeTokenAmount(1 ether);
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () payable {
        issueToken(msg.sender);
    }

    /// @dev Issue token based on Ether received.
    /// @param recipient Address that newly issued token will be sent to.
    function issueToken(address recipient) payable inProgress {
        // We only accept minimum purchase of 0.01 ETH.
        assert(msg.value >= 0.01 ether);

        // We only accept maximum purchase of 10000 ETH.
        assert(msg.value <= 10000 ether);

        // We only accept totalEthReceived < HARD_CAP
        uint ethReceived = totalEthReceived + msg.value;
        assert(ethReceived <= HARD_CAP);

        uint tokens = computeTokenAmount(msg.value);
        totalEthReceived = totalEthReceived.add(msg.value);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[target] = balances[target].sub(tokens);

        Issue(
            issueIndex++,
            recipient,
            msg.value,
            tokens
        );

        if (!target.send(msg.value)) {
            throw;
        }
    }

    /*
     * INTERNAL FUNCTIONS
     */
  
    /// @dev Compute the amount of SUC token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase SUC.
    /// @return Amount of SUC token to purchase
    function computeTokenAmount(uint ethAmount) internal constant returns (uint tokens) {
        uint phase = (block.number - firstblock).div(BLOCKS_PER_PHASE);

        // A safe check
        if (phase >= bonusPercentages.length) {
            phase = bonusPercentages.length - 1;
        }

        uint tokenBase = ethAmount.mul(BASE_RATE);
        uint tokenBonus = tokenBase.mul(bonusPercentages[phase]).div(100);

        tokens = tokenBase.add(tokenBonus);
    }

    /// @return true if sale has started, false otherwise.
    function saleStarted() constant returns (bool) {
        return (firstblock > 0 && block.number >= firstblock);
    }

    /// @return true if sale has ended, false otherwise.
    function saleEnded() constant returns (bool) {
        return firstblock > 0 && (saleDue() || hardCapReached());
    }

    /// @return true if sale is due when the last phase is finished.
    function saleDue() constant returns (bool) {
        return block.number >= firstblock + BLOCKS_PER_PHASE * NUM_OF_PHASE;
    }

    /// @return true if the hard cap is reached.
    function hardCapReached() constant returns (bool) {
        return totalEthReceived >= HARD_CAP;
    }
}