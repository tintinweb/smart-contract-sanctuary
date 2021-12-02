// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC20.sol";
import "./utils/Runnable.sol";
import "./utils/ReentrancyGuard.sol";

contract GameWallet is ReentrancyGuard, Runnable {

    mapping (address => mapping(address => uint256)) _userBalances;
    
    function depositToken(address tokenAddress, uint256 amount) public returns(bool){
        require(tokenAddress != address(0), "tokenAddress is address 0");
        require(amount > 0, "amount = 0");

        require(IERC20(tokenAddress).transferFrom(_msgSender(), address(this), amount), "Can not deposit token");

        emit TokenDeposited(_msgSender(), tokenAddress, amount);
        return true;
    }

    function setWithdrawalAmount(address account, address tokenAddress, uint256 amount) public onlyOwner{
        require(account != address(0), "account is address 0");
        require(tokenAddress != address(0), "tokenAddress is address 0");
        require(amount > 0, "amount = 0");

        _userBalances[account][tokenAddress] += amount;
        emit BalanceAdded(account, tokenAddress, amount);
    }

    function withdraw(address tokenAddress, uint256 amount) public{
        require(tokenAddress != address(0), "tokenAddress is address 0");
        require(amount > 0, "amount = 0");
        require(_userBalances[_msgSender()][tokenAddress] >= amount, "Not enough balance to withdraw");

        _userBalances[_msgSender()][tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(_msgSender(), amount);

        emit Withdrawn(_msgSender(), tokenAddress, amount);
    }

    function withdrawToken(address tokenAddress, address recepient, uint256 amount) public onlyOwner{
        require(tokenAddress != address(0), "tokenAddress is address 0");
        require(recepient != address(0), "recepient is address 0");
        require(amount > 0, "amount = 0");
        IERC20(tokenAddress).transfer(recepient, amount);
    }

    event TokenDeposited(address account, address tokenAddress, uint256 amount);
    event BalanceAdded(address account, address tokenAddress, uint256 amount);
    event Withdrawn(address account, address tokenAddress, uint256 amount);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";

contract Runnable is Ownable{
    modifier whenRunning{
        require(_isRunning, "Paused");
        _;
    }
    
    modifier whenNotRunning{
        require(!_isRunning, "Running");
        _;
    }
    
    bool public _isRunning;
    
    constructor(){
        _isRunning = true;
    }
    
    function toggleRunning() public onlyOwner{
        _isRunning = !_isRunning;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract ReentrancyGuard {
    uint256 public constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 internal _status;

    constructor() {
         _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './Context.sol';

contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
     _owner = _msgSender();
     emit OwnershipTransferred(address(0), _msgSender());
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
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  
  function _now() internal view returns (uint256) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return block.timestamp;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}