/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

// SPDX-License-Identifier: MIT
// Author: ThangTKT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  function _thisAddress() internal view virtual returns (address) {
    return address(this);
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;
  address private _newOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(_thisAddress(), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Accept the ownership transfer. This is to make sure that the contract is
   * transferred to a working address
   *
   * Can only be called by the newly transfered owner.
   */
  function acceptOwnership() public {
    require(
      _msgSender() == _newOwner,
      "Ownable: only new owner can accept ownership"
    );
    address oldOwner = _owner;
    _owner = _newOwner;
    _newOwner = address(0);
    emit OwnershipTransferred(oldOwner, _owner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   *
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _newOwner = newOwner;
  }
}

/**
 * @dev Contract DCCDevFunds.
 */
contract DCCDevFunds is Context, Ownable {
  // struct
  struct Balance {
    address token;
    uint256 value;
  }

  struct Funder {
    address wallet;
    Balance[] data;
  }

  /**
   * @dev List of coins in the contract
   */
  mapping(address => uint256) public balances;
  mapping(address => uint256) private balanceIndex;
  Balance[] private balanceData;
  uint256 private balanceCount;

  /**
   * @dev List of address donated
   */
  mapping(address => mapping(address => uint256)) public funders;
  mapping(address => uint256) private funderIndex;
  Funder[] private funderData;
  uint256 private funderCount;

  /**
   * @dev Emitted when address donate to contract
   *
   * sender: address donate
   * token: token donate
   * value: amount donate
   * Note that `value` may be zero.
   */
  event Deposit(
    address indexed sender,
    address indexed token,
    uint256 indexed value
  );

  /**
   * @dev Emitted when owner donate
   *
   * wallet: address owner
   * token: token withdraw
   * value: amount withdraw
   * Note that `value` may be zero.
   */
  event Withdraw(
    address indexed wallet,
    address indexed token,
    uint256 indexed value
  );

  // This is the constructor which registers the
  constructor() {
    balanceData.push(Balance(_thisAddress(), 0));
    balanceIndex[_thisAddress()] = balanceCount;
    balanceCount++;

    funderData.push();
    Funder storage newFunder = funderData[0];
    newFunder.wallet = _thisAddress();
    newFunder.data.push(Balance(_thisAddress(), 0));
    funderIndex[_thisAddress()] = funderCount;
    funderCount++;
  }

  /*
   * accepts ether sent with no txData
   */
  receive() external payable {}

  function addBalance(address _address, uint256 amount) private {
    if (balanceIndex[_address] == 0 && _address != _thisAddress()) {
      balanceIndex[_address] = balanceCount;
      balanceData.push(Balance(_address, amount));
      balanceCount++;
    } else {
      uint256 i = balanceIndex[_address];
      Balance memory _balance = balanceData[i];
      _balance.value += amount;
      balanceData[i] = _balance;
    }
    balances[_address] += amount;
  }

  function getBalances() external view returns (Balance[] memory) {
    return balanceData;
  }

  function addFunder(
    address _address,
    address token,
    uint256 amount
  ) private {
    if (funderIndex[_address] == 0 && _address != _thisAddress()) {
      funderData.push();
      Funder storage newFunder = funderData[funderCount];
      newFunder.wallet = _address;
      newFunder.data.push(Balance(token, amount));
      funderIndex[_address] = funderCount;
      funderCount++;
    } else {
      uint256 i = funderIndex[_address];
      Funder storage _funder = funderData[i];
      _funder.data.push(Balance(token, amount));
    }
    funders[_address][token] += amount;
  }

  function getFunders() external view returns (Funder[] memory) {
    return funderData;
  }

  function deposit() public payable returns (bool) {
    uint256 amount = msg.value;
    addFunder(_msgSender(), _thisAddress(), amount);
    addBalance(_thisAddress(), amount);
    emit Deposit(_msgSender(), _thisAddress(), msg.value);
    return true;
  }

  function addFunds(address _address, uint256 amount) external returns (bool) {
    require(amount > 0, "Insufficient funds x");
    uint256 allowance = IERC20(_address).allowance(
      _msgSender(),
      _thisAddress()
    );
    require(allowance >= amount, "Check the token allowance");
    IERC20(_address).transferFrom(_msgSender(), _thisAddress(), amount);
    emit Deposit(_msgSender(), _address, amount);
    addBalance(_address, amount);
    addFunder(_msgSender(), _address, amount);
    return true;
  }

  function withdrawToken(address _address, uint256 amount)
    external
    onlyOwner
    returns (bool)
  {
    require(balanceOfAddress(_address) >= amount, "Insufficient funds");
    IERC20(_address).transfer(_msgSender(), amount);
    balances[_address] -= amount;
    uint256 i = balanceIndex[_address];
      Balance memory _balance = balanceData[i];
      _balance.value -= amount;
      balanceData[i] = _balance;
    emit Withdraw(_msgSender(), _address, amount);
    return true;
  }

  function withdraw(uint256 amount) external onlyOwner returns (bool) {
    require(balance() >= amount, "Insufficient funds");
    payable(_msgSender()).transfer(amount);
    balances[_thisAddress()] -= amount;
    emit Withdraw(_msgSender(), _thisAddress(), amount);
    return true;
  }

  function balanceOfAddress(address _address) public view returns (uint256) {
    uint256 balanceToken = IERC20(_address).balanceOf(_thisAddress());
    return balanceToken;
  }

  function balance() public view returns (uint256) {
    return _thisAddress().balance;
  }
}