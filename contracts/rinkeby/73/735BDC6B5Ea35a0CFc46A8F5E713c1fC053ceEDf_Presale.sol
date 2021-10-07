// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
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

  event Purchase(address indexed purchaser, uint256 amount, uint256 cost);
  event NewPresale(
    uint8 round,
    uint32 cap,
    uint128 openingTime,
    uint128 closingTime,
    uint256 price,
    bool isPublicSale
  );

  constructor(
    IToken token_,
    address wallet_,
    address signer_,
    uint128 openingTime_,
    uint128 closingTime_,
    uint256 price_,
    uint32 cap_,
    uint8 initialRound_
  ) {
    require(openingTime_ >= block.timestamp, "Invalid opening time");
    require(closingTime_ >= openingTime_, "Closing time < Opening time");

    token = token_;
    wallet = wallet_;
    signer = signer_;
    openingTime = openingTime_;
    closingTime = closingTime_;
    price = price_;
    cap = cap_;
    round = initialRound_;
  }

  function isOpen() public view returns (bool) {
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  function getTime() external view returns (uint256) {
    return block.timestamp;
  }

  function buyNFT(uint256 amount, bytes memory whitelistSig) external payable {
    address purchaser = _msgSender();
    uint256 value = msg.value;

    //Checks
    _preValidatePurchase(purchaser, amount, value, whitelistSig);

    //Effects
    sold += uint32(amount); //amount is no more than 10

    //Interactions
    token.safeMint(purchaser, amount);

    emit Purchase(purchaser, amount, value);
  }

  function _preValidatePurchase(
    address purchaser,
    uint256 amount,
    uint256 value,
    bytes memory whitelistSig
  ) private view whenNotPaused {
    require(isOpen(), "Not open");
    if (!isPublicSale) {
      bool whitelisted = _verify(purchaser, whitelistSig);
      require(whitelisted, "Invalid access");
    }
    require(amount > 0 && amount <= 10, "Must be > 0 and <= 10");
    require(sold + uint32(amount) <= cap, "Exceeds cap");
    require(value == price * amount, "Insufficient funds");
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
    require(closingTime_ >= openingTime_, "Closing time < Opening time");

    if (!isOpen()) {
      require(openingTime_ > block.timestamp, "Invalid opening time");
      openingTime = openingTime_;
      round = round_;
      sold = 0;
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
    (bool success, ) = payable(wallet).call{ value: address(this).balance }("");
    require(success, "Withdraw failed");
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}