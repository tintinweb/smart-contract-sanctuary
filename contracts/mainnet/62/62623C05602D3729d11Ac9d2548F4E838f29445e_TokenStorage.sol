// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenStorage is Ownable {

  // token_id -> filename -> file batches
  mapping (uint256 => mapping(uint256 => uint256[][])) internal _tokenFileData;

  // so we can list the filenames & sizes associated with a token
  mapping (uint256 => uint256[]) internal _tokenFileNames;
  mapping (uint256 => uint256[]) internal _tokenFileSizes;

  // once this is set - we can never change the storage for this token
  mapping (uint256 => bool) internal _finalized;

  constructor ()  {}

  // store the filename of a new file
  // this unlocks the ability to start adding data to that file
  function createFile(uint256 tokenId, uint256 name, uint256 size) external onlyOwner {
    require(!_finalized[tokenId], "0x40");
    _tokenFileNames[tokenId].push(name);
    _tokenFileSizes[tokenId].push(size);
  }

  // return an array of filenames for the token
  function getFileNames(uint256 tokenId) public view returns (uint256[] memory) {
    return _tokenFileNames[tokenId];
  }

  function getFileSizes(uint256 tokenId) public view returns (uint256[] memory) {
    return _tokenFileSizes[tokenId];
  }

  // add data to a file
  // the token must not be finalized
  // the file must exist and have a non-zero size
  // the batchIndex must be an empty array
  function writeFileBatch(uint256 tokenId, uint256 fileName, uint256 batchIndex, uint256[] calldata batchData) external onlyOwner {
    require(!_finalized[tokenId], "0x40");
    uint256[][] storage fileStorage = _tokenFileData[tokenId][fileName];
    require(fileStorage.length == batchIndex, "0x43");
    fileStorage.push(batchData);
  }

  // prevent any more changes happening to a given token
  function finalizeToken(uint256 tokenId) external onlyOwner {
    require(!_finalized[tokenId], "0x40");
    _finalized[tokenId] = true;
  }

  function isFinalized(uint256 tokenId) public view returns (bool) {
    return _finalized[tokenId];
  }

  // how many batches is a file saved in
  // this let's the client iterate over batches to rebuild the file
  function getFileBatchLength(uint256 tokenId, uint256 fileName) public view returns (uint256) {
    return _tokenFileData[tokenId][fileName].length;
  }

  // get a single batch for some media
  // the client must loop over batches because whilst it's a "view" function
  // it's still subject to block has limits
  function getFileBatchData(uint256 tokenId, uint256 fileName, uint256 batchIndex) public view returns (uint256[] memory) {
    return _tokenFileData[tokenId][fileName][batchIndex];
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
  "optimizer": {
    "enabled": false,
    "runs": 2000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}