pragma solidity ^0.4.23;

// File: contracts/classes/sale/ISale.sol

interface ISale {
  function buy() external payable;
}

// File: contracts/classes/sale_manager/ISaleManager.sol

interface ISaleManager {
  function getAdmin() external view returns (address);
  function getCrowdsaleInfo() external view returns (uint, address, bool, bool);
  function isCrowdsaleFull() external view returns (bool, uint);
  function getCrowdsaleStartAndEndTimes() external view returns (uint, uint);
  function getCurrentTierInfo() external view returns (bytes32, uint, uint, uint, uint, uint, bool, bool);
  function getCrowdsaleTier(uint) external view returns (bytes32, uint, uint, uint, uint, bool, bool);
  function getTierWhitelist(uint) external view returns (uint, address[]);
  function getCrowdsaleMaxRaise() external view returns (uint, uint);
  function getCrowdsaleTierList() external view returns (bytes32[]);
  function getCrowdsaleUniqueBuyers() external view returns (uint);
  function getTierStartAndEndDates(uint) external view returns (uint, uint);
  function getTokensSold() external view returns (uint);
  function getWhitelistStatus(uint, address) external view returns (uint, uint);
}

interface SaleManagerIdx {
  function getAdmin(address, bytes32) external view returns (address);
  function getCrowdsaleInfo(address, bytes32) external view returns (uint, address, bool, bool);
  function isCrowdsaleFull(address, bytes32) external view returns (bool, uint);
  function getCrowdsaleStartAndEndTimes(address, bytes32) external view returns (uint, uint);
  function getCurrentTierInfo(address, bytes32) external view returns (bytes32, uint, uint, uint, uint, uint, bool, bool);
  function getCrowdsaleTier(address, bytes32, uint) external view returns (bytes32, uint, uint, uint, uint, bool, bool);
  function getTierWhitelist(address, bytes32, uint) external view returns (uint, address[]);
  function getCrowdsaleMaxRaise(address, bytes32) external view returns (uint, uint);
  function getCrowdsaleTierList(address, bytes32) external view returns (bytes32[]);
  function getCrowdsaleUniqueBuyers(address, bytes32) external view returns (uint);
  function getTierStartAndEndDates(address, bytes32, uint) external view returns (uint, uint);
  function getTokensSold(address, bytes32) external view returns (uint);
  function getWhitelistStatus(address, bytes32, uint, address) external view returns (uint, uint);
}

// File: contracts/classes/token/IToken.sol

interface IToken {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function decimals() external view returns (uint8);
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

// File: contracts/classes/token_manager/ITokenManager.sol

interface ITokenManager {
  function getReservedTokenDestinationList() external view returns (uint, address[]);
  function getReservedDestinationInfo(address) external view returns (uint, uint, uint, uint);
}

interface TokenManagerIdx {
  function getReservedTokenDestinationList(address, bytes32) external view returns (uint, address[]);
  function getReservedDestinationInfo(address, bytes32, address) external view returns (uint, uint, uint, uint);
}

// File: contracts/IMintedCapped.sol

interface IMintedCapped {
  function init(address, uint, bytes32, uint, uint, uint, uint, bool, bool, address) external;
}

// File: authos-solidity/contracts/interfaces/StorageInterface.sol

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

// File: authos-solidity/contracts/core/Proxy.sol

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

  // Function selector for storage &#39;exec&#39; function
  bytes4 internal constant EXEC_SEL = bytes4(keccak256(&#39;exec(address,bytes32,bytes)&#39;));

  // Event emitted in case of a revert from storage
  event StorageException(bytes32 indexed execution_id, string message);

  // For storage refunds
  function () external payable { }

  // Constructor - sets proxy admin, as well as initial variables
  constructor (address _storage, bytes32 _registry_exec_id, address _provider, bytes32 _app_name) public {
    proxy_admin = msg.sender;
    app_storage = StorageInterface(_storage);
    registry_exec_id = _registry_exec_id;
    provider = _provider;
    app_name = _app_name;
  }

  // Declare abstract execution function -
  function exec(bytes _calldata) external payable returns (bool);

  // Checks to see if an error message was returned with the failed call, and emits it if so -
  function checkErrors() internal {
    // If the returned data begins with selector &#39;Error(string)&#39;, get the contained message -
    string memory message;
    bytes4 err_sel = bytes4(keccak256(&#39;Error(string)&#39;));
    assembly {
      // Get pointer to free memory, place returned data at pointer, and update free memory pointer
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, returndatasize)
      mstore(0x40, add(ptr, returndatasize))

      // Check value at pointer for equality with Error selector -
      if eq(mload(ptr), and(err_sel, 0xffffffff00000000000000000000000000000000000000000000000000000000)) {
        message := add(0x24, ptr)
      }
    }
    // If no returned message exists, emit a default error message. Otherwise, emit the error message
    if (bytes(message).length == 0)
      emit StorageException(app_exec_id, "No error recieved");
    else
      emit StorageException(app_exec_id, message);
  }
}

// File: authos-solidity/contracts/lib/StringUtils.sol

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

// File: contracts/MintedCappedProxy.sol

contract SaleProxy is ISale, Proxy {

  // Allows a sender to purchase tokens from the active sale
  function buy() external payable {
    if (address(app_storage).call.value(msg.value)(abi.encodeWithSelector(
      EXEC_SEL, msg.sender, app_exec_id, msg.data
    )) == false) checkErrors(); // Call failed - emit errors
    // Return unspent wei to sender
    address(msg.sender).transfer(address(this).balance);
  }
}

contract SaleManagerProxy is ISaleManager, SaleProxy {

  /*
  Returns the admin address for the crowdsale

  @return address: The admin of the crowdsale
  */
  function getAdmin() external view returns (address) {
    return SaleManagerIdx(app_index).getAdmin(app_storage, app_exec_id);
  }

  /*
  Returns information about the ongoing sale -

  @return uint: The total number of wei raised during the sale
  @return address: The team funds wallet
  @return bool: Whether the sale is finished configuring
  @return bool: Whether the sale has completed
  */
  function getCrowdsaleInfo() external view returns (uint, address, bool, bool) {
    return SaleManagerIdx(app_index).getCrowdsaleInfo(app_storage, app_exec_id);
  }

  /*
  Returns whether or not the sale is full, as well as the maximum number of sellable tokens

  @return bool: Whether or not the sale is sold out
  @return uint: The total number of tokens for sale
  */
  function isCrowdsaleFull() external view returns (bool, uint) {
    return SaleManagerIdx(app_index).isCrowdsaleFull(app_storage, app_exec_id);
  }

  /*
  Returns the start and end times of the sale

  @return uint: The time at which the sale will begin
  @return uint: The time at which the sale will end
  */
  function getCrowdsaleStartAndEndTimes() external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getCrowdsaleStartAndEndTimes(app_storage, app_exec_id);
  }

  /*
  Returns information about the current sale tier

  @return bytes32: The tier&#39;s name
  @return uint: The index of the tier
  @return uint: The time at which the tier will end
  @return uint: The number of tokens remaining for sale during this tier
  @return uint: The price of 1 token (10^decimals units) in wei
  @return uint: The minimum amount of tokens that must be purchased during this tier
  @return bool: Whether the tier&#39;s duration can be modified by the sale admin, prior to it beginning
  @return bool: Whether the tier is whitelisted
  */
  function getCurrentTierInfo() external view returns (bytes32, uint, uint, uint, uint, uint, bool, bool) {
    return SaleManagerIdx(app_index).getCurrentTierInfo(app_storage, app_exec_id);
  }

  /*
  Returns information about the tier represented by the given index

  @param _idx: The index of the tier about which information will be returned
  @return bytes32: The tier&#39;s name
  @return uint: The number of tokens available for sale during this tier, in total
  @return uint: The price of 1 token (10^decimals units) in wei
  @return uint: The duration the tier lasts
  @return uint: The minimum amount of tokens that must be purchased during this tier
  @return bool: Whether the tier&#39;s duration can be modified by the sale admin, prior to it beginning
  @return bool: Whether the tier is whitelisted
  */
  function getCrowdsaleTier(uint _idx) external view returns (bytes32, uint, uint, uint, uint, bool, bool) {
    return SaleManagerIdx(app_index).getCrowdsaleTier(app_storage, app_exec_id, _idx);
  }

  /*
  Returns the whitelist associated with the given tier

  @param _tier_idx: The index of the tier about which information will be returned
  @return uint: The length of the whitelist
  @return address[]: The list of addresses whitelisted
  */
  function getTierWhitelist(uint _tier_idx) external view returns (uint, address[]) {
    return SaleManagerIdx(app_index).getTierWhitelist(app_storage, app_exec_id, _tier_idx);
  }

  /*
  Returns the maximum amount of wei that can be raised, as well as the total number of tokens that can be sold

  @return uint: The maximum amount of wei that can be raised
  @return uint: The total number of tokens that can be sold
  */
  function getCrowdsaleMaxRaise() external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getCrowdsaleMaxRaise(app_storage, app_exec_id);
  }

  /*
  Returns a list of the sale&#39;s tier names

  @return bytes32[]: A list of the names of each of the tiers of the sale (names may not be unique)
  */
  function getCrowdsaleTierList() external view returns (bytes32[]) {
    return SaleManagerIdx(app_index).getCrowdsaleTierList(app_storage, app_exec_id);
  }

  /*
  Returns the number of unique contributors to the sale

  @return uint: The number of unique contributors to the sale
  */
  function getCrowdsaleUniqueBuyers() external view returns (uint) {
    return SaleManagerIdx(app_index).getCrowdsaleUniqueBuyers(app_storage, app_exec_id);
  }

  /*
  Returns the start and end time of the given tier

  @param _idx: The index of the tier about which information will be returned
  @return uint: The time at which the tier will begin
  @return uint: The time at which the tier will end
  */
  function getTierStartAndEndDates(uint _idx) external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getTierStartAndEndDates(app_storage, app_exec_id, _idx);
  }

  /*
  Returns the total number of tokens sold during the sale

  @return uint: The total number of tokens sold during the sale
  */
  function getTokensSold() external view returns (uint) {
    return SaleManagerIdx(app_index).getTokensSold(app_storage, app_exec_id);
  }

  /*
  Returns whitelist information for a buyer during a given tier

  @param _tier: The index of the tier whose whitelist will be queried
  @param _buyer: The address about which the whitelist information will be retrieved
  @return uint: The minimum number of tokens the buyer must make during the sale
  @return uint: The maximum amount of tokens able to be purchased by the buyer this tier
  */
  function getWhitelistStatus(uint _tier, address _buyer) external view returns (uint, uint) {
    return SaleManagerIdx(app_index).getWhitelistStatus(app_storage, app_exec_id, _tier, _buyer);
  }
}

contract TokenManagerProxy is ITokenManager, SaleManagerProxy {

  /*
  Returns the list of addresses for which tokens have been reserved

  @return uint: The length of the list
  @return address[]: The list of destinations
  */
  function getReservedTokenDestinationList() external view returns (uint, address[]) {
    return TokenManagerIdx(app_index).getReservedTokenDestinationList(app_storage, app_exec_id);
  }

  /*
  Returns information about a reserved token destination

  @param _destination: The address whose reservation information will be queried
  @return uint: The index of the address in the reservation list
  @return uint: The number of tokens that will be minted for the destination when the sale is completed
  @return uint: The percent of tokens sold that will be minted for the destination when the sale is completed
  @return uint: The number of decimals in the above percent figure
  */
  function getReservedDestinationInfo(address _destination) external view returns (uint, uint, uint, uint) {
    return TokenManagerIdx(app_index).getReservedDestinationInfo(app_storage, app_exec_id, _destination);
  }
}

contract TokenProxy is IToken, TokenManagerProxy {

  using StringUtils for bytes32;

  // Returns the name of the token
  function name() external view returns (string) {
    return TokenIdx(app_index).name(app_storage, app_exec_id).toStr();
  }

  // Returns the symbol of the token
  function symbol() external view returns (string) {
    return TokenIdx(app_index).symbol(app_storage, app_exec_id).toStr();
  }

  // Returns the number of decimals the token has
  function decimals() external view returns (uint8) {
    return TokenIdx(app_index).decimals(app_storage, app_exec_id);
  }

  // Returns the total supply of the token
  function totalSupply() external view returns (uint) {
    return TokenIdx(app_index).totalSupply(app_storage, app_exec_id);
  }

  // Returns the token balance of the owner
  function balanceOf(address _owner) external view returns (uint) {
    return TokenIdx(app_index).balanceOf(app_storage, app_exec_id, _owner);
  }

  // Returns the number of tokens allowed by the owner to be spent by the spender
  function allowance(address _owner, address _spender) external view returns (uint) {
    return TokenIdx(app_index).allowance(app_storage, app_exec_id, _owner, _spender);
  }

  // Executes a transfer, sending tokens to the recipient
  function transfer(address _to, uint _amt) external returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Transfer(msg.sender, _to, _amt);
    return true;
  }

  // Executes a transferFrom, transferring tokens from the _from account by using an allowed amount
  function transferFrom(address _from, address _to, uint _amt) external returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Transfer(_from, _to, _amt);
    return true;
  }

  // Approve a spender for a given amount
  function approve(address _spender, uint _amt) external returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Approval(msg.sender, _spender, _amt);
    return true;
  }

  // Increase the amount approved for the spender
  function increaseApproval(address _spender, uint _amt) external returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Approval(msg.sender, _spender, _amt);
    return true;
  }

  // Decrease the amount approved for the spender, to a minimum of 0
  function decreaseApproval(address _spender, uint _amt) external returns (bool) {
    app_storage.exec(msg.sender, app_exec_id, msg.data);
    emit Approval(msg.sender, _spender, _amt);
    return true;
  }
}

contract MintedCappedProxy is IMintedCapped, TokenProxy {

  // Constructor - sets storage address, registry id, provider, and app name
  constructor (address _storage, bytes32 _registry_exec_id, address _provider, bytes32 _app_name) public
    Proxy(_storage, _registry_exec_id, _provider, _app_name) { }

  // Constructor - creates a new instance of the application in storage, and sets this proxy&#39;s exec id
  function init(address, uint, bytes32, uint, uint, uint, uint, bool, bool, address) external {
    require(msg.sender == proxy_admin && app_exec_id == 0 && app_name != 0);
    (app_exec_id, app_version) = app_storage.createInstance(
      msg.sender, app_name, provider, registry_exec_id, msg.data
    );
    app_index = app_storage.getIndex(app_exec_id);
  }

  // Executes an arbitrary function in this application
  function exec(bytes _calldata) external payable returns (bool success) {
    require(app_exec_id != 0 && _calldata.length >= 4);
    // Call &#39;exec&#39; in AbstractStorage, passing in the sender&#39;s address, the app exec id, and the calldata to forward -
    app_storage.exec.value(msg.value)(msg.sender, app_exec_id, _calldata);

    // Get returned data
    success = checkReturn();
    // If execution failed, emit errors -
    if (!success) checkErrors();

    // Transfer any returned wei back to the sender
    msg.sender.transfer(address(this).balance);
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