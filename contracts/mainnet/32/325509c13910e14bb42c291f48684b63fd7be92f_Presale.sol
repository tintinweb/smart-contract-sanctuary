pragma solidity ^0.4.10;

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

pragma solidity ^0.4.24;


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

pragma solidity ^0.4.21;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic is Ownable {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
  function burn(uint256 _value) onlyOwner public {
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


contract StockusToken is BurnableToken {

    string public constant name = "Stockus Token";
    string public constant symbol = "STT";
    uint32 public constant decimals = 2;
    uint256 public INITIAL_SUPPLY = 15000000 * 100;
    bool public isSale;

    function StockusToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(address(0), msg.sender, INITIAL_SUPPLY);
        isSale = true;
    }

    modifier saleIsOn() {
        require(isSale);
        _;
    }

    function refund(address _from, uint256 _value) onlyOwner saleIsOn public returns(bool) {
        balances[_from] = balances[_from].sub(_value);
        balances[owner] = balances[owner].add(_value);
        Transfer(_from, owner, _value);
        return true;
    }

    function stopSale() onlyOwner saleIsOn public returns(bool) {
        isSale = false;
        return true;
    }

}

pragma solidity ^0.4.10;

contract Crowdsale is Ownable {

    using SafeMath for uint;

    address public multisig;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public hardcap;
    uint256 public softcap;
    StockusToken public token; //Token contract
    uint256 public saleSupply;
    uint256 public bountySupply;
    bool public saleStopped;
    bool public sendToTeam;
    uint256 public sendToTeamTime;
    uint256 public endSaleTime;
    mapping(address => uint256) public saleBalances;

    uint256 public constant RESERVED_SUPPLY = 1500000 * 100;

    function Crowdsale(address _multisig, StockusToken _token, uint256 _weiRaised, uint256 _saleSupply, uint256 _bountySupply) public {
        multisig = _multisig;
        weiRaised = _weiRaised;
        hardcap = 700 ether;
        softcap = 100 ether;
        token = _token;
        saleSupply = _saleSupply;
        bountySupply = _bountySupply;
        saleStopped = false;
        sendToTeam = false;
        endSaleTime = now + 4 weeks;
    }

    modifier isOverSoftcap() {
        require(weiRaised >= softcap);
        _;
    }

    modifier isUnderSoftcap() {
        require(weiRaised <= softcap);
        _;
    }

    modifier isSale() {
        require(now < endSaleTime);
        _;
    }

    modifier saleEnded() {
        require(now >= endSaleTime);
        _;
    }

    modifier saleNoStopped() {
        require(saleStopped == false);
        _;
    }

    function stopSale() onlyOwner saleEnded isOverSoftcap public returns(bool) {
        if (saleSupply > 0) {
            token.burn(saleSupply);
            saleSupply = 0;
        }
        saleStopped = true;
        sendToTeamTime = now + 12 weeks;
        forwardFunds();
        return token.stopSale();
    }

    function createTokens() isSale saleNoStopped payable public {
        if (now < endSaleTime - 3 weeks) {
            rate = 12000000000000;
        } else if (now > endSaleTime - 3 weeks && now < endSaleTime - 2 weeks) {
            rate = 14000000000000;
        } else if (now > endSaleTime - 2 weeks && now < endSaleTime - 1 weeks) {
            rate = 16000000000000;
        } else {
            rate = 18000000000000;
        }
        uint256 tokens = msg.value.div(rate);
        require(saleSupply >= tokens);
        saleSupply = saleSupply.sub(tokens);
        saleBalances[msg.sender] = saleBalances[msg.sender].add(msg.value);
        token.transfer(msg.sender, tokens);
    }

    function adminSendTokens(address _to, uint256 _value, uint256 _weiAmount) onlyOwner saleNoStopped public returns(bool) {
        require(saleSupply >= _value);
        saleSupply = saleSupply.sub(_value);
        weiRaised = weiRaised.add(_weiAmount);
        return token.transfer(_to, _value);
    }

    function adminRefundTokens(address _from, uint256 _value, uint256 _weiAmount) onlyOwner saleNoStopped public returns(bool) {
        saleSupply = saleSupply.add(_value);
        weiRaised = weiRaised.sub(_weiAmount);
        return token.refund(_from, _value);
    }

    function bountySend(address _to, uint256 _value) onlyOwner saleNoStopped public returns(bool) {
        require(bountySupply >= _value);
        bountySupply = bountySupply.sub(_value);
        return token.transfer(_to, _value);
    }

    function bountyRefund(address _from, uint256 _value) onlyOwner saleNoStopped public returns(bool) {
        bountySupply = bountySupply.add(_value);
        return token.refund(_from, _value);
    }

    function refund() saleEnded isUnderSoftcap public returns(bool) {
        uint256 value = saleBalances[msg.sender];
        saleBalances[msg.sender] = 0;
        msg.sender.transfer(value);
    }

    function refundTeamTokens() onlyOwner public returns(bool) {
        require(sendToTeam == false);
        require(now >= sendToTeamTime);
        sendToTeam = true;
        return token.transfer(msg.sender, RESERVED_SUPPLY);
    }

    function forwardFunds() private {
        multisig.transfer(this.balance);
    }

    function setMultisig(address _multisig) onlyOwner public {
        multisig = _multisig;
    }

    function() external payable {
        createTokens();
    }

}



pragma solidity ^0.4.21;

contract Presale is Ownable {

    using SafeMath for uint;

    address public multisig;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public tokensBurned;
    StockusToken public token; //Token contract
    Crowdsale public crowdsale; // Crowdsale contract
    uint256 public saleSupply = 12000000 * 100;
    uint256 public presaleSupply = 2000000 * 100;
    uint256 public bountySupply = 1500000 * 100;
    uint256 public tokensSoftcap = 500000 * 100;

    function Presale(address _multisig) public {
        multisig = _multisig;
        token = new StockusToken();
    }

    modifier isOverSoftcap() {
        require(tokensBurned >= tokensSoftcap);
        _;
    }

    function startCrowdsale() onlyOwner isOverSoftcap public {
        crowdsale = new Crowdsale(multisig, token, weiRaised, saleSupply, bountySupply);
        token.transfer(address(crowdsale), token.balanceOf(this));
        token.transferOwnership(address(crowdsale));
        crowdsale.transferOwnership(owner);
        forwardFunds();
    }

    function createTokens() payable public {
        uint256 weiAmount = msg.value;
        if (tokensBurned < tokensSoftcap) {
            rate = 5000000000000;
        } else {
            rate = 7000000000000;
        }
        uint256 tokens = weiAmount.div(rate);
        require(presaleSupply >= tokens);
        tokensBurned = tokensBurned.add(tokens);
        weiRaised = weiRaised.add(weiAmount);
        saleSupply = saleSupply.sub(tokens);
        presaleSupply = presaleSupply.sub(tokens);
        token.transfer(msg.sender, tokens);
    }

    function bountySend(address _to, uint256 _value) onlyOwner public returns(bool) {
        require(bountySupply >= _value);
        bountySupply = bountySupply.sub(_value);
        return token.transfer(_to, _value);
    }

    function bountyRefund(address _from, uint256 _value) onlyOwner public returns(bool) {
        bountySupply = bountySupply.add(_value);
        return token.refund(_from, _value);
    }

    function forwardFunds() private {
        multisig.transfer(this.balance);
    }

    function setMultisig(address _multisig) onlyOwner public {
        multisig = _multisig;
    }

    function() external payable {
        createTokens();
    }

}