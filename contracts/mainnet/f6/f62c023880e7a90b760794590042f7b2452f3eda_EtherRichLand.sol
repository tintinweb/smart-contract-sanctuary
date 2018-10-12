pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/EtherRichLand.sol

contract EtherRichLand is Ownable, StandardToken {
    string public constant name = "Ether Rich Land"; // name of token
    string public constant symbol = "ERL"; // symbol of token
    //uint8 public constant decimals = 18;

    using SafeMath for uint256;

    struct Investor {
        uint256 weiDonated;
        uint256 weiIncome;
        address landlord;
        uint256 taxRate;
    }

    mapping(uint256 => Investor) Land;
    uint256 public weiCollected = 0;
    uint256 public constant landTotal = 100;
    address public constant manager1 = 0x978076A6a69A29f6f114072950A4AF9D2bB23435;
    address public constant manager2 = 0xB362D19e44CbA1625d3837149F31bEaf318f5E61;
    address public constant manager3 = 0xF62C64729717E230445C3A1Bbfc0c8fbdb9CCB72;

   //address private crowdsale;
 
  constructor(
    ) public {
    //crowdsale = address(this);
  }


  function () external payable {

    require(msg.value >= 0.001 ether); // minimal ether to buy

    playGame(msg.sender, msg.value); // the msg.value is in wei
  }


  function getLandTaxRate(uint256 _value) internal pure returns (uint256) {
    require(_value > 0);
    uint256 _taxRate = 0;

    if (_value > 0 && _value <= 1 ether) {
        _taxRate = 1;
    } else if (_value > 1 ether && _value <= 10 ether) {
        _taxRate = 5;
    } else if (_value > 10 ether && _value <= 100 ether) {
        _taxRate = 10;
    } else if (_value > 100 ether && _value <= 500 ether) {
        _taxRate = 15;
    } else if (_value > 500 ether && _value <= 1000 ether) {
        _taxRate = 20;
    } else if (_value > 1000 ether) {
        _taxRate = 30;
    }
    return _taxRate;
  }


  function playGame(address _from, uint256 _value) private  
  {
    require(_from != 0x0); // 0x0 is meaning to destory(burn)
    require(_value > 0);

    // the unit of the msg.value is in wei 
    uint256 _landId = uint256(blockhash(block.number-1))%landTotal;
    uint256 _chanceId = uint256(blockhash(block.number-1))%10;

    uint256 weiTotal;
    address landlord;
    uint256 weiToLandlord;
    uint256 weiToSender;

    if (Land[_landId].weiDonated > 0) {
        // there is a landlord in the land
        if (_from != Land[_landId].landlord) {
            if (_chanceId == 5) {
                // the old landlord get his wei and his landlord role is ended
                weiTotal = Land[_landId].weiDonated + Land[_landId].weiIncome;
                landlord = Land[_landId].landlord;
                // the new player is the new landlord
                Land[_landId].weiDonated = _value;
                Land[_landId].weiIncome = 0;
                Land[_landId].landlord = _from;
                Land[_landId].taxRate = getLandTaxRate(_value);

                landlord.transfer(weiTotal);
            } else {
                // pay tax to the landlord
                weiToLandlord = _value * Land[_landId].taxRate / 100;
                weiToSender = _value - weiToLandlord;
                Land[_landId].weiIncome += weiToLandlord;

                _from.transfer(weiToSender);
            }
        } else {
            // change the tax rate of the land
            Land[_landId].weiDonated += _value;
            Land[_landId].taxRate = getLandTaxRate(Land[_landId].weiDonated);
        }   
    } else {
        // no landlord in the land
        Land[_landId].weiDonated = _value;
        Land[_landId].weiIncome = 0;
        Land[_landId].landlord = _from;
        Land[_landId].taxRate = getLandTaxRate(_value);
    }
  }


  function sellLand() public {
    uint256 _landId;
    uint256 totalWei = 0;
    //uint256 totalIncome = 0;
    address _from;

    for(_landId=0; _landId<landTotal;_landId++) {
        if (Land[_landId].landlord == msg.sender) {
            totalWei += Land[_landId].weiDonated;
            totalWei += Land[_landId].weiIncome;
            //totalIncome += Land[_landId].weiIncome;
            Land[_landId].weiDonated = 0;
            Land[_landId].weiIncome = 0;
            Land[_landId].landlord = 0x0;
            Land[_landId].taxRate = 0;
        }
    }
    if (totalWei > 0) {
        uint256 communityFunding = totalWei * 1 / 100;
        uint256 finalWei = totalWei - communityFunding;

        weiCollected += communityFunding;
        _from = msg.sender;
        _from.transfer(finalWei);
    }
  }

  function getMyBalance() view public returns (uint256, uint256, uint256) {
    require(msg.sender != 0x0);
    uint256 _landId;
    uint256 _totalWeiDonated = 0;
    uint256 _totalWeiIncome = 0;
    uint256 _totalLand = 0;

    for(_landId=0; _landId<landTotal;_landId++) {
        if (Land[_landId].landlord == msg.sender) {
            _totalWeiDonated += Land[_landId].weiDonated;
            _totalWeiIncome += Land[_landId].weiIncome;
            _totalLand += 1;
        }
    }
    return (_totalLand, _totalWeiDonated, _totalWeiIncome);
  }

  function getBalanceOfAccount(address _to) view public onlyOwner() returns (uint256, uint256, uint256) {
    require(_to != 0x0);

    uint256 _landId;
    uint256 _totalWeiDonated = 0;
    uint256 _totalWeiIncome = 0;
    uint256 _totalLand = 0;

    for(_landId=0; _landId<landTotal;_landId++) {
        if (Land[_landId].landlord == _to) {
            _totalWeiDonated += Land[_landId].weiDonated;
            _totalWeiIncome += Land[_landId].weiIncome;
            _totalLand += 1;
        }
    }
    return (_totalLand, _totalWeiDonated, _totalWeiIncome);
  }

  function sendFunding(address _to, uint256 _value) public onlyOwner() {
    require(_to != 0x0);
    require(_to == manager1 || _to == manager2 || _to == manager3);
    require(_value > 0);
    require(weiCollected >= _value);

    weiCollected -= _value;
    _to.transfer(_value); // wei
  }
}