// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './OKLGProduct.sol';

/**
 * @title OKLGTrustedTimestamping
 * @dev Stores SHA256 data hashes for trusted timestamping implementations.
 */
contract OKLGTrustedTimestamping is OKLGProduct {
  struct DataHash {
    bytes32 dataHash;
    uint256 time;
    string fileName;
    uint256 fileSizeBytes;
  }

  struct Address {
    address addy;
    uint256 time;
  }

  uint256 public totalNumberHashesStored;
  mapping(address => DataHash[]) public addressHashes;
  mapping(bytes32 => Address[]) public fileHashesToAddress;

  event StoreHash(address from, bytes32 dataHash);

  constructor(address _tokenAddress, address _pendAddress)
    OKLGProduct(uint8(3), _tokenAddress, _pendAddress)
  {}

  /**
   * @dev Process transaction and store hash in blockchain
   */
  function storeHash(
    bytes32 dataHash,
    string memory fileName,
    uint256 fileSizeBytes
  ) external payable {
    _payForService(0);

    uint256 theTimeNow = block.timestamp;
    addressHashes[msg.sender].push(
      DataHash({
        dataHash: dataHash,
        time: theTimeNow,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes
      })
    );
    fileHashesToAddress[dataHash].push(
      Address({ addy: msg.sender, time: theTimeNow })
    );
    totalNumberHashesStored++;
    emit StoreHash(msg.sender, dataHash);
  }

  function getHashesForAddress(address _userAddy)
    external
    view
    returns (DataHash[] memory)
  {
    return addressHashes[_userAddy];
  }

  function getAddressesForHash(bytes32 dataHash)
    external
    view
    returns (Address[] memory)
  {
    return fileHashesToAddress[dataHash];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './interfaces/IOKLGSpend.sol';
import './OKLGWithdrawable.sol';

/**
 * @title OKLGProduct
 * @dev Contract that every product developed in the OKLG ecosystem should implement
 */
contract OKLGProduct is OKLGWithdrawable {
  IERC20 private _token; // OKLG
  IOKLGSpend private _spend;

  uint8 public productID;

  constructor(
    uint8 _productID,
    address _tokenAddy,
    address _spendAddy
  ) {
    productID = _productID;
    _token = IERC20(_tokenAddy);
    _spend = IOKLGSpend(_spendAddy);
  }

  function setTokenAddy(address _tokenAddy) external onlyOwner {
    _token = IERC20(_tokenAddy);
  }

  function setSpendAddy(address _spendAddy) external onlyOwner {
    _spend = IOKLGSpend(_spendAddy);
  }

  function setProductID(uint8 _newId) external onlyOwner {
    productID = _newId;
  }

  function getTokenAddress() public view returns (address) {
    return address(_token);
  }

  function getSpendAddress() public view returns (address) {
    return address(_spend);
  }

  function _payForService(uint256 _weiToRemoveFromSpend) internal {
    _spend.spendOnProduct{ value: msg.value - _weiToRemoveFromSpend }(
      msg.sender,
      productID
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.4;

/**
 * @title IOKLGSpend
 * @dev Logic for spending OKLG on products in the product ecosystem.
 */
interface IOKLGSpend {
  function spendOnProduct(address _payor, uint8 _product) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title OKLGWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract OKLGWithdrawable is Ownable {
  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}