/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract UserPost is Context, Ownable {

  address public mscToken;

  struct Post {
    address creator;
    uint256 timestamp;
    bool hasData;
  }

  mapping(string => Post) public _posts;

  event PostCreated(address creator, string contentHash);

  constructor (address _mscToken) {
    mscToken = _mscToken;
  }

  function publish(string memory _postHash) external returns (string memory) {
    Post storage curPost = _posts[_postHash];
    curPost.creator = _msgSender();
    curPost.timestamp = block.timestamp;
    curPost.hasData = true;

    emit PostCreated(_msgSender(), _postHash);

    return _postHash;
  }

  function checkPost(string memory _postHash) public view returns(bool, address, uint256){
    return (_posts[_postHash].hasData, _posts[_postHash].creator, _posts[_postHash].timestamp);
  }

  modifier validPost(string memory _postHash) {
    require(_posts[_postHash].hasData == true, "Not a valid post");
    _;
  }

}