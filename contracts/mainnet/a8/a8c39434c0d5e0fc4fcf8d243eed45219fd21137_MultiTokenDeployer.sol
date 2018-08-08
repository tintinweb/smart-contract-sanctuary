pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// File: contracts/BasicMultiToken.sol

contract BasicMultiToken is StandardToken, DetailedERC20 {
    
    ERC20[] public tokens;

    event Mint(address indexed minter, uint256 value);
    event Burn(address indexed burner, uint256 value);
    
    constructor() public DetailedERC20("", "", 0) {
    }

    function init(ERC20[] _tokens, string _name, string _symbol, uint8 _decimals) public {
        require(decimals == 0, "init: contract was already initialized");
        require(_decimals > 0, "init: _decimals should not be zero");
        require(bytes(_name).length > 0, "init: _name should not be empty");
        require(bytes(_symbol).length > 0, "init: _symbol should not be empty");
        require(_tokens.length >= 2, "Contract do not support less than 2 inner tokens");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        tokens = _tokens;
    }

    function mintFirstTokens(address _to, uint256 _amount, uint256[] _tokenAmounts) public {
        require(totalSupply_ == 0, "This method can be used with zero total supply only");
        _mint(_to, _amount, _tokenAmounts);
    }

    function mint(address _to, uint256 _amount) public {
        require(totalSupply_ != 0, "This method can be used with non zero total supply only");
        uint256[] memory tokenAmounts = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokenAmounts[i] = tokens[i].balanceOf(this).mul(_amount).div(totalSupply_);
        }
        _mint(_to, _amount, tokenAmounts);
    }

    function burn(uint256 _value) public {
        burnSome(_value, tokens);
    }

    function burnSome(uint256 _value, ERC20[] someTokens) public {
        require(someTokens.length > 0, "Array of tokens can&#39;t be empty");

        uint256 totalSupply = totalSupply_;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);

        for (uint i = 0; i < someTokens.length; i++) {
            uint256 prevBalance = someTokens[i].balanceOf(this);
            uint256 tokenAmount = prevBalance.mul(_value).div(totalSupply);
            someTokens[i].transfer(msg.sender, tokenAmount); // Can&#39;t use require because not all ERC20 tokens return bool
            require(someTokens[i].balanceOf(this) == prevBalance.sub(tokenAmount), "Invalid token behavior");
        }
    }

    function _mint(address _to, uint256 _amount, uint256[] _tokenAmounts) internal {
        require(tokens.length == _tokenAmounts.length, "Lenghts of tokens and _tokenAmounts array should be equal");

        for (uint i = 0; i < tokens.length; i++) {
            uint256 prevBalance = tokens[i].balanceOf(this);
            tokens[i].transferFrom(msg.sender, this, _tokenAmounts[i]); // Can&#39;t use require because not all ERC20 tokens return bool
            require(tokens[i].balanceOf(this) == prevBalance.add(_tokenAmounts[i]), "Invalid token behavior");
        }

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

}

// File: contracts/ERC228.sol

interface ERC228 {
    function changeableTokenCount() external view returns (uint16 count);
    function changeableToken(uint16 _tokenIndex) external view returns (address tokenAddress);
    function getReturn(address _fromToken, address _toToken, uint256 _amount) external view returns (uint256 returnAmount);
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) external returns (uint256 returnAmount);

    event Update();
    event Change(address indexed _fromToken, address indexed _toToken, address indexed _changer, uint256 _amount, uint256 _return);
}

// File: contracts/MultiToken.sol

contract MultiToken is BasicMultiToken, ERC228 {

    mapping(address => uint256) public weights;

    function init(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 _decimals) public {
        super.init(_tokens, _name, _symbol, _decimals);
        require(_weights.length == tokens.length, "Lenghts of _tokens and _weights array should be equal");
        for (uint i = 0; i < tokens.length; i++) {
            require(_weights[i] != 0, "The _weights array should not contains zeros");
            require(weights[tokens[i]] == 0, "The _tokens array have duplicates");
            weights[tokens[i]] = _weights[i];
        }
    }

    function init2(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 _decimals) public {
        init(_tokens, _weights, _name, _symbol, _decimals);
    }

    function changeableTokenCount() public view returns (uint16 count) {
        count = uint16(tokens.length);
    }

    function changeableToken(uint16 _tokenIndex) public view returns (address tokenAddress) {
        tokenAddress = tokens[_tokenIndex];
    }

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns(uint256 returnAmount) {
        if (weights[_fromToken] > 0 && weights[_toToken] > 0 && _fromToken != _toToken) {
            uint256 fromBalance = ERC20(_fromToken).balanceOf(this);
            uint256 toBalance = ERC20(_toToken).balanceOf(this);
            returnAmount = toBalance.mul(_amount).mul(weights[_fromToken]).div(weights[_toToken]).div(fromBalance.add(_amount));
        }
    }

    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns(uint256 returnAmount) {
        returnAmount = getReturn(_fromToken, _toToken, _amount);
        require(returnAmount > 0, "The return amount is zero");
        require(returnAmount >= _minReturn, "The return amount is less than _minReturn value");
        
        uint256 fromBalance = ERC20(_fromToken).balanceOf(this);
        ERC20(_fromToken).transferFrom(msg.sender, this, _amount);
        require(ERC20(_fromToken).balanceOf(this) == fromBalance + _amount);
        
        uint256 toBalance = ERC20(_toToken).balanceOf(this);
        ERC20(_toToken).transfer(msg.sender, returnAmount);
        require(ERC20(_toToken).balanceOf(this) == toBalance - returnAmount);

        emit Change(_fromToken, _toToken, msg.sender, _amount, returnAmount);
    }

    function changeOverERC228(address _fromToken, address _toToken, uint256 _amount, address exchange) public returns(uint256 returnAmount) {
        returnAmount = getReturn(_fromToken, _toToken, _amount);
        require(returnAmount > 0, "The return amount is zero");

        uint256 fromBalance = ERC20(_fromToken).balanceOf(this);
        ERC20(_toToken).approve(exchange, returnAmount);
        ERC228(exchange).change(_toToken, _fromToken, returnAmount, _amount);
        uint256 realReturnAmount = ERC20(_fromToken).balanceOf(this).sub(fromBalance);
        require(realReturnAmount >= _amount);

        if (realReturnAmount > _amount) {
            uint256 reward = realReturnAmount.sub(_amount);
            ERC20(_fromToken).transfer(msg.sender, reward); // Arbiter reward
            require(ERC20(_fromToken).balanceOf(this) == fromBalance.add(_amount));
        }

        emit Change(_fromToken, _toToken, msg.sender, _amount, returnAmount);
    }

}

// File: contracts/registry/IDeployer.sol

interface IDeployer {
    function deploy(bytes data) external returns(address mtkn);
}

// File: contracts/registry/MultiTokenDeployer.sol

contract MultiTokenDeployer is IDeployer {
    function deploy(bytes data) external returns(address mtkn) {
        require(
            // init(address[],uint256[],string,string,uint8)
            (data[0] == 0x6f && data[1] == 0x5f && data[2] == 0x53 && data[3] == 0x5d) ||
            // init2(address[],uint256[],string,string,uint8)
            (data[0] == 0x18 && data[1] == 0x2a && data[2] == 0x54 && data[3] == 0x15)
        );

        mtkn = new MultiToken();
        require(mtkn.call(data));
    }
}