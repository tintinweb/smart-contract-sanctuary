// SPDX-License-Identifier: MIT
import "./ERC1155.sol";

pragma solidity >=0.6.0 <0.8.9;

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


contract NFTmint is ERC1155, Ownable {

  // Hashes of nft pictures on IPFS
  string[] public hashes;
  // Mapping for enforcing unique hashes
  mapping(string => bool) _hashExists;

  // Mapping from NFT token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from hash to NFT token ID
  mapping (string => address) private _hashToken;

  constructor() public ERC1155("https://game.example/api/item/{id}.json") {
  }

  function mint(string memory _hash, string memory _uri, bytes memory metadata) public {
    require(!_hashExists[_hash], "Token is already minted");
    require(bytes(_uri).length > 0, "uri should be set");
    hashes.push(_hash);
    uint _id = hashes.length - 1;
    _mint(msg.sender, _id, 1, _uri, metadata);
    _hashExists[_hash] = true;
  }

  function getNFTmintCount() public view returns(uint256 count) {
    return hashes.length;
  }

  function uri(uint256 _tokenId) public view override returns(string memory _uri) {
    return _tokenURI(_tokenId);
  }

  function setTokenUri(uint256 _tokenId, string memory _uri) public onlyOwner {
    _setTokenURI(_tokenId, _uri);
  }

  function safeTransferFromWithProvision(
    address payable from,
    address to,
    uint256 id,
    uint256 amount
    // uint256 price
  )
    public payable returns(bool approved)
  {
    setApprovalForAll(to,true);
    safeTransferFrom(from, to, id, amount, "0x0");
    return isApprovedForAll(from, to);
    // from.transfer(price);
  }

}