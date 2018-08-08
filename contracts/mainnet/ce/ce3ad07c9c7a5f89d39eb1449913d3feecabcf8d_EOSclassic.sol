pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title EOSclassic
 */

// Imports









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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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






/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <remco@2π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    // solium-disable-next-line security/no-send
    assert(owner.send(address(this).balance));
  }
}


// Contract to help import the original EOS Crowdsale public key
contract EOSContractInterface
{
    mapping (address => string) public keys;
    function balanceOf( address who ) constant returns (uint value);
}

// EOSclassic smart contract 
contract EOSclassic is StandardToken, HasNoEther 
{
    // Welcome to EOSclassic
    string public constant name = "EOSclassic";
    string public constant symbol = "EOSC";
    uint8 public constant decimals = 18;

    // Total amount minted
    uint public constant TOTAL_SUPPLY = 1000000000 * (10 ** uint(decimals));
    
    // Amount given to founders
    uint public constant foundersAllocation = 100000000 * (10 ** uint(decimals));   

    // Contract address of the original EOS contracts
    address public constant eosTokenAddress = 0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0;
    address public constant eosCrowdsaleAddress = 0xd0a6E6C54DbC68Db5db3A091B171A77407Ff7ccf;
    
    // Map EOS keys; if not empty it should be favored over the original crowdsale address
    mapping (address => string) public keys;
    
    // Keep track of EOS->EOSclassic claims
    mapping (address => bool) public eosClassicClaimed;

    // LogClaim is called any time an EOS crowdsale user claims their EOSclassic equivalent
    event LogClaim (address user, uint amount);

    // LogRegister is called any time a user registers a new EOS public key
    event LogRegister (address user, string key);

    // ************************************************************
    // Constructor; mints all tokens, assigns founder&#39;s allocation
    // ************************************************************
    constructor() public 
    {
        // Define total supply
        totalSupply_ = TOTAL_SUPPLY;
        // Allocate total supply of tokens to smart contract for disbursement
        balances[address(this)] = TOTAL_SUPPLY;
        // Announce initial allocation
        emit Transfer(0x0, address(this), TOTAL_SUPPLY);
        
        // Transfer founder&#39;s allocation
        balances[address(this)] = balances[address(this)].sub(foundersAllocation);
        balances[msg.sender] = balances[msg.sender].add(foundersAllocation);
        // Announce founder&#39;s allocation
        emit Transfer(address(this), msg.sender, foundersAllocation);
    }

    // Function that checks the original EOS token for a balance
    function queryEOSTokenBalance(address _address) view public returns (uint) 
    {
        //return ERC20Basic(eosCrowdsaleAddress).balanceOf(_address);
        EOSContractInterface eosTokenContract = EOSContractInterface(eosTokenAddress);
        return eosTokenContract.balanceOf(_address);
    }

    // Function that returns any registered EOS address from the original EOS crowdsale
    function queryEOSCrowdsaleKey(address _address) view public returns (string) 
    {
        EOSContractInterface eosCrowdsaleContract = EOSContractInterface(eosCrowdsaleAddress);
        return eosCrowdsaleContract.keys(_address);
    }

    // Use to claim EOS Classic from the calling address
    function claimEOSclassic() external returns (bool) 
    {
        return claimEOSclassicFor(msg.sender);
    }

    // Use to claim EOSclassic for any Ethereum address 
    function claimEOSclassicFor(address _toAddress) public returns (bool)
    {
        // Ensure that an address has been passed
        require (_toAddress != address(0));
        // Ensure that the address isn&#39;t unrecoverable
        require (_toAddress != 0x00000000000000000000000000000000000000B1);
        // Ensure this address has not already been claimed
        require (isClaimed(_toAddress) == false);

        
        // Query the original EOS Crowdsale for address balance
        uint _eosContractBalance = queryEOSTokenBalance(_toAddress);
        
        // Ensure that address had some balance in the crowdsale
        require (_eosContractBalance > 0);
        
        // Sanity check: ensure we have enough tokens to send
        require (_eosContractBalance <= balances[address(this)]);

        // Mark address as claimed
        eosClassicClaimed[_toAddress] = true;
        
        // Convert equivalent amount of EOS to EOSclassic
        // Transfer EOS Classic tokens from this contract to claiming address
        balances[address(this)] = balances[address(this)].sub(_eosContractBalance);
        balances[_toAddress] = balances[_toAddress].add(_eosContractBalance);
        
        // Broadcast transfer 
        emit Transfer(address(this), _toAddress, _eosContractBalance);
        
        // Broadcast claim
        emit LogClaim(_toAddress, _eosContractBalance);
        
        // Success!
        return true;
    }

    // Check any address to see if its EOSclassic has already been claimed
    function isClaimed(address _address) public view returns (bool) 
    {
        return eosClassicClaimed[_address];
    }

    // Returns the latest EOS key registered.
    // EOS token holders that never registered their EOS public key 
    // can do so using the &#39;register&#39; function in EOSclassic and then request restitution 
    // via the EOS mainnet arbitration process.
    // EOS holders that previously registered can update their keys here;
    // This contract could be used in future key snapshots for future EOS forks.
    function getMyEOSKey() external view returns (string)
    {
        return getEOSKeyFor(msg.sender);
    }

    // Return the registered EOS public key for the passed address
    function getEOSKeyFor(address _address) public view returns (string)
    {
        string memory _eosKey;

        // Get any key registered with EOSclassic
        _eosKey = keys[_address];

        if (bytes(_eosKey).length > 0) {
            // EOSclassic key was registered; return this over the original crowdsale address
            return _eosKey;
        } else {
            // EOSclassic doesn&#39;t have an EOS public key registered; return any original crowdsale key
            _eosKey = queryEOSCrowdsaleKey(_address);
            return _eosKey;
        }
    }

    // EOSclassic developer&#39;s note: the registration function is identical
    // to the original EOS crowdsale registration function with only the
    // freeze function removed, and &#39;emit&#39; added to the LogRegister event,
    // per updated Solidity standards.
    //
    // Value should be a public key.  Read full key import policy.
    // Manually registering requires a base58
    // encoded using the STEEM, BTS, or EOS public key format.
    function register(string key) public {
        assert(bytes(key).length <= 64);

        keys[msg.sender] = key;

        emit LogRegister(msg.sender, key);
    }

}