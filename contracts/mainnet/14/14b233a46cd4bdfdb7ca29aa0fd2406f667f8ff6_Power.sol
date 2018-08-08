pragma solidity 0.4.16;


contract ControllerInterface {


  // State Variables
  bool public paused;
  address public nutzAddr;

  // Nutz functions
  function babzBalanceOf(address _owner) constant returns (uint256);
  function activeSupply() constant returns (uint256);
  function burnPool() constant returns (uint256);
  function powerPool() constant returns (uint256);
  function totalSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);

  function approve(address _owner, address _spender, uint256 _amountBabz) public;
  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public;
  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public;

  // Market functions
  function floor() constant returns (uint256);
  function ceiling() constant returns (uint256);

  function purchase(address _sender, uint256 _value, uint256 _price) public returns (uint256);
  function sell(address _from, uint256 _price, uint256 _amountBabz);

  // Power functions
  function powerBalanceOf(address _owner) constant returns (uint256);
  function outstandingPower() constant returns (uint256);
  function authorizedPower() constant returns (uint256);
  function powerTotalSupply() constant returns (uint256);

  function powerUp(address _sender, address _from, uint256 _amountBabz) public;
  function downTick(address _owner, uint256 _now) public;
  function createDownRequest(address _owner, uint256 _amountPower) public;
  function downs(address _owner) constant public returns(uint256, uint256, uint256);
  function downtime() constant returns (uint256);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  function totalSupply() constant returns (uint256);
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}


contract Power is Ownable, ERC20Basic {

  event Slashing(address indexed holder, uint value, bytes32 data);

  string public name = "Acebusters Power";
  string public symbol = "ABP";
  uint256 public decimals = 12;


  function balanceOf(address _holder) constant returns (uint256) {
    return ControllerInterface(owner).powerBalanceOf(_holder);
  }

  function totalSupply() constant returns (uint256) {
    return ControllerInterface(owner).powerTotalSupply();
  }

  function activeSupply() constant returns (uint256) {
    return ControllerInterface(owner).outstandingPower();
  }


  // ############################################
  // ########### ADMIN FUNCTIONS ################
  // ############################################

  function slashPower(address _holder, uint256 _value, bytes32 _data) public onlyOwner {
    Slashing(_holder, _value, _data);
  }

  function powerUp(address _holder, uint256 _value) public onlyOwner {
    // NTZ transfered from user&#39;s balance to power pool
    Transfer(address(0), _holder, _value);
  }

  // ############################################
  // ########### PUBLIC FUNCTIONS ###############
  // ############################################

  // registers a powerdown request
  function transfer(address _to, uint256 _amountPower) public returns (bool success) {
    // make Power not transferable
    require(_to == address(0));
    ControllerInterface(owner).createDownRequest(msg.sender, _amountPower);
    Transfer(msg.sender, address(0), _amountPower);
    return true;
  }

  function downtime() public returns (uint256) {
    ControllerInterface(owner).downtime;
  }

  function downTick(address _owner) public {
    ControllerInterface(owner).downTick(_owner, now);
  }

  function downs(address _owner) constant public returns (uint256, uint256, uint256) {
    return ControllerInterface(owner).downs(_owner);
  }

}