pragma solidity ^0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: contracts/Vault.sol

contract Vault is Ownable {

    using SafeERC20 for ERC20;
    
    mapping(bytes32 => bool) internal imports_;
    
    address internal signer_;

    ERC20 internal token_;

    event Export(address indexed from, uint indexed accountId, uint amount);
    event Import(address indexed to, uint amount);

    constructor (address _token, address _signer) public {

        token_ = ERC20(_token);
        signer_ = _signer;

    }

    function token() external view returns (address) {
        return token_;
    }

    function signer() external view returns (address) {
        return signer_;
    }

    function imports(bytes32 _hash) external view returns (bool) {
        return imports_[_hash];
    }
    
    /**
        Exports tokens from Ethereum network to private network
        ethereum -> private
    */
    function exportTokens (uint amount, uint accountId) public {

        token_.safeTransferFrom(msg.sender, this, amount);

        emit Export(msg.sender, accountId, amount);

    }

    /**
        Imports token from private to ethereum network
        private -> ethereum
    */
    function importTokens (bytes32 txId, address to, uint amount, bytes signature) public {

        bytes32 dataHash = keccak256(abi.encodePacked(txId, "-", to, "-", amount));
        
        // check if already imported
        require(imports_[dataHash] == false);
        
        // check signature
        require(prefixedRecover(dataHash, signature) == signer_);

        imports_[dataHash] = true;
        
        token_.safeTransfer(to, amount);
        
        emit Import(to, amount);
        
    }
    
    function toEthereumSignedMessage (bytes32 _msg) internal pure returns (bytes32) {

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        return keccak256(abi.encodePacked(prefix, _msg));
    
    }

    function prefixedRecover (bytes32 _msg, bytes sig) internal pure returns (address) {
        
        bytes32 ethSignedMsg = toEthereumSignedMessage(_msg);
        
        return recover(ethSignedMsg, sig);
    
    }
    
    function recover (bytes32 hash, bytes sig) internal pure returns (address) {
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }
        
        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
        
    }
    
}