pragma solidity >=0.6.12 <0.9.0;

import "../main/security/IGuarder.sol";
import "../lib/Address.sol";
import "../interface/Ownable.sol";

contract BaseSecurityController is Ownable {
  IGuarder internal _guarderContract;
  
  bool private _isMaintenance = false;

  mapping(address => uint256) lastBlockNumberCalled;

  constructor(address guarderAddress) {
    _guarderContract = IGuarder(guarderAddress);
  }

  modifier oncePerBlock(address user) {
		require(lastBlockNumberCalled[user] < block.number, "Once call per block");
		lastBlockNumberCalled[user] = block.number;
		_;
	}

  modifier notForBannedUser(address user) {
    require(!_guarderContract.isUserBanned(user), "Banned account");
    _;
  }

  modifier notForBannedCharacter(uint256 tokenId) {
    require(!_guarderContract.isCharacterBanned(tokenId), "Banned character");
    _;
  }

  modifier notForBannedItem(uint256 tokenId) {
    require(!_guarderContract.isCharacterBanned(tokenId), "Banned item");
    _;
  }

  modifier notUnderMaintenance {
    require(!_isMaintenance, "Under maintenance");
    _;
  }

  function banCharacter(uint256 tokenId) internal {
    _guarderContract.banCharacter(tokenId);
  }

  function banItems(uint256[] memory itemIds) internal {
    _guarderContract.banItems(itemIds);
  }

  function checkCallFromContract(address sender) internal returns(bool) {
    if(sender != tx.origin) {
      _guarderContract.banUser(sender);
      _guarderContract.banUser(tx.origin);
      return true;
    }
    return false;
  }

  function updateGuarder(address newGuarderAddress) public onlyAuthorized {
    require(newGuarderAddress != address(0));
    _guarderContract = IGuarder(newGuarderAddress);
  }

  function updateMaintenance(bool isMaintenance) external onlyAuthorized {
    _isMaintenance = isMaintenance;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.12 <0.9.0;

interface IBep20Token {
  function balanceOf(address account) external view returns(uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.9.0;

import "./Context.sol";

abstract contract Ownable is Context {
    address internal _owner;
    mapping(address => bool) internal _authorizedActor;

    event AuthorityTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 authorityType
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _authorizedActor[msgSender] = true;
        emit AuthorityTransferred(address(0), msgSender, 1);
        emit AuthorityTransferred(address(0), msgSender, 2);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function isAuthorized(address actor) public view returns(bool) {
      return _authorizedActor[actor];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAuthorized() {
      require(owner() == _msgSender() || _authorizedActor[msg.sender], "No permission");
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
        emit AuthorityTransferred(_owner, address(0), 1);
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyAuthorized {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit AuthorityTransferred(_owner, newOwner, 1);
        _owner = newOwner;
    }

    function updateActorPermission(address actor, bool authorized) public onlyAuthorized {
      _authorizedActor[actor] = authorized;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../model/ItemInfo.sol";

interface IItemController {
  function isOwner(address owner, uint256 tokenId) external view returns(bool);

  function getInfoForItems(uint256[] memory tokenIds) external view returns(ItemInfo[] memory);

  function getOpponentItemBonusRewardFactor(uint256 power) external view returns(uint256);

  function finishFighting(
    address user, ItemInfo[] memory itemInfoList, uint256 manaCostPerBattle
  ) external;

  function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;

import "../../../model/ItemInfo.sol";

interface INftItems {
  function balanceOf(address owner) external view returns(uint256);

  function ownerOf(uint256 tokenId) external view returns(address);

  function mintItem(
    address owner, uint256 itemType, uint256 rarity, uint256 mana, 
    uint256 baseReward, uint256 luck, uint256 bonusReward, uint256 criticalChance
  ) external returns(uint256);

  function mintCombo(
    address owner, uint256 totalItems, uint256 mana, uint256[] memory itemTypes, uint256[] memory baseRewards, 
    uint256[] memory rarities, uint256[] memory lucks, uint256[] memory bonusRewards, uint256[] memory criticalChances
  ) external returns(uint256[] memory);

  function getTotalTokens() external view returns(uint256);

  function transferOwnership(address newOwner) external;

  function transferExecutiveAuthority(address newOwner) external;

  function getItemInfo(uint256 tokenId) external view returns(ItemInfo memory);

  function getItems(uint256[] memory tokenIds) external view returns(ItemInfo[] memory);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);

  function updateItemImmutableInfoList(ItemInfo[] memory itemInfoList) external;

  function updateItemMutableInfoList(ItemInfo[] memory itemInfoList) external;

  function getTotalOwnedItemsByItemType(address owner, uint256 itemType) external view returns(uint256);

  function getOwnerItemInfoByItemTypeAndIndex(
    address owner, uint256 itemType, uint256 index
  ) external view returns(ItemInfo memory);

  function transferFrom(address from, address to, uint256 tokenId) external;

  function approve(address to, uint256 tokenId) external;

  function mintItems(address owner, ItemInfo[] memory itemInfoList) external;
}

pragma solidity ^0.8.0;

import "../../../base/BaseSecurityController.sol";
import "../../item/nft/INftItems.sol";
import "../item/IMarketItemManager.sol";
import "../../../interface/IBep20Token.sol";
import "../../item/controller/IItemController.sol";
import "../../../model/ItemInfo.sol";
import "../../../model/MarketItemInfo.sol";

contract MarketController is BaseSecurityController {
  INftItems private _nftItemsContract;
  IMarketItemManager private _marketItemManager;
  IBep20Token private _tokenContract;

  event ItemOnSale(uint256 indexed tokenId, address indexed owner, uint256 price);
  event ItemOffSale(uint256 indexed tokenId, address indexed owner);
  event ItemPriceChanged(uint256 indexed tokenId, address indexed owner, uint256 price);
  event ItemSold(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner, uint256 price);

  modifier isOwnerOf(uint256 tokenId) {
    require(
      _nftItemsContract.ownerOf(tokenId) == msg.sender, 
      "Not item owner"
    );
    _;
  }

  constructor(
    address nftItemsAddress, address marketItemManagerAddress,
    address tokenAddress, address guarderAddress
  ) BaseSecurityController(guarderAddress) {
    _nftItemsContract = INftItems(nftItemsAddress);
    _marketItemManager = IMarketItemManager(marketItemManagerAddress);
    _tokenContract = IBep20Token(tokenAddress);
  }

  /** Area business logic --- BEGIN */
  // User must approve for this contract to transfer first
  function addListing(
    uint256 tokenId, uint256 price
  ) public notForBannedUser(msg.sender) isOwnerOf(tokenId) notForBannedItem(tokenId) oncePerBlock(msg.sender) notUnderMaintenance {
    require(price > 0, "Price invalid");

    _marketItemManager.addListing(msg.sender, tokenId, price);

    // Transfer first
    _nftItemsContract.transferFrom(msg.sender, address(_nftItemsContract), tokenId);

    emit ItemOnSale(tokenId, msg.sender, price);
  }

  function cancelListing(uint256 tokenId) 
      public notForBannedUser(msg.sender) notForBannedItem(tokenId) oncePerBlock(msg.sender) notUnderMaintenance {
    _marketItemManager.cancelListing(msg.sender, tokenId);

    _nftItemsContract.transferFrom(address(_nftItemsContract), msg.sender, tokenId);

    emit ItemOffSale(tokenId, msg.sender);
  }

  function changePrice(
    uint256 tokenId, uint256 price
  ) public notForBannedUser(msg.sender) notForBannedItem(tokenId) oncePerBlock(msg.sender) notUnderMaintenance {
    require(price > 0, "Price invalid");

    _marketItemManager.changePrice(msg.sender, tokenId, price);

    emit ItemPriceChanged(tokenId, msg.sender, price);
  }

  function buyItem(uint256 tokenId) 
      public notForBannedUser(msg.sender) notForBannedItem(tokenId) oncePerBlock(msg.sender) notUnderMaintenance {
    (address currentOwner, uint256 itemPrice) = _marketItemManager.getItemOwnerAndPrice(tokenId);
    require(currentOwner != msg.sender, "Your own item");

    _marketItemManager.sellItem(tokenId);

    bool isPaymentSuccess = _tokenContract.transferFrom(msg.sender, currentOwner, itemPrice);
    require(isPaymentSuccess, "Payment unsuccessful");

    _nftItemsContract.transferFrom(address(_nftItemsContract), msg.sender, tokenId);

    emit ItemSold(tokenId, currentOwner, msg.sender, itemPrice);
  }

  function getMarketItemInfo(uint256 tokenId) public view returns(MarketItemInfo memory) {
    ItemInfo memory itemInfo = _nftItemsContract.getItemInfo(tokenId);
    (address owner, uint256 price) = _marketItemManager.getItemOwnerAndPrice(tokenId);

    MarketItemInfo memory marketItemInfo = makeMarketItemInfo(itemInfo);
    marketItemInfo.price = price;
    marketItemInfo.owner = owner;

    return marketItemInfo;
  }

  function getMarketItemInfoByList(uint256[] memory tokenIds) public view returns(MarketItemInfo[] memory) {
    MarketItemInfo[] memory marketItemPriceAndOwnerList = _marketItemManager.getItemOwnerAndPriceByList(tokenIds);
    
    ItemInfo[] memory itemInfoList = _nftItemsContract.getItems(tokenIds);
    MarketItemInfo[] memory finalMarketItemInfoList = new MarketItemInfo[](tokenIds.length);

    for(uint256 i=0;i<tokenIds.length;i++) {
      MarketItemInfo memory marketItemInfo = makeMarketItemInfo(itemInfoList[i]);
      MarketItemInfo memory ownerAndPriceInfo = marketItemPriceAndOwnerList[i];

      marketItemInfo.price = ownerAndPriceInfo.price;
      marketItemInfo.owner = ownerAndPriceInfo.owner;

      finalMarketItemInfoList[i] = marketItemInfo;
    }

    return finalMarketItemInfoList;
  }
  /** Area business logic --- END */

  /** Area update contracts --- BEGIN */
  function updateNftItemsContract(address nftItemsAddress) public onlyAuthorized {
    _nftItemsContract = INftItems(nftItemsAddress);
  }

  function updateMarketItemManager(address marketItemManagerAddress) public onlyAuthorized {
    _marketItemManager = IMarketItemManager(marketItemManagerAddress);
  }

  function updateTokenContract(address tokenContractAddress) public onlyAuthorized {
    _tokenContract = IBep20Token(tokenContractAddress);
  }
  /** Area update contracts --- END */

  /** Area transfer ownership --- BEGIN */
  function transferMarketItemManagerOwnership(address newOwner) public onlyAuthorized {
    require(newOwner != address(0), "Transfer to 0");
    _marketItemManager.transferOwnership(newOwner);
  }
  /** Area transfer ownership --- END */

  function makeMarketItemInfo(ItemInfo memory itemInfo) private pure returns(MarketItemInfo memory) {
    MarketItemInfo memory marketItemInfo;

    marketItemInfo.tokenId = itemInfo.tokenId;
    marketItemInfo.luck = itemInfo.luck;
    marketItemInfo.classId = itemInfo.classId;
    marketItemInfo.enhancementLevel = itemInfo.enhancementLevel;
    marketItemInfo.itemType = itemInfo.itemType;
    marketItemInfo.rarity = itemInfo.rarity;
    marketItemInfo.criticalChance = itemInfo.criticalChance;

    return marketItemInfo;
  }
}

pragma solidity ^0.8.0;

import "../../../model/MarketItemInfo.sol";

interface IMarketItemManager {
  function addListing(address owner, uint256 tokenId, uint256 price) external;

  function cancelListing(address owner, uint256 tokenId) external;

  function changePrice(address owner, uint256 tokenId, uint256 price) external;

  function sellItem(uint256 tokenId) external;

  function getPriceOf(uint256 tokenId) external view returns(uint256);

  function ownerOf(uint256 tokenId) external view returns(address);

  function getItemOwnerAndPrice(uint256 tokenId) external view returns(address, uint256);

  function getItemOwnerAndPriceByList(uint256[] memory tokenIds) external view returns(MarketItemInfo[] memory);

  function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;

interface IGuarder {
  function isUserBanned(address account) external view returns(bool);

  function isCharacterBanned(uint256 tokenId) external view returns(bool);

  function isItemBanned(uint256 tokenId) external view returns(bool);

  function banUser(address account) external returns(bool);

  function banCharacter(uint256 tokenId) external returns(bool);

  function banItem(uint256 tokenId) external returns(bool);

  function banItems(uint256[] memory itemIds) external returns(bool);
}

pragma solidity ^0.8.0;

struct ItemInfo {
  uint256 tokenId;
  uint256 baseReward;
  uint256 bonusReward;
  uint256 lastUsedManaTime;
  uint256 luck;
  uint256 mana;
  uint256 classId;
  uint256 enhancementLevel;
  uint256 itemType;
  uint256 rarity;
  uint256 criticalChance;
  uint256 status; // 1 - able to fight; 2 - on sale
}

pragma solidity ^0.8.0;

struct MarketItemInfo {
  uint256 tokenId;
  uint256 luck; // uint16
  uint256 classId; // uint8
  uint256 enhancementLevel; // uint8
  uint256 itemType; // uint8
  uint256 rarity; // uint8
  uint256 criticalChance; // uint8
  uint256 price; // uint256
  address owner;
}

