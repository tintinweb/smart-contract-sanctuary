// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity 0.8.0;

import "./0-context.sol";

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable is Context
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    virtual
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./0-ownable.sol";
import "./0-erc721.sol";
import "./0-ierc20.sol";
import "./9-blacklister.sol";

/*
0x5e94B621128Bd55E9cba527CBf9D021565406594, [
  "0x7CAF64245A384eAd6A3Aa70690462A869291a7B1",
  "0x89Ef414D1E7123192Aba9b78Bd6792157A1a8a07",
  "0x5BDa7d4146739DA0654c0a1A8945830ab42E5F62"
]
*/

/*
0x3e32558F319f1D650aC17f82f3ac76976e9DC9aF, [
  "0x43bAB1A12dB095641CC8B13c3B23347FA2b3AAa4",
  "0x70784d8A360491562342B4F3d3D039AaAcAf8F5D",
  "0xAEb60a1fCa0ae49e220DD632fD14294d851B3fd8"
]
*/

contract Market is Ownable {
  struct Config {
    ERC721 petNft;
    IERC20 erc20Token;
    Blacklister blacklister;
  }
  
  ERC721 public petNft;
  IERC20 public erc20Token;
  Blacklister public blacklister;

  constructor(Config memory config) {
    petNft = config.petNft;
    erc20Token = config.erc20Token;
    blacklister = config.blacklister;
  }

  enum MarketItemStatus {
    LISTING,
    CANCELED,
    TRADED
  }

  struct MarketItem {
    uint itemId;
    uint256 tokenId;
    address seller;
    uint256 price;
    MarketItemStatus status;
  }

  mapping(uint256 => MarketItem) public marketItems;

  event MarketItemCreated(
    uint256 itemId,
    uint256 tokenId,
    address seller,
    uint256 price
  );

  uint256 public LISTING_FEE = 10 ether;
  
  function setListingFee(uint256 newFee) public onlyOwner {
    LISTING_FEE = newFee;
  }

  uint256 itemCount = 0;

  function sell(uint256 tokenId, uint256 price) public {
    blacklister.ensureAccountNotInBlacklist(_msgSender());
    blacklister.ensurePetNotInBlacklist(tokenId);
    if (LISTING_FEE != 0) {
      erc20Token.transferFrom(_msgSender(), address(this), LISTING_FEE);
    }

    petNft.transferFrom(_msgSender(), address(this), tokenId);
    
    uint itemId = itemCount++;
    marketItems[itemId] = MarketItem({
      itemId: itemId,
      tokenId: tokenId,
      seller: _msgSender(),
      price: price,
      status: MarketItemStatus.LISTING
    });

    emit MarketItemCreated(
      itemId,
      tokenId,
      _msgSender(),
      price
    );
  }

  event MarketItemCanceled(uint256 itemId);

  function cancel(uint256 itemId) public {
    blacklister.ensureAccountNotInBlacklist(_msgSender());
    blacklister.ensurePetNotInBlacklist(itemId);
    MarketItem storage marketItemItem  = marketItems[itemId];
    require(marketItemItem.status == MarketItemStatus.LISTING, "ONLY_ACTIVE_ITEM");
    require(marketItemItem.seller == _msgSender(), "ONLY_SELLER");

    petNft.transferFrom(address(this), _msgSender(), marketItemItem.tokenId);
    marketItemItem.status = MarketItemStatus.CANCELED;
    emit MarketItemCanceled(itemId);
  }

  uint256 public TRADING_FEE = 5; // 5%
  
  function setTradingFee(uint256 newFee) public onlyOwner {
    TRADING_FEE = newFee;
  }

  event MarketItemTraded(uint256 itemId, address buyer);

  function buy(uint256 itemId) public {
    blacklister.ensureAccountNotInBlacklist(_msgSender());
    blacklister.ensurePetNotInBlacklist(itemId);
    MarketItem storage marketItemItem  = marketItems[itemId];
    require(marketItemItem.status == MarketItemStatus.LISTING, "ONLY_ACTIVE_ITEM");

    petNft.transferFrom(address(this), _msgSender(), marketItemItem.tokenId);

    uint256 fee = TRADING_FEE * marketItemItem.price / 100;
    
    erc20Token.transferFrom(_msgSender(), address(this), fee);
    erc20Token.transferFrom(_msgSender(), marketItemItem.seller, marketItemItem.price - fee);

    marketItemItem.status = MarketItemStatus.TRADED;
    emit MarketItemTraded(itemId, _msgSender());
  }

  function withdrawMatic() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(uint256 amount, IERC20 erc20) public onlyOwner {
    erc20.transfer(owner, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./0-ownable.sol";
import "./0-ierc20.sol";

contract Blacklister is Ownable {

  mapping(address => bool) public accountBlackList;

  event AddAccountBlacklist(address account);

  function addAccountBackList(address[] memory accounts) public onlyOwner {
    uint256 length = accounts.length;
    for (uint256 index = 0; index < length; index++) {
      accountBlackList[accounts[index]] = true;
      emit AddAccountBlacklist(accounts[index]);
    }
  }

  event RemoveAccountBlacklist(address account);

  function removeAccountBlackList(address[] memory accounts) public onlyOwner {
    uint256 length = accounts.length;
    for (uint256 index = 0; index < length; index++) {
      accountBlackList[accounts[index]] = false;
      emit RemoveAccountBlacklist(accounts[index]);
    }
  }

  function ensureAccountNotInBlacklist(address account) public view {
    require(!accountBlackList[account], "BLACKLISTED");
  }

  mapping(uint256 => bool) public petBlackList;

  event AddPetBlacklist(uint256 id);

  function addPetBackList(uint256[] memory ids) public onlyOwner {
    uint256 length = ids.length;
    for (uint256 index = 0; index < length; index++) {
      petBlackList[ids[index]] = true;
      emit AddPetBlacklist(ids[index]);
    }
  }

  event RemovePetBlacklist(uint256 id);

  function removePetBlackList(uint256[] memory ids) public onlyOwner {
    uint256 length = ids.length;
    for (uint256 index = 0; index < length; index++) {
      petBlackList[ids[index]] = false;
      emit RemovePetBlacklist(ids[index]);
    }
  }

  function ensurePetNotInBlacklist(uint256 id) public view {
    require(!petBlackList[id], "BLACKLISTED");
  }

  function withdrawMatic() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(uint256 amount, IERC20 erc20) public onlyOwner {
    erc20.transfer(owner, amount);
  }
}