// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;
import './TransferHelper.sol';
import './ERC20Interface.sol';
import './hotWalletCreation.sol';


contract SourceHotWallet {
 
    event depositForwarded(address executer, uint256 value, bytes data);
    event depositeDone(address from, uint256 value, bytes data);
    event tokenDepositForwarded(address tokenContractAddress, address _to, uint256 value, bytes data);
    event BatchTransfer(address sender, address recipient, uint256 value);
    event OwnerChange(address prevOwner, address newOwner);
    event TransferGasLimitChange(
    uint256 prevTransferGasLimit,
    uint256 newTransferGasLimit
  );

    mapping(address => bool) public signers;
    address public owner;
    uint256 public lockCounter = 1;
    uint256 public transferGasLimit = 20000;
    bool public initialized = false; 
    address walletCreationAddress;
  
      modifier lockCall() {
        lockCounter++;
        uint256 localCounter = lockCounter;
        _;
        require(localCounter == lockCounter, 'Reentrancy attempt detected');
      }
    
      modifier onlyAdmin() {
        address adminAddress = hotWalletCreation(walletCreationAddress).showAdminAddress();
        require(msg.sender == adminAddress, 'Not Admin');
        _;
      }
      
      modifier onlyWhenNotPause() {
        address adminAddress = hotWalletCreation(walletCreationAddress).showAdminAddress();
        require(msg.sender == adminAddress, 'Not Admin');
        _;
      }



  function init(address[] calldata allowedSigners, address _walletCreationAddress) external onlyUninitialized {
    require(allowedSigners.length == 3, 'Invalid number of signers');
    walletCreationAddress = _walletCreationAddress;
    for (uint8 i = 0; i < allowedSigners.length; i++) {
      require(allowedSigners[i] != address(0), 'Invalid signer');
      signers[allowedSigners[i]] = true;
    }
    initialized = true;
  }


  fallback() external payable {
    if (msg.value > 0) {
        hotWalletCreation(walletCreationAddress).
        DepositDoneEvent(msg.sender, msg.value, address(this), msg.data);
        emit depositeDone(msg.sender, msg.value, msg.data);
    }
  }


  receive() external payable {
    if (msg.value > 0) {
     hotWalletCreation(walletCreationAddress).
     DepositDoneEvent(msg.sender, msg.value, address(this), msg.data);
     emit depositeDone(msg.sender, msg.value, msg.data);
    }
  }

  modifier onlyUninitialized {
    require(!initialized, 'Contract already initialized');
    _;
  }

  function withdrawTokens(address _tokenContractAddress, address _to, uint256 _value)
  public
  payable
  onlyAdmin
  onlyWhenNotPause {
    require(_value > 0);
    require(_tokenContractAddress != address(0));
    require(_to != address(0));
    TransferHelper.safeTransfer(
      _tokenContractAddress,
      _to,
      _value
    );
     emit tokenDepositForwarded(_tokenContractAddress, msg.sender, _value, msg.data);
  }

  function withdrawETH(address _to, uint256 _value)
  public
  payable
  onlyAdmin
  onlyWhenNotPause {
    require(_value > 0);
    require(_to != address(0));
    (bool success, ) = _to.call{ value: _value, gas: transferGasLimit}('');
    require(success, 'Withdraw failed');
    emit depositForwarded(_to, _value, msg.data);
  }
  
  
  function BatchTokens(address _tokenContractAddress, address[] calldata recipients, uint256[] calldata values)
    public
    payable
    lockCall
    onlyAdmin
    onlyWhenNotPause{
    require(_tokenContractAddress != address(0));
    require(recipients.length != 0, 'Must send to at least one person');
    require(
      recipients.length == values.length,
      'Unequal recipients and values'
    );
    require(recipients.length < 256, 'Too many recipients');
    
    for (uint8 i = 0; i < recipients.length; i++) {
        TransferHelper.safeTransfer(
        _tokenContractAddress,
        recipients[i],
        values[i]);
    emit BatchTransfer(msg.sender, recipients[i], values[i]);
    }
    
    }
  
  
  function batchETH(address[] calldata recipients, uint256[] calldata values)
    public
    payable
    lockCall
    onlyAdmin
    onlyWhenNotPause
  {
    require(recipients.length != 0, 'Must send to at least one person');
    require(
      recipients.length == values.length,
      'Unequal recipients and values'
    );
    require(recipients.length < 256, 'Too many recipients');

    // Try to send all given amounts to all given recipients
    // Revert everything if any transfer fails
    for (uint8 i = 0; i < recipients.length; i++) {
      require(recipients[i] != address(0), 'Invalid recipient address');
      (bool success, ) = recipients[i].call{
        value: values[i],
        gas: transferGasLimit
      }('');
      require(success, 'Send failed');
      emit BatchTransfer(msg.sender, recipients[i], values[i]);
    }
  }

 
  function recover(
    address _to,
    uint256 _value
  ) public onlyAdmin returns (bytes memory) {
    (bool success, bytes memory returnData) = _to.call{ value: _value }('');
    return returnData;
  }

  function changeTransferGasLimit(uint256 newTransferGasLimit)
    public
    onlyAdmin
  {
    require(newTransferGasLimit >= 2300, 'Transfer gas limit too low');
    emit TransferGasLimitChange(transferGasLimit, newTransferGasLimit);
    transferGasLimit = newTransferGasLimit;
  }
}