//SourceUnit: ZLW.sol

pragma solidity ^0.4.24;

contract TokenAdmin {
    bool public isPaused = false;
    bool public canBurn = false;

    address public ownerAddr;
    address public adminAddr;

    constructor() public {
        ownerAddr = msg.sender;
        adminAddr = msg.sender;
    }
 
    /// @dev Black Lists
    mapping (address => bool) blackLists;

    modifier isOwner() {
        require(msg.sender == ownerAddr);
        _;
    }

    modifier isAdmin() {
        require(msg.sender == adminAddr);
        _;
    }

    modifier isNotPaused() {
        require(isPaused == false);
        _;
    }

    modifier isNotBlackListed(address _addr){
       require(!blackLists[_addr]);
        _;
    }

    function setAdmin(address _newAdmin) external isOwner {
        require(_newAdmin != address(0));
        adminAddr = _newAdmin;
    }

    function setPause(bool _pause) external isAdmin {
        isPaused = _pause;
    }

    function setCanBurn(bool _val) external isAdmin {
        canBurn = _val;
    }

    function addBlackList(address _addr) external isAdmin {
      blackLists[_addr] = true;
    }

    function removeBlackList(address _addr) external isAdmin {
      delete blackLists[_addr];
    }

    function getBlackListStatus(address _addr) external view returns (bool) {
      return blackLists[_addr];
    }

}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract ZolowTechToken is TokenAdmin {
  using SafeMath for uint256;
  // Public variables of the token
  string public name = "Zolow Tech";
  string public symbol = "ZLW";
  uint8 public decimals = 6;
  uint256 public totalSupply = 10000000000 * (10 ** uint256(decimals)); // 10 billion tokens;

  // This creates an array with all balances
  mapping (address => uint256) public _balances;
  mapping (address => mapping(address => uint256)) private _allowed;

  // This generates a public event on the blockchain that will notify clients
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  /**
    * Constructor function
    * Initializes contract with initial supply tokens to the creator of the contract
  */

  constructor() public {
    _balances[msg.sender] = totalSupply;
  }

  function balanceOf(address _owner) external view returns (uint256) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowed[_owner][_spender];
  }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
  function transfer(address _to, uint256 _value) 
    public
    isNotPaused
    isNotBlackListed(_to) 
    isNotBlackListed(msg.sender)   
  {
    require(_value <= _balances[msg.sender] && _value > 0);
    require(_to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
  }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
  function transferFrom(address _from, address _to, uint256 _value) 
    public
    isNotPaused
    isNotBlackListed(_from)
    isNotBlackListed(_to) 
    isNotBlackListed(msg.sender)   
    returns (bool) 
  {

    require(_to != address(0));
    require(_value <= _balances[_from] && _value > 0);
    require(_value <= _allowed[_from][msg.sender]);

    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;

  }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
  function approve(address _spender, uint256 _value) 
    public
    isNotPaused
    isNotBlackListed(_spender)
    isNotBlackListed(msg.sender)  
    returns (bool) 
  {
    require(_spender != address(0));
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    isNotPaused
    isNotBlackListed(_spender)
    isNotBlackListed(msg.sender)
    returns (bool) 
  {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
      }
  }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
  function burn(uint256 _value) 
    public
    isNotPaused
    isNotBlackListed(msg.sender) 
    returns (bool) 
  {
    require (canBurn == true);                  // check if ZLW can be burnt
    require(_balances[msg.sender] >= _value);   // Check if the sender has enough
    _balances[msg.sender] = _balances[msg.sender].sub(_value);   // Subtract from the sender
    totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
    emit Burn(msg.sender, _value);
    return true;
  }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
  function burnFrom(address _from, uint256 _value) 
    public 
    isNotPaused
    isNotBlackListed(_from)
    isNotBlackListed(msg.sender)  
    returns (bool) 
  {
    require (canBurn == true);                          // check if ZLW can be burnt
    require(_balances[_from] >= _value);                // Check if the targeted balance is enough
    require(_value <= _allowed[_from][msg.sender]);    // Check allowance
    _balances[_from] = _balances[_from].sub(_value);                         // Subtract from the targeted balance
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
    totalSupply = totalSupply.sub(_value);                                  // Update totalSupply
    emit Burn(_from, _value);
    return true;
  }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}