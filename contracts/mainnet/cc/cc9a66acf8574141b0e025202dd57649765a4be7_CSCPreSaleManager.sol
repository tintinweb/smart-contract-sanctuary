pragma solidity ^0.4.19;

/* Adapted from strings.sol created by Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="43223122202b2d2a27032d2c37272c376d2d2637">[email&#160;protected]</a>>
 * Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="83e2f1e2e0ebedeae7c3edecf7e7ecf7adede6f7">[email&#160;protected]</a>>
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
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="debabbaabb9ebfa6b7b1b3a4bbb0f0bdb1">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address owner);
  function approve(address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function implementsERC721() public pure returns (bool);
  function takeOwnership(uint256 _tokenId) public;
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

/* Controls state and access rights for contract functions
 * @title Operational Control
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from contract created by OpenZeppelin
 * Ref: https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract OperationalControl {
    // Facilitates access & control for the game.
    // Roles:
    //  -The Managers (Primary/Secondary): Has universal control of all elements (No ability to withdraw)
    //  -The Banker: The Bank can withdraw funds and adjust fees / prices.

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // @dev Keeps track whether the contract erroredOut. When that is true, most actions are blocked & refund can be claimed
    bool public error = false;

    /// @dev Operation modifiers for limiting access
    modifier onlyManager() {
        require(msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager
        );
        _;
    }

    /// @dev Assigns a new address to act as the Primary Manager.
    function setPrimaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerPrimary = _newGM;
    }

    /// @dev Assigns a new address to act as the Secondary Manager.
    function setSecondaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerSecondary = _newGM;
    }

    /// @dev Assigns a new address to act as the Banker.
    function setBanker(address _newBK) external onlyManager {
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
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function unpause() public onlyManager whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function hasError() public onlyManager whenPaused {
        error = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function noError() public onlyManager whenPaused {
        error = false;
    }
}

contract CSCPreSaleItemBase is ERC721, OperationalControl, StringHelpers {

    /*** EVENTS ***/
    /// @dev The Created event is fired whenever a new collectible comes into existence.
    event CollectibleCreated(address owner, uint256 globalId, uint256 collectibleType, uint256 collectibleClass, uint256 sequenceId, bytes32 collectibleName);
    
    /*** CONSTANTS ***/
    
    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant NAME = "CSCPreSaleFactory";
    string public constant SYMBOL = "CSCPF";
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
    
    /// @dev CSC Pre Sale Struct, having details of the collectible
    struct CSCPreSaleItem {
    
        /// @dev sequence ID i..e Local Index
        uint256 sequenceId;
        
        /// @dev name of the collectible stored in bytes
        bytes32 collectibleName;
        
        /// @dev Collectible Type
        uint256 collectibleType;
        
        /// @dev Collectible Class
        uint256 collectibleClass;
        
        /// @dev owner address
        address owner;
        
        /// @dev redeemed flag (to help whether it got redeemed or not)
        bool isRedeemed;
    }
    
    /// @dev array of CSCPreSaleItem type holding information on the Collectibles Created
    CSCPreSaleItem[] allPreSaleItems;
    
    /// @dev Max Count for preSaleItem type -> preSaleItem class -> max. limit
    mapping(uint256 => mapping(uint256 => uint256)) public preSaleItemTypeToClassToMaxLimit;
    
    /// @dev Map from preSaleItem type -> preSaleItem class -> max. limit set (bool)
    mapping(uint256 => mapping(uint256 => bool)) public preSaleItemTypeToClassToMaxLimitSet;

    /// @dev Map from preSaleItem type -> preSaleItem class -> Name (string / bytes32)
    mapping(uint256 => mapping(uint256 => bytes32)) public preSaleItemTypeToClassToName;
    
    // @dev mapping which holds all the possible addresses which are allowed to interact with the contract
    mapping (address => bool) approvedAddressList;
    
    // @dev mapping holds the preSaleItem -> owner details
    mapping (uint256 => address) public preSaleItemIndexToOwner;
    
    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) private ownershipTokenCount;
    
    /// @dev A mapping from preSaleItem to an address that has been approved to call
    ///  transferFrom(). Each Collectible can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public preSaleItemIndexToApproved;
    
    /// @dev A mapping of preSaleItem Type to Type Sequence Number to Collectible
    mapping (uint256 => mapping (uint256 => mapping ( uint256 => uint256 ) ) ) public preSaleItemTypeToSequenceIdToCollectible;
    
    /// @dev A mapping from Pre Sale Item Type IDs to the Sequqence Number .
    mapping (uint256 => mapping ( uint256 => uint256 ) ) public preSaleItemTypeToCollectibleCount;

    /// @dev Token Starting Index taking into account the old presaleContract total assets that can be generated
    uint256 public STARTING_ASSET_BASE = 3000;
    
    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
    function setMaxLimit(string _collectibleName, uint256 _collectibleType, uint256 _collectibleClass, uint256 _maxLimit) external onlyManager whenNotPaused {
        require(_maxLimit > 0);
        require(_collectibleType >= 0 && _collectibleClass >= 0);
        require(stringToBytes32(_collectibleName) != stringToBytes32(""));

        require(!preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass]);
        preSaleItemTypeToClassToMaxLimit[_collectibleType][_collectibleClass] = _maxLimit;
        preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass] = true;
        preSaleItemTypeToClassToName[_collectibleType][_collectibleClass] = stringToBytes32(_collectibleName);
    }
    
    /// @dev Method to fetch collectible details
    function getCollectibleDetails(uint256 _tokenId) external view returns(uint256 assetId, uint256 sequenceId, uint256 collectibleType, uint256 collectibleClass, string collectibleName, bool isRedeemed, address owner) {

        require (_tokenId > STARTING_ASSET_BASE);
        uint256 generatedCollectibleId = _tokenId - STARTING_ASSET_BASE;
        
        CSCPreSaleItem memory _Obj = allPreSaleItems[generatedCollectibleId];
        assetId = _tokenId;
        sequenceId = _Obj.sequenceId;
        collectibleType = _Obj.collectibleType;
        collectibleClass = _Obj.collectibleClass;
        collectibleName = bytes32ToString(_Obj.collectibleName);
        owner = _Obj.owner;
        isRedeemed = _Obj.isRedeemed;
    }
    
    /*** PUBLIC FUNCTIONS ***/
    /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) public {
        // Caller must own token.
        require (_tokenId > STARTING_ASSET_BASE);
        
        require(_owns(msg.sender, _tokenId));
        preSaleItemIndexToApproved[_tokenId] = _to;
        
        Approval(msg.sender, _to, _tokenId);
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
    /// @param _tokenId The tokenID for owner inquiry
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        require (_tokenId > STARTING_ASSET_BASE);

        owner = preSaleItemIndexToOwner[_tokenId];
        require(owner != address(0));
    }
    
    /// @dev Required for ERC-721 compliance.
    function symbol() public pure returns (string) {
        return SYMBOL;
    }
    
    /// @notice Allow pre-approved user to take ownership of a token
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public {
        require (_tokenId > STARTING_ASSET_BASE);

        address newOwner = msg.sender;
        address oldOwner = preSaleItemIndexToOwner[_tokenId];
        
        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));
        
        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));
        
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
    /// @param _owner The owner whose collectibles tokens we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire CSCPreSaleItem array looking for collectibles belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCount = totalSupply() + 1 + STARTING_ASSET_BASE;
            uint256 resultIndex = 0;
        
            // We count on the fact that all LS PreSaleItems have IDs starting at 0 and increasing
            // sequentially up to the total count.
            uint256 _tokenId;
        
            for (_tokenId = STARTING_ASSET_BASE; _tokenId < totalCount; _tokenId++) {
                if (preSaleItemIndexToOwner[_tokenId] == _owner) {
                    result[resultIndex] = _tokenId;
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
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) public {

        require (_tokenId > STARTING_ASSET_BASE);
        
        require(_addressNotNull(_to));
        require(_owns(msg.sender, _tokenId));
        
        _transfer(msg.sender, _to, _tokenId);
    }
    
    /// Third-party initiates transfer of token from address _from to address _to
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require (_tokenId > STARTING_ASSET_BASE);

        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
        
        _transfer(_from, _to, _tokenId);
    }
    
    /*** PRIVATE FUNCTIONS ***/
    /// @dev  Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) internal pure returns (bool) {
        return _to != address(0);
    }
    
    /// @dev  For checking approval of transfer for address _to
    function _approved(address _to, uint256 _tokenId) internal view returns (bool) {
        return preSaleItemIndexToApproved[_tokenId] == _to;
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
          _collectibleType,
          _collectibleClass,
          address(0),
          false
        );
        
        uint256 generatedCollectibleId = allPreSaleItems.push(_collectibleObj) - 1;
        uint256 collectibleIndex = generatedCollectibleId + STARTING_ASSET_BASE;
        
        preSaleItemTypeToSequenceIdToCollectible[_collectibleType][_collectibleClass][_sequenceId] = collectibleIndex;
        preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] = _sequenceId;
        
        // emit Created event
        // CollectibleCreated(address owner, uint256 globalId, uint256 collectibleType, uint256 collectibleClass, uint256 sequenceId, bytes32 collectibleName);
        CollectibleCreated(address(this), collectibleIndex, _collectibleType, _collectibleClass, _sequenceId, _collectibleObj.collectibleName);
        
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), address(this), collectibleIndex);
        
        return collectibleIndex;
    }
    
    /// @dev Check for token ownership
    function _owns(address claimant, uint256 _tokenId) internal view returns (bool) {
        return claimant == preSaleItemIndexToOwner[_tokenId];
    }
    
    /// @dev Assigns ownership of a specific preSaleItem to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        uint256 generatedCollectibleId = _tokenId - STARTING_ASSET_BASE;

        // Updating the owner details of the collectible
        CSCPreSaleItem memory _Obj = allPreSaleItems[generatedCollectibleId];
        _Obj.owner = _to;
        allPreSaleItems[generatedCollectibleId] = _Obj;
        
        // Since the number of preSaleItem is capped to 2^32 we can&#39;t overflow this
        ownershipTokenCount[_to]++;
        
        //transfer ownership
        preSaleItemIndexToOwner[_tokenId] = _to;
        
        // When creating new collectibles _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
          ownershipTokenCount[_from]--;
          // clear any previously approved ownership exchange
          delete preSaleItemIndexToApproved[_tokenId];
        }
        
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }
    
    /// @dev Checks if a given address currently has transferApproval for a particular CSCPreSaleItem.
    /// 0 is a valid value as it will be the starter
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        require(_tokenId > STARTING_ASSET_BASE);

        return preSaleItemIndexToApproved[_tokenId] == _claimant;
    }
}

/* Lucid Sight, Inc. ERC-721 Collectibles Manager. 
 * @title LSPreSaleManager - Lucid Sight, Inc. Non-Fungible Token
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract CSCPreSaleManager is CSCPreSaleItemBase {

    event RefundClaimed(address owner, uint256 refundValue);

    /// @dev defines if preSaleItem type -> preSaleItem class -> Vending Machine to set limit (bool)
    mapping(uint256 => mapping(uint256 => bool)) public preSaleItemTypeToClassToCanBeVendingMachine;

    /// @dev defines if preSaleItem type -> preSaleItem class -> Vending Machine Fee
    mapping(uint256 => mapping(uint256 => uint256)) public preSaleItemTypeToClassToVendingFee;

    /// @dev Mapping created store the amount of value a wallet address used to buy assets
    mapping(address => uint256) public addressToValue;
    
    bool CSCPreSaleInit = false;
    /// @dev Constructor creates a reference to the NFT (ERC721) ownership contract
    function CSCPreSaleManager() public {
        require(msg.sender != address(0));
        paused = true;
        error = false;
        managerPrimary = msg.sender;
    }

    /// @dev allows the contract to accept ETH
    function() external payable {
    }
    
    /// @dev Function to add approved address to the 
    /// approved address list
    function addToApprovedAddress (address _newAddr) onlyManager whenNotPaused {
        require(_newAddr != address(0));
        require(!approvedAddressList[_newAddr]);
        approvedAddressList[_newAddr] = true;
    }
    
    /// @dev Function to remove an approved address from the 
    /// approved address list
    function removeFromApprovedAddress (address _newAddr) onlyManager whenNotPaused {
        require(_newAddr != address(0));
        require(approvedAddressList[_newAddr]);
        approvedAddressList[_newAddr] = false;
    }

    /// @dev Function toggle vending for collectible
    function toggleVending (uint256 _collectibleType, uint256 _collectibleClass) external onlyManager {
        if(preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass] == false) {
            preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass] = true;
        } else {
            preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass] = false;
        }
    }

    /// @dev Function toggle vending for collectible
    function setVendingFee (uint256 _collectibleType, uint256 _collectibleClass, uint fee) external onlyManager {
        preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass] = fee;
    }
    
    /// @dev This helps in creating a collectible and then 
    /// transfer it _toAddress
    function createCollectible(uint256 _collectibleType, uint256 _collectibleClass, address _toAddress) onlyManager external whenNotPaused {
        require(msg.sender != address(0));
        require(msg.sender != address(this));
        
        require(_toAddress != address(0));
        require(_toAddress != address(this));
        
        require(preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass]);
        require(preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] < preSaleItemTypeToClassToMaxLimit[_collectibleType][_collectibleClass]);
        
        uint256 _tokenId = _createCollectible(preSaleItemTypeToClassToName[_collectibleType][_collectibleClass], _collectibleType, _collectibleClass);
        
        _transfer(address(this), _toAddress, _tokenId);
    }


    /// @dev This helps in creating a collectible and then 
    /// transfer it _toAddress
    function vendingCreateCollectible(uint256 _collectibleType, uint256 _collectibleClass, address _toAddress) payable external whenNotPaused {
        
        //Only if Vending is Allowed for this Asset
        require(preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass]);

        require(msg.value >= preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass]);

        require(msg.sender != address(0));
        require(msg.sender != address(this));
        
        require(_toAddress != address(0));
        require(_toAddress != address(this));
        
        require(preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass]);
        require(preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] < preSaleItemTypeToClassToMaxLimit[_collectibleType][_collectibleClass]);
        
        uint256 _tokenId = _createCollectible(preSaleItemTypeToClassToName[_collectibleType][_collectibleClass], _collectibleType, _collectibleClass);
        uint256 excessBid = msg.value - preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass];
        
        if(excessBid > 0) {
            msg.sender.transfer(excessBid);
        }

        addressToValue[msg.sender] += preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass];
        
        _transfer(address(this), _toAddress, _tokenId);
    }

    
    
    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyManager whenPaused {
        // Actually unpause the contract.
        super.unpause();
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function hasError() public onlyManager whenPaused {
        // Actually error out the contract.
        super.hasError();
    }
    
    /// @dev Function does the init step and thus allow
    /// to create a Dummy 0th colelctible
    function preSaleInit() onlyManager {
        require(!CSCPreSaleInit);
        require(allPreSaleItems.length == 0);
        
        CSCPreSaleInit = true;
        
        //Fill in index 0 to null requests
        CSCPreSaleItem memory _Obj = CSCPreSaleItem(0, stringToBytes32("DummyAsset"), 0, 0, address(this), true);
        allPreSaleItems.push(_Obj);
    }

    /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT (ERC721) contract, but can be called either by
    ///  the owner or the NFT (ERC721) contract.
    function withdrawBalance() onlyBanker {
        // We are using this boolean method to make sure that even if one fails it will still work
        bankManager.transfer(this.balance);
    }

    // @dev a function to claim refund if and only if theres an error in the contract
    function claimRefund(address _ownerAddress) whenError {
        uint256 refundValue = addressToValue[_ownerAddress];

        require (refundValue > 0);
        
        addressToValue[_ownerAddress] = 0;

        _ownerAddress.transfer(refundValue);
        RefundClaimed(_ownerAddress, refundValue);
    }
    

    /// @dev Function used to set the flag isRedeemed to true
    /// can be called by addresses in the approvedAddressList
    function isRedeemed(uint256 _tokenId) {
        require(approvedAddressList[msg.sender]);
        require(_tokenId > STARTING_ASSET_BASE);
        uint256 generatedCollectibleId = _tokenId - STARTING_ASSET_BASE;
        
        CSCPreSaleItem memory _Obj = allPreSaleItems[generatedCollectibleId];
        _Obj.isRedeemed = true;
        
        allPreSaleItems[generatedCollectibleId] = _Obj;
    }
}