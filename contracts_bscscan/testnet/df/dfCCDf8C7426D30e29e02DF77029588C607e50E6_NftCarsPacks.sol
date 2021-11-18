// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface INFTCARS {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract NftCarsPacks is Ownable {
  // price for a token is pack price is not set
  uint256 public basePrice;
  // uint256 private currectIndex

  // wallet address that holds NFTs
  // should setApprovementForAll for this contract to be able to transfer tokens
  address public tokensHolder;

  // NFTCARS contract address
  address public constant NFT_CARS = 0xe37dA064468A33971794cCe0E66F220acEB0cEF7;

  // boolean to 
  // bool private startingIndexFinalised;
  
  // mapping for storing pack prices based on the tokens numbers in the pack
  mapping (uint256 => uint256) private packPrices;

  INFTCARS private NFTCARS = INFTCARS(NFT_CARS);

  // event that is triggered when pack purchase happens
  event buyPack(
    address buyer,
    uint256 numberOfTokensInPack,
    uint256[] tokenIdPurchased
  );

  /**
  * @dev Constructor sets the pase token price and the NFTs holder address
  */
  constructor (uint256 _basePrice, address _holderAddress) {
    basePrice = _basePrice;
    tokensHolder = _holderAddress;
  }

  /**
    * @dev Public method to return the price of N tokens (pack).
    * If price for a pack is not set it will be calculated based on the base price
  */
  function getPackPrice(uint256 numberOfTokens) public view returns (uint256) {
    uint256 packPrice = packPrices[numberOfTokens];
    if (packPrice == 0) {
      packPrice = numberOfTokens * basePrice;
    }
    return packPrice;
  }


  /**
  * @dev Internal method for generating random index
  */
  function getRandomIndex(uint256 maxIndex) internal view returns(uint256){
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _msgSender()))) % maxIndex;
  }

  /**
  * @dev Internal method getting random token ID of holder address
  */
  function getRandomToken() private view returns (uint256) {
    uint256 totalHolderBalance = NFTCARS.balanceOf(tokensHolder);
    uint256 randomIndex = getRandomIndex(totalHolderBalance);
    uint256 tokenToSend = NFTCARS.tokenOfOwnerByIndex(tokensHolder, randomIndex);
    return tokenToSend;
  }

  /**
  * @dev Public method that allows users to purchase N tockens at once (pack)
  * This method returnes the array of IDs that has been transferred to the new owner
  */
  function purchasePack(uint256 numberOfTokens) public payable returns (uint256[] memory) {
    require(NFTCARS.balanceOf(tokensHolder) >= numberOfTokens, 'Holder balance is less then number of requested tokens');
    require(getPackPrice(numberOfTokens) == msg.value, "BNB value sent is not correct");

    uint256[] memory tokenIdsToSend = new uint256[](numberOfTokens);

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 tokenIdToSend = getRandomToken();
      NFTCARS.safeTransferFrom(tokensHolder, _msgSender(), tokenIdToSend);
      tokenIdsToSend[i] = tokenIdToSend;
    }

    emit buyPack(_msgSender(), numberOfTokens, tokenIdsToSend);
    return(tokenIdsToSend);
  }

  /**
  * @dev Admin function that allows to change the price of PACK. Should pe set in wie.
  */
  function changePackPrice(uint256 numberOfTokens, uint256 price) public onlyOwner {
    packPrices[numberOfTokens] = price;
  }

  /**
  * @dev Admin function that allows to change the base price of token. Should pe set in wei.
  */
  function changeBasePrice(uint256 newPrice) public onlyOwner {
    require(newPrice != 0, 'price should be greater then 0');
    basePrice = newPrice;
  }

  /**
  * @dev Admin function that allows to change the holder tokens address.
  * New adddress should setApprovementForAll for this contract to be able to transfer tokens.
  */
  function changeHolderAddress(address newAddress) public onlyOwner {
    require(newAddress != address(0), 'cannot be 0 address');
    tokensHolder = newAddress;
  }

  /**
  * @dev Admin function that allows to withdraw all funds collected in the contract to the owner address.
  */
  function widthdraw() public onlyOwner {
    require(address(this).balance > 0, 'nothing to transfer');

    (bool sent, bytes memory data) = owner().call{value: address(this).balance}("");
    require(sent, "Failed to send BNB");
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