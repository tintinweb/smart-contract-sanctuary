/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity ^0.4.21;

contract Token {
    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint internal _totalSupply;
    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;
   
    function Token(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }
   
    function name() public constant returns (string) {
        return _name;
    }
   
    function symbol() public constant returns (string) {
        return _symbol;
    }
   
    function decimals() public constant returns (uint8) {
        return _decimals;
    }
   
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
   
    function balanceOf(address _addr) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external constant returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
pragma solidity ^0.4.19;

interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

pragma solidity ^0.4.18;

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

   function isOwner(address _address) internal view returns (bool) {
        return (_address == owner);
    }
   
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

// create a Flix token with a supply of 100 million
// using the ERC223 protocol
contract FlixToken is Ownable,Token("FLIX", "FLIX Token", 18, 0), ERC20, ERC223 {

    using SafeMath for uint256;
    using SafeMath for uint;

    address owner;

    bool airdrop_funded = false;
    bool crowdsale_funded = false;
    bool bounty_campaign_funded = false;
    bool vest_funded = false;
    bool reserve_funded = false;


    event Mint(address indexed to, uint256 amount);
   
    event Burn(address indexed burner, uint256 value);

    function FlixToken() public {
        owner = msg.sender;
        _balanceOf[owner] = 0;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint) {
        return _balanceOf[_addr];
    }



  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= _balanceOf[msg.sender]);
   
    bytes memory empty;

    _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
    _balanceOf[_to] = _balanceOf[_to].add(_value);
   
    emit Transfer(msg.sender, _to, _value);
   
    if(isContract(_to)){
        ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
        _contract.tokenFallback(msg.sender, _value, empty);
    }

    return true;
  }

   function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= _balanceOf[msg.sender]);
       
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        if(isContract(_to)){
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
            _contract.tokenFallback(msg.sender, _value, _data);
        }        
        return true;
    }
   

    function isContract(address _addr) internal view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }
   
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0));
        require(_value <= _balanceOf[_from]);
        require(_value <= _allowances[_from][msg.sender]);

        _balanceOf[_from] = _balanceOf[_from].sub(_value);
    _balanceOf[_to] = _balanceOf[_to].add(_value);
    _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }


    function approve(address _spender, uint _value) external returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external constant returns (uint) {
        return _allowances[_owner][_spender];
    }
 
  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value,address _who) onlyOwner public {
    require((now <= 1526637600));      
    _burn(_who, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require((now <= 1526637600));
    require(_value <= _balanceOf[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    _balanceOf[_who] = _balanceOf[_who].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
 
function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require((now <= 1526637600));
    _totalSupply = _totalSupply.add(_amount);
    _balanceOf[_to] = _balanceOf[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }


  /**
   * Mint tokens and allocate to wallet
     Reversible until presale launch
   *
   */
  function mintToContract(bytes32 mintType,address _to) onlyOwner public returns (bool) {
    require((now <= 1526635600));
    require((mintType == "Crowdsale") || (mintType == "Airdrop") || (mintType == "BountyCampaign") || (mintType =="Vesting") || (mintType =="Reserved"));
    uint256 amount = 0;
    if(mintType == "Crowdsale"){
        require(!crowdsale_funded);
        amount = 59000000000000000000000000;
        crowdsale_funded = true;
    }
     if(mintType == "BountyCampaign"){
        require(!bounty_campaign_funded);
        amount = 2834000000000000000000000;
        bounty_campaign_funded = true;

    }
    if(mintType == "Vesting"){
        require(!vest_funded);
        amount = 18000000000000000000000000;
        vest_funded = true;
    }
    if(mintType == "Reserved"){
        require(!reserve_funded);
        amount = 20000000000000000000000000;
        reserve_funded = true;
    }
    _totalSupply = _totalSupply.add(amount);
    _balanceOf[_to] = _balanceOf[_to].add(amount);
    emit Mint(_to, amount);
    emit Transfer(address(0), _to, amount);
    return true;
  }
}