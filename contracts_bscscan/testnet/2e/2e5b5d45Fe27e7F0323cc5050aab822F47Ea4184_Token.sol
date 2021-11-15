// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Ownable.sol";

contract Token is Context, IERC20, IERC20Metadata, Ownable {

  struct Holder {
    address ethAddress;
    uint256 balance;
    mapping(address => uint256) allowances;
    bool canReceive;
    bool excludeFees;
  }

  mapping(address => Holder) private _holders;

    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 private _totalSupply;
    
    struct FeeRecipient {
      address feeAddress;
      string name;
      uint256 fee;
      uint256 balance;
    }
    mapping(string => FeeRecipient) private _feesByName;
    string[] public feeNames;

    bool _whitelistActive;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * 10 ** decimals_;

        _holders[_msgSender()].balance = _totalSupply;
        _holders[_msgSender()].canReceive = true;
        _holders[_msgSender()].excludeFees = true;

        FeeRecipient storage reflectionBalanceType = _feesByName['REFLECTION'];
        reflectionBalanceType.balance = _totalSupply / 10;

        emit Transfer(address(0), _msgSender(), _totalSupply);

        _whitelistActive = true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(recipient != sender, "ERC20: transfer to self");

        Holder storage senderHolder = _holders[sender];
        Holder storage recipientHolder = _holders[recipient];

        require(recipientHolder.canReceive, "to address cannot receive tokens yet");

        uint256 senderBalance = senderHolder.balance;
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            senderHolder.balance = senderBalance - amount;
        }
        recipientHolder.balance += amount;
        emit Transfer(sender, recipient, amount);
        if ( recipientHolder.excludeFees != true ) {
            _takeFees(recipient,amount);
        }
    }

    function balanceOf(address account) public view override returns(uint256) {
        uint256 tokenBalance = _holders[account].balance;
        if ( _holders[account].excludeFees ) {
            return tokenBalance;
        }
        else {
            FeeRecipient storage reflectionBalanceType = _feesByName['REFLECTION'];
            uint256 myPercentageOfReflectionBalance = tokenBalance / _totalSupply;
            uint256 additionalBalance = reflectionBalanceType.balance * myPercentageOfReflectionBalance;
            uint256 totalBalance = tokenBalance + additionalBalance;
            return totalBalance;
        }
    }

    function getPercentageOfTotalSupply(address addy) public returns(uint256) {
        return (_holders[addy].balance*100) / (_totalSupply*100) * 100;
    }

    function getTotalFees(string memory feeName) public view returns(uint256) {
      FeeRecipient storage balanceType = _feesByName[feeName];
      return balanceType.balance;
    }

    function _takeFees(address recipient,uint256 amount) private {
        for ( uint i = 0 ; i < feeNames.length ; i++ ) {
          string memory feeName = feeNames[i];
          FeeRecipient storage balanceType = _feesByName[feeName];
          uint256 fee = (amount * balanceType.fee) / 100;
          balanceType.balance += fee;
          _holders[recipient].balance -= fee;
          _holders[balanceType.feeAddress].balance += fee;
          emit Transfer(recipient, balanceType.feeAddress, fee);
        }
    }

    function addFee(address feeAddress,string calldata feeName,uint256 fee) public onlyOwner {
      _feesByName[feeName] = FeeRecipient(feeAddress,feeName, fee, 0);
      _holders[feeAddress].balance = 0;
      _holders[feeAddress].canReceive = true; // auto-add fee address to whitelist
      _holders[feeAddress].excludeFees = true; // do not include fees in fees ;)
      feeNames.push(feeName);
    }

    function setFee(string calldata feeName,uint256 fee) public onlyOwner {
      _feesByName[feeName].fee = fee;
    }

    function getFee(string memory feeName) public view returns(uint256) {
      return _feesByName[feeName].fee;
    }

    function getWhitelistStatus(address addy) public view returns(bool) {
      return _holders[addy].canReceive;
    }

    function isWhitelistActive() public view returns(bool) {
      return _whitelistActive;
    }

    /* OWNER Functions */

    function setWhitelistActive(bool flag) public onlyOwner {
      _whitelistActive = flag;
    }

    function addToWhitelist(address[] calldata addresses) public onlyOwner {
      for ( uint i = 0 ; i < addresses.length ; i++ ) {
        _holders[addresses[i]].canReceive = true;
      }
    }

    function setWhitelistStatus(address addy,bool flag) public {
        _holders[addy].canReceive = flag;
    }

    /*-------------------- STANDARD ERC20 stuff below ------------------------ */

    function name() public view override returns(string memory) { return _name; }
    function symbol() public view override returns(string memory) { return _symbol; }
    function decimals() public view override returns(uint8) { return _decimals; }
    function totalSupply() public view override returns(uint256) { return _totalSupply; }

    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _holders[sender].allowances[_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _holders[owner].allowances[spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _holders[owner].allowances[spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _holders[_msgSender()].allowances[spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        uint256 currentAllowance = _holders[_msgSender()].allowances[spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
}

