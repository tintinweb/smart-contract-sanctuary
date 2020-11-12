pragma solidity ^0.6.6;

import './IUniswapV2Router02.sol';
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
contract UniswapTradingBot is Ownable{
  address internal constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
  mapping (address => bool) public whitelist;
  IUniswapV2Router02 public uniswapRouter;
  
  event AddWhitelist(address account);
  event RemoveWhitelist(address account);
  
  function addWhitelist(address account) public onlyOwner {
    whitelist[account] = true;
    emit AddWhitelist(account);
  }

  function removeWhitelist(address account) public onlyOwner {
    whitelist[account] = false;
    emit RemoveWhitelist(account);
  }
  
  constructor() public {
    uniswapRouter = IUniswapV2Router02(ROUTER_ADDRESS);
    addWhitelist(msg.sender);
  }
  function convertEthToToken(address tokenContract, uint256 tokenWantToBuy, uint maxTimeWaiting) public payable {
    require(whitelist[msg.sender] == true, "You dont have any privilege!");
    uint deadline = block.timestamp + maxTimeWaiting; // using 'now' for convenience, for mainnet pass deadline from frontend!
    uniswapRouter.swapETHForExactTokens{ value: msg.value }(tokenWantToBuy, getPathForETHtoToken(tokenContract), msg.sender, deadline);

    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
    
  }

  function getEstimatedETHforToken(address tokenContract, uint tokenAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(tokenAmount, getPathForETHtoToken(tokenContract));
  }

  function getPathForETHtoToken(address tokenContract) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = tokenContract;
    return path;
  }
  receive() payable external {}
}