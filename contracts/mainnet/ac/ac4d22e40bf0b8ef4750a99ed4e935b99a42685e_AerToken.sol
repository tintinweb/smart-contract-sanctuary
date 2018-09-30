pragma solidity ^0.4.23;

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

/**
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
 * Secured contract
 * @dev Important actions such as mint or burn will be controlled by smart contract.
 *      This contract will get admin privillige from owner
 */
contract Secured is Owned {
    address public admin;

    event SetAdmin(address indexed _admin);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function setAdmin(address _newAdmin) public onlyOwner {
        admin = _newAdmin;
        emit SetAdmin(admin);
    }
}


/**
 * @title ERC20 interface
 * @dev 
 */
contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Basic token
 * @dev Basic version of ERC20 token.
 * @dev based on https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * @dev Contract which inherit this token should implement transfer and transferFrom as specified in ERC20
 */
contract BasicToken is ERC20 {
  using SafeMath for uint256;
  
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
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
}


/**
 * @title TimeLock
 * @dev Deny some action from lockstart to lockend. 
 *      Owner is allowd action even it is timelocked.
 */
contract Timelocked is Owned {
  uint256 public lockstart;
  uint256 public lockend;

  event SetTimelock(uint256 start, uint256 end);

  /**
  * @dev timelock modifier.
  */
  modifier notTimeLocked() {
    require((msg.sender == owner) || (now < lockstart || now > lockend));
    _;
  }

  function setTimeLock(uint256 _start, uint256 _end) public onlyOwner {
    require(_end > _start);
    lockstart = _start;
    lockend = _end;
    
    emit SetTimelock(_start, _end);
  }
  
  function releaseTimeLock() public onlyOwner {
    lockstart = 0;
    lockend = 0;
    
    emit SetTimelock(0, 0);
  }

}

/**
 * @title Mintable token
 * @dev Admin(contract which controls AER token) can mint token.
 *      Minted tokens is belong to owner, so that owner can distribute to users.
 *      After distribution, all remained tokens will be reserved as burnable token.
 */
contract MintableToken is BasicToken, Owned, Secured {
  event Mint(address indexed to, uint256 amount);

  /**
   * @dev Function to mint tokens
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    uint256 _amount
  )
    onlyAdmin
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[owner] = balances[owner].add(_amount);
    emit Mint(owner, _amount);
    emit Transfer(address(0), owner, _amount);
    return true;
  }
}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed) for each AERYUS transaction.
 *      Tokens are burned at a rate based on the average transaction per second. 
 */
contract BurnableToken is BasicToken, Owned, Secured {
  // coldledger address which has reserved tokens for Aeryus transactions.   
  address public coldledger; 

  event SetColdledger(address ledger);
  event BurnForTransaction(address who, uint256 nft, string txtype, uint256 value);

  function setColdLedger(address ledger) public onlyOwner {
      require(ledger != address(0));
      coldledger = ledger;
      emit SetColdledger(ledger);
  }

   /**
   * @dev All token remained is stored to coldledger.
   */
  function reserveAll() public onlyOwner {
    uint256 val = balances[owner];
    balances[coldledger] = balances[coldledger].add(val);
    emit Transfer(owner, coldledger, val);
  }
  
  /**
   * @dev Burns a specific amount of tokens.
   * @param _nft ERC721 token(NFT) address(index).
   * @param _txtype transaction type such as POS, mobile, government or 
   *        any other type that can be covered by the NFTA model .
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _nft, string _txtype, uint256 _value) public onlyAdmin {
    require(_value <= balances[coldledger]);

    balances[coldledger] = balances[coldledger].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit BurnForTransaction(coldledger, _nft, _txtype, _value);
    emit Transfer(coldledger, address(0), _value);
  }
}


// ----------------------------------------------------------------------------
// The AER Token is fungible token asset of Aeryus protocol.
// As ERC-721 tokens are created to document transactions, AER tokens are burned at a rate based on
// the average transaction per second.
// Visit http://aeryus.ilhaus.com/ for full details. Thank you
//
//
// AER Token Contract
//
// Symbol      : AER
// Name        : Aeryus Token
// Total supply: 4,166,666,663.000000000000000000
// Decimals    : 18
// Website     : http://aeryus.ilhaus.com
// Company     : AERYUS
//
// ----------------------------------------------------------------------------

contract AerToken is Timelocked, MintableToken, BurnableToken {

  string public name;
  string public symbol;
  uint256 public decimals;
  
  constructor(address coldledger) public {
    name = "Aeryus Token";
    symbol = "AER";
    decimals = 18;
    totalSupply_ = 4166666663000000000000000000;
    balances[msg.sender] = totalSupply_;
    setColdLedger(coldledger);
    
    emit Transfer(address(0), msg.sender, totalSupply_);
  }
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public notTimeLocked returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

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
    public notTimeLocked
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

    // ------------------------------------------------------------------------

    // Do not accept ETH

    // ------------------------------------------------------------------------

    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return BasicToken(tokenAddress).transfer(owner, tokens);

    }
}