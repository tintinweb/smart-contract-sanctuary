/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0

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
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
   function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
   function balanceOf(address owner) external view returns (uint256 balance);

}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}



contract Master is  Ownable {
    event logs(uint64,bytes32,uint64,uint256);
  struct LastWrite {
    uint64 time;
    uint64 blockNum;
  }
  struct Whitelist {
    bool isWhitelisted;
    uint16 numMinted;
  }
  mapping(address => LastWrite) private _lastWrite;
  function mint() public  returns(uint256){
      uint256 seed = 0;
  LastWrite storage lw = _lastWrite[tx.origin];
  seed = random(seed, lw.time, lw.blockNum);
  emit logs(lw.time,blockhash(lw.blockNum),lw.blockNum,seed);
  return seed;
}
      function random(uint256 seed, uint64 timestamp, uint64 blockNumber) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(blockNumber > 1 ? blockNumber - 2 : blockNumber),// Different block than WnDGame to ensure if needing to re-randomize that it goes down a different path
            timestamp,
            seed
        )));
    }

}