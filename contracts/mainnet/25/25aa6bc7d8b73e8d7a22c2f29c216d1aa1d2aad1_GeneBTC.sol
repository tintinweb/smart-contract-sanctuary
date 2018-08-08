pragma solidity ^0.4.13;

/**
 * @title SafeMath
    * @dev Math operations with safety checks that throw on error
       */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
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


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
        * account.
             */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title ERC20Basic
    * @dev Simpler version of ERC20 interface
       * @dev see https://github.com/ethereum/EIPs/issues/179
          */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
    * @dev see https://github.com/ethereum/EIPs/issues/20
       */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
    *
      * @dev Implementation of the basic standard token.
         * @dev https://github.com/ethereum/EIPs/issues/20
            * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
               */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
        * @param _from address The address which you want to send tokens from
             * @param _to address The address which you want to transfer to
                  * @param _value uint256 the amout of tokens to be transfered
                       */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
        * @param _spender The address which will spend the funds.
             * @param _value The amount of tokens to be spent.
                  */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
        * @param _owner address The address which owns the funds.
             * @param _spender address The address which will spend the funds.
                  * @return A uint256 specifing the amount of tokens still avaible for the spender.
                       */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract GeneBTC is StandardToken, Ownable {
    using SafeMath for uint256;

    // Token Info.
    string  public constant name = "Gene BTC";
    string  public constant symbol = "GBC";
    uint8   public constant decimals = 18;

    // Sale period.
    uint256 public startDate;
    uint256 public endDate;

    // Token Cap for each rounds
    uint256 public saleCap;

    // Address where funds are collected.
    address public wallet;

    // Amount of raised money in wei.
    uint256 public weiRaised;

    // GeneBlockChain user ID
    mapping(address => bytes32) public GeneBlockChainUserIDs;

    // Event
    event TokenPurchase(address indexed purchaser, uint256 value,
                        uint256 amount);
    event PreICOTokenPushed(address indexed buyer, uint256 amount);
    event UserIDChanged(address owner, bytes32 user_id);

    // Modifiers
    modifier uninitialized() {
        require(wallet == 0x0);
        _;
    }

    function GeneBTC() {
    }

    function initialize(address _wallet, uint256 _start, uint256 _end,
                        uint256 _saleCap, uint256 _totalSupply)
                        onlyOwner uninitialized {
        require(_start >= getCurrentTimestamp());
        require(_start < _end);
        require(_wallet != 0x0);
        require(_totalSupply > _saleCap);

        startDate = _start;
        endDate = _end;
        saleCap = _saleCap;
        wallet = _wallet;
        totalSupply = _totalSupply;

        balances[wallet] = _totalSupply.sub(saleCap);
        balances[0xb1] = saleCap;
    }

    function supply() internal returns (uint256) {
        return balances[0xb1];
    }

    function getCurrentTimestamp() internal returns (uint256) {
        return now;
    }

    function getRateAt(uint256 at) constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 7 days)) {
            return 840;
        } else if (at < (startDate + 37 days)) {
            return 770;
        } else if (at <= endDate) {
            return 700;
        } else {
            return 0;
        }
    }

    // Fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender, msg.value);
    }

    // For pushing pre-ICO records
    function push(address buyer, uint256 amount) onlyOwner {
        require(balances[wallet] >= amount);

        // Transfer
        balances[wallet] = balances[wallet].sub(amount);
        balances[buyer] = balances[buyer].add(amount);
        PreICOTokenPushed(buyer, amount);
    }

    function buyTokens(address sender, uint256 value) internal {
        require(saleActive());
        require(value >= 0.1 ether);

        uint256 weiAmount = value;
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);

        // Calculate token amount to be purchased
        uint256 actualRate = getRateAt(getCurrentTimestamp());
        uint256 amount = weiAmount.mul(actualRate);

        // We have enough token to sale
        require(supply() >= amount);

        // Transfer
        balances[0xb1] = balances[0xb1].sub(amount);
        balances[sender] = balances[sender].add(amount);
        TokenPurchase(sender, weiAmount, amount);

        // Update state.
        weiRaised = updatedWeiRaised;

        // Forward the fund to fund collection wallet.
        wallet.transfer(msg.value);
    }

    function finalize() onlyOwner {
        require(!saleActive());

        // Transfer the rest of token to GeneBlockChain
        balances[wallet] = balances[wallet].add(balances[0xb1]);
        balances[0xb1] = 0;
    }

    function saleActive() public constant returns (bool) {
        return (getCurrentTimestamp() >= startDate &&
                getCurrentTimestamp() < endDate && supply() > 0);
    }

    function setUserID(bytes32 user_id) {
        GeneBlockChainUserIDs[msg.sender] = user_id;
        UserIDChanged(msg.sender, user_id);
    }
}