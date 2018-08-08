pragma solidity ^0.4.24;


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

contract IERC20{
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
  function totalSupply() external view returns (uint);
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract IERC20Sec is IERC20 {
  event ReleaseDividendsRights(address indexed _for, uint256 value);
  event AcceptDividends(uint256 value);

  function dividendsRightsOf(address _owner) external view returns (uint balance);
  function releaseDividendsRights(uint _value) external returns(bool);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20{
  using SafeMath for uint;

  mapping(address => uint) internal balances;
  mapping (address => mapping (address => uint)) internal allowed;

  uint internal totalSupply_;


  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() external view returns (uint) {
    return totalSupply_;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value The amount of tokens to be transferred
   */
  function transfer_(address _from, address _to, uint _value) internal returns (bool) {
    if(_from != _to) {
      uint _bfrom = balances[_from];
      uint _bto = balances[_to];
      require(_to != address(0));
      require(_value <= _bfrom);
      balances[_from] = _bfrom.sub(_value);
      balances[_to] = _bto.add(_value);
    }
    emit Transfer(_from, _to, _value);
    return true;
  }


  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) external returns (bool) {
    return transfer_(msg.sender, _to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) external returns (bool) {
    uint _allowed = allowed[_from][msg.sender];
    require(_value <= _allowed);
    allowed[_from][msg.sender] = _allowed.sub(_value);
    return transfer_(_from, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) external view returns (uint balance) {
    return balances[_owner];
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
  function approve(address _spender, uint _value) external returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) external view returns (uint) {
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
  function increaseApproval(address _spender, uint _addedValue) external returns (bool) {
    uint _allowed = allowed[msg.sender][_spender];
    _allowed = _allowed.add(_addedValue);
    allowed[msg.sender][_spender] = _allowed;
    emit Approval(msg.sender, _spender, _allowed);
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
  function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool) {
    uint _allowed = allowed[msg.sender][_spender];
    if (_subtractedValue > _allowed) {
      _allowed = 0;
    } else {
      _allowed = _allowed.sub(_subtractedValue);
    }
    allowed[msg.sender][_spender] = _allowed;
    emit Approval(msg.sender, _spender, _allowed);
    return true;
  }

}

contract ICassette {
  uint8 constant CT_ETHER = 0x01;
  uint8 constant CT_TOKEN = 0x02;
  

  function getCassetteSize_() internal view returns(uint);
  function acceptAbstractToken_(uint _value) internal returns(bool);
  function releaseAbstractToken_(address _for, uint _value) internal returns(bool);
  function getCassetteType_() internal pure returns(uint8);

}


/**
 * @title Standard token with dividends distribution support
 */
contract ERC20Sec is IERC20, IERC20Sec, ERC20, ICassette {
  using SafeMath for uint;

  uint constant DECIMAL_MULTIPLIER = 10 ** 18;
  uint constant INT256_MAX = 1 << 255 - 1;

  mapping (address => uint) internal dividendsRightsFix;
  uint internal dividendsPerToken;

  /**
  * @dev Gets the dividends rights of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount of dividends rights owned by the passed address.
  */
  function dividendsRightsOf(address _owner) external view returns (uint) {
    return dividendsRightsOf_(_owner);
  }

  function dividendsRightsOf_(address _owner) internal view returns (uint) {
    uint rights = dividendsPerToken * balances[_owner] / DECIMAL_MULTIPLIER + dividendsRightsFix[_owner];
    return int(rights) < 0 ? 0 : rights;
  }


  /**
  * @dev release dividends rights
  * @param _value The amount of dividends to be transferred.
  * @param _for The address to transfer for.
  */
  function releaseDividendsRights_(address _for, uint _value) internal returns(bool) {
    uint _dividendsRights = dividendsRightsOf_(_for);
    require(_dividendsRights >= _value);
    dividendsRightsFix[_for] -= _value;
    releaseAbstractToken_(_for, _value);
    emit ReleaseDividendsRights(_for, _value);
    return true;
  }


  /**
  * @dev release dividends rights
  * @param _value The amount of dividends to be transferred.
  */
  function releaseDividendsRights(uint _value) external returns(bool) {
    return releaseDividendsRights_(msg.sender, _value);
  }


  /**
   * @dev Update dividends rights fix
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function dividendsRightsFixUpdate_(address _from, address _to, uint _value) private {
    if (_from != _to) {
      uint _dividendsPerToken = dividendsPerToken;
      uint _balanceFrom = balances[_from];
      uint _balanceTo = balances[_to];
      dividendsRightsFix[_from] += _dividendsPerToken * _balanceFrom / DECIMAL_MULTIPLIER - 
        _dividendsPerToken * (_balanceFrom - _value) / DECIMAL_MULTIPLIER;
      dividendsRightsFix[_to] += _dividendsPerToken * _balanceTo / DECIMAL_MULTIPLIER - 
        _dividendsPerToken * (_balanceTo + _value) / DECIMAL_MULTIPLIER; 
    }
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) external returns (bool) {
    dividendsRightsFixUpdate_(msg.sender, _to, _value);
    return transfer_(msg.sender, _to, _value);
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) external returns (bool) {
    uint _allowed = allowed[_from][msg.sender];
    require(_value <= _allowed);
    allowed[_from][msg.sender] = _allowed.sub(_value);
    dividendsRightsFixUpdate_(_from, _to, _value);
    return transfer_(_from, _to, _value);
  }



  function () public payable {
    releaseDividendsRights_(msg.sender, dividendsRightsOf_(msg.sender));
    if(msg.value > 0){
      msg.sender.transfer(msg.value);
    }
  }

  /**
   * @dev Accept dividends in ether
   */

  function acceptDividends(uint _tvalue) public payable {
    uint _value;
    if(getCassetteType_()==CT_ETHER) {
      _value = msg.value;
    } else if (getCassetteType_()==CT_TOKEN) {
      _value = _tvalue;
      require(acceptAbstractToken_(_value));
    } else revert();
    uint _dividendsPerToken = dividendsPerToken;
    uint _totalSupply = totalSupply_;
    require(_totalSupply > 0);
    _dividendsPerToken = _dividendsPerToken.add(_value.mul(DECIMAL_MULTIPLIER)/_totalSupply);
    require(_dividendsPerToken.mul(_totalSupply) <= INT256_MAX);
    dividendsPerToken = _dividendsPerToken;
    emit AcceptDividends(_value);
  }
}


contract MultiOwnable{

  mapping(address => bool) public owners;
  uint internal ownersLength_;

  modifier onlyOwner() {
    require(owners[msg.sender]);
    _;
  }
  
  event AddOwner(address indexed sender, address indexed owner);
  event RemoveOwner(address indexed sender, address indexed owner);

  function addOwner_(address _for) internal returns(bool) {
    if(!owners[_for]) {
      ownersLength_ += 1;
      owners[_for] = true;
      emit AddOwner(msg.sender, _for);
      return true;
    }
    return false;
  }

  function addOwner(address _for) onlyOwner external returns(bool) {
    return addOwner_(_for);
  }

  function removeOwner_(address _for) internal returns(bool) {
    if((owners[_for]) && (ownersLength_ > 1)){
      ownersLength_ -= 1;
      owners[_for] = false;
      emit RemoveOwner(msg.sender, _for);
      return true;
    }
    return false;
  }

  function removeOwner(address _for) onlyOwner external returns(bool) {
    return removeOwner_(_for);
  }

}


contract EtherCassette is ICassette {
  function getCassetteSize_() internal view returns(uint) {
    return address(this).balance;
  }

  function acceptAbstractToken_(uint _value) internal returns(bool){
    return true;
  }
  function releaseAbstractToken_(address _for, uint _value) internal returns(bool){
    _for.transfer(_value);
    return true;
  }

  function getCassetteType_() internal pure returns(uint8){
    return CT_ETHER;
  }

}

contract TechHives is ERC20Sec, EtherCassette, MultiOwnable {
  using SafeMath for uint;
  uint constant DECIMAL_MULTIPLIER = 10 ** 18;
  string public name = "TechHives";
  string public symbol = "THV";
  uint8 public decimals = 18;

  uint mintSupply_;

  /**
  * @dev release dividends rights for a specified address
  * @param _for The address to transfer for.
  * @param _value The amount of dividends to be transferred.
  */
  function releaseDividendsRightsForce(address _for, uint _value) external onlyOwner returns(bool) {
    return releaseDividendsRights_(_for, _value);
  }

  function dividendsRightsFixUpdate_(address _for, uint _value) private {
    uint _dividendsPerToken = dividendsPerToken;
    uint _balanceFor = balances[_for];
    dividendsRightsFix[_for] += _dividendsPerToken * _balanceFor / DECIMAL_MULTIPLIER - 
      _dividendsPerToken * (_balanceFor + _value) / DECIMAL_MULTIPLIER; 
  }
  
  function mint_(address _for, uint _value) internal returns(bool) {
    require (mintSupply_ >= _value);
    dividendsRightsFixUpdate_(_for, _value);
    mintSupply_ = mintSupply_.sub(_value);
    balances[_for] = balances[_for].add(_value);
    totalSupply_ = totalSupply_.add(_value);
    emit Transfer(address(0), _for, _value);
    return true;
  }

  function mint(address _for, uint _value) external onlyOwner returns(bool) {
    return mint_(_for, _value);
  }
  
  
  function mintSupply() external view returns(uint) {
      return mintSupply_;
  }

  constructor() public {
    mintSupply_ = 25000 * DECIMAL_MULTIPLIER;
    addOwner_(0x47FC2e245b983A92EB3359F06E31F34B107B6EF6);
    mint_(0x47FC2e245b983A92EB3359F06E31F34B107B6EF6, 10000e18);
    addOwner_(msg.sender);
  }
}