//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol
pragma solidity ^0.4.21;


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

//File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol
pragma solidity ^0.4.21;


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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\BasicToken.sol
pragma solidity ^0.4.21;






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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol
pragma solidity ^0.4.21;




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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\StandardToken.sol
pragma solidity ^0.4.21;





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

//File: contracts\ARTIDToken.sol
/**
 * @title ParkinGO token
 *
 * @version 1.0
 * @author ParkinGO
 */
pragma solidity ^0.4.21;





contract ARTIDToken is StandardToken {
    using SafeMath for uint256;
    
    string public constant name = "ARTIDToken";
    string public constant symbol = "ARTID";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 120e6 * 1e18;
    uint256 public constant Wallet_Initial_Supply = 12e6 * 1e18;
    address public constant Wallet1 =address(0x5593105770Cd53802c067734d7e321E22E08C9a4);
    //
    address public constant Wallet2 =address(0x7003D8df7b38f4c758975fD4800574Fecc0DA7cd);
    //
    address public constant Wallet3 =address(0xDfdAA3B74fcc65b9E90d5922a74F8140A2b67d0f);
    //
    address public constant Wallet4 =address(0x0141f8d84F25739e426fd19783A1eC3A1f5a35e0);
    //
    address public constant Wallet5 =address(0x8863F676474C65E9B85dc2B7fEe16188503AE790);
    //
    address public constant Wallet6 =address(0xAbF2e86c69648E9ed6CD284f4f82dF3f9df7a3DD);
    //
    address public constant Wallet7 =address(0x66348c99019D6c21fe7c4f954Fd5A5Cb0b41aa2c);
    //
    address public constant Wallet8 =address(0x3257b7eBB5e52c67cdd0C1112b28db362b7463cD);
    //
    address public constant Wallet9 =address(0x0c26122396a4Bd59d855f19b69dADBa3B19BA4D7);
    //
    address public constant Wallet10=address(0x5b38E7b2C9aC03fA53E96220DCd299E3B47e1624);

    /**
     * @dev Constructor of ArtToken that instantiates a new Mintable Pausable Token
     */
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[Wallet1] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet1, Wallet_Initial_Supply);
        balances[Wallet2] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet2, Wallet_Initial_Supply);
        balances[Wallet3] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet3, Wallet_Initial_Supply);
        balances[Wallet4] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet4, Wallet_Initial_Supply);
        balances[Wallet5] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet5, Wallet_Initial_Supply);
        balances[Wallet6] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet6, Wallet_Initial_Supply);
        balances[Wallet7] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet7, Wallet_Initial_Supply);
        balances[Wallet8] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet8, Wallet_Initial_Supply);
        balances[Wallet9] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet9, Wallet_Initial_Supply);
        balances[Wallet10] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet10, Wallet_Initial_Supply);

    }

}