pragma solidity ^0.4.19;

/* Adapted from strings.sol created by Nick Johnson <<span class="__cf_email__" data-cfemail="bedfccdfddd6d0d7dafed0d1cadad1ca90">[email&#160;protected]</span>net>
 * Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <<span class="__cf_email__" data-cfemail="f190839092999f9895b19f9e85959e85df9f9485">[email&#160;protected]</span>>
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
/// @author Dieter Shirley <<span class="__cf_email__" data-cfemail="7c181908193c1d04151311061912521f13">[email&#160;protected]</span>> (https://github.com/dete)
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
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);

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
  event CollectibleCreated(address owner, uint256 globalId, uint256 collectibleType, uint256 collectibleClass, uint256 sequenceId, bytes32 collectibleName, bool isRedeemed);
  event Transfer(address from, address to, uint256 shipId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CSCPreSaleShip";
  string public constant SYMBOL = "CSC";
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
  struct CSCPreSaleItem {

    /// @dev asset ID i..e Local Index
    uint256 assetId;

    /// @dev name of the collectible stored in bytes
    bytes32 collectibleName;

    /// @dev Timestamp when bought
    uint256 boughtTimestamp;

    /// @dev Collectible Types (Voucher/Ship)
    /// can be 0 - Voucher, 1 - Ship
    uint256 collectibleType;

    /// @dev Collectible Class (1 - Prometheus, 2 - Crosair, 3 - Intrepid)
    uint256 collectibleClass;

    // @dev owner address
    address owner;

    // @dev redeeme flag (to help whether it got redeemed or not)
    bool isRedeemed;
  }
  
  // @dev Mapping containing the reference to all CSC PreSaleItem
  //mapping (uint256 => CSCPreSaleItem[]) public indexToPreSaleItem;

  // @dev array of CSCPreSaleItem type holding information on the Ships
  CSCPreSaleItem[] allPreSaleItems;

  // Max Count for Voucher(s), Prometheus, Crosair & Intrepid Ships
  uint256 public constant PROMETHEUS_SHIP_LIMIT = 300;
  uint256 public constant INTREPID_SHIP_LIMIT = 1500;
  uint256 public constant CROSAIR_SHIP_LIMIT = 600;
  uint256 public constant PROMETHEUS_VOUCHER_LIMIT = 100;
  uint256 public constant INTREPID_VOUCHER_LIMIT = 300;
  uint256 public constant CROSAIR_VOUCHER_LIMIT = 200;

  // Variable to keep a count of Prometheus/Intrepid/Crosair Minted
  uint256 public prometheusShipMinted;
  uint256 public intrepidShipMinted;
  uint256 public crosairShipMinted;
  uint256 public prometheusVouchersMinted;
  uint256 public intrepidVouchersMinted;
  uint256 public crosairVouchersMinted;

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

  /// @dev A mapping of preSaleItem Type to Type Sequence Number to Collectible
  /// 0 - Voucher
  /// 1 - Prometheus
  /// 2 - Crosair
  /// 3 - Intrepid
  mapping (uint256 => mapping (uint256 => mapping ( uint256 => uint256 ) ) ) public preSaleItemTypeToSequenceIdToCollectible;

  /// @dev A mapping from Pre Sale Item Type IDs to the Sequqence Number .
  /// 0 - Voucher
  /// 1 - Prometheus
  /// 2 - Crosair
  /// 3 - Intrepid
  mapping (uint256 => mapping ( uint256 => uint256 ) ) public preSaleItemTypeToCollectibleCount;

  /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
  ///  Returns true for any standardized interfaces implemented by this contract. We implement
  ///  ERC-165 (obviously!) and ERC-721.
  function supportsInterface(bytes4 _interfaceID) external view returns (bool)
  {
      // DEBUG ONLY
      //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));
      return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  function getCollectibleDetails(uint256 _assetId) external view returns(uint256 assetId, uint256 sequenceId, uint256 collectibleType, uint256 collectibleClass, bool isRedeemed, address owner) {
    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    assetId = _assetId;
    sequenceId = _Obj.assetId;
    collectibleType = _Obj.collectibleType;
    collectibleClass = _Obj.collectibleClass;
    owner = _Obj.owner;
    isRedeemed = _Obj.isRedeemed;
  }
  
  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _assetId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(address _to, uint256 _assetId) public {
    // Caller must own token.
    require(_owns(msg.sender, _assetId));
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
  function _createCollectible(bytes32 _collectibleName, uint256 _collectibleType, uint256 _collectibleClass) internal returns(uint256) {
    uint256 _sequenceId = uint256(preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass]) + 1;

    // These requires are not strictly necessary, our calling code should make
    // sure that these conditions are never broken.
    require(_sequenceId == uint256(uint32(_sequenceId)));
    
    CSCPreSaleItem memory _collectibleObj = CSCPreSaleItem(
      _sequenceId,
      _collectibleName,
      0,
      _collectibleType,
      _collectibleClass,
      address(0),
      false
    );

    uint256 newCollectibleId = allPreSaleItems.push(_collectibleObj) - 1;
    
    preSaleItemTypeToSequenceIdToCollectible[_collectibleType][_collectibleClass][_sequenceId] = newCollectibleId;
    preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] = _sequenceId;

    // emit Created event
    // CollectibleCreated(address owner, uint256 globalId, uint256 collectibleType, uint256 collectibleClass, uint256 sequenceId, bytes32[6] attributes, bool isRedeemed);
    CollectibleCreated(address(this), newCollectibleId, _collectibleType, _collectibleClass, _sequenceId, _collectibleObj.collectibleName, false);
    
    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), address(this), newCollectibleId);
    
    return newCollectibleId;
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _assetId) internal view returns (bool) {
    return claimant == preSaleItemIndexToOwner[_assetId];
  }

  /// @dev Assigns ownership of a specific Emoji to an address.
  function _transfer(address _from, address _to, uint256 _assetId) internal {
    // Updating the owner details of the ship
    CSCPreSaleItem memory _shipObj = allPreSaleItems[_assetId];
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

  /// @dev Checks if a given address currently has transferApproval for a particular CSCPreSaleItem.
  /// 0 is a valid value as it will be the starter
  function _approvedFor(address _claimant, uint256 _assetId) internal view returns (bool) {
      return preSaleItemIndexToApproved[_assetId] == _claimant;
  }

  function _getCollectibleDetails (uint256 _assetId) internal view returns(CSCPreSaleItem) {
    CSCPreSaleItem storage _Obj = allPreSaleItems[_assetId];
    return _Obj;
  }

  /// @dev Helps in fetching the attributes of the ship depending on the ship
  /// assetId : The actual ERC721 Asset ID
  /// sequenceId : Index w.r.t Ship type
  function getShipDetails(uint256 _sequenceId, uint256 _shipClass) external view returns (
    uint256 assetId,
    uint256 sequenceId,
    string shipName,
    uint256 collectibleClass,
    uint256 boughtTimestamp,
    address owner
    ) {  
    uint256 _assetId = preSaleItemTypeToSequenceIdToCollectible[1][_shipClass][_sequenceId];

    CSCPreSaleItem storage _collectibleObj = allPreSaleItems[_assetId];
    require(_collectibleObj.collectibleType == 1);

    assetId = _assetId;
    sequenceId = _sequenceId;
    shipName = bytes32ToString(_collectibleObj.collectibleName);
    collectibleClass = _collectibleObj.collectibleClass;
    boughtTimestamp = _collectibleObj.boughtTimestamp;
    owner = _collectibleObj.owner;
  }

  /// @dev Helps in fetching information regarding a Voucher
  /// assetId : The actual ERC721 Asset ID
  /// sequenceId : Index w.r.t Voucher Type
  function getVoucherDetails(uint256 _sequenceId, uint256 _voucherClass) external view returns (
    uint256 assetId,
    uint256 sequenceId,
    uint256 boughtTimestamp,
    uint256 voucherClass,
    address owner
    ) {
    uint256 _assetId = preSaleItemTypeToSequenceIdToCollectible[0][_voucherClass][_sequenceId];

    CSCPreSaleItem storage _collectibleObj = allPreSaleItems[_assetId];
    require(_collectibleObj.collectibleType == 0);

    assetId = _assetId;
    sequenceId = _sequenceId;
    boughtTimestamp = _collectibleObj.boughtTimestamp;
    voucherClass = _collectibleObj.collectibleClass;
    owner = _collectibleObj.owner;
  }

  function _isActive(uint256 _assetId) internal returns(bool) {
    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    return (_Obj.boughtTimestamp == 0);
  }
}

/* Lucid Sight, Inc. ERC-721 CSC Collectilbe Sale Contract. 
 * @title CSCCollectibleSale
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract CSCCollectibleSale is CSCCollectibleBase {
  event CollectibleBought (uint256 _assetId, address owner);
  event PriceUpdated (uint256 collectibleClass, uint256 newPrice, uint256 oldPrice);

  //  SHIP DATATYPES & CONSTANTS
  // @dev ship Prices & price cap
  uint256 public PROMETHEUS_SHIP_PRICE = 0.25 ether;
  uint256 public INTREPID_SHIP_PRICE = 0.005 ether;
  uint256 public CROSAIR_SHIP_PRICE = 0.1 ether;

  uint256 public constant PROMETHEUS_MAX_PRICE = 0.85 ether;
  uint256 public constant INTREPID_MAX_PRICE = 0.25 ether;
  uint256 public constant CROSAIR_MAX_PRICE = 0.5 ether;

  uint256 public constant PROMETHEUS_PRICE_INCREMENT = 0.05 ether;
  uint256 public constant INTREPID_PRICE_INCREMENT = 0.002 ether;
  uint256 public constant CROSAIR_PRICE_INCREMENT = 0.01 ether;

  uint256 public constant PROMETHEUS_PRICE_THRESHOLD = 0.85 ether;
  uint256 public constant INTREPID_PRICE_THRESHOLD = 0.25 ether;
  uint256 public constant CROSAIR_PRICE_THRESHOLD = 0.5 ether;

  uint256 public prometheusSoldCount;
  uint256 public intrepidSoldCount;
  uint256 public crosairSoldCount;

  //  VOUCHER DATATYPES & CONSTANTS
  uint256 public PROMETHEUS_VOUCHER_PRICE = 0.75 ether;
  uint256 public INTREPID_VOUCHER_PRICE = 0.2 ether;
  uint256 public CROSAIR_VOUCHER_PRICE = 0.35 ether;

  uint256 public prometheusVoucherSoldCount;
  uint256 public crosairVoucherSoldCount;
  uint256 public intrepidVoucherSoldCount;
  
  /// @dev Mapping created store the amount of value a wallet address used to buy assets
  mapping(address => uint256) addressToValue;

  /// @dev Mapping to holde the balance of each address, i.e. addrs -> collectibleType -> collectibleClass -> balance
  mapping(address => mapping(uint256 => mapping (uint256 => uint256))) addressToCollectibleTypeBalance;

  function _bid(uint256 _assetId, uint256 _price,uint256 _collectibleType,uint256 _collectibleClass, address _buyer) internal {
    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];

    if(_collectibleType == 1 && _collectibleClass == 1) {
      require(_price == PROMETHEUS_SHIP_PRICE);
      _Obj.owner = _buyer;
      _Obj.boughtTimestamp = now;

      addressToValue[_buyer] += _price;

      prometheusSoldCount++;
      if(prometheusSoldCount % 10 == 0){
        if(PROMETHEUS_SHIP_PRICE < PROMETHEUS_PRICE_THRESHOLD){
          PROMETHEUS_SHIP_PRICE +=  PROMETHEUS_PRICE_INCREMENT;
        }
      }
    }

    if(_collectibleType == 1 && _collectibleClass == 2) {
      require(_price == CROSAIR_SHIP_PRICE);
      _Obj.owner = _buyer;
      _Obj.boughtTimestamp = now;

      addressToValue[_buyer] += _price;

      crosairSoldCount++;
      if(crosairSoldCount % 10 == 0){
        if(CROSAIR_SHIP_PRICE < CROSAIR_PRICE_THRESHOLD){
          CROSAIR_SHIP_PRICE += CROSAIR_PRICE_INCREMENT;
        }
      }
    }

    if(_collectibleType == 1 && _collectibleClass == 3) {
      require(_price == INTREPID_SHIP_PRICE);
      _Obj.owner = _buyer;
      _Obj.boughtTimestamp = now;

      addressToValue[_buyer] += _price;

      intrepidSoldCount++;
      if(intrepidSoldCount % 10 == 0){
        if(INTREPID_SHIP_PRICE < INTREPID_PRICE_THRESHOLD){
          INTREPID_SHIP_PRICE += INTREPID_PRICE_INCREMENT;
        }
      }
    }

    if(_collectibleType == 0 &&_collectibleClass == 1) {
        require(_price == PROMETHEUS_VOUCHER_PRICE);
        _Obj.owner = _buyer;
        _Obj.boughtTimestamp = now;

        addressToValue[_buyer] += _price;

        prometheusVoucherSoldCount++;
      }

      if(_collectibleType == 0 && _collectibleClass == 2) {
        require(_price == CROSAIR_VOUCHER_PRICE);
        _Obj.owner = _buyer;
        _Obj.boughtTimestamp = now;

        addressToValue[_buyer] += _price;

        crosairVoucherSoldCount++;
      }
      
      if(_collectibleType == 0 && _collectibleClass == 3) {
        require(_price == INTREPID_VOUCHER_PRICE);
        _Obj.owner = _buyer;
        _Obj.boughtTimestamp = now;

        addressToValue[_buyer] += _price;

        intrepidVoucherSoldCount++;
      }

    addressToCollectibleTypeBalance[_buyer][_collectibleType][_collectibleClass]++;

    CollectibleBought(_assetId, _buyer);
  }

  function getCollectibleTypeBalance(address _owner, uint256 _collectibleType, uint256 _collectibleClass) external view returns(uint256) {
    require(_owner != address(0));
    return addressToCollectibleTypeBalance[_owner][_collectibleType][_collectibleClass];
  }

  function getCollectiblePrice(uint256 _collectibleType, uint256 _collectibleClass) external view returns(uint256 _price){

    // For Ships
    if(_collectibleType == 1 && _collectibleClass == 1) {
      return PROMETHEUS_SHIP_PRICE;
    }

    if(_collectibleType == 1 && _collectibleClass == 2) {
      return CROSAIR_SHIP_PRICE;
    }

    if(_collectibleType == 1 && _collectibleClass == 3) {
      return INTREPID_SHIP_PRICE;
    }

    // For Vouchers
    if(_collectibleType == 0 && _collectibleClass == 1) {
      return PROMETHEUS_VOUCHER_PRICE;
    }

    if(_collectibleType == 0 && _collectibleClass == 2) {
      return CROSAIR_VOUCHER_PRICE;
    }

    if(_collectibleType == 0 && _collectibleClass == 3) {
      return INTREPID_VOUCHER_PRICE;
    }
  }
}

/* Lucid Sight, Inc. ERC-721 Collectibles. 
 * @title LSNFT - Lucid Sight, Inc. Non-Fungible Token
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract CSCPreSaleManager is CSCCollectibleSale {
  event RefundClaimed(address owner, uint256 refundValue);

  // Ship Names
  string private constant prometheusShipName = "Vulcan Harvester";
  string private constant crosairShipName = "Phoenix Cruiser";
  string private constant intrepidShipName = "Reaper Interceptor";

  bool CSCPreSaleInit = false;

  /// @dev Constructor creates a reference to the NFT (ERC721) ownership contract
  function CSCPreSaleManager() public {
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

  function() external payable {
  }

  /// @dev Bid Function which call the interncal bid function
  /// after doing all the pre-checks required to initiate a bid
  function bid(uint256 _collectibleType, uint256 _collectibleClass) external payable {
    require(msg.sender != address(0));
    require(msg.sender != address(this));

    require(_collectibleType >= 0 && _collectibleType <= 1);

    require(_isActive(_assetId));

    bytes32 collectibleName;

    if(_collectibleType == 0){
      collectibleName = bytes32("NoNameForVoucher");
      if(_collectibleClass == 1){
        require(prometheusVouchersMinted < PROMETHEUS_VOUCHER_LIMIT);
        collectibleName = stringToBytes32(prometheusShipName);
        prometheusVouchersMinted++;
      }
      
      if(_collectibleClass == 2){
        require(crosairVouchersMinted < CROSAIR_VOUCHER_LIMIT);
        crosairVouchersMinted++;
      }

      if(_collectibleClass == 3){
        require(intrepidVoucherSoldCount < INTREPID_VOUCHER_LIMIT);
        intrepidVouchersMinted++;
      }
    }

    if(_collectibleType == 1){
      if(_collectibleClass == 1){
        require(prometheusShipMinted < PROMETHEUS_SHIP_LIMIT);
        collectibleName = stringToBytes32(prometheusShipName);
        prometheusShipMinted++;
      }
      
      if(_collectibleClass == 2){
        require(crosairShipMinted < CROSAIR_VOUCHER_LIMIT);
        collectibleName = stringToBytes32(crosairShipName);
        crosairShipMinted++;
      }

      if(_collectibleClass == 3){
        require(intrepidShipMinted < INTREPID_SHIP_LIMIT);
        collectibleName = stringToBytes32(intrepidShipName);
        intrepidShipMinted++;
      }
    }

    uint256 _assetId = _createCollectible(collectibleName, _collectibleType, _collectibleClass); 

    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];

    _bid(_assetId, msg.value, _Obj.collectibleType, _Obj.collectibleClass, msg.sender);
    
    _transfer(address(this), msg.sender, _assetId);
  }

  /// @dev Bid Function which call the interncal bid function
  /// after doing all the pre-checks required to initiate a bid
  function createReferralGiveAways(uint256 _collectibleType, uint256 _collectibleClass, address _toAddress) onlyGameManager external {
    require(msg.sender != address(0));
    require(msg.sender != address(this));

    require(_collectibleType >= 0 && _collectibleType <= 1);

    bytes32 collectibleName;

    if(_collectibleType == 0){
      collectibleName = bytes32("ReferralGiveAwayVoucher");
      if(_collectibleClass == 1){
        collectibleName = stringToBytes32(prometheusShipName);
      }
      
      if(_collectibleClass == 2){
        crosairVouchersMinted++;
      }

      if(_collectibleClass == 3){
        intrepidVouchersMinted++;
      }
    }

    if(_collectibleType == 1){
      if(_collectibleClass == 1){
        collectibleName = stringToBytes32(prometheusShipName);
      }
      
      if(_collectibleClass == 2){
        collectibleName = stringToBytes32(crosairShipName);
      }

      if(_collectibleClass == 3){
        collectibleName = stringToBytes32(intrepidShipName);
      }
    }

    uint256 _assetId = _createCollectible(collectibleName, _collectibleType, _collectibleClass); 

    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    
    _transfer(address(this), _toAddress, _assetId);
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

  function claimRefund(address _ownerAddress) whenError {
    uint256 refundValue = addressToValue[_ownerAddress];
    addressToValue[_ownerAddress] = 0;

    _ownerAddress.transfer(refundValue);
    RefundClaimed(_ownerAddress, refundValue);
  }
  
  function preSaleInit() onlyGameManager {
    require(!CSCPreSaleInit);
    require(allPreSaleItems.length == 0);
      
    CSCPreSaleInit = true;

    //Fill in index 0 to null requests
    CSCPreSaleItem memory _Obj = CSCPreSaleItem(0, stringToBytes32("DummyAsset"), 0, 0, 0, address(this), true);
    allPreSaleItems.push(_Obj);
  }

  function isRedeemed(uint256 _assetId) {
    require(approvedAddressList[msg.sender]);

    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    _Obj.isRedeemed = true;

    allPreSaleItems[_assetId] = _Obj;
  }
}