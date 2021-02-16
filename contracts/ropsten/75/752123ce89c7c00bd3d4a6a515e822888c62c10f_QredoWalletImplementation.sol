// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "./ECDSA.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IQredoWalletImplementation.sol";

// WalletImplementation => WI

contract QredoWalletImplementation is IQredoWalletImplementation {
  using ECDSA for bytes32;
  using SafeMath for uint256;

  uint256 constant private INCREMENT = 1;
  uint256 private _nonce;
  address private _walletOwner;
  bool private _locked;
  bool private _initialized;
  
  /**
    * @dev Throws if contract is initialized.
  */
  modifier isInitialized() {
      require(!_initialized, "WI::isInitialized:already initialized"); 
      _;
      _initialized = true;
  }

  /**
    * @dev Sets the values for {_walletOwner}
    *
    * This value is immutable: it can only be set once during
    * initialization.
  */
  function init(address walletOwner) isInitialized() external override {
    require(walletOwner != address(0), "WI::init: _walletOwner address can't be 0!");
    _walletOwner = walletOwner;
  }

  modifier noReentrancy() {
      require(!_locked, "WI::noReentrancy:Reentrant call.");
      _locked = true;
      _;
      _locked = false;
  }

  modifier onlySigner(address _to, uint256 _value, bytes calldata _data, bytes memory signature) {
    require(_to != address(0), "WI::onlySigner:to address can not be 0");
    bytes memory payload = abi.encode(_to, _value, _data, _nonce);
    address signatureAddress = keccak256(payload).toEthSignedMessageHash().recover(signature);
    require(_walletOwner == signatureAddress, "WI::onlySigner:Failed to verify signature");
    _;
  }

  function invoke(bytes memory signature, address _to, uint256 _value, bytes calldata _data) noReentrancy() onlySigner(_to, _value, _data, signature) external override returns (bytes memory _result) {
    bool success;
    (success, _result) = _to.call{value: _value}(_data);
    if (!success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    emit Invoked(msg.sender, _to, _value, _nonce, _data); 
    _nonce = _nonce.add(INCREMENT);
  }
  
  receive() external payable {
      emit Received(msg.sender, msg.value, msg.data);
  }
  
  fallback() external payable {
      emit Fallback(msg.sender, msg.value, msg.data);
  }

  /**
    * @dev Returns Balance of this contract for the current token
  */
  function getBalance(address tokenAddress) external override view returns(uint256 _balance) {
    return IERC20(tokenAddress).balanceOf(address(this));
  }

  /**
    * @dev Returns nonce;
  */
  function getNonce() external override view returns(uint256 nonce) {
    return _nonce;
  }

  /**
    * @dev Returns walletOwner address;
  */
  function getWalletOwnerAddress() external override view returns(address walletOwner) {
    return _walletOwner;
  }
}