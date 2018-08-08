pragma solidity ^0.4.23;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

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


contract MecotoConstant {
    // hard cap of mecoto token i.e total number of token which can be ever minted
    uint256 constant TOKEN_HARDCAP = 48000000 ;

    // hard cap for pre ico
    uint256 constant PRESALE_HARDCAP = 3000000;

    // hard cap for crowdsale
    uint256 constant CROWDSALE_HARDCAP = 27000000;

    // token distribution share for different team while minting defined in multiple of 1000
    uint256 constant TEAM_TOKENS_PERCENT =  28000;
    uint256 constant ADVISORS_TOKENS_PERCENT= 4000;
    uint256 constant BOUNTY_TOKENS_PERCENT = 3200;
    uint256 constant FLOAT_TOKENS_PERCENT =  21600; 

    // Bonus Discount&#39;s upto Investment&#39;s
    uint256 constant BONUS_DISCOUNT_1 = 1500000;
    uint256 constant BONUS_DISCOUNT_2 = 2500000;
    uint256 constant BONUS_DISCOUNT_3 = 3000000;

     // Bonus percentage
    uint256 constant BONUS_DISCOUNT_PERCENT_1 = 50;
    uint256 constant BONUS_DISCOUNT_PERCENT_2 = 17;
    uint256 constant BONUS_DISCOUNT_PERCENT_3 = 8;

    // different wallets to store token
    address constant TEAM_ADDRESS = 0xc9D0A09F0C91e982673Fe47304d2a50a2122045a;
    address constant ADVISOR_ADDRESS = 0xc803D536FFb1eC9B71548352784FAAeCF95929a9;
    address constant BOUNTY_ADDRESS = 0xC1b3d77D80B4aeCB0f346c3274dB2261f629f60D;
    address constant FLOAT_WALLET = 0xb875ce361235d25B846ED487eFC1D14aC61B69C3;

    // Token Name and Symbol
    string constant TOKEN_NAME = "Mecoto Token";
    string constant TOKEN_SYMBOL = "XTK";
}


contract MecotoToken is MecotoConstant, StandardToken, Ownable {
    // Different Events need to be emitted
    event MintingFinished();
    event MintingAddressAdded(address indexed _address);
    event MintingAddressRemoved(address indexed _address);
    event TransferAddressAdded(address indexed _address);
    event Mint(address indexed _address, uint256 _amount);

    // Pause token transfer, after successfully finished crowdsale it becomes false to enable transfer.
    bool public isLocked = true;
    bool public isMintingFinished = false;

    // Accounts who can transfer token even if paused. Works only during crowdsale.
    mapping(address => bool) adrAllowedForTransfer;
    mapping(address => bool) adrAllowedForMinting;

    modifier onlyAllowedForTransfer {
        if(isLocked) {
            require(adrAllowedForTransfer[msg.sender] == true);
            _;
        } else {
            _;
        }
    }

    modifier onlyAllowedForMinting {
        require(adrAllowedForMinting[msg.sender] == true);
        _;
    }

    modifier canMint {
        require(!isMintingFinished);
        _;
    }

    /**
    *@dev Set it for using mint function
    *@param it is the address of the deployed project
    */
    function setAllowedForMinting(address _address) external onlyOwner  {
        adrAllowedForMinting[_address] = true;
        emit MintingAddressAdded(_address);
    }

    /**
    *@dev Set it for using mint function
    *@param it is the address of the deployed project
    */
    function setDisallowedForMinting(address _address) external onlyOwner  {
        adrAllowedForMinting[_address] = false;
        emit MintingAddressRemoved(_address);
    }

    function checkAllowedAddressForMinting(address _address) external view onlyOwner returns (bool){
        return adrAllowedForMinting[_address];
    }

    function approveProject(address _investorAddress, uint256 _value) onlyAllowedForTransfer public {
        allowed[_investorAddress][msg.sender] = _value;
        emit Approval(_investorAddress, msg.sender, _value);
    }

    /**
    *@dev Set it before using transferfunction 
    *@param it is the address of the deployed project
    */
    function setAllowedForTransfer(address _address) external onlyOwner {
        adrAllowedForTransfer[_address] = true;
        emit TransferAddressAdded(_address);
    }

    function checkAllowedAddressFoTransfer(address _address) external view onlyOwner returns (bool){
        return adrAllowedForTransfer[_address];
    }

    function name() public pure returns (string) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string) {
        return TOKEN_SYMBOL;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyAllowedForTransfer returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public onlyAllowedForTransfer returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Function to mint tokens
    */
    function mint(address _to, uint256 _amount) onlyAllowedForMinting canMint public {
        require(totalSupply_.add(_amount) <= TOKEN_HARDCAP, "Token Hardcap Reached!");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyAllowedForMinting canMint public {
        isMintingFinished = true;
        isLocked = false;
        emit MintingFinished();
    }
}