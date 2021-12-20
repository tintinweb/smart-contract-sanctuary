pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KeyUpgrade is Ownable {
  WMinter public minter;

  mapping(uint => uint) public watcherId;
  mapping(uint => address) public raribleContracts;
  mapping(uint => bool) public isERC721;

  uint256 STELLAR_KEY_ID = 38;
  uint256 DATA_KEY_ID = 36;

  constructor(address _minterAddress, uint256[] memory _raribleTokenIds, uint256[] memory _watcherTokenIds, address[] memory _raribleContracts, bool[] memory _isERC721) {
    minter = WMinter(_minterAddress);

    for (uint i = 0; i < _raribleTokenIds.length; i++) {
      watcherId[_raribleTokenIds[i]] = _watcherTokenIds[i];
      raribleContracts[_raribleTokenIds[i]] = _raribleContracts[i];
      isERC721[_raribleTokenIds[i]] = _isERC721[i];
    }
  }

  function upgradeKey(uint256 _raribleTokenId, uint256 _amount) external {
    require(minter.balanceOf(msg.sender, DATA_KEY_ID) >= _amount, "User does not own enough DATA keys");

    transferWatcher(_raribleTokenId, _amount);

    uint256[] memory burnIds = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    uint256[] memory mintIds = new uint256[](1);

    burnIds[0] = DATA_KEY_ID;
    mintIds[0] = STELLAR_KEY_ID;
    amounts[0] = _amount;

    minter.burnForMint(msg.sender, burnIds, amounts, mintIds, amounts);
  }

  function transferWatcher(uint256 _raribleTokenId, uint256 _amount) public {
    address _raribleContract = raribleContracts[_raribleTokenId];
    bool _isERC721 = isERC721[_raribleTokenId];

    require(_amount > 0, "Amount must be greater than zero");
    require(_raribleContract != address(0), "Address cannot be null");
    require(watcherId[_raribleTokenId] != 0, "Invalid Rarible token ID");

    if (_isERC721) {
      RaribleERC721 raribleERC721 = RaribleERC721(_raribleContract);
      
      require(raribleERC721.isApprovedForAll(msg.sender, address(this)) == true, "Contract is not authorized");
      require(raribleERC721.ownerOf(_raribleTokenId) == msg.sender, "User does not own this NFT");
      require(_amount == 1, "ERC721 can only burn 1");

      raribleERC721.burn(_raribleTokenId);
    } else {
      RaribleERC1155 raribleERC1155 = RaribleERC1155(_raribleContract);

      require(raribleERC1155.isApprovedForAll(msg.sender, address(this)) == true, "Contract is not authorized");
      require(raribleERC1155.balanceOf(msg.sender, _raribleTokenId) >= _amount, "User does not own this quantity of NFTs");

      raribleERC1155.burn(msg.sender, _raribleTokenId, _amount);
    }

    uint256 watcherTokenId = watcherId[_raribleTokenId];
    minter.mint(msg.sender, watcherTokenId, _amount);
  }

  function setWatcher(uint256 _raribleTokenId, uint256 _watcherTokenId, address _raribleContract, bool _isERC721) external onlyOwner() {
    watcherId[_raribleTokenId] = _watcherTokenId;
    raribleContracts[_raribleTokenId] = _raribleContract;
    isERC721[_raribleTokenId] = _isERC721;
  }
}

abstract contract RaribleERC721 {
  function isApprovedForAll(address _owner, address _operator) virtual public view returns (bool);
  function ownerOf(uint256 _tokenId) virtual public view returns (address);
  function burn(uint256 _tokenId) virtual public;
}

abstract contract RaribleERC1155 {
  function isApprovedForAll(address _owner, address _operator) virtual public view returns (bool);
  function balanceOf(address _owner, uint256 _id) virtual public view returns (uint256);
  function burn(address _owner, uint256 _id, uint256 _value) virtual public;
}

abstract contract WMinter {
  function balanceOf(address _account, uint256 _id) virtual public view returns (uint256);
  function balanceOfBatch(address[] memory _accounts, uint256[] memory _ids) virtual public view returns (uint256[] memory);

  function mint(address _to, uint256 _id, uint256 _amount) virtual public;
  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) virtual public;
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