/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IERC20 {
    // function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    // function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    // function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract StableExchange is Ownable{
    address public baseToken;
    address public exchangeToken;
    address public walletAddress;
    
    constructor (address _baseToken, address _exchangeToken) {
        baseToken = _baseToken;
        exchangeToken = _exchangeToken;
        walletAddress = msg.sender;
    }
    
    event Deposit(address indexed from, address indexed to, uint256 value, address token);
    event Withdraw(address indexed from, address indexed to, uint256 value, address token);
    event Exchange(address indexed from, address indexed to, uint256 value_from, address token_from, uint256 value_to, address token_to);

    function updateWalletAddress(address addr) public onlyOwner {
        walletAddress = addr;
    }
    
    function exchangeForToken(uint256 amount) public {
        uint256 balance = IERC20(baseToken).balanceOf(address(msg.sender));
        require(balance >= amount, "INSUFFICIENT_FUND");
         
         // get decimals
        uint8 decimalsBaseTokens = IERC20(baseToken).decimals();
        uint8 decimalsExchangeTokens = IERC20(exchangeToken).decimals();
        
        // conversion
        uint256 exchangeAmount = amount / 10 ** (decimalsExchangeTokens - decimalsBaseTokens);
        
        uint256 exchangeTokenBalance = balanceOfExchangeToken();
        require(exchangeTokenBalance >= exchangeAmount, "CONTRACT_HAS_INSUFFICIENT_TOKEN_IN_POOL");
        
        IERC20(baseToken).transferFrom(msg.sender, address(this), amount);
        IERC20(exchangeToken).transfer(msg.sender, amount);
         
        emit Exchange(msg.sender, address(this), amount, baseToken, exchangeAmount, exchangeToken);
    }
    
    function depositExchangeToken(uint256 amount) public onlyOwner {
        uint256 balance = IERC20(exchangeToken).balanceOf(address(msg.sender));
        require(balance >= amount, "INSUFFICIENT_INPUT_AMOUNT");
        IERC20(exchangeToken).transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, address(this), amount, exchangeToken);
    }
    
    function withdrawExchangeToken() public onlyOwner {
        uint256 balance = IERC20(exchangeToken).balanceOf(address(this));   
        IERC20(exchangeToken).transfer(walletAddress, balance);

        emit Withdraw(address(this), walletAddress, balance, exchangeToken);
    }
    
    function withdrawBaseToken() public onlyOwner {
        uint256 balance = IERC20(baseToken).balanceOf(address(this));   
        IERC20(baseToken).transfer(walletAddress, balance);

        emit Withdraw(address(this), walletAddress, balance, baseToken);
    }
    
    function balanceOfExchangeToken() public view returns (uint256 amount) {
        uint256 balance = IERC20(exchangeToken).balanceOf(address(this));
        return balance;
    }

    function balanceOfBaseToken() public view returns (uint256 amount) {
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        return balance;
    }
    
}