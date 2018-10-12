pragma solidity ^0.4.24;

// TokenLoot v2.0 2e59d4
// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: contracts/TokenLoot.sol

/// @title Token Loot Contract
/// @author Julia Altenried, Yuriy Kashnikov

contract TokenLoot is Ownable {

  // FIELDS
  /* signer address, verified in &#39;receiveTokenLoot&#39; method, can be set by owner only */
  address public neverdieSigner;
  /* Nonces */
  mapping (address => uint256) public nonces;
  /* Tokens */
  address[] public tokens;

  // EVENTS
  event ReceiveLoot(address indexed sender,
                    uint256 nonce,
                    address[] tokens,
                    uint256[] amounts);
 

  // SETTERS
  function setNeverdieSignerAddress(address _to) public onlyOwner {
    neverdieSigner = _to;
  }

  function setTokens(address[] _tokens) public onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i] = _tokens[i];
    }
    for (uint256 j = _tokens.length; j < _tokens.length; j++) {
      tokens.push(_tokens[j]);
    }
  }

  /// @param _tokens tokens addresses
  /// @param _signer signer address, verified further in swap functions
  constructor(address[] _tokens, address _signer) {
    for (uint256 i = 0; i < _tokens.length; i++) {
      tokens.push(_tokens[i]);
    }
    neverdieSigner = _signer;
  }

  function receiveTokenLoot(uint256[] _amounts, 
                            uint256 _nonce, 
                            uint8 _v, 
                            bytes32 _r, 
                            bytes32 _s) {

    // reject if the new nonce is lower or equal to the current one
    require(_nonce > nonces[msg.sender],
            "wrong nonce");
    nonces[msg.sender] = _nonce;

    // verify signature
    address signer = ecrecover(keccak256(msg.sender, 
                                         _nonce,
                                         _amounts), _v, _r, _s);
    require(signer == neverdieSigner,
            "signature verification failed");

    // transer tokens
    
    for (uint256 i = 0; i < _amounts.length; i++) {
      if (_amounts[i] > 0) {
        assert(ERC20(tokens[i]).transfer(msg.sender, _amounts[i]));
      }
    }
    

    // emit event
    ReceiveLoot(msg.sender, _nonce, tokens, _amounts);
  }

  /// @dev fallback function to reject any ether coming directly to the contract
  function () payable public { 
      revert(); 
  }

  /// @dev withdraw all SKL and XP tokens
  function withdraw() public onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 amount = ERC20(tokens[i]).balanceOf(this);
      if (amount > 0) ERC20(tokens[i]).transfer(msg.sender, amount);
    }
  }

  /// @dev kill contract, but before transfer all SKL and XP tokens 
  function kill() onlyOwner public {
    withdraw();
    selfdestruct(owner);
  }

}