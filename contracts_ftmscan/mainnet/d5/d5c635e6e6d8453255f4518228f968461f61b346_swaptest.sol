/**
 *Submitted for verification at FtmScan.com on 2022-01-20
*/

/**
SPDX-License-Identifier: Unlicensed
*/

/**
FTMS SWAP FROM V1 TO v2

Tokenomics:
10% reflections paid in USDC
2% allocated to liquidity
2% allocated to marketing wallet
2%  allocated to dev/team wallet

Website: https://www.ftmstable.com

Discord: discord.gg/fDDrJzAJuV

Telegram: https://t.me/FTMStable

Twitter: https://twitter.com/FTMStable
*/

pragma solidity ^0.8.4;

// ********************************************************************************
// ********************************************************************************
// Context.sol

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
}


// ********************************************************************************
// ********************************************************************************
// Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ********************************************************************************
// ********************************************************************************
// IERC20.sol

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

// ********************************************************************************
// ********************************************************************************
// FTMSSWAP

interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}

/**
 * @title FTMS_SWAP
 * @dev Swap FTMSv1 for FTMSv2
 */
contract swaptest is Ownable {
  IERC20Decimals private ftmsV1;
  IERC20Decimals private ftmsV2;

  mapping(address => bool) public swapped;

  constructor(address _v1, address _v2) {
    ftmsV1 = IERC20Decimals(_v1);
    ftmsV2 = IERC20Decimals(_v2);
  }

  function swap() external {
    require(!swapped[msg.sender], 'already swapped V1 for V2');

    uint256 _v2Amount = ftmsV1.balanceOf(msg.sender);
    require(_v2Amount > 0, 'you do not have any V1 tokens');
    require(
      ftmsV2.balanceOf(address(this)) >= _v2Amount,
      'not enough V2 liquidity to complete swap'
    );
    swapped[msg.sender] = true;
    ftmsV1.transferFrom(msg.sender, address(this), _v2Amount);
    ftmsV2.transfer(
      msg.sender,
      (_v2Amount * 10**ftmsV2.decimals()) / 10**ftmsV1.decimals()
    );
  }

  function setSwapped(address _wallet, bool _swapped) external onlyOwner {
    swapped[_wallet] = _swapped;
  }

  function v1() external view returns (address) {
    return address(ftmsV1);
  }

  function v2() external view returns (address) {
    return address(ftmsV2);
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH(uint256 _amount) external onlyOwner {
    _amount = _amount > 0 ? _amount : address(this).balance;
    require(_amount > 0, 'make sure there is tokens available to withdraw');
    payable(owner()).call{ value: _amount }('');
  }

  // to recieve from external wallets
  receive() external payable {}
}