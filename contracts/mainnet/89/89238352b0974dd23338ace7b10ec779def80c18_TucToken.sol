pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

contract ERC827 is ERC20 {
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);
}

contract ERC827Token is ERC827, StandardToken {

  /**
   * @dev Addition to ERC20 token methods. It allows to
   * @dev approve the transfer of value and execute a call with the sent data.
   *
   * @dev Beware that changing an allowance with this method brings the risk that
   * @dev someone may use both the old and the new allowance by unfortunate
   * @dev transaction ordering. One possible solution to mitigate this race condition
   * @dev is to first reduce the spender&#39;s allowance to 0 and set the desired value
   * @dev afterwards:
   * @dev https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param _spender The address that will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @param _data ABI-encoded contract call to call `_to` address.
   *
   * @return true if the call function was executed successfully
   */
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.approve(_spender, _value);

    // solium-disable-next-line security/no-call-value
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

  /**
   * @dev Addition to ERC20 token methods. Transfer tokens to a specified
   * @dev address and execute a call with the sent data on the same transaction
   *
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   * @param _data ABI-encoded contract call to call `_to` address.
   *
   * @return true if the call function was executed successfully
   */
  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_to != address(this));

    super.transfer(_to, _value);

    // solium-disable-next-line security/no-call-value
    require(_to.call.value(msg.value)(_data));
    return true;
  }

  /**
   * @dev Addition to ERC20 token methods. Transfer tokens from one address to
   * @dev another and make a contract call on the same transaction
   *
   * @param _from The address which you want to send tokens from
   * @param _to The address which you want to transfer to
   * @param _value The amout of tokens to be transferred
   * @param _data ABI-encoded contract call to call `_to` address.
   *
   * @return true if the call function was executed successfully
   */
  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public payable returns (bool)
  {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    // solium-disable-next-line security/no-call-value
    require(_to.call.value(msg.value)(_data));
    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Increase the amount of tokens that
   * @dev an owner allowed to a spender and execute a call with the sent data.
   *
   * @dev approve should be called when allowed[_spender] == 0. To increment
   * @dev allowed value is better to use this function to avoid 2 calls (and wait until
   * @dev the first transaction is mined)
   * @dev From MonolithDAO Token.sol
   *
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function increaseApprovalAndCall(
    address _spender,
    uint _addedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    // solium-disable-next-line security/no-call-value
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Decrease the amount of tokens that
   * @dev an owner allowed to a spender and execute a call with the sent data.
   *
   * @dev approve should be called when allowed[_spender] == 0. To decrement
   * @dev allowed value is better to use this function to avoid 2 calls (and wait until
   * @dev the first transaction is mined)
   * @dev From MonolithDAO Token.sol
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function decreaseApprovalAndCall(
    address _spender,
    uint _subtractedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    // solium-disable-next-line security/no-call-value
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

}

contract TucToken is ERC827Token, Ownable {

    mapping(address => uint256) preApprovedBalances;
    mapping(address => bool) approvedAccounts;

    address admin1;
    address admin2;

    address public accountPubICOSale;
    uint8 public decimals;
	string public name;
	string public symbol;
	
	uint constant pubICOStartsAt = 1541030400; // 1.11.2018 = 1541030400

    modifier onlyKycTeam {
        require(msg.sender == admin1 || msg.sender == admin2);
        _;
    }
	
	modifier PubICOstarted {
		require(now >= pubICOStartsAt );
		_;
	}

    /**
     * @dev Create new TUC token contract.
     *
     * @param _accountFounder The account for the found tokens that receives 1,024,000,000 tokens on creation.
     * @param _accountPrivPreSale The account for the private pre-sale tokens that receives 1,326,000,000 tokens on creation.
     * @param _accountPubPreSale The account for the public pre-sale tokens that receives 1,500,000,000 tokens on creation.
     * @param _accountPubICOSale The account for the public pre-sale tokens that receives 4,150,000,000 tokens on creation.
	 * @param _accountSalesMgmt The account for the Sales Management tokens that receives 2,000,000,000 tokens on creation.
     * @param _accountTucWorld The account for the TUC World tokens that receives 2,000.000,000 tokens on creation.
     */
    constructor (
        address _admin1,
        address _admin2,
		address _accountFounder,
		address _accountPrivPreSale,
		address _accountPubPreSale,
        address _accountPubICOSale,
		address _accountSalesMgmt,
		address _accountTucWorld
		)
    public 
    payable
    {
        admin1 = _admin1;
        admin2 = _admin2;
        accountPubICOSale = _accountPubICOSale;
        decimals = 18; // 10**decimals=1000000000000000000
		totalSupply_ = 12000000000000000000000000000;
		 
		balances[_accountFounder]     = 1024000000000000000000000000 ; // 1024000000 * 10**(decimals);
        balances[_accountPrivPreSale] = 1326000000000000000000000000 ; // 1326000000 * 10**(decimals);
        balances[_accountPubPreSale]  = 1500000000000000000000000000 ; // 1500000000 * 10**(decimals);
		balances[_accountPubICOSale]  = 4150000000000000000000000000 ; // 4150000000 * 10**(decimals);
        balances[_accountSalesMgmt]   = 2000000000000000000000000000 ; // 2000000000 * 10**(decimals);
        balances[_accountTucWorld]    = 2000000000000000000000000000 ; // 2000000000 * 10**(decimals);
		emit Transfer(0, _accountFounder, 		balances[_accountFounder]);
		emit Transfer(0, _accountPrivPreSale, 	balances[_accountPrivPreSale]);
		emit Transfer(0, _accountPubPreSale, 	balances[_accountPubPreSale]);
		emit Transfer(0, _accountPubICOSale, 	balances[_accountPubICOSale]);
		emit Transfer(0, _accountSalesMgmt, 	balances[_accountSalesMgmt]);
		emit Transfer(0, _accountTucWorld, 		balances[_accountTucWorld]);
		
		name = "TUC.World";
		symbol = "TUC";
    }

    /** 
     * @dev During the public ICO users can buy TUC tokens by sending ETH to this method.
     * @dev The price per token is fixed to 0.00000540 ETH / TUC.
     *
     * @dev The buyer will receive his tokens after successful KYC approval by the TUC team. In case KYC is refused,
     * @dev the send ETH funds are send back to the buyer and no TUC tokens will be delivered.
     */
    function buyToken()
    payable
    external
	PubICOstarted
    {
        uint256 tucAmount = (msg.value * 1000000000000000000) / 5400000000000;
        require(balances[accountPubICOSale] >= tucAmount);
		
        if (approvedAccounts[msg.sender]) {
            // already kyc approved
            balances[msg.sender] += tucAmount;
			emit Transfer(accountPubICOSale, msg.sender, tucAmount);
        } else {
            // not kyc approved
            preApprovedBalances[msg.sender] += tucAmount;
        }
        balances[accountPubICOSale] -= tucAmount;
    }

    /**
     * @dev Approve KYC of a user, who contributed in ETH.
     * @dev Deliver the tokens to the user&#39;s account and move the ETH balance to the TUC contract.
     *
     * @param _user The account of the user to approve KYC.
     */
    function kycApprove(address _user)
    external
    onlyKycTeam
    {
        // account is approved
        approvedAccounts[_user] = true;
        // move balance for this account to "real" balances
        balances[_user] += preApprovedBalances[_user];
        // account has no more "unapproved" balance
        preApprovedBalances[_user] = 0;
		emit Transfer(accountPubICOSale, _user, balances[_user]);
    }

    /**
     * @dev Refusing KYC of a user, who contributed in ETH.
     * @dev Send back the ETH funds and deny delivery of TUC tokens.
     *
     * @param _user The account of the user to refuse KYC.
     */
    function kycRefuse(address _user)
    external
    onlyKycTeam
    {
		require(approvedAccounts[_user] == false);
        uint256 tucAmount = preApprovedBalances[_user];
        uint256 weiAmount = (tucAmount * 5400000000000) / 1000000000000000000;
        // account is not approved now
        approvedAccounts[_user] = false;
        // pubPreSale gets back its tokens
        balances[accountPubICOSale] += tucAmount;
        // user has no more balance
        preApprovedBalances[_user] = 0;
        // we transfer the eth back to the user that were used to buy the tokens
        _user.transfer(weiAmount);
    }

    /**
     * @dev Retrieve ETH from the contract.
     *
     * @dev The contract owner can use this method to transfer received ETH to another wallet.
     *
     * @param _safe The address of the wallet the funds should get transferred to.
     * @param _value The amount of ETH to transfer.
     */
    function retrieveEth(address _safe, uint256 _value)
    external
    onlyOwner
    {
        _safe.transfer(_value);
    }
}