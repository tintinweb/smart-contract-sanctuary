pragma solidity ^0.4.20;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMathLib{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  mapping (address => bool) public admins;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
    admins[owner] = true;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function changeAdmin(address _newAdmin, bool _approved) onlyOwner public {
    admins[_newAdmin] = _approved;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
 * @title Coinvest COIN Token
 * @dev ERC20 contract utilizing ERC865 to allow users to pay Ethereum fees in tokens.
**/

contract LoveTracker is Ownable {
    using SafeMathLib for uint256;
    
    string public constant symbol = "Love";
    string public constant name = "I see u";
    
    uint8 public constant decimals = 18;
    uint256 public _totalSupply = 107142857 * (10 ** 18);
    
    // Used for ecrecover from signed data.
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";

    // Balances for each account
    mapping(address => uint256) balances;

    // Keeps track of the last nonce sent from user. Used for delegated functions.
    mapping (address => uint256) nonces;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed from, address indexed spender, uint tokens);
    event DelegatedTransfer(address from, address to, address delegate, uint256 value, uint256 fee);
    event DelegatedTransferFrom(address from, address spender, address to, address delegate, uint256 value, uint256 fee);
    event DelegatedApproveAndCall(address from, address spender, address delegate, uint256 value, uint256 fee, bytes data);
    event DelegatedApprove(address from, address spender, address delegate, uint256 value, uint256 fee);

    /**
     * @dev Set owner and beginning balance.
    **/
    function LoveTracker()
      public
    {
        balances[msg.sender] = _totalSupply;
    }

/** ******************************** ERC20 ********************************* **/

    /**
     * @dev Transfers coins from one address to another.
     * @param _to The recipient of the transfer amount.
     * @param _amount The amount of tokens to transfer.
    **/
    function transfer(address _to, uint256 _amount) 
      external
    returns (bool success)
    {
        // Throw if insufficient balance
        require(balances[msg.sender] >= _amount);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    /**
     * @dev An allowed address can transfer tokens from another&#39;s address.
     * @param _from The owner of the tokens to be transferred.
     * @param _to The address to which the tokens will be transferred.
     * @param _amount The amount of tokens to be transferred.
    **/
    function transferFrom(address _from, address _to, uint _amount)
      external
    returns (bool success)
    {
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    /**
     * @dev Approves a wallet to transfer tokens on one&#39;s behalf.
     * @param _spender The wallet approved to spend tokens.
     * @param _amount The amount of tokens approved to spend.
    **/
    function approve(address _spender, uint256 _amount) 
      public
    returns (bool success)
    {
        require(balances[msg.sender] >= _amount);
        
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /**
     * @dev Used to approve an address and call a function on it in the same transaction.
     * @dev _spender The address to be approved to spend COIN.
     * @dev _amount The amount of COIN to be approved to spend.
     * @dev _data The data to send to the called contract.
    **/
    function approveAndCall(address _spender, uint256 _amount, bytes _data) 
      external
    returns (bool success) 
    {
        approve(_spender, _amount);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _data);
        return true;
    }
    
/** ************************ Delegated Functions *************************** **/

    /**
     * @dev Called by delegate with a signed hash of the transaction data to allow a user
     * @dev to transfer tokens without paying gas in Ether (they pay in COIN instead).
     * @param _nonce Nonce of the user&#39;s new transaction.
     * @param _from The user that has signed the data and will have COIN transferred.
     * @param _to The address to transfer COIN to.
     * @param _value The amount of COIN to transfer.
     * @param _fee The fee paid to the delegate for sending the delegatedTransfer to the blockchain.
     * @param sig Signature data of user to allow for ecrecover.
    **/
    function delegatedTransfer(
		uint256 _nonce, 
		address _from, 
		address _to, 
		uint256 _value, 
		uint256 _fee,
		//uint256 _delegatedId
		bytes sig) 
	  public 
	returns (bool) {
	    
		uint256 total = _value.add(_fee);
		require(_from != address(0));
		require(_to != address(0));
		require(total <= balances[_from]);
		require(_nonce > nonces[_from]);
		//require(_delegatedId == 1);

		address delegate = msg.sender;
		address token = address(this);
		bytes32 delegatedTxnHash = keccak256(delegate, token, _nonce, _from, _to, _value, _fee);
		address signatory = ecrecoverFromSig(keccak256(signingPrefix, delegatedTxnHash), sig);
		require(signatory == _from);

		balances[_from] = balances[_from].sub(total);
		balances[_to] = balances[_to].add(_value);
		balances[delegate] = balances[delegate].add(_fee);
		nonces[_from] = _nonce;

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, msg.sender, _fee);
		emit DelegatedTransfer(_from, _to, delegate, _value, _fee);
		return true;
    }
    
    /**
     * @dev Same deal as delegatedTransfer. Unexplained variables are the same as well.
     * @param _from The address that COIN will be transferred from (NOT the user who signs transaction).
     * @param _spender The spender of the COIN (user that signs transaction).
    **/
    function delegatedTransferFrom(
		uint256 _nonce, 
		address _from,
		address _spender,
		address _to, 
		uint256 _value, 
		uint256 _fee,
		//uint256 _delegatedId,
		bytes sig) 
	  public 
	returns (bool) {
	    
		require(_from != address(0));
		require(_spender != address(0));
		require(_to != address(0));
		require(_fee <= balances[_spender]);
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][_spender]);
		require(_nonce > nonces[_spender]);
		//require(_delegatedId == 2);

		address delegate = msg.sender;
		address token = address(this);
		bytes32 delegatedTxnHash = keccak256(delegate, token, _nonce, _from, _spender, _to, _value, _fee);
		address signatory = ecrecoverFromSig(keccak256(signingPrefix, delegatedTxnHash), sig);
		require(signatory == _spender);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		balances[_spender] = balances[_spender].sub(_fee);
		balances[delegate] = balances[delegate].add(_fee);
		nonces[_spender] = _nonce;

        emit Transfer(_from, _to, _value);
        emit Transfer(_spender, msg.sender, _fee);
		emit DelegatedTransferFrom(_from, _spender, _to, delegate, _value, _fee);
		return true;
    }
    
    /**
     * @dev Same deal as delegatedTransfer but instead of sending COIN we approve a spender.
    **/
    function delegatedApprove(
		uint256 _nonce, 
		address _from, 
		address _spender, 
		uint256 _value, 
		uint256 _fee,
		//uint256 _delegatedId,
		bytes sig) 
	  public 
	returns (bool) {
	    
		uint256 total = _value.add(_fee);
		require(_from != address(0));
		require(_spender != address(0));
		require(total <= balances[_from]);
		require(_nonce > nonces[_from]);
		//require(_delegatedId == 3);

		address delegate = msg.sender;
		address token = address(this);
		bytes32 delegatedTxnHash = keccak256(delegate, token, _nonce, _from, _spender, _value, _fee);
		address signatory = ecrecoverFromSig(keccak256(signingPrefix, delegatedTxnHash), sig);
		require(signatory == _from);
		
		allowed[_from][_spender] = _value;
		balances[_from] = balances[_from].sub(_fee);
		balances[delegate] = balances[delegate].add(_fee);
		nonces[_from] = _nonce;

        emit Approval(_from, _spender, _value);
        emit Transfer(_from, msg.sender, _fee);
		emit DelegatedApprove(_from, _spender, delegate, _value, _fee);
		return true;
    }
    
    /**
     * @dev Same deal as delegatedApprove but we use approveAndCall to call a contract in the same tx.
     * @param _data The data to be sent to the called contract.
    **/
    function delegatedApproveAndCall(
		uint256 _nonce, 
		address _from, 
		address _spender, 
		uint256 _value, 
		uint256 _fee,
		bytes _data,
		//uint256 _delegatedId,
		bytes sig) 
	  public 
	returns (bool) {
	    
		uint256 total = _value.add(_fee);
		require(_from != address(0));
		require(_spender != address(0));
		require(total <= balances[_from]);
		require(_nonce > nonces[_from]);
		//require(_delegatedId == 4);

		address delegate = msg.sender;
		address token = address(this);
		bytes32 delegatedTxnHash = keccak256(delegate, token, _nonce, _from, _spender, _value, _fee, _data);
		address signatory = ecrecoverFromSig(keccak256(signingPrefix, delegatedTxnHash), sig);
		require(signatory == _from);
		
		allowed[_from][_spender] = _value;
		balances[_from] = balances[_from].sub(_fee);
		balances[delegate] = balances[delegate].add(_fee);
		nonces[_from] = _nonce;
		
		ApproveAndCallFallBack(_spender).receiveApproval(_from, _value, address(this), _data);

        emit Approval(_from, _spender, _value);
        emit Transfer(_from, msg.sender, _fee);
		emit DelegatedApproveAndCall(_from, _spender, delegate, _value, _fee, _data);
		return true;
    }
    
    /**
     * @dev Used by frontend to get hash for potential transaction.
    **/
    function getTransferHash(
        address _delegate,
        uint256 _nonce,
		address _from, 
		address _to, 
		uint256 _value, 
		uint256 _fee)
      external
      view
    returns (bytes32 delegateHash) {
        bytes32 suffix = keccak256(_delegate, address(this), _nonce, _from, _to, _value, _fee);
        return keccak256(signingPrefix, suffix);
    }
    
    /**
     * @dev Used by frontend to confirm data from signed hash.
    **/
    function checkTransferHash(
        address _delegate,
        uint256 _nonce,
		address _from, 
		address _to, 
		uint256 _value, 
		uint256 _fee,
		bytes sig)
      external
      view
    returns (address signatory) {
		bytes32 delegatedTxnHash = keccak256(_delegate, address(this), _nonce, _from, _to, _value, _fee);
		signatory = ecrecoverFromSig(keccak256(signingPrefix, delegatedTxnHash), sig);
    }

/** ***************************** Maintenance ****************************** **/
    
    /**
     * @dev Allow the owner to take ERC20 tokens off of this contract if they are accidentally sent.
    **/
    function token_escape(address _tokenContract)
      external
      onlyOwner
    {
        LoveTracker lostToken = LoveTracker(_tokenContract);
        
        uint256 stuckTokens = lostToken.balanceOf(address(this));
        lostToken.transfer(owner, stuckTokens);
    }
    
/** ****************************** Constants ******************************* **/
    
    /**
     * @dev Return total supply of token
    **/
    function totalSupply() 
      external
      view 
     returns (uint256) 
    {
        return _totalSupply;
    }

    /**
     * @dev Return balance of a certain address.
     * @param _owner The address whose balance we want to check.
    **/
    function balanceOf(address _owner)
      external
      view 
    returns (uint256) 
    {
        return balances[_owner];
    }
    
    /**
     * @dev Allowed amount for a user to spend of another&#39;s tokens.
     * @param _owner The owner of the tokens approved to spend.
     * @param _spender The address of the user allowed to spend the tokens.
    **/
    function allowance(address _owner, address _spender) 
      external
      view 
    returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    /**
     * @dev Frontend queries to find the next nonce of the user so they can find the new nonce to send.
     * @param _owner Address that will be sending the COIN.
    **/
    function lastNonce(address _owner)
      external
      view
    returns (uint256)
    {
        return nonces[_owner];
    }
    
    /**
     * @dev Thank you to bokky for this method, helps to reduce stack depth problems for delegations.
     * @param hash The hash of signed data for the transaction.
     * @param sig Contains r, s, and v for recovery of address from the hash.
    **/
    function ecrecoverFromSig(bytes32 hash, bytes sig) 
      public 
      pure 
    returns (address recoveredAddress) 
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP, one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }
}