/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

/*
This contract aids the token deposit and registering with the Krakin't exchange.
Data already exists on a block-chain and therefore, it has to be accessed via API calls.
The Administrator account is used to send tokens to and out of the exchange.
Since the Administrator account needs GAS, the users need to deposit the Ethereum necessary to run this contract.
We are also collecting the information from the block-chain and writing it inside the contract.
This way, we can always transfer this data into new databases and make the last solution as decentralized as possible.
There are 3 primary accounts associated with this contract:
- The owner account
- The external contract contract
- The oracle contract

The purpose of the owner is the general maintenance of the contract.
The purpose of admin is to connect to an outside wallet to do the main contract interaction.
The purpose of the external contract is to act as an admin, and as a decentralized solution while standing in a middle.
The purpose of the oracle contract is to enable communication with the oracles to call the blockchain API rather than having a centralized solution.
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.7 .4;

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address internal _owner;
  bool internal pause;
  address internal externalContract;
  address oracleAddress;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    // adminAddress = msgSender;
    externalContract = address(0);
    oracleAddress = address(0);
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }



  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

abstract contract Transfer {
  function transfer(address toAddress, uint256 amount) external virtual;
}

abstract contract OracleCall {
  function registerTransfer(address userAddress, address tokenAddress, uint amount, uint blockNumber) external virtual returns(bool result);
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

}

contract ERC20Deposit is Ownable {
  using SafeMath
  for uint;

  mapping(address => uint) internal registration; //for account flagging, 100 is blacklisted
  mapping(address => string) internal registerData; //for registering tokens, projects, etc
  mapping(address => address) internal associatedAccounts; //krakin't account => user account

  //---------------------------------
  mapping(uint => address) internal pivotToAddress;
  mapping(address => uint) internal addressToPivot;
  uint internal pivot;
  //---------------------------------
  uint internal transactionPivot;
  mapping(uint => uint) internal transactionHistory;
  //------------------

  Transfer internal transfer = Transfer(address(0));
  OracleCall internal oracleCall = OracleCall(address(0));

  //The admin must make this call!
  function registerNewEthBalance( uint blockNumber) external virtual returns(bool success) {
    require(blockNumber > transactionHistory[transactionPivot]);
    address userAddress = associatedAccounts[msg.sender];
    registerUser(userAddress);
    transactionPivot = transactionPivot.add(1);
    transactionHistory[transactionPivot] = blockNumber;
    return true;
  }

  //recover ETH from Admin is a web3 function, not a contract, then another call to registerNewEthBalance is made

  //==== TOKEN ====

  function registerNewTokenBalance(uint blockNumber) external virtual returns(bool success) {
    require(blockNumber > transactionHistory[transactionPivot]);
    address userAddress = associatedAccounts[msg.sender];

    registerUser(userAddress);

    transactionPivot = transactionPivot.add(1);
    transactionHistory[transactionPivot] = blockNumber;

    transfer = Transfer(0);

    return true;
  }

  //The admin must make this call!
  function withdrawTokens(address tokenAddress, uint amount) external virtual returns(bool success) {

    address userAddress = associatedAccounts[msg.sender];

    transfer = Transfer(tokenAddress);

    transactionPivot = transactionPivot.add(1);
    transactionHistory[transactionPivot] = block.number;

    transfer.transfer(userAddress, amount);
    transfer = Transfer(0);


    return true;
  }
  
  function associateNewAccount(address userAddress) external virtual returns(bool success) {
      associatedAccounts[msg.sender] = userAddress;
      return true;
  }

  function registerBalanceWithOracle(address userAddress, address tokenAddress, uint amount, uint blockNumber) external virtual returns(bool success) {
    require(oracleAddress != address(0));
    require(registration[msg.sender] != 100);
    require(blockNumber > transactionHistory[transactionPivot]);

    registerUser(userAddress);
    bool response = oracleCall.registerTransfer(userAddress, tokenAddress, amount, blockNumber);
    if (response) {
      transactionHistory[transactionPivot] = blockNumber;
      transactionPivot = transactionPivot.add(1);
    }

    return true;
  }

  //---------helpers-------
  function registerUser(address userAddress) private returns(bool success) {
    if (addressToPivot[userAddress] == 0) {
      pivot = pivot.add(1);
      addressToPivot[userAddress] = pivot;
      pivotToAddress[pivot] = userAddress;
    }
    return true;
  }

}

contract OnlyOwner is ERC20Deposit {


  function setOracleAddress(address newContract) external onlyOwner virtual returns(bool success) {
    oracleCall = OracleCall(newContract);
    oracleAddress = newContract;
    return true;
  }

  function setExternalContractAddress(address newContract) external onlyOwner virtual returns(bool success) {
    externalContract = newContract;
    return true;
  }

  function setAccountFlag(address userAddress, uint flagType) external onlyOwner virtual returns(bool success) {
    registration[userAddress] = flagType;
    return true;
  }

  function updateRegisterData(address userAddress, string memory data) external virtual onlyOwner returns(bool success) {
    registerData[userAddress] = data;
    return true;
  }

  function flipPauseSwitch() external onlyOwner virtual returns(bool success) {
    pause = !pause;
    return true;
  }
}

contract Views is ERC20Deposit {

  function getExternalContractAddress() public view virtual returns(address externalContract) {
    return externalContract;
  }

  function getOracleAddress() public view virtual returns(address admin) {
    return oracleAddress;
  }

  function getBlockNumber() public view virtual returns(uint blockNumber) {
    return block.number;
  }

  function getAccountFlag(address userAddress) public view virtual returns(uint accountFlag) {
    return registration[userAddress];
  }

  function getRegisterData(address userAddress) public view virtual returns(string memory data) {
    return registerData[userAddress];
  }

  function isPauseOn() public view virtual returns(bool safetySwitch) {
    return pause;
  }

  function getPivot() public view virtual returns(uint pivot) {
    return pivot;
  }

  function getTransactionPivot() public view virtual returns(uint pivot) {
    return transactionPivot;
  }

  function getAddressFromPivot(uint pivot) public view virtual returns(address userAddress) {
    return pivotToAddress[pivot];
  }

  function getPivotFromAddress(address userAddress) public view virtual returns(uint pivot) {
    return addressToPivot[userAddress];
  }

  function getTransactionFromPivot(uint pivot) public view virtual returns(uint transaction) {
    return transactionHistory[pivot];
  }

}