/**
 *Submitted for verification at Etherscan.io on 2020-08-07
*/

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
**/
library SafeMath{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @dev Abstract contract for approveAndCall.
**/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
 * @title SiuCoin Token
 * @dev ERC20 contract utilizing ERC865-ish structure (3esmit's implementation with alterations).
 * @dev to allow users to pay Ethereum fees in tokens.
**/
contract SiuCoin is Ownable {
    using SafeMath for uint256;
    
    string public constant symbol = "SIU";
    string public constant name = "Siucoin";
    
    uint8 public constant decimals = 18;
    uint256 private _totalSupply = 1500000 * (10 ** 18);
    
    // Function sigs to be used within contract for signature recovery.
    bytes4 internal constant transferSig = 0xa9059cbb;
    bytes4 internal constant approveSig = 0x095ea7b3;
    bytes4 internal constant increaseApprovalSig = 0xd73dd623;
    bytes4 internal constant decreaseApprovalSig = 0x66188463;
    bytes4 internal constant approveAndCallSig = 0xcae9ca51;
    bytes4 internal constant revokeSignatureSig = 0xe40d89e5;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    // Keeps track of the last nonce sent from user. Used for delegated functions.
    mapping (address => uint256) nonces;
    
    // Mapping of past used hashes: true if already used.
    mapping (address => mapping (bytes => bool)) invalidSignatures;

    // Mapping of finalized ERC865 standard sigs => our function sigs for future-proofing
    mapping (bytes4 => bytes4) public standardSigs;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed from, address indexed spender, uint tokens);
    event SignatureRedeemed(bytes _sig, address indexed from);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);

       
    constructor()
      public
    {
        balances[0xDbCCd61648edFFD465A50a7929B9f7a278Fd7D56] = 1000000 ether;
        balances[0xca1504e201d4Dc31691b70653EB7Dcb1691bc62B] = 500000 ether;
    }
    
    
        
    function _burn(address _who, uint256 _value) onlyOwner public returns (bool) {
            require(_value <= balances[_who]);
            
            balances[_who] = balances[_who].sub(_value);
            _totalSupply = _totalSupply.sub(_value);
            emit Burn(_who, _value);
            emit Transfer(_who, address(0), _value);
            
            return true;
    
    }
        
    function _mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
            _totalSupply = SafeMath.add(_totalSupply, _amount);
            balances[_to] = balances[_to].add(_amount);
            emit Mint(_to, _amount);
            emit Transfer(0x0000000000000000000000000000000000000000, _to, _amount);
            return true;
        }
    
    /**
     * @dev This code allows us to redirect pre-signed calls with different function selectors to our own.
    **/
    function () 
      public
    {
        bytes memory calldata = msg.data;
        bytes4 new_selector = standardSigs[msg.sig];
        require(new_selector != 0);
        
        assembly {
           mstore(add(0x20, calldata), new_selector)
        }
        
        require(address(this).delegatecall(calldata));
        
        assembly {
            if iszero(eq(returndatasize, 0x20)) { revert(0, 0) }
            returndatacopy(0, 0, returndatasize)
            return(0, returndatasize)
        }
    }


    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_transfer(msg.sender, _to, _amount));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        require(_transfer(_from, _to, _amount));
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_approve(msg.sender, _spender, _amount));
        return true;
    }
    
    
    function increaseApproval(address _spender, uint256 _amount) 
      public
    returns (bool success)
    {
        require(_increaseApproval(msg.sender, _spender, _amount));
        return true;
    }
    
    
    function decreaseApproval(address _spender, uint256 _amount) 
      public
    returns (bool success)
    {
        require(_decreaseApproval(msg.sender, _spender, _amount));
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _amount, bytes _data) 
      public
    returns (bool success) 
    {
        require(_approve(msg.sender, _spender, _amount));
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, address(this), _data);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount)
      internal
    returns (bool success)
    {
        require (_to != address(0));
        require(balances[_from] >= _amount);
        
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
   
    function _approve(address _owner, address _spender, uint256 _amount) 
      internal
    returns (bool success)
    {
        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
        return true;
    }
    
    function _increaseApproval(address _owner, address _spender, uint256 _amount)
      internal
    returns (bool success)
    {
        allowed[_owner][_spender] = allowed[_owner][_spender].add(_amount);
        emit Approval(_owner, _spender, allowed[_owner][_spender]);
        return true;
    }
    
    function _decreaseApproval(address _owner, address _spender, uint256 _amount)
      internal
    returns (bool success)
    {
        if (allowed[_owner][_spender] <= _amount) allowed[_owner][_spender] = 0;
        else allowed[_owner][_spender] = allowed[_owner][_spender].sub(_amount);
        
        emit Approval(_owner, _spender, allowed[_owner][_spender]);
        return true;
    }
    
    function transferPreSigned(
        bytes _signature,
        address _to, 
        uint256 _value, 
        bytes _extraData,
        uint256 _nonce) 
      public
      validPayload(292)
    returns (bool) 
    {
        // Log starting gas left of transaction for later gas price calculations.

        // Recover signer address from signature; ensure address is valid.
        address from = recoverPreSigned(_signature, transferSig, _to, _value, _extraData, _nonce);
        require(from != address(0));
        
        // Require the hash has not been used, declare it used, increment nonce.
        require(!invalidSignatures[from][_signature]);
        invalidSignatures[from][_signature] = true;
        nonces[from]++;
        
        // Internal transfer.
        require(_transfer(from, _to, _value));

       
        emit SignatureRedeemed(_signature, from);
        return true;
    }
   
    function approvePreSigned(
        bytes _signature,
        address _to, 
        uint256 _value, 
        bytes _extraData,
        uint256 _nonce) 
      public
      validPayload(292)
    returns (bool) 
    {
        address from = recoverPreSigned(_signature, approveSig, _to, _value, _extraData, _nonce);
        require(from != address(0));
        require(!invalidSignatures[from][_signature]);
        
        invalidSignatures[from][_signature] = true;
        nonces[from]++;
        
        require(_approve(from, _to, _value));

        
        emit SignatureRedeemed(_signature, from);
        return true;
    }
    
  
    function increaseApprovalPreSigned(
        bytes _signature,
        address _to, 
        uint256 _value, 
        bytes _extraData,
        uint256 _nonce)
      public
      validPayload(292)
    returns (bool) 
    {
        address from = recoverPreSigned(_signature, increaseApprovalSig, _to, _value, _extraData, _nonce);
        require(from != address(0));
        require(!invalidSignatures[from][_signature]);
        
        invalidSignatures[from][_signature] = true;
        nonces[from]++;
        
        require(_increaseApproval(from, _to, _value));

        
        emit SignatureRedeemed(_signature, from);
        return true;
    }
    
    /**
     * @dev Added for the same reason as increaseApproval. Decreases to 0 if "_value" is greater than allowed.
    **/
    function decreaseApprovalPreSigned(
        bytes _signature,
        address _to, 
        uint256 _value, 
        bytes _extraData,

        uint256 _nonce) 
      public
      validPayload(292)
    returns (bool) 
    {
        
        address from = recoverPreSigned(_signature, decreaseApprovalSig, _to, _value, _extraData, _nonce);
        require(from != address(0));
        require(!invalidSignatures[from][_signature]);
        
        invalidSignatures[from][_signature] = true;
        nonces[from]++;
        
        require(_decreaseApproval(from, _to, _value));

    
        emit SignatureRedeemed(_signature, from);
        return true;
    }
    
    function approveAndCallPreSigned(
        bytes _signature,
        address _to, 
        uint256 _value,
        bytes _extraData,
        uint256 _nonce) 
      public
      validPayload(356)
    returns (bool) 
    {
        address from = recoverPreSigned(_signature, approveAndCallSig, _to, _value, _extraData, _nonce);
        require(from != address(0));
        require(!invalidSignatures[from][_signature]);
        
        invalidSignatures[from][_signature] = true;
        nonces[from]++;
        
        require(_approve(from, _to, _value));
        ApproveAndCallFallBack(_to).receiveApproval(from, _value, address(this), _extraData);

      
        
        emit SignatureRedeemed(_signature, from);
        return true;
    }

    function revokeSignature(bytes _sigToRevoke)
      public
    returns (bool)
    {
        invalidSignatures[msg.sender][_sigToRevoke] = true;
        
        emit SignatureRedeemed(_sigToRevoke, msg.sender);
        return true;
    }
    
  
    function revokeSignaturePreSigned(
        bytes _signature,
        bytes _sigToRevoke
        )
      public
      validPayload(356)
    returns (bool)
    {
        address from = recoverRevokeHash(_signature, _sigToRevoke);
        require(!invalidSignatures[from][_signature]);
        invalidSignatures[from][_signature] = true;
        
        invalidSignatures[from][_sigToRevoke] = true;
        
        
        emit SignatureRedeemed(_signature, from);
        return true;
    }
    
    
    function getRevokeHash(bytes _sigToRevoke)
      public
      pure
    returns (bytes32 txHash)
    {
        return keccak256(revokeSignatureSig, _sigToRevoke);
    }

   
    function recoverRevokeHash(bytes _signature, bytes _sigToRevoke)
      public
      pure
    returns (address from)
    {
        return ecrecoverFromSig(getSignHash(getRevokeHash(_sigToRevoke)), _signature);
    }
    
    function getPreSignedHash(
        bytes4 _function,
        address _to, 
        uint256 _value,
        bytes _extraData,
        uint256 _nonce)
      public
      view
    returns (bytes32 txHash) 
    {
        return keccak256(address(this), _function, _to, _value, _extraData, _nonce);
    }
    
   
    function recoverPreSigned(
        bytes _sig,
        bytes4 _function,
        address _to,
        uint256 _value,
        bytes _extraData,
        uint256 _nonce) 
      public
      view
    returns (address recovered)
    {
        bytes32 hexdData = getPreSignedHash(_function, _to, _value, _extraData, _nonce);
        return ecrecoverFromSig( keccak256("\x19Ethereum Signed Message:\n32",hexdData), _sig);
    }
    
    /**
     * @dev Add signature prefix to hash for recovery à la ERC191.
     * @param _hash The hashed transaction to add signature prefix to.
    **/
    function getSignHash(bytes32 _hash)
      public
      pure
    returns (bytes32 signHash)
    {
        return keccak256("\x19Ethereum Signed Message:\n32", _hash);
    }

    /**
     * @dev Helps to reduce stack depth problems for delegations. Thank you to Bokky for this!
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
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
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

    /**
     * @dev Frontend queries to find the next nonce of the user so they can find the new nonce to send.
     * @param _owner Address that will be sending the COIN.
    **/
    function getNonce(address _owner)
      external
      view
    returns (uint256 nonce)
    {
        return nonces[_owner];
    }
    
/** ****************************** Constants ******************************* **/
    
    /**
     * @dev Return total supply of token.
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
     * @dev Allowed amount for a user to spend of another's tokens.
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
    
/** ****************************** onlyOwner ******************************* **/
    
    /**
     * @dev Allow the owner to take ERC20 tokens off of this contract if they are accidentally sent.
    **/
    function token_escape(address _tokenContract)
      external
      onlyOwner
    {
        SiuCoin lostToken = SiuCoin(_tokenContract);
        
        uint256 stuckTokens = lostToken.balanceOf(address(this));
        lostToken.transfer(owner, stuckTokens);
    }
    
    /**
     * @dev Owner may set the standard sig to redirect to one of our pre-signed functions.
     * @dev Added in order to prepare for the ERC865 standard function names to be different from ours.
     * @param _standardSig The function signature of the finalized standard function.
     * @param _ourSig The function signature of our implemented function.
    **/
    function updateStandard(bytes4 _standardSig, bytes4 _ourSig)
      external
      onlyOwner
    returns (bool success)
    {
        // These 6 are the signatures of our pre-signed functions. Don't want the owner messin' around.
        require(_ourSig == 0x1296830d || _ourSig == 0x617b390b || _ourSig == 0xadb8249e ||
            _ourSig == 0x8be52783 || _ourSig == 0xc8d4b389 || _ourSig == 0xe391a7c4);
        standardSigs[_standardSig] = _ourSig;
        return true;
    }
    
/** ***************************** Modifiers ******************************** **/
    
    modifier validPayload(uint _size) {
        uint payload_size;
        assembly {
            payload_size := calldatasize
        }
        require(payload_size >= _size);
        _;
    }
    
}