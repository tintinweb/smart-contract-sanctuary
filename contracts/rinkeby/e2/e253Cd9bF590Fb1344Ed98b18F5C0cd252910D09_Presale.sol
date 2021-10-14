// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "hardhat/console.sol";

interface IToken {
  function safeMint(address, uint256) external;
}

contract Presale is Ownable, Pausable {
  // Presale time in UNIX
  uint128 public openingTime;
  uint128 public closingTime;

  //The price per NFT token (1token = ? wei)
  uint256 public price;

  //The NFT token for safe
  IToken public immutable token;

  //WETH (Wrapped Ether)
  IERC20 public immutable weth;

  // Withdraw address (should be a multisig)
  address public wallet;

  //Signer of signatures
  address public signer;

  //Max supply for round
  uint32 public cap;

  //Tokens sold for round
  uint32 public sold;

  //Sale round
  uint8 public round;

  //Private or public sale
  bool public isPublicSale;

  event Purchase(address indexed purchaser, uint8 indexed round, uint256 amount, uint256 cost);
  event NewPresale(uint8 round, uint32 cap, uint128 openingTime, uint128 closingTime, uint256 price, bool isPublicSale);

  constructor(
    IToken token_,
    IERC20 weth_,
    address wallet_,
    address signer_
  ) {
    token = token_;
    weth = weth_;
    wallet = wallet_;
    signer = signer_;
  }

  function isOpen() public view returns (bool) {
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  function getTime() external view returns (uint256) {
    return block.timestamp;
  }

  function buyNFT(uint256 amount, bytes memory whitelistSig) external {
    address purchaser = _msgSender();
    uint256 value = price * amount;

    //Checks
    _preValidatePurchase(purchaser, amount, whitelistSig);

    //Effects
    sold += uint32(amount); //amount is no more than 10

    //Interactions
    weth.transferFrom(purchaser, address(this), value);
    token.safeMint(purchaser, amount);

    emit Purchase(purchaser, round ,amount, value);
  }

  function _preValidatePurchase(
    address purchaser,
    uint256 amount,
    bytes memory whitelistSig
  ) private view whenNotPaused {
    require(isOpen(), "Not open");
    if (!isPublicSale) {
      bool whitelisted = _verify(purchaser, whitelistSig);
      require(whitelisted, "Invalid access");
    }
    require(amount > 0 && amount <= 10, "Must be > 0 and <= 10");
    require(sold + uint32(amount) <= cap, "Exceeds cap");
  }

  /* Whitelist verification */

  function _verify(address user, bytes memory signature) private view returns (bool) {
    bytes32 messageHash = keccak256(abi.encodePacked(user, address(this), round));
    bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
    return _recoverSigner(ethSignedMessageHash, signature) == signer;
  }

  function _getEthSignedMessageHash(bytes32 messageHash) private pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
  }

  function _recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) private pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }

  function _splitSignature(bytes memory sig)
    private
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    require(sig.length == 65, "Invalid signature length");
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }

  /* Only owner functions */

  function setPresale(
    uint128 openingTime_,
    uint128 closingTime_,
    uint256 price_,
    uint32 cap_,
    uint8 round_,
    bool isPublicSale_
  ) external onlyOwner {
    require(!isOpen() || paused(), "Cannot set now");
    if (!isOpen()) {
      require(closingTime_ >= openingTime_, "Closing time < Opening time");
      require(openingTime_ > block.timestamp, "Invalid opening time");
      openingTime = openingTime_;
      round = round_;
      sold = 0;
    }else{
      require(closingTime_ > block.timestamp, "Closing time < Opening time");
    }
    cap = cap_;
    price = price_;
    isPublicSale = isPublicSale_;
    closingTime = closingTime_;

    emit NewPresale(round, cap, openingTime, closingTime, price, isPublicSale);
  }

  function setSigner(address signer_) external onlyOwner {
    signer = signer_;
  }

  function updateWallet(address wallet_) external onlyOwner {
    wallet = wallet_;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function withdrawFunds() external onlyOwner {
    uint256 amount = weth.balanceOf(address(this));
    weth.transfer(wallet, amount);
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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