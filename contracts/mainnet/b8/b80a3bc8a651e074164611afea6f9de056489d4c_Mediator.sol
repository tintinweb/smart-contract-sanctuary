/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// Sources flattened with hardhat v2.2.0 https://hardhat.org

// File contracts/IAmb.sol

pragma solidity ^0.8.0;

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes calldata _data, uint256 _gas) external returns (bytes32);
    function requireToConfirmMessage(address _contract, bytes calldata _data, uint256 _gas) external returns (bytes32);
    function sourceChainId() external view returns (uint256);
    function destinationChainId() external view returns (uint256);
}


// File contracts/Forwarder.sol
pragma solidity ^0.8.0;

contract Forwarder {
  event PassToEth(bytes32 indexed msgId, address mediator, bytes data);
  event PassToBsc(bytes32 indexed msgId, address mediator, bytes data);
  
  IAMB bscAmb;
  IAMB ethAmb;
  
  address ethMediator;
  address bscMediator;
  uint256 gasLimit;

  bool isFrozen;
  
  constructor(address _bscAmb, address _ethAmb) {
    bscAmb = IAMB(_bscAmb);
    ethAmb = IAMB(_ethAmb);
  }

  function set(address _ethMediator,
               address _bscMediator,
               uint256 _gasLimit) public {
    require(!isFrozen, "Contract is frozen");
    ethMediator = _ethMediator;
    bscMediator = _bscMediator;
    gasLimit = _gasLimit;
  }

  function freeze() public {
    isFrozen = true;
  }

  function forwardToEth(address _mediator, bytes calldata _data) public {
    require(msg.sender == address(bscAmb), "Only AMB can call.");
    require(bscAmb.messageSender() == bscMediator, "Not receiving this from BSC Mediator.");
    bytes32 msgId = ethAmb.requireToPassMessage(
        _mediator,
        _data,
        gasLimit
    );
    
    emit PassToEth(msgId, _mediator, _data);
  }

  function forwardToBsc(address _mediator, bytes calldata _data) public {
    require(msg.sender == address(ethAmb), "Only AMB can call.");
    require(ethAmb.messageSender() == ethMediator, "Not receiving this from ETH Mediator.");
    bytes32 msgId = bscAmb.requireToPassMessage(
        _mediator,
        _data,
        gasLimit
    );

    emit PassToBsc(msgId, _mediator, _data);
  }
}


// File contracts/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
  function mint(address to, uint256 amount) external returns (bool);
  function burn(address from, uint256 amount) external returns (bool);
  function burnFrom(address from, uint256 amount) external returns (bool);
}


// File contracts/ITokenRecipient.sol

pragma solidity ^0.8.0;

/// @title Interface of recipient contract for `approveAndCall` pattern.
///        Implementors will be able to be used in an `approveAndCall`
///        interaction with a supporting contract, such that a token approval
///        can call the contract acting on that approval in a single
///        transaction.
///
///        See the `FundingScript` and `RedemptionScript` contracts as examples.
interface ITokenRecipient {
  /// Typically called from a token contract's `approveAndCall` method, this
  /// method will receive the original owner of the token (`_from`), the
  /// transferred `_value` (in the case of an ERC721, the token id), the token
  /// address (`_token`), and a blob of `_extraData` that is informally
  /// specified by the implementor of this method as a way to communicate
  /// additional parameters.
  ///
  /// Token calls to `receiveApproval` should revert if `receiveApproval`
  /// reverts, and reverts should remove the approval.
  ///
  /// @param _from The original owner of the token approved for transfer.
  /// @param _value For an ERC20, the amount approved for transfer; for an
  ///        ERC721, the id of the token approved for transfer.
  /// @param _token The address of the contract for the token whose transfer
  ///        was approved.
  /// @param _extraData An additional data blob forwarded unmodified through
  ///        `approveAndCall`, used to allow the token owner to pass
  ///         additional parameters and data to this method. The structure of
  ///         the extra data is informally specified by the implementor of
  ///         this interface.
  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes calldata _extraData
  ) external;
}


// File contracts/Mediator.sol

pragma solidity ^0.8.0;




contract Mediator is ITokenRecipient {
  event StartCross(bytes32 indexed msgId,
                   bool isTrdl,
                   address indexed sender,
                   address indexed recipient,
                   uint256 value);
  event EndCross(bool isTrdl,
                 address indexed recipient,
                 uint256 value);
  
  IAMB public amb;
  
  IERC20 public strudel;
  IERC20 public vbch;
  address public otherMediator;
  address public forwarder;
  uint256 public gasLimit;
  bool isMainnet;

  bool isFrozen;

  constructor(address _amb) {
    amb = IAMB(_amb);
  }

  function set(address _strudel,
               address _vbch,
               address _otherMediator,
               address _forwarder,
               uint256 _gasLimit,
               bool _isMainnet) public {
    require(!isFrozen, "Contract is frozen");
    strudel = IERC20(_strudel);
    vbch = IERC20(_vbch);
    otherMediator = _otherMediator;
    forwarder = _forwarder;
    gasLimit = _gasLimit;
    isMainnet = _isMainnet;
  }

  function freeze() public {
    isFrozen = true;
  }

  function startCross(bool isTrdl, uint256 _value, address _recipient) public returns (bool) {

    bytes4 methodSelector = Mediator(address(0)).endCross.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, isTrdl, _value, _recipient);

    bytes4 f_methodSelector;
    if (isMainnet) {
      f_methodSelector = Forwarder(address(0)).forwardToBsc.selector;
    } else {
      f_methodSelector = Forwarder(address(0)).forwardToEth.selector;
    }
    bytes memory f_data = abi.encodeWithSelector(f_methodSelector, otherMediator, data);
    
    bytes32 msgId = amb.requireToPassMessage(
        forwarder,
        f_data,
        gasLimit
    );

    if (isTrdl) {
      strudel.burn(msg.sender, _value);
    } else {
      vbch.burn(msg.sender, _value);
    }
    
    emit StartCross(msgId, isTrdl, msg.sender, _recipient, _value);
    return true;
  }

  // for strudel: only called on mainnet
  function receiveApproval(address _from,
                           uint256 _value,
                           address _token,
                           bytes calldata _extraData
                           ) external override {
    require(msg.sender == address(strudel), "Only strudel can call.");
    require(_token == address(strudel), "Only strudel can call.");

    address _recipient = getAddr(_extraData);

    bytes4 methodSelector = Mediator(address(0)).endCross.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, true, _value, _recipient);

    bytes4 f_methodSelector = Forwarder(address(0)).forwardToBsc.selector;
    bytes memory f_data = abi.encodeWithSelector(f_methodSelector, otherMediator, data);
    
    bytes32 msgId = amb.requireToPassMessage(
        forwarder,
        f_data,
        gasLimit
    );

    strudel.burnFrom(_from, _value);
    emit StartCross(msgId, true, _from, _recipient, _value);
  }

  function endCross(bool isTrdl, uint256 _value, address _recipient) public returns (bool) {
    require(msg.sender == address(amb), "Only AMB can call.");
    require(amb.messageSender() == forwarder, "Not receiving this from forwarder");

    if (isTrdl) {
      strudel.mint(_recipient, _value);
    } else {
      vbch.mint(_recipient, _value);
    }
    
    emit EndCross(isTrdl, _recipient, _value);
    return true;
  }

  function getAddr(bytes memory _extraData) internal pure returns (address){
    address addr;
    assembly {
      addr := mload(add(_extraData,20))
    }
    return addr;
  }
}