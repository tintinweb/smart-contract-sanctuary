/**
 *Submitted for verification at Etherscan.io on 2021-08-11
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
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Pool is Ownable{
    address private _owner;
    uint256 private _balances;
    address public token;
    address public walletAddress;
    
    constructor (address _token) {
        token = _token;
        _owner = msg.sender;
        walletAddress = msg.sender;
        transferOwnership(_owner);
    }
    
    function updateWalletAddress(address addr) public {
        require(msg.sender == _owner, "Only Owner Can Use This Function");
        walletAddress = addr;
    }
    
    function deposit(uint256 amount) public {
        uint256 balance = IERC20(token).balanceOf(address(msg.sender));
        require(balance >= amount, "Pool: INSUFFICIENT_INPUT_AMOUNT");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _balances += amount;
    }
    
    function withdraw(uint256 amount) public {
        require(msg.sender == _owner, "Only Owner has the right to withdraw");
        require(_balances >= amount, "Pool: INSUFFICIENT_OUTPUT_AMOUNT");
         
        IERC20(token).transfer(walletAddress, amount);
        _balances -= amount;
    }
    
    function balanceOfPool() public view returns (uint256 amount) {
        require(msg.sender == _owner, "Only Owner has the right to check balance");
        return _balances;
    }
    

}