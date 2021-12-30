// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../interfaces/ILordArenaCharacter.sol";
import "../interfaces/ILordArenaEquipment.sol";
import "../utils/RandomUtil.sol";

contract GachaBox is Initializable, OwnableUpgradeable {
  constructor() initializer {}

  struct BoxInfo {
    uint256 quota;
    uint256 totalSold;
    uint256 price;
    address currency;
    uint256 maxRewardCardNumber;
  }

  mapping(uint256 => BoxInfo) public boxConfig;
  address public lordArenaCharacter;
  address public lordArenaItem;
  address public treasury;
  address public buyToken;
  address private randomContract;
  event NewBoxBUSD(
    address indexed minter,
    uint256 character1NFTId,
    uint256 character2NFTId,
    uint256 character3NFTId,
    uint256 indexed character5NFTId,
    uint256 indexed equipmentNFTId
  );
  event NewBoxLORDA(address indexed minter, uint256 indexed character5NFTId);

  function initialize() public initializer {
    __Ownable_init();
  }

  modifier onlyNonContract {
    require(tx.origin == msg.sender, "Only non-contract call");
    _;
  }

  // Update config
  function updateConfig(
    address _lordArenaCharacter,
    address _lordArenaItem,
    address _treasury,
    address _randomContract
  ) public onlyOwner {
    lordArenaCharacter = _lordArenaCharacter;
    lordArenaItem = _lordArenaItem;
    treasury = _treasury;
    randomContract = _randomContract;
  }

  // Update boxConfig
  function updateBoxConfig(
    uint256 _quota,
    uint256 _price,
    uint256 _boxId,
    uint256 _maxRewardCardNumber,
    address _currencyToken
  ) public onlyOwner {
    require(_boxId != 0, "Invalid boxId");
    require(_boxId < 4, "Invalid boxId");
    boxConfig[_boxId].quota = _quota;
    boxConfig[_boxId].price = _price;
    boxConfig[_boxId].currency = _currencyToken;
    boxConfig[_boxId].maxRewardCardNumber = _maxRewardCardNumber;
  }

  function getCharacterIds()
    public view
    returns (uint256[] memory, uint256[] memory)
  {
    uint256[] memory characterIds = new uint256[](4);
    uint256[] memory characterQualities = new uint256[](4);
    uint256[13] memory characters = [uint256(8), 9, 10, 11, 20, 21, 22, 31, 32, 33, 41, 42, 43];

    for (uint256 i = 0; i < 4; i++) {
      // uint256 characterIdx = RandomUtil(randomContract).getRandomNumber(characters.length - i);
      characterIds[i] = characters[i];
      // characters[characters.length - i] = characters[characterIdx];

      // uint256 pctRnd = RandomUtil(randomContract).getRandomNumber(100);
      characterQualities[i] = 2;
      // if (pctRnd <= 60) {
      //   characterQualities[i] = 2;
      // } else {
      //   characterQualities[i] = 3;
      // }
    }
    return (characterIds, characterQualities);
  }

  function testgetCharacterIds()
    public view
    returns (uint256[] memory)
  {
    uint256[] memory characterIds = new uint256[](4);
    uint256[] memory characterQualities = new uint256[](4);
    uint256[13] memory characters = [uint256(8), 9, 10, 11, 20, 21, 22, 31, 32, 33, 41, 42, 43];

    for (uint256 i = 0; i < 4; i++) {
      // uint256 characterIdx = RandomUtil(randomContract).getRandomNumber(characters.length - i);
      characterIds[i] = characters[i];
      // characters[characters.length - i] = characters[characterIdx];

      // uint256 pctRnd = RandomUtil(randomContract).getRandomNumber(100);
      characterQualities[i] = 2;
      // if (pctRnd <= 60) {
      //   characterQualities[i] = 2;
      // } else {
      //   characterQualities[i] = 3;
      // }
    }
    return (characterIds);
  }

  function getSpecialCharacterNFTId() public view returns (uint256 characterNFTId) {
    uint8[26] memory characters =
      [1, 2, 3, 4, 5, 6, 14, 15, 16, 17, 18, 19, 25, 26, 27, 28, 29, 30, 36, 37, 38, 39, 40, 47, 48, 49];
    uint256 qualityId;

    uint256 pctRnd = RandomUtil(randomContract).getRandomNumber(1000);
    if (pctRnd <= 5) {
      uint256 highRnd = RandomUtil(randomContract).getRandomNumber(2);
      qualityId = highRnd == 1 ? 9 : 10;
    } else if (pctRnd <= 10) {
      qualityId = 9;
    } else if (pctRnd <= 30) {
      qualityId = 7;
    } else if (pctRnd <= 150) {
      qualityId = 6;
    } else {
      qualityId = 5;
    }

    uint256 characterId = characters[RandomUtil(randomContract).getRandomNumber(characters.length - 1)];
    return characterId;
    // characterNFTId = ILordArenaCharacter(lordArenaCharacter).safeMint(msg.sender, characterId, qualityId);
  }

  function genCharacterIdByLORDA() public view returns (uint256 characterId, uint256 qualityId) {
    uint8[8] memory commonCharacters = [12, 23, 34, 44, 13, 24, 35, 45];
    uint8[13] memory rareCharacters = [10, 41, 20, 31, 9, 43, 22, 32, 11, 42, 21, 33, 8];
    uint8[39] memory eliteCharacters =
      [
        1,
        2,
        3,
        4,
        5,
        6,
        8,
        9,
        10,
        11,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        47,
        48,
        49
      ];

    uint256 pctRnd = RandomUtil(randomContract).getRandomNumber(100);
    if (pctRnd <= 8) {
      qualityId = 4;
      characterId = eliteCharacters[RandomUtil(randomContract).getRandomNumber(eliteCharacters.length - 1)];
    } else if (pctRnd <= 40) {
      qualityId = 1;
      characterId = commonCharacters[RandomUtil(randomContract).getRandomNumber(commonCharacters.length - 1)];
    } else {
      qualityId = 2;
      characterId = rareCharacters[RandomUtil(randomContract).getRandomNumber(rareCharacters.length - 1)];
    }
  }

  function openBoxByBUSD(uint256 _boxId)
    public
    onlyNonContract
    returns (
      uint256 character1NFTId,
      uint256 character2NFTId,
      uint256 character3NFTId,
      uint256 character4NFTId,
      uint256 character5NFTId,
      uint256 equipmentNFTId
    )
  {
    require(boxConfig[_boxId].totalSold <= boxConfig[_boxId].quota, "Box is full");
    require(boxConfig[_boxId].price > 0, "Invalid Box.");
    boxConfig[_boxId].totalSold += 1;
    IERC20Upgradeable(boxConfig[_boxId].currency).transferFrom(msg.sender, treasury, boxConfig[_boxId].price);

    uint256[4] memory characterNFTIds;
    (uint256[] memory characterIds, uint256[] memory characterQualities) = getCharacterIds();
    for (uint8 i = 0; i < 4; i++) {
      uint256 characterNFTId =
        ILordArenaCharacter(lordArenaCharacter).safeMint(msg.sender, characterIds[i], characterQualities[i]);
      characterNFTIds[i] = characterNFTId;
    }
    character1NFTId = characterNFTIds[0];
    character2NFTId = characterNFTIds[1];
    character3NFTId = characterNFTIds[2];
    character4NFTId = characterNFTIds[3];
    // character5NFTId = getSpecialCharacterNFTId();
    uint256 itemId = RandomUtil(randomContract).getRandomNumber(12);
    equipmentNFTId = ILordArenaEquipment(lordArenaItem).safeMint(msg.sender, itemId, 4);
    emit NewBoxBUSD(msg.sender, character1NFTId, character2NFTId, character3NFTId, character5NFTId, equipmentNFTId);
  }

  function openBoxByLORDA(uint256 _boxId) public onlyNonContract returns (uint256 characterNFTId) {
    require(boxConfig[_boxId].totalSold <= boxConfig[_boxId].quota, "Box is full");
    require(boxConfig[_boxId].price > 0, "Invalid Box.");
    boxConfig[_boxId].totalSold += 1;
    IERC20Upgradeable(boxConfig[_boxId].currency).transferFrom(msg.sender, treasury, boxConfig[_boxId].price);
    (uint256 characterId, uint256 qualityId) = genCharacterIdByLORDA();
    characterNFTId = ILordArenaCharacter(lordArenaCharacter).safeMint(msg.sender, characterId, qualityId);
    emit NewBoxLORDA(msg.sender, characterNFTId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../dependencies/open-zeppelin/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ILordArenaCharacter is IERC165Upgradeable {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */

  struct CharacterInfo {
    uint256 nftID;
    uint256 level;
    uint256 characterID;
    uint256 quality; // 1 common, 2 rare, 3 rare+, 4 elite, 5 elite+, 6 legendary, 7 legendary+, 8 mythic, 9 mythic+, 10 immortal
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  /**
   * @dev Safely mint `_characterId` to `_to` with quality `_quality`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `_characterId` must exist.
   * - `_quality` 1 common, 2 rare, 3 rare+, 4 elite, 5 elite+, 6 legendary, 7 legendary+, 8 mythic, 9 mythic+, 10 immortal
   */
  function safeMint(
    address to,
    uint256 _characterId,
    uint256 _quality
  ) external returns (uint256);

  function getTokenOwners(address _owner, uint256[] memory _selectedIdx) external view returns (CharacterInfo[] memory);

  function tokensOfOwners(address _owner, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../dependencies/open-zeppelin/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ILordArenaEquipment is IERC165Upgradeable {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */

  struct CharacterInfo {
    uint256 nftID;
    uint256 level;
    uint256 equipmentID;
    uint256 quality; // 1 common, 2 rare, 3 rare+, 4 elite, 5 elite+, 6 legendary, 7 legendary+, 8 mythic, 9 mythic+, 10 immortal
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  /**
   * @dev Safely mint `_characterId` to `_to` with quality `_quality`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `_characterId` must exist.
   * - `_quality` 1 common, 2 rare, 3 rare+, 4 elite, 5 elite+, 6 legendary, 7 legendary+, 8 mythic, 9 mythic+, 10 immortal
   */
  function safeMint(
    address to,
    uint256 _equipmentId,
    uint256 _quality
  ) external returns (uint256);

  function getTokenOwners(address _owner, uint256[] memory _selectedIdx) external view returns (CharacterInfo[] memory);

  function tokensOfOwners(address _owner, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../dependencies/open-zeppelin/utils/StringsUpgradeable.sol";

contract RandomUtil is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    uint256 randomCounter;
    mapping(address => bool) public whitelistRandom;  

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyWhitelistRandom() {
        require(whitelistRandom[msg.sender], 'Only whitelist');
        _;
    }

    function getRandomSeed() internal view returns (uint256) {
        return uint256(sha256(abi.encodePacked(block.coinbase, randomCounter, blockhash(block.number -1), block.difficulty, block.gaslimit, block.timestamp, gasleft(), msg.sender)));
    }

    function setWhiteList(address _whitelist, bool status) public onlyOwner {
        whitelistRandom[_whitelist] = status;
    }

    // Get random number
    function updateCounter(uint256 addedCounter) public onlyWhitelistRandom{
        unchecked { randomCounter += addedCounter; }
    }

    // Get random number
    function getRandomNumber(uint256 _rate) public view onlyWhitelistRandom returns (uint256) {
        return (getRandomSeed() % _rate)  + 1;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}