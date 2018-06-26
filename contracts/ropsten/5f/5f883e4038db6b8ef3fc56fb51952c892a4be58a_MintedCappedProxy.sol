pragma solidity ^0.4.23;

interface ISale {
  function buy() external payable;
}

interface ISaleManager {
  function getCrowdsaleInfo() external view returns (uint, address, uint, bool, bool);
  function isCrowdsaleFull() external view returns (bool, uint);
  function getCrowdsaleStartAndEndTimes() external view returns (uint, uint);
  function getCurrentTierInfo() external view returns (bytes32, uint, uint, uint, uint, bool, bool);
  function getCrowdsaleTier(uint) external view returns (bytes32, uint, uint, uint, bool, bool);
  function getCrowdsaleMaxRaise() external view returns (uint, uint);
  function getCrowdsaleTierList() external view returns (bytes32[]);
  function getTierStartAndEndDates(uint) external view returns (uint, uint);
  function getTokensSold() external view returns (uint);
  function getWhitelistStatus(uint, address) external view returns (uint, uint);
}

interface SaleManagerIdx {
  function getCrowdsaleInfo(address, bytes32) external view returns (uint, address, uint, bool, bool);
  function isCrowdsaleFull(address, bytes32) external view returns (bool, uint);
  function getCrowdsaleStartAndEndTimes(address, bytes32) external view returns (uint, uint);
  function getCurrentTierInfo(address, bytes32) external view returns (bytes32, uint, uint, uint, uint, bool, bool);
  function getCrowdsaleTier(address, bytes32, uint) external view returns (bytes32, uint, uint, uint, bool, bool);
  function getCrowdsaleMaxRaise(address, bytes32) external view returns (uint, uint);
  function getCrowdsaleTierList(address, bytes32) external view returns (bytes32[]);
  function getTierStartAndEndDates(address, bytes32, uint) external view returns (uint, uint);
  function getTokensSold(address, bytes32) external view returns (uint);
  function getWhitelistStatus(address, bytes32, uint, address) external view returns (uint, uint);
}

interface IToken {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function decimals() external view returns (uint);
  function totalSupply() external view returns (uint);
  function balanceOf(address) external view returns (uint);
  function allowance(address, address) external view returns (uint);
  function transfer(address, uint) external returns (bool);
  function transferFrom(address, address, uint) external returns (bool);
  function approve(address, uint) external returns (bool);
  function increaseApproval(address, uint) external returns (bool);
  function decreaseApproval(address, uint) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint amt);
  event Approval(address indexed owner, address indexed spender, uint amt);
}

interface TokenIdx {
  function name(address, bytes32) external view returns (bytes32);
  function symbol(address, bytes32) external view returns (bytes32);
  function decimals(address, bytes32) external view returns (uint8);
  function totalSupply(address, bytes32) external view returns (uint);
  function balanceOf(address, bytes32, address) external view returns (uint);
  function allowance(address, bytes32, address, address) external view returns (uint);
}

interface IMintedCapped {
  function init(address, uint, bytes32, uint, uint, uint, bool, bool, address) external;
}

interface StorageInterface {
  function getTarget(bytes32 exec_id, bytes4 selector)
      external view returns (address implementation);
  function getIndex(bytes32 exec_id) external view returns (address index);
  function createInstance(address sender, bytes32 app_name, address provider, bytes32 registry_exec_id, bytes calldata)
      external payable returns (bytes32 instance_exec_id, bytes32 version);
  function createRegistry(address index, address implementation) external returns (bytes32 exec_id);
  function exec(address sender, bytes32 exec_id, bytes calldata)
      external payable returns (uint emitted, uint paid, uint stored);
}

library StringUtils {

  function toStr(bytes32 _val) internal pure returns (string memory str) {
    assembly {
      str := mload(0x40)
      mstore(str, 0x20)
      mstore(add(0x20, str), _val)
      mstore(0x40, add(0x40, str))
    }
  }
}

contract Proxy {

  // Registry storage
  address public proxy_admin;
  StorageInterface public app_storage;
  bytes32 public registry_exec_id;
  address public provider;
  bytes32 public app_name;

  // App storage
  bytes32 public app_version;
  bytes32 public app_exec_id;
  address public app_index;

  function () external payable { }

  constructor (address _storage, bytes32 _registry_exec_id, address _provider, bytes32 _app_name) public {
    proxy_admin = msg.sender;
    app_storage = StorageInterface(_storage);
    registry_exec_id = _registry_exec_id;
    provider = _provider;
    app_name = _app_name;
  }
}

contract SaleProxy is ISale, Proxy {

  function buy() public payable {
    app_storage.exec.value(msg.value)(msg.sender, app_exec_id, msg.data);
  }
}

contract SaleManagerProxy is ISaleManager, SaleProxy {

  function getCrowdsaleInfo() external view returns (uint, address, uint, bool, bool) {
    return SaleManagerIdx(app_index).getCrowdsaleInfo(app_storage, app_exec_id);
  }

  function isCrowdsaleFull() external view returns (bool, uint) {
    return SaleManagerIdx(app_index).isCrowdsaleFull(app_storage, app_exec_id);
  }

  function getCrowdsaleStartAndEndTimes() external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getCrowdsaleStartAndEndTimes(app_storage, app_exec_id);
  }

  function getCurrentTierInfo() external view returns (bytes32, uint, uint, uint, uint, bool, bool) {
    return SaleManagerIdx(app_index).getCurrentTierInfo(app_storage, app_exec_id);
  }

  function getCrowdsaleTier(uint _idx) external view returns (bytes32, uint, uint, uint, bool, bool) {
    return SaleManagerIdx(app_index).getCrowdsaleTier(app_storage, app_exec_id, _idx);
  }

  function getCrowdsaleMaxRaise() external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getCrowdsaleMaxRaise(app_storage, app_exec_id);
  }

  function getCrowdsaleTierList() external view returns (bytes32[]) {
    return SaleManagerIdx(app_index).getCrowdsaleTierList(app_storage, app_exec_id);
  }

  function getTierStartAndEndDates(uint _idx) external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getTierStartAndEndDates(app_storage, app_exec_id, _idx);
  }

  function getTokensSold() external view returns (uint) {
    return SaleManagerIdx(app_index).getTokensSold(app_storage, app_exec_id);
  }

  function getWhitelistStatus(uint _tier, address _buyer) external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getWhitelistStatus(app_storage, app_exec_id, _tier, _buyer);
  }
}

contract TokenProxy is IToken, SaleManagerProxy {

  using StringUtils for bytes32;

  function name() public view returns (string) {
    return TokenIdx(app_index).name(app_storage, app_exec_id).toStr();
  }

  function symbol() public view returns (string) {
    return TokenIdx(app_index).symbol(app_storage, app_exec_id).toStr();
  }

  function decimals() public view returns (uint8) {
    return TokenIdx(app_index).decimals(app_storage, app_exec_id);
  }

  function totalSupply() public view returns (uint) {
    return TokenIdx(app_index).totalSupply(app_storage, app_exec_id);
  }

  function balanceOf(address _owner) public view returns (uint) {
    return TokenIdx(app_index).balanceOf(app_storage, app_exec_id, _owner);
  }

  function allowance(address _owner, address _spender) public view returns (uint) {
    return TokenIdx(app_index).allowance(app_storage, app_exec_id, _owner, _spender);
  }

  function transfer(address _to, uint _amt) public returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Transfer(msg.sender, _to, _amt);
  }

  function transferFrom(address _from, address _to, uint _amt) public returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Transfer(_from, _to, _amt);
  }

  function approve(address _spender, uint _amt) public returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Approval(msg.sender, _spender, _amt);
  }

  function increaseApproval(address _spender, uint _amt) public returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Approval(msg.sender, _spender, _amt);
  }

  function decreaseApproval(address _spender, uint _amt) public returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Approval(msg.sender, _spender, _amt);
  }
}

contract MintedCappedProxy is IMintedCapped, TokenProxy {

  constructor (address _storage, bytes32 _registry_exec_id, address _provider, bytes32 _app_name) public
    Proxy(_storage, _registry_exec_id, _provider, _app_name) { }

  function init(address, uint, bytes32, uint, uint, uint, bool, bool, address) public {
    require(msg.sender == proxy_admin && app_exec_id == 0 && app_name != 0);
    (app_exec_id, app_version) = app_storage.createInstance(
      msg.sender, app_name, provider, registry_exec_id, msg.data
    );
    app_index = app_storage.getIndex(app_exec_id);
  }

  function exec(bytes32 _exec_id, bytes _calldata) external payable returns (bool success) {
    // Call &#39;exec&#39; in AbstractStorage, passing in the sender&#39;s address, the app exec id, and the calldata to forward -
    app_storage.exec.value(msg.value)(msg.sender, _exec_id, _calldata);

    // Get returned data
    success = checkReturn();
    // If execution failed, revert -
    require(success, &#39;Execution failed&#39;);

    // Transfer any returned wei back to the sender
    address(msg.sender).transfer(address(this).balance);
  }

  // Checks data returned by an application and returns whether or not the execution changed state
  function checkReturn() internal pure returns (bool success) {
    success = false;
    assembly {
      // returndata size must be 0x60 bytes
      if eq(returndatasize, 0x60) {
        // Copy returned data to pointer and check that at least one value is nonzero
        let ptr := mload(0x40)
        returndatacopy(ptr, 0, returndatasize)
        if iszero(iszero(mload(ptr))) { success := 1 }
        if iszero(iszero(mload(add(0x20, ptr)))) { success := 1 }
        if iszero(iszero(mload(add(0x40, ptr)))) { success := 1 }
      }
    }
    return success;
  }
}