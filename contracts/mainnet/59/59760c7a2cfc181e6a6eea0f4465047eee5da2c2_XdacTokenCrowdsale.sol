pragma solidity ^0.4.18;

// File: node_modules/zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: contracts/XdacToken.sol

contract XdacToken is StandardToken, Ownable {
    string public name = "XDAC COIN";
    string public symbol = "XDAC";
    uint8 public decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000000 ether;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function XdacToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}

// File: contracts/XdacTokenCrowdsale.sol

/**
 * @title XdacTokenCrowdsale
 */
contract XdacTokenCrowdsale is Ownable {

    using SafeMath for uint256;
    uint256[] roundGoals;
    uint256[] roundRates;
    uint256 minContribution;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    mapping(address => Contributor) public contributors;
    //Array of the addresses who participated
    address[] addresses;

    // Amount of wei raised
    uint256 public weiDelivered;


    event TokenRefund(address indexed purchaser, uint256 amount);
    event TokenPurchase(address indexed purchaser, address indexed contributor, uint256 value, uint256 amount);

    struct Contributor {
        uint256 eth;
        bool whitelisted;
        bool created;
    }


    function XdacTokenCrowdsale(
        address _wallet,
        uint256[] _roundGoals,
        uint256[] _roundRates,
        uint256 _minContribution
    ) public {
        require(_wallet != address(0));
        require(_roundRates.length == 5);
        require(_roundGoals.length == 5);
        roundGoals = _roundGoals;
        roundRates = _roundRates;
        minContribution = _minContribution;
        token = new XdacToken();
        wallet = _wallet;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev token purchase
     * @param _contributor Address performing the token purchase
     */
    function buyTokens(address _contributor) public payable {
        require(_contributor != address(0));
        require(msg.value != 0);
        require(msg.value >= minContribution);
        require(weiDelivered.add(msg.value) <= roundGoals[4]);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(msg.value);

        TokenPurchase(msg.sender, _contributor, msg.value, tokens);
        _forwardFunds();
    }

    /**********internal***********/
    function _getCurrentRound() internal view returns (uint) {
        for (uint i = 0; i < 5; i++) {
            if (weiDelivered < roundGoals[i]) {
                return i;
            }
        }
    }

    /**
     * @dev the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint curRound = _getCurrentRound();
        uint256 calculatedTokenAmount = 0;
        uint256 roundWei = 0;
        uint256 weiRaisedIntermediate = weiDelivered;
        uint256 weiAmount = _weiAmount;

        for (curRound; curRound < 5; curRound++) {
            if (weiRaisedIntermediate.add(weiAmount) > roundGoals[curRound]) {
                roundWei = roundGoals[curRound].sub(weiRaisedIntermediate);
                weiRaisedIntermediate = weiRaisedIntermediate.add(roundWei);
                weiAmount = weiAmount.sub(roundWei);
                calculatedTokenAmount = calculatedTokenAmount.add(roundWei.mul(roundRates[curRound]));
            }
            else {
                calculatedTokenAmount = calculatedTokenAmount.add(weiAmount.mul(roundRates[curRound]));
                break;
            }
        }
        return calculatedTokenAmount;
    }


    /**
     * @dev the way in which tokens is converted to ether.
     * @param _tokenAmount Value in token to be converted into wei
     * @return Number of ether that required to purchase with the specified _tokenAmount
     */
    function _getEthAmount(uint256 _tokenAmount) internal view returns (uint256) {
        uint curRound = _getCurrentRound();
        uint256 calculatedWeiAmount = 0;
        uint256 roundWei = 0;
        uint256 weiRaisedIntermediate = weiDelivered;
        uint256 tokenAmount = _tokenAmount;

        for (curRound; curRound < 5; curRound++) {
            if(weiRaisedIntermediate.add(tokenAmount.div(roundRates[curRound])) > roundGoals[curRound]) {
                roundWei = roundGoals[curRound].sub(weiRaisedIntermediate);
                weiRaisedIntermediate = weiRaisedIntermediate.add(roundWei);
                tokenAmount = tokenAmount.sub(roundWei.div(roundRates[curRound]));
                calculatedWeiAmount = calculatedWeiAmount.add(tokenAmount.div(roundRates[curRound]));
            }
            else {
                calculatedWeiAmount = calculatedWeiAmount.add(tokenAmount.div(roundRates[curRound]));
                break;
            }
        }

        return calculatedWeiAmount;
    }

    function _forwardFunds() internal {
        Contributor storage contributor = contributors[msg.sender];
        contributor.eth = contributor.eth.add(msg.value);
        if (contributor.created == false) {
            contributor.created = true;
            addresses.push(msg.sender);
        }
        if (contributor.whitelisted) {
            _deliverTokens(msg.sender);
        }
    }

    function _deliverTokens(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];
        uint256 amountEth = contributor.eth;
        uint256 amountToken = _getTokenAmount(amountEth);
        require(amountToken > 0);
        require(amountEth > 0);
        require(contributor.whitelisted);
        contributor.eth = 0;
        weiDelivered = weiDelivered.add(amountEth);
        wallet.transfer(amountEth);
        token.transfer(_contributor, amountToken);
    }

    function _refundTokens(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];
        uint256 ethAmount = contributor.eth;
        require(ethAmount > 0);
        contributor.eth = 0;
        TokenRefund(_contributor, ethAmount);
        _contributor.transfer(ethAmount);
    }

    function _whitelistAddress(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];
        contributor.whitelisted = true;
        if (contributor.created == false) {
            contributor.created = true;
            addresses.push(_contributor);
        }
        //Auto deliver tokens
        if (contributor.eth > 0) {
            _deliverTokens(_contributor);
        }
    }

    /**********************owner*************************/

    function whitelistAddresses(address[] _contributors) public onlyOwner {
        for (uint256 i = 0; i < _contributors.length; i++) {
            _whitelistAddress(_contributors[i]);
        }
    }


    function whitelistAddress(address _contributor) public onlyOwner {
        _whitelistAddress(_contributor);
    }

    function transferTokenOwnership(address _newOwner) public onlyOwner returns(bool success) {
        XdacToken _token = XdacToken(token);
        _token.transfer(_newOwner, _token.balanceOf(_token.owner()));
        _token.transferOwnership(_newOwner);
        return true;
    }

    /**
     * @dev Refound tokens. For owner
     */
    function refundTokensForAddress(address _contributor) public onlyOwner {
        _refundTokens(_contributor);
    }


    /**********************contributor*************************/

    function getAddresses() public onlyOwner view returns (address[] )  {
        return addresses;
    }

    /**
    * @dev Refound tokens. For contributors
    */
    function refundTokens() public {
        _refundTokens(msg.sender);
    }
    /**
     * @dev Returns tokens according to rate
     */
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
        return _getTokenAmount(_weiAmount);
    }

    /**
     * @dev Returns ether according to rate
     */
    function getEthAmount(uint256 _tokenAmount) public view returns (uint256) {
        return _getEthAmount(_tokenAmount);
    }

    function getCurrentRate() public view returns (uint256) {
        return roundRates[_getCurrentRound()];
    }
}