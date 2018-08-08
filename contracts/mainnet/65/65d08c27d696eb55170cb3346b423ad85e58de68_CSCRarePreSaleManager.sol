pragma solidity ^0.4.19;

/* Adapted from strings.sol created by Nick Johnson <<span class="__cf_email__" data-cfemail="93f2e1f2f0fbfdfaf7d3fdfce7f7fce7bdfdf6e7">[email&#160;protected]</span>>
 * Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <<span class="__cf_email__" data-cfemail="b2d3c0d3d1dadcdbd6f2dcddc6d6ddc69cdcd7c6">[email&#160;protected]</span>>
 */
library strings {
    
    struct slice {
        uint _len;
        uint _ptr;
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    
    function concat(slice self, slice other) internal returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice self, slice needle) internal returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 68 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    ptr := selfptr
                    loop:
                    jumpi(exit, eq(and(mload(ptr), mask), needledata))
                    ptr := add(ptr, 1)
                    jumpi(loop, lt(sub(ptr, 1), end))
                    ptr := add(selfptr, selflen)
                    exit:
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

     /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice self, slice needle) internal returns (slice token) {
        split(self, needle, token);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice&#39;s text.
     */
    function toString(slice self) internal pure returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

}

/* Helper String Functions for Game Manager Contract
 * @title String Healpers
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract StringHelpers {
    using strings for *;
    
    function stringToBytes32(string memory source) internal returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x) constant internal returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<span class="__cf_email__" data-cfemail="afcbcadbcaefced7c6c0c2d5cac181ccc0">[email&#160;protected]</span>> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _assetId) public view returns (address owner);
  function approve(address _to, uint256 _assetId) public;
  function transfer(address _to, uint256 _assetId) public;
  function transferFrom(address _from, address _to, uint256 _assetId) public;
  function implementsERC721() public pure returns (bool);
  function takeOwnership(uint256 _assetId) public;
  function totalSupply() public view returns (uint256 total);

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _assetId) public view returns (string infoUrl);

  // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

/* Controls game play state and access rights for game functions
 * @title Operational Control
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from contract created by OpenZeppelin
 * Ref: https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract OperationalControl {
    // Facilitates access & control for the game.
    // Roles:
    //  -The Game Managers (Primary/Secondary): Has universal control of all game elements (No ability to withdraw)
    //  -The Banker: The Bank can withdraw funds and adjust fees / prices.

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public gameManagerPrimary;
    address public gameManagerSecondary;
    address public bankManager;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // @dev Keeps track whether the contract erroredOut. When that is true, most actions are blocked & refund can be claimed
    bool public error = false;

    /// @dev Operation modifiers for limiting access
    modifier onlyGameManager() {
        require(msg.sender == gameManagerPrimary || msg.sender == gameManagerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier anyOperator() {
        require(
            msg.sender == gameManagerPrimary ||
            msg.sender == gameManagerSecondary ||
            msg.sender == bankManager
        );
        _;
    }

    /// @dev Assigns a new address to act as the GM.
    function setPrimaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerPrimary = _newGM;
    }

    /// @dev Assigns a new address to act as the GM.
    function setSecondaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerSecondary = _newGM;
    }

    /// @dev Assigns a new address to act as the Banker.
    function setBanker(address _newBK) external onlyGameManager {
        require(_newBK != address(0));

        bankManager = _newBK;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract has Error
    modifier whenError {
        require(error);
        _;
    }

    /// @dev Called by any Operator role to pause the contract.
    /// Used only if a bug or exploit is discovered (Here to limit losses / damage)
    function pause() external onlyGameManager whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function unpause() public onlyGameManager whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function hasError() public onlyGameManager whenPaused {
        error = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function noError() public onlyGameManager whenPaused {
        error = false;
    }
}

contract CSCCollectibleBase is ERC721, OperationalControl, StringHelpers {

  /*** EVENTS ***/
  /// @dev The Created event is fired whenever a new collectible comes into existence.
  event CollectibleCreated(address owner, uint256 collectibleId, bytes32 collectibleName, bool isRedeemed);
  event Transfer(address from, address to, uint256 shipId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CSCRareCollectiblePreSale";
  string public constant SYMBOL = "CSCR";
  bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
  bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256(&#39;name()&#39;)) ^
        bytes4(keccak256(&#39;symbol()&#39;)) ^
        bytes4(keccak256(&#39;totalSupply()&#39;)) ^
        bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
        bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
        bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
        bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

  /// @dev CSC Pre Sale Struct, having details of the ship
  struct RarePreSaleItem {

    /// @dev name of the collectible stored in bytes
    bytes32 collectibleName;

    /// @dev Timestamp when bought
    uint256 boughtTimestamp;

    // @dev owner address
    address owner;

    // @dev redeeme flag (to help whether it got redeemed or not)
    bool isRedeemed;
  }

  // @dev array of RarePreSaleItem type holding information on the Ships
  RarePreSaleItem[] allPreSaleItems;

  // @dev mapping which holds all the possible addresses which are allowed to interact with the contract
  mapping (address => bool) approvedAddressList;

  // @dev mapping holds the preSaleItem -> owner details
  mapping (uint256 => address) public preSaleItemIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from preSaleItem to an address that has been approved to call
  ///  transferFrom(). Each Ship can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public preSaleItemIndexToApproved;

  /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
  ///  Returns true for any standardized interfaces implemented by this contract. We implement
  ///  ERC-165 (obviously!) and ERC-721.
  function supportsInterface(bytes4 _interfaceID) external view returns (bool)
  {
      // DEBUG ONLY
      //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));
      return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _assetId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(address _to, uint256 _assetId) public {
    // Caller must own token.
    require(_owns(address(this), _assetId));
    preSaleItemIndexToApproved[_assetId] = _to;

    Approval(msg.sender, _to, _assetId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// For querying owner of token
  /// @param _assetId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _assetId) public view returns (address owner) {
    owner = preSaleItemIndexToOwner[_assetId];
    require(owner != address(0));
  }

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _assetId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _assetId) public {
    address newOwner = msg.sender;
    address oldOwner = preSaleItemIndexToOwner[_assetId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _assetId));

    _transfer(oldOwner, newOwner, _assetId);
  }

  /// @param _owner The owner whose ships tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire CSCShips array looking for emojis belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
        // Return an empty array
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalShips = totalSupply() + 1;
        uint256 resultIndex = 0;

        // We count on the fact that all CSC Ship Collectible have IDs starting at 0 and increasing
        // sequentially up to the total count.
        uint256 _assetId;

        for (_assetId = 0; _assetId < totalShips; _assetId++) {
            if (preSaleItemIndexToOwner[_assetId] == _owner) {
                result[resultIndex] = _assetId;
                resultIndex++;
            }
        }

        return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return allPreSaleItems.length - 1; //Removed 0 index
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _assetId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(address _to, uint256 _assetId) public {
    require(_addressNotNull(_to));
    require(_owns(msg.sender, _assetId));

    _transfer(msg.sender, _to, _assetId);
  }

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _assetId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(address _from, address _to, uint256 _assetId) public {
    require(_owns(_from, _assetId));
    require(_approved(_to, _assetId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _assetId);
  }

  /*** PRIVATE FUNCTIONS ***/
  /// @dev  Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) internal pure returns (bool) {
    return _to != address(0);
  }

  /// @dev  For checking approval of transfer for address _to
  function _approved(address _to, uint256 _assetId) internal view returns (bool) {
    return preSaleItemIndexToApproved[_assetId] == _to;
  }

  /// @dev For creating CSC Collectible
  function _createCollectible(bytes32 _collectibleName, address _owner) internal returns(uint256) {
    
    RarePreSaleItem memory _collectibleObj = RarePreSaleItem(
      _collectibleName,
      0,
      address(0),
      false
    );

    uint256 newCollectibleId = allPreSaleItems.push(_collectibleObj) - 1;
    
    // emit Created event
    CollectibleCreated(_owner, newCollectibleId, _collectibleName, false);
    
    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newCollectibleId);
    
    return newCollectibleId;
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _assetId) internal view returns (bool) {
    return claimant == preSaleItemIndexToOwner[_assetId];
  }

  /// @dev Assigns ownership of a specific Emoji to an address.
  function _transfer(address _from, address _to, uint256 _assetId) internal {
    // Updating the owner details of the ship
    RarePreSaleItem memory _shipObj = allPreSaleItems[_assetId];
    _shipObj.owner = _to;
    allPreSaleItems[_assetId] = _shipObj;

    // Since the number of emojis is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;

    //transfer ownership
    preSaleItemIndexToOwner[_assetId] = _to;

    // When creating new emojis _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete preSaleItemIndexToApproved[_assetId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _assetId);
  }

  /// @dev Checks if a given address currently has transferApproval for a particular RarePreSaleItem.
  /// 0 is a valid value as it will be the starter
  function _approvedFor(address _claimant, uint256 _assetId) internal view returns (bool) {
      return preSaleItemIndexToApproved[_assetId] == _claimant;
  }

  function _getCollectibleDetails (uint256 _assetId) internal view returns(RarePreSaleItem) {
    RarePreSaleItem storage _Obj = allPreSaleItems[_assetId];
    return _Obj;
  }

  /// @dev Helps in fetching the attributes of the ship depending on the ship
  /// assetId : The actual ERC721 Asset ID
  /// sequenceId : Index w.r.t Ship type
  function getShipDetails(uint256 _assetId) external view returns (
    uint256 collectibleId,
    string shipName,
    uint256 boughtTimestamp,
    address owner,
    bool isRedeemed
    ) {
    RarePreSaleItem storage _collectibleObj = allPreSaleItems[_assetId];
    collectibleId = _assetId;
    shipName = bytes32ToString(_collectibleObj.collectibleName);
    boughtTimestamp = _collectibleObj.boughtTimestamp;
    owner = _collectibleObj.owner;
    isRedeemed = _collectibleObj.isRedeemed;
  }
}

/* Lucid Sight, Inc. ERC-721 CSC Collectilbe Sale Contract. 
 * @title CSCCollectibleSale
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract CSCCollectibleSale is CSCCollectibleBase {
  event SaleWinner(address owner, uint256 collectibleId, uint256 buyingPrice);
  event CollectibleBidSuccess(address owner, uint256 collectibleId, uint256 newBidPrice, bool isActive);
  event SaleCreated(uint256 tokenID, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint64 startedAt, bool isActive, uint256 bidPrice);

  //  SHIP DATATYPES & CONSTANTS
  struct CollectibleSale {
    // Current owner of NFT (ERC721)
    address seller;
    // Price (in wei) at beginning of sale (For Buying)
    uint256 startingPrice;
    // Price (in wei) at end of sale (For Buying)
    uint256 endingPrice;
    // Duration (in seconds) of sale
    uint256 duration;
    // Time when sale started
    // NOTE: 0 if this sale has been concluded
    uint64 startedAt;

    // Flag denoting is the Sale stilla ctive
    bool isActive;

    // address of the wallet who had the maxBid
    address highestBidder;

    // address of the wallet who bought the asset
    address buyer;

    // ERC721 AssetID
    uint256 tokenId;
  }

  // @dev ship Prices & price cap
  uint256 public constant SALE_DURATION = 2592000;
  
  /// mapping holding details of the last person who had a successfull bid. used for giving back the last bid price until the asset is bought
  mapping(uint256 => address) indexToBidderAddress;
  mapping(address => mapping(uint256 => uint256)) addressToBidValue;

  // A map from assetId to the bid increment
  mapping ( uint256 => uint256 ) indexToPriceIncrement;
  /// Map from assetId to bid price
  mapping ( uint256 => uint256 ) indexToBidPrice;

  // Map from token to their corresponding sale.
  mapping (uint256 => CollectibleSale) tokenIdToSale;

  /// @dev Adds an sale to the list of open sales. Also fires the
  ///  SaleCreated event.
  function _addSale(uint256 _assetId, CollectibleSale _sale) internal {
      // Require that all sales have a duration of
      // at least one minute.
      require(_sale.duration >= 1 minutes);
      
      tokenIdToSale[_assetId] = _sale;
      indexToBidPrice[_assetId] = _sale.endingPrice;

      SaleCreated(
          uint256(_assetId),
          uint256(_sale.startingPrice),
          uint256(_sale.endingPrice),
          uint256(_sale.duration),
          uint64(_sale.startedAt),
          _sale.isActive,
          indexToBidPrice[_assetId]
      );
  }

  /// @dev Removes an sale from the list of open sales.
  /// @param _assetId - ID of the token on sale
  function _removeSale(uint256 _assetId) internal {
      delete tokenIdToSale[_assetId];
  }

  function _bid(uint256 _assetId, address _buyer, uint256 _bidAmount) internal {
    CollectibleSale storage _sale = tokenIdToSale[_assetId];
    
    require(_bidAmount >= indexToBidPrice[_assetId]);

    uint256 _newBidPrice = _bidAmount + indexToPriceIncrement[_assetId];
    indexToBidPrice[_assetId] = _newBidPrice;

    _sale.highestBidder = _buyer;
    _sale.endingPrice = _newBidPrice;

    address lastBidder = indexToBidderAddress[_assetId];
    
    if(lastBidder != address(0)){
      uint256 _value = addressToBidValue[lastBidder][_assetId];

      indexToBidderAddress[_assetId] = _buyer;

      addressToBidValue[lastBidder][_assetId] = 0;
      addressToBidValue[_buyer][_assetId] = _bidAmount;

      lastBidder.transfer(_value);
    } else {
      indexToBidderAddress[_assetId] = _buyer;
      addressToBidValue[_buyer][_assetId] = _bidAmount;
    }

    // Check that the bid is greater than or equal to the current buyOut price
    uint256 price = _currentPrice(_sale);

    if(_bidAmount >= price) {
      _sale.buyer = _buyer;
      _sale.isActive = false;

      _removeSale(_assetId);

      uint256 bidExcess = _bidAmount - price;
      _buyer.transfer(bidExcess);

      SaleWinner(_buyer, _assetId, _bidAmount);
      _transfer(address(this), _buyer, _assetId);
    } else {
      tokenIdToSale[_assetId] = _sale;

      CollectibleBidSuccess(_buyer, _assetId, _sale.endingPrice, _sale.isActive);
    }
  }

  /// @dev Returns true if the FT (ERC721) is on sale.
  function _isOnSale(CollectibleSale memory _sale) internal view returns (bool) {
      return (_sale.startedAt > 0 && _sale.isActive);
  }

  /// @dev Returns current price of a Collectible (ERC721) on sale. Broken into two
  ///  functions (this one, that computes the duration from the sale
  ///  structure, and the other that does the price computation) so we
  ///  can easily test that the price computation works correctly.
  function _currentPrice(CollectibleSale memory _sale) internal view returns (uint256) {
      uint256 secondsPassed = 0;

      // A bit of insurance against negative values (or wraparound).
      // Probably not necessary (since Ethereum guarnatees that the
      // now variable doesn&#39;t ever go backwards).
      if (now > _sale.startedAt) {
          secondsPassed = now - _sale.startedAt;
      }

      return _computeCurrentPrice(
          _sale.startingPrice,
          _sale.endingPrice,
          _sale.duration,
          secondsPassed
      );
  }

  /// @dev Computes the current price of an sale. Factored out
  ///  from _currentPrice so we can run extensive unit tests.
  ///  When testing, make this function public and turn on
  ///  `Current price computation` test suite.
  function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed) internal pure returns (uint256) {
      // NOTE: We don&#39;t use SafeMath (or similar) in this function because
      //  all of our public functions carefully cap the maximum values for
      //  time (at 64-bits) and currency (at 128-bits). _duration is
      //  also known to be non-zero (see the require() statement in
      //  _addSale())
      if (_secondsPassed >= _duration) {
          // We&#39;ve reached the end of the dynamic pricing portion
          // of the sale, just return the end price.
          return _endingPrice;
      } else {
          // Starting price can be higher than ending price (and often is!), so
          // this delta can be negative.
          int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

          // This multiplication can&#39;t overflow, _secondsPassed will easily fit within
          // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
          // will always fit within 256-bits.
          int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

          // currentPriceChange can be negative, but if so, will have a magnitude
          // less that _startingPrice. Thus, this result will always end up positive.
          int256 currentPrice = int256(_startingPrice) + currentPriceChange;

          return uint256(currentPrice);
      }
  }
  
  /// @dev Escrows the ERC721 Token, assigning ownership to this contract.
  /// Throws if the escrow fails.
  function _escrow(address _owner, uint256 _tokenId) internal {
    transferFrom(_owner, this, _tokenId);
  }

  function getBuyPrice(uint256 _assetId) external view returns(uint256 _price){
    CollectibleSale memory _sale = tokenIdToSale[_assetId];
    
    return _currentPrice(_sale);
  }
  
  function getBidPrice(uint256 _assetId) external view returns(uint256 _price){
    return indexToBidPrice[_assetId];
  }

  /// @dev Creates and begins a new sale.
  function _createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) internal {
      // Sanity check that no inputs overflow how many bits we&#39;ve allocated
      // to store them in the sale struct.
      require(_startingPrice == uint256(uint128(_startingPrice)));
      require(_endingPrice == uint256(uint128(_endingPrice)));
      require(_duration == uint256(uint64(_duration)));

      CollectibleSale memory sale = CollectibleSale(
          _seller,
          uint128(_startingPrice),
          uint128(_endingPrice),
          uint64(_duration),
          uint64(now),
          true,
          address(this),
          address(this),
          uint256(_tokenId)
      );
      _addSale(_tokenId, sale);
  }

  function _buy(uint256 _assetId, address _buyer, uint256 _price) internal {

    CollectibleSale storage _sale = tokenIdToSale[_assetId];
    address lastBidder = indexToBidderAddress[_assetId];
    
    if(lastBidder != address(0)){
      uint256 _value = addressToBidValue[lastBidder][_assetId];

      indexToBidderAddress[_assetId] = _buyer;

      addressToBidValue[lastBidder][_assetId] = 0;
      addressToBidValue[_buyer][_assetId] = _price;

      lastBidder.transfer(_value);
    }

    // Check that the bid is greater than or equal to the current buyOut price
    uint256 currentPrice = _currentPrice(_sale);

    require(_price >= currentPrice);
    _sale.buyer = _buyer;
    _sale.isActive = false;

    _removeSale(_assetId);

    uint256 bidExcess = _price - currentPrice;
    _buyer.transfer(bidExcess);

    SaleWinner(_buyer, _assetId, _price);
    _transfer(address(this), _buyer, _assetId);
  }

  /// @dev Returns sales info for an CSLCollectibles (ERC721) on sale.
  /// @param _assetId - ID of the token on sale
  function getSale(uint256 _assetId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, bool isActive, address owner, address highestBidder) {
      CollectibleSale memory sale = tokenIdToSale[_assetId];
      require(_isOnSale(sale));
      return (
          sale.seller,
          sale.startingPrice,
          sale.endingPrice,
          sale.duration,
          sale.startedAt,
          sale.isActive,
          sale.buyer,
          sale.highestBidder
      );
  }
}

/* Lucid Sight, Inc. ERC-721 Collectibles. 
 * @title LSNFT - Lucid Sight, Inc. Non-Fungible Token
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract CSCRarePreSaleManager is CSCCollectibleSale {
  event RefundClaimed(address owner);

  bool CSCPreSaleInit = false;

  /// @dev Constructor creates a reference to the NFT (ERC721) ownership contract
  function CSCRarePreSaleManager() public {
      require(msg.sender != address(0));
      paused = true;
      error = false;
      gameManagerPrimary = msg.sender;
  }

  function addToApprovedAddress (address _newAddr) onlyGameManager {
    require(_newAddr != address(0));
    require(!approvedAddressList[_newAddr]);
    approvedAddressList[_newAddr] = true;
  }

  function removeFromApprovedAddress (address _newAddr) onlyGameManager {
    require(_newAddr != address(0));
    require(approvedAddressList[_newAddr]);
    approvedAddressList[_newAddr] = false;
  }

  function createPreSaleShip(string collectibleName, uint256 startingPrice, uint256 bidPrice) whenNotPaused returns (uint256){
    require(approvedAddressList[msg.sender] || msg.sender == gameManagerPrimary || msg.sender == gameManagerSecondary);
    
    uint256 assetId = _createCollectible(stringToBytes32(collectibleName), address(this));

    indexToPriceIncrement[assetId] = bidPrice;

    _createSale(assetId, startingPrice, bidPrice, uint64(SALE_DURATION), address(this));
  }

  function() external payable {
  }

  /// @dev Bid Function which call the interncal bid function
  /// after doing all the pre-checks required to initiate a bid
  function bid(uint256 _assetId) external whenNotPaused payable {
    require(msg.sender != address(0));
    require(msg.sender != address(this));
    CollectibleSale memory _sale = tokenIdToSale[_assetId];
    require(_isOnSale(_sale));
    
    address seller = _sale.seller;

    _bid(_assetId, msg.sender, msg.value);
  }

  /// @dev BuyNow Function which call the interncal buy function
  /// after doing all the pre-checks required to initiate a buy
  function buyNow(uint256 _assetId) external whenNotPaused payable {
    require(msg.sender != address(0));
    require(msg.sender != address(this));
    CollectibleSale memory _sale = tokenIdToSale[_assetId];
    require(_isOnSale(_sale));
    
    address seller = _sale.seller;

    _buy(_assetId, msg.sender, msg.value);
  }

  /// @dev Override unpause so it requires all external contract addresses
  ///  to be set before contract can be unpaused. Also, we can&#39;t have
  ///  newContractAddress set either, because then the contract was upgraded.
  /// @notice This is public rather than external so we can call super.unpause
  ///  without using an expensive CALL.
  function unpause() public onlyGameManager whenPaused {
      // Actually unpause the contract.
      super.unpause();
  }

  /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
  ///  as well as any Ether sent directly to the contract address.
  ///  Always transfers to the NFT (ERC721) contract, but can be called either by
  ///  the owner or the NFT (ERC721) contract.
  function withdrawBalance() onlyBanker {
      // We are using this boolean method to make sure that even if one fails it will still work
      bankManager.transfer(this.balance);
  }
  
  function preSaleInit() onlyGameManager {
    require(!CSCPreSaleInit);
    require(allPreSaleItems.length == 0);
      
    CSCPreSaleInit = true;

    bytes32[6] memory attributes = [bytes32(999), bytes32(999), bytes32(999), bytes32(999), bytes32(999), bytes32(999)];
    //Fill in index 0 to null requests
    RarePreSaleItem memory _Obj = RarePreSaleItem(stringToBytes32("Dummy"), 0, address(this), true);
    allPreSaleItems.push(_Obj);
  } 
}