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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(
      address indexed previousOwner
  );
  
  event OwnershipTransferred(
      address indexed previousOwner, address indexed newOwner
  );

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ItsvitToken
 */
contract ItsvitToken is Ownable {

  using SafeMath for uint256;
  
  event Transfer(
    address indexed from, address indexed to, uint256 value
  );
  
  event Burn(
    address _address, uint256 value
  );

  string public constant name = &quot;ItSvitToken&quot;;

  string public constant symbol = &quot;IST&quot;;

  uint8 public constant decimals = 1;
  
  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  uint256 notUsedToken_;

  /**
   * @dev total number of tokens 
   */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  /**
   * @dev total number of tokens 
   */
  function notUsedToken() public view returns (uint256) {
    return notUsedToken_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyOwner public returns (bool) {
    require(_to != address(0));
    
    totalSupply_ = totalSupply_.add(_value);
    notUsedToken_ = notUsedToken_.add(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    
    return true;
  }

  /**
  * @dev burn token for a specified address
  * @param _value The amount to be burn.
  */
  function burn(address _from, uint256 _value) onlyOwner public returns (bool) {
    require(_value <= balances[_from]);
    
    notUsedToken_ = notUsedToken_.sub(_value);
    balances[_from] = balances[_from].sub(_value);
    emit Burn(_from, _value);
    
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _address The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _address) public view returns (uint256) {
    return balances[_address];
  }
}

contract Loyalty is Ownable {
    using SafeMath for uint256;
    
    event AddClient(
      address _client
    );

    event OutProjectBinding(
      address _client, uint256 _project_id
    );

    event AddHourToProject(
      uint256 _project_id,  uint256 _hour
    );

    event AddBonusToClient(
      address _client, uint256 _amount, string _description
    );

    event UseTokens(
      address client, uint256 _amount, uint256 _type
    );

    event EditTokensForHour(
      uint256 _rate
    );

    struct Project {
      address _client;
      uint256 _hour;
    }

    uint256 tokensForHour;

    mapping (address => bool) public clients;

    mapping (uint256 => Project) public projects; 

    ItsvitToken token;

    function Loyalty() public {
      token = new ItsvitToken();
      tokensForHour = 10;
    }

    function addClient( address _address) onlyOwner public returns(bool) {
      clients[_address] = true;
      emit AddClient(_address);

      return true;
    }

    function outProjectBinding( uint256 _project_id, address _address) onlyOwner public returns(bool) {
      require(clients[_address] == true);
      require(_project_id > 0);
      require(getProjectClient(_project_id) == address(0));

      projects[_project_id] = Project(_address, 0);
      emit OutProjectBinding(_address, _project_id);

      return true;
    }

    function addHourToProject(uint256 _project_id, uint256 _hour) onlyOwner public returns(bool) {
      require(getProjectClient(_project_id) != address(0));
      require(_hour > 0);
      
      uint256 tokenSum;
      tokenSum = _hour.mul(tokensForHour);
      token.transfer(getProjectClient(_project_id), tokenSum);
      projects[_project_id]._hour = projects[_project_id]._hour + _hour;
      emit AddHourToProject(_project_id,  _hour);

      return true;
    }
    
    function getProjectHour(uint256 _project_id) internal view returns (uint256) {
        Project storage project = projects[_project_id];
        return project._hour;
    }

    function getProjectClient(uint256 _project_id) internal view returns (address) {
      Project storage project = projects[_project_id];
      return project._client;
    }
    
    function addBonusToClient(address _address, uint256 _amount, string _description) onlyOwner public returns(bool) {
      require(clients[_address] == true);
      require(_amount > 0);

      token.transfer(_address, _amount);
      emit AddBonusToClient(_address,  _amount, _description);

      return true;
    }

    function useTokens(address _address, uint256 _amount, uint256 _type) onlyOwner public returns(bool) {
      require(_amount <= token.balanceOf(_address));
      require(clients[_address] == true);
      require(_type == 1 || _type == 2 ); 

      token.burn(_address, _amount);
      emit UseTokens(_address, _amount, _type);

      return true;
    }
    
    function editTokensForHour(uint256 _rate) onlyOwner public returns(uint256) {
      require(_rate > 0);

      tokensForHour = _rate;
      emit EditTokensForHour(_rate);

      return _rate;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return token.balanceOf(_address);
    }
    
    function getTotalSupply() public view returns (uint256) {
        return token.totalSupply();
    }
    
     function getNotUsedToken_() public view returns (uint256) {
        return token.notUsedToken();
    }
    
}