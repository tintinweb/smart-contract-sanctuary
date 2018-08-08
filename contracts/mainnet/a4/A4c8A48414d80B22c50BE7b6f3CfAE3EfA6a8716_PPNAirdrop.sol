pragma solidity ^0.4.18;

contract PPNAirdrop {
    /**
    * @dev Air drop Public Variables
    */
    address                         public admin;
    PolicyPalNetworkToken           public token;

    using SafeMath for uint256;

    /**
    * @dev   Token Contract Modifier
    * Check if only admin
    *
    */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /**
    * @dev   Token Contract Modifier
    * Check if valid address
    *
    * @param _addr - The address to check
    *
    */
    modifier validAddress(address _addr) {
        require(_addr != address(0x0));
        require(_addr != address(this));
        _;
    }

    /**
    * @dev   Token Contract Modifier
    * Check if the batch transfer amount is
    * equal or more than balance
    * (For single batch amount)
    *
    * @param _recipients - The recipients to send
    * @param _amount - The amount to send
    *
    */
    modifier validBalance(address[] _recipients, uint256 _amount) {
        // Assert balance
        uint256 balance = token.balanceOf(this);
        require(balance > 0);
        require(balance >= _recipients.length.mul(_amount));
        _;
    }

    /**
    * @dev   Token Contract Modifier
    * Check if the batch transfer amount is
    * equal or more than balance
    * (For multiple batch amounts)
    *
    * @param _recipients - The recipients to send
    * @param _amounts - The amounts to send
    *
    */
    modifier validBalanceMultiple(address[] _recipients, uint256[] _amounts) {
        // Assert balance
        uint256 balance = token.balanceOf(this);
        require(balance > 0);

        uint256 totalAmount;
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
        }
        require(balance >= totalAmount);
        _;
    }

    /**
    * @dev Airdrop Contract Constructor
    * @param _token - PPN Token address
    * @param _adminAddr - Address of the Admin
    */
    function PPNAirdrop(
        PolicyPalNetworkToken _token, 
        address _adminAddr
    )
        public
        validAddress(_adminAddr)
        validAddress(_token)
    {
        // Assign addresses
        admin = _adminAddr;
        token = _token;
    }
    
    /**
     * @dev TokenDrop Event
     */
    event TokenDrop(address _receiver, uint _amount);

    /**
     * @dev batch Air Drop by single amount
     * @param _recipients - Address of the recipient
     * @param _amount - Amount to transfer used in this batch
     */
    function batchSingleAmount(address[] _recipients, uint256 _amount) external
        onlyAdmin
        validBalance(_recipients, _amount)
    {
        // Loop through all recipients
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];

            // Transfer amount
            assert(token.transfer(recipient, _amount));

            // TokenDrop event
            TokenDrop(recipient, _amount);
        }
    }

    /**
     * @dev batch Air Drop by multiple amount
     * @param _recipients - Address of the recipient
     * @param _amounts - Amount to transfer used in this batch
     */
    function batchMultipleAmount(address[] _recipients, uint256[] _amounts) external
        onlyAdmin
        validBalanceMultiple(_recipients, _amounts)
    {
        // Loop through all recipients
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];
            uint256 amount = _amounts[i];

            // Transfer amount
            assert(token.transfer(recipient, amount));

            // TokenDrop event
            TokenDrop(recipient, amount);
        }
    }

    /**
     * @dev Air drop single amount
     * @param _recipient - Address of the recipient
     * @param _amount - Amount to drain
     */
    function airdropSingleAmount(address _recipient, uint256 _amount) external
      onlyAdmin
    {
        assert(_amount <= token.balanceOf(this));
        assert(token.transfer(_recipient, _amount));
    }
}

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

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PolicyPalNetworkToken is StandardToken, BurnableToken, Ownable {
    /**
    * @dev Token Contract Constants
    */
    string    public constant name     = "PolicyPal Network Token";
    string    public constant symbol   = "PAL";
    uint8     public constant decimals = 18;

    /**
    * @dev Token Contract Public Variables
    */
    address public  tokenSaleContract;
    bool    public  isTokenTransferable = false;


    /**
    * @dev   Token Contract Modifier
    *
    * Check if a transfer is allowed
    * Transfers are restricted to token creator & owner(admin) during token sale duration
    * Transfers after token sale is limited by `isTokenTransferable` toggle
    *
    */
    modifier onlyWhenTransferAllowed() {
        require(isTokenTransferable || msg.sender == owner || msg.sender == tokenSaleContract);
        _;
    }

    /**
     * @dev Token Contract Modifier
     * @param _to - Address to check if valid
     *
     *  Check if an address is valid
     *  A valid address is as follows,
     *    1. Not zero address
     *    2. Not token address
     *
     */
    modifier isValidDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    /**
     * @dev Enable Transfers (Only Owner)
     */
    function toggleTransferable(bool _toggle) external
        onlyOwner
    {
        isTokenTransferable = _toggle;
    }
    

    /**
    * @dev Token Contract Constructor
    * @param _adminAddr - Address of the Admin
    */
    function PolicyPalNetworkToken(
        uint _tokenTotalAmount,
        address _adminAddr
    ) 
        public
        isValidDestination(_adminAddr)
    {
        require(_tokenTotalAmount > 0);

        totalSupply_ = _tokenTotalAmount;

        // Mint all token
        balances[msg.sender] = _tokenTotalAmount;
        Transfer(address(0x0), msg.sender, _tokenTotalAmount);

        // Assign token sale contract to creator
        tokenSaleContract = msg.sender;

        // Transfer contract ownership to admin
        transferOwnership(_adminAddr);
    }

    /**
    * @dev Token Contract transfer
    * @param _to - Address to transfer to
    * @param _value - Value to transfer
    * @return bool - Result of transfer
    * "Overloaded" Function of ERC20Basic&#39;s transfer
    *
    */
    function transfer(address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Token Contract transferFrom
    * @param _from - Address to transfer from
    * @param _to - Address to transfer to
    * @param _value - Value to transfer
    * @return bool - Result of transferFrom
    *
    * "Overloaded" Function of ERC20&#39;s transferFrom
    * Added with modifiers,
    *    1. onlyWhenTransferAllowed
    *    2. isValidDestination
    *
    */
    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Token Contract burn
    * @param _value - Value to burn
    * "Overloaded" Function of BurnableToken&#39;s burn
    */
    function burn(uint256 _value)
        public
    {
        super.burn(_value);
        Transfer(msg.sender, address(0x0), _value);
    }

    /**
    * @dev Token Contract Emergency Drain
    * @param _token - Token to drain
    * @param _amount - Amount to drain
    */
    function emergencyERC20Drain(ERC20 _token, uint256 _amount) public
        onlyOwner
    {
        _token.transfer(owner, _amount);
    }
}