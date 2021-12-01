/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/comics/ACDrop.sol


pragma solidity ^0.8.0;

interface ACMint {
  function mint(
    address to,
    uint256 tokenId
  )
    external;
}

contract ACDrop is Ownable {

  /**
   * @dev Time when the drop starts
   */
  uint256 public dropStart;
  /**
   * @dev Address of Aradena comics smart contract.
   */
  ACMint public ACaddress;

  /**
   * @dev AC token ids.
   */
  uint256 public nextId;

  /**
   * @dev AC token maxId (Total supply is  maxId - nextId + 1).
   */
  uint256 public maxId;

  /**
   * @dev Used wallets - one mint per wallet.
   */
  mapping(address => bool) usedWallets;

  /**
   * @dev If drop is paused or not.
   */
  bool public isPaused = false;

  /**
   * @dev Price per token.
   */
  uint256 public price; // 0.1 ETH

  /**
   * @dev Amount of reserved tokens.
   */
  uint16 public reserve;

  /**
   * @dev Sets default variables.
   * @param _ACaddress Address of aradena comic smart contract.
   * @param _dropStart Unix timestamp (in seconds) from which the drop will be available.
   * @param _nextId First id in AC comics that does not yet exist.
   * @param _maxId Max id of AC comics that this drop can create.
   * @param _price Price per token.
   * @param _reserve Amount of tokens reserved.
   */
  constructor(
    address _ACaddress,
    uint256 _dropStart,
    uint256 _nextId, 
    uint256 _maxId,
    uint256 _price,
    uint16 _reserve
  ) {
    ACaddress = ACMint(_ACaddress);
    dropStart = _dropStart;
    nextId = _nextId;
    maxId = _maxId;
    price = _price;
    reserve = _reserve;
  }

  /**
   * @dev Mint tokens reserved for owner.
   * @param _quantity Amount of reserve tokens to mint.
   * @param _receiver Receiver of the tokens.
   */
  function mintReserve(
    uint16 _quantity,
    address _receiver
  )
    external
    onlyOwner
  {
    require(_quantity <= reserve, "The quantity exceeds the reserve.");
    reserve -= _quantity;
    for (uint i = 0; i < _quantity; i++) {
      ACaddress.mint(_receiver, nextId);
      nextId++;
    }
  } 

  /**
   * @dev Buys an aradena comic NFT.
   */
  function mint()
    public
    payable
  {
    require(block.timestamp >= dropStart, "Drop not yet available.");
    require(!usedWallets[msg.sender], "Wallet already used.");
    require(!isPaused, "Drop is not active.");
    require(nextId <= maxId - reserve, "Drop is sold out.");
    require(price == msg.value, "Sent ether value is incorrect.");

    usedWallets[msg.sender] = true;
    ACaddress.mint(msg.sender, nextId);
    nextId++;
  }

  /**
   * @dev Changes pause state.
   */
  function flipPauseStatus()
    external
    onlyOwner
  {
    isPaused = !isPaused;
  }

  /**
   * Default for sending eth.
   */
  receive()
    external
    payable
  {
    mint();
  }

  /**
   * @dev Withdraws eth.
   */
  function withdraw()
    external
    onlyOwner
  {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}