/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.5.0;

/**
 * @title Bad formed ERC20 token interface.
 * @dev The interface of the a bad formed ERC20 token.
 */
interface IBadERC20 {
    function transfer(address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function transferFrom(
      address from,
      address to,
      uint256 value
    ) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(
      address who
    ) external view returns (uint256);

    function allowance(
      address owner,
      address spender
    ) external view returns (uint256);

    event Transfer(
      address indexed from,
      address indexed to,
      uint256 value
    );
    event Approval(
      address indexed owner,
      address indexed spender,
      uint256 value
    );
}



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
    require(msg.sender == owner, "fn: onlyOwner)=, msg: msg.sender not owner");
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
    require(
      _newOwner != address(0),
      "fn: _transferOwnership(), msg: _newOwner == 0"
    );
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title SafeTransfer
 * @dev Transfer Bad ERC20 tokens
 */
library SafeTransfer {
/**
   * @dev Wrapping the ERC20 transferFrom function to avoid missing returns.
   * @param _tokenAddress The address of bad formed ERC20 token.
   * @param _from Transfer sender.
   * @param _to Transfer receiver.
   * @param _value Amount to be transfered.
   * @return Success of the safeTransferFrom.
   */

  function _safeTransferFrom(
    address _tokenAddress,
    address _from,
    address _to,
    uint256 _value
  )
    internal
    returns (bool result)
  {
    IBadERC20(_tokenAddress).transferFrom(_from, _to, _value);
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      switch returndatasize()
      case 0 {                      // This is our BadToken
        result := not(0)            // result is true
      }
      case 32 {                     // This is our GoodToken
        returndatacopy(0, 0, 32)
        result := mload(0)          // result == returndata of external call
      }
      default {                     // This is not an ERC20 token
        revert(0, 0)
      }
    }
  }

  /**
   * @dev Wrapping the ERC20 transfer function to avoid missing returns.
   * @param _tokenAddress The address of bad formed ERC20 token.
   * @param _to Transfer receiver.
   * @param _amount Amount to be transfered.
   * @return Success of the safeTransfer.
   */
  function _safeTransfer(
    address _tokenAddress,
    address _to,
    uint _amount
  )
    internal
    returns (bool result)
  {
    IBadERC20(_tokenAddress).transfer(_to, _amount);
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      switch returndatasize()
      case 0 {                      // This is our BadToken
        result := not(0)            // result is true
      }
      case 32 {                     // This is our GoodToken
        returndatacopy(0, 0, 32)
        result := mload(0)          // result == returndata of external call
      }
      default {                     // This is not an ERC20 token
        revert(0, 0)
      }
    }
  }
}

contract BouncerProxy is Ownable {
  using SafeTransfer for address;

  // avoid replay attacks
  mapping(address => uint) public nonce;

  // allow for third party metatx account to make transactions through this
  // contract like an identity but make sure the owner has whitelisted the account
  mapping(address => bool) public whitelist;

  // whitelist the deployer so they can whitelist others
  constructor() public {
    whitelist[msg.sender] = true;
  }

  event LogUpdateWhitelist(address indexed _account, bool _value);

  event LogTransactionForward(
    bytes _signedHashedMessage,
    address indexed _signer,
    address indexed _recipient,
    uint _transactionObjectValueField,
    bytes _transactionObjectDataField,
    address _rewardTokenAddress,
    uint _rewardAmount,
    bytes32 _hash
  );

  function () external payable { }

  function updateWhitelist(
    address _account,
    bool _value
  )
    public
    onlyOwner
    returns (bool)
  {
    whitelist[_account] = _value;
    emit LogUpdateWhitelist(_account, _value);
    return true;
  }

  function getHash(
    address _signer,
    address _recipient,
    uint _transactionObjectValueField,
    bytes memory _transactionObjectDataField,
    address _rewardTokenAddress,
    uint _rewardAmount
  )
    public
    view
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        address(this),
        _signer,
        _recipient,
        _transactionObjectValueField,
        _transactionObjectDataField,
        _rewardTokenAddress,
        _rewardAmount,
        nonce[_signer]
      )
    );
  }

  // original forward function copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  function forward(
    bytes memory _signedHashedMessage,
    address _signer,
    address _recipient,
    uint _transactionObjectValueField,
    bytes memory _transactionObjectDataField,
    address _rewardTokenAddress,
    uint _rewardAmount
  )
    public
    returns (bool)
  {
    bytes32 hashedMessage = getHash(
      _signer,
      _recipient,
      _transactionObjectValueField,
      _transactionObjectDataField,
      _rewardTokenAddress,
      _rewardAmount
    );

    //increment the nonce counter so this tx can't run again
    nonce[_signer] += 1;

    //this makes sure signer signed correctly AND signer is a valid bouncer
    require(
      isSignerWhitelisted(hashedMessage, _signedHashedMessage),
      "fn: forward(), msg: forward Signer is not whitelisted"
    );
    // make sure the signer pays in whatever token (or ether) the sender and signer agreed to
    // or skip this if the sender is incentivized in other ways and there is no need for a token
    if (_rewardAmount > 0) {
      // address 0 mean reward with ETH
      if (_rewardTokenAddress == address(0)){
        // reward with ETH
        msg.sender.transfer(_rewardAmount);
      } else {
        // reward token
        require(
          _rewardTokenAddress._safeTransfer(
            msg.sender,
            _rewardAmount
          ),
          "fn: forward(), msg: token transfer failed"
        );
      }
    }
    // execute the transaction with all the given parameters
    require(
      executeCall(_recipient, _transactionObjectValueField, _transactionObjectDataField),
      "fn: forward(), msg: executeCall() function failed"
    );
    emit LogTransactionForward(
      _signedHashedMessage,
      _signer,
      _recipient,
      _transactionObjectValueField,
      _transactionObjectDataField,
      _rewardTokenAddress,
      _rewardAmount,
      hashedMessage
    );

    return true;
  }

  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  // which was copied from GnosisSafe
  // https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol
  function executeCall(
    address _to,
    uint256 _value,
    bytes memory _data
  )
    internal
    returns (bool success)
  {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
       success := call(gas, _to, _value, add(_data, 0x20), mload(_data), 0, 0)
    }
  }

  //borrowed from OpenZeppelin's ESDA stuff:
  //https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/cryptography/ECDSA.sol
  function isSignerWhitelisted(
    bytes32 _hashedMessage,
    bytes memory _signedHashedMessage
  )
    internal
    view
    returns (bool)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    // Check the signature length
    if (_signedHashedMessage.length != 65) {
      return false;
    }
    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(_signedHashedMessage, 32))
      s := mload(add(_signedHashedMessage, 64))
      v := byte(0, mload(add(_signedHashedMessage, 96)))
    }
    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }
    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return false;
    } else {
      // solium-disable-next-line arg-overflow
      return whitelist[ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hashedMessage)),
        v, r, s
      )];
    }
  }
}