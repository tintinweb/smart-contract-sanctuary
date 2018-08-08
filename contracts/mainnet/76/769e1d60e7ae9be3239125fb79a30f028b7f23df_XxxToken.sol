pragma solidity ^0.4.11;

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
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract XxxToken is MintableToken {
    // Token Info.
    string public constant name = "XXX Token";
    string public constant symbol = "XXX";
    uint8 public constant decimals = 18;
}

contract XxxTokenSale is Ownable {
    using SafeMath for uint256;

    // Sale period.
    uint256 public startDate;
    uint256 public endDate;

    // Cap USD 25mil @ 200 ETH/USD
    uint256 public cap;

    // Address where funds are collected.
    address public wallet;

    // Amount of raised money in wei.
    uint256 public weiRaised;

    // Actual Token contract
    XxxToken public token;

    // Event
    event TokenPurchase(address indexed purchaser, address indexed beneficiary,
                        uint256 value, uint256 amount);
    event TokenReserveMinted(uint256 amount);

    // Modifiers
    modifier initialized() {
        require(address(token) != 0x0);
        _;
    }

    function XxxTokenSale() {
    }

    function initialize(XxxToken _token, address _wallet,
                        uint256 _start, uint256 _end,
                        uint256 _cap) onlyOwner {
        require(address(token) == address(0));
        require(_token.owner() == address(this));
        require(_start >= getCurrentTimestamp());
        require(_start < _end);
        require(_wallet != 0x0);

        token = _token;
        wallet = _wallet;
        startDate = _start;
        endDate = _end;
        cap = _cap;
    }

    function getCurrentTimestamp() internal returns (uint256) {
        return now;
    }

    // fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender);
    }

    function getRateAt(uint256 at) constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 7 days)) {
            return 2000;
        } else if (at < (startDate + 14 days)) {
            return 1800;
        } else if (at < (startDate + 21 days)) {
            return 1700;
        } else if (at < (startDate + 28 days)) {
            return 1600;
        } else if (at < (startDate + 35 days)) {
            return 1500;
        } else if (at < (startDate + 49 days)) {
            return 1400;
        } else if (at < (startDate + 63 days)) {
            return 1300;
        } else if (at < (startDate + 77 days)) {
            return 1200;
        } else if (at <= endDate) {
            return 1100;
        } else {
            return 0;
        }
    }

    function buyTokens(address beneficiary) payable {
        require(beneficiary != 0x0);
        require(msg.value != 0);
        require(saleActive());

        uint256 weiAmount = msg.value;
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);

        // Can not exceed cap.
        require(updatedWeiRaised <= cap);

        // calculate token amount to be created
        uint256 actualRate = getRateAt(getCurrentTimestamp());
        uint256 tokens = weiAmount.mul(actualRate);

        // Update state.
        weiRaised = updatedWeiRaised;

        // Mint Token and give it to sender.
        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        // Forward the fund to fund collection wallet.
        wallet.transfer(msg.value);
    }

    function finalize() onlyOwner {
        require(!saleActive());

        // Allocate 20% for AirPorn (for development, marketing, etc...)
        uint256 xxxToReserve = SafeMath.div(token.totalSupply(), 5);
        token.mint(wallet, xxxToReserve);
        TokenReserveMinted(xxxToReserve);

        // Finish minting as we no longer want to mint any new token after the
        // sale.
        token.finishMinting();
    }

    function saleActive() public constant returns (bool) {
        return (getCurrentTimestamp() >= startDate &&
                getCurrentTimestamp() <= endDate && weiRaised < cap);
    }
}