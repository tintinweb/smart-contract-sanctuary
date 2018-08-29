pragma solidity ^0.4.24;

// File: contracts/ReceivingContractCallback.sol

contract ReceivingContractCallback {

  function tokenFallback(address _from, uint _value) public;

}

// File: contracts/ownership/Ownable.sol

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

// File: contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/IntermediateWallet.sol

contract IntermediateWallet is ReceivingContractCallback, Ownable {
    
  address public token = 0xB36F13C4e2df1b5201e3D64cd79b1897e0E80D39;  

  address public wallet =0x9ff88775a5212373733D041816A2f114769358C6;

  struct TokenTx {
    address from;
    uint amount;
    uint date;
  }

  TokenTx[] public txs;
  
  constructor() public {

  }

  function setToken(address newTokenAddr) public onlyOwner {
    token = newTokenAddr;
  }
  
  function setWallet(address newWallet) public onlyOwner {
    wallet = newWallet;
  }

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20Basic alienToken = ERC20Basic(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

  function () payable public {
    wallet.transfer(msg.value);
  }

  function tokenFallback(address _from, uint _value) public {
    require(msg.sender == token);
    txs.push(TokenTx(_from, _value, now));
    ERC20Basic(token).transfer(wallet, _value);
  }

}