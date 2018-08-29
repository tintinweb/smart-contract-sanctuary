pragma solidity 0.4.24;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

contract CanReclaimToken is Ownable {
  

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(token.transfer(owner, balance));
  }

}

contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
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
    require(owner.send(address(this).balance));
  }
}

contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC23 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    revert();
  }

}



contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CertificateRedeemer is Claimable, HasNoTokens, HasNoEther {
    /// @dev A set of addresses that are approved to sign on behalf of this contract
    mapping(address => bool) public signers;

    /// @dev The nonce associated with each hash(accountId).  In this case, the account is an external
    /// concept that does not correspond to an Ethereum address.  Therefore, the hash of the accountId
    /// is used
    mapping(bytes32 => uint256) public nonces;

    address public token;
    address public tokenHolder;

    event TokenHolderChanged(address oldTokenHolder, address newTokenHolder);
    event CertificateRedeemed(string accountId, uint256 amount, address recipient, uint256 nonce, address signer);
    event SignerAdded(address signer);
    event SignerRemoved(address signer);
    event AccountNonceChanged(uint256 oldNonce, uint256 newNone);

    constructor(address _token, address _tokenHolder)
    public
    {
        token = _token;
        tokenHolder = _tokenHolder;
    }

    function redeemWithdrawalCertificate(string accountId, uint256 amount, address recipient, bytes signature)
      external
      returns (bool)
    {
        // although the external accountId is a string, internally we use a hash of the string
        bytes32 accountHash = hashAccountId(accountId);
        uint256 nonce = nonces[accountHash]++;
        
        // compute the message that should have been signed for this action.
        bytes32 unsignedMessage = generateWithdrawalHash(accountId, amount, recipient, nonce);

        // assuming the computed message is correct, recover the signer from the given signature.
        // If the actual message that was signed was a different message, the recovered signer
        // address will be a random address. We can be sure the correct message was signed if
        // the signer is one of our approved signers.
        address signer = recoverSigner(unsignedMessage, signature);

        // require that the signer is an approved signer
        require(signers[signer]);

        // log the event, including the nonce that was used and the signer that approved the action
        emit CertificateRedeemed(accountId, amount, recipient, nonce, signer);

        // make sure the transfer is successful
        require(ERC20(token).transferFrom(tokenHolder, recipient, amount));

        return true;
    }

    /// Helper Methods

    /**
     * @dev Generates the hash of the message that needs to be signed by an approved signer.
     * The nonce is read directly from the contract&#39;s state.
     */
    function generateWithdrawalHash(string accountId, uint256 amount, address recipient, uint256 nonce)
     view
     public
    returns (bytes32)
    {
        bytes memory message = abi.encodePacked(address(this), &#39;withdraw&#39;, accountId, amount, recipient, nonce);
        bytes32 messageHash = keccak256(message);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    /**
     * @dev converts and accoutId to a bytes32
     */
    function hashAccountId(string accountId)
    pure
    internal
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(accountId));
    }


    function recoverSigner(bytes32 _hash, bytes _signature)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }


    /// Admin Methods

    function updateTokenHolder(address newTokenHolder)
     onlyOwner
     external
    {
        address oldTokenHolder = tokenHolder;
        tokenHolder = newTokenHolder;
        emit TokenHolderChanged(oldTokenHolder, newTokenHolder);
    }

    function addSigner(address signer)
     onlyOwner
     external
    {
        signers[signer] = true;
        emit SignerAdded(signer);
    }

    function removeSigner(address signer)
     onlyOwner
     external
    {
        signers[signer] = false;
        emit SignerRemoved(signer);
    }
    
    function setNonce(string accountId, uint256 newNonce) 
      public
      onlyOwner
    {
        bytes32 accountHash = hashAccountId(accountId);
        uint256 oldNonce = nonces[accountHash];
        require(newNonce > oldNonce);
        
        nonces[accountHash] = newNonce;
        
        emit AccountNonceChanged(oldNonce, newNonce);
    }
}