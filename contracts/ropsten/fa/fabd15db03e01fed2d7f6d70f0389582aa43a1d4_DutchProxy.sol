pragma solidity ^0.4.23;

//&quot;0xca35b7d915458ef540ade6068dfe2f44e8fa733c&quot;,&quot;0xa&quot;,&quot;0xca35b7d915458ef540ade6068dfe2f44e8fa733c&quot;,&quot;0xa&quot;

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
      emit StorageException(app_exec_id, &quot;No error recieved&quot;);
    else
      emit StorageException(app_exec_id, message);
  }
}

interface IAdmin {
  function getAdmin() external view returns (address);
  function getCrowdsaleInfo() external view returns (uint, address, uint, bool, bool, bool);
  function isCrowdsaleFull() external view returns (bool, uint);
  function getCrowdsaleStartAndEndTimes() external view returns (uint, uint);
  function getCrowdsaleStatus() external view returns (uint, uint, uint, uint, uint, uint, bool);
  function getTokensSold() external view returns (uint);
  function getCrowdsaleWhitelist() external view returns (uint, address[]);
  function getWhitelistStatus(address) external view returns (uint, uint);
}

interface AdminIdx {
  function getAdmin(address, bytes32) external view returns (address);
  function getCrowdsaleInfo(address, bytes32) external view returns (uint, address, uint, bool, bool, bool);
  function isCrowdsaleFull(address, bytes32) external view returns (bool, uint);
  function getCrowdsaleStartAndEndTimes(address, bytes32) external view returns (uint, uint);
  function getCrowdsaleStatus(address, bytes32) external view returns (uint, uint, uint, uint, uint, uint, bool);
  function getTokensSold(address, bytes32) external view returns (uint);
  function getCrowdsaleWhitelist(address, bytes32) external view returns (uint, address[]);
  function getWhitelistStatus(address, bytes32, address) external view returns (uint, uint);
}

interface ISale {
  function buy() external payable;
}

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

interface IDutchCrowdsale {
  function init(address, uint, uint, uint, uint, uint, uint, bool, address, bool) external;
}

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

contract AdminProxy is IAdmin, SaleProxy {

  /*
  Returns the admin address for the crowdsale

  @return address: The admin of the crowdsale
  */
  function getAdmin() external view returns (address) {
    return AdminIdx(app_index).getAdmin(app_storage, app_exec_id);
  }

  /*
  Returns information about the ongoing sale -

  @return uint: The total number of wei raised during the sale
  @return address: The team funds wallet
  @return uint: The minimum number of tokens a purchaser must buy
  @return bool: Whether the sale is finished configuring
  @return bool: Whether the sale has completed
  @return bool: Whether the unsold tokens at the end of the sale are burnt (if false, they are sent to the team wallet)
  */
  function getCrowdsaleInfo() external view returns (uint, address, uint, bool, bool, bool) {
    return AdminIdx(app_index).getCrowdsaleInfo(app_storage, app_exec_id);
  }

  /*
  Returns whether or not the sale is full, as well as the maximum number of sellable tokens
  If the current rate is such that no more tokens can be purchased, returns true

  @return bool: Whether or not the sale is sold out
  @return uint: The total number of tokens for sale
  */
  function isCrowdsaleFull() external view returns (bool, uint) {
    return AdminIdx(app_index).isCrowdsaleFull(app_storage, app_exec_id);
  }

  /*
  Returns the start and end times of the sale

  @return uint: The time at which the sale will begin
  @return uint: The time at which the sale will end
  */
  function getCrowdsaleStartAndEndTimes() external view returns (uint, uint) {
    return AdminIdx(app_index).getCrowdsaleStartAndEndTimes(app_storage, app_exec_id);
  }

  /*
  Returns information about the current sale tier

  @return uint: The price of 1 token (10^decimals) in wei at the start of the sale
  @return uint: The price of 1 token (10^decimals) in wei at the end of the sale
  @return uint: The price of 1 token (10^decimals) currently
  @return uint: The total duration of the sale
  @return uint: The amount of time remaining in the sale (factors in time till sale starts)
  @return uint: The amount of tokens still available to be sold
  @return bool: Whether the sale is whitelisted or not
  */
  function getCrowdsaleStatus() external view returns (uint, uint, uint, uint, uint, uint, bool) {
    return AdminIdx(app_index).getCrowdsaleStatus(app_storage, app_exec_id);
  }

  /*
  Returns the number of tokens sold during the sale, so far

  @return uint: The number of tokens sold during the sale up to this point
  */
  function getTokensSold() external view returns (uint) {
    return AdminIdx(app_index).getTokensSold(app_storage, app_exec_id);
  }

  /*
  Returns the whitelist set by the admin

  @return uint: The length of the whitelist
  @return address[]: The list of addresses in the whitelist
  */
  function getCrowdsaleWhitelist() external view returns (uint, address[]) {
    return AdminIdx(app_index).getCrowdsaleWhitelist(app_storage, app_exec_id);
  }

  /*
  Returns whitelist information for a buyer

  @param _buyer: The address about which the whitelist information will be retrieved
  @return uint: The minimum number of tokens the buyer must make during the sale
  @return uint: The maximum amount of tokens allowed to be purchased by the buyer
  */
  function getWhitelistStatus(address _buyer) external view returns (uint, uint) {
    return AdminIdx(app_index).getWhitelistStatus(app_storage, app_exec_id, _buyer);
  }
}

contract TokenProxy is IToken, AdminProxy {

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

contract DutchProxy is IDutchCrowdsale, TokenProxy {

  // Constructor - sets storage address, registry id, provider, and app name
  constructor (address _storage, bytes32 _registry_exec_id, address _provider, bytes32 _app_name) public
    Proxy(_storage, _registry_exec_id, _provider, _app_name) { }

  // Constructor - creates a new instance of the application in storage, and sets this proxy&#39;s exec id
  function init(address, uint, uint, uint, uint, uint, uint, bool, address, bool) external {
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