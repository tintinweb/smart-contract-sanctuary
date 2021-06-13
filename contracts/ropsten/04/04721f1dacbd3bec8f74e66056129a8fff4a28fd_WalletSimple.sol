// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.5;
import './TransferHelper.sol';
import './ERC20Interface.sol';
import './WalletFactory.sol';


contract WalletSimple {

    event ForwardDeposited(address from, uint256 value, bytes data);
    event Deposited(address from, uint256 value, bytes data);
  
  mapping(address => bool) public signers; // The addresses that can co-sign transactions on the wallet
  bool public initialized = false; // True if the contract has been initialized
  address walletFactoryAddress;
  

  function init(address[] calldata allowedSigners, address _walletFactoryAddress) external  {
    require(allowedSigners.length == 3, 'Invalid number of signers');
    walletFactoryAddress = _walletFactoryAddress;
    for (uint8 i = 0; i < allowedSigners.length; i++) {
      require(allowedSigners[i] != address(0), 'Invalid signer');
      signers[allowedSigners[i]] = true;
    }
    initialized = true;
  }


  fallback() external payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
     emit Deposited(msg.sender, msg.value, msg.data);
    }
  }


  receive() external payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
     emit Deposited(msg.sender, msg.value, msg.data);
    }
  }
  

  modifier onlyUninitialized {
    require(!initialized, 'Contract already initialized');
    _;
  }



  function flushTokens(address tokenContractAddress) public {
   
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }

    TransferHelper.safeTransfer(
      tokenContractAddress,
      WalletFactory(walletFactoryAddress).showColdWalletAddress(),
      forwarderBalance
    );
  }


  function flush() public {
     
    uint256 value = address(this).balance;
    if (value == 0) {
      return;
    }
    
    (bool success, ) = WalletFactory(walletFactoryAddress).showColdWalletAddress().call{ value: value }('');
    require(success, 'Flush failed');
    emit ForwardDeposited(msg.sender, value, msg.data);
  }

}