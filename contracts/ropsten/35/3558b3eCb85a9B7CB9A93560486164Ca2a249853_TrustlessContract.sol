// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrustlessContract is Context, Ownable {

  uint256 public lockStart;
  uint256 public lockEnd;
  uint256 public unlockPrice;
  bool public unlocked = false;

  //address USDT = 0xdac17f958d2ee523a2206206994597c13d831ec7;
  //address USDC = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48;

  address[] private _stableTokensMainnet = [0xdAC17F958D2ee523a2206206994597C13D831ec7, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48];
  address[] private _stableTokensRopsten = [0x516de3a7A567d81737e3a46ec4FF9cFD1fcb0136, 0x0D9C8723B343A8368BebE0B5E89273fF8D712e3C];
  mapping(address => bool) private stableTokens;

  constructor(uint256 _lockStart, uint256 _lockEnd, uint256 _unlockPrice) {
    lockStart = _lockStart;
    lockEnd = _lockEnd;
    unlockPrice = _unlockPrice;
    if (block.chainid == 1) {
      for (uint256 i = 0; i < _stableTokensMainnet.length; i++) {
        stableTokens[_stableTokensMainnet[i]] = true;
      }
    } else if (block.chainid == 3) {
      for (uint256 i = 0; i < _stableTokensRopsten.length; i++) {
        stableTokens[_stableTokensRopsten[i]] = true;
      }
    }
  }

  function unlock(address _stableToken) public onlyOwner {
    require(stableTokens[_stableToken] == true, "unlock: invalid stable token address");
    IERC20 token = IERC20(_stableToken);
    require(token.balanceOf(msg.sender) >= unlockPrice, "unlock: insufficient balance");
    require(token.allowance(msg.sender, address(this)) >= unlockPrice, "unlock: insufficient allowance");
    unlocked = true;
  }

  function withdrawETH(uint256 _amount) public onlyOwner {
    require(block.timestamp < lockStart || block.timestamp > lockEnd || unlocked, "withdrawETH: fonds are locked");
    require((_amount == 0 && address(this).balance > 0) || address(this).balance >= _amount, "withdrawETH: invalid amount");
    address payable _sender = payable(msg.sender);
    _sender.transfer(_amount);
  }

  function withdrawToken(address _token, uint256 _amount) public onlyOwner  {
    require(block.timestamp < lockStart || block.timestamp > lockEnd || unlocked, "withdrawToken: fonds are locked");
    IERC20 token = IERC20(_token);
    require((_amount == 0 && token.balanceOf(address(this)) > 0) || token.balanceOf(address(this)) >= _amount, "withdrawToken: invalid amount");
    token.transfer(msg.sender, _amount);
  }

  function getTokenBalance(address _token) public view returns (uint256) {
    IERC20 token = IERC20(_token);
    return token.balanceOf(address(this));
  }

  function getUnlockTokens() public view returns (address[] memory) {
    if (block.chainid == 1) {
      return _stableTokensMainnet;

    } else if (block.chainid == 3) {
      return _stableTokensRopsten;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}