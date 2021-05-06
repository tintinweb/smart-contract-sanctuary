/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

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
    function owner() public view virtual returns (address) {
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
interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  function approve(address _spender, uint256 _value) external returns (bool success);
  function transfer(address _to, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Swap is Ownable {
  event Exchanged(address baseAsset, address quoteAsset, uint256 amount);
  
  uint256 public exchange_ratio = 1;
  
  function reserveOf(address asset) public view returns (uint256) {
      return IERC20(asset).balanceOf(address(this));
  }
 
  function getExchangeRatio(
    address baseAsset, 
    uint256 amountOfBaseAsset, 
    address quoteAsset, 
    uint256 amountOfQuoteAsset
  ) public view returns (uint256) {
    uint256 valueOfBaseAsset = amountOfBaseAsset * 10 ** IERC20(baseAsset).decimals();
    uint256 valueOfQuoteAsset = amountOfQuoteAsset * 10 ** IERC20(quoteAsset).decimals();
    return valueOfBaseAsset / valueOfQuoteAsset;
  }
  
  function exchange(
    address baseAsset,
    address quoteAsset,
    uint256 amount
  ) public returns (bool) {
    // 1. Amount must be greater than 0
    require(amount > 0, "You need to send some asset to buy");

    // 2. This contract must have enough assets to exchange
    uint256 reserve = IERC20(quoteAsset).balanceOf(address(this)) / IERC20(quoteAsset).decimals();
    require(reserve >= amount, "Not enough quote asset in the reserve.");

    // 3. Msg sender must approve to spend asset of a given amount
    uint256 allowance = IERC20(baseAsset).allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the asset allowance");

    // Sell baseAsset and buy quoteAsset
    uint256 decimalsOfBaseAsset = 10 ** IERC20(baseAsset).decimals();
    uint256 amountOfBaseAsset = amount * exchange_ratio;
    uint256 valueOfBaseAsset = amountOfBaseAsset * decimalsOfBaseAsset;

    uint256 decimalsOfQuoteAsset = 10 ** IERC20(quoteAsset).decimals();
    uint256 amountOfQuoteAsset = exchange_ratio / amount;
    uint256 valueOfQuoteAsset = amountOfQuoteAsset * decimalsOfQuoteAsset;
    
    // Exchange!
    IERC20(baseAsset).transferFrom(msg.sender, address(this), valueOfBaseAsset);
    IERC20(quoteAsset).transfer(msg.sender, valueOfQuoteAsset);

    emit Exchanged(baseAsset, quoteAsset, amount);
    return true;
  }
  
  function setExchangeRatio(uint256 ratio) public onlyOwner {
      exchange_ratio = ratio; 
  }
    
}