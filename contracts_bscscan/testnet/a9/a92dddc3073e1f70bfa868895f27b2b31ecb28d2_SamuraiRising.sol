// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

import './ERC721.sol';

interface IERC721Enumerable is IERC721 {

  function totalSupply() external view returns (uint);
  function tokenOfOwnerByIndex(address owner, uint index)
    external
    view
    returns (uint tokenId);
  function tokenByIndex(uint index) external view returns (uint);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint32 => uint32)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint32 => uint32) private _ownedTokensIndex;

  // The current index of the token
  uint32 public currentIndex;
  uint32 public burntCount;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint index)
    public
    view
    virtual
    override
    returns (uint)
  {
    require(
      index < ERC721.balanceOf(owner),
      "ERC721Enumerable: owner index out of bounds"
    );
    return _ownedTokens[owner][uint32(index)];
  }

  function totalSupply() public view virtual override returns (uint) {
    return currentIndex - burntCount;
  }

  function tokenByIndex(uint index)
    public
    view
    virtual
    override
    returns (uint)
  {
    require(
      index < currentIndex,
      "ERC721Enumerable: global index out of bounds"
    );
    return index;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint tokenId
  ) internal virtual override {
    require(to != address(0), "NFT not burnable");
    require (uint32(tokenId) == tokenId, "tokenId overflow");

    super._beforeTokenTransfer(from, to, tokenId);

    if (from == address(0)) {
      currentIndex++;
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, uint32(tokenId));
    }
    
    if (to == address(0)) {
        burntCount++;
    }

    if (to != from) {
      _addTokenToOwnerEnumeration(to, uint32(tokenId));
    }
  }

  function _addTokenToOwnerEnumeration(address to, uint32 tokenId) private {
    uint32 length = uint32(ERC721.balanceOf(to));
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _removeTokenFromOwnerEnumeration(address from, uint32 tokenId)
    private
  {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint32 lastTokenIndex = uint32(ERC721.balanceOf(from) - 1);
    uint32 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint32 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    AdjustVariables,
    Mint,
    ManagePacks,
    ManageAttributes,
    Withdraw
}

/**
 * Allows for contract ownership along with multi-address authorization for different permissions
 */
abstract contract RSunAuth {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint => bool)) private authorizations; // uint is permission index
    
    uint constant NUM_PERMISSIONS = 8; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint) permissionNameToIndex;
    mapping(uint => string) permissionIndexToName;

    mapping(uint => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        // a permission name can't be longer than 32 bytes
        permissionNameToIndex["Authorize"] = uint(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint(Permission.Unauthorize);
        permissionNameToIndex["LockPermissions"] = uint(Permission.LockPermissions);
        permissionNameToIndex["AdjustVariables"] = uint(Permission.AdjustVariables);
        permissionNameToIndex["Mint"] = uint(Permission.Mint);
        permissionNameToIndex["ManagePacks"] = uint(Permission.ManagePacks);
        permissionNameToIndex["ManageAttributes"] = uint(Permission.ManageAttributes);
        permissionNameToIndex["Withdraw"] = uint(Permission.Withdraw);

        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.AdjustVariables)] = "AdjustVariables";
        permissionIndexToName[uint(Permission.Mint)] = "Mint";
        permissionIndexToName[uint(Permission.ManagePacks)] = "ManagePacks";
        permissionIndexToName[uint(Permission.ManageAttributes)] = "ManageAttributes";
        permissionIndexToName[uint(Permission.Withdraw)] = "Withdraw";
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorizedFor(Permission permission) {
        require(!lockedPermissions[uint(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint(permission)]))); _;
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Authorize) {
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Authorize) {
        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, string memory permissionName) public view returns (bool) {
        return authorizations[adr][permissionNameToIndex[permissionName]];
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, Permission permission) public view returns (bool) {
        return authorizations[adr][uint(permission)];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * Get the index of the permission by its name
     */
    function getPermissionNameToIndex(string memory permissionName) public view returns (uint) {
        return permissionNameToIndex[permissionName];
    }
    
    /**
     * Get the time the timelock expires
     */
    function getPermissionUnlockTime(string memory permissionName) public view returns (uint) {
        return lockedPermissions[permissionNameToIndex[permissionName]].expiryTime;
    }

    /**
     * Check if the permission is locked
     */
    function isLocked(string memory permissionName) public view returns (bool) {
        return lockedPermissions[permissionNameToIndex[permissionName]].isLocked;
    }

    /*
     *Locks the permission from being used for the amount of time provided
     */
    function lockPermission(string memory permissionName, uint64 time) public virtual authorizedFor(Permission.LockPermissions) {
        uint permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }
    
    /*
     * Unlocks the permission if the lock has expired 
     */
    function unlockPermission(string memory permissionName) public virtual {
        require(block.timestamp > getPermissionUnlockTime(permissionName) , "Permission is locked until the expiry time.");
        uint permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint permissionIndex);
}

contract SamuraiRising is ERC721Enumerable, RSunAuth {

    struct Pack {
        uint232 basePrice;
        uint8 numberOfCards;
        bool saleRunning;
        uint8 cardSetId;
    }

    struct CardSet {
        uint64 minted;
        uint64 mintLimit;
        uint64 priceIncreasePerMilestone;
        uint64 milestoneEvery;
    }

    struct Attribute {
        string name;
        uint changeCost;
        address costToken;
    }

    struct FeeReceiver {
        address adr;
        uint96 weight;
    }
    
    // Attributes
    mapping(uint => mapping(string => string)) public nftAttributes;
    Attribute[] public attributes;
    mapping(string => bool) public attributeExists;
    mapping(string => uint) public attributeIndex;

    // Packs
    Pack[] public packTypes; // index is pack ID
    mapping(uint => uint) public packIdOfToken; // first is token ID, second is pack ID
    CardSet[] public cardSets;

    // Pricing
    uint public priceModDenominator = 100000;

    // Fees
    FeeReceiver[] feeReceivers;
    uint totalWeight;
    bool pushAutomatically = false;
    uint pushThreshold = 20 * 10 ** 14; // debug

    // Base URI
    string private _baseURIextended = "https://api.blowfish.one/test/";

    // ADDRESSES
    address public rsunAdr = 0xB9930e78423c6148f3b94A9781af19785a0FFB16;
    IBEP20 private rsun;

    // event DebugLog(string text, uint value);

    event PackPurchased(address user, uint8 packId);
    event CardMinted(address recipient, uint cardId, uint8 packId);

    // event PackAdded(uint packId, uint basePrice, uint numOfCards, uint cardSetId);
    // event PackEdited(uint packId, uint basePrice, uint numOfCards, bool saleRunning, uint cardSetId);
    // event SaleStarted(uint packId);
    // event SalePaused(uint packId);
    // event SaleRunningChanged(uint packId, bool saleRunning);

    // event CardSetAdded(uint setId, uint64 mintLimit, uint64 priceIncreasePerMilestone, uint64 milestoneEvery);
    // event CardSetEdited(uint setId, uint64 mintLimit, uint64 priceIncreasePerMilestone, uint64 milestoneEvery);

    // event AttributeAdded(uint id, string name, uint changeCost, address costToken);
    // event AttributeEdited(uint id, string name, uint changeCost, address costToken);
    // event AttributeChanged(uint cardId, string attributeName, string newValue);

    // event FeesPushed(address recipient, uint amount);

    constructor() ERC721("SamuraiRising", "Samurai Rising") RSunAuth(msg.sender) {
        rsun = IBEP20(rsunAdr);

        addCardSet(100, 1000, 3);
        addCardSet(20, 2000, 1);

        addPack(15 * 10 ** 14, 1, 0);
        // setSaleRunning(0, true);

        addPack(50 * 10 ** 14, 5, 0);
        // setSaleRunning(1, true);

        addPack(100 * 10 ** 14, 10, 0);
        // setSaleRunning(2, true);

        // addPack(150 * 10 ** 14, 15, 0);
        // setSaleRunning(3, true);
        
        addPack(200 * 10 ** 14, 25, 0);
        // setSaleRunning(3, true);


        addPack(40 * 10 ** 14, 1, 1);
        // setSaleRunning(4, true);

        // addPack(200 * 10 ** 14, 6, 1);
        // setSaleRunning(6, true);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function purchasePack(uint8 packId) external {
        Pack memory pack = packTypes[packId];
        CardSet memory cardSet = cardSets[pack.cardSetId];

        require(pack.saleRunning == true, "Sale not running");
        require(cardSet.minted + pack.numberOfCards <= cardSet.mintLimit, "Mint limit exceeded");

        _mintCardsOfPack(msg.sender, packId, pack.numberOfCards);

        cardSets[pack.cardSetId].minted += pack.numberOfCards;

        if (pushAutomatically && rsun.balanceOf(address(this)) >= pushThreshold) {
            pushFees();
        }

        require(rsun.transferFrom(msg.sender, address(this), getPrice(packId)), "Transfer failed");

        emit PackPurchased(msg.sender, packId);
    }

    function _mintCardsOfPack(address user, uint8 packId, uint8 numOfCards) internal {
        // uint loopStartGas = gasleft();
        // uint startGas;
        uint mintIndex = currentIndex;

        for (uint8 i; i < numOfCards; i++) {
            // startGas = gasleft();
            packIdOfToken[mintIndex] = packId;
            // emit DebugLog("Gas used by adding to packIdOfToken", startGas - gasleft());

            // startGas = gasleft();
            _safeMint(user, mintIndex);
            // emit DebugLog("Gas used _safeMint", startGas - gasleft());

            emit CardMinted(user, mintIndex, packId);

            mintIndex += 1;
        }
        // emit DebugLog("Gas used by the entire minting loop", loopStartGas - gasleft());
    }
    
    function getPrice(uint8 packId) public view returns (uint price) {
        Pack memory pack = packTypes[packId];
        price = pack.basePrice * getPriceMod(pack.cardSetId) / priceModDenominator;
    }

    function getPacks() external view returns (Pack[] memory) {
        return packTypes;
    }

    // function getPacksWithAdjustedPrices() external view returns (Pack[] memory) {
    //     Pack[] memory packs = packTypes;
    //     for (uint8 i = 0; i < packs.length; i++) {
    //         packs[i].basePrice = uint232(getPrice(i));
    //     }
    //     return packs;
    // }

    function getPriceMod(uint8 cardSetId) public view returns (uint mod) {
        CardSet memory set = cardSets[cardSetId];
        mod = (set.minted / set.milestoneEvery) * set.priceIncreasePerMilestone + priceModDenominator;
    }

    function changeAttribute(uint cardId, string memory attribute, string memory value) external {
        Attribute memory attr = attributes[attributeIndex[attribute]];
        require(ownerOf(cardId) == msg.sender, "Not owner");
        require(attributeExists[attribute], "Attribute doesn't exist");
        require(IBEP20(attr.costToken).transferFrom(msg.sender, address(this), attr.changeCost), "Transfer failed");

        nftAttributes[cardId][attribute] = value;

        // emit AttributeChanged(cardId, attribute, value);
    }

    function pushFees() public {
        uint toBeDistributed = rsun.balanceOf(address(this));
        // emit DebugLog("pushFees toBeDistributed", toBeDistributed);

        for (uint256 i = 0; i < feeReceivers.length; i++) {
            uint amt = toBeDistributed * feeReceivers[i].weight / totalWeight;
            
            // emit DebugLog("pushFees i", i);
            // emit DebugLog("pushFees amt", amt);
            // emit DebugLog("pushFees adr", uint160(feeReceivers[i].adr));

            /* bool test =  */rsun.transfer(feeReceivers[i].adr, amt);
            // emit DebugLog("pushFees transfer", test ? 1 : 0);
        
            // emit FeesPushed(feeReceivers[i].adr, amt);
        }
    }
    
    event Received(address sender, uint amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setBaseURI(string memory baseURI_) external authorizedFor(Permission.AdjustVariables) {
        _baseURIextended = baseURI_;
    }

    function setRsunAddress(address newAdr) external authorizedFor(Permission.AdjustVariables) {
        rsunAdr = newAdr;
        rsun = IBEP20(newAdr);
    }

    function setPushSettings(bool auto_, uint threshold_) external authorizedFor(Permission.AdjustVariables) {
        pushAutomatically = auto_;
        pushThreshold = threshold_;
    }

    function setFeeReceivers(address[] calldata receivers, uint96[] memory weights) external authorizedFor(Permission.AdjustVariables) {
        require(receivers.length == weights.length, "Not the same length.");

        delete feeReceivers; // clear the array
        uint total = 0;

        for (uint256 i = 0; i < receivers.length; i++) {
            feeReceivers.push(FeeReceiver(receivers[i], weights[i]));
            total += weights[i];
        }

        totalWeight = total;
    }

    function addPack(uint232 basePrice, uint8 numberOfCards, uint8 cardSetId) public authorizedFor(Permission.ManagePacks) {
        // require(basePrice > 0, "Price can't be 0");
        // require(numberOfCards > 0, "Too few cards");

        packTypes.push(Pack(
            basePrice,
            numberOfCards,
            false,
            cardSetId
        ));

        // emit PackAdded(packTypes.length - 1, basePrice, numberOfCards, cardSetId);
    }

    function editPack(uint8 packId, uint232 basePrice, uint8 numberOfCards, bool saleRunning, uint8 cardSetId) external authorizedFor(Permission.ManagePacks) {
        // require(basePrice > 0, "Price can't be 0");
        // require(numberOfCards > 0, "There have to be more than 0 cards in a pack");

        packTypes[packId].basePrice = basePrice;
        packTypes[packId].numberOfCards = numberOfCards;
        packTypes[packId].saleRunning = saleRunning;
        packTypes[packId].cardSetId = cardSetId;

        // emit PackEdited(packTypes.length - 1, basePrice, numberOfCards, saleRunning, cardSetId);
    }

    function addCardSet(uint64 mintLimit, uint64 priceIncrease, uint64 milestoneEvery) public authorizedFor(Permission.ManagePacks) {
        // require(mintLimit > 0, "Mint limit can't be 0");
        // require(milestoneEvery > 0, "Milestone distance can't be 0");

        cardSets.push(CardSet(
            0,
            mintLimit,
            priceIncrease,
            milestoneEvery
        ));

        // emit CardSetAdded(cardSets.length - 1, mintLimit, priceIncrease, milestoneEvery);
    }

    function editCardSet(uint setId, uint64 mintLimit, uint64 priceIncrease, uint64 milestoneEvery) public authorizedFor(Permission.ManagePacks) {
        // require(mintLimit > 0, "Mint limit can't be 0");
        // require(milestoneEvery > 0, "Milestone distance can't be 0");

        cardSets[setId].mintLimit = mintLimit;
        cardSets[setId].priceIncreasePerMilestone = priceIncrease;
        cardSets[setId].milestoneEvery = milestoneEvery;

        // emit CardSetEdited(setId, mintLimit, priceIncrease, milestoneEvery);
    }

    function addAttribute(string memory name, uint cost, address costToken) public authorizedFor(Permission.ManageAttributes) {
        attributes.push(Attribute(
            name,
            cost,
            costToken
        ));

        attributeIndex[name] = attributes.length - 1;
        attributeExists[name] = true;

        // emit AttributeAdded(attributes.length - 1, name, cost, costToken);
    }

    function editAttribute(uint attrId, string memory name, uint cost, address costToken) public authorizedFor(Permission.ManageAttributes) {
        Attribute memory old = attributes[attrId];

        if (compareStrings(old.name, name) == false) {
            delete attributeIndex[old.name];
            attributeIndex[name] = attrId;
        
            delete attributeExists[old.name];
            attributeExists[name] = true;
        }

        attributes[attrId].name = name;
        attributes[attrId].changeCost = cost;
        attributes[attrId].costToken = costToken;

        // emit AttributeEdited(attrId, name, cost, costToken);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setAttribute(uint cardId, string memory attribute, string memory value) public authorizedFor(Permission.ManageAttributes) {
        require(attributeExists[attribute], "Attribute doesn't exist");
        
        nftAttributes[cardId][attribute] = value;
        
        // emit AttributeChanged(cardId, attribute, value);
    }

    // function teamMintSingle(uint8 packId) external authorizedFor(Permission.Mint) {
    //     _singleMint(msg.sender, packId);
    // }

    // function teamMintSingle(uint8 packId, address recipient) external authorizedFor(Permission.Mint) {
    //     if (recipient == address(0)) recipient = msg.sender;
    //     _singleMint(recipient, packId);
    // }

    // function teamMintPack(uint8 packId) external authorizedFor(Permission.Mint) {
    //     Pack memory pack = packTypes[packId];

    //     cardSets[pack.cardSetId].minted += pack.numberOfCards;
    //     _mintCardsOfPack(msg.sender, packId, pack.numberOfCards);
    // }

    // function teamMintPack(uint8 packId, address recipient) external authorizedFor(Permission.Mint) {
    //     if (recipient == address(0)) recipient = msg.sender;
    //     Pack memory pack = packTypes[packId];
        
    //     cardSets[pack.cardSetId].minted += pack.numberOfCards;
    //     _mintCardsOfPack(recipient, packId, pack.numberOfCards);
    // }

    function teamMint(address[] memory recipients, uint8[] memory packIds) external authorizedFor(Permission.Mint) {
        require(recipients.length == packIds.length, "Not the same length.");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _singleMint(recipients[i], packIds[i]);
        }
    }

    function _singleMint(address recipient, uint8 packId) internal {
        uint mintIndex = currentIndex;
        packIdOfToken[mintIndex] = packId;
        _safeMint(recipient, mintIndex);

        cardSets[packTypes[packId].cardSetId].minted++;
        emit CardMinted(recipient, mintIndex, packId);
    }

    function withdrawFees() public payable authorizedFor(Permission.Withdraw) {
        require(rsun.transfer(msg.sender, rsun.balanceOf(address(this))), "Transfer failed");
    }
}