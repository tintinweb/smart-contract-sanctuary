// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.5;
import './TransferHelper.sol';
import './ERC20Interface.sol';
import './IWalletFactory.sol';

/**
 *
 * WalletSimple
 * ============
 *
 * Basic multi-signer wallet designed for use in a co-signing environment where 2 signatures are required to move funds.
 * Typically used in a 2-of-3 signing configuration. Uses ecrecover to allow for 2 signatures in a single transaction.
 *
 * The first signature is created on the operation hash (see Data Formats) and passed to sendMultiSig/sendMultiSigToken
 * The signer is determined by verifyMultiSig().
 *
 * The second signature is created by the submitter of the transaction and determined by msg.signer.
 *
 * Data Formats
 * ============
 *
 * The signature is created with ethereumjs-util.ecsign(operationHash).
 * Like the eth_sign RPC call, it packs the values as a 65-byte array of [r, s, v].
 * Unlike eth_sign, the message is not prefixed.
 *
 * The operationHash the result of keccak256(prefix, toAddress, value, data, expireTime).
 * For ether transactions, `prefix` is "ETHER".
 * For token transaction, `prefix` is "ERC20" and `data` is the tokenContractAddress.
 *
 *
 */
contract WalletSimple {
  // Events
  event ForwarderDeposited(address from, uint256 value, bytes data);
 event Deposited(address from, uint256 value, bytes data);
  // Public fields
  mapping(address => bool) public signers; // The addresses that can co-sign transactions on the wallet
  bool public initialized = false; // True if the contract has been initialized
  address walletFactoryAddress;
  IWalletFactory mainWallet = IWalletFactory(walletFactoryAddress);

  /**
   * Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
   * 2 signers will be required to send a transaction from this wallet.
   * Note: The sender is NOT automatically added to the list of signers.
   * Signers CANNOT be changed once they are set
   *
   * @param allowedSigners An array of signers on the wallet
   */
  

  function init(address[] calldata allowedSigners, address _walletFactoryAddress) external onlyUninitialized {
    require(allowedSigners.length == 3, 'Invalid number of signers');
    walletFactoryAddress = _walletFactoryAddress;
    for (uint8 i = 0; i < allowedSigners.length; i++) {
      require(allowedSigners[i] != address(0), 'Invalid signer');
      signers[allowedSigners[i]] = true;
    }
    initialized = true;
  }

  

  /**
   * Modifier that will execute internal code block only if the contract has not been initialized yet
   */
  modifier onlyUninitialized {
    require(!initialized, 'Contract already initialized');
    _;
  }

 /**
   * Default function; Gets called when data is sent but does not match any other function
   */
  fallback() external payable {
     if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
      emit Deposited(msg.sender, msg.value, msg.data);
     }
  }

   /**
  * Default function; Gets called when Ether is deposited with no data, and forwards it to the parent address
  */
  receive() external payable {
       if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
      emit Deposited(msg.sender, msg.value, msg.data);
    }
  }
 
 
   
   function showwalletFactoryAddress()public view returns(address){
       return(walletFactoryAddress);
   }
    /** 
     * Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushTokens(address tokenContractAddress) public {
      
    require(msg.sender == mainWallet.showDeployerAddress());
      
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }

    TransferHelper.safeTransfer(
      tokenContractAddress,
      mainWallet.showColdWalletAddress(),
      forwarderBalance
    );
  }
  function showdeployerAddressAS()public view returns(address){
      address deployerAddress = mainWallet.showDeployerAddress();
      return(deployerAddress);
                        
  }
   /**
   * Flush the entire balance of the contract to the parent address.
   */
  function flush() public {
      require(msg.sender == showdeployerAddressAS());
    uint256 value = address(this).balance;
    if (value == 0) {
      return;
    }
    
    mainWallet.showColdWalletAddress().call{ value: value };
    emit ForwarderDeposited(msg.sender, value, msg.data);
  }

}