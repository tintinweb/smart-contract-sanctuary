pragma solidity ^0.4.24;


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


/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param _info The contact information to attach to the contract.
    */
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
  }
}

/** Function to receive approval and execute in one call
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address _from, uint256 _tokens, address _token, bytes _data) public;
}

/**
 * @title HEdpAY Token Contract that can hold and transfer ERC-20 tokens
 */
contract HedpayToken is  IERC20, Contactable {

   using SafeMath for uint;

   string public  name;
   string public symbol;
   uint8 public decimals;
   uint public _totalSupply;

   mapping(address => uint) balances;
   mapping(address => mapping(address => uint)) allowed;

    /**
    * @dev Constructor that sets the initial contract parameters
    */
    constructor() public {
        name = "HEdpAY";
        symbol = "Hdp.ф";
        decimals = 4;
        _totalSupply = 10000000000000; //1 billion * 10000 (decimals)
        balances[owner] = _totalSupply;
    }

    /**
    * @dev Return actual totalSupply value
    */
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    /**
    * @dev Get the token balance for account of token owner
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
        require(_owner != address(0));
		return balances[_owner];
    }

    /**
    * @dev Gets the specified accounts approval value
    * @param _owner address the tokens owner
    * @param _spender address the tokens spender
    * @return uint the specified accounts spending tokens amount
    */
    function allowance(address _owner, address _spender)
    public view returns (uint) {
        require(_owner != address(0));
        require(_spender != address(0));
        return allowed[_owner][_spender];
    }

    /**
    * @dev Function to transfer tokens
    * @param _to address the tokens recepient
    * @param _value uint amount of the tokens to be transferred
    */
    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Function to transfer tokens from the approved `msg.sender` account
    * @param _from address the tokens owner
    * @param _to address the tokens recepient
    * @param _value uint amount of the tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
		require(_from != address(0));
        require(_to != address(0));
        require(_value <= allowance(_from, msg.sender));
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
		emit Approval(_from, msg.sender, allowance(_from, msg.sender));
        return true;
    }

    /**
    * @dev Function to approve account to spend owned tokens
    * @param _spender address the tokens spender
    * @param _value uint amount of the tokens to be approved
    */
   function approve(address _spender, uint _value) public  returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    *@dev Function to approve for spender to transferFrom tokens
    *@param _spender address of the spender
    *@param _tokens the value of tokens for transferring
    *@param _data is used for metadata
    */
    function approveAndCall(address _spender, uint _tokens, bytes _data) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _tokens, this, _data);
        return true;
    }

    /**
    *@dev Function allows owner to transfer out
    *any accidentally sent tokens
    *@param _tokenAddress the address of tokens holder
    *@param _tokens the amount of tokens for transferring
    */
    function transferAnyERC20Token(address _tokenAddress, uint _tokens) public onlyOwner returns (bool success) {
        return IERC20(_tokenAddress).transfer(owner, _tokens);
    }

}