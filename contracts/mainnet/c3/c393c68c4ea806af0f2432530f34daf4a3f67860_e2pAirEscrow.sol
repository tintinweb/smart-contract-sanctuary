/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title Stoppable
 * @dev Base contract which allows children to implement final irreversible stop mechanism.
 */
contract Stoppable is Pausable {
  event Stop();

  bool public stopped = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not stopped.
   */
  modifier whenNotStopped() {
    require(!stopped);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is stopped.
   */
  modifier whenStopped() {
    require(stopped);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function stop() public onlyOwner whenNotStopped {
    stopped = true;
    emit Stop();
  }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}


/**
 * @title e2pAir Escrow Contract
 * @dev Contract sends tokens from airdropper&#39;s account to receiver on claim.
 * 
 * When deploying contract, airdroper provides airdrop parametrs: token, amount 
 * of tokens and amount of eth should be claimed per link and  airdrop transit 
 * address and deposits ether needed for the airdrop.
 * 
 * Airdrop transit address is used to verify that links are signed by airdropper. 
 * 
 * Airdropper generates claim links. Each link contains a private key 
 * signed by the airdrop transit private key. The link private key can be used 
 * once to sign receiver&#39;s address. Receiver provides signature
 * to the Relayer Server, which calls smart contract to withdraw tokens. 
 * 
 * On claim smart contract verifies, that receiver provided address signed 
 * by a link private key. 
 * If everything is correct smart contract sends tokens and ether to receiver.
 * 
 * Anytime airdropper can get back unclaimed ether using getEtherBack method.
 * 
 */
contract e2pAirEscrow is Stoppable {
  
  address public TOKEN_ADDRESS; // token to distribute
  uint public CLAIM_AMOUNT; // tokens claimed per link
  uint public REFERRAL_AMOUNT; // referral reward

  uint public CLAIM_AMOUNT_ETH; // ether claimed per link
  address public AIRDROPPER; // airdropper address, which has tokens to distribute
  address public AIRDROP_TRANSIT_ADDRESS; // special address, used on claim to verify 
                                          // that links signed by the airdropper
  

  // Mappings of transit address => true if link is used.                                                                                                                                
  mapping (address => bool) usedTransitAddresses;
  
   /**
   * @dev Contructor that sets airdrop params and receives ether needed for the 
   * airdrop. 
   * @param _tokenAddress address Token address to distribute
   * @param _claimAmount uint tokens (in atomic values) claimed per link
   * @param _claimAmountEth uint ether (in wei) claimed per link
   * @param _airdropTransitAddress special address, used on claim to verify that links signed by airdropper
   */
  constructor(address _tokenAddress,
              uint _claimAmount, 
              uint  _referralAmount, 
              uint _claimAmountEth,
              address _airdropTransitAddress) public payable {
    AIRDROPPER = msg.sender;
    TOKEN_ADDRESS = _tokenAddress;
    CLAIM_AMOUNT = _claimAmount;
    REFERRAL_AMOUNT = _referralAmount;
    CLAIM_AMOUNT_ETH = _claimAmountEth;
    AIRDROP_TRANSIT_ADDRESS = _airdropTransitAddress;
  }

   /**
   * @dev Verify that address is signed with needed private key.
   * @param _transitAddress transit address assigned to transfer
   * @param _addressSigned address Signed address.
   * @param _v ECDSA signature parameter v.
   * @param _r ECDSA signature parameters r.
   * @param _s ECDSA signature parameters s.
   * @return True if signature is correct.
   */
  function verifyLinkPrivateKey(
			   address _transitAddress,
			   address _addressSigned,
			   address _referralAddress,
			   uint8 _v,
			   bytes32 _r,
			   bytes32 _s)
    public pure returns(bool success) {
    bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32", _addressSigned, _referralAddress);
    address retAddr = ecrecover(prefixedHash, _v, _r, _s);
    return retAddr == _transitAddress;
  }
  
  
   /**
   * @dev Verify that address is signed with needed private key.
   * @param _transitAddress transit address assigned to transfer
   * @param _addressSigned address Signed address.
   * @param _v ECDSA signature parameter v.
   * @param _r ECDSA signature parameters r.
   * @param _s ECDSA signature parameters s.
   * @return True if signature is correct.
   */
  function verifyReceiverAddress(
			   address _transitAddress,
			   address _addressSigned,
			   uint8 _v,
			   bytes32 _r,
			   bytes32 _s)
    public pure returns(bool success) {
    bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32", _addressSigned);
    address retAddr = ecrecover(prefixedHash, _v, _r, _s);
    return retAddr == _transitAddress;
  }
  
/**
   * @dev Verify that claim params are correct and the link key wasn&#39;t used before.  
   * @param _recipient address to receive tokens.
   * @param _transitAddress transit address provided by the airdropper
   * @param _keyV ECDSA signature parameter v. Signed by the airdrop transit key.
   * @param _keyR ECDSA signature parameters r. Signed by the airdrop transit key.
   * @param _keyS ECDSA signature parameters s. Signed by the airdrop transit key.
   * @param _recipientV ECDSA signature parameter v. Signed by the link key.
   * @param _recipientR ECDSA signature parameters r. Signed by the link key.
   * @param _recipientS ECDSA signature parameters s. Signed by the link key.
   * @return True if claim params are correct. 
   */
  function checkWithdrawal(
            address _recipient, 
            address _referralAddress, 
		    address _transitAddress,
		    uint8 _keyV, 
		    bytes32 _keyR,
			bytes32 _keyS,
			uint8 _recipientV, 
		    bytes32 _recipientR,
			bytes32 _recipientS) 
    public view returns(bool success) {
    
        // verify that link wasn&#39;t used before  
        require(usedTransitAddresses[_transitAddress] == false);

        // verifying that key is legit and signed by AIRDROP_TRANSIT_ADDRESS&#39;s key
        require(verifyLinkPrivateKey(AIRDROP_TRANSIT_ADDRESS, _transitAddress, _referralAddress, _keyV, _keyR, _keyS));
    
        // verifying that recepients address signed correctly
        require(verifyReceiverAddress(_transitAddress, _recipient, _recipientV, _recipientR, _recipientS));
        
        // verifying that there is enough ether to make transfer
        require(address(this).balance >= CLAIM_AMOUNT_ETH);
        
        return true;
  }
  
  /**
   * @dev Withdraw tokens to receiver address if withdraw params are correct.
   * @param _recipient address to receive tokens.
   * @param _transitAddress transit address provided to receiver by the airdropper
   * @param _keyV ECDSA signature parameter v. Signed by the airdrop transit key.
   * @param _keyR ECDSA signature parameters r. Signed by the airdrop transit key.
   * @param _keyS ECDSA signature parameters s. Signed by the airdrop transit key.
   * @param _recipientV ECDSA signature parameter v. Signed by the link key.
   * @param _recipientR ECDSA signature parameters r. Signed by the link key.
   * @param _recipientS ECDSA signature parameters s. Signed by the link key.
   * @return True if tokens (and ether) were successfully sent to receiver.
   */
  function withdraw(
		    address _recipient, 
		    address _referralAddress, 
		    address _transitAddress,
		    uint8 _keyV, 
		    bytes32 _keyR,
			bytes32 _keyS,
			uint8 _recipientV, 
		    bytes32 _recipientR,
			bytes32 _recipientS
		    )
    public
    whenNotPaused
    whenNotStopped
    returns (bool success) {
    
    require(checkWithdrawal(_recipient, 
    		_referralAddress,
		    _transitAddress,
		    _keyV, 
		    _keyR,
			_keyS,
			_recipientV, 
		    _recipientR,
			_recipientS));
        

    // save to state that address was used
    usedTransitAddresses[_transitAddress] = true;

    // send tokens
    if (CLAIM_AMOUNT > 0 && TOKEN_ADDRESS != 0x0000000000000000000000000000000000000000) {
        StandardToken token = StandardToken(TOKEN_ADDRESS);
        token.transferFrom(AIRDROPPER, _recipient, CLAIM_AMOUNT);
    }
    
    // send tokens to the address who refferred the airdrop 
    if (REFERRAL_AMOUNT > 0 && _referralAddress != 0x0000000000000000000000000000000000000000) {
        token.transferFrom(AIRDROPPER, _referralAddress, REFERRAL_AMOUNT);
    }

    
    // send ether (if needed)
    if (CLAIM_AMOUNT_ETH > 0) {
        _recipient.transfer(CLAIM_AMOUNT_ETH);
    }
    
    return true;
  }

 /**
   * @dev Get boolean if link is already claimed. 
   * @param _transitAddress transit address provided to receiver by the airdropper
   * @return True if the transit address was already used. 
   */
  function isLinkClaimed(address _transitAddress) 
    public view returns (bool claimed) {
        return usedTransitAddresses[_transitAddress];
  }

   /**
   * @dev Withdraw ether back deposited to the smart contract.  
   * @return True if ether was withdrawn. 
   */
  function getEtherBack() public returns (bool success) { 
    require(msg.sender == AIRDROPPER);
      
    AIRDROPPER.transfer(address(this).balance);
      
    return true;
  }
}